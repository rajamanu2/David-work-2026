import { LightningElement, api, track } from "lwc";

const parseJson = (j, d = []) => {
  try { return j ? JSON.parse(j) : d; } catch { return d; }
};

const hasValue = (v) =>
  v !== null && v !== undefined && (typeof v !== "string" || v.trim() !== "");

const evalCondition = (row, when) => {
  const val = row?.[when?.field];
  switch ((when?.operator || "HAS_VALUE").toUpperCase()) {
    case "HAS_VALUE": return hasValue(val);
    case "EQUALS":    return val == when.value; // eslint-disable-line eqeqeq
    default:          return false;
  }
};

export default class RecordTableBase extends LightningElement {
  /* ---------- Inputs ---------- */
  @api title = "Flow Table";
  @api recordsJson;
  @api columnsJson;
  @api requiredFieldsCsv;
  @api requiredRulesJson;
  @api maxRowSelection = 9999;

  // Always only validate selected rows
  _requiredOnlyWhenSelected = true;

  /* ---------- Outputs ---------- */
  @api updatedRecordsJson;
  @api selectedRecordsJson;
  @api selectedIdsJson;
  @api hasValidationErrors = false;

  /* ---------- Internal state ---------- */
  @track data        = [];
  @track columns     = [];
  @track draftValues = [];
  @track selectedIds = [];

  @track datatableErrors;
  @track showErrorBanner = false;
  errorBannerText = "";

  get storageKey() {
    return "RecordTable_state";
  }

  connectedCallback() {
    this.columns = parseJson(this.columnsJson, []);
    const incoming = parseJson(this.recordsJson, []);

    // Read directly from sessionStorage to check if this is a re-render
    // after failed validation — don't rely on prop binding which may not
    // have propagated yet when connectedCallback fires
    let isRerender = false;
    try {
      const ts = sessionStorage.getItem("RecordTable_rerender_ts");
      if (ts) {
        const age = Date.now() - parseInt(ts, 10);
        isRerender = age < 3000;
        console.log("recordTableBase: last validate was", age, "ms ago, isRerender =", isRerender);
      }
    } catch { /* ignore */ }

    console.log("recordTableBase: connectedCallback, isRerender =", isRerender);

    if (isRerender) {
      let persisted = null;
      try { persisted = sessionStorage.getItem(this.storageKey); } catch { /* ignore */ }

      if (persisted) {
        const state = parseJson(persisted, null);
        if (state) {
          console.log("recordTableBase: restoring state, selectedIds =", JSON.stringify(state.selectedIds));
          this.data        = state.data        || incoming.map(({ isSelected, ...rest }) => ({ ...rest }));
          this.selectedIds = state.selectedIds || [];
          this.draftValues = state.draftValues || [];
          this._runValidation();
          return;
        }
      }
    }

    console.log("recordTableBase: fresh load");
    try { sessionStorage.removeItem(this.storageKey); } catch { /* ignore */ }
    this.selectedIds = [];
    this.data = incoming.map(({ isSelected, ...rest }) => ({ ...rest }));
  }

  get selectedCount() { return this.selectedIds.length; }

  get maxRowSelectionNum() {
    return parseInt(this.maxRowSelection, 10) || 9999;
  }

  /* ---------- Persist state ---------- */

  _persistState() {
    try {
      console.log("recordTableBase: persisting state, selectedIds =", JSON.stringify(this.selectedIds));
      sessionStorage.setItem(this.storageKey, JSON.stringify({
        data:        this.data,
        selectedIds: this.selectedIds,
        draftValues: this.draftValues
      }));
    } catch { /* ignore */ }
  }

  /* ---------- Draft handling ---------- */

  handleCellChange(e) {
    const incoming = e.detail.draftValues || [];
    const map = new Map(this.draftValues.map(d => [d.Id, { ...d }]));
    incoming.forEach(d => {
      map.set(d.Id, { ...(map.get(d.Id) || { Id: d.Id }), ...d });
    });
    this.draftValues = [...map.values()];
    this._persistState();
    this.dispatchChange();
  }

  handleSave(e) {
    const drafts = this.draftValues.length ? this.draftValues : e.detail.draftValues;
    this.mergeDrafts(drafts);
    this.draftValues = [];
    this._persistState();
    this.validateAndEmit();
  }

  mergeDrafts(drafts) {
    const map = new Map(this.data.map(r => [r.Id, { ...r }]));
    drafts.forEach(d => map.set(d.Id, { ...map.get(d.Id), ...d }));
    this.data = [...map.values()];
  }

  commitDrafts() {
    if (!this.draftValues.length) return;
    this.mergeDrafts(this.draftValues);
    this.draftValues = [];
  }

  /* ---------- Selection ---------- */

  handleRowSelection(e) {
    this.selectedIds = e.detail.selectedRows.map(r => r.Id);
    this._persistState();
    this.validateAndEmit();
  }

  /* ---------- Validation ---------- */

  _runValidation() {
    const required = (this.requiredFieldsCsv || "")
      .split(",").map(f => f.trim()).filter(Boolean);
    const rules    = parseJson(this.requiredRulesJson, []);
    const selected = new Set(this.selectedIds);

    this.datatableErrors     = undefined;
    this.showErrorBanner     = false;
    this.hasValidationErrors = false;

    const draftMap = new Map(this.draftValues.map(d => [d.Id, d]));
    const errors   = {};

    this.data.forEach(row => {
      if (this._requiredOnlyWhenSelected && !selected.has(row.Id)) return;

      const effective = { ...row, ...(draftMap.get(row.Id) || {}) };
      const missing   = new Set();

      required.forEach(f => { if (!hasValue(effective[f])) missing.add(f); });
      rules.forEach(r => {
        if (evalCondition(effective, r.when)) {
          r.require.forEach(f => { if (!hasValue(effective[f])) missing.add(f); });
        }
      });

      if (missing.size) {
        this.hasValidationErrors = true;
        errors[row.Id] = {
          title:      "Missing required fields",
          fieldNames: [...missing],
          messages:   [`Fill: ${[...missing].join(", ")}`]
        };
      }
    });

    if (this.hasValidationErrors) {
      this.datatableErrors = { rows: errors };
      this.showErrorBanner = true;
      this.errorBannerText = "Some rows are missing required values.";
    }

    return selected;
  }

  validateAndEmit() {
    const selected = this._runValidation();
    const out = this.data.map(r => ({ ...r, isSelected: selected.has(r.Id) }));
    this.updatedRecordsJson  = JSON.stringify(out);
    this.selectedRecordsJson = JSON.stringify(out.filter(r => r.isSelected));
    this.selectedIdsJson     = JSON.stringify([...selected]);
    this.dispatchChange();
  }

  dispatchChange() {
    this.dispatchEvent(new CustomEvent("tablechange", {
      detail: {
        updatedRecordsJson:  this.updatedRecordsJson,
        selectedRecordsJson: this.selectedRecordsJson,
        selectedIdsJson:     this.selectedIdsJson,
        hasValidationErrors: this.hasValidationErrors
      },
      bubbles:  true,
      composed: true
    }));
  }

  /* ---------- Flow Next ---------- */

  @api
  validate() {
    this.commitDrafts();
    this.validateAndEmit();
    this._persistState();
    return this.hasValidationErrors
      ? { isValid: false, errorMessage: "Fix the highlighted rows before continuing." }
      : { isValid: true };
  }
}