trigger P_ProductRepairTrigger on Product_Repair__c  (before insert, after insert, before update, after update, before delete) {

    P_ProductRepairTriggerHandler ph = new P_ProductRepairTriggerHandler();
    ph.processRecords(Trigger.new, Trigger.newMap, Trigger.oldMap);
}