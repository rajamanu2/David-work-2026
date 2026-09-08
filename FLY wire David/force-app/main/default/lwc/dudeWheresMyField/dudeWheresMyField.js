import { LightningElement,api,wire,track} from 'lwc';
import getPriceActions from '@salesforce/apex/dudeWheresMyField_Helper.getPriceActions';
import getPriceConditions from '@salesforce/apex/dudeWheresMyField_Helper.getPriceConditions';
import getLookupQueries from '@salesforce/apex/dudeWheresMyField_Helper.getLookupQueries';

export default class DatatableEx12 extends LightningElement {
    @track columns = [
        {
            label: 'Record URL',
            fieldName: 'nameURL',
            type: 'url',
            typeAttributes: {label: {fieldName: 'recordName'}, target: '_blank'},
            sortable: true
        },
        {
            label: 'Rule Name',
            fieldName: 'ruleURL',
            type: 'url',
            typeAttributes: {label: {fieldName: 'ruleName'}, target: '_blank'},
            sortable: true
        },
        {
            label: 'Rule ID',
            fieldName: 'ruleID',
            type: 'text',
            sortable: true
        },
        {
            label: 'Is Active?',
            fieldName: 'isActive',
            type: 'boolean',
            sortable: true
        },
        {
            label: 'Firing Order',
            fieldName: 'sortOrder',
            type: 'text',
            sortable: true
        }

    ];
    @track error;
    @track actions;
    @track conditions;
    @track queries;
    @track searchAPI;
    searchAPI = 'NULL';

    handleChange(event){
            this.searchAPI = event.target.value;
    }
    
    @wire(getPriceActions, {searchAPI: '$searchAPI'})

    getRecords(){
        getPriceConditions({searchAPI: this.searchAPI})
        .then(result => {
            this.conditions = result;
            console.log('conditions: '+ this.conditions);
            this.error = undefined;
        })
        .catch(error => {
            this.error = error;
            console.log('Error: '+ this.error.message);
            this.actions = undefined;
        });

        getLookupQueries({searchAPI: this.searchAPI})
        .then(result => {
            this.queries = result;
            console.log('queries: '+ this.conditions);
            this.error = undefined;
        })
        .catch(error => {
            this.error = error;
            console.log('Error: '+ this.error.message);
            this.actions = undefined;
        });

        getPriceActions({searchAPI: this.searchAPI})
        .then(result => {
            this.actions = result;
            console.log('actions: '+ this.actions);
            this.error = undefined;
        })
        .catch(error => {
            this.error = error;
            console.log('Error: '+ this.error.message);
            this.actions = undefined;
        });
    }
}