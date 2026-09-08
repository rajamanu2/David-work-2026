trigger QuoteLineTrigger on SBQQ__QuoteLine__c (after insert, after update, after delete, after undelete) {
    
    // Prevent recursion during the calculation updates
    if (!QuoteLineTriggerHandler.isFirstRun) return;
    QuoteLineTriggerHandler.isFirstRun = false;

    if (Trigger.isInsert || Trigger.isUndelete) {
        // For Insert/Undelete, pass Trigger.new and null for oldMap
        QuoteLineTriggerHandler.calculateAveragePrice(Trigger.new, null);
    } 
   
    else if (Trigger.isUndelete) {
        QuoteLineTriggerHandler.calculateAveragePrice(Trigger.new, null);
    }
    else if (Trigger.isUpdate) {
        // For Update, pass Trigger.new and Trigger.oldMap
        QuoteLineTriggerHandler.calculateAveragePrice(Trigger.new, Trigger.oldMap);
    } 
    else if (Trigger.isDelete) {
        // For Delete, pass Trigger.old (as the records list) and null for oldMap
        QuoteLineTriggerHandler.calculateAveragePrice(Trigger.old, null);
        
        //Previously called in QuoteLineDeleteTrigger
        QuoteLineDeleteHandler.resetPriceChangeOnSource(Trigger.old);
    }

    QuoteLineTriggerHandler.isFirstRun = true;
    
}