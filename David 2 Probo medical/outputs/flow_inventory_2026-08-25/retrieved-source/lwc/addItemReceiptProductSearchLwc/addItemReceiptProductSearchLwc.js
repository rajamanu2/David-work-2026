import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getObjectsAccessImperative from '@salesforce/apex/UserHasAccess.getObjectsAccessImperative';
import createProductRepairLineItems from '@salesforce/apex/AddIRProductServices.createProductRepairLineItems';
import getIRProducts from '@salesforce/apex/AddIRProductServices.getIRProducts';
import getProductRepairInfo from '@salesforce/apex/AddIRProductServices.getProductRepairInfo';
import deleteProductRepairLineItem from '@salesforce/apex/AddIRProductServices.deleteProductRepairLineItem';

import { flattenObject, flattenQueryResult, addToList,  removeFromList } from 'c/utilitiesLwc';


const SEARCH_DELAY = 500;
const DELAY = 10;


export default class AddItemReceiptProductSearchLwc extends LightningElement {
    @api 
    get parentId() {
      return this.localRecordId;
    }
    set parentId(value) {
        this.localRecordId = value;
        console.log('Id passed in to search lwc component: ' + value);
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
    @api 
    get selectedPrli() {
      return this.selectedPRLIData;
    }
    set selectedPrli(value) {
        setTimeout(() => {
            this.handlePRLISelection(value);
        }, DELAY);    
    }
    @track searchTerm;
    @track pastQuantity;
    @track productData;
    @track productDataAvailable = false;
    @track tableRequest;
    @track pageSettings = {
      activeSections: ['searchResults', 'selectedItems', 'swappedItems'],
      objectsToCheckForAccess: ['Product2', 'Item_Receipt__c', 'IR_Product__c', 'ProductItem__c', 'Product_Repair__c'],
      objectsAccessResult: null
    }
    @track hideSpinner = false;
    @track selectedPRLIData = [];
    @track selectedPRLIDataAvailable = false;
    @track hasIRProductSwapData = null;
    @track currentPRLIRecord;
    @track currentPRLIRecordPosition = 0;
    @track currentNewPRLIRecord;
    @track newPRLIData = [];
    @track newPRLIEditedData = [];
    @track newPRLIDataMap = new Map();
    @track newPRLIDataAvailable = false;
    @track productDataMap = new Map();
    @track selectedPRLICount = 0;
    @track selections = {
        showModal: false,
        selectedItemToRemove: null,
        saveInProgress: false
    }    
    @track swapPRLICount = 0;
    @track swapPRLIData = [];
    @track swapPRLIDataAvailable = false;
    @track swapPRLIRecords = [];
    @track error;
    @track currentHoverRecordId;
    @track left;
    @track top;
    @track searchString;
    @track productRepair = {
      id: null,
      repairActivity: null
    }
    @track itemReceiptProductDataMap = new Map();
    @track itemReceiptProductData = [];
    @track tableWidth = 5000;
    @track messages = {
          savePRLIErrorMessage: null,
          savePRLIerrorMessageAvailable: false,
          savePRLISuccessMessage: null,
          savePRLISuccessMessageAvailable: false,
          searchResultsMessage: null,
          searchResultsMessageAvailable: false,
          warningMessage: null,
          warningHeader: null,
          warningMessageAvailable: false,
          closeButtonLabel: null,
          showConfirmationButton: false,
          invalidRecordCount: null,
          validationErrorMessage: null,
          validationErrorMessageAvailable: false
    }
    
    @track localRecordId=null;
    @track localObjectName=null;
    @track localAction=null;
    
    objectsToVerifyAccess;
    pageInitialized = false;
    /*
    controlValues;
    totalDependentValues = [];*/

    
    
    renderedCallback() {

        if (this.pageInitialized) {
          return;
        } else {
            if (this.localObjectName == 'Product_Repair__c') {
                console.log('need to get access to Product Repair');
                this.objectsToVerifyAccess = ['Product2', 'ProductItem__c', 'Product_Repair__c', 'Item_Receipt__c', 'IR_Product__c'];
                this.handleGetObjectsAccess();
                this.handleGetProductRepairInfo()
            } 
           
            // reset search data
            if (this.itemReceiptProductData.length > 0) {
                this.itemReceiptProductData.length = 0;
            }
          

            this.pageInitialized = true;
  
        }
  
  
    }

            handleGetObjectsAccess() {
      getObjectsAccessImperative({ objectNames: this.objectsToVerifyAccess })
          .then(result => {
              this.error = undefined;
              
              if (result) {
                  this.pageSettings.objectsAccessResult = result; 
                  let permissionsMessage;
                  // data received is a map of maps. Each key in the main map is the object and
                  // the value of a map of access levels with true or false
                  // for example, mapObjectsAccess: {Opportunity={Create=true, Delete=true, Edit=true, Read=true}, OpportunityLineItem={Create=true, Delete=true, Edit=true, Read=true}, Product2={Create=true, Delete=true, Edit=true, Read=true}, ProductItem__c={Create=true, Delete=true, Edit=true, Read=true}}
                  if (this.localObjectName == 'Product_Repair__c') {
                    let productRepairAccess = this.pageSettings.objectsAccessResult.Product_Repair__c;
                    let productRepairResult = Object.getOwnPropertyNames(productRepairAccess);
                    let productRepairMissingPermissions = [];
                    
                    console.log('Product Repair Access Levels');
                    productRepairResult.forEach(
                    function (accessLevel) {
                        console.log(accessLevel + ' -> ' + productRepairAccess[accessLevel]);
                        // If the access level is false, add it to the list of missing permissions
                        if (!productRepairAccess[accessLevel] && accessLevel !== 'Delete') {
                            productRepairMissingPermissions.push(String(accessLevel));
                        }
                    }
                    );

                    if (productRepairMissingPermissions.length > 0) {
                        permissionsMessage += '\nMissing Permissions: Product Repair - ' + productRepairMissingPermissions;
                    }
                  }
                    let itemReceiptAccess = this.pageSettings.objectsAccessResult.Item_Receipt__c;
                    let itemReceiptResult = Object.getOwnPropertyNames(itemReceiptAccess);
                    let itemReceiptMissingPermissions = [];
                    
                    console.log('Item Receipt Access Levels');
                    itemReceiptResult.forEach(
                    function (accessLevel) {
                        console.log(accessLevel + ' -> ' + itemReceiptAccess[accessLevel]);
                        // If the access level is false, add it to the list of missing permissions
                        if (!itemReceiptAccess[accessLevel] && accessLevel !== 'Delete') {
                            itemReceiptMissingPermissions.push(String(accessLevel));
                        }
                    }
                    );

                    if (itemReceiptMissingPermissions.length > 0) {
                        permissionsMessage += '\nMissing Permissions: Item Receipt - ' + itemReceiptMissingPermissions;
                    }

                    let itemReceiptProductAccess = this.pageSettings.objectsAccessResult.IR_Product__c;
                    let itemReceiptProductResult = Object.getOwnPropertyNames(itemReceiptProductAccess);
                    let itemReceiptProductMissingPermissions = [];
                    
                    console.log('IR Product Access Levels');
                    itemReceiptProductResult.forEach(
                    function (accessLevel) {
                        console.log(accessLevel + ' -> ' + itemReceiptProductAccess[accessLevel]);
                        // If the access level is false, add it to the list of missing permissions
                        if (!itemReceiptProductAccess[accessLevel] && accessLevel !== 'Delete') {
                            itemReceiptProductMissingPermissions.push(String(accessLevel));
                        }
                    }
                    );

                    if (itemReceiptProductMissingPermissions.length > 0) {
                        permissionsMessage += '\nMissing Permissions: IR Product - ' + itemReceiptProductMissingPermissions;
                    }
                    
                  let productAccess = this.pageSettings.objectsAccessResult.Product2;
                  let productResult = Object.getOwnPropertyNames(productAccess);
                  let productMissingPermissions = [];
                  console.log('Product Access Levels');
                  productResult.forEach(
                  function (accessLevel) {
                      console.log(accessLevel + ' -> ' + productAccess[accessLevel]);
                      if (!productAccess[accessLevel] && accessLevel == 'Read') {
                      productMissingPermissions.push(String(accessLevel));
                      }
                  }
                  );

                  if (productMissingPermissions.length > 0) {
                      permissionsMessage += '\nMissing Permissions: Product - ' + productMissingPermissions;
                  }

                  let productItemAccess = this.pageSettings.objectsAccessResult.ProductItem__c;
                  let productItemResult = Object.getOwnPropertyNames(productItemAccess);
                  let productItemMissingPermissions = [];
                  console.log('Product Item Access Levels');
                  productItemResult.forEach(
                  function (accessLevel) {
                      console.log(accessLevel + ' -> ' + productItemAccess[accessLevel]);
                      if (!productItemAccess[accessLevel] && accessLevel !== 'Delete') {
                      productItemMissingPermissions.push(String(accessLevel));
                      }
                  }
                  );
              
                  if (productItemMissingPermissions.length > 0) {
                      permissionsMessage += '\nMissing Permissions: Asset - ' + productItemMissingPermissions;
                  }

                  if (permissionsMessage) {
                  this.messages.warningHeader = 'You do not have the correct permissions to use this feature on this record. Please contact your system administrator if you have further questions.';
                  this.messages.warningMessage = permissionsMessage;
                  this.messages.showConfirmationButton = false;
                  this.messages.closeButtonLabel = 'Close';
                  this.messages.warningMessageAvailable = true;
                  }
              }  
              
          })
          .catch(TypeError => {
            this.error = TypeError;
            console.log('type error occurred in getObjectsAccess: ' + this.error);
            return false;
          })
          .catch(error => {
              this.error = error;
              console.log('error occurred in getObjectsAccess: ' + this.error);
              return false;
          });       
    } 
/*
    @wire(getObjectInfo, { objectApiName: PRODUCTITEM_OBJECT })
    objectInfo;  */

        handleGetProductRepairInfo() {
      getProductRepairInfo({ productRepairId: this.localRecordId })
          .then(result => {
              this.error = undefined;

              if (result) {
                  let productRepairRecord = result;
                  
                  if (productRepairRecord.hasOwnProperty('repairActivity')) {
                      this.productRepair.repairActivity = productRepairRecord.repairActivity;
                  }
                  console.log('repair activity: ' + this.productRepair.repairActivity);
                  

                  this.hideSpinner = true;
              } 
          })
          .catch(TypeError => {
            this.error = this.getErrorMessage(TypeError);
            console.log('type error occurred in getProductRepairInfo: ' + this.error);
            return false;
          })
          .catch(error => {
              this.error = this.getErrorMessage(error);
              console.log('error occurred in getProductRepairInfo: ' + this.error);
              return false;
          });    
    }

  // this is for the product search
    handleSearch() {
      getIRProducts({ queryParams: this.tableRequest })
          .then(result => {
            try {
                  this.error = undefined;
                  let recordIdsReceived = [];
                  
                  if (result && result.length > 0) {
                    this.productData = flattenQueryResult(result);
                    //this.productDataAvailable = true;
                                        
                    console.log('data received from wire method.');
                    for (let record of this.productData) { 
                        console.log('record');
                        console.log(record);
                        console.log('Id ' + record.Id);
                        let hideAddProductValue;
                        let recordIdPosition = recordIdsReceived.indexOf(record.Id);
                        let newQuantity = 1;
                        let disableIRProduct = false;
                        if (recordIdPosition == -1) {
                            recordIdsReceived.push(record.Id);

                            // gray out checkbox for certain assets
                            if(record.Quantity_Remaining__c <= 0){
                                hideAddProductValue = true;
                            }
                            else{
                                hideAddProductValue = false;
                            }
                            
                            if(this.pastQuantity != null){
                                newQuantity = this.pastQuantity;
                            }
                            if(record.quantity != null){
                                newQuantity = parseFloat(record.quantity);
                            }
                            if (record.Name !== undefined) {
                                console.log('Qty Remaining ' + record.Quantity_Remaining__c);
                                if(record.Quantity_Remaining__c == 0 || record.Quantity_Remaining__c == null){
                                    disableIRProduct = true;
                                }
                                
                            }
                            console.log('THIS IS THE NEW QUANTITY >> ' + newQuantity);
                            let itemReceiptProductRecord = {
                                id: record.Id, 
                                quantity: newQuantity,
                                url: '/' + record.Id,
                                selected: false,
                                saved: false,
                                hideAddProduct: hideAddProductValue,
                                disableItem: disableIRProduct,
                                data: record
                            };
                            console.log('IR product record ' + itemReceiptProductRecord);
                            this.itemReceiptProductData.push(itemReceiptProductRecord);
                            this.itemReceiptProductDataMap.set(record.Id, itemReceiptProductRecord);
                            
                        }
                            
                    }      
                
                    if (this.itemReceiptProductData.length > 0) {
                        this.productDataAvailable = true;
                    }

                    for (let i = 0; i < this.productData.length; i++){
                        let record = this.productData[i];
                        if (!this.productDataMap.has(record.Id)) {
                          this.productDataMap.set(record.Id, record);
                        }
                    }
                  } else {
                    this.messages.searchResultsMessage = 'No results found';
                    this.messages.searchResultsMessageAvailable = true;
                  }
            } catch(error) {
              console.log('error occurred while processing search: ' + error);
            } 
          })
          .catch(TypeError => {
            this.error = this.getErrorMessage(TypeError);
            console.log('type error occurred in search: ' + this.error);
            return false;
          })
          .catch(error => {
              this.error = error;
              console.log('error occurred in search: ' + this.error);
              return false;
          });
    }

    // Product search methods
    handleSearchKeyChange(event) {
          window.clearTimeout(this.delayTimeout);
          this.searchString = event.target.value;
          console.log('search string: ' + this.searchString);
          
          if (this.searchString != null && this.searchString.length > 2) {
              console.log('processing new request');
              this.delayTimeout = setTimeout(() => {
                this.triggerNewSearch();
              }, SEARCH_DELAY);
          }
    }

    handleSearchLoad(event) {
      console.log('load event');
      if (this.searchTerm != null && this.searchTerm != undefined && this.searchTerm.length > 2) {
          this.searchString = event.detail;

          console.log('processing new request');
          // eslint-disable-next-line @lwc/lwc/no-async-operation
          this.delayTimeout = setTimeout(() => {
            this.triggerNewSearch();
          }, SEARCH_DELAY);
      }
    }  
    handleQuantityChange(event) {
        console.log('handleQuantityChange in search component');
        let eventId = event.detail.key;
        console.log('id: ' + eventId);
        let updatedQuantity = event.detail.quantity;
        console.log('updated quantity: ' + updatedQuantity);
        let obj;
        obj = this.itemReceiptProductDataMap.get(eventId);
        
        console.log('selected prli record:' + obj);
        console.log('current quantity: ' + obj.quantity);
        
        obj.quantity = updatedQuantity;
        console.log('updated quantity: ' + obj.quantity);

        //reset Validation
        this.messages.invalidRecordCount = null;
        this.messages.validationErrorMessage = null;
        this.messages.validationErrorMessageAvailable = false;
        
    }

    triggerNewSearch() {
      if (this.searchString != null && this.searchString.length > 2) {
          this.productDataAvailable = false;
          
          if (this.itemReceiptProductData.length > 0) {
              this.itemReceiptProductData.length = 0;
          }
          
          this.messages.searchResultsMessage = '';
          this.messages.searchResultsMessageAvailable = false;

          console.log('triggering new search....');

          let newRequest;
    
            console.log('using regular search filters....');
            newRequest = {
                queryString: this.searchString
            
            };
          


          this.tableRequest = newRequest;
          this.handleSearch();
          
          // this.tableWidth = 5000;
        
          
      }
    }

    // Existing PRLI selection methods (swap) 
    handlePRLISelection(selectedRows) {
        console.log('handle PRLI selection in product search lwc component');
        
        this.selectedPRLIData.length = 0;
        
        if (selectedRows.length > 0) {
            console.log('selected PRLI data available');
            for (let i = 0; i < selectedRows.length; i++){
                this.selectedPRLIData.push(selectedRows[i]);
                let row = selectedRows[i];
                console.log('row in process: ' + JSON.stringify(row));
                if (row.hasOwnProperty('Product_Name__c')) {
                  console.log('we have IR Product swap data');
                  console.log('IT product name: ' + selectedRows[i].Product_Name__c);
                  this.hasIRProductSwapData = true;
                  
                } else {
                  this.hasIRProductSwapData = false;
                  
                  console.log('we have PRLI swap data');
                  console.log('PRLI product name: ' + selectedRows[i].IR_Product_Name__c);
                }
                
            }
            this.selectedPRLIDataAvailable = null;
            this.selectedPRLIDataAvailable = true;
            this.currentPRLIRecord = this.selectedPRLIData[0];
            if (this.hasIRProductSwapData) {
              this.searchTerm = this.currentPRLIRecord.Product_Name__c;
            } else {
              this.searchTerm = this.currentPRLIRecord.IR_Product_Name__c;
              this.pastQuantity = this.currentPRLIRecord.Quantity__c;
            }
            
            console.log('searchTerm: ' + this.searchTerm);
            let searchEvent = new CustomEvent('searchLoad', {detail: this.searchTerm});
            this.handleSearchLoad(searchEvent);
        }
    
    }

  
    
    handlePrevious(event) {
    console.log('handle previous event');
        this.currentPRLIRecordPosition = event.detail;
        console.log('current position: ' + this.currentPRLIRecordPosition);
        this.currentPRLIRecord = this.selectedPRLIData[this.currentPRLIRecordPosition];
        console.log('current prli record: ' + this.currentPRLIRecord);
        this.productData.length = 0;
        this.itemReceiptProductData.length = 0;
        this.productDataAvailable = false;
        if (this.hasIRProductSwapData) {
          this.searchTerm = this.currentPRLIRecord.Product_Name__c;
        } else {
          this.searchTerm = this.currentPRLIRecord.IR_Product_Name__c;
        }
        console.log('searchTerm: ' + this.searchTerm);
        let searchEvent = new CustomEvent('searchLoad', {detail: this.searchTerm});
        this.handleSearchLoad(searchEvent);
    } 

    handleNext(event) {
        console.log('handle next event');
        this.currentPRLIRecordPosition = event.detail;
        console.log('current position: ' + this.currentPRLIRecordPosition);
        this.currentPRLIRecord = this.selectedPRLIData[this.currentPRLIRecordPosition];
        console.log('current prli record: ' + this.currentPRLIRecord);
        this.productData.length = 0;
        this.itemReceiptProductData.length = 0;
        this.productDataAvailable = false;
        if (this.hasIRProductSwapData) {
          this.searchTerm = this.currentPRLIRecord.Product_Name__c;
        } else {
          this.searchTerm = this.currentPRLIRecord.IR_Product_Name__c;
        }
        console.log('searchTerm: ' + this.searchTerm);
        let searchEvent = new CustomEvent('searchLoad', {detail: this.searchTerm});
        this.handleSearchLoad(searchEvent);
    } 

    // New PRLI methods
    handleNewPRLISelection(event) {
        console.log('handle new PRLI selection event');
        let isChecked = event.target.checked;
        console.log('is checked' + isChecked);
        let selectedRecord;
        let eventValue = event.currentTarget.getAttribute("data-selection");
        console.log('event value' + eventValue);
        selectedRecord = this.itemReceiptProductDataMap.get(eventValue);
        
        selectedRecord.selected = isChecked;
        let obj = this.productDataMap.get(eventValue);
        const selectedItemPosition = this.newPRLIData.indexOf(obj);
        console.log('selected prli record:' + obj);
        console.log('selected prli record position in selected items:' + selectedItemPosition);
        if (isChecked) {
            console.log('adding selected prli to list');
            this.currentNewPRLIRecord = obj;     
            if (selectedItemPosition == -1) {
            this.newPRLIData.push(obj);
            this.newPRLIEditedData.push(selectedRecord);
            this.newPRLIDataMap.set(eventValue, selectedRecord);
            this.newPRLIDataAvailable = true;
            }
        } else {
            console.log('removing from prli list');
            if (selectedItemPosition != -1) {
            this.newPRLIData.splice(selectedItemPosition,1);
            this.newPRLIEditedData.splice(selectedItemPosition,1);
            this.newPRLIDataMap.delete(eventValue);
            }

            if (this.selectedPRLIDataAvailable){
                let swapValue = this.currentPRLIRecord.Id + '-' + eventValue;
                if (this.swapPRLIData != null && this.swapPRLIData.indexOf(swapValue) != -1) {
                    const deSelectedItemPosition = this.swapPRLIData.indexOf(swapValue);
                    console.log('found swap item that has been deselected: ' + deSelectedItemPosition);
                    console.log('removing from swap prli list');
                    this.swapPRLIData.splice(deSelectedItemPosition,1);
                    this.swapPRLIRecords.splice(deSelectedItemPosition,1);
                    this.swapPRLICount = this.swapPRLIData.length;
                }
            }
        }

        this.selectedPRLICount = this.newPRLIData.length;
        
    
    }

    handleNewPRLIDeselection(event) {
        console.log('handle new PRLI deselection event in search component');
        
        let eventValue = event.detail.key;
        console.log('event value: ' + eventValue);
        let deSelectedRecord;
        deSelectedRecord = this.itemReceiptProductDataMap.get(eventValue);
        

        deSelectedRecord.selected = false;
        let obj = this.productDataMap.get(eventValue);
        let selectedItemPosition = this.newPRLIData.indexOf(obj);
        console.log('selected prli record:' + deSelectedRecord);
        console.log('selected prli record position in selected items:' + selectedItemPosition);
        
        
        if (selectedItemPosition != -1) {
            console.log('removing from prli list');
            this.newPRLIData.splice(selectedItemPosition,1);
            this.newPRLIEditedData.splice(selectedItemPosition,1);
            this.newPRLIDataMap.delete(eventValue);
        }
        
        this.selectedPRLICount = this.newPRLIData.length;
        if (this.newPRLIData.length == 0) {
            this.newPRLIDataAvailable = false;
        }

        if (this.selectedPRLIDataAvailable){
            let swapValue = this.currentPRLIRecord.Id + '-' + eventValue;
            if (this.swapPRLIData != null && this.swapPRLIData.indexOf(swapValue) != -1) {
                const deSelectedItemPosition = this.swapPRLIData.indexOf(swapValue);
                console.log('found swap item that has been deselected: ' + deSelectedItemPosition);
                console.log('removing from swap prli list');
                this.swapPRLIData.splice(deSelectedItemPosition,1);
                this.swapPRLIRecords.splice(deSelectedItemPosition,1);
                this.swapPRLICount = this.swapPRLIData.length;
            }
        }
        this.selections.selectedItemToRemove = null;
        this.selections.showModal = false;
        this.delayTimeout = setTimeout(() => {
            this.triggerNewSearch();
        }, DELAY);

        // if the selected item had been saved, delete the line item
        if (deSelectedRecord.saved) {
            let deleteResult = deleteProductRepairLineItem({
            itemReceiptProductId: eventValue,
            productRepairId: this.localRecordId
            })
            .then((deleteResult) => {
                if (deleteResult == 'success') {
                console.log('delete complete');
                } else {
                console.log('error occurred during delete');
                }
            })
            .catch((error) => {
                this.message = 'Error received: code' + error.errorCode + ', ' +
                    'message ' + error.message;
            });
        }
    }


    // main methods  
    handleSwap(event) {
        console.log('handle swap event');
        if (this.currentPRLIRecord == null) {
          this.currentPRLIRecord = this.selectedPRLIData[0];
        }
        console.log('current PRLI to swap: ' + this.currentPRLIRecord.Id);
        console.log('current new PRLI: ' + this.currentNewPRLIRecord.Id);
        const selectedItemPosition = this.swapPRLIData.indexOf(this.currentPRLIRecord.Id);
        console.log('selected prli record position in swap items:' + selectedItemPosition);
        if (selectedItemPosition != -1) {
          console.log('removing from swap prli list');
          this.swapPRLIData.splice(selectedItemPosition,1);
          this.swapPRLIRecords.splice(selectedItemPosition,1);
        }  
        let swapValue = this.currentPRLIRecord.Id + '-' + this.currentNewPRLIRecord.Id;
        console.log('swap value: ' + swapValue + ' and swap origin data : ' + this.currentPRLIRecord + ' and swap new data : ' + this.currentNewPRLIRecord);
        this.swapPRLIData.push(swapValue);
        let swapRecord = {
          id: this.currentPRLIRecord.Id,
          originData: this.currentPRLIRecord,
          swapData: this.currentNewPRLIRecord,
          saved: false
        };
        this.swapPRLIRecords.push(swapRecord);
        this.swapPRLICount = this.swapPRLIData.length;
        this.swapPRLIDataAvailable = true;
    } 
  
    handleSaveAndClose(event) {
        this.validateRecords();
        if (this.messages.invalidRecordCount == null) {
            this.addSwapItem();
            //this.hideSpinner = false;
            this.savePRLI(event, true);
        } else {
            this.messages.validationErrorMessage = 'Please enter the Quantity in your selected items';
            this.messages.validationErrorMessageAvailable = true;
        }
    }
  
    handleSave(event) {
        this.validateRecords();
        if (this.messages.invalidRecordCount == null) {
            this.selections.saveButtonPressed = true;
            this.addSwapItem();
            this.savePRLI(event, false);
            this.selections.saveButtonPressed = false;
             
        } else {
            this.messages.validationErrorMessage = 'Please enter the Quantity in your selected items';
            this.messages.validationErrorMessageAvailable = true;
        }
    }

    // Add swap item if the user did not click on the Swap button and there is only
    // one product selected
    addSwapItem() {
      if (this.selectedPRLIData.length > 0 && this.swapPRLIData.length == 0 && this.newPRLIData.length == 1) {
          console.log('calling addSwapItem');
          if (this.currentPRLIRecord == null) {
          this.currentPRLIRecord = this.selectedPRLIData[0];
          }

          let swapValue = this.currentPRLIRecord.Id + '-' + this.currentNewPRLIRecord.Id;
          console.log('swap value: ' + swapValue);
          this.swapPRLIData.push(swapValue);
          let swapRecord = {
          id: this.currentPRLIRecord.Id,
          originData: this.currentPRLIRecord,
          swapData: this.currentNewPRLIRecord,
          saved: false
          };
          this.swapPRLIRecords.push(swapRecord);
          this.swapPRLIDataAvailable = true;
      }
    }  

    savePRLI(event, saveAndClose) {
    var url = '/' + this.localRecordId;
    console.log('handle save event');
    this.selections.saveInProgress = true;
    this.messages.savePRLIErrorMessage = '';
    this.messages.savePRLIErrorMessageAvailable = false;
    
    if (this.newPRLIData.length > 0 || this.swapPRLIData.size > 0) {
        let swapItems = [];
        let itemReceiptProductItems = [];
        
        console.log('processing product repair');
        for (let key of this.newPRLIDataMap.keys()) { 
            let record = this.newPRLIDataMap.get(key);
            if (record.selected && !record.saved) {
                let itemReceiptProductRecord = {
                    id: key,
                    quantity: parseFloat(record.quantity)
                };
                itemReceiptProductItems.push(itemReceiptProductRecord);
            }
        }  
        

        for (let record of this.swapPRLIRecords) {
          if (!record.saved) {
              let swapValue = record.originData.Id + '-' + record.swapData.Id;
              console.log('swap value to save: ' + swapValue);
              swapItems.push(swapValue);
          }
        }
        
        if (itemReceiptProductItems.length > 0 || swapItems.length > 0) {
            if (saveAndClose){ 
                this.hideSpinner = false;
            }
            
             // Create line items as needed
             if (this.localObjectName == 'Product_Repair__c') {
                console.log('creating product repair line items');
                let saveResult = this.handleCreateProductRepairLineItems(itemReceiptProductItems,swapItems, saveAndClose);
                
             }
            
        } else {
            this.selections.saveInProgress = false;
            if(saveAndClose){
            // TO DO: Update Navigation once we migrate to Lightning
            // this[NavigationMixin.Navigate]({
            //     type: 'standard__recordPage',
            //     attributes: {
            //         recordId: '$opportunityId',
            //         objectApiName: 'Opportunity',
            //         actionName: 'view'
            //     }
            // });
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.delayTimeout = setTimeout(() => {
                window.location.href = url;
            }, 300);
            window.location.href = url;
            }
        }
    }  // end main if 

    }  

    validateRecords() {
      console.log('validating records...');
      let counter = 0;

      for (let key of this.newPRLIDataMap.keys()) { 
        let record = this.newPRLIDataMap.get(key);
        if (!record.quantity) {
            console.log('found record missing quantity');
            counter += 1;
        }

      }

      if (counter != 0) {
         this.messages.invalidRecordCount = counter;
         console.log('invalid record count updated: ' + this.messages.invalidRecordCount);
      }
    }  

    handleCreateProductRepairLineItems(itemReceiptProductItems, swapItems, saveAndClose) {
      let result = createProductRepairLineItems({
        selectedItems: itemReceiptProductItems,
        swapItems: swapItems,
        productRepairId: this.localRecordId,
        
        })
        .then((result) => {
        console.log('result: ' + result);
        this.hideSpinner = true;

        if (result == 'success') {
            console.log('save complete');
            
            if (this.swapPRLIData.length > 0) {
            this.messages.savePRLISuccessMessage = 'Swap completed successfully';
            this.messages.savePRLISuccessMessageAvailable = true;
            } else {
            this.messages.savePRLISuccessMessage = 'Line items added successfully';
            this.messages.savePRLISuccessMessageAvailable = true;
            }

            if (this.newPRLIDataMap.size > 0) {
              for (let key of this.newPRLIDataMap.keys()) {
                  let record = this.newPRLIDataMap.get(key);
                  record.saved = true;
                  console.log('record marked as saved : ' + record.data.Name);
              }
            }

            if (this.swapPRLIRecords.length > 0) {
              for (let record of this.swapPRLIRecords) {
                  record.saved = true;
              }  
            }
            this.selections.saveInProgress = false;
            
            if (saveAndClose) {
                console.log('ready to redirect');
                let url = '/' + this.localRecordId;
                window.location.href = url;
                //this.delayTimeout = setTimeout(() => {
                //  window.location.href = url;
               //}, 300);
            }

            return result;
        } else {
            this.selections.saveInProgress = false;
            console.log('error occurred during save' + result);
            if (result){
            this.messages.savePRLIErrorMessage = 'Error occurred during Save: ' + result;
            this.messages.savePRLIErrorMessageAvailable = true;
            }
            return null;
        }

        })
        .catch((error) => {
            this.message = 'Error received: code' + error.errorCode + ', ' +
                'message ' + error.message;
        }); 


    }


    handleCancel(event) {
    var url = '/' + this.localRecordId;
    console.log('handle cancel event');
        // TO DO: Update Navigation once we migrate to Lightning
        // this[NavigationMixin.Navigate]({
        //     type: 'standard__recordPage',
        //     attributes: {
        //         recordId: '$opportunityId',
        //         objectApiName: 'Opportunity',
        //         actionName: 'view'
        //     }
        // });
        window.location.href = url;
    }

    handleWarningConfirmation(event) {
        this.messages.warningMessageAvailable = false;
    }

    showData(event){
        console.log('show data event');
        let val = event.currentTarget.dataset.record;
        this.currentHoverRecordId = val;
        console.log('value of hover record id: ' + this.currentHoverRecordId);
        console.log('left' + event.clientX);
        console.log('top' + event.clientY);
        this.left = event.clientX;
        this.top=event.clientY;
    }
  
    hideData(event){
        console.log('hide data event');
        this.currentHoverRecordId = "";
        //this.popOverPermissionSetName = "";
    }

    get dynamicTableClass() { 
        return `min-height:450px; max-height: none; width:${this.tableWidth}px;`;
    }

    


    getErrorMessage(error) {
      let errorMessage = 'Unknown error';
      if (typeof error.body.message === 'string') {
          errorMessage = error.body.message;
      }

      return errorMessage;
    }

  

}