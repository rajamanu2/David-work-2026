import { LightningElement, api, wire, track } from 'lwc';
import { flattenObject, flattenQueryResult } from 'c/utilitiesLwc';
import getLoanerInfo from '@salesforce/apex/AddProductServices.getLoanerInfo';
import getRentalOrderInfo from '@salesforce/apex/AddProductServices.getRentalOrderInfo';
// temporarily disabled for deployment
//import createServiceContractLineItems from '@salesforce/apex/ServiceContractLineItemServices.createServiceContractLineItems';
import createItemReceiptLineItems from '@salesforce/apex/ItemReceiptLineItemServices.createItemReceiptLineItems';
import createPurchasingReturnLineItems from '@salesforce/apex/PurchasingReturnLineItemServices.createPurchasingReturnLineItems';
import createPOBill from '@salesforce/apex/POBillLineItemServices.createPOBill';
import createPOBillLineItems from '@salesforce/apex/POBillLineItemServices.createPOBillLineItems'

const DELAY = 2;

export default class ExistingLineItemLwc extends LightningElement {
    @api 
    get parentId() {
      return this.localRecordId;
    }
    set parentId(value) {
        this.localRecordId = value;
        console.log('Id passed in to existing line item lwc component: ' + value);
        //this.hideSpinner = true;
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
    }
    @track localRecordId = null;
    @track localObjectName = null;
    @track localAction = null;
    @track localOpportunityId = null;
    @track hideSpinner = false;
    @track displayRecordTypeSelection = false;
    @track displayLineItemSelection = false;
    @track selectedOLIData = [];
    @track selectedRecordTypeId = null;
    @track selectedRecordTypeName = null;
    @track recordTypeSelectionComplete = null;
    @track error;
    @track messages = {
        warningMessage: null,
        warningHeader: null,
        warningMessageAvailable: false,
        closeButtonLabel: null,
        showConfirmationButton: false
    }
    @track isProcessing = null;
    pageInitialized = false;

    renderedCallback() {
        

        if (this.pageInitialized) {
          return;
        } else {
            if (this.localObjectName == 'Opportunity') {
                console.log('Opportunity object. Use local record Id as opportunity Id.');
                this.localOpportunityId = this.localRecordId
            } else if (this.localObjectName == 'Loaner__c') {
                console.log('Loaner object. Need to fetch opportunity Id.');
                this.handleGetLoanerInfo();
            } else if (this.localObjectName == 'Rental_Order__c') {
                console.log('Rental Order object. Need to fetch opportunity Id.');
                this.handleGetRentalOrderInfo();
            }  else {
                console.log('Local object. ' + this.localObjectName);
            }  
               
            console.log('Local action in existing line item component:. ' + this.localAction);

            if (this.localAction == 'addContractLineItem' || this.localAction == 'addPurchasingReturnLineItem' || this.localAction == 'addPOBillLineItem') {
                this.delayTimeout = setTimeout(() => {
                    this.displayRecordTypeSelection = null;
                    this.displayRecordTypeSelection = true;
                }, DELAY);
            }    
            
            this.pageInitialized = true;
            this.hideSpinner = true;
  
        }
  
  
    }

    handleGetLoanerInfo() {
        getLoanerInfo({ loanerId: this.localRecordId })
            .then(result => {
                this.error = undefined;
  
                if (result) {
                    let loanerRecord = result;
  
                    if (loanerRecord.hasOwnProperty('opportuntyId')) {
                        this.localOpportunityId = loanerRecord.opportuntyId;
                        console.log('opportunity Id: ' + this.localOpportunityId );
                    }  
  
                    this.hideSpinner = true;
                } 
            })
            .catch(TypeError => {
              this.error = this.getErrorMessage(TypeError);
              console.log('type error occurred in getLoanerInfo: ' + this.error);
              return false;
            })
            .catch(error => {
                this.error = this.getErrorMessage(error);
                console.log('error occurred in getLoanerInfo: ' + this.error);
                return false;
            });    
    }  

