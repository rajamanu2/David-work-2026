trigger QuoteLineTrigger on SBQQ__QuoteLine__c (before insert, before update, after insert, after update, after delete, after undelete) {

    // =========================================================================
    // BEFORE SAVE: STAGE BACKGROUND FIELDS, PRICE CHANGE & OPPORTUNITY LINE MAPPING
    // =========================================================================
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            // SALDEV-1499: Replaces 'Quote Line Type background field update' Flow in memory to prevent SOQL 101 limits
            QuoteLineTriggerHandler.processBackgroundFields(Trigger.new, Trigger.oldMap);

            // Evaluates New vs. Price Change vs. Cancellation
            QuoteLineTriggerHandler.handlePriceChangeOnAmendmentClones(Trigger.new);
        }
        if (Trigger.isInsert) {
            //SALDEV-1427 Maps Opportunity Line IDs across ramped groups
            QuoteLineTriggerHandler.copyOpportunityLineIdOnRamp(Trigger.new);
        }
    }

    // =========================================================================
    // AFTER SAVE: RECURSION GUARD & HEAVY CALCULATIONS
    // =========================================================================
    if (Trigger.isAfter) {
        
        // ---------------------------------------------------------------------
        // SALDEV-1467 GUARDED OLI ID SELF-HEALING (Runs on Quote Line Updates)
        // ---------------------------------------------------------------------
        if (Trigger.isUpdate && QuoteLineTriggerHandler.isFirstRun) {
            Boolean needsIdSync = false;
            Set<Id> quoteIds = new Set<Id>();

            for (SBQQ__QuoteLine__c ql : Trigger.new) {
                SBQQ__QuoteLine__c oldQl = Trigger.oldMap.get(ql.Id);

                if (String.isBlank(ql.Opportunity_Line_Id__c) || ql.SBQQ__Group__c != oldQl.SBQQ__Group__c) {
                    needsIdSync = true;
                    if (ql.SBQQ__Quote__c != null) {
                        quoteIds.add(ql.SBQQ__Quote__c);
                    }
                }
            }

            if (!needsIdSync || quoteIds.isEmpty()) return;

            List<OpportunityLineItem> relatedOlis = [
                SELECT Id, Auto_Opp_Line_Id__c, Opportunity_Line_Id__c, SBQQ__QuoteLine__c, 
                       SBQQ__QuoteLine__r.SBQQ__Quote__c, SBQQ__QuoteLine__r.SBQQ__Product__c,
                       SBQQ__QuoteLine__r.Opportunity_Line_Id__c, SBQQ__QuoteLine__r.SBQQ__Group__c,
                       SBQQ__QuoteLine__r.SBQQ__Group__r.SBQQ__Number__c, SBQQ__QuoteLine__r.SBQQ__Source__c,
                       SBQQ__QuoteLine__r.SBQQ__Source__r.SBQQ__Group__c
                FROM OpportunityLineItem 
                WHERE SBQQ__QuoteLine__r.SBQQ__Quote__c IN :quoteIds
            ];

            if (!relatedOlis.isEmpty()) {
                QuoteLineTriggerHandler.isFirstRun = false;
                OpportunityLineItemTriggerHandler.processOliIdSync(relatedOlis);
                QuoteLineTriggerHandler.isFirstRun = true;
            }
        }

        // ---------------------------------------------------------------------
        // RECURSION GUARDED HEAVY CALCULATIONS
        // ---------------------------------------------------------------------
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