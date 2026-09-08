import { LightningElement, api, track } from 'lwc';

export default class FslEditModal extends LightningElement {
    @api variant = 'po';
    @api saving = false;
    @api shippingAddressOptions = [];
    @track poNumber = '';
    @track addressMode = 'saved';
    @track addressSelection = '';
    @track addressForm = { street: '', city: '', state: '', country: 'United States', postalCode: '' };
    addressModeOptions = [
        { label: 'Use saved address', value: 'saved' },
        { label: 'Enter manually', value: 'manual' }
    ];

    @api
    set initialData(value) {
        const data = value || {};
        this.poNumber = data.poNumber || '';
        this.addressMode = data.addressMode || 'saved';
        this.addressSelection = data.addressSelection || '';
        this.addressForm = {
            street: data.addressForm?.street || '',
            city: data.addressForm?.city || '',
            state: data.addressForm?.state || '',
            country: data.addressForm?.country || 'United States',
            postalCode: data.addressForm?.postalCode || ''
        };
    }

    get showPo() { return this.variant === 'po'; }
    get showAddress() { return this.variant === 'address'; }
    get modalTitle() { return this.showPo ? 'Update PO Number' : 'Add address'; }
    get showSavedAddressOption() {
        return this.showAddress && this.shippingAddressOptions?.length > 0 && this.addressMode === 'saved';
    }
    get showManualAddressOption() { return this.showAddress && this.addressMode === 'manual'; }

    handleClose() { this.dispatchEvent(new CustomEvent('cancel')); }
    stopPropagation(event) { event.stopPropagation(); }

    handlePoKeydown(event) {
        if (event.key === 'Enter') {
            event.preventDefault();
            this.handleSave();
        }
    }

    handleAddressModeChange(event) { this.addressMode = event.detail.value; }
    handleAddressSelection(event) {
        this.addressSelection = event.detail?.value || '';
        const match = (this.shippingAddressOptions || []).find(opt => opt.value === this.addressSelection);
        if (match && match.addressData) {
            this.addressForm = { ...match.addressData };
        }
    }
    handleSave() {
        const poInput = this.template.querySelector('lightning-input[name="poNumber"]');
        if (poInput) {
            this.poNumber = poInput.value || '';
        }
        const addressSelectionInput = this.template.querySelector(
            'lightning-combobox[name="addressSelection"]'
        );
        if (addressSelectionInput) {
            this.addressSelection = addressSelectionInput.value || '';
        }
        const streetInput = this.template.querySelector('lightning-textarea[name="street"]');
        const cityInput = this.template.querySelector('lightning-input[name="city"]');
        const stateInput = this.template.querySelector('lightning-input[name="state"]');
        const countryInput = this.template.querySelector('lightning-input[name="country"]');
        const postalInput = this.template.querySelector('lightning-input[name="postalCode"]');
        if (streetInput || cityInput || stateInput || countryInput || postalInput) {
            this.addressForm = {
                street: streetInput ? streetInput.value || '' : this.addressForm.street || '',
                city: cityInput ? cityInput.value || '' : this.addressForm.city || '',
                state: stateInput ? stateInput.value || '' : this.addressForm.state || '',
                country: countryInput ? countryInput.value || '' : this.addressForm.country || '',
                postalCode: postalInput ? postalInput.value || '' : this.addressForm.postalCode || ''
            };
        }
        this.dispatchEvent(new CustomEvent('save', {
            detail: {
                variant: this.variant,
                poNumber: this.poNumber,
                addressMode: this.addressMode,
                addressSelection: this.addressSelection,
                addressForm: this.addressForm
            }
        }));
    }
}