/**
 * Created by jeff on 8/15/18.
 */

@IsTest
private class OpportunityShippingCheckListTest {

    static testmethod void TestOpportunityShippingCheckListTest() {
        Account acc = TestDataFactory.createAccount(true);
        
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acc.Id, false);
        opp.Estimated_Ready_Date__c = Date.today();
        opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        opp.Ship_Date__c = Date.today();
        insert opp;
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(null, true);
        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id , null, true);

        Test.startTest();

        apexPages.currentPage().getParameters().put('Id',opp.Id);
        ApexPAges.StandardController sc = new ApexPages.StandardController(opp);
        OpportunityShippingCheckList cl = new OpportunityShippingCheckList(sc);

        Test.stopTest();
    }
}