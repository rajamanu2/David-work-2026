trigger P_OppLineItemTrigger on OpportunityLineItem (before insert, after insert, before update, after update, before delete, after delete) {
    if(!Validator_Class.ByPassOppTrigger()) {
        //if(Trigger.isAfter || (Trigger.IsBefore && (Trigger.IsInsert || Trigger.IsUpdate))){
        String debug = '';
        System.debug('OLI TRIGGER (CURRENT LIMIT PRIOR TO RUNNING): ' + Limits.getQueries());
        if(Trigger.isInsert || Trigger.IsUpdate){ 
            if(Trigger.isbefore) {
            	debug = '...OLI before';
        	} else {
            	debug = '...OLI after';
        	} 
            if(Trigger.isInsert) {
                debug += ' Insert ';
            } else {
                debug += ' Update ';
            }
            System.debug(debug + 'Start of P_OppLineItemTrigger' );
            P_OppLineItemTriggerHandler hndlr = new P_OppLineItemTriggerHandler();
            hndlr.processRecords(Trigger.new, Trigger.oldMap);

            if (Trigger.isAfter) {
                Boolean shouldEnqueueSync = Trigger.isInsert;
                if (Trigger.isUpdate) {
                    for (OpportunityLineItem oli : Trigger.new) {
                        OpportunityLineItem oldOli = Trigger.oldMap.get(oli.Id);
                        if (oldOli == null
                            || oli.OpportunityId != oldOli.OpportunityId
                            || oli.Description != oldOli.Description
                            || oli.Quantity != oldOli.Quantity
                            || oli.UnitPrice != oldOli.UnitPrice
                            || oli.PricebookEntryId != oldOli.PricebookEntryId
                            || oli.ProductItem__c != oldOli.ProductItem__c
                            || oli.Product2Id != oldOli.Product2Id
                            || oli.Exchange__c != oldOli.Exchange__c) {
                            shouldEnqueueSync = true;
                            break;
                        }
                    }
                }

                if (shouldEnqueueSync) {
                    WorkOrderOpportunityProductSync.enqueueFromOpportunity(Trigger.new, Trigger.oldMap, false);
                }
            }

        }
        if(Trigger.IsDelete){
            P_OppLineItemDeleteHandler rh = new P_OppLineItemDeleteHandler();
            if(Trigger.isBefore){
                rh.doBeforeDeleteWork(Trigger.oldMap);
            }
            if(Trigger.IsAfter){
                rh.doAfterDeleteWork(Trigger.oldMap);
                WorkOrderOpportunityProductSync.enqueueFromOpportunity(null, Trigger.oldMap, true);
            }
        }
        
    }
}