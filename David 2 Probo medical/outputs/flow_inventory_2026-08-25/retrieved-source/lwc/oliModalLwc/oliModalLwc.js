import { LightningElement, api, track, wire } from 'lwc';

export default class OliModalLwc extends LightningElement {


    handleContinue(event) {
        this.dispatchEvent(
          new CustomEvent('continuedeselection')
        );
    }

    handleClose(event) {
        this.dispatchEvent(
          new CustomEvent('closemodal')
        );
    }
}