trigger LoanerTrigger on Loaner__c (before insert, before update) {

    LoanerTriggerHandler hndlr = new LoanerTriggerHandler();
    if(Trigger.isUpdate){
        hndlr.doTriggerUpdateWork(Trigger.new, Trigger.newMap, Trigger.oldMap);
    }
    if(Trigger.isInsert){
        hndlr.doTriggerInsertWork(Trigger.new);
    }


}