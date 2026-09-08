trigger P_ProductTestTrigger on ProductTest__c (before insert, before update, after insert, after update, before delete) {
	if(Trigger.isInsert || Trigger.IsUpdate){
    	P_ProductTestTriggerHandler th = new P_ProductTestTriggerHandler();
    	th.processRecords(Trigger.new, Trigger.newMap, Trigger.oldMap);
    }
    if(Trigger.IsDelete){
        P_TestDeleteHandler rh = new P_TestDeleteHandler();
        rh.checkDeletes(Trigger.oldMap);
    }

}