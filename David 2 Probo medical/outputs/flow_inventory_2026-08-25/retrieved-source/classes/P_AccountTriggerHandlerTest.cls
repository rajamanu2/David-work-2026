@isTest
public class P_AccountTriggerHandlerTest {
    @testSetup static void setup() {
        Account acc = TestDataFactory.createAccount(false); 
        acc.Intacct_Customer_Sync_Status__c = 'Synced';
        acc.Intacct_Vendor_Sync_Status__c = 'Synced';
        insert acc;
        
        String userId = UserInfo.getUserId();
        
        // PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Intacct_Synced_Records' LIMIT 1];
        
        // AssignPermissionSet.remove(userId, ps.Id);
    }
    
    /*
    @isTest static void updateAcc() {     
        Account acc = [SELECT Id FROM Account LIMIT 1];
        acc.Intacct_Customer_Sync_Status__c = '';
        
        Boolean exceptionThrown = false;
        
        test.StartTest();
        try{
            update acc;
        } catch(Exception e) {
            exceptionThrown = true;
            Boolean expectedExceptionThrown =  (e.getMessage().contains('You can not change the status of an Account that has been synced with Intacct')) ? true : false; 
            System.AssertEquals(true, expectedExceptionThrown, e.getMessage()); 
        }
        System.assertEquals(true, exceptionThrown, 'No exception was thrown');
        
        
        acc.Intacct_Vendor_Sync_Status__c = '';
        
        try{
            update acc;
        } catch(Exception e) {
            exceptionThrown = true;
            Boolean expectedExceptionThrown =  (e.getMessage().contains('You can not change the status of an Account that has been synced with Intacct')) ? true : false; 
            System.AssertEquals(true, expectedExceptionThrown, e.getMessage()); 
        }
        System.assertEquals(true, exceptionThrown, 'No exception was thrown');
        Test.StopTest();
    }
	*/
    
    @isTest static void deleteAccException() {
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Boolean exceptionThrown = false;
        
        try{
            delete acc;
        } catch(Exception e) {
            exceptionThrown = true;
            Boolean expectedExceptionThrown =  (e.getMessage().contains('You can not delete an Account that has been synced with Intacct')) ? true : false; 
            System.AssertEquals(true, expectedExceptionThrown, e.getMessage()); 
        }
        
        System.assertEquals(true, exceptionThrown, 'No exception was thrown');
    }
    
    @isTest static void deleteAcc() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        acc.Allow_Delete__c = true;
        update acc;
        
        Boolean exceptionThrown = false;
        
        test.StartTest();
        try{
            delete acc;
        } catch(Exception e) {
            exceptionThrown = true;
            Boolean expectedExceptionThrown =  (e.getMessage().contains('You can not delete an Account that has been synced with Intacct')) ? true : false; 
        }
        System.assertEquals(false, exceptionThrown, 'No exception was thrown');
        Test.StopTest();
    }
    
}