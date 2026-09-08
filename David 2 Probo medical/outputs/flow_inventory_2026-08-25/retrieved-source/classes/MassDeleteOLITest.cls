@isTest
private class MassDeleteOLITest {
    static testmethod void TestMassDeleteOLI() {
		system.debug('TEST: start TestAddProductTest1');
        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity('Purchasing Opportunity', acc.Id, true);
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Generic_Product__c = true;
        pi.sold__c = false;
        insert pi;
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, true);
		system.debug('TEST: pi: '+ pi);
        system.debug('TEST: oli: '+ oli);
        Test.startTest();

        ApexPages.StandardController sc = new ApexPages.standardController(opp);
        System.currentPageReference().getParameters().put('id', opp.id);
        OLIController OLItest = new OLIController(sc);
        OLITest.MassDelete();
        
        opp = [SELECT Id, (SELECT Id FROM OpportunityLineItems) FROM Opportunity LIMIT 1];

        Test.stopTest();
    }
}