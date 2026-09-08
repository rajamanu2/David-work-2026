trigger P_RMATrigger on RMA__c (before update, after insert, after update, before delete) {
    system.debug('THIS IS THE RMA VALIDATOR CLASS >> ' + Validator_Class.ByPassRMATrigger());
    if(!Validator_Class.ByPassRMATrigger()) {
        if((Trigger.isInsert || Trigger.IsUpdate) && Trigger.isAfter){
            P_RMATriggerHandler rh = new P_RMATriggerHandler();
            rh.processFromP_RMATrigger();
            
        }
        if(Trigger.IsDelete){
            P_RMADeleteHandler rh = new P_RMADeleteHandler();
            rh.checkDeletes(Trigger.oldMap);
        }

        if(Trigger.isBefore && Trigger.isUpdate) {
            RMAHelper.SetEmailandApprovalFields(Trigger.New, Trigger.OldMap);
        }
    }    

    // Maurice Chesire 9/19/2019:  added call to run GH framework.
    //rh.run();
}