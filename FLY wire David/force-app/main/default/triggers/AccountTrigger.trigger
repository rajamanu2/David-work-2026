trigger AccountTrigger on Account (after insert,after update,after undelete,before delete) {
    
    List<String> statusList = new List<String>{'Active (Product Live)','Client Signed'};
        Set<id> accIds = new set<Id>();
    Set<id> accParentCountIds = new set<Id>();
    Set<id> accChildCountIds = new set<Id>();
    
    if(trigger.isUpdate){
        for(Account acc : trigger.new){
            if(acc.ParentId != trigger.oldMap.get(acc.Id).ParentId){
                accIds.add(acc.Id);
                if(acc.ParentId!=Null){
                    accChildCountIds.add(acc.ParentId); 
                }
                if(trigger.oldMap.get(acc.Id).ParentId != Null){
                    accChildCountIds.add(trigger.oldMap.get(acc.Id).ParentId); 
                }
            }
            if(acc.Parent_Accounts__c != trigger.oldMap.get(acc.Id).Parent_Accounts__c || acc.Active_Parent_Accounts__c != trigger.oldMap.get(acc.Id).Active_Parent_Accounts__c
               || acc.Signed_Parent_Accounts__c != trigger.oldMap.get(acc.Id).Signed_Parent_Accounts__c){
                   accParentCountIds.add(acc.Id);
               }
            
            if(acc.Child_Accounts__c != trigger.oldMap.get(acc.Id).Child_Accounts__c || acc.Active_Child_Accounts__c != trigger.oldMap.get(acc.Id).Active_Child_Accounts__c
               || acc.Signed_Child_Accounts__c != trigger.oldMap.get(acc.Id).Signed_Child_Accounts__c){
                   if(acc.ParentId!=Null){
                       accChildCountIds.add(acc.ParentId); 
                   }
               }
            
            if(acc.Account_Status__c != trigger.oldMap.get(acc.Id).Account_Status__c && (statusList.contains(acc.Account_Status__c) || statusList.contains(trigger.oldMap.get(acc.Id).Account_Status__c))){
                accParentCountIds.add(acc.Id);
                if(acc.ParentId!=Null){
                    accChildCountIds.add(acc.ParentId); 
                }
            }
        }
    }
    
    if(trigger.isInsert || trigger.isUndelete){
        for(Account acc : trigger.new){
            accIds.add(acc.Id);
            if(acc.ParentId != Null){
                accChildCountIds.add(acc.ParentId);
            }
        }
    }
    
    if(trigger.isDelete){
        for(Account acc : trigger.old){
            if(acc.ParentId != null){                
                accChildCountIds.add(acc.ParentId);
            }
            accParentCountIds.add(acc.Id);
        }
    }
    
    //Update Parent Count
    if(!accParentCountIds.isEmpty()){
        Map<Id,Account> tempMap = new Map<Id,Account>([SELECT Id FROM Account WHERE ParentId in: accParentCountIds]);
        accIds.addAll(tempMap.keySet());
    }
    
    accParentCountIds = new Set<Id>();
    accParentCountIds.addAll(accIds);
    
    //setting time for scheduling the classes
    Datetime scheduleTime=Datetime.now();
    scheduleTime=scheduleTime.addSeconds(3);
    
    //parse to cron expression
    String nextFireTime = String.valueOf(scheduleTime.second()) + ' ' + String.valueOf(scheduleTime.minute()) + ' ' + String.valueOf(scheduleTime.hour()) + ' * * ?';
    
    if(!accParentCountIds.isEmpty()){	        
        AccountParentCountBatch s = new AccountParentCountBatch(accParentCountIds); 
        System.schedule('parent job Started At ' + String.valueOf(Datetime.now()), nextFireTime, s); 
    }
    
    //Update Child Count
    
    if(!accChildCountIds.isEmpty()){	        
        AccountChildCountBatch s = new AccountChildCountBatch(accChildCountIds); 
        System.schedule('child Started At ' + String.valueOf(Datetime.now()), nextFireTime, s); 
    }
}