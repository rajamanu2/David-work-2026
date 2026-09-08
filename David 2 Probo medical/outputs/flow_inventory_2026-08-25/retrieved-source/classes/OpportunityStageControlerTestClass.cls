@isTest
private class OpportunityStageControlerTestClass{

    static testMethod void TestOpportunityStageControlerTest() {
        Account acc = TestDataFactory.createAccount(true);

        Opportunity opp1 = TestDataFactory.createOpportunity('Sales Opportunity', acc.Id, false);
        opp1.Name = 'oppname1';
        opp1.StageName = 'Closed Lost';
        opp1.Shipping_FROM_Location__c = 'Fishers, IN';
        opp1.CloseDate = system.today() - 500;
        opp1.Reason_Lost__c = 'Price too high';
        insert opp1;

        Opportunity opp2 = TestDataFactory.createOpportunity('Sales Opportunity', acc.Id, false);
        opp2.Name = 'oppname2';
        opp2.Amount = null;
        opp2.StageName = 'Closed Won';
        opp2.Shipping_FROM_Location__c = 'Fishers, IN';
        opp2.CloseDate = system.today() - 500;
        opp2.Confirmation_number__c = '12345';
        insert opp2;

        Opportunity opp3 = TestDataFactory.createOpportunity('Sales Opportunity', acc.Id, false);
        opp3.Name = 'oppname3';
        opp3.StageName = 'Closed Lost';
        opp3.Shipping_FROM_Location__c = 'Fishers, IN';
        opp3.CloseDate = system.today() - 500;
        opp3.Reason_Lost__c = 'Price too high';
        insert opp3;

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp1.Id, pbe.Id, pi.Id, true);

        Test.startTest();

        OpportunityStageControler OSC = new OpportunityStageControler();
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        system.assert(opps.size() == 3, 'Assertion Failed - Not enough opps created.');

        Test.stopTest();
    }
}