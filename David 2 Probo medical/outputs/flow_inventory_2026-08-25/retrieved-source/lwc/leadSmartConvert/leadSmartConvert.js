import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Apex
import convertLeadFlat from '@salesforce/apex/LeadConversionController.convertLeadFlat';
import searchByOppNumber from '@salesforce/apex/LeadConversionController.searchOpportunitiesByNumber';
import searchContactsForAccount from '@salesforce/apex/LeadConversionController.searchContactsForAccount';
import getOpportunityRecordTypes from '@salesforce/apex/LeadConversionController.getOpportunityRecordTypes';
import getLeadPrefill from '@salesforce/apex/LeadConversionController.getLeadPrefill';
import getServiceContractForOpp from '@salesforce/apex/LeadConversionController.getServiceContractForOpp';
import searchAccountsRich from '@salesforce/apex/LeadConversionController.searchAccountsRich';



// UI API
import { getRecord } from 'lightning/uiRecordApi';

// Standard Lead fields to detect already-converted leads
import LEAD_IS_CONVERTED from '@salesforce/schema/Lead.IsConverted';
import LEAD_CONVERTED_ACCOUNT_ID from '@salesforce/schema/Lead.ConvertedAccountId';
import LEAD_CONVERTED_CONTACT_ID from '@salesforce/schema/Lead.ConvertedContactId';
import LEAD_CONVERTED_OPPORTUNITY_ID from '@salesforce/schema/Lead.ConvertedOpportunityId';

// Names for tiles/pills
import ACCOUNT_NAME from '@salesforce/schema/Account.Name';
import CONTACT_NAME from '@salesforce/schema/Contact.Name';
import OPPORTUNITY_NAME from '@salesforce/schema/Opportunity.Name';

export default class LeadSmartConvert extends LightningElement {
  @api recordId;
  _pageRef;

  @wire(CurrentPageReference) setPR(pr) { this._pageRef = pr; }

  // ---------------- Derived/UI ----------------
  get needsLeadId() { return !this._looksLikeId(this.recordId); }
  get leadIdClass() { return this.needsLeadId ? 'lead-id--bad' : 'lead-id--ok'; }
  get resolvedLeadId() { return (this.recordId && this.recordId.length) ? this.recordId : '— not set —'; }

  get convertDisabled() { return this.createOpportunity && !this.opportunityName; }
  get hasResults() { return this.resultAccount || this.resultContact || this.resultOpportunity; }

  // Links for header/results tiles
  get leadUrl() { return this.recordId ? `/lightning/r/Lead/${this.recordId}/view` : '#'; }
  get resultAccountUrl() { return this.resultAccount?.Id ? `/lightning/r/Account/${this.resultAccount.Id}/view` : '#'; }
  get resultContactUrl() { return this.resultContact?.Id ? `/lightning/r/Contact/${this.resultContact.Id}/view` : '#'; }
  get resultOpportunityUrl() { return this.resultOpportunity?.Id ? `/lightning/r/Opportunity/${this.resultOpportunity.Id}/view` : '#'; }

