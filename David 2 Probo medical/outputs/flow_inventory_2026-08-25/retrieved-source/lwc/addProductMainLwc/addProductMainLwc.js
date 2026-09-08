import { LightningElement, api, wire, track } from 'lwc';

export default class AddProductMainLwc extends LightningElement {
    @api objectRecordId;
    @api action;
    @api objectName;
    @track showOLISelectionPage;
    @track showPRLISelectionPage;
    @track showAddProductPage;
    @track showAddIRProductPage;
    @track localRecordId=null;
    @track localObjectName=null;
    @track localAction=null;
    @track selectedOLIData = [];
    @track selectedPRLIData = [];
    pageInitialized = false;


    connectedCallback() {
      this.localRecordId = this.objectRecordId;
      this.localObjectName = this.objectName;
      this.localAction = this.action;
        
      if (this.action == 'addOppLineItem' || this.action == 'addWorkOrderLineItem' ) {
        this.showAddProductPage = true;
      } else if (this.action == 'swapOppLineItem' || this.action == 'swapAsset'  || this.action == 'addContractLineItem'
        || this.action == 'addItemReceiptLineItem' || this.action == 'addPurchasingReturnLineItem' || this.action == 'addPOBillLineItem') {
        this.showOLISelectionPage = true;
      } else if (this.action == 'addIRProduct') {
        this.showAddIRProductPage = true;
      } 
      else if (this.action == 'swapIRProduct') {
        this.showPRLISelectionPage = true;
      } 

      console.log('record Id in lwc: ' + this.objectRecordId);
      console.log('action in lwc: ' + this.action);
      console.log('object name in lwc: ' + this.objectName);
    }

    renderedCallback() {

    }

    handleOLISelectionComplete(event) {
      console.log('handle OLI selection complete event in main lwc component');

        console.log(event.detail);
        this.selectedOLIData.length = 0;
        const selectedRows = event.detail;
        let tempList = [];
        if (selectedRows.length > 0) {
            console.log('selected OLI data available');
            for (let i = 0; i < selectedRows.length; i++){
              tempList.push(selectedRows[i]);
            }
        }

        this.selectedOLIData = tempList;
        this.showOLISelectionPage = null;
        this.showOLISelectionPage = false;
        this.showAddProductPage = true;
    } 
// product repair line item
    handlePRLISelectionComplete(event) {
      console.log('handle PRLI selection complete event in main lwc component');

        console.log(event.detail);
        this.selectedPRLIData.length = 0;
        const selectedRows = event.detail;
        let tempList = [];
        if (selectedRows.length > 0) {
            console.log('selected PRLI data available');
            for (let i = 0; i < selectedRows.length; i++){
              tempList.push(selectedRows[i]);
              
            }
        }

        this.selectedPRLIData = tempList;
        this.showPRLISelectionPage = null;
        this.showPRLISelectionPage = false; 
        this.showAddIRProductPage = true;
    } 
    
}