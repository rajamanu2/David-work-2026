trigger P_CaseTrigger on Case (before insert) {
    
    if(Trigger.IsInsert){
        P_CaseTriggerHandler ch = new P_CaseTriggerHandler();
        ch.processRecords(Trigger.New);
    }

}