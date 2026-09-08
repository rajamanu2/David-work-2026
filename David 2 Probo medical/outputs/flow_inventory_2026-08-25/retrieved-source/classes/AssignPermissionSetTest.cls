@isTest
public class AssignPermissionSetTest {
    
    @isTest static void assignPS() {
        String userId = UserInfo.getUserId();
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Intacct_Synced_Records' LIMIT 1];
        
        List<PermissionSetAssignment> psaList = [SELECT AssigneeId FROM PermissionSetAssignment WHERE AssigneeId =: userId AND PermissionSetId =: ps.Id LIMIT 1];
        
        Test.StartTest();
        if (!psaList.isEmpty()) {
            delete psaList[0];
        }
        AssignPermissionSet.assign(userId, ps.Id);
        Test.StopTest();
        
        PermissionSetAssignment psa = [SELECT AssigneeId FROM PermissionSetAssignment WHERE AssigneeId =: userId AND PermissionSetId =: ps.Id LIMIT 1];
        System.AssertEquals(psa.AssigneeId, userId); 
    }
    
    @isTest static void removePS() {
        String userId = UserInfo.getUserId();
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Intacct_Synced_Records' LIMIT 1];
        
        List<PermissionSetAssignment> psaList = [SELECT AssigneeId FROM PermissionSetAssignment WHERE AssigneeId =: userId AND PermissionSetId =: ps.Id LIMIT 1];
        
        Test.StartTest();
        if (psaList.isEmpty()) {
            insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = ps.Id);
        }
        AssignPermissionSet.remove(userId, ps.Id);
        Test.StopTest();
        
        List<PermissionSetAssignment> psa = [SELECT AssigneeId FROM PermissionSetAssignment WHERE AssigneeId =: userId AND PermissionSetId =: ps.Id LIMIT 1];
        System.AssertEquals(true, psa.isEmpty()); 
    }
    
}