@isTest
public class WorkOrderShippingCheckListTest {
    static testmethod void TestOpportunityShippingCheckListTest() {
        Account acc = TestDataFactory.createAccount(true);
        
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acc.Id, false);
        opp.Estimated_Ready_Date__c = Date.today();
        opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        opp.Ship_Date__c = Date.today();
        opp.PO__c = 'Test PO';
        insert opp;
        
        WorkOrder WO = new WorkOrder(RecordTypeId='0124O000000tDuBQAU',AccountId =acc.Id,Opportunity__c=opp.id,Pricebook2Id='01sU00000001dZOIAY');
        insert WO;
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(null, true);
        WorkOrderLineItem WOLine = new WorkOrderLineItem(WorkOrderId = WO.id,PricebookEntryId=pbe.id);
        insert WOLine;
        
        ProductItem__c ProdItem = TestDataFactory.createProductItem('01tU00000038YuhIAE', true);
        

        Test.startTest();

        apexPages.currentPage().getParameters().put('Id',WO.Id);
        ApexPAges.StandardController sc = new ApexPages.StandardController(WO);
        WorkOrderShippingCheckList cl = new WorkOrderShippingCheckList(sc);

        Test.stopTest();
    }

}