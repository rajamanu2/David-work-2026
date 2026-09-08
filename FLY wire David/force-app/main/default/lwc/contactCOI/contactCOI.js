import { LightningElement, wire, api } from 'lwc';
import { getRecord, getRecordUi, getFieldValue } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { NavigationMixin } from 'lightning/navigation';

import ACCOUNT_RECORD_TYPE_FIELD from '@salesforce/schema/Account.RecordType.DeveloperName';

export default class ContactCOI extends NavigationMixin(LightningElement) {
    @api recordId;  // This will hold the Account ID when you put this LWC in the Account record page
    contacts =[];
    contactsToDisplay =[];
    error;
    status = 'Main_Point_Person__c'; //Default filter option
    accountRecordTypeName

    //1319 - Get recordtype DeveloperName of account
    @wire(getRecord, {recordId: '$recordId', fields: [ACCOUNT_RECORD_TYPE_FIELD]})
    accountinfo({data, error}){
        if(data){
            this.accountRecordTypeName = getFieldValue(data, ACCOUNT_RECORD_TYPE_FIELD) ?? '';
            console.log('accountRecordTypeName ',this.accountRecordTypeName);
        }
        else if (error){
            this.error = error;
        }
    }

    get isHealthcareAccount(){
        return this.accountRecordTypeName === 'Healthcare';
    }

    get contactFilters(){
      const filterOptions = [
        { label: 'All', value: 'All'},
        { label: 'Main Point Person', value: 'Main_Point_Person__c'},
        { label: 'Billing Contact', value: 'Billing_Contact__c' },
        { label: 'Chargeback Contact', value: 'Chargeback_Contact__c' },
        { label: 'Influencer', value: 'Influencer__c' }, 
        { label: 'Refund Contact', value: 'Refund_Contact__c' }
        
    ];
    
    //1319 - If Account record type is healthcare then append Flywire Reference to filterOptions
    if(this.isHealthcareAccount){
        return  [...filterOptions,
            { label: 'Flywire Reference', value: 'Flywire_Reference__c' }
        ]
    }
    return filterOptions;
    }

    //{ label: 'Billing All', value: 'Billing' },
    get cardLabel() {
        return 'Contacts Key Stakeholders (' + this.contactsToDisplay.length + ')';
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Contacts',
        fields: ['Contact.Name','Contact.FirstName','Contact.LastName','Contact.Title','Contact.Phone','Contact.Email','Contact.Billing_Contact__c','Contact.Influencer__c','Contact.Main_Point_Person__c','Contact.Refund_Contact__c','Contact.Chargeback_Contact__c','Contact.Dashboard_Access__c','Contact.Id','Contact.Flywire_Reference__c'],
        where: '{  and: [ { or: [ {Main_Point_Person__c: { eq: TRUE}} , {Billing_Contact__c: { eq: TRUE}}, {Refund_Contact__c: { eq: TRUE}} , {Chargeback_Contact__c: { eq: TRUE}}, {Influencer__c: { eq: TRUE}}, {Flywire_Reference__c: { eq: TRUE}} ]} , {Inactive__c: { eq: FALSE}} ]}',
        sortBy: ['Contact.Name']
    })listInfo({ error, data }) {

         if (data) {
            this.contacts = data.records;
            const contactsInt = data.records;
            
            this.error = undefined;
            this.contactsToDisplay = this.contacts.filter(elem => elem.fields.Main_Point_Person__c.value == true );
            //this.contacts = this.contactsToDisplay;
            this.dispatchEvent(new CustomEvent('contactcount', { detail: this.contactsToDisplay.length}));
            console.log('Got the data successfully');
            console.log('contacts length'+ this.contacts.length);
            console.log('contactsToDisplay length'+ this.contactsToDisplay.length);
            //updateList();
        } else if (error) {
            this.error = error;
            this.contacts = undefined;
            console.error('Error getting activity from apex message:', error.body.message);
        }
    }

    handleSelection(event) {
        this.status = event.detail.value;
        this.updateList();
    }


    updateList() {
        if (this.status === 'Billing_Contact__c') {
            this.contactsToDisplay = this.contacts.filter(elem => elem.fields.Billing_Contact__c.value == true);
        } else if (this.status === 'Refund_Contact__c') {
            this.contactsToDisplay = this.contacts.filter(elem => elem.fields.Refund_Contact__c.value == true);
        }else if (this.status === 'Main_Point_Person__c') {
            this.contactsToDisplay = this.contacts.filter(elem => elem.fields.Main_Point_Person__c.value == true);
        }else if (this.status === 'Chargeback_Contact__c') {
            this.contactsToDisplay = this.contacts.filter(elem => elem.fields.Chargeback_Contact__c.value == true);
        }else if (this.status === 'Influencer__c') {
            this.contactsToDisplay = this.contacts.filter(elem => elem.fields.Influencer__c.value == true);
        }else if (this.status === 'Billing') {
            this.contactsToDisplay = this.contacts.filter(elem => elem.fields.Billing_Contact__c.value == true 
            || elem.fields.Refund_Contact__c.value == true 
            || elem.fields.Chargeback_Contact__c.value == true);
        }else if (this.status === 'Flywire_Reference__c') {
            this.contactsToDisplay = this.contacts.filter(elem => elem.fields.Flywire_Reference__c.value == true);
        }else if (this.status === 'All' && !this.isHealthcareAccount) {
            this.contactsToDisplay = this.contacts.filter(elem => elem.fields.Billing_Contact__c.value == true 
            || elem.fields.Refund_Contact__c.value == true 
            || elem.fields.Main_Point_Person__c.value == true
            || elem.fields.Chargeback_Contact__c.value == true 
            || elem.fields.Influencer__c.value == true
            || elem.fields.Billing_Contact__c.value == true
            );
        }
        //1319 - Flywire Reference = true contacts are returned only for healthcare accounts
        else if (this.status === 'All' && this.isHealthcareAccount) {
            this.contactsToDisplay = this.contacts.filter(elem => elem.fields.Billing_Contact__c.value == true 
            || elem.fields.Refund_Contact__c.value == true 
            || elem.fields.Main_Point_Person__c.value == true
            || elem.fields.Chargeback_Contact__c.value == true 
            || elem.fields.Influencer__c.value == true
            || elem.fields.Billing_Contact__c.value == true
            || elem.fields.Flywire_Reference__c.value == true
            );
        }
        this.dispatchEvent(new CustomEvent('contactcount', { detail: this.contactsToDisplay.length}));
    }

    viewRecord(event) {
        const currentContactId = event.currentTarget.dataset.id;

        // Navigate to Contact record page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                "recordId": currentContactId,
                "objectApiName": "Contact",
                "actionName": "view"
            },
        });
    }
}