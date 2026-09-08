trigger P_PurchasingReturnTrigger on Purchasing_Return__c (before update, before delete) {
    P_PurchasingReturnTriggerHandler handler = new P_PurchasingReturnTriggerHandler();
    handler.doTriggerWork(Trigger.New, Trigger.OldMap);
}