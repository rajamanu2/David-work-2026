trigger QuoteLineGroupTrigger on SBQQ__QuoteLineGroup__c (before insert, before update, after insert, after update) {
    
    // Block recursion from helper updates
    if (QuoteLineGroupAsyncHelper.isExecuting) return;

    Set<Id> quoteIds = new Set<Id>();
    for (SBQQ__QuoteLineGroup__c grp : Trigger.new) {
        if (grp.SBQQ__Quote__c != null) {
            quoteIds.add(grp.SBQQ__Quote__c);
        }
    }

    if (quoteIds.isEmpty()) return;

    // 1. Fetch parent Quotes with Type, Opportunity Type, and Master Contract Lineage
    Map<Id, SBQQ__Quote__c> parentQuotes = new Map<Id, SBQQ__Quote__c>(
        [SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__SubscriptionTerm__c, 
                SBQQ__Type__c, SBQQ__Opportunity2__r.Type, SBQQ__MasterContract__c
         FROM SBQQ__Quote__c 
         WHERE Id IN :quoteIds]
    );

    // Filter to process ONLY Net New Quotes
    Set<Id> netNewQuoteIds = new Set<Id>();
    for (Id qId : parentQuotes.keySet()) {
        SBQQ__Quote__c q = parentQuotes.get(qId);
        
        Boolean isNetNewType = (q.SBQQ__Type__c == 'Quote' || q.SBQQ__Type__c == null);
        Boolean isNewBusinessOpp = (q.SBQQ__Opportunity2__r != null && q.SBQQ__Opportunity2__r.Type == 'New Business');
        Boolean isNotAmendmentOrRenewal = (q.SBQQ__Type__c != 'Renewal' && q.SBQQ__Type__c != 'Amendment' && q.SBQQ__MasterContract__c == null);

        if ((isNetNewType || isNewBusinessOpp) && isNotAmendmentOrRenewal) {
            netNewQuoteIds.add(qId);
        }
    }

    // Exit early if no Net New quotes exist in trigger context
    if (netNewQuoteIds.isEmpty()) return;

    // 2. Query Quote Lines to map each Group ID to its Product Code(s)
    Map<Id, String> groupToProductCodeMap = new Map<Id, String>();
    String fallbackProductCode = null;

    for (SBQQ__QuoteLine__c line : [
        SELECT Id, SBQQ__Group__c, SBQQ__ProductCode__c, SBQQ__Product__c 
        FROM SBQQ__QuoteLine__c 
        WHERE SBQQ__Quote__c IN :netNewQuoteIds AND SBQQ__Group__c != null
    ]) {
        if (line.SBQQ__ProductCode__c != null) {
            if (!groupToProductCodeMap.containsKey(line.SBQQ__Group__c)) {
                groupToProductCodeMap.put(line.SBQQ__Group__c, line.SBQQ__ProductCode__c);
            }
            if (fallbackProductCode == null) {
                fallbackProductCode = line.SBQQ__ProductCode__c;
            }
        }
    }

    // 3. Query existing groups sorted strictly by Number
    List<SBQQ__QuoteLineGroup__c> allQuoteGroups = [
        SELECT Id, Name, SBQQ__Quote__c, SBQQ__Number__c, Allow_Product_Ramping__c, 
               SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__SubscriptionTerm__c
        FROM SBQQ__QuoteLineGroup__c
        WHERE SBQQ__Quote__c IN :netNewQuoteIds
        ORDER BY SBQQ__Quote__c ASC, SBQQ__Number__c ASC
    ];

    Map<Id, SBQQ__QuoteLineGroup__c> triggerNewMap = new Map<Id, SBQQ__QuoteLineGroup__c>();
    for (SBQQ__QuoteLineGroup__c newGrp : Trigger.new) {
        if (newGrp.Id != null && netNewQuoteIds.contains(newGrp.SBQQ__Quote__c)) {
            triggerNewMap.put(newGrp.Id, newGrp);
        }
    }

    // Build Group Name to Product Code mapping from existing saved groups
    Map<String, String> groupNameToProductCodeMap = new Map<String, String>();
    for (SBQQ__QuoteLineGroup__c grp : allQuoteGroups) {
        if (grp.Name != null && groupToProductCodeMap.containsKey(grp.Id)) {
            groupNameToProductCodeMap.put(grp.Name, groupToProductCodeMap.get(grp.Id));
        }
    }

    Map<Id, List<SBQQ__QuoteLineGroup__c>> quoteToGroupsMap = new Map<Id, List<SBQQ__QuoteLineGroup__c>>();
    for (Id qId : netNewQuoteIds) {
        quoteToGroupsMap.put(qId, new List<SBQQ__QuoteLineGroup__c>());
    }

    for (SBQQ__QuoteLineGroup__c grp : allQuoteGroups) {
        if (triggerNewMap.containsKey(grp.Id)) {
            SBQQ__QuoteLineGroup__c fresh = triggerNewMap.get(grp.Id);
            grp.Allow_Product_Ramping__c = fresh.Allow_Product_Ramping__c;
            grp.SBQQ__SubscriptionTerm__c = fresh.SBQQ__SubscriptionTerm__c;
            grp.Name = fresh.Name;
        }
        quoteToGroupsMap.get(grp.SBQQ__Quote__c).add(grp);
    }

    for (SBQQ__QuoteLineGroup__c newGrp : Trigger.new) {
        if (newGrp.Id == null && newGrp.SBQQ__Quote__c != null && netNewQuoteIds.contains(newGrp.SBQQ__Quote__c)) {
            quoteToGroupsMap.get(newGrp.SBQQ__Quote__c).add(newGrp);
        }
    }

    List<Id> asyncGroupIds = new List<Id>();
    List<Date> asyncStartDates = new List<Date>();
    List<Date> asyncEndDates = new List<Date>();

    // =========================================================================
    // SECTION 1: Sequential Date Calculation Loop (NET NEW QUOTES ONLY)
    // =========================================================================
    for (Id qId : quoteToGroupsMap.keySet()) {
        SBQQ__Quote__c parentQuote = parentQuotes.get(qId);
        if (parentQuote == null || parentQuote.SBQQ__StartDate__c == null) continue;

        Date quoteStartDate = parentQuote.SBQQ__StartDate__c;
        Date quoteEndDate = parentQuote.SBQQ__EndDate__c;
        Decimal quoteHeaderTerm = (parentQuote.SBQQ__SubscriptionTerm__c != null) ? parentQuote.SBQQ__SubscriptionTerm__c : 36;

        List<SBQQ__QuoteLineGroup__c> groupsForQuote = quoteToGroupsMap.get(qId);
        Date previousRampedGroupEndDate = null;

        for (SBQQ__QuoteLineGroup__c grp : groupsForQuote) {
            Boolean isRamping = (grp.Allow_Product_Ramping__c == true);
            Date calculatedStartDate;
            Date calculatedEndDate;

            if (isRamping) {
                Decimal grpTerm = (grp.SBQQ__SubscriptionTerm__c != null) ? grp.SBQQ__SubscriptionTerm__c : 0;

                if (previousRampedGroupEndDate == null) {
                    calculatedStartDate = quoteStartDate;
                } else {
                    calculatedStartDate = previousRampedGroupEndDate.addDays(1);
                }

                if (calculatedStartDate != null && grpTerm > 0) {
                    Integer termMonths = grpTerm.intValue();
                    calculatedEndDate = calculatedStartDate.addMonths(termMonths).addDays(-1);
                }

                if (calculatedEndDate != null) {
                    previousRampedGroupEndDate = calculatedEndDate;
                }
            } else {
                previousRampedGroupEndDate = null;
                calculatedStartDate = quoteStartDate;
                calculatedEndDate = quoteEndDate;

                Decimal defaultTerm = quoteHeaderTerm;

                if (Trigger.isBefore && triggerNewMap.containsKey(grp.Id)) {
                    triggerNewMap.get(grp.Id).SBQQ__SubscriptionTerm__c = defaultTerm;
                } else if (Trigger.isBefore && grp.Id == null) {
                    grp.SBQQ__SubscriptionTerm__c = defaultTerm;
                }
            }

            if (Trigger.isBefore && triggerNewMap.containsKey(grp.Id)) {
                SBQQ__QuoteLineGroup__c target = triggerNewMap.get(grp.Id);
                target.SBQQ__StartDate__c = calculatedStartDate;
                target.SBQQ__EndDate__c = calculatedEndDate;
            } else if (Trigger.isBefore && grp.Id == null) {
                grp.SBQQ__StartDate__c = calculatedStartDate;
                grp.SBQQ__EndDate__c = calculatedEndDate;
            }

            if (Trigger.isAfter && grp.Id != null && !triggerNewMap.containsKey(grp.Id)) {
                asyncGroupIds.add(grp.Id);
                asyncStartDates.add(calculatedStartDate);
                asyncEndDates.add(calculatedEndDate);
            }
        }
    }

    if (Trigger.isAfter && !asyncGroupIds.isEmpty()) {
        QuoteLineGroupAsyncHelper.updateSiblingGroups(asyncGroupIds, asyncStartDates, asyncEndDates);
    }

    // =========================================================================
    // SECTION 2: NAME MATCHING & SEQUENCE PROXIMITY VALIDATION
    // =========================================================================
    if (Trigger.isBefore) {
        for (Id qId : netNewQuoteIds) {
            SBQQ__Quote__c parentQuote = parentQuotes.get(qId);
            if (parentQuote == null || parentQuote.SBQQ__SubscriptionTerm__c == null) continue;

            Decimal quoteHeaderTerm = parentQuote.SBQQ__SubscriptionTerm__c;
            List<SBQQ__QuoteLineGroup__c> groupsForQuote = quoteToGroupsMap.get(qId);
            if (groupsForQuote == null) continue;

            Integer unsavedGroupCount = 0;
            for (SBQQ__QuoteLineGroup__c grp : groupsForQuote) {
                if (grp.Id == null) unsavedGroupCount++;
            }
            if (Trigger.isInsert && unsavedGroupCount > 0) continue;

            // Map total term sums strictly by Product Code
            Map<String, Decimal> productChainSums = new Map<String, Decimal>();
            String lastSeenRampedProductCode = fallbackProductCode;

            for (SBQQ__QuoteLineGroup__c grp : groupsForQuote) {
                Boolean isRamping = (grp.Allow_Product_Ramping__c == true);
                Decimal termValue = (grp.SBQQ__SubscriptionTerm__c != null) ? grp.SBQQ__SubscriptionTerm__c : 0;

                if (isRamping) {
                    String prodKey = null;

                    // 1. Saved group: Use Product Code directly from SOQL lines
                    if (grp.Id != null && groupToProductCodeMap.containsKey(grp.Id)) {
                        prodKey = groupToProductCodeMap.get(grp.Id);
                    } 
                    // 2. Name Matching: Match draft group's copied name against existing group names
                    else if (grp.Name != null && groupNameToProductCodeMap.containsKey(grp.Name)) {
                        prodKey = groupNameToProductCodeMap.get(grp.Name);
                    }
                    // 3. Proximity Fallback: Use last seen ramped product code in sequence
                    else if (lastSeenRampedProductCode != null) {
                        prodKey = lastSeenRampedProductCode;
                    } 
                    // 4. Default Fallback
                    else {
                        prodKey = fallbackProductCode != null ? fallbackProductCode : 'Ramp_Chain_1';
                    }

                    // Keep sequence proximity pointer updated
                    lastSeenRampedProductCode = prodKey;

                    Decimal currentSum = productChainSums.containsKey(prodKey) ? productChainSums.get(prodKey) : 0;
                    productChainSums.put(prodKey, currentSum + termValue);
                }
            }

            // Inspect Product Code Chain Totals
            List<String> errors = new List<String>();
            Integer chainIndex = 1;

            for (String prodKey : productChainSums.keySet()) {
                Decimal chainTotalTerm = productChainSums.get(prodKey);

                if (chainTotalTerm != quoteHeaderTerm) {
                    Decimal difference = quoteHeaderTerm - chainTotalTerm;

                    if (difference > 0) {
                        errors.add('RampedUp Group' + '' + ' (' + prodKey + ') total term (' + chainTotalTerm.intValue() + 
                            ' months) must equal the Quote Header Term (' + quoteHeaderTerm.intValue() + 
                            ' months). You have ' + difference.intValue() + ' month(s) remaining unallocated.');
                    } else {
                        errors.add('Cannot clone additional rampup Group. The RampUp Group for Product Line #' + ' ' + ' (' + prodKey + ')' +
                            ' (' + chainTotalTerm.intValue() + ' months) exceeds the maximum Quote Header Term (' + 
                            quoteHeaderTerm.intValue() + ' months). Please delete or reduce extra cloned groups.');
                    }
                }
                chainIndex++;
            }

            if (!errors.isEmpty()) {
                String primaryErrorMessage = errors[0];

                for (SBQQ__QuoteLineGroup__c triggerGrp : Trigger.new) {
                    if (triggerGrp.SBQQ__Quote__c == qId) {
                        triggerGrp.addError(primaryErrorMessage);
                    }
                }
            }
        }
    }
}