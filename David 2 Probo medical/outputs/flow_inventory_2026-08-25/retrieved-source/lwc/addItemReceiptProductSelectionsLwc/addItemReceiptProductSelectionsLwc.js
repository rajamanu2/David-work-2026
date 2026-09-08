import { LightningElement, api, wire, track } from 'lwc';



export default class AddItemReceiptProductSelections extends LightningElement {
    @api 
    get prliDataEdited() {
      return this.newPRLIEditedData;
    }
    set prliDataEdited(value) {
        this.newPRLIEditedData = value;
    }
        
    
    @api 
    get itemCount() {
      return this.prliCount;
    }
    set itemCount(value) {
        this.prliCount = value;
        console.log('prli count passed in lwc component: ' + value);
        if(this.prliCount !== null && Number(this.prliCount) > 0) {
            this.newPRLIDataAvailable = true;
            console.log('display new prli data selections in lwc component');
        } else {
            this.newPRLIDataAvailable = false;
            console.log('hide new prli data selections in lwc component');
        }
    }
    @track selections = {
        showModal: false,
        selectedItemToRemove: null,
    } 
    @track newPRLIData = [];
    @track newPRLIEditedData = [];
    @track newPRLIDataMap = new Map();
    @track newPRLIDataAvailable = false;
    @track prliCount = 0;


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
    handleNewPRLIDeselection(event) {
        console.log('handle new PRLI deselection event');
       
        let eventObject = { key: this.selections.selectedItemToRemove};
        this.selections.showModal = false;
        
        this.dispatchEvent(
            new CustomEvent('deselect', {  
                detail: eventObject   
            })
        );

       

    }   


}