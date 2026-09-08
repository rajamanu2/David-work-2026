public class RecordLockStatus {
    
    @InvocableMethod(label='Check Record Lock Status' iconName = 'slds:custom:custom77')
    public static List<Boolean> checkRecordLockStatus(List<String> recordIds) {
        List<Boolean> lockStatusList = new List<Boolean>();
        
        for (String recordId : recordIds) {
            Boolean isLocked = isRecordLocked(recordId);
            lockStatusList.add(isLocked);
        }
        
        return lockStatusList;
    }
    
    public static Boolean isRecordLocked(String recordId) {
        return Approval.isLocked(recordId);
    }
}