    handleGetRentalOrderInfo() {
        getRentalOrderInfo({ rentalOrderId: this.localRecordId })
            .then(result => {
                this.error = undefined;
  
                if (result) {
                    let rentalOrderRecord = result;
  
                    if (rentalOrderRecord.hasOwnProperty('opportuntyId')) {
                        this.localOpportunityId = rentalOrderRecord.opportuntyId;
                        console.log('opportunity Id: ' + this.localOpportunityId );
                    } 
                } 
            })
            .catch(TypeError => {
              this.error = this.getErrorMessage(TypeError);
              console.log('type error occurred in getRentalOrderInfo: ' + this.error);
              return false;
            })
            .catch(error => {
                this.error = this.getErrorMessage(error);
                console.log('error occurred in getRentalOrderInfo: ' + this.error);
                return false;
            });    
    } 
  
 

    handleOLISelection(event) {
        console.log('handle OLI selectionsuccess event in existing line item lwc component');
        console.log(event.detail);
        this.selectedOLIData.length = 0;
        const selectedRows = event.detail;
        if (selectedRows.length > 0) {
            console.log('selected OLI data available');
            for (let i = 0; i < selectedRows.length; i++){
              this.selectedOLIData.push(selectedRows[i]);
            }
        }
        
    }

    handleOLISelectionComplete(event) {
        console.log('handle OLI selection complete event in existing line item lwc component');
        console.log('selected list size: ' + this.selectedOLIData.length);

        if (this.selectedOLIData.length > 0) {
            if (this.localAction == 'swapOppLineItem') {
                // Send event to parent component in order to process opp line item swap
                console.log('sending event');
                this.dispatchEvent(
                    new CustomEvent('selectioncomplete', {detail: flattenQueryResult(this.selectedOLIData)})
                );
            } else if (this.localAction == 'addContractLineItem') {
                console.log('addContractLineItem event. Ready to create records');
                // Process creation of Service Contract and line items
                this.hideSpinner = false;
                // temporarily disabled for deployment
                //this.handleCreateServiceContract();
            }     
        }
    } 

    handleRecordSelection(event) {
        console.log('handle asset selection success event in existing line item lwc component');
        console.log(event.detail);
        this.selectedOLIData.length = 0;
        const selectedRows = event.detail;
        if (selectedRows.length > 0) {
            console.log('selected record data available');
            for (let i = 0; i < selectedRows.length; i++){
              this.selectedOLIData.push(selectedRows[i]);
            }
        }
        
    }

    handleRecordSelectionComplete(event) {
        console.log('handle asset selection complete event in existing line item lwc component');
        console.log('selected list size: ' + this.selectedOLIData.length);

        if (this.selectedOLIData.length > 0) {
            if (this.localAction == 'swapAsset') {
                // Send event to parent component in order to process asset swap
                console.log('swap asset. sending selection complete event');
                this.dispatchEvent(
                    new CustomEvent('selectioncomplete', {detail: flattenQueryResult(this.selectedOLIData)})
                );
            } else if (this.localAction == 'addItemReceiptLineItem') {
                console.log('addItemReceiptLineItem event. Ready to create records');
                // Process creation of Item Receipt and line items
                this.hideSpinner = false;
                this.handleCreateItemReceipt();
            } else if (this.localAction == 'addPurchasingReturnLineItem')  {
                console.log('addPurchasingReturnLineItem event. Ready to create records');
                // Process creation of Purchasing Return and line items
                this.handleCreatePurchasingReturn();
            } else if (this.localAction == 'addPOBillLineItem' && this.selectedRecordTypeName == 'PO Bill') {
                console.log('addPOBillLineItem event with PO Bill record type. Ready to create records');
                // Process creation of PO Bill and line items
               this.handleCreatePOBillLineItems();
            } else if (this.localAction == 'swapIRProduct') {
                // Send event to parent component in order to process prli swap
                console.log('swap prli. sending selection complete event');
                this.dispatchEvent(
                    new CustomEvent('selectioncomplete', {detail: flattenQueryResult(this.selectedOLIData)})
                );
            } 
        }
    } 


