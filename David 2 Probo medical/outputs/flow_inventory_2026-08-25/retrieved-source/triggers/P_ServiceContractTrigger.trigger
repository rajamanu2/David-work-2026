trigger P_ServiceContractTrigger on ServiceContract (before insert, before update) {
	if(Trigger.isBefore){
        P_ServiceContractTriggerHandler sc = new P_ServiceContractTriggerHandler();
        sc.processFSEInfo(Trigger.New, Trigger.OldMap);
    }
}