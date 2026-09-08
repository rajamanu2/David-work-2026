import { LightningElement,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";

export default class NavigateToNewOpportunity extends NavigationMixin(LightningElement) {
    @api defaultAccountId;

    connectedCallback() {

        const defaultValues = encodeDefaultFieldValues({
            AccountId: this.defaultAccountId,
            });
            
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues,
                useRecordTypeCheck: 'true'
            },
        });
    }

}