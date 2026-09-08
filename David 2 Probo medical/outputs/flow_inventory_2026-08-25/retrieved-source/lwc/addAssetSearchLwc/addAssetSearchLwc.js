import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import getObjectsAccessImperative from '@salesforce/apex/UserHasAccess.getObjectsAccessImperative';
//import PRODUCTITEM_OBJECT from '@salesforce/schema/ProductItem__c';
//import LOCATION_FIELD from '@salesforce/schema/ProductItem__c.Location__c';
//import CHECK_IN_TYPE_FIELD from '@salesforce/schema/ProductItem__c.Check_In_Type__c';
//import REVIEW_STATUS_FIELD from '@salesforce/schema/ProductItem__c.Review_Status__c';
//import SUBLOCATION_FIELD from '@salesforce/schema/ProductItem__c.Sub_Location__c';
import getHarvestWorkOrderInfo from '@salesforce/apex/AddAssetServices.getHarvestWorkOrderInfo';
import getProducts from '@salesforce/apex/AddAssetServices.getProducts';
import createAssets from '@salesforce/apex/AddAssetServices.createAssets';
import { flattenObject, flattenQueryResult, addToList,  removeFromList } from 'c/utilitiesLwc';

const SEARCH_DELAY = 500;
const DELAY = 10;

export default class AddAssetSearchLwc extends LightningElement {
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

