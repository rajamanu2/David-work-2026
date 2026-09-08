import { LightningElement , wire, api} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getActivitiesFromApex from '@salesforce/apex/ActivityComponentController.getActivities';
import getOpenNonMarketoActivities from '@salesforce/apex/ActivityComponentController.getOpenNonMarketoActivities';

export default class ActivityComponentv2 extends NavigationMixin(LightningElement) {
    @api recordId;
    activity =[];
    openActivity =[];
    totalActivities = 0;
    activeSections = ['A', 'B'];

    get cardLabel() {
        this.totalActivities =  this.activity.length + this.openActivity.length ;
        return 'Activities (' + this.totalActivities + ')';
        //return 'Activies (' + this.activity.length + ')';
    }

    @wire(getActivitiesFromApex, { recordId: '$recordId' })
     wiredActivity({ error, data }) {
        if (data) {
            this.activity = data;
            this.dispatchEvent(new CustomEvent('activitycount', { detail: this.activity.length}));
        } else if (error) {
            this.error = error;
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
            console.error('Error getting activity from apex message:', error.body.message);
        }
    }

    @wire(getOpenNonMarketoActivities, { recordId: '$recordId' })
     wiredOpenActivity({ error, data }) {
        if (data) {
            this.openActivity = data;
            // Add IsOverdue field to each activity
            this.openActivity = data.map(activity => {
                let today = new Date();
                today.setHours(0, 0, 0, 0); // Reset time to start of the day
                // Convert ActivityDate to Date object and compare
                let activityDate = new Date(activity.ActivityDate);
                let isOverdue = activityDate < today;
                // Spread operator to clone the activity and add IsOverdue property
                return { ...activity, IsOverdue: isOverdue };
            });
            //this.dispatchEvent(new CustomEvent('activitycount', { detail: this.openActivity.length}));
        } else if (error) {
            this.error = error;
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
            console.error('Error getting open non marketo activity from apex message:', error.body.message);
        }
    }


    handleNavigateActivity(event) {
        //event.preventDefault();
        //event.stopPropagation();
        //alert(JSON.stringify(event));
        //console.error('handleNavigateActivity event.target.dataset-targetId:',event.target.dataset.targetId);
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.dataset.targetId,
                actionName: 'view',
            }
        })
    }

}