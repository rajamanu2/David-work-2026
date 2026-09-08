/* eslint-disable no-console */
import { LightningElement, api, wire, track } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
//import { getRecord } from 'lightning/uiRecordApi';
import getObjectsAccess from '@salesforce/apex/UserHasAccess.getObjectsAccess';
import createOpportunityLineItems from '@salesforce/apex/OpportunityLineItemServices.createOpportunityLineItems';
import getFieldNames from '@salesforce/apex/DataTableServices.getFieldNames';
import getProducts from '@salesforce/apex/OpportunityLineItemServices.getProducts';
import getOpportunityRecordTypeName from '@salesforce/apex/OpportunityLineItemServices.getOpportunityRecordTypeName';
import checkPriceFieldAccess from '@salesforce/apex/OpportunityLineItemServices.checkPriceFieldAccess';
import deleteOpportunityLineItem from '@salesforce/apex/OpportunityLineItemServices.deleteOpportunityLineItem';
import PRODUCTITEM_OBJECT from '@salesforce/schema/ProductItem__c';
//import FUNCTIONAL_RATING_FIELD from '@salesforce/schema/ProductItem__c.Functional_Rating__c';
import COSMETIC_RATING_FIELD from '@salesforce/schema/ProductItem__c.Cosmetic_Rating__c';
import CHECK_IN_TYPE_FIELD from '@salesforce/schema/ProductItem__c.Check_In_Type__c';
import REVIEW_STATUS_FIELD from '@salesforce/schema/ProductItem__c.Review_Status__c';

const SEARCH_DELAY = 500;
const DELAY = 10;
const opportunityFields = [
  'Opportunity.RecordTypeId'
];

export default class AddProductLwc extends LightningElement {
    @api opportunityId;
    @api action;
    @track searchTerm;
    @track productData;
    @track productDataAvailable = false;
    @track tableRequest;
    @track pageSettings = {
      activeSections: ['searchResults', 'selectedItems', 'swappedItems'],
      objectsToCheckForAccess: ['Product2', 'ProductItem__c', 'Opportunity', 'OpportunityLineItem'],
      objectsAccessResult: null
    }
    @track hideSpinner = false;
    @track showOLISelectionPage = false;
    @track showAddProductPage = false;
    @track currentAction;
    @track selectedOLIData = [];
    @track selectedOLIDataAvailable = false;
    @track currentOLIRecord;
    @track currentOLIRecordPosition = 0;
    @track currentNewOLIRecord;
    @track newOLIData = [];
    @track newOLIEditedData = [];
    @track newOLIDataMap = new Map();
    @track newOLIDataAvailable = false;
    @track productDataMap = new Map();
    @track selectedOLICount = 0;
    @track selections = {
        selectedFamilies: [],
        selectedFunctionalRating: [],
        selectedCosmeticRating: [],
        selectedCheckInType: [],
        selectedReviewStatus: [],
        selectedDomesticOption: true,
        selectedCompatiblePartsOption: true,
        selectedAvailableOption: true,
        showModal: false,
        selectedItemToRemove: null,
        functionalRatingValues: ['New','Good','Fair','Bad'],
        functionalRatings: [{value:'New', selected: false},{value:'Good', selected: false},{value:'Fair', selected: false},{value:'Bad', selected: false}],
        checkInTypeValues: [],
        checkInTypes: [],
        productFamilyValues: ['Probe','System','Parts','Non-Inventory', 'Other'],
        productFamilies: [{key:'Ultrasound Probe', value:'Probe', selected: false},{key:'Ultrasound System', value:'System', selected: false},{key:'Part', value:'Parts', selected: false},{key:'Non Inventory Item', value:'Non-Inventory', selected: false},{key:'Other Medical Equipment', value:'Other', selected: false}],
        saveInProgress: false
    }    
    @track swapOLICount = 0;
    @track swapOLIData = [];
    @track swapOLIDataAvailable = false;
    @track swapOLIRecords = [];
    @track error;
    @track currentHoverRecordId;
    @track left;
    @track top;
    @track searchString;
    @track columnSettings = {
            columnsToHide: null,
            showCompatibleSystemColumn: true,
            showCheckInTypeColumn: true,
            showReservedColumn: true,
            showPurchasingApprovedColumn: true,
            showPostedOnEbayColumn: true,
            showVendorNameColumn: true,
            showReviewStatusColumn: true,
            showLocationColumn: true,
            showFunctionalRatingColumn: true,
            showCosmeticRatingColumn: true,
            showPriceColumn: true,
            showSugPrOutColumn: true,
            showSugPrExColumn:  true,
            showStdCostOutColumn: true,
            showStdCostExColumn: true,
            showSugPrWithSystemColumn: true,
            showSpecialOfferColumn: true,
            showSerialNumberColumn: true,
            showPartNumberColumn: true,
            showReceivedDateColumn: true,
            showSysSoftColumn: true,
            showDOMColumn: true,
            showSystemTestColumn: true,
            showPropSTDWholeslPrColumn: true,
            showPropSTDRefurbColumn: true,
            showPropSTDRetailColumn: true,
            showNewSugPrOutColumn: true,
            showNewSugPrExColumn: true,
            showNewStdCostOutColumn: true,
            showNewStdCostExColumn: true
    }
    @track isSalesOpportunity = false;
    @track isInterCompanyTransfer = false;
    @track popOverPermissionSetName;
    @track opportunityRecordTypeName;
    @track purchasingProductData = [];
    @track purchasingProductDataMap = new Map();
    @track salesProductDataMap = new Map();
    @track salesProductData = [];
    @track tableWidth = 5000;
    @track messages = {
          saveOLIErrorMessage: null,
          saveOLIerrorMessageAvailable: false,
          saveOLISuccessMessage: null,
          saveOLISuccessMessageAvailable: false,
          searchResultsMessage: null,
          searchResultsMessageAvailable: false,
          permissionsErrorMessage: null,
          permissionsErrorHeader: null,
          permissionsErrorMessageAvailable: false
    }

