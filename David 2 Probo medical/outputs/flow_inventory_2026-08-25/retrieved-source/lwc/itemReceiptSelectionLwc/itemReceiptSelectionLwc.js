import { LightningElement, api, track, wire } from 'lwc';
import getDataTableColumnsAndRecordsWithQuery from '@salesforce/apex/DataTableServices.getDataTableColumnsAndRecordsWithQuery';
import getProducts from '@salesforce/apex/ItemReceiptLineItemServices.getProducts';
import { flattenObject, flattenQueryResult, addToList,  removeFromList } from 'c/utilitiesLwc';

const EDIT_DELAY = 10;

export default class ItemReceiptSelectionLwc extends LightningElement {
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
    @track existingRecordsData=null;
    @track existingRecordsColumns;
    @track existingRecordsDataAvailable = false;
    @track existingRecordsQuery=null;
    @track selectedRecords = [];
    @track queryObjectName=null;
    @track error;
    pageInitialized = false;

    renderedCallback() {

        if (this.pageInitialized) {
            return;
        } else {
            //this.handleGetQuery();
            this.handleGetProducts();
            this.pageInitialized = true;
        }
  
    }

    /*@wire(getDataTableColumnsAndRecordsWithQuery, {strObjectName:'$queryObjectName', strQueryString: '$existingRecordsQuery'})
    wiredExistingRecords({ error, data }) {
        console.log('calling datatable method with query string : ' + this.existingRecordsQuery);
      if (data) {
        this.existingRecordsColumns = data.lstDataTableColumns;
        this.existingRecordsData = flattenQueryResult(data.lstDataTableData);
        this.existingRecordsDataAvailable = true;

      } else if (error) {
          this.error = this.getErrorMessage(error);
          console.log('existing Records record error: ' + this.error);
      }
    }*/

    handleGetProducts() {
        console.log('calling getProducts method ');
        getProducts({ opportunityId: this.localRecordId })
            .then(result => {
                this.error = undefined;
  
                if (result) {
                    this.existingRecordsData = flattenQueryResult(result);
                    this.existingRecordsDataAvailable = true;
  
                    
                } 
            })
            .catch(TypeError => {
              this.error = this.getErrorMessage(TypeError);
              console.log('type error occurred in getProducts: ' + this.error);
              return false;
            })
            .catch(error => {
                this.error = this.getErrorMessage(error);
                console.log('error occurred in getProducts: ' + this.error);
                return false;
            });    
    } 

    handleSelectedLineItems(event) {
        console.log('selected record event in item receipt component');
        this.selectedRecords.length = 0;

        let isChecked = event.target.checked;
        console.log('isChecked: ' + isChecked);
        let eventRecordId = event.currentTarget.getAttribute("data-value");
        console.log('event record Id: ' + eventRecordId);
        const selectedRecordPosition  = this.existingRecordsData.findIndex(oli => oli.Id == eventRecordId);
        console.log('selectedRecordPosition: ' + selectedRecordPosition);
        let record = this.existingRecordsData[selectedRecordPosition];
        
        if (isChecked) {
            console.log('adding line item to list ');
            this.selectedRecords.push(record);
            console.log('list size: ' + this.selectedRecords.length);
            
        } else {
            removeFromList(this.selectedRecords, record);
        }
         
        this.dispatchEvent(
            new CustomEvent('successrecordselection', {detail: flattenQueryResult(this.selectedRecords)})
        );
        
        
    }

    handleSelectAllLineItems(event) {
        console.log('selected all records event in item receipt component');
        this.selectedRecords.length = 0;
        let isChecked = event.target.checked;
        console.log('isChecked: ' + isChecked);

        let inputComponents = this.template.querySelectorAll("lightning-input");

        if (isChecked) {
            console.log('adding all line items to list ');

            for (let record of this.existingRecordsData) { 
                this.selectedRecords.push(record);
            }
                
            inputComponents.forEach(function(element){
                if (element.type == 'checkbox' && !element.disabled) {
                    console.log('setting checkbox to checked');
                    element.checked = true;
                }    
            },this);    


        } else {
           
            inputComponents.forEach(function(element){
                if (element.type == 'checkbox' && !element.disabled) {
                    console.log('setting checkbox to unchecked');
                    element.checked = false;
                }    
            },this);  
        }  
        
        this.dispatchEvent(
            new CustomEvent('successrecordselection', {detail: flattenQueryResult(this.selectedRecords)})
        );

    }    

    handleCostChange(event) {
        
        console.log('cost change event');
        let eventValue = event.currentTarget.value;
        console.log('event value: ' + eventValue);
        let eventRecordId = event.currentTarget.getAttribute("data-value");
        console.log('event record Id: ' + eventRecordId);
        const selectedRecordPosition  = this.existingRecordsData.findIndex(oli => oli.Id == eventRecordId);
        console.log('selectedRecordPosition: ' + selectedRecordPosition);
        let eventRecord = Object.assign({}, JSON.parse(JSON.stringify(this.existingRecordsData[selectedRecordPosition])));
        
        console.log('updating record clone');
        console.log('value before update: ' + this.existingRecordsData[selectedRecordPosition].Cost__c);
        eventRecord.Cost__c = eventValue;
        
        console.log('updating oli list with updated record');
        this.existingRecordsData[selectedRecordPosition] = eventRecord;
        console.log('updated cost: ' + this.existingRecordsData[selectedRecordPosition].Cost__c);

        const updatedRecordPosition  = this.selectedRecords.findIndex(oli => oli.Id == eventRecordId);
        if (updatedRecordPosition != -1) {
            console.log('updating selected records list');
            let record  = this.selectedRecords[updatedRecordPosition];
            removeFromList(this.selectedRecords, record);
            this.selectedRecords.push(eventRecord);

            this.dispatchEvent(
                new CustomEvent('successrecordselection', {detail: flattenQueryResult(this.selectedRecords)})
            );

        }

        
  
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

    /*handleGetQuery() {
        console.log('calling handleGetQuery in item receipt Selection component');
        if (this.localObjectName == 'Item_Receipt__c') {
          this.queryObjectName = 'ProductItem__c';
          this.existingRecordsQuery = 'SELECT Id, Name, Product2_Name__c, Serial_No__c, Purchasing_Approved__c, Functional_Rating__c,' +
                                 ' Cosmetic_Rating__c, Sold__c, Sales_Price__c, Repair_Value__c, Probo_s_Offer__c, Cost__c, Product_Name__r.Std_Cost_Out__c' +
                                 ' FROM ProductItem__c WHERE Purchasing_Opportunity__c =\'' + this.localRecordId + '\' AND Item_Receipt__c = null' +
                                 ' ORDER BY Product2_Name__c';

          console.log('generated query in handleGetQuery: ' + this.existingRecordsQuery); 
        }  
 
    }*/

    getErrorMessage(error) {
        let errorMessage = 'Unknown error';
        if (Array.isArray(error.body)) {
            errorMessage = error.body.map(e => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
            errorMessage = error.body.message;
        }
  
        return errorMessage;
    }





}