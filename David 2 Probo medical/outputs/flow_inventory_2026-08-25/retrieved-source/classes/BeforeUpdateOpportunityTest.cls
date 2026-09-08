@isTest
private class BeforeUpdateOpportunityTest {

    // Add a "Sales Opportunity" opportunity, a product, an Asset (ProductItem__c), a pbe, and an OLI
    // Test the Validator_Class.resetAlreadyDone1 function, the UpdateOpportunity trigger, and related classes
    // Use assertions to verify related business rules
    static testmethod void TestBeforeUpdateTest1() {

        ProboCommonUtils.getStdPricebookId();

        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity('Sales Opportunity', acc.Id, false);
        opp.Repair_Evaluation_Serial_Number__c = '1234';
        opp.StageName = 'Repair Evaluation';
        insert opp;
        Validator_Class.resetAlreadyDone1();

        Opportunity opp2 = TestDataFactory.createOpportunity('Sales Opportunity', acc.Id, false);
        opp2.Loaner_Turned_to_Sale__c = false;
        opp2.StageName = 'Proposal/Price Quote';
        insert opp2;
        Validator_Class.resetAlreadyDone1();

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);

        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp2.Id, pbe.Id, pi.Id, true);
        Validator_Class.resetAlreadyDone1();

        OpportunityLineItem oli2 = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, true);
        Validator_Class.resetAlreadyDone1();

        Test.startTest();

        opp2.StageName = 'Probe Loan';
        update opp2;

        // check that the opportunity was updated as expected
        List<Opportunity> ots = [SELECT Id, StageName FROM Opportunity WHERE Id = :opp2.Id];
        System.Assert(ots.size() == 1, 'Assertion Failed - Did not find updated opportunity as expected.');
        System.Assert(ots[0].StageName == 'Probe Loan', 'Assertion Failed - Did not find updated opportunity as expected.');

        Test.stopTest();
    }

}