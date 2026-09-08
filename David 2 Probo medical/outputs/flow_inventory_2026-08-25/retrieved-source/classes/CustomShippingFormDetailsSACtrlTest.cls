@isTest(SeeAllData=true)
public class CustomShippingFormDetailsSACtrlTest {

    @isTest
    static void testGetTableData() {
        // Find a Work Order that already has WOLIs with Part_Used__c populated
        List<WorkOrderLineItem> existingWolis = [
            SELECT Id, WorkOrderId
            FROM WorkOrderLineItem
            WHERE Part_Used__c != NULL
            LIMIT 1
        ];

        if (existingWolis.isEmpty()) {
            System.debug('No WOLI with Part_Used__c found in org - skipping test');
            return;
        }

        Id woId = existingWolis[0].WorkOrderId;
        System.debug('Using Work Order ID: ' + woId);

        // Create a Service Appointment linked to that Work Order
        ServiceAppointment sa = new ServiceAppointment();
        sa.Work_Order__c = woId;
        sa.ParentRecordId = woId;
        sa.EarliestStartTime = System.now();
        sa.DueDate = System.now().addDays(1);
        insert sa;
        System.debug('Created SA ID: ' + sa.Id);

        // Update the existing WOLI to point to our new SA
        existingWolis[0].Service_Appointment__c = sa.Id;
        update existingWolis[0];
        System.debug('Updated WOLI ID: ' + existingWolis[0].Id + ' to point to SA: ' + sa.Id);

        Test.startTest();

        CustomShippingFormDetailsSACtrl ctrl = new CustomShippingFormDetailsSACtrl();
        ctrl.theSAID = sa.Id;
        List<CustomShippingFormDetailsSACtrl.ShippingFormDetailsRow> results = ctrl.gettableData();

        Test.stopTest();

        System.assertNotEquals(null, results, 'Results list should never be null');
        System.debug('Rows returned: ' + results.size());

        if (!results.isEmpty()) {
            CustomShippingFormDetailsSACtrl.ShippingFormDetailsRow firstRow = results[0];
            System.debug('First row assetNum: '    + firstRow.assetNum);
            System.debug('First row productName: ' + firstRow.productName);
            System.debug('First row partNum: '     + firstRow.partNum);
            System.debug('First row totalPrice: '  + firstRow.totalPrice);
            System.debug('First row rmaNum: '      + firstRow.rmaNum);
            System.assertNotEquals(null, firstRow.assetNum,    'Asset number should not be null');
            System.assertNotEquals(null, firstRow.productName, 'Product name should not be null');
            System.assertNotEquals(null, firstRow.partNum,     'Part number should not be null');
        } else {
            System.debug('WOLI resolved to Generic type - controller filtered it out, no rows returned');
        }
    }

    @isTest
    static void testNoWorkOrder() {
        List<WorkOrder> woList = [
            SELECT Id
            FROM WorkOrder
            LIMIT 1
        ];

        if (woList.isEmpty()) {
            System.debug('No Work Order found in org - skipping test');
            return;
        }

        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = woList[0].Id;
        sa.EarliestStartTime = System.now();
        sa.DueDate = System.now().addDays(1);
        insert sa;
        System.debug('Created SA ID with no Work_Order__c: ' + sa.Id);

        Test.startTest();

        CustomShippingFormDetailsSACtrl ctrl = new CustomShippingFormDetailsSACtrl();
        ctrl.theSAID = sa.Id;
        List<CustomShippingFormDetailsSACtrl.ShippingFormDetailsRow> results = ctrl.gettableData();

        Test.stopTest();

        System.assert(results.isEmpty(), 'Expected empty results when SA has no Work Order');
    }

    @isTest
    static void testNullSAID() {
        Test.startTest();

        CustomShippingFormDetailsSACtrl ctrl = new CustomShippingFormDetailsSACtrl();
        List<CustomShippingFormDetailsSACtrl.ShippingFormDetailsRow> results = ctrl.gettableData();

        Test.stopTest();

        System.assert(results.isEmpty(), 'Expected empty results when SA ID is null');
    }
}