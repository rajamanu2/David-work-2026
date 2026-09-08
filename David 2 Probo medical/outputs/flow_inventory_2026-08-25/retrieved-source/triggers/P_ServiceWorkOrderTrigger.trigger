trigger P_ServiceWorkOrderTrigger on WorkOrder (before insert, before update, after update) {
    
  	P_ServiceWorkOrderTriggerHandler hndlr = new P_ServiceWorkOrderTriggerHandler();
    if(Trigger.isInsert){
        hndlr.doTriggerInsertWork(Trigger.new);
    }
    if(Trigger.isUpdate && Trigger.isBefore){
        hndlr.doTriggerBeforeUpdateWork(Trigger.new, Trigger.oldMap);
    }
    if(Trigger.isUpdate && Trigger.isAfter){
        hndlr.doTriggerAfterUpdateWork(Trigger.new, Trigger.oldMap);
        
    }
    
    
    
}