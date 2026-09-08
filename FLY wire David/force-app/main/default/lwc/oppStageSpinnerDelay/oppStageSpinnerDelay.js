import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USERPROFILE_NAME from '@salesforce/schema/User.Profile.Name';

const FIELDS = ['Opportunity.Probability', 'Opportunity.RecordTypeId'];

export default class SpinnerLoadDelay extends LightningElement {
    @api delayTime;
    @api probabilityParam;
    @track isLoading = false;
    @api recordId;
    recordTypes = ['Agents'];

    currentUserProfileName;
    opportunity;

    @wire(getRecord, { recordId: USER_ID, fields: [USERPROFILE_NAME]}) 
    userDetails({error, data}) {
        if (error) {
            console.log(error);
        } else if (data) {
            this.currentUserProfileName = data.fields.Profile.value.fields.Name.value;
            this.setSpinner();
        }
    }    

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data}) {
        if (error) {
            console.log(error);
        } else if (data) {
            this.opportunity = data;
            this.setSpinner()
        }
    }

    setSpinner() {
        if (this.opportunity && this.currentUserProfileName !== 'System Administrator') {
            this.setDelay();
        }
    }

    setDelay() {
        if (!isNaN(this.delayTime) && this.shouldCheckOpp()) {
            this.isLoading = true;
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                this.isLoading = false;
            }, this.delayTime);
        }
    }

    shouldCheckOpp() {
        return this.recordTypes.includes(this.recordTypeName) && this.probability >= this.probabilityParam;
    }

    get recordTypeName() {
        return this.opportunity.recordTypeInfo.name;
    }

    get probability() {
        return this.opportunity.fields.Probability.value;
    }
}