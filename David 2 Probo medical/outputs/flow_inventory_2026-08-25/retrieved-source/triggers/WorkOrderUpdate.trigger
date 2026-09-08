trigger WorkOrderUpdate on Work_Order__c (before insert, after insert, before update, after update) {

    WorkOrderTriggerHandler.processWOs(Trigger.new, Trigger.oldMap);
}