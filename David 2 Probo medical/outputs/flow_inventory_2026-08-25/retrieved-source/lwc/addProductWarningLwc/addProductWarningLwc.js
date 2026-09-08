import { LightningElement, api, track  } from 'lwc';

export default class AddProductWarningLwc extends LightningElement {

    @api 
    get header() {
      return this.warningHeader;
    }
    set header(value) {
        this.warningHeader = value;
    }

    @api 
    get message() {
      return this.warningMessage;
    }
    set message(value) {
        this.warningMessage = value;
    }

    @api 
    get showConfirm() {
      return this.displayConfimationButton;
    }
    set showConfirm(value) {
      this.displayConfimationButton = value;
    }

    @api 
    get cancelLabel() {
      return this.cancelButtonLabel;
    }
    set cancelLabel(value) {
      this.cancelButtonLabel = value;
    }

    @track warningHeader;
    @track warningMessage;
    @track displayConfimationButton;
    @track cancelButtonLabel;


    handleConfirm(event) {
      this.dispatchEvent(
        new CustomEvent('confirmmessage')
      );
    }

    handleClose(event) {
        this.dispatchEvent(
          new CustomEvent('closemessage')
        );
    }
}