import { LightningElement, api, wire, track } from 'lwc';
import { getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
//import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import getObjectsAccessImperative from '@salesforce/apex/UserHasAccess.getObjectsAccessImperative';
import createOpportunityLineItems from '@salesforce/apex/OpportunityLineItemServices.createOpportunityLineItems';
import createLoanerLineItems from '@salesforce/apex/LoanerLineItemServices.createLoanerLineItems';
import createWorkOrderLineItems from '@salesforce/apex/WorkOrderLineItemServices.createWorkOrderLineItems';
import createRentalOrderLineItems from '@salesforce/apex/RentalOrderLineItemServices.createRentalOrderLineItems';
import getFieldNames from '@salesforce/apex/DataTableServices.getFieldNames';
import getProducts from '@salesforce/apex/AddProductServices.getProducts';
import getUserInfo from '@salesforce/apex/AddProductServices.getUserInfo';
import getOpportunityInfo from '@salesforce/apex/AddProductServices.getOpportunityInfo';
import getWorkOrderInfo from '@salesforce/apex/AddProductServices.getWorkOrderInfo';
import getLoanerInfo from '@salesforce/apex/AddProductServices.getLoanerInfo';
import getRentalOrderInfo from '@salesforce/apex/AddProductServices.getRentalOrderInfo';
import checkPriceFieldAccess from '@salesforce/apex/AddProductServices.checkPriceFieldAccess';
import checkCostFieldAccess from '@salesforce/apex/AddProductServices.checkCostFieldAccess';
import deleteOpportunityLineItem from '@salesforce/apex/OpportunityLineItemServices.deleteOpportunityLineItem';
import PRODUCTITEM_OBJECT from '@salesforce/schema/ProductItem__c';
import COSMETIC_RATING_FIELD from '@salesforce/schema/ProductItem__c.Cosmetic_Rating__c';
import CHECK_IN_TYPE_FIELD from '@salesforce/schema/ProductItem__c.Check_In_Type__c';
import REVIEW_STATUS_FIELD from '@salesforce/schema/ProductItem__c.Review_Status__c';
import OWNERSHIP_FIELD from '@salesforce/schema/ProductItem__c.Ownership__c';
import LOCATION_FIELD from '@salesforce/schema/ProductItem__c.Location__c';

import { flattenObject, flattenQueryResult, addToList,  removeFromList } from 'c/utilitiesLwc';


const SEARCH_DELAY = 500;
const DELAY = 10;


export default class AddProductSearchLwc extends LightningElement {
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
    get selectedOli() {
      return this.selectedOLIData;
    }
    set selectedOli(value) {
        setTimeout(() => {
            this.handleOLISelection(value);
        }, DELAY);    
    }
    @track appointmentId;
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
    @track selectedOLIData = [];
    @track selectedOLIDataAvailable = false;
    @track hasAssetSwapData = null;
    @track currentExchangeValue;
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
        selectedExactSearchOption: false,
        selectedAvailableOption: false,
        showModal: false,
        selectedItemToRemove: null,
        functionalRatingValues: ['New','Good','Fair','Bad'],
        functionalRatings: [{value:'New', selected: false},{value:'Good', selected: false},{value:'Fair', selected: false},{value:'Bad', selected: false}],
        checkInTypeValues: [],
        checkInTypes: [],
        productFamilyValues: ['Probe','System','Parts','Non-Inventory', 'Other'],
        productFamilies: [{key:'Ultrasound Probe', value:'Probe', selected: false},{key:'Ultrasound System', value:'System', selected: false},{key:'Part', value:'Parts', selected: false},{key:'Non Inventory Item', value:'Non-Inventory', selected: false},{key:'Other Medical Equipment', value:'Other', selected: false}],
        productOwnershipValues: [],
        productOwnerships: [],
        productLocationValues: [],
        productLocations: [],
        saveInProgress: false,
        isPartsOnlySearch: false,
        isCompatiblePartsSearch: true,
        isExactSearch: false,
        selectedCompatibleSystemOEM: null,
        selectedCompatibleSystemFamily: null,
        selectedCompatibleSystemModel: null,
        selectedCompatibleSystemRevisionLevel: null,
        selectedCompatibleSystemSoftwareVersion: null,
        selectedOEM: null,
        selectedPartType: null,
        selectedModality: null
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
            showRetailPrOutColumn: true,
            showRetailPrExColumn:  true,
            showDealerPrOutColumn: true,
            showDealerPrExColumn:  true,
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
            showNewStdCostExColumn: true,
            showCostColumn: true
    }
    @track isSalesOpportunity = false;
    @track isMaterialTransfer = false;
    @track popOverPermissionSetName;
    @track opportunity = {
      id: null,
      recordTypeName: null,
      stageName: null,
      dealType: null,
      accountType: null,
      accountTier: null,
      opportunityEntityName: null
    }
    
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
          warningMessage: null,
          warningHeader: null,
          warningMessageAvailable: false,
          closeButtonLabel: null,
          showConfirmationButton: false
    }
    @track user = {
      id: USER_ID,
      profileName: null,
      location: null,
      entityName: null
    }
    @track localRecordId=null;
    @track localObjectName=null;
    @track localAction=null;
    @track serviceContract = {
        id: null,
        opportunity: null
    }
    
    objectsToVerifyAccess;
    pageInitialized = false;
    controlValues;
    totalDependentValues = [];

    
    
    renderedCallback() {

        if (this.pageInitialized) {
          return;
        } else {
            if (this.localObjectName == 'Opportunity') {
                console.log('need to get access to Opportunity');
                this.objectsToVerifyAccess = ['Product2', 'ProductItem__c', 'Opportunity', 'OpportunityLineItem'];
                this.handleGetObjectsAccess();
                this.handleGetUserInfo();
                this.handleGetOpportunityInfo();
            } else if (this.localObjectName == 'WorkOrder') {
                console.log('need to get access to Work Order');
                this.objectsToVerifyAccess = ['Product2', 'ProductItem__c', 'Opportunity', 'OpportunityLineItem', 'ServiceContract', 'WorkOrder', 'WorkOrderLineItem'];
                this.handleGetObjectsAccess();
                this.handleGetUserInfo();
                this.handleGetWorkOrderInfo();
            } else if (this.localObjectName == 'Loaner__c') {
                console.log('need to get access to Loaner');
                this.objectsToVerifyAccess = ['Product2', 'ProductItem__c', 'Opportunity', 'OpportunityLineItem', 'Loaner__c'];
                this.handleGetObjectsAccess();
                this.handleGetUserInfo();
                this.handleGetLoanerInfo();
            } else if (this.localObjectName == 'Rental_Order__c') {
                console.log('need to get access to Rental Order');
                this.objectsToVerifyAccess = ['Product2', 'ProductItem__c', 'Opportunity', 'OpportunityLineItem', 'Rental_Order__c'];
                this.handleGetObjectsAccess();
                this.handleGetUserInfo();
                this.handleGetRentalOrderInfo();
          }  

            
            
            // reset search data
            if (this.salesProductData.length > 0) {
                this.salesProductData.length = 0;
            }
          
            if (this.purchasingProductData.length > 0) {
                this.purchasingProductData.length = 0;
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
                    if (this.localObjectName == 'Loaner__c') {
                        let loanerAccess = this.pageSettings.objectsAccessResult.Loaner__c;
                        let loanerResult = Object.getOwnPropertyNames(loanerAccess);
                        let loanerMissingPermissions = [];
                        
                        console.log('Loaner Access Levels');
                        loanerResult.forEach(
                        function (accessLevel) {
                            console.log(accessLevel + ' -> ' + loanerAccess[accessLevel]);
                            // If the access level is false, add it to the list of missing permissions
                            if (!loanerAccess[accessLevel] && accessLevel !== 'Delete') {
                              loanerMissingPermissions.push(String(accessLevel));
                            }
                        }
                        );

                        if (loanerMissingPermissions.length > 0) {
                            permissionsMessage += '\nMissing Permissions: Loaner - ' + loanerMissingPermissions;
                        }

                    } else if (this.localObjectName == 'Rental_Order__c') {

                        let rentalOrderAccess = this.pageSettings.objectsAccessResult.Rental_Order__c;
                        let rentalOrderResult = Object.getOwnPropertyNames(rentalOrderAccess);
                        let rentalOrderMissingPermissions = [];
                        
                        console.log('Rental Order Access Levels');
                        rentalOrderResult.forEach(
                        function (accessLevel) {
                            console.log(accessLevel + ' -> ' + rentalOrderAccess[accessLevel]);
                            // If the access level is false, add it to the list of missing permissions
                            if (!rentalOrderAccess[accessLevel] && accessLevel !== 'Delete') {
                              rentalOrderMissingPermissions.push(String(accessLevel));
                            }
                        }
                        );

                        if (rentalOrderMissingPermissions.length > 0) {
                            permissionsMessage += '\nMissing Permissions: Rental Order - ' + rentalOrderMissingPermissions;
                        }

                    
                    } else if (this.localObjectName == 'WorkOrder') {
                        let serviceContractAccess = this.pageSettings.objectsAccessResult.ServiceContract;
                        let serviceContractResult = Object.getOwnPropertyNames(serviceContractAccess);
                        let serviceContractMissingPermissions = [];
                        
                        console.log('Service Contract Access Levels');
                        serviceContractResult.forEach(
                        function (accessLevel) {
                            console.log(accessLevel + ' -> ' + serviceContractAccess[accessLevel]);
                            // If the access level is false, add it to the list of missing permissions
                            if (!serviceContractAccess[accessLevel] && accessLevel !== 'Delete') {
                                serviceContractMissingPermissions.push(String(accessLevel));
                            }
                        }
                        );

                        if (serviceContractMissingPermissions.length > 0) {
                            permissionsMessage += '\nMissing Permissions: Service Contract - ' + serviceContractMissingPermissions;
                        }

                        let workOrderAccess = this.pageSettings.objectsAccessResult.WorkOrder;
                        let workOrderResult = Object.getOwnPropertyNames(workOrderAccess);
                        let workOrderMissingPermissions = [];
                        
                        console.log('work Order Access Levels');
                        workOrderResult.forEach(
                        function (accessLevel) {
                            console.log(accessLevel + ' -> ' + workOrderAccess[accessLevel]);
                            // If the access level is false, add it to the list of missing permissions
                            if (!workOrderAccess[accessLevel] && accessLevel !== 'Delete') {
                              workOrderMissingPermissions.push(String(accessLevel));
                            }
                        }
                        );

                        if (workOrderMissingPermissions.length > 0) {
                            permissionsMessage += '\nMissing Permissions: Work Order - ' + workOrderMissingPermissions;
                        }


                        let workOrderLineItemAccess = this.pageSettings.objectsAccessResult.WorkOrderLineItem;
                        let workOrderLineItemResult = Object.getOwnPropertyNames(workOrderLineItemAccess);
                        let workOrderLineItemMissingPermissions = [];
                        console.log('Work Order Line Item Access Levels');
                        workOrderLineItemResult.forEach(
                        function (accessLevel) {
                            console.log(accessLevel + ' -> ' + workOrderLineItemAccess[accessLevel]);
                            if (!workOrderLineItemAccess[accessLevel]) {
                              workOrderLineItemMissingPermissions.push(String(accessLevel));
                            }
                        }
                        );
                        
                        if (workOrderLineItemMissingPermissions.length > 0) {
                            permissionsMessage += '\nMissing Permissions: Work Order Line Item - ' + workOrderLineItemMissingPermissions;
                        }

                    }    

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
                        permissionsMessage += '\nMissing Permissions: Opportunity - ' + opportunityMissingPermissions;
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
                        permissionsMessage += '\nMissing Permissions: Opportunity Line Item - ' + opportunityLineItemMissingPermissions;
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

    @wire(getObjectInfo, { objectApiName: PRODUCTITEM_OBJECT })
    objectInfo;  

    
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

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: OWNERSHIP_FIELD})
    productOwnershipPicklistValues({error, data}) {
      if (data) {
          
          for (let record of data.values) { 
            this.selections.productOwnershipValues.push(record.value);
            let productOwnership = {value: record.value, selected: false};
            this.selections.productOwnerships.push(productOwnership);
          }  
      }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LOCATION_FIELD})
    productLocationPicklistValues({error, data}) {
      if (data) {
          
          for (let record of data.values) { 
            this.selections.productLocationValues.push(record.value);
            let productLocation = {value: record.value, selected: false};
            this.selections.productLocations.push(productLocation);
          }  
      }
    }

    
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

    @wire(checkCostFieldAccess)
    wiredCheckCostFieldAccess ({error, data}) {
        if (data) {
            let result = data;
            console.log('cost field access: ' + result);
            if (result == 'none') {
                this.columnSettings.showCostColumn = false;
            }
            
        }
    }

    handleGetUserInfo() {
      getUserInfo({ userId: this.user.id })
          .then(result => {
              this.error = undefined;

              if (result) {
                  console.log('calling getUserInfo method ');
                  let userRecord = result;
                  
                  this.user.profileName = userRecord.profileName;
                  this.user.location = userRecord.location;
                  this.user.entityName = userRecord.entityName;
                  
                  this.hideSpinner = true;
              } 
          })
          .catch(TypeError => {
            this.error = this.getErrorMessage(TypeError);
            console.log('type error occurred in getUserInfo: ' + this.error);
            return false;
          })
          .catch(error => {
              this.error = this.getErrorMessage(error);
              console.log('error occurred in getUserInfo: ' + this.error);
              return false;
          });    
  }
    
    handleGetOpportunityInfo() {
        getOpportunityInfo({ oppId: this.localRecordId })
            .then(result => {
                this.error = undefined;

                if (result) {
                    let opportunityRecord = result;
                    if (opportunityRecord.hasOwnProperty('recordTypeName')) {
                      console.log('we have a record type: ' + opportunityRecord.recordTypeName);
                    }
                    if (opportunityRecord.hasOwnProperty('stageName')) {
                      console.log('we have a stage: ' + opportunityRecord.stageName);
                    }
                    this.opportunity.recordTypeName = opportunityRecord.recordTypeName;
                    this.opportunity.stageName = opportunityRecord.stageName;
                    this.opportunity.dealType = opportunityRecord.dealType;
                    this.opportunity.accountType = opportunityRecord.accountType;
                    this.opportunity.accountTier = opportunityRecord.accountTier;
                    this.opportunity.opportunityEntityName = opportunityRecord.opportunityEntityName;
                    console.log('opportunity record type name: ' + this.opportunity.recordTypeName);
                    console.log('opportunity stage name: ' + this.opportunity.stageName);
                    console.log('opportunity deal type: ' + this.opportunity.dealType);
                    console.log('opportunity account type: ' + this.opportunity.accountType);
                    console.log('opportunity account tier: ' + this.opportunity.accountTier);
                    console.log('opportunity entity name: ' + this.opportunity.opportunityEntityName);
                    if (this.opportunity.recordTypeName != 'Purchasing_Opportunity' && this.opportunity.recordTypeName != 'Big_Iron_Purchasing_Opportunity') {
                        this.isSalesOpportunity = true;

                      if (this.opportunity.recordTypeName == 'Material_Transfer') {
                          this.isMaterialTransfer = true;
                      } 
                    }

                    this.hideSpinner = true;
                } 
            })
            .catch(TypeError => {
              this.error = this.getErrorMessage(TypeError);
              console.log('type error occurred in getOpportunityInfo: ' + this.error);
              return false;
            })
            .catch(error => {
                this.error = this.getErrorMessage(error);
                console.log('error occurred in getOpportunityInfo: ' + this.error);
                return false;
            });    
    }

    handleGetWorkOrderInfo() {
      getWorkOrderInfo({ workOrderId: this.localRecordId })
          .then(result => {
              this.error = undefined;

              if (result) {
                  let workOrderRecord = result;
                  console.log('calling getWorkOrderInfo method ' + workOrderRecord);
                  if(workOrderRecord.hasOwnProperty('serviceContractId')){
                      this.serviceContract.id = workOrderRecord.serviceContractId;
                      console.log('service contract Id: ' + this.serviceContract.id);
                  }
                  

                  if (workOrderRecord.hasOwnProperty('oppId')) {
                      this.serviceContract.opportunity = workOrderRecord.oppId;
                      this.opportunity.id = workOrderRecord.oppId;
                      this.opportunity.recordTypeName = workOrderRecord.opportunityRecordTypeName;
                      this.opportunity.stageName = workOrderRecord.opportunityStageName;
                      this.opportunity.dealType = workOrderRecord.opportunityDealType;
                      this.opportunity.accountType = workOrderRecord.opportunityAccountType;
                      this.opportunity.accountTier = workOrderRecord.opportunityAccountTier;
                      this.opportunity.opportunityEntityName = workOrderRecord.opportunityEntityName;
                      
                      console.log('opportunity Id: ' + this.opportunity.id);
                      console.log('opportunity record type name: ' + this.opportunity.recordTypeName);
                      console.log('opportunity stage name: ' + this.opportunity.stageName);
                      console.log('opportunity deal type: ' + this.opportunity.dealType);
                      console.log('opportunity account type: ' + this.opportunity.accountType);
                      console.log('opportunity account tier: ' + this.opportunity.accountTier);
                      console.log('opportunity entity name: ' + this.opportunity.opportunityEntityName);
                      if (this.opportunity.recordTypeName != 'Purchasing_Opportunity' && this.opportunity.recordTypeName != 'Big_Iron_Purchasing_Opportunity') {
                          this.isSalesOpportunity = true;

                        if (this.opportunity.recordTypeName == 'Material_Transfer') {
                            this.isMaterialTransfer = true;
                        } 
                      }
                  } else {
                            this.isSalesOpportunity = true;
                  }   

                  this.hideSpinner = true;
              } 
          })
          .catch(TypeError => {
            this.error = this.getErrorMessage(TypeError);
            console.log('type error occurred in getWorkOrderInfo: ' + this.error);
            return false;
          })
          .catch(error => {
              this.error = this.getErrorMessage(error);
              console.log('error occurred in getWorkOrderInfo: ' + this.error);
              return false;
          });    
    }  
    
    handleGetLoanerInfo() {
      getLoanerInfo({ loanerId: this.localRecordId })
          .then(result => {
              this.error = undefined;

              if (result) {
                  let loanerRecord = result;
                  
                  if (loanerRecord.hasOwnProperty('oppId')) {
                      this.opportunity.id = loanerRecord.oppId;
                      this.opportunity.recordTypeName = loanerRecord.opportunityRecordTypeName;
                      this.opportunity.stageName = loanerRecord.opportunityStageName;
                      this.opportunity.dealType = loanerRecord.opportunityDealType;
                      this.opportunity.accountType = loanerRecord.opportunityAccountType;
                      this.opportunity.accountTier = loanerRecord.opportunityAccountTier;
                      this.opportunity.opportunityEntityName = loanerRecord.opportunityEntityName;
                      console.log('opportunity Id: ' + this.opportunity.id);
                      console.log('opportunity record type name: ' + this.opportunity.recordTypeName);
                      console.log('opportunity stage name: ' + this.opportunity.stageName);
                      console.log('opportunity deal type: ' + this.opportunity.dealType);
                      console.log('opportunity account type: ' + this.opportunity.accountType);
                      console.log('opportunity account tier: ' + this.opportunity.accountTier);
                      console.log('opportunity entity name: ' + this.opportunity.opportunityEntityName);
                      if (this.opportunity.recordTypeName != 'Purchasing_Opportunity' && this.opportunity.recordTypeName != 'Big_Iron_Purchasing_Opportunity') {
                          this.isSalesOpportunity = true;

                        if (this.opportunity.recordTypeName == 'Material_Transfer') {
                            this.isMaterialTransfer = true;
                        } 
                      }
                  } else {
                            this.isSalesOpportunity = true;
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
      console.log('calling getRentalOrderInfo method ');
      getRentalOrderInfo({ rentalOrderId: this.localRecordId })
          .then(result => {
              this.error = undefined;

              if (result) {
                  let rentalOrderRecord = result;

                  if (rentalOrderRecord.hasOwnProperty('oppId')) {
                      this.opportunity.id = rentalOrderRecord.oppId;
                      this.opportunity.recordTypeName = rentalOrderRecord.opportunityRecordTypeName;
                      this.opportunity.stageName = rentalOrderRecord.opportunityStageName;
                      this.opportunity.dealType = rentalOrderRecord.opportunityDealType;
                      this.opportunity.accountType = rentalOrderRecord.opportunityAccountType;
                      this.opportunity.accountTier = rentalOrderRecord.opportunityAccountTier;
                      this.opportunity.opportunityEntityName = rentalOrderRecord.opportunityEntityName;
                      console.log('opportunity Id: ' + this.opportunity.id);
                      console.log('opportunity record type name: ' + this.opportunity.recordTypeName);
                      console.log('opportunity stage name: ' + this.opportunity.stageName);
                      console.log('opportunity deal type: ' + this.opportunity.dealType);
                      console.log('opportunity account type: ' + this.opportunity.accountType);
                      console.log('opportunity account tier: ' + this.opportunity.accountTier);
                      console.log('opportunity entity name: ' + this.opportunity.opportunityEntityName);
                      if (this.opportunity.recordTypeName != 'Purchasing_Opportunity' && this.opportunity.recordTypeName != 'Big_Iron_Purchasing_Opportunity') {
                          this.isSalesOpportunity = true;

                        if (this.opportunity.recordTypeName == 'Material_Transfer') {
                            this.isMaterialTransfer = true;
                        } 
                      }
                  } else {
                            this.isSalesOpportunity = true;
                  }   

                  this.hideSpinner = true;
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
    // this is the section for the service appointment search
    displayInfo = {
      primaryField: 'AppointmentNumber',
      additionalFields: ['Subject'],
     };

    get filter() {
        console.log('Opp/Work Order ID:', this.parentId);
        return {
            criteria: [
                {
                    fieldPath: 'ParentRecordId',
                    operator: 'eq',
                    value: this.parentId
                }
            ]
        };
    }

  // this is for the product search
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
                        console.log('record');
                        console.log(record);
                        console.log('price ' + record.Price__c);
                        console.log('exchange ' + record.Exchange__c);
                        console.log('Id ' + record.Id);
                        console.log('location ' + record.Location__c);
                        console.log('Sub location ' + record.Sub_location__c);
                        console.log('THIS OPPORTUNITY >> ' + this.opportunity.accountType);
                        console.log('This is the OPP RT >>> ' + this.opportunity.recordTypeName);
                        console.log('User Location ' + this.user.location + ' FROM THIS USER ' + this.user.id);
                        console.log('Asset Ownership ' + record.Ownership__c + ' AND IT IS FROM THE UK >> ' + record.Ownership__c.includes('UK'));
                        let recordIdPosition = recordIdsReceived.indexOf(record.Id);
                       
                        if (recordIdPosition == -1) {
                            recordIdsReceived.push(record.Id);

                            if (this.opportunity.recordTypeName == 'Purchasing_Opportunity' || this.opportunity.recordTypeName == 'Big_Iron_Purchasing_Opportunity') {
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
                                    cost: record.Cost__c,
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
                                    this.purchasingProductDataMap.set(record.Id, purchasingRecord);
                                    
                                }
                            } else {
                                if (record.Product_Name__r !== undefined) {
                                    let purchasingApprovedValue;
                                    let exchangeValue;
                                    let partSugPrExValue = 0;
                                    let partSugPrOutValue = 0;
                                    let retailPrOutValue = 0;
                                    let priceValue = 0;
                                    let locationMatchValue;
                                    let hideAddProductValue;
                                    
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
                                    
                                  
                                    console.log('partSugExPrValue >> ' + this.opportunity.accountType + '; ' + this.opportunity.accountTier + '; ' + record.Product_Name__r.REFURB_Exchange_Price__c);
                                    
                                    
                                    if(record.Product_Name__r.Retail_Pr_Out__c != null){
                                      retailPrOutValue = record.Product_Name__r.Retail_Pr_Out__c;
                                    }
                                    
                                    if(this.opportunity.accountTier!= null){
                                      if(this.opportunity.accountTier.includes('Tier 1') && record.Product_Name__r.REFURB_Exchange_Price__c != null){
                                         partSugPrExValue = record.Product_Name__r.Tier_1_REFURB_Ex__c;
                                      }
                                      if(this.opportunity.accountTier.includes('Tier 2') && record.Product_Name__r.REFURB_Exchange_Price__c != null){
                                        partSugPrExValue = record.Product_Name__r.Tier_2_REFURB_Ex__c;
                                     }
                                     if(this.opportunity.accountTier.includes('Tier 3') && record.Product_Name__r.REFURB_Exchange_Price__c != null){
                                        partSugPrExValue = record.Product_Name__r.Tier_3_REFURB_Ex__c;
                                     }
                                      if(this.opportunity.accountTier.includes('Storage - Strategic Partner') && record.Product_Name__r.Strategic_Partner__c != null){
                                        retailPrOutValue = record.Product_Name__r.Strategic_Partner__c;
                                      }
                                      if(this.opportunity.accountTier.includes('Storage - Partner') && record.Product_Name__r.Partner__c != null){
                                        retailPrOutValue = record.Product_Name__r.Partner__c;
                                      }
                                      if(this.opportunity.accountTier.includes('Storage - Individual/VA') && record.Product_Name__r.Individual_VA__c != null){
                                        retailPrOutValue = record.Product_Name__r.Individual_VA__c;
                                      }
                                    }
                                    if(this.opportunity.recordTypeName = 'Equipment_Storage_Rental_Opportunity'){
                                      priceValue = retailPrOutValue;
                                    }
                                    else {
                                      priceValue = record.Price__c;
                                    }
                                    if(partSugPrExValue == 0 && record.Product_Name__r.REFURB_Exchange_Price__c != null){
                                      partSugPrExValue = record.Product_Name__r.REFURB_Exchange_Price__c;
                                    }
                                    partSugPrOutValue = partSugPrExValue * 2;
                                    if(record.Product_Name__r.Outright_Only_Part__c == true){
                                      partSugPrExValue = 0;
                                    }
                                    if(record.Functional_Rating__c == 'Good - New'){
                                      if(record.Product_Name__r.NEW_Exchange_Price__c != null){
                                         partSugPrExValue = record.Product_Name__r.NEW_Exchange_Price__c;
                                         partSugPrOutValue = record.Product_Name__r.NEW_Exchange_Price__c;
                                      }
                                      else{
                                        partSugPrExValue = 0;
                                        partSugPrOutValue = 0;
                                      }
                                    }


                                    console.log('ACTUAL PartSugPrExValue >>> ' + partSugPrExValue);

                                    if(record.Ownership__c != null && this.opportunity.opportunityEntityName != null){
                                      let recordEntityName = this.opportunity.opportunityEntityName;
                                      
                                      
                                      console.log('THIS IS THE ENTITY NAME ON OPP >>> ' + recordEntityName + ' AND IT IS FROM UK >> ' + recordEntityName.includes('UK'));
                                      if(recordEntityName.includes('UK')){
                                          if(record.Ownership__c.includes('UK')){
                                            locationMatchValue = true;
                                          }
                                          else {
                                            locationMatchValue = false; 
                                          }
                                      }
                                      else if(recordEntityName.includes('SAS')){
                                        if(record.Ownership__c.includes('SAS')){
                                          locationMatchValue = true;
                                        }
                                        else {
                                          locationMatchValue = false; 
                                        }
                                      }
                                      else if(recordEntityName.includes('GMBH')){
                                        if(record.Ownership__c.includes('GMBH')){
                                          locationMatchValue = true;
                                        }
                                        else {
                                          locationMatchValue = false; 
                                        }
                                      }
                                      else if(recordEntityName.includes('CAD')){
                                        if(record.Ownership__c.includes('CAD')){
                                          locationMatchValue = true;
                                        }
                                        else {
                                          locationMatchValue = false; 
                                        }
                                      }
                                      else if(recordEntityName.includes('ASG')){
                                        if(record.Ownership__c.includes('ASG')){
                                          locationMatchValue = true;
                                        }
                                        else {
                                          locationMatchValue = false; 
                                        }
                                      }
                                      else if(recordEntityName.includes('US')){
                                        if(record.Ownership__c.includes('US')){
                                          locationMatchValue = true;
                                        }
                                        else {
                                          locationMatchValue = false; 
                                        }
                                      }
                                      else {
                                        locationMatchValue = false;
                                      }
                                      console.log('ACTUAL locationMatchValue >>> ' + locationMatchValue);
      
                                    }
                                    console.log('THIS IS THE CHECK IN TYPE >> ' + record.Check_In_Type__c + ' AND FAMILY >> ' + record.Product_Name__r.Family);
                                    
                                  // gray out checkbox for certain assets
                                    if((record.Reserved__c || !locationMatchValue || (this.opportunity.opportunityEntityName == 'Probo-US' && this.opportunity.recordTypeName == 'Parts_Sales_Opportunity' && this.localObjectName != 'WorkOrder' && record.Product_Name__r.Family.includes('Part') && (record.Review_Status__c != 'Finished Goods' || record.Designated_For__c == 'Service'))) && (record.Check_In_Type__c != 'Generic' || (this.opportunity.recordTypeName != 'Purchasing_Opportunity' && this.opportunity.recordTypeName != 'Big_Iron_Purchasing_Opportunity' && record.Check_In_Type__c == 'Generic' && record.Product_Name__r.RecordType.DeveloperName == 'Non_Inventory_Item'))){
                                        hideAddProductValue = true;
                                    }
                                    else{
                                      hideAddProductValue = false;
                                    }


                                    let salesRecord = {
                                        id: record.Id,
                                        url: '/' + record.Id,
                                        price: priceValue,
                                        cost: record.Cost__c,
                                        selected: false,
                                        saved: false,
                                        exchange: exchangeValue,
                                        partSugPrEx: partSugPrExValue,
                                        partSugPrOut: partSugPrOutValue,
                                        retailPrOut: retailPrOutValue,
                                        purchasingApproved: purchasingApprovedValue,
                                        hideAddProduct: hideAddProductValue,
                                        data: record
                                    };
                                    console.log('sales record ' + salesRecord);
                                    this.salesProductData.push(salesRecord);
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
      } else {
        this.selections.selectedFamilies = removeFromList(this.selections.selectedFamilies, key);
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
        this.selections.selectedFunctionalRating = addToList(this.selections.selectedFunctionalRating, eventValue);
      } else {
          this.selections.selectedFunctionalRating = removeFromList(this.selections.selectedFunctionalRating, eventValue);
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
          this.selections.selectedCosmeticRating = addToList(this.selections.selectedCosmeticRating, eventValue);
      } else {
         this.selections.selectedCosmeticRating = removeFromList(this.selections.selectedCosmeticRating, eventValue);
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
          this.selections.selectedCheckInType = addToList(this.selections.selectedCheckInType, eventValue);
      } else {
          this.selections.selectedCheckInType = removeFromList(this.selections.selectedCheckInType, eventValue);
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
          this.selections.selectedReviewStatus = addToList(this.selections.selectedReviewStatus, eventValue);
      } else {
         this.selections.selectedReviewStatus = removeFromList(this.selections.selectedReviewStatus, eventValue);
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

    handleCompatiblePartsToggleChange(event) {
      let isChecked = event.target.checked;
      //console.log('is checked: ' + isChecked);
      if (isChecked) {
        this.selections.selectedCompatiblePartsOption = true;
      } else {
        this.selections.selectedCompatiblePartsOption = false;
      }
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.triggerNewSearch();
      }, DELAY);
    }

    handleExactSearchToggleChange(event) {
      let isChecked = event.target.checked;
      //console.log('is checked: ' + isChecked);
      if (isChecked) {
        this.selections.selectedExactSearchOption = true;
      } else {
        this.selections.selectedExactSearchOption = false;
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

    // New filter events
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
        
        this.tableWidth = 5000;
      } else if (this.isSystemFamilySelected) {
        permissionSetName = 'Ultrasound_System_Fields_To_Hide';
        this.popOverPermissionSetName = 'Ultrasound System Fields To Show';
        console.log('Ultrasound System family selected');
        this.columnSettings.showNewSugPrOutColumn = false;
        this.columnSettings.showNewSugPrExColumn = false;
        this.columnSettings.showNewStdCostOutColumn = false;
        this.columnSettings.showNewStdCostExColumn = false;
        
        this.tableWidth = 5000;
      } else if (this.isPartsFamilySelected) {
        permissionSetName = 'Ultrasound_Part_Fields_To_Hide';
        this.popOverPermissionSetName = 'Ultrasound_Part_Fields_To_Show';
        
        this.tableWidth = 5000;
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
                      case 'Retail_Pr_Out__c':
                        console.log('found column to hide');
                        this.columnSettings.showRetailPrOutColumn = false;
                        break;
                      case 'Retail_Pr_Ex__c':
                        console.log('found column to hide');
                        this.columnSettings.showRetailPrExColumn = false;
                        break;
                      case 'Dealer_Pr_Out__c':
                          console.log('found column to hide');
                          this.columnSettings.showDealerPrOutColumn = false;
                          break;
                       case 'Dealer_Pr_Ex__c':
                          console.log('found column to hide');
                          this.columnSettings.showDealerPrExColumn = false;
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
        showRetailPrOutColumn: true,
        showRetailPrExColumn:  true,
        showDealerPrOutColumn: true,
        showDealerPrExColumn:  true,
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
      console.log('value of isPartsOnlySearch: ' + this.selections.isPartsOnlySearch)
      if ((this.selections.isPartsOnlySearch == false && this.searchString != null && this.searchString.length > 2) ||
          (this.selections.isPartsOnlySearch == true)) {
          this.productDataAvailable = false;
          
          if (this.salesProductData.length > 0) {
              this.salesProductData.length = 0;
          }
          
          if (this.purchasingProductData.length > 0) {
              this.purchasingProductData.length = 0;
          }

          this.messages.searchResultsMessage = '';
          this.messages.searchResultsMessageAvailable = false;

          console.log('triggering new search....');

          let newRequest;
     
          if (this.selections.isPartsOnlySearch == true) {
              console.log('adding parts only search filters....');
              newRequest = {
                partsOnly: this.selections.isPartsOnlySearch,
                compatibleParts: this.selections.selectedCompatiblePartsOption,
                exactSearch: this.selections.selectedExactSearchOption,
                
                queryString: this.searchString,
                availableOnly: this.selections.selectedAvailableOption,
                family: this.selections.selectedFamilies,
                functionalRating: this.selections.selectedFunctionalRating,
                cosmeticRating: this.selections.selectedCosmeticRating,
                checkInType: this.selections.selectedCheckInType,
                reviewStatus: this.selections.selectedReviewStatus,
                domestic: this.selections.selectedDomesticOption,
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
                compatibleParts: this.selections.selectedCompatiblePartsOption,
                exactSearch: this.selections.selectedExactSearchOption,
                oppRecordType: this.opportunity.recordTypeName,
                queryString: this.searchString,
                availableOnly: this.selections.selectedAvailableOption,
                family: this.selections.selectedFamilies,
                functionalRating: this.selections.selectedFunctionalRating,
                cosmeticRating: this.selections.selectedCosmeticRating,
                checkInType: this.selections.selectedCheckInType,
                reviewStatus: this.selections.selectedReviewStatus,
                domestic: this.selections.selectedDomesticOption
                
                
                
              };
          }


          this.tableRequest = newRequest;
          this.handleSearch();
          console.log('THIS IS THE SELECTED FAMILIES LENGTH >> ' + this.selections.selectedFamilies.length);
          console.log('THIS IS THE SELECTED FAMILIES >> ' + this.selections.selectedFamilies);
          if (this.selections.selectedFamilies.length == 1) {
            this.handleColumnsToHide();
          } else if (this.tableWidth !== 5000) {
            if ((this.opportunity.recordTypeName == 'Purchasing_Opportunity' || this.opportunity.recordTypeName == 'Big_Iron_Purchasing_Opportunity') && this.tableWidth !== 5800) {
              this.tableWidth = 5800;
            } else {
              this.tableWidth = 5000;
            }
            this.resetColumnSettings();
          }
          
      }
    }

    // Existing OLI selection methods (swap) 
    handleOLISelection(selectedRows) {
        console.log('handle OLI selection in product search lwc component');
        
        this.selectedOLIData.length = 0;
        
        if (selectedRows.length > 0) {
            console.log('selected OLI data available');
            for (let i = 0; i < selectedRows.length; i++){
                this.selectedOLIData.push(selectedRows[i]);
                let row = selectedRows[i];
                console.log('row in process: ' + JSON.stringify(row));
                if (row.hasOwnProperty('Product2_Name__c')) {
                  console.log('we have asset swap data');
                  console.log('asset product name: ' + selectedRows[i].Product2_Name__c);
                  this.hasAssetSwapData = true;
                  
                } else {
                  this.hasAssetSwapData = false;
                  console.log('we have OLI swap data');
                  console.log('OLI product name: ' + selectedRows[i].Product_Name__c);
                }
                
            }
            this.selectedOLIDataAvailable = null;
            this.selectedOLIDataAvailable = true;
            this.currentOLIRecord = this.selectedOLIData[0];
            if (this.hasAssetSwapData) {
              this.searchTerm = this.currentOLIRecord.Product2_Name__c;
            } else {
              this.searchTerm = this.currentOLIRecord.Product_Name__c;
            }
            
            console.log('searchTerm: ' + this.searchTerm + ' and exchange value: ' + this.currentOLIRecord.Exchange__c);
            let searchEvent = new CustomEvent('searchLoad', {detail: this.searchTerm});
            this.handleSearchLoad(searchEvent);
        }
    
    }

    /*handleOLISelectionComplete(event) {
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
    }*/ 

    
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
        if (this.hasAssetSwapData) {
          this.searchTerm = this.currentOLIRecord.Product2_Name__c;
        } else {
          this.searchTerm = this.currentOLIRecord.Product_Name__c;
        }
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
        if (this.hasAssetSwapData) {
          this.searchTerm = this.currentOLIRecord.Product2_Name__c;
        } else {
          this.searchTerm = this.currentOLIRecord.Product_Name__c;
        }
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
        console.log('this is the record type in the new OLI >>> ' + this.opportunity.recordTypeName);
        if (this.opportunity.recordTypeName == 'Purchasing_Opportunity' || this.opportunity.recordTypeName == 'Big_Iron_Purchasing_Opportunity'){
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
        console.log('handle new OLI deselection event in search component');
        
        let eventValue = event.detail.key;
        console.log('event value: ' + eventValue);
        let deSelectedRecord;
            
        if (this.opportunity.recordTypeName == 'Purchasing_Opportunity' || this.opportunity.recordTypeName == 'Big_Iron_Purchasing_Opportunity'){
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
            opportunityId: this.localRecordId
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
// capture service appointment selection
/*
    handleAppointmentSelection(event) {
      console.log('handleAppointmentSelection in search component');
      let selectedAppointment = event.detail.recordId;
      console.log('selected appointment: ' + selectedAppointment);
      this.appointmentId = selectedAppointment;
      
      
    }
*/
    handlePriceChange(event) {
        console.log('handlePriceChange in search component');
        let eventId = event.detail.key;
        console.log('id: ' + eventId);
        let updatedPrice = event.detail.price;
        console.log('updated price: ' + updatedPrice);
        let obj;
        if (this.opportunity.recordTypeName == 'Purchasing_Opportunity' || this.opportunity.recordTypeName == 'Big_Iron_Purchasing_Opportunity'){
          obj = this.purchasingProductDataMap.get(eventId);
        } else {
          obj = this.salesProductDataMap.get(eventId);
        }
        console.log('selected oli record:' + obj);
        console.log('current price: ' + obj.price);
        
        obj.price = updatedPrice;
        console.log('updated price: ' + obj.price);
        
    }

    handleCostChange(event) {
        console.log('handleCostChange in search component');
        let eventId = event.detail.key;
        console.log('id: ' + eventId);
        let updatedCost = event.detail.cost;
        console.log('updated cost: ' + updatedCost);
        let obj;
        if (this.opportunity.recordTypeName == 'Purchasing_Opportunity' || this.opportunity.recordTypeName == 'Big_Iron_Purchasing_Opportunity'){
          obj = this.purchasingProductDataMap.get(eventId);
        } else {
          obj = this.salesProductDataMap.get(eventId);
        }
        console.log('selected oli record:' + obj);
        console.log('current cost: ' + obj.cost);
        
        obj.cost = updatedCost;
        console.log('updated cost: ' + obj.cost);
    }

    handleExchangeChange(event) {
        console.log('handleExchangeChange in search component');
        let eventId = event.detail.key;
        console.log('id: ' + eventId);
        let isChecked = event.detail.checked;
        console.log('is checked: ' + isChecked);
        let obj;
        let obj2;
  
        if (this.opportunity.recordTypeName == 'Purchasing_Opportunity' || this.opportunity.recordTypeName == 'Big_Iron_Purchasing_Opportunity'){
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


    // main methods  
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
        console.log('swap value: ' + swapValue + ' and swap origin data : ' + this.currentOLIRecord + ' and swap new data : ' + this.currentNewOLIRecord);
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
    var url = '/' + this.localRecordId;
    console.log('handle save event');
    this.selections.saveInProgress = true;
    this.messages.saveOLIErrorMessage = '';
    this.messages.saveOLIErrorMessageAvailable = false;
    
    if (this.newOLIData.length > 0 || this.swapOLIData.size > 0) {
        let swapItems = [];
        let purchasingItems = [];
        let salesItems = [];
        console.log('THIS IS IN THE SAVE OLI >>> ' + this.opportunity.recordTypeName);
        if (this.opportunity.recordTypeName == 'Purchasing_Opportunity' || this.opportunity.recordTypeName == 'Big_Iron_Purchasing_Opportunity'){
            console.log('processing Purchasing_Opportunity');
            for (let key of this.newOLIDataMap.keys()) { 
            let record = this.newOLIDataMap.get(key);
            if (record.selected && !record.saved) {
                console.log('found selected item to save for Purchasing_Opportunity');
                let purchasingRecord = {
                    id: key,
                    price: parseFloat(record.price),
                    cost: parseFloat(record.cost),
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
                let salesRecord = {
                    id: key,
                    price: parseFloat(record.price),
                    cost: parseFloat(record.cost),
                    exchange: record.exchange,
                    appointment: this.appointmentId
                };
                salesItems.push(salesRecord);
            }
            }  
        }

        for (let record of this.swapOLIRecords) {
          if (!record.saved) {
              let swapValue = record.originData.Id + '-' + record.swapData.Id;
              console.log('swap value origin exchange: ' + record.originData.Exchange__c + ' and swap value swap exchange: ' + record.swapData.Exchange__c);
              this.currentExchangeValue = record.originData.Exchange__c;
              console.log('swap value to save: ' + swapValue);
              swapItems.push(swapValue);
          }
        }
        
        if (salesItems.length > 0 || purchasingItems.length > 0 || swapItems.length > 0) {

            if (saveAndClose){ 
                this.hideSpinner = false;
            }
            
             // Create line items as needed
             if (this.localObjectName == 'Opportunity') {
                console.log('creating opportunity line items');
                let saveResult = this.handleCreateOpportunityLineItems(salesItems, purchasingItems,swapItems, saveAndClose);
             } else if (this.localObjectName == 'WorkOrder') {
                console.log('creating work order line items');
                let saveResult = this.handleCreateWorkOrderLineItems(salesItems, purchasingItems, saveAndClose);
             } else if (this.localObjectName == 'Loaner__c') {
                console.log('creating loaner line items');
                let saveResult = this.handleCreateLoanerLineItems(salesItems, purchasingItems,swapItems, saveAndClose);
             }  else if (this.localObjectName == 'Rental_Order__c') {
                console.log('creating rental order line items');
                let saveResult =  this.handleCreateRentalOrderLineItems(salesItems, purchasingItems,swapItems, saveAndClose);
             } 

             if (saveAndClose) {
                  this.dispatchEvent(new CustomEvent('swapdone'));
                  window.location.href = url;
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

    // Clears the in-memory selection after a successful Add (non-close) save so that
    // a subsequent Add cannot re-send the same rows. This is a companion to the Apex
    // dedupe guard; the Apex guard is what actually prevents duplicate line items.
    resetSelectionAfterAdd() {
        console.log('resetting selection state after successful add');

        // Uncheck any rows still flagged selected in the displayed grids.
        // Reassign the arrays so the grid re-renders with cleared checkboxes.
        if (this.salesProductData && this.salesProductData.length > 0) {
            this.salesProductData = this.salesProductData.map((record) => {
                record.selected = false;
                return record;
            });
        }
        if (this.purchasingProductData && this.purchasingProductData.length > 0) {
            this.purchasingProductData = this.purchasingProductData.map((record) => {
                record.selected = false;
                return record;
            });
        }

        // Clear the "new line item" selection collections.
        this.newOLIData = [];
        this.newOLIEditedData = [];
        this.newOLIDataMap = new Map();
        this.newOLIDataAvailable = false;
        this.selectedOLICount = 0;
        this.currentNewOLIRecord = null;

        // Clear any pending swap selections that have now been saved.
        this.swapOLIData = [];
        this.swapOLIRecords = [];
        this.swapOLICount = 0;
        this.swapOLIDataAvailable = false;
    }

    handleCreateOpportunityLineItems(salesItems, purchasingItems,swapItems, saveAndClose) {
      console.log('handle create exchange value ' + this.currentExchangeValue);
      let result = createOpportunityLineItems({
        selectedItems: salesItems,
        selectedPurchasingItems: purchasingItems,
        swapItems: swapItems,
        opportunityId: this.localRecordId,
        exchangeValue: this.currentExchangeValue

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
            
            if (saveAndClose) {
                console.log('ready to redirect');
                let url = '/' + this.localRecordId;
                window.location.href = url;
                //this.delayTimeout = setTimeout(() => {
                //  window.location.href = url;
               //}, 300);
            } else {
                // Plain Add (stay on page): clear selection so it can't be re-sent on the next Add.
                this.resetSelectionAfterAdd();
            }

            return result;
        } else {
            this.selections.saveInProgress = false;
            console.log('error occurred during save');
            if (result){
            this.messages.saveOLIErrorMessage = 'Error occurred during Save: ' + result;
            this.messages.saveOLIErrorMessageAvailable = true;
            }
            return null;
        }

        })
        .catch((error) => {
            this.message = 'Error received: code' + error.errorCode + ', ' +
                'message ' + error.message;
        }); 


    }

    handleCreateLoanerLineItems(salesItems, purchasingItems,swapItems, saveAndClose) {
      let result = createLoanerLineItems({
        selectedItems: salesItems,
        selectedPurchasingItems: purchasingItems,
        swapItems: swapItems,
        opportunityId: this.opportunity.id,
        loanerId: this.localRecordId
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
            this.messages.saveOLIErrorMessage = 'Error occurred during Save: ' + result;
            this.messages.saveOLIErrorMessageAvailable = true;
            }
            return null;
        }

        })
        .catch((error) => {
            this.message = 'Error received: code' + error.errorCode + ', ' +
                'message ' + error.message;
        }); 


    }

    handleCreateWorkOrderLineItems(salesItems, purchasingItems, saveAndClose) {
      let result = createWorkOrderLineItems({
        selectedItems: salesItems,
        selectedPurchasingItems: purchasingItems,
        opportunityId: this.opportunity.id,
        workOrderId: this.localRecordId
        })
        .then((result) => {
        console.log('result: ' + result);
        this.hideSpinner = true;

        if (result == 'success') {
            console.log('save complete');
            
            this.messages.saveOLISuccessMessage = 'Line items added successfully';
            this.messages.saveOLISuccessMessageAvailable = true;

            if (this.newOLIDataMap.size > 0) {
              for (let key of this.newOLIDataMap.keys()) {
                  let record = this.newOLIDataMap.get(key);
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
            this.messages.saveOLIErrorMessage = 'Error occurred during Save: ' + result;
            this.messages.saveOLIErrorMessageAvailable = true;
            }
            return null;
        }

        })
        .catch((error) => {
            this.message = 'Error received: code' + error.errorCode + ', ' +
                'message ' + error.message;
        }); 



      
    }

    handleCreateRentalOrderLineItems(salesItems, purchasingItems,swapItems, saveAndClose) {
      let result = createRentalOrderLineItems({
        selectedItems: salesItems,
        selectedPurchasingItems: purchasingItems,
        swapItems: swapItems,
        opportunityId: this.opportunity.id,
        rentalOrderId: this.localRecordId
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
            this.messages.saveOLIErrorMessage = 'Error occurred during Save: ' + result;
            this.messages.saveOLIErrorMessageAvailable = true;
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

    get partsOnlySearch() {
        if (this.selections.selectedFamilies.length == 1 && this.selections.selectedFamilies[0] =='Part') {
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