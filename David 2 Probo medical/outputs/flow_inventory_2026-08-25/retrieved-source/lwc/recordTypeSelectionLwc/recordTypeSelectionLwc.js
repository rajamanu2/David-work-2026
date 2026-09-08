import { LightningElement , api, track, wire } from 'lwc';
import getRecordTypePickListValues from '@salesforce/apex/RecordTypeUtility.getRecordTypePickListValues';

export default class RecordTypeSelectionLwc extends LightningElement {
    @api 
    get name() {
      return this.localObjectName;
    }
    set name(value) {
        this.localObjectName = value;
        console.log('local object name in record type component: ' + this.localObjectName);
    }
    @api 
    get parentId() {
      return this.localRecordId;
    }
    set parentId(value) {
        this.localRecordId = value;
    }

    @track localObjectName = null;
    @track localRecordId = null;
    @track fieldOptions = {
        recordTypeOptions: null,
        recordTypeMap: null
    }
    @track selectedRecordTypeId = null;
    @track selectedRecordTypeName = null;
    pageInitialized = false;

    renderedCallback() {

        if (this.pageInitialized) {
            return;
        } else {
            this.handleGetRecordTypePickListOptions();                       
            this.pageInitialized = true;
        }
  
    }

    handleGetRecordTypePickListOptions() {
        getRecordTypePickListValues({sObjectName: this.localObjectName})
            .then(result => {
              console.log('received data from getRecordTypePickListValues imprative method');
              this.fieldOptions.recordTypeOptions = [];
              this.fieldOptions.recordTypeMap = new Map();
              let recordTypeOptions = result;
  
              for (let opt of recordTypeOptions) {
                console.log('record type: ' + opt.label);
                if (opt.label !== 'Master') {
                    let fieldOption = {label: String(opt.label), value: String(opt.value)};
                    this.fieldOptions.recordTypeOptions.push(fieldOption);
                    this.fieldOptions.recordTypeMap.set(String(opt.value), String(opt.label));
                }
              }
  
            })
            .catch(TypeError => {
              this.error =  this.getErrorMessage(TypeError);
              console.log('type error occurred in getRecordTypePickListValues: ' + this.error);
              return false;
            })
            .catch(error => {
                this.error = this.getErrorMessage(error);
                console.log('error occurred in getRecordTypePickListValues: ' + this.error);
                return false;
            });
    }

    handleRecordTypeChange(event) {
        let eventValue = event.detail.value;
        this.selectedRecordTypeId = eventValue;
        console.log('selected record type Id: ' + eventValue);
        this.selectedRecordTypeName = this.fieldOptions.recordTypeMap.get(String(eventValue));
        console.log('selected record type Name: ' + this.selectedRecordTypeName);

        let recordType = {
            id: this.selectedRecordTypeId,
            name: this.selectedRecordTypeName
        };
        
        this.dispatchEvent(
            new CustomEvent('successrecordtypeselection', {detail: recordType})
        );

    }    

    handleNext(event) {
        this.dispatchEvent(
          new CustomEvent('recordtypeselectioncomplete')
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