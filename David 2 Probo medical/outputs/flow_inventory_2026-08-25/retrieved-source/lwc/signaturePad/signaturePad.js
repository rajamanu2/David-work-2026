import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import SIGNATURE_PAD from '@salesforce/resourceUrl/signature_pad';

const CANVAS_HEIGHT = 180;   // fallback only; real height comes from clientHeight
const MAX_ATTEMPTS = 90;     // ~1.5s of frames before we call it a failure

/**
 * Presentational signature pad: a name input + drawing canvas.
 * No save logic; the parent reads its state via the @api members.
 *
 * Field Service Mobile notes:
 *  - There is no console in the FSM webview, so a failed init is reported on
 *    screen (initError) instead of only to console.error.
 *  - loadScript is a live network fetch. On a weak connection it can reject,
 *    which is the most common cause of an inert pad in the field.
 *  - iOS Low Power Mode throttles requestAnimationFrame, so the layout retry
 *    is bounded and reports failure rather than spinning forever.
 *  - The canvas is re-sized on layout changes (keyboard, rotation, Split View,
 *    Stage Manager) so strokes never land offset from the finger.
 */
export default class SignaturePad extends LightningElement {
    @api label = '';

    signerName = '';
    initError = '';          // rendered in the template when init fails

    _defaultName = '';
    _nameTouched = false;
    _loadStarted = false;
    _ready = false;
    _attempts = 0;
    _pad;
    _resizeObserver;

    /**
     * Pre-fills the name field. Safe to set late (e.g. when an Apex call
     * resolves) — it only seeds the field while the signer has not typed.
     */
    @api
    set defaultName(value) {
        this._defaultName = value || '';
        if (!this._nameTouched && !this.signerName) {
            this.signerName = this._defaultName;
        }
    }
    get defaultName() { return this._defaultName; }

    get nameLabel() { return (this.label ? this.label + ' ' : '') + 'name'; }
    get hasInitError() { return this.initError !== ''; }

    @api getName() { return this.signerName; }

    // True when the pad is genuinely blank. Also true when the pad never
    // started — use isReady to tell those two cases apart.
    @api get isEmpty() { return !this._pad || this._pad.isEmpty(); }

    // Lets the parent distinguish "nothing drawn" from "pad is broken".
    @api get isReady() { return this._ready; }

    // Returns base64 PNG (no data: prefix), or null if nothing usable was exported.
    @api getImageBase64() {
        if (this.isEmpty) return null;
        let url;
        try {
            url = this._pad.toDataURL('image/png');
        } catch (e) {
            return null;
        }
        if (!url || url.indexOf(',') === -1) return null;
        const b64 = url.split(',')[1];
        return (b64 && b64.length > 0) ? b64 : null;
    }

    @api clearPad() { if (this._pad) this._pad.clear(); }

    // Escape hatch: force another init attempt (used by the Retry button).
    @api retryInit() {
        this._attempts = 0;
        this.initError = '';
        if (window.SignaturePad) {
            this.initPad();
            return;
        }
        // Library never arrived — try the fetch again.
        loadScript(this, SIGNATURE_PAD)
            .then(() => this.initPad())
            .catch((e) => this.fail('The signature library could not be loaded. Check your connection and try again.', e));
    }

    renderedCallback() {
        if (this._loadStarted) return;
        this._loadStarted = true;

        // Only the load is guarded here. initPad() does its own error handling
        // so a constructor failure is not misreported as a load failure.
        loadScript(this, SIGNATURE_PAD)
            .then(() => this.initPad())
            .catch((e) => this.fail('The signature library could not be loaded. Check your connection and try again.', e));
    }

    disconnectedCallback() {
        if (this._resizeObserver) {
            this._resizeObserver.disconnect();
            this._resizeObserver = null;
        }
    }

    initPad() {
        if (this._ready) return;

        const canvas = this.template.querySelector('canvas');
        // clientWidth excludes the border, so the backing store matches the
        // drawable area and pointer coordinates line up exactly.
        const w = canvas ? canvas.clientWidth : 0;

        // Canvas not in the DOM yet, or not laid out yet. Both cases retry --
        // giving up on either one is what leaves a permanently inert pad.
        if (!canvas || !w) {
            if (this._attempts++ >= MAX_ATTEMPTS) {
                this.fail('The signature area could not be sized. Close and reopen this window.');
                return;
            }
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            requestAnimationFrame(() => this.initPad());
            return;
        }

        if (!window.SignaturePad) {
            this.fail('The signature library loaded but did not register correctly.');
            return;
        }

        try {
            this.sizeCanvas(canvas);
            this._pad = new window.SignaturePad(canvas, {
                penColor: 'rgb(0, 0, 0)',
                backgroundColor: 'rgb(255, 255, 255)'
            });
            this._ready = true;
            this.initError = '';
            this.observeResize(canvas);
        } catch (e) {
            this.fail('The signature pad could not be started.', e);
        }
    }

    sizeCanvas(canvas) {
        canvas.width = canvas.clientWidth;
        canvas.height = canvas.clientHeight || CANVAS_HEIGHT;
    }

    // Re-size the backing store when the layout changes (on-screen keyboard,
    // rotation, Split View, Stage Manager, Dynamic Type). Without this the
    // canvas keeps its original dimensions and strokes land offset from the
    // finger. Existing strokes survive the resize.
    observeResize(canvas) {
        if (typeof ResizeObserver === 'undefined') return;
        this._resizeObserver = new ResizeObserver(() => this.handleResize(canvas));
        this._resizeObserver.observe(canvas);
    }

    handleResize(canvas) {
        if (!this._pad) return;
        const w = canvas.clientWidth;
        const h = canvas.clientHeight || CANVAS_HEIGHT;
        if (!w) return;                                       // hidden — ignore
        if (w === canvas.width && h === canvas.height) return; // nothing changed

        let data = null;
        try { data = this._pad.toData(); } catch (e) { data = null; }

        this.sizeCanvas(canvas);
        this._pad.clear();

        if (data && data.length) {
            try { this._pad.fromData(data); } catch (e) { /* strokes lost; pad still usable */ }
        }
    }

    fail(message, err) {
        this.initError = message;
        this._ready = false;
        this._pad = undefined;
        // eslint-disable-next-line no-console
        console.error('signaturePad init failed:', message, err);
    }

    handleName(e) {
        this._nameTouched = true;
        this.signerName = e.detail.value;
    }

    handleClear() { this.clearPad(); }
    handleRetry() { this.retryInit(); }
}