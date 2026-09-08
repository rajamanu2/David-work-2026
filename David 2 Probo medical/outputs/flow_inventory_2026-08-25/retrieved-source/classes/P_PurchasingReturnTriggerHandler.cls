public class P_PurchasingReturnTriggerHandler {
    public void doTriggerWork(List<Purchasing_Return__c> purchasingReturnList, Map<Id, Purchasing_Return__c> oldPurchasingReturn) {
        if (Trigger.isBefore) {
            if (Trigger.isDelete) {
                checkDeletes(oldPurchasingReturn);
            }  
            if (Trigger.IsUpdate) {
                checkUpdates(purchasingReturnList, oldPurchasingReturn);
            }
        }
    }
    
    // This prevents anyone from deleting a purchasing return that is synced to intacct.
    private void checkDeletes(Map<Id, Purchasing_Return__c> oldRecs) {
        for (Purchasing_Return__c pr : oldRecs.values()) {
            if (pr.Intacct_PO_Return_Sync_Status__c != '' && pr.Intacct_PO_Return_Sync_Status__c != null) {
                if (!pr.Allow_Delete__c) {
                    pr.addError('You can not delete a Purchasing Return that has been synced with Intacct');
                } else {
                    Synced_Record_Delete_Log__c dl = new Synced_Record_Delete_Log__c(
                        Name=pr.Name,
                        Record_Id__c=pr.Id,
                        Record_Type__c='Purchasing_Return__c'
                    );
                    insert dl;
                }
            }
        }
    }
    
    // This prevents anyone from changing the status if it is synced to intacct.
    public static void checkUpdates(List<Purchasing_Return__c> newRecs, Map<Id, Purchasing_Return__c> oldRecs) {
        Boolean hasPermission = FeatureManagement.checkPermission('Manage_Intacct_Synced_Records');
        for (Purchasing_Return__c pr : newRecs) {
            if (oldRecs.get(pr.Id).Intacct_PO_Return_Sync_Status__c == 'Synced' && pr.Intacct_PO_Return_Sync_Status__c != 'Synced' && !hasPermission) {
                pr.addError('You can not change the status of a Purchasing Return that has been synced with Intacct');
            }
        }
    }
}