@IsTest
private class CustomShippingFormDetCmpCtrlTest {
    @IsTest
    static void simpletestOpp() {

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', null, false);
        opp.StageName = 'Prospecting';
        opp.Shipping_FROM_Location__c = 'Fishers, IN';
        insert opp;

        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Other_Notes__c='Cable needs cleaned';
        pi.Check_In_Type__c = 'Purchase';
        pi.PO_Number__c = '1234';
        pi.Purchasing_Opportunity__c = opp.Id;
        pi.Other_Notes__c = 'Cable needs cleaned';
        pi.Repair_Due_Date__c = system.today();
        pi.Asset_Model_No__c = '49dj3l';
        insert pi;

        RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', false);
        rma.ProductItem__c = pi.Id;
        insert rma;

        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);

        System.assertNotEquals(null, pbe, 'PriceBookEntry was not created');

        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opp.Id;
        oli.ProductItem__c = pi.Id;
        oli.PricebookEntryId = pbe.Id;
        oli.Quantity = 1;
        oli.UnitPrice = 5;
        insert oli;

        Test.startTest();
        System.debug('TEST: start of the test');
        CustomShippingFormDetCmpCtrl r = new CustomShippingFormDetCmpCtrl();
        r.theOppID = opp.Id;
        List<CustomShippingFormDetCmpCtrl.ShippingFormDetailsRow> res = r.gettableData();
        Test.stopTest();
        System.debug('TEST: end of the test');
        System.assertNotEquals(null, res, 'gettableData() did not return anything');

    }
    @isTest
    static void simpletestWO() {

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', null, false);
        opp.StageName = 'Prospecting';
        opp.Shipping_FROM_Location__c = 'Fishers, IN';
        insert opp;

        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Other_Notes__c='Cable needs cleaned';
        pi.Check_In_Type__c = 'Purchase';
        pi.PO_Number__c = '1234';
        pi.Purchasing_Opportunity__c = opp.Id;
        pi.Other_Notes__c = 'Cable needs cleaned';
        pi.Repair_Due_Date__c = system.today();
        insert pi;

        RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', false);
        rma.ProductItem__c = pi.Id;
        insert rma;

        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);

        System.assertNotEquals(null, pbe, 'PriceBookEntry was not created');

        Schema.WorkOrder WO = new Schema.WorkOrder(Opportunity__c = opp.id, Billable_Work_Order__c = 1000);
        insert WO;
        
        Schema.WorkOrderLineItem WOLineItem = new Schema.WorkOrderLineItem(WorkOrderID = WO.id, Status = 'NEW', Part_Used__c = pi.id);
        insert WOLineItem;
        

        Test.startTest();
        System.debug('TEST: start of the test');
        CustomShippingFormDetailsWOCtrl r = new CustomShippingFormDetailsWOCtrl();
        r.theWOID = WO.Id;
        List<CustomShippingFormDetailsWOCtrl.ShippingFormDetailsRow> res = r.gettableData();
        Test.stopTest();
        System.debug('TEST: end of the test');
        System.assertNotEquals(null, res, 'gettableData() did not return anything');

    }
}