    @track searchTerm;
    @track productData = [];
    @track productDataMap = new Map();
    @track productDataAvailable = false;
    @track tableRequest;
    @track pageSettings = {
      activeSections: ['searchResults', 'selectedItems', 'swappedItems'],
      objectsToCheckForAccess: ['Product2', 'ProductItem__c', 'Opportunity', 'OpportunityLineItem'],
      objectsAccessResult: null
    }
    @track hideSpinner = false;
    @track selectedPartsData = [];
    @track selectedPartsDataAvailable = false;
    @track currentnewAssetRecord;
    @track newAssetData = [];
    @track newAssetEditedData = [];
    @track newAssetDataMap = new Map();
    @track newAssetDataAvailable = false;
    @track selectedPartsCount = 0;
    @track selections = {
        selectedFamilies: [],
        selectedFunctionalRating: [],
        selectedCosmeticRating: [],
        selectedCheckInType: [],
        selectedReviewStatus: [],
        selectedDomesticOption: true,
        selectedAvailableOption: true,
        showModal: false,
        selectedItemToRemove: null,
        functionalRatingValues: ['New','Good','Fair','Bad'],
        functionalRatings: [{value:'New', selected: false},{value:'Good', selected: false},{value:'Fair', selected: false},{value:'Bad', selected: false}],
        checkInTypeValues: [],
        checkInTypes: [],
        productFamilyValues: ['Probe','System','Parts','Non-Inventory', 'Other'],
        productFamilies: [{key:'Ultrasound Probe', value:'Probe', selected: false},{key:'Ultrasound System', value:'System', selected: false},{key:'Part', value:'Parts', selected: false},{key:'Non Inventory Item', value:'Non-Inventory', selected: false},{key:'Other Medical Equipment', value:'Other', selected: false}],
        saveInProgress: false,
        isPartsOnlySearch: false,
        selectedCompatibleSystemOEM: null,
        selectedCompatibleSystemFamily: null,
        selectedCompatibleSystemModel: null,
        selectedCompatibleSystemRevisionLevel: null,
        selectedCompatibleSystemSoftwareVersion: null,
        selectedOEM: null,
        selectedPartType: null,
        selectedModality: null
    }    
    @track error;
    @track currentHoverRecordId;
    @track left;
    @track top;
    @track searchString;
    @track harvestWorkOrder = {
      status: null,
      systemWorkOrder: null,
      location: null
    }
    @track partsProductDataMap = new Map();
    @track partsProductData = [];
    @track tableWidth = 1000;
    @track messages = {
          saveAssetsErrorMessage: null,
          saveAssetsErrorMessageAvailable: false,
          saveOLISuccessMessage: null,
          saveOLISuccessMessageAvailable: false,
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
    @track localRecordId = null;
    @track localObjectName = null;
    @track localAction = null;


    objectsToVerifyAccess;
    pageInitialized = false;


    renderedCallback() {

        if (this.pageInitialized) {
          return;
        } else {
            if (this.localObjectName == 'Harvest_Work_Order__c') {
                console.log('need to get access to Harvest Work Order');
                this.objectsToVerifyAccess = ['Product2', 'ProductItem__c', 'Harvest_Work_Order__c'];
                this.handleGetObjectsAccess();
                this.handleGetHarvestWorkOrderInfo()
            } 
            this.pageInitialized = true;
  
        }
  
  
    }


    /*@wire(getObjectInfo, { objectApiName: PRODUCTITEM_OBJECT })
    objectInfo;  
    
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: SUBLOCATION_FIELD})
    subLocationPicklistValues({error, data}) {
        if (data) {
            console.log('location field data received from wire method');
            this.error = undefined;
            this.subLocationOptions = [];
            
            for (let record of data.values) { 
                console.log('sub location: label-> ' + record.label + ' value-> ' + record.value);
                let option = {label: String(record.label), value: String(record.value)};
                this.subLocationOptions.push(option);
            }  
        } else if (error) {
            this.error = this.getErrorMessage(error);
            console.log('error occurred while receiving location field data: ' + this.error);
        }
    }*/
 
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
                  if (this.localObjectName == 'Harvest_Work_Order__c') {
                      let harvestWorkOrderAccess = this.pageSettings.objectsAccessResult.Harvest_Work_Order__c;
                      let harvestWorkOrderResult = Object.getOwnPropertyNames(harvestWorkOrderAccess);
                      let harvestWorkOrderMissingPermissions = [];
                      
                      console.log('Harvest Work Order Access Levels');
                      harvestWorkOrderResult.forEach(
                      function (accessLevel) {
                          console.log(accessLevel + ' -> ' + harvestWorkOrderAccess[accessLevel]);
                          // If the access level is false, add it to the list of missing permissions
                          if (!harvestWorkOrderAccess[accessLevel] && accessLevel !== 'Delete') {
                              harvestWorkOrderMissingPermissions.push(String(accessLevel));
                          }
                      }
                      );

                      if (harvestWorkOrderMissingPermissions.length > 0) {
                          permissionsMessage += '\nMissing Permissions: Harvest Work Order - ' + harvestWorkOrderMissingPermissions;
                      }

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

    handleGetHarvestWorkOrderInfo() {
      getHarvestWorkOrderInfo({ harvestWorkOrderId: this.localRecordId })
          .then(result => {
              this.error = undefined;

              if (result) {
                  let harvestWorkOrderRecord = result;
                  
                  if (harvestWorkOrderRecord.hasOwnProperty('systemWorkOrder')) {
                      this.harvestWorkOrder.systemWorkOrder = harvestWorkOrderRecord.systemWorkOrder;
                  }
                  console.log('system work order: ' + this.harvestWorkOrder.systemWorkOrder);
                  if (harvestWorkOrderRecord.hasOwnProperty('location')) {
                    this.harvestWorkOrder.location = harvestWorkOrderRecord.location;
                    console.log('harvest work order location: ' + this.harvestWorkOrder.location);
                  }

                  if (harvestWorkOrderRecord.hasOwnProperty('functionalRating')) {
                    this.harvestWorkOrder.functionalRating = harvestWorkOrderRecord.functionalRating;
                    console.log('harvest work order system functional rating: ' + this.harvestWorkOrder.functionalRating);
                  }

                  this.hideSpinner = true;
              } 
          })
          .catch(TypeError => {
            this.error = this.getErrorMessage(TypeError);
            console.log('type error occurred in getHarvestWorkOrderInfo: ' + this.error);
            return false;
          })
          .catch(error => {
              this.error = this.getErrorMessage(error);
              console.log('error occurred in getHarvestWorkOrderInfo: ' + this.error);
              return false;
          });    
    }

    // Filter events
    handleProductFamilySelectionChange(event) {
      console.log('product family event');
      let eventValue = event.currentTarget.getAttribute("data-value");
      console.log('event value: ' + eventValue);
      const selectedItemPosition = this.selections.productFamilyValues.indexOf(eventValue);
      console.log('event position: ' + selectedItemPosition);
      let currentProductFamily = this.selections.productFamilies[selectedItemPosition];
      console.log('current family: ' + currentProductFamily);
      currentProductFamily.selected = !currentProductFamily.selected;
      console.log('event selected: ' + currentProductFamily.selected);
      let key = currentProductFamily.key;
      console.log('event key: ' + key);

      if (currentProductFamily.selected) {
        this.selections.selectedFamilies = addToList(this.selections.selectedFamilies, key);
        console('selected families count: ' + this.selections.selectedFamilies.length);
        
      } else {
        this.selections.selectedFamilies = removeFromList(this.selections.selectedFamilies, key);
      }

      
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.triggerNewSearch();
      }, DELAY);
    }