  // Opportunity listbox
  get hasOppResults() { return Array.isArray(this.oppResults) && this.oppResults.length > 0; }
  get showListbox() {
    return !this.opportunityId && this.isOpen &&
           (this.hasOppResults || (this.oppSearchTerm && this.oppSearchTerm.length >= 2));
  }
  get comboboxClass() {
    return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.isOpen ? 'slds-is-open' : ''}`;
  }

  get acctComboboxClass() {
  return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.isAcctOpen ? 'slds-is-open' : ''}`;
  }
  get accountUrl() {
    return this.accountId ? `/lightning/r/Account/${this.accountId}/view` : undefined;
  }

  get oppSelectedLabel() { return this.selectedOpp?.label || ''; }
  get oppUrl() { return this.opportunityId ? `/lightning/r/Opportunity/${this.opportunityId}/view` : undefined; }

  // Contact listbox (scoped to Account)
  get isContactSearchDisabled() { return !this.accountId; }
  get contactPlaceholder() { return this.accountId ? 'Search contacts under this Account' : 'Select an Account first'; }
  get hasContactResults() { return Array.isArray(this.contactResults) && this.contactResults.length > 0; }
  get showContactListbox() {
    return !this.contactId && this.isContactOpen &&
           (this.hasContactResults || (this.contactSearchTerm && this.contactSearchTerm.length >= 2));
  }
  get contactComboboxClass() {
    return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.isContactOpen ? 'slds-is-open' : ''}`;
  }
  get contactSelectedLabel() { return this.selectedContact?.label || ''; }
  get contactUrl() { return this.contactId ? `/lightning/r/Contact/${this.contactId}/view` : undefined; }

  // Opp record type combobox
  get oppRecordTypeOptions() { return (this.oppRecordTypes || []).map(r => ({ label: r.name, value: r.id })); }

  // ---------------- State ----------------
  // After successful convert OR if lead is already converted, show only results
  @track showResultsOnly = false;

  // Create toggles
  @track createNewAccount = false;
  @track createNewContact = false;

  // Selections
  @track accountId;
  @track contactId;
  @track opportunityId;

      // ---- Account lookup (rich) ----
  @track acctSearchTerm = '';
  @track acctResults = [];
  @track selectedAccount; // optional display object if you want to show a pill
  isAcctOpen = false;
  _acctDebounce;

  // Opportunity creation
  @track createOpportunity = false;
  @track opportunityName = '';
  @track opportunityRecordTypeId = null;
  @track oppRecordTypes = [];

  // Messaging
  @track errorMessage = '';
  @track successMessage = '';

  // Result tiles (after convert)
  @track resultAccount;
  @track resultContact;
  @track resultOpportunity;

  // state to remember the opp's account
  @track selectedOppParentId = null;
  @track selectedOppParentName = null;

  get hasOppAccountMismatch() {
    // mismatch only matters if both are set
    return this.opportunityId && this.accountId && this.selectedOppParentId && (this.accountId !== this.selectedOppParentId);
  }

  // Disable convert if name missing OR mismatch
  get convertDisabled() {
    const needName = this.createOpportunity && !this.opportunityName;
    return needName || this.hasOppAccountMismatch;
  }


  // Reactive Ids to fetch names for results-only mode
  @track resultAccountId;
  @track resultContactId;
  @track resultOpportunityId;

  // Opp lookup
  @track oppSearchTerm = '';
  @track oppResults = [];
  @track selectedOpp; // { id, label, subtitle }
  isOpen = false;
  _debounceOpp;

  // Service Contract Lookups
  @track resultServiceContract;           // { Id, Name, apiName }
  @track selectedOppServiceContract;      // for the pre-convert selected Opportunity

  get resultServiceContractUrl() {
    const sc = this.resultServiceContract;
    return (sc?.Id && sc?.apiName) ? `/lightning/r/${sc.apiName}/${sc.Id}/view` : undefined;
  }
  get selectedOppServiceContractUrl() {
    const sc = this.selectedOppServiceContract;
    return (sc?.Id && sc?.apiName) ? `/lightning/r/${sc.apiName}/${sc.Id}/view` : undefined;
  }


  // Contact lookup
  @track contactSearchTerm = '';
  @track contactResults = [];
  @track selectedContact; // { id, label, subtitle }
  isContactOpen = false;
  _debounceContact;

  connectedCallback() {
    // Preload opportunity record types (alphabetical from Apex)
    getOpportunityRecordTypes()
      .then(rows => { this.oppRecordTypes = rows || []; })
      .catch(() => { this.oppRecordTypes = []; });
  }

  // ---------------- Detect already-converted (standard fields) ----------------
  @wire(getRecord, {
    recordId: '$recordId',
    fields: [LEAD_IS_CONVERTED, LEAD_CONVERTED_ACCOUNT_ID, LEAD_CONVERTED_CONTACT_ID, LEAD_CONVERTED_OPPORTUNITY_ID]
  })
  wiredLeadConverted({ data }) {
    if (!data) return;
    const f = data.fields;
    const isConverted = f?.IsConverted?.value === true;
    if (!isConverted) return;

    // Results-only view
    this.resultAccountId     = f?.ConvertedAccountId?.value || null;
    this.resultContactId     = f?.ConvertedContactId?.value || null;
    this.resultOpportunityId = f?.ConvertedOpportunityId?.value || null;

    this.resultAccount     = this.resultAccountId     ? { Id: this.resultAccountId,     Name: '' } : null;
    this.resultContact     = this.resultContactId     ? { Id: this.resultContactId,     Name: '' } : null;
    this.resultOpportunity = this.resultOpportunityId ? { Id: this.resultOpportunityId, Name: '' } : null;

    // Service Contract returned by Apex (if any)
    if (resp.serviceContractId) {
      this.resultServiceContract = {
        Id: resp.serviceContractId,
        Name: resp.serviceContractName,
        apiName: resp.serviceContractSObject // 'ServiceContract' or custom object api name
      };
    } else {
      this.resultServiceContract = null;
    }


    this.showResultsOnly = true;
  }

  // ---------------- Prefill from Apex (custom fields) ----------------
  @wire(getLeadPrefill, { leadId: '$recordId' })
  wiredLeadPrefillApex({ data, error }) {
    // If already converted (results-only mode), skip
    if (this.showResultsOnly || error || !data) return;

    const {
      relatedAccountId,
      relatedAccountName,
      matchedContactId,
      matchedContactName,
      opportunityNumber
    } = data;

    // Account
    if (relatedAccountId) {
      this.createNewAccount = false;
      this.accountId = relatedAccountId;
    }

    // Contact (show pill immediately)
    if (matchedContactId) {
      this.createNewContact = false;
      this.contactId = matchedContactId;
      this.selectedContact = {
        id: matchedContactId,
        label: matchedContactName || '',
        subtitle: ''
      };
      this.contactSearchTerm = matchedContactName || '';
    }

    // Opportunity number -> seed lookup and try exact auto-select
    if (opportunityNumber) {
      this.createOpportunity = false;
      this._prefillOppByNumber(opportunityNumber); // async; exact match will auto-select
    }
  }

  // ---------------- Names for tiles/pills ----------------
  @wire(getRecord, { recordId: '$resultAccountId', fields: [ACCOUNT_NAME] })
  wiredAccName({ data }) {
    if (data && this.resultAccountId) {
      this.resultAccount = { Id: this.resultAccountId, Name: data.fields.Name.value };
    }
  }
  @wire(getRecord, { recordId: '$resultContactId', fields: [CONTACT_NAME] })
  wiredConName({ data }) {
    if (data && this.resultContactId) {
      this.resultContact = { Id: this.resultContactId, Name: data.fields.Name.value };
    }
  }
  @wire(getRecord, { recordId: '$resultOpportunityId', fields: [OPPORTUNITY_NAME] })
  wiredOppName({ data }) {
    if (data && this.resultOpportunityId) {
      this.resultOpportunity = { Id: this.resultOpportunityId, Name: data.fields.Name.value };
    }
  }

  // Also fill the contact pill name when Matched_Contact__c prefills contactId
  @wire(getRecord, { recordId: '$contactId', fields: [CONTACT_NAME] })
  wiredPrefillContactName({ data }) {
    if (data && this.contactId && !this.createNewContact) {
      const name = data.fields?.Name?.value || '';
      // Only set if we don't already have a label (keep Apex-provided name if present)
      if (!this.selectedContact?.label) {
        this.selectedContact = { id: this.contactId, label: name, subtitle: '' };
        this.contactSearchTerm = name;
      }
    }
  }

  // ---------------- Helpers ----------------
  _looksLikeId(v) { return typeof v === 'string' && /^[a-zA-Z0-9]{15,18}$/.test(v); }

  _resolveRecordId() {
    if (this._looksLikeId(this.recordId)) return;

    const pr = this._pageRef;
    const fromPR =
      pr?.attributes?.recordId ||
      pr?.state?.recordId ||
      pr?.state?.c__recordId ||
      pr?.state?.leadId ||
      pr?.state?.r__recordId ||
      null;

    if (this._looksLikeId(fromPR)) { this.recordId = fromPR; return; }

    try {
      const href = window.location?.href || '';
      const path = window.location?.pathname || '';
      const mHash = href.match(/\/sObject\/([a-zA-Z0-9]{15,18})\/view/i);
      if (this._looksLikeId(mHash?.[1])) { this.recordId = mHash[1]; return; }
      const mR = href.match(/\/r\/Lead\/([a-zA-Z0-9]{15,18})\/view/i);
      if (this._looksLikeId(mR?.[1])) { this.recordId = mR[1]; return; }
      const mPath = path.match(/\/Lead\/([a-zA-Z0-9]{15,18})/i);
      if (this._looksLikeId(mPath?.[1])) { this.recordId = mPath[1]; }
    } catch { /* ignore */ }
  }

  // Try to auto-select an Opportunity by number; otherwise just seed the search term
  async _prefillOppByNumber(term) {
    this.oppSearchTerm = term;
    try {
      const rows = await searchByOppNumber({ searchTerm: term.trim(), limitSize: 20 });
      this.oppResults = Array.isArray(rows) ? rows : [];
      const exact = (this.oppResults || []).find(
        r => (r.label || '').toLowerCase() === term.trim().toLowerCase()
      );
      if (exact) {
      this.opportunityId = exact.id;
      this.selectedOpp = { id: exact.id, label: exact.label, subtitle: exact.subtitle };
      this.isOpen = false;
      this._loadOppServiceContract(this.opportunityId);      
      } else {
        // Leave dropdown open if there are matches to prompt selection
        this.isOpen = this.oppResults.length > 0;
      }
    } catch {
      // Keep term so user can manually search/confirm
      this.isOpen = false;
      this.oppResults = [];
    }
  }

    // ---------------- Lead picker (fallback) ----------------
    handleLeadPick(e) {
      const id = e.detail.recordId;
      if (this._looksLikeId(id)) this.recordId = id;
    }

  openAcct = () => { this.isAcctOpen = true; };

  handleAcctInput = (e) => {
    this.acctSearchTerm = e.target.value;
    if (this._acctDebounce) clearTimeout(this._acctDebounce);
    this._acctDebounce = setTimeout(() => this._queryAccounts(), 220);
  };

  async _queryAccounts() {
    const term = (this.acctSearchTerm || '').trim();
    if (!term || term.length < 2) { this.acctResults = []; return; }
    try {
      const rows = await searchAccountsRich({ searchTerm: term, limitSize: 20 });
      this.acctResults = Array.isArray(rows) ? rows : [];
      this.isAcctOpen = true;
    } catch (e) {
      this.acctResults = [];
      this.isAcctOpen = true;
    }
  }

  handleAcctClick = (e) => {
    const id = e.currentTarget?.dataset?.id;
    const row = this.acctResults.find(r => r.id === id);
    this.accountId = id;

    // Optional: keep a display object (so we can show a pill with name/subtitle)
    this.selectedAccount = row ? { id: row.id, label: row.label, subtitle: row.subtitle } : null;

    // When account changes, any selected contact is no longer valid
    this.clearContactSelection();

    // Collapse dropdown + show chosen name in the input
    this.acctSearchTerm = row?.label || '';
    this.acctResults = [];
    this.isAcctOpen = false;
  };

  handleAcctKeydown = (e) => { if (e.key === 'Escape') this.isAcctOpen = false; };
  handleAcctBlur = () => { setTimeout(() => { this.isAcctOpen = false; }, 150); };

  clearAccountSelection = () => {
    this.accountId = null;
    this.selectedAccount = null;
    this.acctSearchTerm = '';
    this.acctResults = [];
    this.isAcctOpen = false;
    // also clear contacts since account is gone
    this.clearContactSelection();
  };


  // ---------------- Account ----------------
  handleCreateNewAccount(e) {
    this.createNewAccount = e.target.checked;
    if (this.createNewAccount) {
      this.accountId = null; // ensure conversion creates a new Account
      this.clearContactSelection();
    }
  }
  handleAccountChange(e) {
    this.accountId = e.detail.recordId || null;
    // changing account invalidates contact selection
    this.clearContactSelection();
  }

  // ---------------- Contact (scoped to Account) ----------------
  openContact = () => { if (!this.isContactSearchDisabled) this.isContactOpen = true; };

  handleContactInput = (e) => {
    this.contactSearchTerm = e.target.value;
    if (this._debounceContact) clearTimeout(this._debounceContact);
    this._debounceContact = setTimeout(() => this._queryContacts(), 220);
  };

  async _queryContacts() {
    if (!this.accountId || !this.contactSearchTerm || this.contactSearchTerm.trim().length < 2) {
      this.contactResults = [];
      return;
    }
    try {
      const rows = await searchContactsForAccount({
        accountId: this.accountId,
        searchTerm: this.contactSearchTerm.trim(),
        limitSize: 20
      });
      this.contactResults = Array.isArray(rows) ? rows : [];
      this.isContactOpen = true;
    } catch {
      this.contactResults = [];
      this.isContactOpen = true;
    }
  }

  handleContactClick = (e) => {
    const id = e.currentTarget?.dataset?.id;
    const row = this.contactResults.find(r => r.id === id);
    this.contactId = id;
    this.selectedContact = row ? { id: row.id, label: row.label, subtitle: row.subtitle } : null;
    this.contactSearchTerm = row?.label || '';
    this.contactResults = [];
    this.isContactOpen = false;
  };

  clearContactSelection = () => {
    this.contactId = null;
    this.selectedContact = null;
    this.contactSearchTerm = '';
    this.contactResults = [];
    this.isContactOpen = false;
  };

  handleContactKeydown = (e) => { if (e.key === 'Escape') this.isContactOpen = false; };
  handleContactBlur = () => { setTimeout(() => { this.isContactOpen = false; }, 150); };

  handleCreateNewContact(e) {
    this.createNewContact = e.target.checked;
    if (this.createNewContact) {
      this.clearContactSelection(); // ensure conversion creates a new Contact
    }
  }

accountMatchingInfo = {
  primaryField: 'Name',
  additionalFields: ['BillingStreet','BillingCity','BillingState','BillingPostalCode']
};
accountDisplayInfo = {
  additionalFields: ['BillingStreet','BillingCity','BillingState','BillingPostalCode']
};


  // ---------------- Opportunity lookup (by number) ----------------
  openOpp = () => { if (!this.opportunityId) this.isOpen = true; };

  handleOppInput = (e) => {
    this.oppSearchTerm = e.target.value;
    if (this._debounceOpp) clearTimeout(this._debounceOpp);
    this._debounceOpp = setTimeout(() => this._queryOpps(), 220);
  };

  async _queryOpps() {
    if (!this.oppSearchTerm || this.oppSearchTerm.trim().length < 2) {
      this.oppResults = [];
      return;
    }
    try {
      const rows = await searchByOppNumber({ searchTerm: this.oppSearchTerm.trim(), limitSize: 20 });
      this.oppResults = Array.isArray(rows) ? rows : [];
      this.isOpen = true;
    } catch {
      this.oppResults = [];
      this.isOpen = true;
    }
  }

  handleOppClick = (e) => {
    const id = e.currentTarget?.dataset?.id;
    const row = this.oppResults.find(r => r.id === id);

    this.opportunityId = id;
    this.selectedOpp = row ? { id: row.id, label: row.label, subtitle: row.subtitle } : null;

    // Save the Opportunity's Account (provided by Apex search)
    this.selectedOppParentId = row?.parentId || null;
    this.selectedOppParentName = row?.parentName || null;

    // If no Account has been chosen yet, auto-populate it from the Opportunity
    if (!this.accountId && this.selectedOppParentId) {
      this.createNewAccount = false;                 // ensure we're not in "create account" mode
      this.accountId = this.selectedOppParentId;

      // Set the visible pill/input
      this.selectedAccount = {
        id: this.selectedOppParentId,
        label: this.selectedOppParentName || 'Account',
        subtitle: ''                                  // optional; can be filled later if you fetch details
      };
      this.acctSearchTerm = this.selectedOppParentName || '';
      this.clearContactSelection();                   // account changed → clear contact selection
    }

    this.oppSearchTerm = row?.label || '';
    this.oppResults = [];
    this.isOpen = false;
  };


    useOppAccount = () => {
    if (!this.selectedOppParentId) return;

    // set the selected account to the opp's account
    this.accountId = this.selectedOppParentId;

    // update the display pill (we may not have the address; name is enough)
    this.selectedAccount = {
      id: this.selectedOppParentId,
      label: this.selectedOppParentName || 'Account',
      subtitle: ''  // optional; could fetch details if you want
    };

    // clear the contact since changing accounts invalidates it
    this.clearContactSelection();
  };



  clearOpportunitySelection = () => {
    this.opportunityId = null;
    this.selectedOpp = null;
    this.oppSearchTerm = '';
    this.oppResults = [];
    this.selectedOppServiceContract = null;   // 👈 clear
    this.isOpen = false;
  };


  handleKeydown = (e) => { if (e.key === 'Escape') this.isOpen = false; };
  handleBlur = () => { setTimeout(() => { this.isOpen = false; }, 150); };

  // ---------------- New Opportunity fields ----------------
  handleCreateOppToggle(e) {
    this.createOpportunity = e.target.checked;
    if (this.createOpportunity) {
      this.clearOpportunitySelection();
      this.opportunityName = '';
    } else {
      this.opportunityName = '';
      this.opportunityRecordTypeId = null;
    }
  }
  handleOpportunityNameChange(e) { this.opportunityName = e.target.value; }
  handleOppRecordTypeChange(e) { this.opportunityRecordTypeId = e.detail.value || null; }

 // ---------------- Handle Fetcfhing of Service Contract ---------------
  async _loadOppServiceContract(oppId) {
    this.selectedOppServiceContract = null;
    if (!oppId) return;
    try {
      const sc = await getServiceContractForOpp({ opportunityId: oppId });
      if (sc && sc.id) {
        this.selectedOppServiceContract = { Id: sc.id, Name: sc.name, apiName: sc.sobjectApiName };
      }
    } catch (e) {
      // ignore; keep UI clean
      this.selectedOppServiceContract = null;
    }
  }
  
  // ---------------- Convert ----------------
  async handleConvert() {
    this.clearMessages();
    this.clearResults();

    if (this.hasOppAccountMismatch) {
      const msg = 'Account mismatch: use “Use Opportunity’s Account” or pick an Account that matches the Opportunity.';
      this.errorMessage = msg;
      this.dispatchEvent(new ShowToastEvent({ title: 'Lead Conversion', message: msg, variant: 'error' }));
      return;
    }


    this._resolveRecordId();
    if (!this._looksLikeId(this.recordId)) {
      const msg = 'Lead Id is required. Pick the Lead at the top, or add this component to a Lead record page.';
      this.errorMessage = msg;
      this.dispatchEvent(new ShowToastEvent({ title: 'Lead Conversion', message: msg, variant: 'error' }));
      return;
    }

    // Ensure toggles clear conflicting selections
    const acctId = this.createNewAccount ? null : (this.accountId || null);
    const contId = this.createNewContact ? null : (this.contactId || null);

    try {
      const resp = await convertLeadFlat({
        leadId: this.recordId,
        accountId: acctId,
        contactId: contId,
        opportunityId: this.opportunityId || null,
        createOpportunity: this.createOpportunity,
        opportunityName: this.opportunityName || null,
        opportunityRecordTypeId: (this.createOpportunity && !this.opportunityId)
          ? (this.opportunityRecordTypeId || null)
          : null
      });

      if (!resp || !resp.success) {
        const msg = resp?.message || 'Conversion failed.';
        this.errorMessage = msg;
        this.dispatchEvent(new ShowToastEvent({ title: 'Lead Conversion', message: msg, variant: 'error' }));
        return;
      }

      // Populate results
      if (resp.accountId)     this.resultAccount     = { Id: resp.accountId,     Name: resp.accountName };
      if (resp.contactId)     this.resultContact     = { Id: resp.contactId,     Name: resp.contactName };
      if (resp.opportunityId) this.resultOpportunity = { Id: resp.opportunityId, Name: resp.opportunityName };

      // Success + switch to results-only mode
      this.successMessage = 'Lead converted successfully.';
      this.dispatchEvent(new ShowToastEvent({ title: 'Lead Conversion', message: 'Lead converted', variant: 'success' }));
      this.showResultsOnly = true;

    } catch (e) {
      const msg = e?.body?.message || e?.message || 'Unexpected error.';
      this.errorMessage = msg;
      this.dispatchEvent(new ShowToastEvent({ title: 'Lead Conversion', message: msg, variant: 'error' }));
    }
  }

  // ---------------- Utils ----------------
  clearMessages() { this.errorMessage = ''; this.successMessage = ''; }
  clearResults() {
    this.resultAccount = null;
    this.resultContact = null;
    this.resultOpportunity = null;

    this.resultAccountId = null;
    this.resultContactId = null;
    this.resultOpportunityId = null;
  }
}