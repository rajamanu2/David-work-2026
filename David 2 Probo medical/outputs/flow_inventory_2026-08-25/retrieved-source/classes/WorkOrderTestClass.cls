@isTest
private class WorkOrderTestClass {

    static testmethod void TestWorkOrderTest1() {

        Opportunity opp = TestDataFactory.createOpportunity('Sales Opportunity', null, true);
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Functionally_Good_Probes__c = 190;
        insert pro;
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Added_to_Work_Order__c = false;
        pi.Other_Notes__c = 'Cable needs cleaned';
        insert pi;
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, true);

        Test.startTest();

        User u = TestDataFactory.createUser('Casey', 'Trogden', true);
        system.runas(u) {
            ApexPages.StandardController sc = new ApexPages.StandardController(opp);
            ApexPages.currentPage().getParameters().put('id', opp.id);
            WorkOrderHelper wo = new WorkOrderHelper(sc);
            wo.newAllWorkOrders();
        }
        Test.stopTest();
    }
}