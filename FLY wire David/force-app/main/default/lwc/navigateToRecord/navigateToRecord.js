import { LightningElement ,api} from 'lwc';
import { NavigationMixin } from 'lightning/navigation'; 

export default class NavigateToRecord extends NavigationMixin(LightningElement) {
    @api recordId;

    connectedCallback() {
        console.log('recordId: ', this.recordId);
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId:  this.recordId,
                actionName: 'view'
            }
        });
    }
}