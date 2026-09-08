import { LightningElement, api, wire, track } from 'lwc';

export default class ItemReceiptProductPaginatorLwc extends LightningElement {
    @api 
    get prliRecords() {
      return this.productRepairRecordId;
    }
    set prliRecords(value) {
        for (let i = 0; i < value.length; i++){
            this.selectedPRLIRecords.push(value[i]);
            
        }
    }
  
    @track selectedPRLIRecords = [];
    @track currentPosition = 0;
    @track currentPRLIRecord;
    @track numberOfRecords;
    @track hasIRProductSwapData = null;
    @track hasPRLISwapData = null;
    @track pageTitle = null;
    

    connectedCallback() {
        this.currentPRLIRecord= this.getRecord(this.selectedPRLIRecords);
        // eslint-disable-next-line no-console
        console.log('current record in paginator: ' + this.currentPRLIRecord);
        this.numberOfRecords = this.selectedPRLIRecords.length; 
        console.log('number of records: ' + this.numberOfRecords);
    }

    renderedCallback() {
        let row = this.currentPRLIRecord;
        console.log('row in paginator: ' + JSON.stringify(row));
        if (row != undefined && row.hasOwnProperty('Product_Name__c')) {
              this.hasIRProductSwapData = true;
              this.hasPRLISwapData = null;
              this.pageTitle = 'Current IR Product'; 
              console.log('IR Product data available in paginator '); 
        } else if (row != undefined) {
              this.hasIRProductSwapData = null;
              this.hasPRLISwapData = true;
              this.pageTitle = 'Current Product Repair Line Item'; 
              console.log('prli data available in paginator ');
        }
    }

    getRecord = (listOfObjects) => {
        let obj;
        if (listOfObjects.length > 0) {
            obj = listOfObjects[this.currentPosition];
        }
        return obj;
    }    

    previousHandler() {
        var newPosition = this.currentPosition - 1;
        if (newPosition >= 0) {
            this.currentPosition = newPosition;
            this.currentPRLIRecord = this.getRecord(this.selectedPRLIRecords);
            this.dispatchEvent(new CustomEvent('previous', {detail: this.currentPosition}));
        }
        
    }

    nextHandler() {
        var newPosition = this.currentPosition + 1;
        if (newPosition <= (this.numberOfRecords - 1)) {
            this.currentPosition = newPosition;
            this.currentPRLIRecord = this.getRecord(this.selectedPRLIRecords);
            this.dispatchEvent(new CustomEvent('next', {detail: this.currentPosition}));
        }
        
    }
}