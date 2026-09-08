import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import saveSignatures from '@salesforce/apex/ServiceSignatureController.saveSignatures';
import markReadyForClose from '@salesforce/apex/ServiceSignatureController.markReadyForClose';
import generateReport from '@salesforce/apex/ServiceReportHtml.generateReport';
import getSignatureContext from '@salesforce/apex/ServiceSignatureController.getSignatureContext';
import getMissingRequiredFields from '@salesforce/apex/ServiceSignatureController.getMissingRequiredFields';

export default class CaptureServiceSignatures extends LightningElement {
    @api recordId;          // Work Order Id, injected by the screen quick action

    phase = 'capture';      // 'capture' | 'working' | 'done'
    busy = false;
    workingMessage = '';
    doneMessage = '';

    preliminary = false;    // Preliminary Service Report: no signatures, no field check, "Prelim" prefix
    checkingFields = false; // true while the required-field gate is running
    fieldsChecked = false;  // true once the gate has returned at least once
    missingFields = [];     // friendly labels of any required fields still empty

    // Pre-fills the Engineer name. Comes back on the same Apex round trip as
    // the required-field gate, so there is no second request and no wire
    // timing to coordinate with the pads appearing.
    engineerDefaultName = '';

    connectedCallback() {
        // Run the gate up front so the signature pads only appear once the
        // Work Order's required fields are complete.
        if (this.recordId) this.loadContext();
    }

    // ----- phase getters -----
    get isCapture() { return this.phase === 'capture'; }
    get isWorking() { return this.phase === 'working'; }
    get isDone()    { return this.phase === 'done'; }

    // ----- capture-screen region getters -----
    get isCheckingFields()    { return this.isCapture && !this.preliminary && this.checkingFields; }
    get hasMissingFields()    { return this.missingFields.length > 0; }
    get showMissingFields()   { return this.isCapture && !this.preliminary && this.fieldsChecked && this.hasMissingFields; }
    get showSignaturePads()   { return this.isCapture && !this.preliminary && this.fieldsChecked && !this.hasMissingFields; }
    get showPreliminaryNote() { return this.isCapture && this.preliminary; }

    get saveLabel()    { return this.preliminary ? 'Generate Preliminary Report' : 'Save & Generate Report'; }
    get canSave()      { return this.preliminary || (this.fieldsChecked && !this.hasMissingFields); }
    get saveDisabled() { return this.busy || !this.canSave; }

    handlePreliminaryChange(event) {
        this.preliminary = event.target.checked;
    }

    // One Apex call for the required-field labels plus the engineer's display
    // name. Not cacheable on purpose: the recovery path is "close, fix the
    // fields, reopen", and a cached response would replay the stale list.
    async loadContext() {
        this.checkingFields = true;
        try {
            const ctx = await getSignatureContext({ workOrderId: this.recordId });
            this.missingFields = (ctx && ctx.missingFields) || [];
            this.engineerDefaultName = (ctx && ctx.engineerName) || '';
            // Missing fields render inline on the page (showMissingFields) — no popup needed.
        } catch (err) {
            // Don't hard-block on a gate failure — surface it and let them proceed/cancel.
            this.missingFields = [];
            this.toast('Could not check required fields: ' + this.reduceErrors(err), 'error');
        } finally {
            this.checkingFields = false;
            this.fieldsChecked = true;
        }
    }

    handleCancel() { this.close(); }

    pad(signer) {
        return this.template.querySelector('c-signature-pad[data-signer="' + signer + '"]');
    }

    /**
     * Returns null when the pad is usable, otherwise a message saying why not.
     * Keeping these cases distinct matters: "pad never started" used to produce
     * the same warning as "you forgot to sign", which sent engineers chasing
     * their own input instead of reporting a broken pad.
     */
    padProblem(pad, who) {
        if (!pad) {
            return 'The ' + who + ' signature pad is missing. Close and reopen this window.';
        }
        if (!pad.isReady) {
            return 'The ' + who + ' signature pad did not start. Check your connection, '
                + 'then use Try again on the pad or reopen this window.';
        }
        if (!pad.getName()) {
            return 'Enter the ' + who + ' name.';
        }
        if (pad.isEmpty) {
            return 'The ' + who + ' signature is required.';
        }
        return null;
    }

    async handleSave() {
        if (this.preliminary) {
            await this.runPreliminary();
        } else {
            await this.runFinal();
        }
    }