    handleRecordTypeSelection(event) {
        console.log('handle record type selectionsuccess event in existing line item lwc component');
        console.log('Id: ' + event.detail.id);
        console.log('Name: ' + event.detail.name);
        this.selectedRecordTypeId = event.detail.id;
        this.selectedRecordTypeName = event.detail.name;
        console.log('record type id passed in: ' + this.selectedRecordTypeId);

    }  
    
    
    handleRecordTypeSelectionComplete(event) {
        console.log('handle record type selection complete event in existing line item lwc component');
        this.recordTypeSelectionComplete = true;
        // For PO Bils, with a Purchasing Price Adjustment record type
        // create the PO Bill right away
        if (this.localAction == 'addPOBillLineItem' && this.selectedRecordTypeName == 'Purchasing Price Adjustment') {
            console.log('PO Bill with Purchasing Price Adjustment record type selected. Ready to generate PO Bill');
            this.handleCreatePO();
        } else {
            // For other transactions, display the line item selection
             this.delayTimeout = setTimeout(() => {
                this.displayRecordTypeSelection = null;
                this.displayRecordTypeSelection = false;
                this.displayLineItemSelection = null;
                this.displayLineItemSelection = true;
            }, DELAY);
        }
    }    

    // temporarily disabled for deployment
    /*handleCreateServiceContract() {
        console.log('Processing creation of Service Contract and line items');
        this.isProcessing = true;

        createServiceContractLineItems({ selectedItems: this.selectedOLIData, opportunityId: this.localRecordId, recordTypeId: this.selectedRecordTypeId })
            .then(result => {
                this.error = undefined;

                if (result) {
                    let serviceContractRecord = result;
                    let serviceContractId;
                    let url;
  
                    if (serviceContractRecord.hasOwnProperty('status') && serviceContractRecord.status == 'success') {
                        console.log('service contract line items processed successfully');
                        if (serviceContractRecord.hasOwnProperty('serviceContractId')) {
                            serviceContractId = serviceContractRecord.serviceContractId;
                            console.log('service contract Id: ' + serviceContractId );
                            url = '/' + serviceContractId;
                            //this.hideSpinner = true;
                            window.location.href = url;
                            
                        }
                    } else if (serviceContractRecord.hasOwnProperty('status')) {
                        this.hideSpinner = true;
                        this.messages.warningMessage = serviceContractRecord.status;
                        this.messages.warningHeader = 'Service Contract Error';
                        this.messages.closeButtonLabel = 'Cancel';
                        this.messages.showConfirmationButton = false;
                        this.messages.warningMessageAvailable = true;
                    } else {
                        this.hideSpinner = true;
                        console.log('service contract line items failed to process');
                        this.messages.warningMessage = 'Error occurred while processing service contract line items';
                        this.messages.warningHeader = 'Service Contract Error';
                        this.messages.closeButtonLabel = 'Cancel';
                        this.messages.showConfirmationButton = false;
                        this.messages.warningMessageAvailable = true;
                    } 

                    this.hideSpinner = true;
                    this.isProcessing = false;
                } 
            })
            .catch(TypeError => {
              this.error = this.getErrorMessage(TypeError);
              console.log('type error occurred in createServiceContractLineItems: ' + this.error);
              this.isProcessing = false;
              return false;
            })
            .catch(error => {
                this.error = this.getErrorMessage(error);
                console.log('error occurred in createServiceContractLineItems: ' + this.error);
                this.isProcessing = false;
                return false;
            });    
    }*/