    connectedCallback() {
        //this.searchTerm = null;
        //this.tableRequest = null;
        
        if (this.action == 'add') {
          this.showAddProductPage = true;
        } else if (this.action == 'swap') {
          this.showOLISelectionPage = true;
        }
        console.log('opportunity Id in lwc: ' + this.opportunityId);
        console.log('action in lwc: ' + this.action);
        
    }

    @wire(getObjectsAccess, { objectNames: ['Product2', 'ProductItem__c', 'Opportunity', 'OpportunityLineItem'] })
    wiredObjectAccess({ error, data }) {
        if (data) {
            this.pageSettings.objectsAccessResult = data; 
            // data received is a map of maps. Each key in the main map is the object and
            // the value of a map of access levels with true or false
            // for example, mapObjectsAccess: {Opportunity={Create=true, Delete=true, Edit=true, Read=true}, OpportunityLineItem={Create=true, Delete=true, Edit=true, Read=true}, Product2={Create=true, Delete=true, Edit=true, Read=true}, ProductItem__c={Create=true, Delete=true, Edit=true, Read=true}}
            let opportunityAccess = this.pageSettings.objectsAccessResult.Opportunity;
            let opportunityResult = Object.getOwnPropertyNames(opportunityAccess);
            let opportunityMissingPermissions = [];
            console.log('Opportunity Access Levels');
            opportunityResult.forEach(
              function (accessLevel) {
                console.log(accessLevel + ' -> ' + opportunityAccess[accessLevel]);
                // If the access level is false, add it to the list of missing permissions
                if (!opportunityAccess[accessLevel] && accessLevel !== 'Delete') {
                  opportunityMissingPermissions.push(String(accessLevel));
                }
              }
            );

            if (opportunityMissingPermissions.length > 0) {
                this.messages.permissionsErrorMessage = '\nMissing Permissions: Opportunity - ' + opportunityMissingPermissions;
            }

            let opportunityLineItemAccess = this.pageSettings.objectsAccessResult.OpportunityLineItem;
            let opportunityLineItemResult = Object.getOwnPropertyNames(opportunityLineItemAccess);
            let opportunityLineItemMissingPermissions = [];
            console.log('Opportunity Line Item Access Levels');
            opportunityLineItemResult.forEach(
              function (accessLevel) {
                console.log(accessLevel + ' -> ' + opportunityLineItemAccess[accessLevel]);
                if (!opportunityLineItemAccess[accessLevel]) {
                  opportunityLineItemMissingPermissions.push(String(accessLevel));
                }
              }
            );
            
            if (opportunityLineItemMissingPermissions.length > 0) {
              this.messages.permissionsErrorMessage += '\nMissing Permissions: Opportunity Line Item - ' + opportunityLineItemMissingPermissions;
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
              this.messages.permissionsErrorMessage += '\nMissing Permissions: Product - ' + productMissingPermissions;
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
              this.messages.permissionsErrorMessage += '\nMissing Permissions: Asset - ' + productItemMissingPermissions;
            }

            if (this.messages.permissionsErrorMessage) {
               this.messages.permissionsErrorHeader = 'You do not have the correct permissions to use this feature on this record. Please contact your system administrator if you have further questions.';
               this.messages.permissionsErrorMessageAvailable = true;
            }
            
        } 
    }

    @wire(getObjectInfo, { objectApiName: PRODUCTITEM_OBJECT })
    objectInfo;  
    
