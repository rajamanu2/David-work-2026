trigger QuoteLineTrigger on SBQQ__QuoteLine__c (before insert, before update, after insert, after update, after delete, after undelete) {

    // =========================================================================
    // BEFORE SAVE: STAGE BACKGROUND FIELDS, PRICE CHANGE & OPPORTUNITY LINE MAPPING
    // =========================================================================
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            // Evaluates Price Change status FIRST so Quote_Line_Type_background__c receives derived formula values
            QuoteLineTriggerHandler.handlePriceChangeOnAmendmentClones(Trigger.new);

            // SALDEV-1499: Replaces 'Quote Line Type background field update' Flow in memory to prevent SOQL 101 limits
            QuoteLineTriggerHandler.processBackgroundFields(Trigger.new, Trigger.oldMap);

            // SALDEV-1499: Copy the formula-derived Quote Line Type only after
            // Price_Change__c has been evaluated for the current transaction.
            QuoteLineTriggerHandler.copyQuoteLineTypeToBackground(Trigger.new);
        }

        if (Trigger.isInsert) {
            // SALDEV-1427: Maps Opportunity Line IDs across ramped groups on insert
            QuoteLineTriggerHandler.copyOpportunityLineIdOnRamp(Trigger.new);
        }

        if (Trigger.isUpdate) {
            // SALDEV-1429: Maps Opportunity Line IDs across ramped groups/clones on update
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

                //if (String.isBlank(ql.Opportunity_Line_Id__c) || ql.SBQQ__Group__c != oldQl.SBQQ__Group__c) 
                // FIXED (PREVENTS EXCESS RE-SYNC CALLS):
			if (String.isBlank(ql.Opportunity_Line_Id__c)){
                    needsIdSync = true;

                    if (ql.SBQQ__Quote__c != null) {
                        quoteIds.add(ql.SBQQ__Quote__c);
                    }
                }
            }

            // Guarded block replaces trigger-level return statement to preserve downstream rollups (SALDEV-1499 Review)
            if (needsIdSync && !quoteIds.isEmpty()) {
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
                    Boolean previousState = QuoteLineTriggerHandler.isFirstRun;

                    try {
                        QuoteLineTriggerHandler.isFirstRun = false;
                        OpportunityLineItemTriggerHandler.processOliIdSync(relatedOlis);
                    } finally {
                        QuoteLineTriggerHandler.isFirstRun = previousState;
                    }
                }
            }
        }

        // SALDEV-1499: Do not move this return into the OLI self-healing block above.
        // The OLI synchronization is intentionally isolated so that normal
        // Quote Line rollup processing is not bypassed.
        // ---------------------------------------------------------------------
        // RECURSION GUARDED HEAVY CALCULATIONS
        // ---------------------------------------------------------------------
        if (!QuoteLineTriggerHandler.isFirstRun) return;
        
        try {
            QuoteLineTriggerHandler.isFirstRun = false;

            if (Trigger.isInsert || Trigger.isUndelete) {
                QuoteLineTriggerHandler.calculateRollupField(Trigger.new, null);
            } 
            else if (Trigger.isUpdate) {
                QuoteLineTriggerHandler.calculateRollupField(Trigger.new, Trigger.oldMap);
            } 
            else if (Trigger.isDelete) {
                QuoteLineTriggerHandler.calculateRollupField(Trigger.old, null);
                QuoteLineDeleteHandler.resetPriceChangeOnSource(Trigger.old);
            }

        } finally {
            QuoteLineTriggerHandler.isFirstRun = true;
        }
    }
}