    handleCreateItemReceipt() {
        console.log('Processing creation of Item Receipt and line items');
        this.isProcessing = true;

        createItemReceiptLineItems({ selectedItems: this.selectedOLIData, opportunityId: this.localRecordId })
            .then(result => {
                this.error = undefined;

                if (result) {
                    let itemReceiptRecord = result;
                    let itemReceiptId;
                    let url;
  
                    if (itemReceiptRecord.hasOwnProperty('status') && itemReceiptRecord.status == 'success') {
                        console.log('item receipt line items processed successfully');
                        if (itemReceiptRecord.hasOwnProperty('itemReceiptId')) {
                            itemReceiptId = itemReceiptRecord.itemReceiptId;
                            console.log('item receipt Id: ' + itemReceiptId );
                            url = '/' + itemReceiptId;
                            //this.hideSpinner = true;
                            window.location.href = url;
                            
                        }
                    } else if (itemReceiptRecord.hasOwnProperty('status')) {
                        this.hideSpinner = true;
                        this.messages.warningMessage = itemReceiptRecord.status;
                        this.messages.warningHeader = 'Item Receipt Error';
                        this.messages.closeButtonLabel = 'Cancel';
                        this.messages.showConfirmationButton = false;
                        this.messages.warningMessageAvailable = true;
                    } else {
                        this.hideSpinner = true;
                        console.log('item receipt line items failed to process');
                        this.messages.warningMessage = 'Error occurred while processing item receipt line items';
                        this.messages.warningHeader = 'Item Receipt Error';
                        this.messages.closeButtonLabel = 'Cancel';
                        this.messages.showConfirmationButton = false;
                        this.messages.warningMessageAvailable = true;
                    } 

                    this.hideSpinner = true;
                    this.isProcessing = false;
                } 
            })
            .catch(TypeError => {
              this.error = this.getErrorMessage(TypeError);
              console.log('type error occurred in createServiceContractLineItems: ' + this.error);
              this.isProcessing = false;
              return false;
            })
            .catch(error => {
                this.error = this.getErrorMessage(error);
                console.log('error occurred in createServiceContractLineItems: ' + this.error);
                this.isProcessing = false;
                return false;
            });    
    }

    handleCreatePurchasingReturn(){

        createPurchasingReturnLineItems({ selectedItems: this.selectedOLIData, opportunityId: this.localRecordId, recordTypeId: this.selectedRecordTypeId })
            .then(result => {
                this.error = undefined;

                if (result) {
                    let purchasingReturnRecord = result;
                    let purchasingReturnId;
                    let url;
  
                    if (purchasingReturnRecord.hasOwnProperty('status') && purchasingReturnRecord.status == 'success') {
                        console.log('purchasing return line items processed successfully');
                        if (purchasingReturnRecord.hasOwnProperty('purchasingReturnId')) {
                            purchasingReturnId = purchasingReturnRecord.purchasingReturnId;
                            console.log('purchasing return Id: ' + purchasingReturnId );
                            url = '/' + purchasingReturnId;
                            //this.hideSpinner = true;
                            window.location.href = url;
                            
                        }
                    } else if (purchasingReturnRecord.hasOwnProperty('status')) {
                        this.hideSpinner = true;
                        this.messages.warningMessage = purchasingReturnRecord.status;
                        this.messages.warningHeader = 'Purchasing Return Error';
                        this.messages.closeButtonLabel = 'Cancel';
                        this.messages.showConfirmationButton = false;
                        this.messages.warningMessageAvailable = true;
                    } else {
                        this.hideSpinner = true;
                        console.log('purchasing return line items failed to process');
                        this.messages.warningMessage = 'Error occurred while processing purchasing return line items';
                        this.messages.warningHeader = 'Purchasing Return Error';
                        this.messages.closeButtonLabel = 'Cancel';
                        this.messages.showConfirmationButton = false;
                        this.messages.warningMessageAvailable = true;
                    } 

                    this.hideSpinner = true;
                    this.isProcessing = false;
                } 
            })
            .catch(TypeError => {
              this.error = this.getErrorMessage(TypeError);
              console.log('type error occurred in createPurchasingReturnLineItems: ' + this.error);
              this.isProcessing = false;
              return false;
            })
            .catch(error => {
                this.error = this.getErrorMessage(error);
                console.log('error occurred in createPurchasingReturnLineItems: ' + this.error);
                this.isProcessing = false;
                return false;
            });    
    }


