import { LightningElement, api, wire, track } from 'lwc';



export default class AddProductSelections extends LightningElement {
    @api 
    get oliDataEdited() {
      return this.newOLIEditedData;
    }
    set oliDataEdited(value) {
        this.newOLIEditedData = value;
    }
        
    @api 
    get showPrice() {
      return this.showPriceColumn;
    }
    set showPrice(value) {
        this.showPriceColumn = value;
        console.log('show price flag passed in to selections lwc component: ' + value);
    }
    @api 
    get showCost() {
      return this.showCostColumn;
    }
    set showCost(value) {
        this.showCostColumn = value;
    }
    @api 
    get itemCount() {
      return this.oliCount;
    }
    set itemCount(value) {
        this.oliCount = value;
        console.log('oli count passed in lwc component: ' + value);
        if(this.oliCount !== null && Number(this.oliCount) > 0) {
            this.newOLIDataAvailable = true;
            console.log('display new oli data selections in lwc component');
        } else {
            this.newOLIDataAvailable = false;
            console.log('hide new oli data selections in lwc component');
        }
    }
    @track selections = {
        showModal: false,
        selectedItemToRemove: null,
    } 
    @track newOLIData = [];
    @track newOLIEditedData = [];
    @track newOLIDataMap = new Map();
    @track newOLIDataAvailable = false;
    @track showPriceColumn = false;
    @track showCostColumn = false;
    @track oliCount = 0;


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

    handlePriceChange(event) {
        console.log('price change event');
        let eventId = event.currentTarget.getAttribute("data-key");
        console.log('id: ' + eventId);
        let updatedPrice = event.target.value;
        console.log('updated price: ' + updatedPrice);

        let eventObject = { key: eventId, 
                            price: updatedPrice};

        this.dispatchEvent(
            new CustomEvent('pricechange', {  
                detail: eventObject   
            })
        );

    } 
    
    handleCostChange(event) {
        console.log('cost change event');
        let eventId = event.currentTarget.getAttribute("data-key");
        console.log('id: ' + eventId);
        let updatedCost = event.target.value;
        console.log('updated cost: ' + updatedCost);

        let eventObject = { key: eventId, 
                            cost: updatedCost};

        this.dispatchEvent(
            new CustomEvent('costchange', {  
                detail: eventObject   
            })
        );

    }  
    
    handleExchangeChange(event) {
        console.log('exchange change event');
        let eventId = event.currentTarget.getAttribute("data-key");
        console.log('id: ' + eventId);
        let isChecked = event.target.checked;
        console.log('is checked: ' + isChecked);
        
        let eventObject = { key: eventId, 
            checked: isChecked};

        this.dispatchEvent(
            new CustomEvent('exchangechange', {  
                detail: eventObject   
            })
        );

    }    

    handleNewOLIDeselection(event) {
        console.log('handle new OLI deselection event');
       
        let eventObject = { key: this.selections.selectedItemToRemove};
        this.selections.showModal = false;
        
        this.dispatchEvent(
            new CustomEvent('deselect', {  
                detail: eventObject   
            })
        );

       

    }   


}