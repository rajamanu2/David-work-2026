trigger P_InvoiceTrigger on Invoice__c (before insert, before update, before delete) {
	if(Trigger.IsInsert || Trigger.IsUpdate || Trigger.IsDelete){
            P_InvoiceTriggerHandler invoiceh = new P_InvoiceTriggerHandler();
            invoiceh.doTriggerWork(Trigger.New, Trigger.OldMap);
        }
}