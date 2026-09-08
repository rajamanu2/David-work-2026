import { LightningElement , wire, api, track} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getActivitiesFromApex from '@salesforce/apex/ActivityComponentController.getKeyObjectiveActivities';
import getOpenActivitiesFromApex from '@salesforce/apex/ActivityComponentController.getOpenKeyObjectiveActivities';

const columns = [
    { label: 'Subject', fieldName: 'Link', type: 'url', 
        typeAttributes: { target: '_self', label: { fieldName: 'Subject' }}, 
        cellAttributes: { class: 'slds-text-link' }
    },
    { label: 'Assigned To', fieldName: 'Owner_Link', type: 'url', 
        typeAttributes: { target: '_self', label: { fieldName: 'Owner_Name' }}, 
        cellAttributes: { class: 'slds-text-link' }
    },
    { label: 'Progress', fieldName: 'Progress__c', cellAttributes: { alignment: 'center' }},
    { label: 'Due Date', fieldName: 'ActivityDate', type: 'date', fixedWidth: 100 },
    { label: 'Status', fieldName: 'Status', fixedWidth: 90 }
];

export default class ActivityKeyObjective extends NavigationMixin(LightningElement) {
    @api recordId;
    pageSize = 10;
    pastActivitiesLimit = this.pageSize;
    pastActivitiesRowCount = 0;
    @track pastActivities = [];
    showPastActivities = false;
    openActivitiesLimit = this.pageSize;
    openActivitiesRowCount = 0;
    @track openActivities = [];
    showOpenActivities = false;
    openActivitiesCount = 0;
    pastActivitiesCount = 0;
    activeSections = ['A', 'B'];
    columns = columns;
    loadMoreStatus;
    @api totalNumberOfRows;
    isFetchingPastActivities = false;
    isFetchingOpenActivities = false;


    get cardLabel() {
        return `Activities (${this.openActivitiesCount + this.pastActivitiesCount})`;
    }

    @wire(getOpenActivitiesFromApex, { recordId: '$recordId', numberOfRecords: '$openActivitiesLimit' })
     wiredOpenActivity({ error, data }) {
        this.tableIsLoading('openActivities', true);
        if (data) {
            const result = [];
            for (const record of data.activities) {
                result.push(Object.assign({}, record));
            }
            this.openActivities = result;
            this.openActivitiesCount = data.count;
            this.openActivitiesRowCount = this.openActivities.length;
            this.showOpenActivities = this.openActivities.length > 0;
            this.generateLinks(this.openActivities);
        } else if (error) {
            this.error = error;
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
            console.error('Error getting open key objective activity from apex message:', error.body.message);
        }
        this.isFetchingOpenActivities = false;
        this.tableIsLoading('openActivities', false);
    }

    @wire(getActivitiesFromApex, { recordId: '$recordId',  numberOfRecords: '$pastActivitiesLimit' })
    wiredActivity({ error, data }) {
       this.tableIsLoading('pastActivities', true);
       if (data) {
           const result = [];
           for (const record of data.activities) {
               result.push(Object.assign({}, record));
           }
           this.pastActivities = result;
           this.pastActivitiesCount = data.count;
           this.pastActivitiesRowCount = this.pastActivities.length;
           this.showPastActivities = this.pastActivities.length > 0;
           this.generateLinks(this.pastActivities);
       } else if (error) {
           this.error = error;
           if (Array.isArray(error.body)) {
               this.error = error.body.map(e => e.message).join(', ');
           } else if (typeof error.body.message === 'string') {
               this.error = error.body.message;
           }
           console.error('Error getting key objective activity from apex message:', error.body.message);
       }
       this.isFetchingPastActivities = false;
       this.tableIsLoading('pastActivities', false);
    }

    generateLinks(records) {
        records.forEach(record => {
            record.Link = `/${record.Id}`;

            for (const [key, value] of Object.entries(record)) {
                if (typeof value === 'object') {
                    const newValue = value.Id !== null ? `/${value.Id}` : null;
                    
                    if (newValue !== null ) {
                        record[`${key}_Link`] = newValue;
                    }

                    this.flattenStructure(record, `${key}_`, value);
                }
            }

        });
    }

    flattenStructure(topObj, prefix, toBeFlattened) {
        for (const [key, value] of Object.entries(toBeFlattened)) {
            if (typeof value === 'object') {
                this.flattenStructure(topObj, `${prefix}${key}_`, value);
            } else {
                topObj[`${prefix}${key}`] = value;
            }
        }
    }
    
    loadMorePastActivities(event) {
        if (!this.isFetchingPastActivities) {
            if (this.pastActivitiesRowCount === this.pastActivitiesLimit) {
                this.isFetchingPastActivities = true;
                this.pastActivitiesLimit += this.pageSize;
            } else if (this.pastActivitiesRowCount + this.pageSize === this.pastActivitiesLimit) {
                this.pastActivitiesLimit += this.pageSize;
            } else if (this.pastActivitiesRowCount < this.pageSize || this.pastActivitiesLimit > this.pastActivitiesRowCount) {
                event.target.enableInfiniteLoading = false;
            }
        }
    }

    loadMoreOpenActivities(event) {
        if (!this.isFetchingOpenActivities) {
            if (this.openActivitiesRowCount === this.openActivitiesLimit) {
                this.isFetchingOpenActivities = true;
                this.openActivitiesLimit += this.pageSize;
            } else if (this.openActivitiesRowCount + this.pageSize === this.openActivitiesLimit) {
                this.openActivitiesLimit += this.pageSize;
            } else if (this.openActivitiesRowCount < this.pageSize || this.openActivitiesLimit > this.openActivitiesRowCount) {
                event.target.enableInfiniteLoading = false;
            }
        }
    }

    tableIsLoading(elementId, isLoading) {
        const dataTable = this.template.querySelector(`[data-id="${elementId}"]`);
        if (dataTable) dataTable.isLoading = isLoading
    }

    // handleNavigateActivity(event) {
    //     //event.preventDefault();
    //     //event.stopPropagation();
    //     //alert(JSON.stringify(event));
    //     //console.error('handleNavigateActivity event.target.dataset-targetId:',event.target.dataset.targetId);
        
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__recordPage',
    //         attributes: {
    //             recordId: event.target.dataset.targetId,
    //             actionName: 'view',
    //         }
    //     })
    // }

    /*handleNewTask() {
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__StandardTask'
            }
        });
    }*/

}