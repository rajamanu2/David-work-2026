trigger WorkOrderTrigger on WorkOrder (before insert, before update) {
    
    WorkOrderTriggerHelper helper = new WorkOrderTriggerHelper();
    helper.handler(Trigger.isAfter, Trigger.isBefore, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete, Trigger.isUndelete, Trigger.New, Trigger.Old, Trigger.newMap, Trigger.OldMap);

}