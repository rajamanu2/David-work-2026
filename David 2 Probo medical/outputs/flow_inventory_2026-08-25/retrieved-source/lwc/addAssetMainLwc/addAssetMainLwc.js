import { LightningElement, api, wire, track } from 'lwc';

export default class AddAssetMainLwc extends LightningElement {
    @api objectRecordId;
    @api action;
    @api objectName;
    @track showAddAssetSearchPage;
    @track localRecordId=null;
    @track localObjectName=null;
    @track localAction=null;
    @track selectedOLIData = [];
    pageInitialized = false;


    connectedCallback() {
      this.localRecordId = this.objectRecordId;
      this.localObjectName = this.objectName;
      this.localAction = this.action;
        
      if (this.action == 'addAsset') {
          this.showAddAssetSearchPage = true;
      } 
      console.log('record Id in lwc: ' + this.objectRecordId);
      console.log('action in lwc: ' + this.action);
      console.log('object name in lwc: ' + this.objectName);
    }




}