import { LightningElement, api, track, wire } from 'lwc';
import getDataTableColumnsAndRecordsWithQuery from '@salesforce/apex/DataTableServices.getDataTableColumnsAndRecordsWithQuery';
import { flattenObject, flattenQueryResult, addToList,  removeFromList } from 'c/utilitiesLwc';

export default class RecordSelectionLwc extends LightningElement {
    @api 
    get parentId() {
      return this.localRecordId;
    }
    set parentId(value) {
        this.localRecordId = value;
        console.log('Id passed in to record selection lwc component: ' + value);
    }

    @api 
    get name() {
      return this.localObjectName;
    }
    set name(value) {
        this.localObjectName = value;
    }
    
    @api 
    get action() {
      return this.localAction;
    }
    set action(value) {
        this.localAction = value;
        console.log('action passed in to record selection lwc component: ' + value);
    }

    @track localRecordId=null;
    @track localObjectName=null;
    @track localAction=null;
    @track existingRecordsData;
    @track existingRecordsColumns;
    @track existingRecordsDataAvailable = false;
    @track existingRecordsQuery=null;
    @track selectedRecords = [];
    @track queryObjectName=null;
    pageInitialized = false;

    renderedCallback() {

        if (this.pageInitialized) {
            return;
        } else {
            this.handleGetQuery();
            this.pageInitialized = true;
        }
  
    }

    @wire(getDataTableColumnsAndRecordsWithQuery, {strObjectName:'$queryObjectName', strQueryString: '$existingRecordsQuery'})
    wiredExistingRecords({ error, data }) {
        console.log('calling datatable method with query string : ' + this.existingRecordsQuery);
      if (data) {
        this.existingRecordsColumns = data.lstDataTableColumns;
        this.existingRecordsData = flattenQueryResult(data.lstDataTableData);
        this.existingRecordsDataAvailable = true;
        

        
      } else if(error) {
        console.log('existing Records record error: ' + error);
      }
    }

    handleSelectedLineItems(event) {
        console.log('selected record event in records component');
        this.selectedRecords.length = 0;
        console.log(event.detail.selectedRows);
        const selectedRows = event.detail.selectedRows;
         
        this.dispatchEvent(
          new CustomEvent('successrecordselection', {detail: flattenQueryResult(selectedRows)})
        );
        
    }

    handleNext(event) {
       console.log(' record selection completed event in records component');
      this.dispatchEvent(
        new CustomEvent('recordselectioncomplete')
      );
    }

    handleCancel(event) {
        var url = '/' + this.localRecordId;
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

    handleGetQuery() {
        console.log('calling handleGetQuery in recordSelection component');
        if (this.localObjectName == 'Loaner__c') {
            this.queryObjectName = 'ProductItem__c';
            this.existingRecordsQuery = 'SELECT Id, Name, Product2_Name__c' +
                                   ' FROM ProductItem__c WHERE Id IN (SELECT ProductItem__c FROM Loaner_Asset__c' +
                                   ' WHERE Loaner__c =\'' + this.localRecordId + '\') ORDER BY Product2_Name__c';

            console.log('generated query in handleGetQuery: ' + this.existingRecordsQuery);                        
        } else if (this.localObjectName == 'Rental_Order__c') {
          this.queryObjectName = 'ProductItem__c';
          this.existingRecordsQuery = 'SELECT Id, Name, Product2_Name__c' +
                                 ' FROM ProductItem__c WHERE Id IN (SELECT ProductItem__c FROM Rental_Order_Asset__c' +
                                 ' WHERE Rental_Order__c =\'' + this.localRecordId + '\') ORDER BY Product2_Name__c';

          console.log('generated query in handleGetQuery: ' + this.existingRecordsQuery);                        
        } else if (this.localObjectName == 'Purchasing_Return__c') {
          this.queryObjectName = 'ProductItem__c';
          this.existingRecordsQuery = 'SELECT Id, Name, Serial_No__c, Product2_Name__c, Purchasing_Approved__c, Functional_Rating__c,' +
                                 ' Cosmetic_Rating__c, Sold__c, Sales_Price__c, Repair_Value__c, Cost__c' +
                                 ' FROM ProductItem__c WHERE Purchasing_Opportunity__c =\'' + this.localRecordId + '\' AND Purchasing_Approved__c = true' +
                                 ' AND Purchasing_Return__c = null ORDER BY Product2_Name__c';

          console.log('generated query in handleGetQuery: ' + this.existingRecordsQuery); 
        } else if (this.localObjectName == 'PO_Bill__c') {
          this.queryObjectName = 'ProductItem__c';
          this.existingRecordsQuery = 'SELECT Id, Name, Product2_Name__c, Item_Receipt__c, Item_Receipt__r.Name' +
                                ' FROM ProductItem__c WHERE Purchasing_Opportunity__c =\'' + this.localRecordId + '\' AND Item_Receipt__c != null' +
                                ' ORDER BY Product2_Name__c';

          console.log('generated query in handleGetQuery: ' + this.existingRecordsQuery);                       
        }
 
    }

     

}