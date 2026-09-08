import { LightningElement, api, wire, track } from 'lwc';

export default class OliPaginator extends LightningElement {
    @api 
    get oliRecords() {
      return this.opportunityRecordId;
    }
    set oliRecords(value) {
        for (let i = 0; i < value.length; i++){
            this.selectedOLIRecords.push(value[i]);
            
        }
    }
  
    @track selectedOLIRecords = [];
    @track currentPosition = 0;
    @track currentOLIRecord;
    @track numberOfRecords;
    @track hasAssetSwapData = null;
    @track hasOLISwapData = null;
    @track pageTitle = null;
    

    connectedCallback() {
        this.currentOLIRecord= this.getRecord(this.selectedOLIRecords);
        // eslint-disable-next-line no-console
        console.log('current record in paginator: ' + this.currentOLIRecord);
        this.numberOfRecords = this.selectedOLIRecords.length; 
        console.log('number of records: ' + this.numberOfRecords);
    }

    renderedCallback() {
        let row = this.currentOLIRecord;
        console.log('row in paginator: ' + JSON.stringify(row));
        if (row != undefined && row.hasOwnProperty('Product2_Name__c')) {
              this.hasAssetSwapData = true;
              this.hasOLISwapData = null;
              this.pageTitle = 'Current Asset'; 
              console.log('asset data available in paginator '); 
        } else if (row != undefined) {
              this.hasAssetSwapData = null;
              this.hasOLISwapData = true;
              this.pageTitle = 'Current Opportunity Line Item'; 
              console.log('oli data available in paginator ');
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
            this.currentOLIRecord = this.getRecord(this.selectedOLIRecords);
            this.dispatchEvent(new CustomEvent('previous', {detail: this.currentPosition}));
        }
        
    }

    nextHandler() {
        var newPosition = this.currentPosition + 1;
        if (newPosition <= (this.numberOfRecords - 1)) {
            this.currentPosition = newPosition;
            this.currentOLIRecord = this.getRecord(this.selectedOLIRecords);
            this.dispatchEvent(new CustomEvent('next', {detail: this.currentPosition}));
        }
        
    }
}