    // ----- Preliminary path: no field check, no signatures, "Prelim"-named PDF -----
    async runPreliminary() {
        this.busy = true;
        this.phase = 'working';
        this.workingMessage = 'Generating preliminary report…';
        try {
            await generateReport({ workOrderId: this.recordId, preliminary: true });
            this.doneMessage = 'Preliminary report was added to this Work Order’s Files. '
                + 'No signatures were captured and required fields were not verified.';
        } catch (err) {
            this.doneMessage = 'The preliminary report could not be generated: '
                + this.reduceErrors(err) + ' You can try again later.';
        }
        this.busy = false;
        this.phase = 'done';
    }

    // ----- Final path: gate on required fields, then signatures, then report -----
    async runFinal() {
        // Defensive re-check in case the record changed since the screen opened.
        let missing;
        try {
            missing = await getMissingRequiredFields({ workOrderId: this.recordId });
        } catch (err) {
            this.toast('Could not verify required fields: ' + this.reduceErrors(err), 'error');
            return;
        }
        this.missingFields = missing || [];
        this.fieldsChecked = true;
        if (this.missingFields.length) {
            // Shown inline (showMissingFields); Save is disabled, so just stop here — no popup.
            return;
        }

        const eng = this.pad('engineer');
        const engProblem = this.padProblem(eng, 'engineer');
        if (engProblem) { this.warn(engProblem); return; }
        const engImage = eng.getImageBase64();
        if (!engImage) { this.warn('Could not read the engineer signature — clear and sign again.'); return; }

        const cust = this.pad('customer');
        const custProblem = this.padProblem(cust, 'customer');
        if (custProblem) { this.warn(custProblem); return; }
        const customerImage = cust.getImageBase64();
        if (!customerImage) { this.warn('Could not read the customer signature — clear and sign again.'); return; }
        const customerName = cust.getName();

        this.busy = true;
        this.phase = 'working';

        // Step 1 — save signatures. Must commit before the report can pull the
        // signature images, so this is a separate Apex transaction from step 2.
        this.workingMessage = 'Saving signatures…';
        try {
            await saveSignatures({
                parentId: this.recordId,
                engineerName: eng.getName(),
                engineerImage: engImage,
                customerUnavailable: false,
                customerName: customerName,
                customerImage: customerImage
            });
        } catch (err) {
            this.busy = false;
            this.phase = 'capture';
            this.toast('Save failed: ' + this.reduceErrors(err), 'error');
            return;
        }

        // Step 2 — render the report with Blob.toPdf and file it (synchronous, so
        // when this resolves the PDF is already on the Work Order).
        this.workingMessage = 'Generating report…';
        try {
            await generateReport({ workOrderId: this.recordId, preliminary: false });
            this.doneMessage = 'Signatures saved and the service report was added to this Work Order’s Files.';
        } catch (err) {
            this.doneMessage = 'Signatures saved, but the report could not be generated: '
                + this.reduceErrors(err) + ' The signatures are recorded; you can regenerate the report later.';
        }

        // Final (non-preliminary) submissions advance the Work Order.
        this.workingMessage = 'Updating Work Order status…';
        try {
            await markReadyForClose({ workOrderId: this.recordId });
            this.doneMessage += ' The Work Order was moved to “Ready for Close.”';
        } catch (err) {
            this.doneMessage += ' (The status could not be set to “Ready for Close”: '
                + this.reduceErrors(err) + ')';
        }

        this.busy = false;
        this.phase = 'done';
    }

    reduceErrors(err) {
        if (!err) return 'Unknown error';
        if (Array.isArray(err.body)) {
            return err.body.map((e) => e.message).filter(Boolean).join(', ') || 'Unknown error';
        }
        if (err.body && typeof err.body.message === 'string' && err.body.message) return err.body.message;
        if (err.body && Array.isArray(err.body.pageErrors) && err.body.pageErrors.length) {
            return err.body.pageErrors.map((e) => e.message).join(', ');
        }
        if (typeof err.message === 'string' && err.message) return err.message;
        try { return JSON.stringify(err.body || err); } catch (e) { return 'Unknown error'; }
    }

    handleClose() { this.close(); }
    close() { this.dispatchEvent(new CloseActionScreenEvent()); }
    warn(m) { this.toast(m, 'warning'); }
    toast(message, variant) { this.dispatchEvent(new ShowToastEvent({ title: message, variant })); }
}