    //@wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: FUNCTIONAL_RATING_FIELD})
    //functionalRatingPicklistValues;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: COSMETIC_RATING_FIELD})
    cosmeticRatingPicklistValues;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: CHECK_IN_TYPE_FIELD})
    checkInTypePicklistValues({error, data}) {
      if (data) {
          
          for (let record of data.values) { 
            this.selections.checkInTypeValues.push(record.value);
            let checkInType = {value: record.value, selected: false};
            this.selections.checkInTypes.push(checkInType);
          }  
      }
  }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: REVIEW_STATUS_FIELD})
    reviewStatusPicklistValues;

    @wire(checkPriceFieldAccess)
    wiredCheckPriceFieldAccess ({error, data}) {
        if (data) {
            let result = data;
            console.log('price field access: ' + result);
            if (result == 'none') {
                this.columnSettings.showPriceColumn = false;
            }
            
        }
    }
    
    @wire(getOpportunityRecordTypeName, { opportunityId: '$opportunityId' })
    wiredOpportunityRecord({ error, data }) {
        if (data) {
            this.opportunityRecordTypeName = data;
            console.log('opportunity record type name: ' + this.opportunityRecordTypeName);
            if (this.opportunityRecordTypeName != 'Purchasing_Opportunity' && this.opportunityRecordTypeName != 'Big_Iron_Purchasing_Opportunity') {
                this.isSalesOpportunity = true;

              if (this.opportunityRecordTypeName == 'Inter_Company_Material_Transfer') {
                  this.isInterCompanyTransfer = true;
              } 
            }
            this.hideSpinner = true;
        } 
    }
  
    handleSearch() {
      getProducts({ queryParams: this.tableRequest })
          .then(result => {
            try {
                  this.error = undefined;
                  
                  if (result && result.length > 0) {
                    this.productData = this.flattenQueryResult(result);
                    //this.productDataAvailable = true;
                                        
                    console.log('data received from wire method.');
                    for (let record of this.productData) { 
                      console.log('record');
                      console.log(record);
                      console.log('price ' + record.Price__c);
                      console.log('exchange ' + record.Exchange__c);
                      console.log('Id ' + record.Id);
                      
                      if (this.opportunityRecordTypeName == 'Purchasing_Opportunity' || this.opportunityRecordTypeName == 'Big_Iron_Purchasing_Opportunity') {
                        let avgOffer = 0;
                        let avgQuote = 0;
                        if (record.Opportunity_Product__r) {
                          let offerCount = 0;
                          let offerSum = 0;
                          let quoteCount = 0;
                          let quoteSum = 0;
                          for (let lineItem of record.Opportunity_Product__r) {
                                
                                if (lineItem.Probo_s_Offer__c && lineItem.Probo_s_Offer__c != 0) {
                                  offerCount += 1;
                                  offerSum += lineItem.Probo_s_Offer__c;
                                }
                                console.log('offer count ' + offerCount);
                                console.log('offer sum ' + offerSum);

                                if (lineItem.Supplier_s_Quote__c && lineItem.Supplier_s_Quote__c != 0) {
                                  quoteCount += 1;
                                  quoteSum += lineItem.Supplier_s_Quote__c;
                                }  
                                console.log('quote count ' + quoteCount);
                                console.log('quote sum ' + quoteSum);
                          }

                          if (offerCount > 0) {
                            avgOffer = offerSum/offerCount;
                            console.log('avg offer ' + avgOffer);
                          }

                          if (quoteCount > 0) {
                            avgQuote = quoteSum/quoteCount;
                            console.log('avg quote ' + avgQuote);
                          }
                        }
                        if (record.Product_Name__r !== undefined) {
                            let purchasingApprovedValue;
                            let exchangeValue;

                            if (record.Purchasing_Approved__c) {
                              purchasingApprovedValue = 'True';
                            } else {
                              purchasingApprovedValue = 'False';
                            }
                            
                            if (record.Exchange__c !== undefined && record.Exchange__c == true) {
                              exchangeValue = true;
                            } else {
                              exchangeValue = false;
                            }

                            let purchasingRecord = {
                              id: record.Id,
                              url: '/' + record.Id,
                              price: record.Price__c,
                              offer: 0,
                              quote: 0,
                              averageOffer: avgOffer,
                              averageQuote: avgQuote,
                              selected: false,
                              saved: false,
                              exchange: exchangeValue,
                              purchasingApproved: purchasingApprovedValue,
                              data: record
                            };
                            console.log('purchasing record ' + purchasingRecord);
                            this.purchasingProductData.push(purchasingRecord);
                            if (!this.purchasingProductDataMap.has(record.Id)) {
                              this.purchasingProductDataMap.set(record.Id, purchasingRecord);
                            }
                        }
                      } else {
                          if (record.Product_Name__r !== undefined) {
                              let purchasingApprovedValue;
                              let exchangeValue;
                              
                              if (record.Purchasing_Approved__c) {
                                purchasingApprovedValue = 'True';
                              } else {
                                purchasingApprovedValue = 'False';
                              }

                              if (record.Exchange__c) {
                                exchangeValue = true;
                              } else {
                                exchangeValue = false;
                              }

                              let salesRecord = {
                                id: record.Id,
                                url: '/' + record.Id,
                                price: record.Price__c,
                                selected: false,
                                saved: false,
                                exchange: exchangeValue,
                                purchasingApproved: purchasingApprovedValue,
                                data: record
                              };
                              console.log('sales record ' + salesRecord);
                              this.salesProductData.push(salesRecord);
                              if (!this.salesProductDataMap.has(record.Id)) {
                                this.salesProductDataMap.set(record.Id, salesRecord);
                              }
                          }
                      }
                    }
                    
                    if (this.salesProductData.length > 0 || this.purchasingProductData.length > 0) {
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
        this.selections.selectedFamilies = this.addToList(this.selections.selectedFamilies, key);
      } else {
        this.selections.selectedFamilies = this.removeFromList(this.selections.selectedFamilies, key);
      }
      
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.triggerNewSearch();
      }, DELAY);
    }

    handleFunctionalRatingSelectionChange(event) {
      console.log('functional Rating event');
      let eventValue = event.currentTarget.getAttribute("data-value");
      console.log('event value: ' + eventValue);
      const selectedItemPosition = this.selections.functionalRatingValues.indexOf(eventValue);
      console.log('event position: ' + selectedItemPosition);
      let currentFunctionalRating = this.selections.functionalRatings[selectedItemPosition];
      console.log('current rating: ' + currentFunctionalRating);
      currentFunctionalRating.selected = !currentFunctionalRating.selected;
      console.log('event selected: ' + currentFunctionalRating.selected);
      console.log('event value: ' + currentFunctionalRating.value);
      
      if (currentFunctionalRating.selected) {
        this.selections.selectedFunctionalRating = this.addToList(this.selections.selectedFunctionalRating, eventValue);
      } else {
          this.selections.selectedFunctionalRating = this.removeFromList(this.selections.selectedFunctionalRating, eventValue);
      } 
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.triggerNewSearch();
      }, DELAY);

    }
  
    handleCosmeticRatingSelectionChange(event) {
      let eventValue = event.currentTarget.getAttribute("data-value");
      let isChecked = event.target.checked;
      if (isChecked) {
          this.selections.selectedCosmeticRating = this.addToList(this.selections.selectedCosmeticRating, eventValue);
      } else {
         this.selections.selectedCosmeticRating = this.removeFromList(this.selections.selectedCosmeticRating, eventValue);
      } 
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.triggerNewSearch();
      }, DELAY);
    }  

    handleCheckInTypeSelectionChange(event) {
      console.log('check in type event');
      let eventValue = event.currentTarget.getAttribute("data-value");
      console.log('event value: ' + eventValue);
      const selectedItemPosition = this.selections.checkInTypeValues.indexOf(eventValue);
      console.log('event position: ' + selectedItemPosition);
      let currentCheckInType = this.selections.checkInTypes[selectedItemPosition];
      console.log('current check in type: ' + currentCheckInType);
      currentCheckInType.selected = !currentCheckInType.selected;
      console.log('event selected: ' + currentCheckInType.selected);
      console.log('event value: ' + currentCheckInType.value);
      
      if (currentCheckInType.selected) {
          this.selections.selectedCheckInType = this.addToList(this.selections.selectedCheckInType, eventValue);
      } else {
          this.selections.selectedCheckInType = this.removeFromList(this.selections.selectedCheckInType, eventValue);
      } 
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.triggerNewSearch();
      }, DELAY);

    }

    handleReviewStatusSelectionChange(event) {
      let eventValue = event.currentTarget.getAttribute("data-value");
      let isChecked = event.target.checked;
      if (isChecked) {
          this.selections.selectedReviewStatus = this.addToList(this.selections.selectedReviewStatus, eventValue);
      } else {
         this.selections.selectedReviewStatus = this.removeFromList(this.selections.selectedReviewStatus, eventValue);
      } 
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.triggerNewSearch();
      }, DELAY);
    }

    handleDomesticToggleChange(event) {
      let isChecked = event.target.checked;
      //console.log('is checked: ' + isChecked);
      if (isChecked) {
        this.selections.selectedDomesticOption = true;
      } else {
        this.selections.selectedDomesticOption = false;
      }
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.triggerNewSearch();
      }, DELAY);
    }


    handleAvailableToggleChange(event) {
      let isChecked = event.target.checked;
      //console.log('is checked: ' + isChecked);
      if (isChecked) {
        this.selections.selectedAvailableOption = true;
      } else {
        this.selections.selectedAvailableOption = false;
      }
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.triggerNewSearch();
      }, DELAY);
    }

    handleColumnsToHide() {
      var permissionSetName;
      console.log('calling handleColumnsToHide ' + this.selectedFamilies.length);


      if (this.isProbeFamilySelected) {
        permissionSetName = 'Ultrasound_Probe_Fields_To_Hide';
        this.popOverPermissionSetName = 'Ultrasound_Probe_Fields_To_Show';
        console.log('Ultrasound Probe family selected');
        this.columnSettings.showPropSTDWholeslPrColumn = false;
        this.columnSettings.showPropSTDRefurbColumn = false;
        this.columnSettings.showPropSTDRetailColumn = false;
        this.tableWidth = 4900;
      } else if (this.isSystemFamilySelected) {
        permissionSetName = 'Ultrasound_System_Fields_To_Hide';
        this.popOverPermissionSetName = 'Ultrasound System Fields To Show';
        console.log('Ultrasound System family selected');
        this.columnSettings.showNewSugPrOutColumn = false;
        this.columnSettings.showNewSugPrExColumn = false;
        this.columnSettings.showNewStdCostOutColumn = false;
        this.columnSettings.showNewStdCostExColumn = false;
        this.tableWidth = 4900;
      } else if (this.isPartsFamilySelected) {
        permissionSetName = 'Ultrasound_Part_Fields_To_Hide';
        this.popOverPermissionSetName = 'Ultrasound Part Fields To Show';
        console.log('Ultrasound Part family selected');
      }

      if (permissionSetName) {
        getFieldNames({ strObjectName: 'ProductItem__c', strFieldSetName: permissionSetName })
            .then(fieldResult => {
                this.error = undefined;
                
                if (fieldResult && fieldResult.length > 0) {
                  this.columnSettings.columnsToHide = fieldResult;
                  
                  for (let col of this.columnSettings.columnsToHide) { 
                    console.log('column');
                    console.log(col);
                    switch (String(col)) {
                      case 'Compatible_System__c':
                        console.log('found column to hide');
                        this.columnSettings.showCompatibleSystemColumn = false;
                        break;
                      case 'Check_In_Type__c':
                        console.log('found column to hide');
                        this.columnSettings.showCheckInTypeColumn = false;
                        break;
                      case 'Reserved__c':
                        console.log('found column to hide');
                        this.columnSettings.showReservedColumn = false;
                        break;
                      case 'Purchasing_Approved__c':
                        console.log('found column to hide');
                        this.columnSettings.showPurchasingApprovedColumn = false;
                        break;
                      case 'Posted_on_Ebay__c':
                        console.log('found column to hide');
                        this.columnSettings.showPostedOnEbayColumn = false;
                        break;
                      case 'Vendor_Name__c':
                        console.log('found column to hide');
                        this.columnSettings.showVendorNameColumn = false;
                        break;
                      case 'Review_Status__c':
                        console.log('found column to hide');
                        this.columnSettings.showReviewStatusColumn = false;
                        break;
                      case 'Location__c':
                        console.log('found column to hide');
                        this.columnSettings.showLocationColumn = false;
                        break;
                      case 'Functional_Rating__c':
                        console.log('found column to hide');
                        this.columnSettings.showFunctionalRatingColumn = false;
                        break;
                      case 'Cosmetic_Rating__c':
                        console.log('found column to hide');
                        this.columnSettings.showCosmeticRatingColumn = false;
                        break;
                      case 'Price__c':
                        console.log('found column to hide');
                        this.columnSettings.showPriceColumn = false;
                        break;
                      case 'Sug_Pr_Out__c':
                        console.log('found column to hide');
                        this.columnSettings.showSugPrOutColumn = false;
                        break;
                      case 'Sug_Pr_Ex__c':
                        console.log('found column to hide');
                        this.columnSettings.showSugPrExColumn = false;
                        break;
                      case 'Std_Cost_Out__c':
                        console.log('found column to hide');
                        this.columnSettings.showStdCostOutColumn = false;
                        break;
                      case 'Std_Cost_ex__c':
                        console.log('found column to hide');
                        this.columnSettings.showStdCostExColumn = false;
                        break;
                      case 'Sug_Price_with_System__c':
                        console.log('found column to hide');
                        this.columnSettings.showSugPrWithSystemColumn = false;
                        break;
                      case 'Special_Offer_Pricing__c':
                        console.log('found column to hide');
                        this.columnSettings.showSpecialOfferColumn = false;
                        break;
                      case 'Serial_No__c':
                        console.log('found column to hide');
                        this.columnSettings.showSerialNumberColumn = false;
                        break;
                      case 'Part_Number__c':
                        console.log('found column to hide');
                        this.columnSettings.showPartNumberColumn = false;
                        break;
                      case 'Receive_date__cc':
                        console.log('found column to hide');
                        this.columnSettings.showReceivedDateColumn = false;
                        break;
                      case 'System_Software__c':
                        console.log('found column to hide');
                        this.columnSettings.showSysSoftColumn = false;
                        break;
                      case 'Date_of_Manufacture__c':
                        console.log('found column to hide');
                        this.columnSettings.showDOMColumn = false;
                        break;
                      case 'D_System_Test__c':
                        console.log('found column to hide');
                        this.columnSettings.showSystemTestColumn = false;
                        break;
                      default:
                        console.log('no matching column to hide');
                        break;
                    }
                  }
                  
                } 
            })
            .catch(error => {
                this.error = error;
                console.log('error occurred in column retrieval: ' + this.error);
            });
      }

    }

    resetColumnSettings() {
      this.columnSettings = {
        columnsToHide: null,
        showCompatibleSystemColumn: true,
        showCheckInTypeColumn: true,
        showReservedColumn: true,
        showPurchasingApprovedColumn: true,
        showPostedOnEbayColumn: true,
        showVendorNameColumn: true,
        showReviewStatusColumn: true,
        showLocationColumn: true,
        showFunctionalRatingColumn: true,
        showCosmeticRatingColumn: true,
        showPriceColumn: true,
        showSugPrOutColumn: true,
        showSugPrExColumn:  true,
        showStdCostOutColumn: true,
        showStdCostExColumn: true,
        showSugPrWithSystemColumn: true,
        showSpecialOfferColumn: true,
        showSerialNumberColumn: true,
        showPartNumberColumn: true,
        showReceivedDateColumn: true,
        showSysSoftColumn: true,
        showDOMColumn: true,
        showSystemTestColumn: true,
        showPropSTDWholeslPrColumn: true,
        showPropSTDRefurbColumn: true,
        showPropSTDRetailColumn: true,
        showNewSugPrOutColumn: true,
        showNewSugPrExColumn: true,
        showNewStdCostOutColumn: true,
        showNewStdCostExColumn: true
      };
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

    triggerNewSearch() {
      if (this.searchString != null && this.searchString.length > 2) {
          this.productDataAvailable = false;
          //this.productData.length = 0;
          //this.productDataMap.clear();
          if (this.salesProductData.length > 0) {
              this.salesProductData.length = 0;
          }
          
          if (this.purchasingProductData.length > 0) {
              this.purchasingProductData.length = 0;
          }

          this.messages.searchResultsMessage = '';
          this.messages.searchResultsMessageAvailable = false;

          console.log('triggering new search....');

          let newRequest = {
            queryString: this.searchString,
            family: this.selections.selectedFamilies,
            functionalRating: this.selections.selectedFunctionalRating,
            cosmeticRating: this.selections.selectedCosmeticRating,
            checkInType: this.selections.selectedCheckInType,
            reviewStatus: this.selections.selectedReviewStatus,
            domestic: this.selections.selectedDomesticOption,
            compatibleParts: this.selections.selectedCompatiblePartsOption,
            available: this.selections.selectedAvailableOption
          };
          this.tableRequest = newRequest;
          this.handleSearch();
          if (this.selections.selectedFamilies.length == 1) {
            this.handleColumnsToHide();
          } else if (this.tableWidth !== 5000) {
            if ((this.opportunityRecordTypeName == 'Purchasing_Opportunity' || this.OpportunityRecordTypeName == 'Big_Iron_Purchasing_Opportunity') && this.tableWidth !== 5700) {
              this.tableWidth = 5700;
            } else {
              this.tableWidth = 5000;
            }
            this.resetColumnSettings();
          }
          
      }
    }

    // Existing OLI selection methods (swap) 
    handleOLISelection(event) {
      console.log('handle OLI selectionsuccess event');
      console.log(event.detail);
      this.selectedOLIData.length = 0;
      const selectedRows = event.detail;
      if (selectedRows.length > 0) {
          console.log('selected OLI data available');
          for (let i = 0; i < selectedRows.length; i++){
            //console.log("selected item: " + selectedRows[i]);
            this.selectedOLIData.push(selectedRows[i]);
          }
          this.selectedOLIDataAvailable = true;
      }
      
    }

    handleOLISelectionComplete(event) {
      console.log('handle OLI selection complete event');
      this.showOLISelectionPage = false;
      this.showAddProductPage = true;

      if (this.selectedOLIData.length > 0) {
        this.currentOLIRecord = this.selectedOLIData[0];
        this.searchTerm = this.currentOLIRecord.Product_Name__c;
        console.log('searchTerm: ' + this.searchTerm);
        let searchEvent = new CustomEvent('searchLoad', {detail: this.searchTerm});
        this.handleSearchLoad(searchEvent);
      }
    } 

    
    handlePrevious(event) {
      console.log('handle previous event');
      this.currentOLIRecordPosition = event.detail;
      console.log('current position: ' + this.currentOLIRecordPosition);
      this.currentOLIRecord = this.selectedOLIData[this.currentOLIRecordPosition];
      console.log('current oli record: ' + this.currentOLIRecord);
      this.productData.length = 0;
      this.salesProductData.length = 0;
      this.purchasingProductData.length = 0;
      this.productDataAvailable = false;
      this.searchTerm = this.currentOLIRecord.Product_Name__c;
      console.log('searchTerm: ' + this.searchTerm);
      let searchEvent = new CustomEvent('searchLoad', {detail: this.searchTerm});
      this.handleSearchLoad(searchEvent);
    } 

    handleNext(event) {
      console.log('handle next event');
      this.currentOLIRecordPosition = event.detail;
      console.log('current position: ' + this.currentOLIRecordPosition);
      this.currentOLIRecord = this.selectedOLIData[this.currentOLIRecordPosition];
      console.log('current oli record: ' + this.currentOLIRecord);
      this.productData.length = 0;
      this.salesProductData.length = 0;
      this.purchasingProductData.length = 0;
      this.productDataAvailable = false;
      this.searchTerm = this.currentOLIRecord.Product_Name__c;
      console.log('searchTerm: ' + this.searchTerm);
      let searchEvent = new CustomEvent('searchLoad', {detail: this.searchTerm});
      this.handleSearchLoad(searchEvent);
    } 

    // New OLI methods
    handleNewOLISelection(event) {
      console.log('handle new OLI selection event');
      let isChecked = event.target.checked;
      console.log('is checked' + isChecked);
      let selectedRecord;
      let eventValue = event.currentTarget.getAttribute("data-selection");
      console.log('event value' + eventValue);

      if (this.opportunityRecordTypeName == 'Purchasing_Opportunity' || this.OpportunityRecordTypeName == 'Big_Iron_Purchasing_Opportunity'){
        selectedRecord = this.purchasingProductDataMap.get(eventValue);
      } else { 
        selectedRecord = this.salesProductDataMap.get(eventValue);
      }
      
      selectedRecord.selected = isChecked;
      let obj = this.productDataMap.get(eventValue);
      const selectedItemPosition = this.newOLIData.indexOf(obj);
      console.log('selected oli record:' + obj);
      console.log('selected oli record position in selected items:' + selectedItemPosition);
      if (isChecked) {
        console.log('adding selected oli to list');
        this.currentNewOLIRecord = obj;     
        if (selectedItemPosition == -1) {
          this.newOLIData.push(obj);
          this.newOLIEditedData.push(selectedRecord);
          this.newOLIDataMap.set(eventValue, selectedRecord);
          this.newOLIDataAvailable = true;
        }
      } else {
        console.log('removing from oli list');
        if (selectedItemPosition != -1) {
          this.newOLIData.splice(selectedItemPosition,1);
          this.newOLIEditedData.splice(selectedItemPosition,1);
          this.newOLIDataMap.delete(eventValue);
        }

        if (this.selectedOLIDataAvailable){
            let swapValue = this.currentOLIRecord.Id + '-' + eventValue;
            if (this.swapOLIData != null && this.swapOLIData.indexOf(swapValue) != -1) {
              const deSelectedItemPosition = this.swapOLIData.indexOf(swapValue);
              console.log('found swap item that has been deselected: ' + deSelectedItemPosition);
              console.log('removing from swap oli list');
              this.swapOLIData.splice(deSelectedItemPosition,1);
              this.swapOLIRecords.splice(deSelectedItemPosition,1);
              this.swapOLICount = this.swapOLIData.length;
            }
        }
      }
 
      this.selectedOLICount = this.newOLIData.length;
     
    }

    handleNewOLIDeselection(event) {
      console.log('handle new OLI deselection event');
      
      let eventValue = this.selections.selectedItemToRemove;
      console.log('event value: ' + eventValue);
      let deSelectedRecord;
        
      if (this.opportunityRecordTypeName == 'Purchasing_Opportunity' || this.OpportunityRecordTypeName == 'Big_Iron_Purchasing_Opportunity'){
        deSelectedRecord = this.purchasingProductDataMap.get(eventValue);
      } else { 
        deSelectedRecord = this.salesProductDataMap.get(eventValue);
      }

      deSelectedRecord.selected = false;
      let obj = this.productDataMap.get(eventValue);
      let selectedItemPosition = this.newOLIData.indexOf(obj);
      console.log('selected oli record:' + deSelectedRecord);
      console.log('selected oli record position in selected items:' + selectedItemPosition);
      
      
      if (selectedItemPosition != -1) {
        console.log('removing from oli list');
        this.newOLIData.splice(selectedItemPosition,1);
        this.newOLIEditedData.splice(selectedItemPosition,1);
        this.newOLIDataMap.delete(eventValue);
      }
      
      this.selectedOLICount = this.newOLIData.length;
      if (this.newOLIData.length == 0) {
          this.newOLIDataAvailable = false;
      }

      if (this.selectedOLIDataAvailable){
          let swapValue = this.currentOLIRecord.Id + '-' + eventValue;
          if (this.swapOLIData != null && this.swapOLIData.indexOf(swapValue) != -1) {
            const deSelectedItemPosition = this.swapOLIData.indexOf(swapValue);
            console.log('found swap item that has been deselected: ' + deSelectedItemPosition);
            console.log('removing from swap oli list');
            this.swapOLIData.splice(deSelectedItemPosition,1);
            this.swapOLIRecords.splice(deSelectedItemPosition,1);
            this.swapOLICount = this.swapOLIData.length;
          }
      }
      this.selections.selectedItemToRemove = null;
      this.selections.showModal = false;
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.triggerNewSearch();
      }, DELAY);

      // if the selected item had been saved, delete the line item
      if (deSelectedRecord.saved) {
        let deleteResult = deleteOpportunityLineItem({
          productItemId: eventValue,
          opportunityId: this.opportunityId
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

    handleModalOpen(event) {
      let eventValue = event.target.value;
      this.selections.selectedItemToRemove = eventValue;
      this.selections.showModal = true;
    } 
    
    handleModalClose(event) {
      this.selections.selectedItemToRemove = null;
      this.selections.showModal = false;
    }  

    handleSwap(event) {
      console.log('handle swap event');
      if (this.currentOLIRecord == null) {
        this.currentOLIRecord = this.selectedOLIData[0];
      }
      console.log('current OLI to swap: ' + this.currentOLIRecord.Id);
      console.log('current new OLI: ' + this.currentNewOLIRecord.Id);
      const selectedItemPosition = this.swapOLIData.indexOf(this.currentOLIRecord.Id);
      console.log('selected oli record position in swap items:' + selectedItemPosition);
      if (selectedItemPosition != -1) {
        console.log('removing from swap oli list');
        this.swapOLIData.splice(selectedItemPosition,1);
        this.swapOLIRecords.splice(selectedItemPosition,1);
      }  
      let swapValue = this.currentOLIRecord.Id + '-' + this.currentNewOLIRecord.Id;
      console.log('swap value: ' + swapValue);
      this.swapOLIData.push(swapValue);
      let swapRecord = {
        id: this.currentOLIRecord.Id,
        originData: this.currentOLIRecord,
        swapData: this.currentNewOLIRecord,
        saved: false
      };
      this.swapOLIRecords.push(swapRecord);
      this.swapOLICount = this.swapOLIData.length;
      this.swapOLIDataAvailable = true;
    } 

    handleSaveAndClose(event) {
      this.addSwapItem();
      //this.hideSpinner = false;
      this.saveOLI(event, true);
    }

    handleSave(event) {
      this.selections.saveButtonPressed = true;
      this.addSwapItem();
      this.saveOLI(event, false);
      this.selections.saveButtonPressed = false;
    } 

    // Add swap item if the user did not click on the Swap button and there is only
    // one product selected
    addSwapItem() {
      if (this.selectedOLIData.length > 0 && this.swapOLIData.length == 0 && this.newOLIData.length == 1) {
        console.log('calling addSwapItem');
        if (this.currentOLIRecord == null) {
          this.currentOLIRecord = this.selectedOLIData[0];
        }

        let swapValue = this.currentOLIRecord.Id + '-' + this.currentNewOLIRecord.Id;
        console.log('swap value: ' + swapValue);
        this.swapOLIData.push(swapValue);
        let swapRecord = {
          id: this.currentOLIRecord.Id,
          originData: this.currentOLIRecord,
          swapData: this.currentNewOLIRecord,
          saved: false
        };
        this.swapOLIRecords.push(swapRecord);
        this.swapOLIDataAvailable = true;
      }
    }  

    saveOLI(event, saveAndClose) {
      var url = '/' + this.opportunityId;
      console.log('handle save event');
      this.selections.saveInProgress = true;
      this.messages.saveOLIErrorMessage = '';
      this.messages.saveOLIErrorMessageAvailable = false;
      
      if (this.newOLIData.length > 0 || this.swapOLIData.size > 0) {
         let swapItems = [];
         let purchasingItems = [];
         let salesItems = [];
         if (this.opportunityRecordTypeName == 'Purchasing_Opportunity' || this.OpportunityRecordTypeName == 'Big_Iron_Purchasing_Opportunity'){
            console.log('processing Purchasing_Opportunity');
            for (let key of this.newOLIDataMap.keys()) { 
              let record = this.newOLIDataMap.get(key);
              if (record.selected && !record.saved) {
                  console.log('found selected item to save for Purchasing_Opportunity');
                  let purchasingRecord = {
                    id: key,
                    price: parseFloat(record.price),
                    offer: parseFloat(record.offer),
                    quote: parseFloat(record.quote),
                    exchange: record.exchange
                  };
                  purchasingItems.push(purchasingRecord);
              }
            }  
         } else {  
            console.log('processing sales opportunity');
            for (let key of this.newOLIDataMap.keys()) { 
              let record = this.newOLIDataMap.get(key);
              if (record.selected && !record.saved) {
                  console.log('found selected item to save for sales opportunity');
                  let salesRecord = {
                    id: key,
                    price: parseFloat(record.price),
                    exchange: record.exchange
                  };
                  salesItems.push(salesRecord);
              }
            }  
        }

        for (let record of this.swapOLIRecords) {
          if (!record.saved) {
            let swapValue = record.originData.Id + '-' + record.swapData.Id;
            console.log('swap value to save: ' + swapValue);
            swapItems.push(swapValue);
          }
        }
        
        if (salesItems.length > 0 || purchasingItems.length > 0 || swapItems.length > 0) {
            if (saveAndClose){ 
              this.hideSpinner = false;
            }

            let result = createOpportunityLineItems({
              selectedItems: salesItems,
              selectedPurchasingItems: purchasingItems,
              swapItems: swapItems,
              opportunityId: this.opportunityId
            })
            .then((result) => {
              console.log('result: ' + result);
              this.hideSpinner = true;

              if (result == 'success') {
                console.log('save complete');
                
                if (this.swapOLIData.length > 0) {
                  this.messages.saveOLISuccessMessage = 'Swap completed successfully';
                  this.messages.saveOLISuccessMessageAvailable = true;
                } else {
                  this.messages.saveOLISuccessMessage = 'Line items added successfully';
                  this.messages.saveOLISuccessMessageAvailable = true;
                }

                if (this.newOLIDataMap.size > 0) {
                  for (let key of this.newOLIDataMap.keys()) {
                    let record = this.newOLIDataMap.get(key);
                    record.saved = true;
                    console.log('record marked as saved : ' + record.data.Name);
                  }
                }

                if (this.swapOLIRecords.length > 0) {
                  for (let record of this.swapOLIRecords) {
                      record.saved = true;
                  }  
                }
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
                } else {
                  // eslint-disable-next-line @lwc/lwc/no-async-operation
                  //this.delayTimeout = setTimeout(() => {
                  //  this.messages.saveOLISuccessMessageAvailable = false;
                  //}, 2000);
                }
              } else {
                this.selections.saveInProgress = false;
                console.log('error occurred during save');
                if (result){
                  this.messages.saveOLIErrorMessage = 'Error occurred during Save: ' + result;
                  this.messages.saveOLIErrorMessageAvailable = true;
                }
                
              }

            })
            .catch((error) => {
                this.message = 'Error received: code' + error.errorCode + ', ' +
                    'message ' + error.message;
            }); 
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

    handleCancel(event) {
      var url = '/' + this.opportunityId;
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

    handleOfferChange(event) {
      let eventId = event.currentTarget.getAttribute("data-key");
      console.log('id: ' + eventId);
      let updatedOffer = event.target.value;
      console.log('updated offer: ' + updatedOffer);
      let obj = this.purchasingProductDataMap.get(eventId);
      console.log('selected oli record:' + obj);
      console.log('current offer: ' + obj.offer);
      
      obj.offer = updatedOffer;
      console.log('updated offer: ' + obj.offer);
    }

    handleQuoteChange(event) {
      let eventId = event.currentTarget.getAttribute("data-key");
      console.log('id: ' + eventId);
      let updatedQuote = event.target.value;
      console.log('updated quote: ' + updatedQuote);
      let obj = this.purchasingProductDataMap.get(eventId);
      console.log('selected oli record:' + obj);
      console.log('current quote: ' + obj.quote);
      
      obj.quote = updatedQuote;
      console.log('updated quote: ' + obj.quote);
    }

    handlePriceChange(event) {
      let eventId = event.currentTarget.getAttribute("data-key");
      console.log('id: ' + eventId);
      let updatedPrice = event.target.value;
      console.log('updated price: ' + updatedPrice);
      let obj;
      if (this.opportunityRecordTypeName == 'Purchasing_Opportunity' || this.OpportunityRecordTypeName == 'Big_Iron_Purchasing_Opportunity'){
        obj = this.purchasingProductDataMap.get(eventId);
      } else {
        obj = this.salesProductDataMap.get(eventId);
      }
      console.log('selected oli record:' + obj);
      console.log('current price: ' + obj.price);
      
      obj.price = updatedPrice;
      console.log('updated price: ' + obj.price);
    }

    handleExchangeChange(event) {
      let eventId = event.currentTarget.getAttribute("data-key");
      console.log('id: ' + eventId);
      let isChecked = event.target.checked;
      console.log('is checked: ' + isChecked);
      let obj;
      let obj2;

      if (this.opportunityRecordTypeName == 'Purchasing_Opportunity' || this.OpportunityRecordTypeName == 'Big_Iron_Purchasing_Opportunity'){
        obj = this.purchasingProductDataMap.get(eventId);
      } else {
        obj = this.salesProductDataMap.get(eventId);
      }
      console.log('selected oli record:' + obj);
      console.log('current exchange: ' + obj.exchange);
      
      obj.exchange = isChecked;
      obj2 = this.productDataMap.get(eventId);
      obj2.Exchange__c = isChecked;
      this.productDataMap.delete(eventId);
      this.productDataMap.set(eventId, obj2);
      console.log('updated exchange: ' + obj.exchange);
      console.log('updated exchange field: ' + obj2.Exchange__c);
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
      return `height:450px; width:${this.tableWidth}px;`;
    }

    selectPage = (myaction) => {
      console.log('calling selectPage method: ' + myaction);
      if (myaction == 'add') {
        this.showAddProductPage = true;
      } else if (myaction == 'swap') {
        this.showOLISelectionPage = true;
      }
      
      return myaction;
    }  


    addToList = (list, value) => {
      console.log('calling addToList method');
      const selectedItemPosition = list.indexOf(value);

      if (selectedItemPosition == -1) {
        list.push(value);
      }
     
      return list;
    }
    
    removeFromList = (list, value) => {
      console.log('calling removeFromList method');
      const selectedItemPosition = list.indexOf(value);

      if (selectedItemPosition != -1) {
        list.splice(selectedItemPosition,1);
      }
     
      return list;
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