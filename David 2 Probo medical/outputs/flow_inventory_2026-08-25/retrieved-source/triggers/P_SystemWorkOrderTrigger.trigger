trigger P_SystemWorkOrderTrigger on System_Work_Order__c (before update) {
    P_SystemWorkOrderTriggerHandler rh = new P_SystemWorkOrderTriggerHandler();
    rh.run();
}