import { LightningElement, api, track, wire } from 'lwc';
import getProductRepairLineItemsQuery from '@salesforce/apex/AddIRProductServices.getProductRepairLineItemsQuery';
import getDataTableColumnsAndRecordsWithQuery from '@salesforce/apex/DataTableServices.getDataTableColumnsAndRecordsWithQuery';

export default class PrliSelectionLwc extends LightningElement {

    @api 
    get parentId() {
      return this.productRepairRecordId;
    }
    set parentId(value) {
      this.productRepairRecordId = value;
    }

    @track productRepairRecordId;
    @track existingPRLIData;
    @track existingPRLIColumns;
    @track existingPRLIDataAvailable = false;
    @track existingPRLIQuery;
    @track selectedPRLIRecords = [];
    
    @wire(getProductRepairLineItemsQuery, {productRepairId: '$productRepairRecordId'})  
    wiredExistingPRLIQuery({ error, data }) {
        console.log('calling query method with id: ' + this.productRepairRecordId);
       if (data) {
        this.existingPRLIQuery = data;
         console.log('existing PRLI query');
         console.log(data);
        } else if(error) {
          console.log('existing PRLI query error: ' + error);
        }
    }

    @wire(getDataTableColumnsAndRecordsWithQuery, {strObjectName: 'Product_Repair_Line_Item__c', strQueryString: '$existingPRLIQuery'})
    wiredExistingRecords({ error, data }) {
        console.log('calling datatable method with query string : ' + this.existingPRLIQuery);
      if (data) {
        this.existingPRLIColumns = data.lstDataTableColumns;
        this.existingPRLIData = data.lstDataTableData;
        this.existingPRLIDataAvailable = true;
        for (let record of data.lstDataTableData) { 
          console.log('existing PRLI record');
          console.log(record);
        }
      } else if(error) {
        console.log('existing PRLI record error: ' + error);
      }
    }

    handleSelectedLineItems(event) {
        console.log('edit selected line item event');
        this.selectedPRLIRecords.length = 0;
        console.log(event.detail.selectedRows);
        const selectedRows = event.detail.selectedRows;
        
        for (let i = 0; i < selectedRows.length; i++){
            console.log("You selected: " + selectedRows[i].Id);
            this.selectedPRLIRecords.push(selectedRows[i].Id);
        }
         
        this.dispatchEvent(
          new CustomEvent('successprliselection', {detail: this.flattenQueryResult(selectedRows)})
        );
        
    }

    handleNext(event) {
      this.dispatchEvent(
        new CustomEvent('prliselectioncomplete')
      );
    }

    handleCancel(event) {
        var url = '/' + this.productRepairRecordId;
        console.log('cancel event');
           // TO DO: Update Navigation once we migrate to Lightning
           // this[NavigationMixin.Navigate]({
           //     type: 'standard__recordPage',
           //     attributes: {
           //         recordId: '$opportunityRecordId',
           //         objectApiName: 'Opportunity',
           //         actionName: 'view'
           //     }
           // });
        window.location.href = url;
    }


    flattenQueryResult = (listOfObjects) => {
      let finalArr = [];
      for (let i=0; i<listOfObjects.length; i++) {
        let obj = listOfObjects[i];
        for (let prop in obj) {
          if (!obj.hasOwnProperty(prop)) {
            continue;
          }
          if (typeof obj[prop] == 'object') {
            obj = {...obj, ...this.flattenObject(prop, obj[prop])};
          
        }
        finalArr.push(obj);
      }
      return finalArr;
  }
}
  flattenObject = (propName, obj) => {
      let flatObject = {};
      for (let prop in obj) {
        if (prop) {
          //if this property is an object, we need to flatten again
          let propIsNumber = isNaN(propName);
          let preAppend = propIsNumber ? propName+'_' : '';
  
          if (typeof obj[prop] == 'object') {
            flatObject[preAppend+prop] = {...flatObject, ...this.flattenObject(preAppend+prop,obj[prop])};
          } else {
            flatObject[preAppend+prop] = obj[prop];
          }
        }
      }
      return flatObject;
  }
}