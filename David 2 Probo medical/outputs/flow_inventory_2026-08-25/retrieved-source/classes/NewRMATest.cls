@isTest
public class NewRMATest {

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
        insert opp;
        ServiceContract SC = new ServiceContract(Name = 'Test', Opportunity__c = opp.id);
        insert SC;
        WorkOrder WORecord = new WorkOrder(Opportunity__c = opp.id, ServiceContractId = SC.id);
        insert WORecord;
        
    }
    
    static testmethod void TestRMAFromOpportunity() {
        Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
		
        ApexPages.StandardController sc = new ApexPages.StandardController(o);
        ApexPages.currentPage().getParameters().put('id', o.id);
        NewRMA tester = new NewRMA(sc);
        tester.newStdRMA();
       
         
        Test.stopTest();
        
    }
    
    static testmethod void TestRMAFromServiceContract() {
        ServiceContract SCRecord = [SELECT Id FROM ServiceContract LIMIT 1];

        Test.startTest();
		
        ApexPages.StandardController sc = new ApexPages.StandardController(SCRecord);
        ApexPages.currentPage().getParameters().put('id', SCRecord.id);
        NewRMA tester = new NewRMA(sc);
        tester.newStdRMA();
       
         
        Test.stopTest();
        
    }
    
    static testmethod void TestRMAFromWO() {
        WorkOrder WORecord = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
		
        ApexPages.StandardController sc = new ApexPages.StandardController(WORecord);
        ApexPages.currentPage().getParameters().put('id', WORecord.id);
        NewRMA tester = new NewRMA(sc);
        tester.newStdRMA();
       
         
        Test.stopTest();
        
    }
}