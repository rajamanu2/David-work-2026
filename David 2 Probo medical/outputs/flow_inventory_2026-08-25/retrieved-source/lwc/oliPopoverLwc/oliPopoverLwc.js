import { LightningElement, api, track  } from 'lwc';
import getFieldNames from '@salesforce/apex/DataTableServices.getFieldNames';


export default class OliPopover extends LightningElement {
    @api 
    get hoverRecordId() {
      return this.currentRecordId;
    }
    set hoverRecordId(value) {
        this.currentRecordId = value;
    }

    @api 
    get topMargin() {
      return this.top;
    }
    set topMargin(value) {
        this.top = value;
    }
    
    @api 
    get leftMargin() {
      return this.left;
    }
    set leftMargin(value) {
        this.left = value;
    }

    @api 
    get permissionSetName() {
      return this.currentPermissionSetName;
    }
    set permissionSetName(value) {
        this.currentPermissionSetName = value;
        if (this.currentPermissionSetName) {
          this.isDynamic=true;
          this.handleColumnsToShow();
        }
    }
    
    
    @track currentRecordId;
    @track top;
    @track left;
    @track currentPermissionSetName;
    @track isDynamic = false;
    @track columnsToShow;


    connectedCallback() {

      //if (this.currentPermissionSetName) {
      //  this.isDynamic=true;
      //  this.handleColumnsToShow();
      //}

    }  

    get boxClass() { 
        return `background-color:white; top:${this.top - 380}px; left:${this.left}px; position: absolute; height: auto; width: 800px;`;
    }
    
    handleColumnsToShow() {
      var permissionSetName = this.currentPermissionSetName;

      getFieldNames({ strObjectName: 'ProductItem__c', strFieldSetName: permissionSetName })
          .then(fieldResult => {
              this.error = undefined;
              
              if (fieldResult && fieldResult.length > 0) {
                this.columnsToShow = fieldResult;
              } 
          })
          .catch(error => {
              this.error = error;
              console.log('error occurred in column retrieval (popover): ' + this.error);
          });
        

      }

}