    handleCompatibleSystemOEMSelectionChange(event) {
      console.log('compatible system oem event');
      let eventValue = event.target.value;
      console.log('selected Compatible System OEM: ' + eventValue);
      if (eventValue) {
        this.selections.selectedCompatibleSystemOEM = eventValue;
      } else {
        this.selections.selectedCompatibleSystemOEM = null;
      }

      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.triggerNewSearch();
      }, DELAY);

    } 
    
    handleCompatibleSystemFamilySelectionChange(event) {
      console.log('compatible system family event');
      let eventValue = event.target.value;
      console.log('selected Compatible System Family: ' + eventValue);
      if (eventValue) {
        this.selections.selectedCompatibleSystemFamily = eventValue;
      } else {
        this.selections.selectedCompatibleSystemFamily = null;
      }

      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.triggerNewSearch();
      }, DELAY);

    }

    handleCompatibleSystemModelSelectionChange(event) {
      console.log('compatible system model event');
      let eventValue = event.target.value;
      console.log('selected Compatible System Model: ' + eventValue);
      if (eventValue) {
        this.selections.selectedCompatibleSystemModel = eventValue;
      } else {
        this.selections.selectedCompatibleSystemModel = null;
      }

      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.triggerNewSearch();
      }, DELAY);
    }

    handleCompatibleSystemSoftwareVersionSelectionChange(event) {
      console.log('compatible system software version event');
      let eventValue = event.target.value;
      console.log('selected Compatible Software Version: ' + eventValue);
      if (eventValue) {
        this.selections.selectedCompatibleSystemSoftwareVersion = eventValue;
      } else {
        this.selections.selectedCompatibleSystemSoftwareVersion = null;
      }

      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.triggerNewSearch();
      }, DELAY);

    }

    handleCompatibleSystemRevisionLevelSelectionChange(event) {
      console.log('compatible system revision level event');
      let eventValue = event.target.value;
      console.log('selected Compatible Revision Level: ' + eventValue);
      if (eventValue) {
        this.selections.selectedCompatibleSystemRevisionLevel = eventValue;
      } else {
        this.selections.selectedCompatibleSystemRevisionLevel = null;
      }

      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.triggerNewSearch();
      }, DELAY);

    }

    handleOEMSelectionChange(event) {
      console.log('oem event');
      let eventValue = event.target.value;
      console.log('selected OEM: ' + eventValue);
      if (eventValue) {
        this.selections.selectedOEM = eventValue;
      } else {
        this.selections.selectedOEM = null;
      }

      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.triggerNewSearch();
      }, DELAY);

    } 

    handlePartTypeSelectionChange(event) {
      console.log('part type event');
      let eventValue = event.target.value;
      console.log('selected part type: ' + eventValue);
      if (eventValue) {
        this.selections.selectedPartType = eventValue;
      } else {
        this.selections.selectedPartType = null;
      }

      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.triggerNewSearch();
      }, DELAY);

    } 

    handleModalitySelectionChange(event) {
      console.log('modality event');
      let eventValue = event.target.value;
      console.log('selected modality: ' + eventValue);
      if (eventValue) {
        this.selections.selectedModality = eventValue;
      } else {
        this.selections.selectedModality = null;
      }

      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.triggerNewSearch();
      }, DELAY);

    } 

    // Product search methods
    handleSearchKeyChange(event) {
        window.clearTimeout(this.delayTimeout);
        this.searchString = event.target.value;
        console.log('search string: ' + this.searchString);
        
        if (this.searchString != null && this.searchString.length > 2) {
            console.log('processing new request');
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.delayTimeout = setTimeout(() => {
              this.triggerNewSearch();
            }, SEARCH_DELAY);
        }
    }

  

    triggerNewSearch() {
      if ((this.selections.isPartsOnlySearch == false && this.searchString != null && this.searchString.length > 2) ||
          (this.selections.isPartsOnlySearch == true)) {
          this.productDataAvailable = false;
          
          if (this.partsProductData.length > 0) {
              this.partsProductData.length = 0;
          }
          
          this.messages.searchResultsMessage = '';
          this.messages.searchResultsMessageAvailable = false;

          console.log('triggering new search....');

          let newRequest;
    
          if (this.selections.isPartsOnlySearch == true) {
              console.log('adding parts only search filters....');
              newRequest = {
                partsOnly: this.selections.isPartsOnlySearch,
                queryString: this.searchString,
                family: this.selections.selectedFamilies,
                //functionalRating: this.selections.selectedFunctionalRating,
                //cosmeticRating: this.selections.selectedCosmeticRating,
                //checkInType: this.selections.selectedCheckInType,
                //reviewStatus: this.selections.selectedReviewStatus,
                //domestic: this.selections.selectedDomesticOption,
                compatibleSystemOEM: this.selections.selectedCompatibleSystemOEM,
                compatibleSystemFamily: this.selections.selectedCompatibleSystemFamily,
                compatibleSystemModel: this.selections.selectedCompatibleSystemModel,
                compatibleSystemSoftwareVersion: this.selections.selectedCompatibleSystemSoftwareVersion,
                compatibleSystemRevisionLevel: this.selections.selectedCompatibleSystemRevisionLevel,
                oem: this.selections.selectedOEM,
                partType: this.selections.selectedPartType,
                modality: this.selections.selectedModality
              };
          } else {
              console.log('using regular search filters....');
              newRequest = {
                partsOnly: this.selections.isPartsOnlySearch,
                queryString: this.searchString,
                family: this.selections.selectedFamilies,
                //functionalRating: this.selections.selectedFunctionalRating,
                //cosmeticRating: this.selections.selectedCosmeticRating,
                //checkInType: this.selections.selectedCheckInType,
                //reviewStatus: this.selections.selectedReviewStatus,
                //domestic: this.selections.selectedDomesticOption
              };
          }


          this.tableRequest = newRequest;
          this.handleSearch();
          
      }
    }

    handleSearch() {
      getProducts({ queryParams: this.tableRequest })
          .then(result => {
            try {
                  this.error = undefined;
                  let recordIdsReceived = [];
                  
                  if (result && result.length > 0) {
                    this.productData = flattenQueryResult(result);
                    //this.productDataAvailable = true;
                                        
                    console.log('data received from wire method.');
                    for (let record of this.productData) { 
                        //console.log('record');
                        //console.log(record);
                        //console.log('price ' + record.Price__c);
                        //console.log('exchange ' + record.Exchange__c);
                        console.log('Id ' + record.Id);
                        let recordIdPosition = recordIdsReceived.indexOf(record.Id);

                        if (recordIdPosition == -1) {
                            recordIdsReceived.push(record.Id);
                            
                            if (record.Name !== undefined) {
                                console.log('Part Number ' + record.Part_Number__c);

                                let partsRecord = {
                                    id: record.Id,
                                    url: '/' + record.Name,
                                    quantity: 1,
                                    partStatus: 'WIP',
                                    partSubLocation: null,
                                    serialNumber: null,
                                    //cost: record.Cost__c,
                                    selected: false,
                                    saved: false,
                                    data: record,
                                    functionalRating: null,
                                    dateOfManufacture: null,
                                    tubeCount: null,
                                    tubeCountDate: null
                                };

                                if (this.harvestWorkOrder.location) {
                                   partsRecord.partSubLocation = this.harvestWorkOrder.location;
                                   console.log('setting default sub location to: ' + partsRecord.partSubLocation);
                                }
                                if (this.harvestWorkOrder.functionalRating) {
                                  partsRecord.functionalRating = this.harvestWorkOrder.functionalRating;
                                  console.log('setting default functional rating to: ' + partsRecord.functionalRating);
                               }
                                console.log('parts record ' +partsRecord);
                                this.partsProductData.push(partsRecord);
                                this.partsProductDataMap.set(record.Id, partsRecord);
                                
                            }
                            
                        }      
                    }
                    
                    if (this.partsProductData.length > 0 || this.purchasingProductData.length > 0) {
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
            this.error = TypeError;
            console.log('type error occurred in search: ' + this.error);
            return false;
          })
          .catch(error => {
              this.error = error;
              console.log('error occurred in search: ' + this.error);
              return false;
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
  

   // Line item methods

    handlePartsSelection(event) {
        console.log('handle parts selection event');
        let isChecked = event.target.checked;
        console.log('is checked' + isChecked);
        let selectedRecord;
        let eventValue = event.currentTarget.getAttribute("data-selection");
        console.log('event value' + eventValue);

        selectedRecord = this.partsProductDataMap.get(eventValue);
        
        selectedRecord.selected = isChecked;
        let obj = this.productDataMap.get(eventValue);
        const selectedItemPosition = this.newAssetData.indexOf(obj);
        console.log('selected part record:' + obj);
        console.log('selected part record position in selected items:' + selectedItemPosition);
        if (isChecked) {
            console.log('adding selected part to list');
            this.currentnewAssetRecord = obj;     
            if (selectedItemPosition == -1) {
            this.newAssetData.push(obj);
            this.newAssetEditedData.push(selectedRecord);
            this.newAssetDataMap.set(eventValue, selectedRecord);
            this.newAssetDataAvailable = true;
            }
        } else {
            console.log('removing from part list');
            if (selectedItemPosition != -1) {
            this.newAssetData.splice(selectedItemPosition,1);
            this.newAssetEditedData.splice(selectedItemPosition,1);
            this.newAssetDataMap.delete(eventValue);
            }

        }

        this.selectedPartsCount = this.newAssetData.length;
    
    }

    handlePartsDeselection(event) {
        console.log('handle part deselection event in search component');
        
        let eventValue = event.detail.key;
        console.log('event value: ' + eventValue);
        let deSelectedRecord;
            
        deSelectedRecord = this.partsProductDataMap.get(eventValue);

        deSelectedRecord.selected = false;
        let obj = this.productDataMap.get(eventValue);
        let selectedItemPosition = this.newAssetData.indexOf(obj);
        console.log('selected part record:' + deSelectedRecord);
        console.log('selected part record position in selected items:' + selectedItemPosition);
        
        
        if (selectedItemPosition != -1) {
            console.log('removing from part list');
            this.newAssetData.splice(selectedItemPosition,1);
            this.newAssetEditedData.splice(selectedItemPosition,1);
            this.newAssetDataMap.delete(eventValue);
        }
        
        this.selectedPartsCount = this.newAssetData.length;
        if (this.newAssetData.length == 0) {
            this.newAssetDataAvailable = false;
        }

        this.selections.selectedItemToRemove = null;
        this.selections.showModal = false;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            this.triggerNewSearch();
        }, DELAY);

    }

    handleQuantityChange(event) {
      console.log('handleQuantityChange in search component');
      let eventId = event.detail.key;
      console.log('id: ' + eventId);
      let updatedQuantity = event.detail.quantity;
      console.log('updated quantity: ' + updatedQuantity);
      let obj;
      
      obj = this.partsProductDataMap.get(eventId);
      
      console.log('selected  record:' + obj);
      console.log('current quantity: ' + obj.quantity);
      
      obj.quantity = updatedQuantity;
      console.log('updated quantity: ' + obj.quantity);
      
    }

    handleSubLocationChange(event) {
      console.log('handleSubLocationChange in search component');
      let eventId = event.detail.key;
      console.log('id: ' + eventId);
      let updatedSubLocation = event.detail.sublocation;
      console.log('updated sub location: ' + updatedSubLocation);
      let obj;
      
      obj = this.partsProductDataMap.get(eventId);
      
      console.log('selected  record:' + obj);
      console.log('current sub location: ' + obj.partSubLocation);
      
      obj.partSubLocation = updatedSubLocation;
      console.log('updated location: ' + obj.partSubLocation);

      // reset validation
      this.messages.invalidRecordCount = null;
      this.messages.validationErrorMessage = null;
      this.messages.validationErrorMessageAvailable = false;
      
    }

    handleSerialNumberChange(event) {
      console.log('handleSerialNumberChange in search component');
      let eventId = event.detail.key;
      console.log('id: ' + eventId);
      let updatedSerialNumber = event.detail.serialnumber;
      console.log('updated serial number: ' + updatedSerialNumber);
      let obj;
      
      obj = this.partsProductDataMap.get(eventId);
      
      console.log('selected  record:' + obj);
      console.log('current serial number: ' + obj.serialNumber);
      
      obj.serialNumber = updatedSerialNumber;
      console.log('updated serial number: ' + obj.serialNumber);
      
    }

    handleCosmeticRatingChange(event) {
      console.log('handleCosmeticRatingChange in search component');
      let eventId = event.detail.key;
      console.log('id: ' + eventId);
      let updatedCosmeticRating = event.detail.cosmeticRating;
      console.log('updated cosmetic rating: ' + updatedCosmeticRating);
      let obj;
      
      obj = this.partsProductDataMap.get(eventId);
      
      console.log('selected  record:' + obj);
      console.log('current cosmetic rating: ' + obj.cosmeticRating);
      
      obj.cosmeticRating = updatedCosmeticRating;
      console.log('updated cosmetic Rating: ' + obj.cosmeticRating);
      
    }

    handleDateOfManufactureChange(event) {
      console.log('handleDOMChange in search component');
      let eventId = event.detail.key;
      console.log('id: ' + eventId);
      let updatedDateOfManufacture = event.detail.dateOfManufacture;
      console.log('updated DOM: ' + updatedDateOfManufacture);
      let obj;
      
      obj = this.partsProductDataMap.get(eventId);
      
      console.log('selected  record:' + obj);
      console.log('current DOM: ' + obj.dateOfManufacture);
      
      obj.dateOfManufacture = updatedDateOfManufacture;
      console.log('updated DOM: ' + obj.dateOfManufacture);
      
    }

    handleTubeCountChange(event) {
      console.log('handleTubeCountChange in search component');
      let eventId = event.detail.key;
      console.log('id: ' + eventId);
      let updatedTubeCount = event.detail.tubeCount;
      console.log('updated tube count: ' + updatedTubeCount);
      let obj;
      
      obj = this.partsProductDataMap.get(eventId);
      
      console.log('selected  record:' + obj);
      console.log('current tube count: ' + obj.tubeCount);
      
      obj.tubeCount = updatedTubeCount;
      console.log('updated tube count: ' + obj.tubeCount);
      
    }

    handleTubeCountDateChange(event) {
      console.log('handleTubeCountDateChange in search component');
      let eventId = event.detail.key;
      console.log('id: ' + eventId);
      let updatedTubeCountDate = event.detail.tubeCountDate;
      console.log('updated tube count date: ' + updatedTubeCountDate);
      let obj;
      
      obj = this.partsProductDataMap.get(eventId);
      
      console.log('selected  record:' + obj);
      console.log('current tube count date: ' + obj.tubeCountDate);
      
      obj.tubeCountDate = updatedTubeCountDate;
      console.log('updated tube count date: ' + obj.tubeCountDate);
      
    }

    // save methods
    handleSaveAndClose(event) {
      this.validateRecords();
      if (this.messages.invalidRecordCount == null) {
          this.saveAssets(event, true);
      } else {
        this.messages.validationErrorMessage = 'Please enter the Sub Location in your selected items';
        this.messages.validationErrorMessageAvailable = true;
      }  
    }
    
    handleSave(event) {
      this.validateRecords();
      if (this.messages.invalidRecordCount == null) {
        this.selections.saveButtonPressed = true;
        this.saveAssets(event, false);
        this.selections.saveButtonPressed = false;
      } else {
        this.messages.validationErrorMessage = 'Please enter the Sub Location in your selected items';
        this.messages.validationErrorMessageAvailable = true;
      }   
    } 

    saveAssets(event, saveAndClose) {
      var url = '/' + this.localRecordId;
      console.log('handle save event');
      this.selections.saveInProgress = true;
      this.messages.saveAssetsErrorMessage = '';
      this.messages.saveAssetsErrorMessageAvailable = false;
      
      if (this.newAssetData.length > 0 ) {
          //let swapItems = [];
          //let purchasingItems = [];
          let assetItems = [];
            
          console.log('processing items');
          for (let key of this.newAssetDataMap.keys()) { 
              let record = this.newAssetDataMap.get(key);
              if (record.selected && !record.saved) {
                  console.log('found selected item');
                  var partReviewStatus = '';
                  if(record.cosmeticRating == 'Good' && record.functionalRating == 'Good'){
                    partReviewStatus = 'Finished Goods';
                  }
                  if(record.functionalRating != 'Good'){
                    partReviewStatus = 'Work in Progress - Functional';
                  }
                  if(record.cosmeticRating != 'Good'){
                    partReviewStatus = 'Work in Progress - Cosmetic';
                  }
                  let assetRecord = {
                      id: key,
                      quantity: parseInt(record.quantity),
                      partSubLocation: String(record.partSubLocation),
                      serialNumber: record.serialNumber,
                      record: record.data,
                      cosmeticRating: record.cosmeticRating,
                      functionalRating: record.functionalRating,
                      reviewStatus: partReviewStatus,
                      dateOfManufacture: record.dateOfManufacture,
                      tubeCount: record.tubeCount,
                      tubeCountDate: record.tubeCountDate
                  };
                  assetItems.push(assetRecord);
                  console.log('selected item sub location: ' + assetRecord.partSubLocation);
              }
          }  
         
          
          if (assetItems.length > 0 ) {
              if (saveAndClose){ 
                  this.hideSpinner = false;
              }
              
               // Create assets as needed
               if (this.localAction == 'addAsset') {
                  console.log('creating assets');
                  let saveResult = this.handleCreateAssets(assetItems, saveAndClose);
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

      for (let key of this.newAssetDataMap.keys()) { 
        let record = this.newAssetDataMap.get(key);
        if (!record.partSubLocation) {
            console.log('found record missing sub location');
            counter += 1;
        }

      }

      if (counter != 0) {
         this.messages.invalidRecordCount = counter;
         console.log('invalid record count updated: ' + this.messages.invalidRecordCount);
      }
    }  
  
    handleCreateAssets(assetItems, saveAndClose) {
      let result = createAssets({
        selectedItems: assetItems, harvestWorkOrderId: this.localRecordId
        })
        .then((result) => {
        console.log('result: ' + result);
        this.hideSpinner = true;

        if (result == 'success') {
            console.log('save complete');
            
            this.messages.saveOLISuccessMessage = 'Assets created successfully';
            this.messages.saveOLISuccessMessageAvailable = true;
            

            if (this.newAssetDataMap.size > 0) {
              for (let key of this.newAssetDataMap.keys()) {
                  let record = this.newAssetDataMap.get(key);
                  record.saved = true;
                  console.log('record marked as saved : ' + record.data.Name);
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
            console.log('error occurred during save');
            if (result){
            this.messages.saveAssetsErrorMessage = 'Error occurred during Save: ' + result;
            this.messages.saveAssetsErrorMessageAvailable = true;
            }
            return null;
        }

        })
        .catch((error) => {
          this.error = this.getErrorMessage(error);
          console.log('Error occurred in handleCreateAssets: ' + this.error);
            //this.message = 'Error received: code' + error.errorCode + ', ' +
            //    'message ' + error.message;
        }); 


    }

    get dynamicTableClass() { 
        return `height:450px; width:${this.tableWidth}px;`;
    }
  
    get partsOnlySearch() {
        if (this.selections.selectedFamilies.length == 1 && this.selections.selectedFamilies[0] =='Ultrasound Part') {
            console.log('parts only search');
            this.selections.isPartsOnlySearch = true;
            return true;
        } else {
          console.log('regular search');
          this.selections.isPartsOnlySearch = false;
          this.resetPartsFilters();
          return false;
        }

    }
  
  
    resetPartsFilters() {
      this.selections.selectedCompatibleSystemOEM = null;
      this.selections.selectedCompatibleSystemFamily = null;
      this.selections.selectedCompatibleSystemModel = null;
      this.selections.selectedCompatibleSystemSoftwareVersion = null;
      this.selections.selectedCompatibleSystemRevisionLevel = null;
      this.selections.selectedOEM = null;
      this.selections.selectedPartType = null;
      this.selections.selectedModality = null;
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