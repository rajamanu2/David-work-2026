@isTest
private class UserHasAccessTest {
    @TestSetup
    static void setup() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        system.runAs(currentUser) {
            PermissionSet pr = new PermissionSet(Label='Test User Access Permisson Set',Name='Test_User_Access_Permisson_Set');
            insert pr;
            PermissionSetAssignment pm = new PermissionSetAssignment(AssigneeId=userInfo.getUserId(),PermissionSetId=pr.id);
            insert pm;
        }
    }
    
    static testmethod void testGetObjectsAccess() {
        List<String> listObjects = new List<String>{'Account', 'Opportunity' };
        Map<String, Map<String, Boolean>> mapObjectsAccess = new Map<String, Map<String, Boolean>>();
            
        Test.startTest();
        mapObjectsAccess = UserHasAccess.getObjectsAccess(listObjects);
        Test.stopTest();
        
        system.assert(!mapObjectsAccess.isEmpty(), 'Object access map is empty');
        system.assertEquals(true, mapObjectsAccess.containsKey('Account'), 'Object access map does not have Account information');
    } 

    static testMethod void testHasPermissionSetAccess() {
        PermissionSet p = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Test_User_Access_Permisson_Set' LIMIT 1];
        Boolean hasAccess;
        
        Test.startTest();
        hasAccess = UserHasAccess.hasPermissionSetAccess('Test_User_Access_Permisson_Set');
        Test.stopTest();

		system.assertEquals(true, hasAccess, 'User does not have access to permission set.');        
    }     

}