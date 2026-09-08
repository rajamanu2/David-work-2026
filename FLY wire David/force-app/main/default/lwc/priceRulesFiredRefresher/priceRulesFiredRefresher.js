import { LightningElement,wire,track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRefresher from '@salesforce/apex/PriceRulesFiredHandler.refresher';
import getOriginalLastRunDate from '@salesforce/apex/PriceRulesFiredHandler.getLastRefreshRun';

export default class RefreshPriceRulesFired extends LightningElement {

    @track getOriginalLastRunDate;

    connectedCallback() {
        getOriginalLastRunDate() 
        .then(result => {
            this.getOriginalLastRunDate = result;
            this.error = undefined;
        })
        .catch(error => {
            this.error = error;
            console.log('Error: '+ this.error.message);
            this.data = undefined;
        });
    }

    @track lastRefreshRun;
    @track data;
    @track error;

    _title = 'Price Rules Refreshed!';
    message = 'Price Rules Refresher has run, please refresh any data tables to see results.';
    variant = 'success';

    //fetching data from server
    refreshPriceRulesFired() {
        getRefresher()
        .then(result => {
            console.log('getOriginalLastRunDate BEFORE: ',result);
            this.getOriginalLastRunDate = result;
            console.log('getOriginalLastRunDate: ',result);
            this.error = undefined;
        })
        .catch(error => {
            this.error = error;
            console.log('Error: '+ this.error.message);
            this.data = undefined;
        });

        const evt = new ShowToastEvent({
            title: this._title,
            message: this.message,
            variant: this.variant,
        });
        this.dispatchEvent(evt);
    }
}