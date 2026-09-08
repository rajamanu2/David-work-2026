import { LightningElement, api, track } from "lwc";

export default class RecordTableStateful extends LightningElement {
  /* ---------- Flow Inputs ---------- */
  @api title               = "Flow Table";
  @api initialRecordsJson;
  @api columnsJson;
  @api requiredFieldsCsv;
  @api requiredRulesJson;
  @api maxRowSelection     = 9999;

  /* ---------- Flow Outputs ---------- */
  @api updatedRecordsJson;
  @api selectedRecordsJson;
  @api hasValidationErrors = false;

  /* ---------- Internal ---------- */
  @track effectiveRecordsJson;
  @track restoreState = false;

  get storageKey() {
    return "RecordTableStateful";
  }

  get baseStorageKey() {
    return "RecordTable_state";
  }

  get tsStorageKey() {
    return (this._stateKey || "RecordTableStateful") + "_state_ts";
  }

  connectedCallback() {
    console.log("recordTableStateful: connectedCallback fired, storageKey =", this.storageKey);

    // Check if validate() was called recently (within 3 seconds)
    // indicating a re-render after failed validation
    let isRerender = false;
    try {
      const ts = sessionStorage.getItem("RecordTable_rerender_ts");
      if (ts) {
        const age = Date.now() - parseInt(ts, 10);
        isRerender = age < 3000;
        console.log("recordTableStateful: last validate was", age, "ms ago, isRerender =", isRerender);
      }
    } catch { /* ignore */ }

    if (isRerender) {
      console.log("recordTableStateful: re-render detected, preserving state");
      let recordsJson = null;
      try { recordsJson = sessionStorage.getItem(this.storageKey); } catch { /* ignore */ }
      this.effectiveRecordsJson = recordsJson || this.initialRecordsJson || "[]";
      this.restoreState = true;
    } else {
      console.log("recordTableStateful: fresh run, clearing state");
      try {
        sessionStorage.removeItem(this.storageKey);
        sessionStorage.removeItem(this.baseStorageKey);
        sessionStorage.removeItem("RecordTable_rerender_ts");
      } catch { /* ignore */ }
      this.effectiveRecordsJson = this.initialRecordsJson || "[]";
      this.restoreState = false;
    }
  }

  handleTableChange(e) {
    const d = e.detail || {};
    if (!d.updatedRecordsJson) return;
    this.updatedRecordsJson  = d.updatedRecordsJson;
    this.selectedRecordsJson = d.selectedRecordsJson;
    this.hasValidationErrors = !!d.hasValidationErrors;

    try {
      if (d.updatedRecordsJson) {
        sessionStorage.setItem(this.storageKey, d.updatedRecordsJson);
      }
    } catch { /* ignore */ }
  }

  @api
  validate() {
    const table = this.template.querySelector("c-record-table-base");
    if (table && typeof table.validate === "function") {
      const result = table.validate();
      try {
        if (this.updatedRecordsJson) {
          sessionStorage.setItem(this.storageKey, this.updatedRecordsJson);
        }
        // Write timestamp so connectedCallback can detect a re-render
        sessionStorage.setItem("RecordTable_rerender_ts", Date.now().toString());
      } catch { /* ignore */ }
      return result;
    }
    return { isValid: true };
  }
}