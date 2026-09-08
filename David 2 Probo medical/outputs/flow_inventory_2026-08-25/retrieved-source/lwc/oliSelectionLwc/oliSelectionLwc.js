import { LightningElement, api, track, wire } from 'lwc';
import getOpportunityLineItemsQuery from '@salesforce/apex/OpportunityLineItemServices.getOpportunityLineItemsQuery';
import getDataTableColumnsAndRecordsWithQuery from '@salesforce/apex/DataTableServices.getDataTableColumnsAndRecordsWithQuery';

export default class OliSelectionLwc extends LightningElement {

    @api 
    get opportunityId() {
      return this.opportunityRecordId;
    }
    set opportunityId(value) {
      this.opportunityRecordId = value;
    }

    @track opportunityRecordId;
    @track existingOLIData;
    @track existingOLIColumns;
    @track existingOLIDataAvailable = false;
    @track existingOLIQuery;
    @track selectedOLIRecords = [];
    
    @wire(getOpportunityLineItemsQuery, {opportunityId: '$opportunityRecordId'})  
    wiredExistingOLIQuery({ error, data }) {
        console.log('calling query method with id: ' + this.opportunityRecordId);
       if (data) {
        this.existingOLIQuery = data;
         console.log('existing OLI query');
         console.log(data);
        } else if(error) {
          console.log('existing OLI query error: ' + error);
        }
    }

    @wire(getDataTableColumnsAndRecordsWithQuery, {strObjectName: 'OpportunityLineItem', strQueryString: '$existingOLIQuery'})
    wiredExistingRecords({ error, data }) {
        console.log('calling datatable method with query string : ' + this.existingOLIQuery);
      if (data) {
        this.existingOLIColumns = data.lstDataTableColumns;
        this.existingOLIData = data.lstDataTableData;
        this.existingOLIDataAvailable = true;
        for (let record of data.lstDataTableData) { 
          console.log('existing OLI record');
          console.log(record);
        }
      } else if(error) {
        console.log('existing OLI record error: ' + error);
      }
    }

    handleSelectedLineItems(event) {
        console.log('edit selected line item event');
        this.selectedOLIRecords.length = 0;
        console.log(event.detail.selectedRows);
        const selectedRows = event.detail.selectedRows;
        
        for (let i = 0; i < selectedRows.length; i++){
            console.log("You selected: " + selectedRows[i].Id);
            this.selectedOLIRecords.push(selectedRows[i].Id);
        }
         
        this.dispatchEvent(
          new CustomEvent('successoliselection', {detail: this.flattenQueryResult(selectedRows)})
        );
        
    }

    handleNext(event) {
      this.dispatchEvent(
        new CustomEvent('oliselectioncomplete')
      );
    }

    handleCancel(event) {
        var url = '/' + this.opportunityRecordId;
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
          if (typeof obj[prop] == 'object' && typeof obj[prop] != 'Array') {
            obj = {...obj, ...this.flattenObject(prop, obj[prop])};
          } else if (typeof obj[prop] == 'Array') {
            for (let j=0; j<obj[prop].length; j++) {
              obj[prop+'_'+j] = {...obj, ...this.flattenObject(prop,obj[prop])};
            }
          }
        }
        finalArr.push(obj);
      }
      return finalArr;
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