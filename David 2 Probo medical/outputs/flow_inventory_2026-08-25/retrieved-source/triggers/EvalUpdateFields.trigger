trigger EvalUpdateFields on Evaluation_Natalie__c (before insert, before update) {

    System.debug('start of EvalUpdateFields trigger');
    // SOQL in progress, DML to do.

    EvalUpdateFieldsHandler hndlr = new EvalUpdateFieldsHandler();
    if(Trigger.IsUpdate){
        hndlr.doUpdateWork(Trigger.new, Trigger.oldMap);
    }
    if(Trigger.IsInsert){
        hndlr.doInsertWork(Trigger.new);
    }
    

    System.debug('end of EvalUpdateFields trigger');
}