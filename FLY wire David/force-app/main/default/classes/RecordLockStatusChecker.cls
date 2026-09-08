public class RecordLockStatusChecker {

    @InvocableMethod(
        label='Check Record Lock Status' 
        description='Takes a Record ID and returns True if it is locked, False if it is not.' 
        category='Record Approvals'
    )
    public static List<Boolean> checkLockStatus(List<Id> recordIds) {
        List<Boolean> results = new List<Boolean>();

        // Loop through the IDs (Flow passes a list of 1 for Screen Flows)
        for (Id recordId : recordIds) {
            if (recordId == null) {
                // If no ID is passed, default to false to prevent crashes
                results.add(false); 
            } else {
                // Approval.isLocked returns true or false natively
                results.add(Approval.isLocked(recordId));
            }
        }

        return results;
    }
}