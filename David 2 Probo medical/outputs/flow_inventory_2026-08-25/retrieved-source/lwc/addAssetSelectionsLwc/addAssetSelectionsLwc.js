import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import PRODUCTITEM_OBJECT from '@salesforce/schema/ProductItem__c';
//import LOCATION_FIELD from '@salesforce/schema/ProductItem__c.Location__c';
import SUBLOCATION_FIELD from '@salesforce/schema/ProductItem__c.Sub_Location__c';

export default class AddAssetSelectionsLwc extends LightningElement {
    @api 
    get assetDataEdited() {
      return this.newAssetEditedData;
    }
    set assetDataEdited(value) {
        this.newAssetEditedData = value;
    }
    /*@api 
    get subLocations() {
      return this.subLocationOptions;
    }
    set subLocations(value) {
        this.subLocationOptions = value;
        //console.log('sub location count: ' + this.subLocationOptions.length);
    }*/

    @api 
    get itemCount() {
      return this.partCount;
    }
    set itemCount(value) {
        this.partCount = value;
        console.log('part count passed in lwc component: ' + value);
        if(this.partCount !== null && Number(this.partCount) > 0) {
            this.newAssetDataAvailable = null;
            this.newAssetDataAvailable = true;
        } else {
            this.newAssetDataAvailable = null;
            this.newAssetDataAvailable = false;
        }
    }

    @api 
    get invalidItemCount() {
      return this.invalidPartCount;
    }
    set invalidItemCount(value) {
        this.invalidPartCount = value;
        console.log('invalid part count passed in lwc component: ' + value);
        if(this.invalidPartCount !== null && Number(this.invalidPartCount) > 0) {
            console.log('initiating field validation');
            this.validateRequiredFields();
            
        } else {
            console.log('no field validation required');
        }
    }

    @track selections = {
        showModal: false,
        selectedItemToRemove: null,
    } 
    @track newAssetData = [];
    @track newAssetEditedData = [];
    @track newAssetDataMap = new Map();
    @track newAssetDataAvailable = null;
    @track subLocationOptions = null;
    @track cosmeticRatingOptions = [{value: 'Good', label: 'Good'}, {value: 'Needs Testing', label: 'Needs Testing'}];
    @track invalidPartCount = 0;
    @track partCount = 0;
    @track error;

