@isTest
public class P_ServiceContractTriggerHandlerTest {
    
    static testmethod void CaseCreationTest() {
            Account acct = TestDataFactory.createAccount(true); 
        
        	Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
       
        	Test.startTest();
        
            ServiceContract sc = new ServiceContract(Name = 'Test', AccountId = acct.id, Opportunity__c = opp.id, Field_Service_Engineers__c = 'Hobie Sears', StartDate = date.today(), EndDate = date.Today() + 365);
           
            insert sc;
    
            Test.stopTest();
            
    }

}