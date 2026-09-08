trigger ItemReceiptTrigger on Item_Receipt__c (before update) {
    if(Trigger.isUpdate) {
        Map<Id,Item_Receipt__c> IROldList = new Map<Id,Item_Receipt__c>();
        for(Item_Receipt__c IR : Trigger.Old){
            IROldList.put(IR.id,IR);
        }
        
        Set<Id> ItemReceiptIdSet = new Set<Id>();
        for(Item_Receipt__c IR : Trigger.New){
            if(IR.Intacct_Receipt_Sync_Status__c == 'Sync' && IROldList.get(IR.id).Intacct_Receipt_Sync_Status__c != IR.Intacct_Receipt_Sync_Status__c){                
                ItemReceiptIdSet.add(IR.id);
            }
        }

        if(ItemReceiptIdSet.size()>0){
            P_ItemReceiptActions.SendItemReceiptToIntacct(ItemReceiptIdSet);
        }        
    }

}