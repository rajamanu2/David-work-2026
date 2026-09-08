import { LightningElement, api, wire, track } from 'lwc';

const DELAY = 10;

export default class SwapItemReceiptProductSelectionsLwc extends LightningElement {
    @api 
    get swapRecords() {
        return this.swapPRLIRecords;
    }
    set swapRecords(value) {
        this.swapPRLIRecords = value;
    }
    @api 
    get itemCount() {
      return this.swapPRLICount;
    }
    set itemCount(value) {
        this.swapPRLICount = value;
        this.handleSwapRecordCheck();
    }    
    @track swapPRLIDataAvailable = false;
    @track swapPRLIRecords = [];
    @track swapPRLICount = 0;
    @track hasIRProductSwapData = null;
    @track hasPRLISwapData = null;

    renderedCallback() {
        if (Number(this.swapPRLICount) > 0) {
            let row = this.swapPRLIRecords[0].originData;
            //console.log('row in swap selections: ' + JSON.stringify(row));
            if (row != undefined && row.hasOwnProperty('Product_Name__c')) {
                this.hasIRProductSwapData = true;
                this.hasPRLISwapData = null;
                console.log('IR Product data available in swap selections '); 
            } else if (row != undefined) {
                this.hasIRProductSwapData = null;
                this.hasPRLISwapData = true;
                console.log('prli data available in swap selections ');
            }
        }    
    }

    handleSwapRecordCheck() {
        if (this.swapPRLICount !== null && Number(this.swapPRLICount) > 0) {
            this.swapPRLIDataAvailable = true;
        } else {
            this.swapPRLIDataAvailable = false;
        }
    }    


}