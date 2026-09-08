import { LightningElement , api, track, wire } from 'lwc';
import getDataTableColumnsAndRecordsWithQuery from '@salesforce/apex/DataTableServices.getDataTableColumnsAndRecordsWithQuery';
import { flattenObject, flattenQueryResult } from 'c/utilitiesLwc';
import getPickListOptions from '@salesforce/apex/AddProductServices.getPickListOptions';

export default class OliSelectionNewLwc extends LightningElement {
    @api 
    get opportunityId() {
      return this.opportunityRecordId;
    }
    set opportunityId(value) {
      this.opportunityRecordId = value;
    }
    @api
    get recordTypeName() {
       return this.selectedRecordTypeName;
    }
    set recordTypeName(value) {
      this.selectedRecordTypeName = value;
    }

    @track opportunityRecordId;
    @track selectedRecordTypeName = null;
    @track existingOLIData;
    @track existingOLIColumns;
    @track existingOLIDataAvailable = false;
    @track existingOLIQuery;
    @track selectedOLIRecords = [];
    @track fieldOptions = {
      warrantyTermOptions: null
    }
    @track displayWarrantyTerm = null;
    pageInitialized = false;

    renderedCallback() {

      if (this.pageInitialized) {
          return;
      } else {
          this.existingOLIQuery = 'SELECT Id, Product_Name__c, Check_In_Type__c, OpportunityId, Asset_No__c, ProductItem__c, ProductItem__r.Warranty_Term__c' +
                                 ' FROM OpportunityLineItem WHERE OpportunityId =\'' + this.opportunityRecordId + '\' ORDER BY Product_Name__c';
          this.handleGetPickListOptions();  
          
          if (this.selectedRecordTypeName == 'Warranty') {
              this.displayWarrantyTerm = true;
              console.log('display warranty field');
          }

          this.pageInitialized = true;
      }

    }

    
    @wire(getDataTableColumnsAndRecordsWithQuery, {strObjectName: 'OpportunityLineItem', strQueryString: '$existingOLIQuery'})
    wiredExistingRecords({ error, data }) {
        console.log('calling datatable method with query string : ' + this.existingOLIQuery);
      if (data) {
        this.existingOLIColumns = data.lstDataTableColumns;
        this.existingOLIData = flattenQueryResult(data.lstDataTableData);
        this.existingOLIDataAvailable = true;
        for (let record of data.lstDataTableData) { 
          console.log('existing OLI record');
          console.log(record);
        }
      } else if(error) {
        console.log('existing OLI record error: ' + error);
      }
    }

    handleGetPickListOptions() {
      getPickListOptions()
          .then(result => {
            console.log('received data from getPickListOptions imprative method');
            this.fieldOptions.warrantyTermOptions = [];
            let warrantyTermOptions = result.Warranty_Term__c;

            for (let val of warrantyTermOptions) {
              //console.log('warranty term: ' + val);
              let option = {label: String(val), value: String(val)};
              this.fieldOptions.warrantyTermOptions.push(option);
            }

          })
          .catch(TypeError => {
            this.error =  this.getErrorMessage(TypeError);
            console.log('type error occurred in getPickListOptions: ' + this.error);
            return false;
          })
          .catch(error => {
              this.error = this.getErrorMessage(error);
              console.log('error occurred in getPickListOptions: ' + this.error);
              return false;
          });
    }


    handleSelectedLineItems(event) {
      console.log('selected line item event');
      this.selectedOLIRecords.length = 0;
      let isChecked = event.target.checked;
      console.log('isChecked: ' + isChecked);
      let eventRecordId = event.currentTarget.getAttribute("data-value");
      console.log('event record Id: ' + eventRecordId);
      const selectedRecordPosition  = this.existingOLIData.findIndex(oli => oli.Id == eventRecordId);
      console.log('selectedRecordPosition: ' + selectedRecordPosition);

      if (isChecked) {
        console.log('adding line item to list ');
        this.selectedOLIRecords.push(this.existingOLIData[selectedRecordPosition])
        console.log('list size: ' + this.selectedOLIRecords.length);

        this.dispatchEvent(
          new CustomEvent('successoliselection', {detail: flattenQueryResult(this.selectedOLIRecords)})
        );
      }
    }

    handleWarrantyTermChange(event) {
      console.log('warranty term event');
      let eventValue = event.currentTarget.value;
      console.log('event value: ' + eventValue);
      let eventRecordId = event.currentTarget.getAttribute("data-value");
      console.log('event record Id: ' + eventRecordId);
      const selectedRecordPosition  = this.existingOLIData.findIndex(oli => oli.Id == eventRecordId);
      console.log('selectedRecordPosition: ' + selectedRecordPosition);
      let eventRecord = Object.assign({}, JSON.parse(JSON.stringify(this.existingOLIData[selectedRecordPosition])));
      
      console.log('updating record clone');
      console.log('value before update: ' + this.existingOLIData[selectedRecordPosition].ProductItem__r.Warranty_Term__c);
      eventRecord.ProductItem__r.Warranty_Term__c = eventValue;
      
      console.log('updating oli list with updated record');
      this.existingOLIData[selectedRecordPosition] = eventRecord;
      console.log('updated warranty term: ' + this.existingOLIData[selectedRecordPosition].ProductItem__r.Warranty_Term__c);
      

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

    updateFormatting = (listOfObjects) => {
      let newObjects = JSON.parse(JSON.stringify(listOfObjects));
      let elementResult = Object.getOwnPropertyNames(newObjects);

      elementResult.forEach(
          function (attributeIndex) {
            let field = newObjects[attributeIndex];

            if (field.label === 'ProductItem__r Warranty Term') {
                console.log('found warranty term column');
                // applying editable setting to column
                field.editable = true;
                field.label = 'Warranty Term';
            }

          }
      );
    
      return newObjects;
  }

}