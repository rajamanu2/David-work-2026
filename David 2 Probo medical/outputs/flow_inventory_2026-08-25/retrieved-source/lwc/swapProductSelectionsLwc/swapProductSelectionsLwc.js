import { LightningElement, api, wire, track } from 'lwc';

const DELAY = 10;

export default class SwapProductSelectionsLwc extends LightningElement {
    @api 
    get swapRecords() {
        return this.swapOLIRecords;
    }
    set swapRecords(value) {
        this.swapOLIRecords = value;
    }
    @api 
    get itemCount() {
      return this.swapOLICount;
    }
    set itemCount(value) {
        this.swapOLICount = value;
        this.handleSwapRecordCheck();
    }    
    @track swapOLIDataAvailable = false;
    @track swapOLIRecords = [];
    @track swapOLICount = 0;
    @track hasAssetSwapData = null;
    @track hasOLISwapData = null;

    renderedCallback() {
        if (Number(this.swapOLICount) > 0) {
            let row = this.swapOLIRecords[0].originData;
            //console.log('row in swap selections: ' + JSON.stringify(row));
            if (row != undefined && row.hasOwnProperty('Product2_Name__c')) {
                this.hasAssetSwapData = true;
                this.hasOLISwapData = null;
                console.log('asset data available in swap selections '); 
            } else if (row != undefined) {
                this.hasAssetSwapData = null;
                this.hasOLISwapData = true;
                console.log('oli data available in swap selections ');
            }
        }    
    }

    handleSwapRecordCheck() {
        if (this.swapOLICount !== null && Number(this.swapOLICount) > 0) {
            this.swapOLIDataAvailable = true;
        } else {
            this.swapOLIDataAvailable = false;
        }
    }    


}