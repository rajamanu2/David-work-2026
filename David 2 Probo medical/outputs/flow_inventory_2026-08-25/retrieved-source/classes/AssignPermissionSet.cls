public class AssignPermissionSet {
    @future
    public static void assign(String uId, String pId){
        insert new PermissionSetAssignment(AssigneeId = uId, PermissionSetId = pId);
    }
    @future
    public static void remove(String uId, String pId){
        PermissionSetAssignment psa = [SELECT AssigneeId FROM PermissionSetAssignment WHERE AssigneeId =: uId AND PermissionSetId =: pId LIMIT 1];
        delete psa;
    }
}