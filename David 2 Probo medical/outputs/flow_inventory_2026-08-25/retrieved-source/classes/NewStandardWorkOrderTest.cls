@isTest
public class NewStandardWorkOrderTest {

    @testSetup
    static void setup() {
        Account acc = TestDataFactory.createAccount(false);
        acc.Field_Service_Engineer__c = 'Hobie Sears';
        acc.Standard_Warranty_Length__c = '6 Months';
        acc.Lead_Source__c = 'Referral';
        acc.Name = 'Probo Medical';
        insert acc;
        Contact con = new Contact(LastName='Doe', FirstName='John', AccountId=acc.Id);
        insert con;
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acc.Id, false);
        opp.StageName = 'Verbal Acceptance';
        opp.Attention__c = 'TEST';
        opp.Ship_To_Account__c = 'TEST';
        insert opp;
        ServiceContract SC = new ServiceContract(Name = 'Test', Opportunity__c = opp.id);
        insert SC;
        WorkOrder WO = new WorkOrder(Opportunity__c = opp.id, ServiceContractId = SC.id);
        insert WO;
        RMA__c RMARecord = new RMA__c(Opportunity__c = opp.id);
        insert RMARecord;
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Functionally_Good_Probes__c = 190;
        insert pro;
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, true);
    }
    
    static testmethod void TestWOFromOpportunity() {
        Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
		
        ApexPages.StandardController sc = new ApexPages.StandardController(o);
        ApexPages.currentPage().getParameters().put('id', o.id);
        NewStandardWorkOrder tester = new NewStandardWorkOrder(sc);
        tester.newStdWorkOrder();
       
         
        Test.stopTest();
        
    }
    
    static testmethod void TestWOFromServiceContract() {
        ServiceContract SCRecord = [SELECT Id FROM ServiceContract LIMIT 1];

        Test.startTest();
		
        ApexPages.StandardController sc = new ApexPages.StandardController(SCRecord);
        ApexPages.currentPage().getParameters().put('id', SCRecord.id);
        NewStandardWorkOrder tester = new NewStandardWorkOrder(sc);
        tester.newStdWorkOrder();
       
         
        Test.stopTest();
        
    }
    
    static testmethod void TestWOFromRMA() {
        RMA__c RMARecord = [SELECT Id FROM RMA__c LIMIT 1];

        Test.startTest();
		
        ApexPages.StandardController sc = new ApexPages.StandardController(RMARecord);
        ApexPages.currentPage().getParameters().put('id', RMARecord.id);
        NewStandardWorkOrder tester = new NewStandardWorkOrder(sc);
        tester.newStdWorkOrder();
       
         
        Test.stopTest();
        
    }
    
    static testmethod void TestWOFromWO() {
        WorkOrder WORecord = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
		
        ApexPages.StandardController sc = new ApexPages.StandardController(WORecord);
        ApexPages.currentPage().getParameters().put('id', WORecord.id);
        NewStandardWorkOrder tester = new NewStandardWorkOrder(sc);
        tester.newStdWorkOrder();
       
         
        Test.stopTest();
        
    }
}