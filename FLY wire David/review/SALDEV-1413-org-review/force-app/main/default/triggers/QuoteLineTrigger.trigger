trigger QuoteLineTrigger on SBQQ__QuoteLine__c (before insert, before update, after insert, after update, after delete, after undelete) {

    // =========================================================================
    // BEFORE SAVE: STAGE PRICE CHANGE & OPPORTUNITY LINE MAPPING
    // =========================================================================
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            // Evaluates New vs. Price Change vs. Cancellation
            QuoteLineTriggerHandler.handlePriceChangeOnAmendmentClones(Trigger.new);
        }
        if (Trigger.isInsert) {
            // Maps Opportunity Line IDs across ramped groups
            QuoteLineTriggerHandler.copyOpportunityLineIdOnRamp(Trigger.new);
        }
    }

    // =========================================================================
    // AFTER SAVE: RECURSION GUARD & HEAVY CALCULATIONS
    // =========================================================================
    if (Trigger.isAfter) {
        if (!QuoteLineTriggerHandler.isFirstRun) return;
        QuoteLineTriggerHandler.isFirstRun = false;

        if (Trigger.isInsert || Trigger.isUndelete) {
            QuoteLineTriggerHandler.calculateAveragePrice(Trigger.new, null);
        } 
        else if (Trigger.isUpdate) {
            QuoteLineTriggerHandler.calculateAveragePrice(Trigger.new, Trigger.oldMap);
        } 
        else if (Trigger.isDelete) {
            QuoteLineTriggerHandler.calculateAveragePrice(Trigger.old, null);
            QuoteLineDeleteHandler.resetPriceChangeOnSource(Trigger.old);
        }

        QuoteLineTriggerHandler.isFirstRun = true;
    }
}