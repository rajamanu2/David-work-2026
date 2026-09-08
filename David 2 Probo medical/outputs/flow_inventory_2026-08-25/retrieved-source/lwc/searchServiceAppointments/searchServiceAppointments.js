import { LightningElement, api} from 'lwc';



export default class SearchServiceAppointments extends LightningElement {

    @api workOrderId;

    

    displayInfo = {
        primaryField: 'AppointmentNumber',
        additionalFields: ['Subject'],
    };

    get filter() {

        console.log('Work Order ID:', this.workOrderId);

        return {

            criteria: [

                {
                    fieldPath: 'ParentRecordId',
                    operator: 'eq',
                    value: this.workOrderId,

                }

            ]

        };

    }
   /* filter = {
    criteria: [
           {
        fieldPath: 'ParentRecordId',
        operator: 'eq',
        value: this.workOrderId,
            },
            {
            fieldPath: 'ParentRecordId',
            operator: 'ne',
            value: null,
            },
        ],
        
    };*/
}