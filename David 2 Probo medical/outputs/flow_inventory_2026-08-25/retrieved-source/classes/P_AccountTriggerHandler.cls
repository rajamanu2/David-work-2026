public class P_AccountTriggerHandler {
    public void doTriggerWork(List<Account> accountList, Map<Id, Account> oldAccounts) {
        if (Trigger.isDelete) {
            checkDeletes(oldAccounts);
        } else if (Trigger.IsUpdate) {
            // checkUpdates(accountList, oldAccounts);
        }
    }
    
    // This prevents anyone from deleted an invoice that is synced to intacct.
    private void checkDeletes(Map<Id, Account> oldRecs) {
        for (Account a : oldRecs.values()) {
            if (a.Intacct_Customer_Sync_Status__c != '' && a.Intacct_Customer_Sync_Status__c != null) {
                if (!a.Allow_Delete__c) {
                    a.addError('You can not delete an Account that has been synced with Intacct');
                } else {
                    Synced_Record_Delete_Log__c dl1 = new Synced_Record_Delete_Log__c(
                        Name=a.Name,
                        Record_Id__c=a.Id,
                        Record_Type__c='Account'
                    );
                    insert dl1;
                }
            }
            if (a.Intacct_Vendor_Sync_Status__c != '' && a.Intacct_Vendor_Sync_Status__c != null) {
                if (!a.Allow_Delete__c) {
                    a.addError('You can not delete an Account that has been synced with Intacct');
                } else {
                    Synced_Record_Delete_Log__c dl2 = new Synced_Record_Delete_Log__c(
                        Name=a.Name,
                        Record_Id__c=a.Id,
                        Record_Type__c='Account'
                    );
                    insert dl2;
                }
            }
        }
    }
    
    // This prevents anyone from changing the status if it is synced to intacct.
    /*
    private void checkUpdates(List<Account> newRecs, Map<Id, Account> oldRecs) {
        for (Account a : newRecs) {
            Boolean hasPermission = FeatureManagement.checkPermission('Manage_Intacct_Synced_Records'); 
            if (oldRecs.get(a.Id).Intacct_Customer_Sync_Status__c == 'Synced' && a.Intacct_Customer_Sync_Status__c != 'Synced' && !hasPermission) {
                a.addError('You can not change the status of an Account that has been synced with Intacct');
            }
            if (oldRecs.get(a.Id).Intacct_Vendor_Sync_Status__c == 'Synced' && a.Intacct_Vendor_Sync_Status__c != 'Synced' && !hasPermission) {
                a.addError('You can not change the status of an Account that has been synced with Intacct');
            }
        }
    }
	*/
}