trigger CreateApprovedRepairs on RMA__c (before insert, before update, after update) {
    //if(!Validator_Class.BypassOppTrigger()) {
        P_RMATriggerHandler rh = new P_RMATriggerHandler();
        rh.processFromCreateApprovedRepairs();
    
    //}
}