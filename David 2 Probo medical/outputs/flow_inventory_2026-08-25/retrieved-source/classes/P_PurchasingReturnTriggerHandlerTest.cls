@isTest
public class P_PurchasingReturnTriggerHandlerTest {
    @testSetup static void setup() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Purchasing_Return__c' AND Name = 'Return to Vendor' LIMIT 1];
        
        Account acc = TestDataFactory.createAccount(false); 
        acc.Accounting_Contact_E_mail__c = 'Test@Test.com';
        insert acc;
        
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acc.Id, false);
        insert opp;
        
        Purchasing_Return__c pr = new Purchasing_Return__c (RecordTypeId = rt.Id, Opportunity__c = opp.Id, Account__c = acc.Id, Purchasing_Return_Amount__c = 100, Ship_to__c = 'Probo Medical Test Run', Shipping_Street__c = '123 Test Vendor Street', Shipping_City__c = 'Tamarac', Shipping_State_Province__c = 'Florida', Shipping_Zip_Postal_Code__c = '11111', Shipping_Country__c = 'United States', Ship_From__c = 'Tamarac, FL', Submit_to_Shipping__c = true, Intacct_PO_Return_Sync_Status__c = 'Synced');
        insert pr;
        
        String userId = UserInfo.getUserId();
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Intacct_Synced_Records' LIMIT 1];
        
        List<PermissionSetAssignment> psaList = [SELECT AssigneeId FROM PermissionSetAssignment WHERE AssigneeId =: userId AND PermissionSetId =: ps.Id LIMIT 1];
        
        if (!psaList.isEmpty()) {
            AssignPermissionSet.remove(userId, ps.Id);
        }
    }
    @isTest static void updatePr() {
        Purchasing_Return__c pr = [SELECT Id FROM Purchasing_Return__c LIMIT 1];
        pr.Intacct_PO_Return_Sync_Status__c = '';
        
        Boolean exceptionThrown = false;
        
        try{
            update pr;
        } catch(Exception e) {
            exceptionThrown = true;
            Boolean expectedExceptionThrown =  (e.getMessage().contains('You can not change the status of a Purchasing Return that has been synced with Intacct')) ? true : false; 
            System.AssertEquals(true, expectedExceptionThrown, e.getMessage()); 
        }
        System.assertEquals(true, exceptionThrown, 'No exception was thrown');
        
    }
    
    @isTest static void deletePrException() {
        Purchasing_Return__c pr = [SELECT Id FROM Purchasing_Return__c LIMIT 1];
        Boolean exceptionThrown = false;
        
        test.StartTest();
        try{
            delete pr;
        } catch(Exception e) {
            exceptionThrown = true;
            Boolean expectedExceptionThrown =  (e.getMessage().contains('You can not delete a Purchasing Return that has been synced with Intacct')) ? true : false; 
            System.AssertEquals(true, expectedExceptionThrown, e.getMessage()); 
        }
        
        System.assertEquals(true, exceptionThrown, 'No exception was thrown');
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Intacct_Synced_Records']; 
        
        AssignPermissionSet.assign(UserInfo.getUserId(), ps.Id);
        
        Test.StopTest();
    }
    
    @isTest static void deletePr() {
        Purchasing_Return__c pr = [SELECT Id FROM Purchasing_Return__c LIMIT 1];
        pr.Allow_Delete__c = true;
        update pr;
        
        Boolean exceptionThrown = false;
        
        test.StartTest();
        try{
            delete pr;
        } catch(Exception e) {
            exceptionThrown = true;
            Boolean expectedExceptionThrown =  (e.getMessage().contains('You can not delete a Purchasing Return that has been synced with Intacct')) ? true : false; 
        }
        System.assertEquals(false, exceptionThrown, 'No exception was thrown');
        Test.StopTest();
    }
}