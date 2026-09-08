@IsTest
public class P_InvoiceTriggerHandlerTest {
    @testSetup static void setup() {
        String userId = UserInfo.getUserId();
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Intacct_Synced_Records' LIMIT 1];
        
        List<PermissionSetAssignment> psaList = [SELECT AssigneeId FROM PermissionSetAssignment WHERE AssigneeId =: userId AND PermissionSetId =: ps.Id LIMIT 1];
        
        if (!psaList.isEmpty()) {
            AssignPermissionSet.remove(userId, ps.Id);
        }
    }
    
    @IsTest
    static void addPortalContacttoInvoice() {
        
        Account acc = TestDataFactory.createAccount(false);
        acc.Name = 'Probo Medical - Portal';
        acc.Accounting_Contact_E_mail__c = 'Test@Test.com';
        acc.Shipping_Acct__c = 'test';
        insert acc;
        Contact con = new Contact(AccountId = acc.id, FirstName = 'Hobie', LastName = 'Sears');
        insert con;
        Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', acc.id, true);
        o.Field_Service_Engineer__c = 'Hobie Sears';
        update o;
        system.debug('THIS IS THE OPP FOR TEST >>> ' + o);
        Invoice__c inv = new Invoice__c(Account__c = acc.id, Opportunity__c = o.id);
       
		insert inv;
        
        inv.Down_Payment__c = 1000;
        update inv;
    }
    
    @isTest static void updateInvoice() {
        Account acc = TestDataFactory.createAccount(false);
        insert acc;
        
        Contact con = new Contact(AccountId = acc.id, FirstName = 'Hobie', LastName = 'Sears');
        insert con;
        
        Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', acc.id, true);
        
        Invoice__c inv = new Invoice__c(Account__c = acc.id, Opportunity__c = o.id, Intacct_Invoice_Sync_Status__c = 'Synced');
        
        insert inv;
        
        Boolean exceptionThrown = false;
        inv.Intacct_Invoice_Sync_Status__c = '';
        
        try{
            update inv;
        } catch(Exception e) {
            exceptionThrown = true;
            Boolean expectedExceptionThrown =  (e.getMessage().contains('You can not change the status of an Invoice that has been synced with Intacct')) ? true : false; 
            System.AssertEquals(true, expectedExceptionThrown, e.getMessage()); 
        }
        
        System.assertEquals(true, exceptionThrown, 'No exception was thrown');

    }
    
    @isTest static void deleteInvException() {
        Account acc = TestDataFactory.createAccount(false);
        insert acc;
        
        Contact con = new Contact(AccountId = acc.id, FirstName = 'Hobie', LastName = 'Sears');
        insert con;
        
        Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', acc.id, true);
        
        Invoice__c inv = new Invoice__c(Account__c = acc.id, Opportunity__c = o.id, Intacct_Invoice_Sync_Status__c = 'Synced');
        
        insert inv;
        Boolean exceptionThrown = false;
        
        test.StartTest();
        try{
            delete inv;
        } catch(Exception e) {
            exceptionThrown = true;
            Boolean expectedExceptionThrown =  (e.getMessage().contains('You can not delete an Invoice that has been synced with Intacct')) ? true : false; 
            System.AssertEquals(true, expectedExceptionThrown, e.getMessage()); 
        }
        
        System.assertEquals(true, exceptionThrown, 'No exception was thrown');
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Intacct_Synced_Records']; 
        
        AssignPermissionSet.assign(UserInfo.getUserId(), ps.Id);
        
        Test.StopTest();
    }
    
        @isTest static void deleteInv() {
        Account acc = TestDataFactory.createAccount(false);
        insert acc;
        
        Contact con = new Contact(AccountId = acc.id, FirstName = 'Hobie', LastName = 'Sears');
        insert con;
        
        Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', acc.id, true);
        
        Invoice__c inv = new Invoice__c(Account__c = acc.id, Opportunity__c = o.id, Intacct_Invoice_Sync_Status__c = 'Synced');
        
        insert inv;
        
        inv.Allow_Delete__c = true;
        update inv;
        
        Boolean exceptionThrown = false;
        
        test.StartTest();
        try{
            delete inv;
        } catch(Exception e) {
            exceptionThrown = true;
            Boolean expectedExceptionThrown =  (e.getMessage().contains('You can not delete an Invoice that has been synced with Intacct')) ? true : false; 
        }
        System.assertEquals(false, exceptionThrown, 'No exception was thrown');
        Test.StopTest();
    }
    
}