    @wire(getObjectInfo, { objectApiName: PRODUCTITEM_OBJECT })
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
    }


    handleModalOpen(event) {
        let eventValue = event.target.value;
        this.selections.selectedItemToRemove = eventValue;
        console.log('record Id of item to remove: ' + eventValue);
        this.selections.showModal = true;
    } 
      
    handleModalClose(event) {
        this.selections.selectedItemToRemove = null;
        this.selections.showModal = false;
    }  

    handleQuantityChange(event) {
        console.log('quantity change event');
        let eventId = event.currentTarget.getAttribute("data-key");
        console.log('id: ' + eventId);
        let updatedQuantity = event.target.value;
        console.log('updated quantity: ' + updatedQuantity);

        let eventObject = { key: eventId, 
                            quantity: updatedQuantity};

        this.dispatchEvent(
            new CustomEvent('quantitychange', {  
                detail: eventObject   
            })
        );

    } 


    handleSubLocationChange(event) {
        console.log('sub location event ');
        let eventId = event.currentTarget.getAttribute("data-key");
        console.log('id: ' + eventId);
        let updatedSubLocation = event.target.value;
        console.log('updated sub location: ' + updatedSubLocation);

        if (this.invalidPartCount !== null && Number(this.invalidPartCount) > 0) {
            this.resetValidation("lightning-combobox", eventId);
        }

        let eventObject = { key: eventId, 
                            sublocation: updatedSubLocation};

        this.dispatchEvent(
            new CustomEvent('sublocationchange', {  
                detail: eventObject   
            })
        );

    } 

    handleSerialNumberChange(event) {
        console.log('serial number change event');
        let eventId = event.currentTarget.getAttribute("data-key");
        console.log('id: ' + eventId);
        let updatedSerialNumber = event.target.value;
        console.log('updated serial number: ' + updatedSerialNumber);

        let eventObject = { key: eventId, 
                            serialnumber: updatedSerialNumber};

        this.dispatchEvent(
            new CustomEvent('serialnumberchange', {  
                detail: eventObject   
            })
        );

    } 

    handleCosmeticRatingChange(event) {
        console.log('cosmetic rating change event');
        let eventId = event.currentTarget.getAttribute("data-key");
        console.log('id: ' + eventId);
        let updatedCosmeticRating = event.target.value;
        console.log('updated cosmetic Rating: ' + updatedCosmeticRating);

        let eventObject = { key: eventId, 
                            cosmeticRating: updatedCosmeticRating};

        this.dispatchEvent(
            new CustomEvent('cosmeticratingchange', {  
                detail: eventObject   
            })
        );

    } 

    handleDateOfManufactureChange(event) {
        console.log('DOM change event');
        let eventId = event.currentTarget.getAttribute("data-key");
        console.log('id: ' + eventId);
        let updatedDateOfManufacture = event.target.value;
        console.log('updated DOM: ' + updatedDateOfManufacture);

        let eventObject = { key: eventId, 
                            dateOfManufacture: updatedDateOfManufacture};

        this.dispatchEvent(
            new CustomEvent('dateofmanufacturechange', {  
                detail: eventObject   
            })
        );

    } 

    handleTubeCountChange(event) {
        console.log('tube count change event');
        let eventId = event.currentTarget.getAttribute("data-key");
        console.log('id: ' + eventId);
        let updatedTubeCount = event.target.value;
        console.log('updated tube count: ' + updatedTubeCount);

        let eventObject = { key: eventId, 
                            tubeCount: updatedTubeCount};

        this.dispatchEvent(
            new CustomEvent('tubecountchange', {  
                detail: eventObject   
            })
        );

    } 

    handleTubeCountDateChange(event) {
        console.log('tube count date change event');
        let eventId = event.currentTarget.getAttribute("data-key");
        console.log('id: ' + eventId);
        let updatedTubeCountDate = event.target.value;
        console.log('updated tube count date: ' + updatedTubeCountDate);

        let eventObject = { key: eventId, 
                            tubeCountDate: updatedTubeCountDate};

        this.dispatchEvent(
            new CustomEvent('tubecountdatechange', {  
                detail: eventObject   
            })
        );

    } 
        
    getsubLocationOptions(event) {
        return this.subLocationOptions;
    }

    getcosmeticRatingOptions(event) {
        return this.cosmeticRatingOptions;
    }

    
    handleNewAssetDeselection(event) {
        console.log('handle new OLI deselection event');
       
        let eventObject = { key: this.selections.selectedItemToRemove};
        this.selections.showModal = false;
        
        this.dispatchEvent(
            new CustomEvent('deselect', {  
                detail: eventObject   
            })
        );

       

    }  

    validateRequiredFields() {
        console.log('calling validateRequiredFields ');

        let comboBoxComponents = this.template.querySelectorAll("lightning-combobox");

        console.log('validating required location field');

        comboBoxComponents.forEach(function(element){
            if(!element.value) {
                element.setCustomValidity("Sub Location is required.");
                element.reportValidity();
            } 
            
        },this);

        
        /*if (this.messages.validationPassed === false) {
            this.messages.validationErrorMessage = 'Please enter all the required fields.'
            this.dispatchEvent(
                new ShowToastEvent({
                message: this.messages.validationErrorMessage,
                variant: "warning",
                })
            );
        }*/
    }

    resetValidation(fieldType, fieldName) {
        let inputComponents = this.template.querySelectorAll(fieldType);
        
        inputComponents.forEach(function(element){
            if(element.name == fieldName) {
                element.setCustomValidity("");
                element.reportValidity();
            }
            
        },this);
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