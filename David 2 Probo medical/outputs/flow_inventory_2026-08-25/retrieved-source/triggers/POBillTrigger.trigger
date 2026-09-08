trigger POBillTrigger on PO_Bill__c (before update) {
    if(Trigger.isUpdate) {
        Map<Id,PO_Bill__c> POOldList = new Map<Id,PO_Bill__c>();
        for(PO_Bill__c PO : Trigger.Old){
            POOldList.put(PO.id,PO);
        }
        
        Set<Id> POIdSet = new Set<Id>();
        for(PO_Bill__c PO : Trigger.New){
            if(PO.Intacct_AP_Bill_Sync_Status__c == 'Sync' && POOldList.get(PO.id).Intacct_AP_Bill_Sync_Status__c != PO.Intacct_AP_Bill_Sync_Status__c){                
                POIdSet.add(PO.id);
            }
        }

        if(POIdSet.size()>0){
           POBillActions.SendPOToIntacct(POIdSet);
        }        
    }

}