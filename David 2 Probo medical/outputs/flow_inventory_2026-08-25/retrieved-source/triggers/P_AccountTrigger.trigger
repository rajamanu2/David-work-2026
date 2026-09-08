trigger P_AccountTrigger on Account (before update, before delete) {
    P_AccountTriggerHandler handler = new P_AccountTriggerHandler();
    handler.doTriggerWork(Trigger.New, Trigger.OldMap);
}