trigger CreditMemoTrigger on Credit_Memo__c (before update) {
	
    if(Trigger.isUpdate) {
        Map<Id,Credit_Memo__c> CMOldList = new Map<Id,Credit_Memo__c>();
        for(Credit_Memo__c CM : Trigger.Old){
            CMOldList.put(CM.id,CM);
        }
        
        Set<Id> CreditMemoIdSet = new Set<Id>();
        for(Credit_Memo__c CM : Trigger.New){
            if(CM.Intacct_Credit_Memo_Sync_Status__c == 'sync' && CMOldList.get(CM.id).Intacct_Credit_Memo_Sync_Status__c != CM.Intacct_Credit_Memo_Sync_Status__c){
                CreditMemoIdSet.add(CM.id);
            }
        }

        if(CreditMemoIdSet.size()>0){
            P_CreditMemoActions.SendCreditMemoToIntacct(CreditMemoIdSet);
        }        
    }
}