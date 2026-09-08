@IsTest
private class SourcingRequestTest {

    @IsTest
    static void testBehavior() {

        ProboCommonUtils.getStdPricebookId();

        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity('Sales Opportunity', acc.Id, false);
        opp.Repair_Evaluation_Serial_Number__c = '1234';
        opp.StageName = 'Proposal/Price Quote';
        insert opp;

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, true);

        Test.startTest();

        PageReference pageRef = Page.Producttest;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id',oli.id);
        ApexPages.StandardController ctrlr = new ApexPages.StandardController(oli);
        SourcingRequest sr = new SourcingRequest(ctrlr);
        sr.NewRequest();

        Test.stopTest();
    }
}