    handleCreatePO(){

        createPOBill({ opportunityId: this.localRecordId, recordTypeId: this.selectedRecordTypeId })
            .then(result => {
                this.error = undefined;

                if (result) {
                    let poBillRecord = result;
                    let poBillId;
                    let url;
  
                    if (poBillRecord.hasOwnProperty('status') && poBillRecord.status == 'success') {
                        console.log('po bill processed successfully');
                        if (poBillRecord.hasOwnProperty('poBillId')) {
                            poBillId = poBillRecord.poBillId;
                            console.log('po bill Id: ' + poBillId );
                            url = '/' + poBillId;
                            //this.hideSpinner = true;
                            window.location.href = url;
                            
                        }
                    } else if (poBillRecord.hasOwnProperty('status')) {
                        this.hideSpinner = true;
                        this.messages.warningMessage = poBillRecord.status;
                        this.messages.warningHeader = 'PO Bill Error';
                        this.messages.closeButtonLabel = 'Cancel';
                        this.messages.showConfirmationButton = false;
                        this.messages.warningMessageAvailable = true;
                    } else {
                        this.hideSpinner = true;
                        console.log('po bill failed to process');
                        this.messages.warningMessage = 'Error occurred while processing po bill';
                        this.messages.warningHeader = 'PO Bill Error';
                        this.messages.closeButtonLabel = 'Cancel';
                        this.messages.showConfirmationButton = false;
                        this.messages.warningMessageAvailable = true;
                    } 

                    this.hideSpinner = true;
                    this.isProcessing = false;
                } 
            })
            .catch(TypeError => {
              this.error = this.getErrorMessage(TypeError);
              console.log('type error occurred in createPOBill: ' + this.error);
              this.isProcessing = false;
              return false;
            })
            .catch(error => {
                this.error = this.getErrorMessage(error);
                console.log('error occurred in createPOBill: ' + this.error);
                this.isProcessing = false;
                return false;
            });    
    }

    handleCreatePOBillLineItems(){

        createPOBillLineItems({ selectedItems: this.selectedOLIData, opportunityId: this.localRecordId, recordTypeId: this.selectedRecordTypeId })
            .then(result => {
                this.error = undefined;

                if (result) {
                    let poBillRecord = result;
                    let poBillId;
                    let url;
  
                    if (poBillRecord.hasOwnProperty('status') && poBillRecord.status == 'success') {
                        console.log('po bill line items processed successfully');
                        if (poBillRecord.hasOwnProperty('poBillId')) {
                            poBillId = poBillRecord.poBillId;
                            console.log('po bill Id: ' + poBillId );
                            url = '/' + poBillId;
                            //this.hideSpinner = true;
                            window.location.href = url;
                            
                        }
                    } else if (poBillRecord.hasOwnProperty('status')) {
                        this.hideSpinner = true;
                        this.messages.warningMessage = poBillRecord.status;
                        this.messages.warningHeader = 'PO Bill Error';
                        this.messages.closeButtonLabel = 'Cancel';
                        this.messages.showConfirmationButton = false;
                        this.messages.warningMessageAvailable = true;
                    } else {
                        this.hideSpinner = true;
                        console.log('po bill line items failed to process');
                        this.messages.warningMessage = 'Error occurred while processing po bill line items';
                        this.messages.warningHeader = 'PO Bill Error';
                        this.messages.closeButtonLabel = 'Cancel';
                        this.messages.showConfirmationButton = false;
                        this.messages.warningMessageAvailable = true;
                    } 

                    this.hideSpinner = true;
                    this.isProcessing = false;
                } 
            })
            .catch(TypeError => {
              this.error = this.getErrorMessage(TypeError);
              console.log('type error occurred in createPOBillLineItems: ' + this.error);
              this.isProcessing = false;
              return false;
            })
            .catch(error => {
                this.error = this.getErrorMessage(error);
                console.log('error occurred in createPOBillLineItems: ' + this.error);
                this.isProcessing = false;
                return false;
            });    
    }

    handleCancel(event) {
        var url = '/' + this.localRecordId;
        console.log('handle cancel event');
        window.location.href = url;
    }

    

    get isContractLineItemSearch() {
        if (this.localAction =='addContractLineItem') {
            return true;
        } else {
            return false;
        }
    }

    get isOppLineItemSwap() {
        if (this.localAction =='swapOppLineItem') {
            return true;
        } else {
            return false;
        }
    }

    get isPRLISelection() {
        if (this.localAction =='swapIRProduct') {
            return true;
        } else {
            return false;
        }
    }

    get isAssetSelection() {
        if (this.localAction =='swapAsset' || (this.localAction == 'addPurchasingReturnLineItem' && this.recordTypeSelectionComplete ) 
        || (this.localAction == 'addPOBillLineItem' && this.selectedRecordTypeName == 'PO Bill' && this.recordTypeSelectionComplete) ) {
            return true;
        } else {
            return false;
        }
    }

    get isItemReceiptSelection() {
        if (this.localAction =='addItemReceiptLineItem') {
            return true;
        } else {
            return false;
        }
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