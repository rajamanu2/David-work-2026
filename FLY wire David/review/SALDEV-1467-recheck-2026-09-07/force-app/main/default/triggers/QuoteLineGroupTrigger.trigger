trigger QuoteLineGroupTrigger on SBQQ__QuoteLineGroup__c (before insert, before update, after insert, after update) {
    
    // Global Recursion Guard
    if (QuoteLineGroupAsyncHelper.isExecuting) return;

    Set<Id> quoteIds = new Set<Id>();
    for (SBQQ__QuoteLineGroup__c grp : Trigger.new) {
        if (grp.SBQQ__Quote__c != null) {
            quoteIds.add(grp.SBQQ__Quote__c);
        }
    }

    if (quoteIds.isEmpty()) return;

    // =========================================================================
    // SECTION 0: BULKIFIED SOURCE-RELATIVE GROUP RE-SEQUENCING (AFTER INSERT ONLY)
    // =========================================================================
    // Moving sequence updates to after insert prevents before-trigger recursion loops!
    if (Trigger.isAfter && Trigger.isInsert) {
        Set<Id> sourceGroupIds = new Set<Id>();
        for (SBQQ__QuoteLineGroup__c newGrp : Trigger.new) {
            if (newGrp.SBQQ__Source__c != null) {
                sourceGroupIds.add(newGrp.SBQQ__Source__c);
            }
        }

        if (!sourceGroupIds.isEmpty()) {
            Map<Id, SBQQ__QuoteLineGroup__c> sourceGroups = new Map<Id, SBQQ__QuoteLineGroup__c>(
                [SELECT Id, SBQQ__Quote__c, SBQQ__Number__c FROM SBQQ__QuoteLineGroup__c WHERE Id IN :sourceGroupIds]
            );

            Set<Id> targetQuoteIds = new Set<Id>();
            for (SBQQ__QuoteLineGroup__c src : sourceGroups.values()) {
                if (src.SBQQ__Quote__c != null) targetQuoteIds.add(src.SBQQ__Quote__c);
            }

            List<SBQQ__QuoteLineGroup__c> existingQuoteGroups = [
                SELECT Id, SBQQ__Quote__c, SBQQ__Number__c 
                FROM SBQQ__QuoteLineGroup__c 
                WHERE SBQQ__Quote__c IN :targetQuoteIds AND Id NOT IN :Trigger.newMap.keySet()
                ORDER BY SBQQ__Number__c DESC
            ];

            Map<Id, List<SBQQ__QuoteLineGroup__c>> quoteToExistingGroupsMap = new Map<Id, List<SBQQ__QuoteLineGroup__c>>();
            for (SBQQ__QuoteLineGroup__c grp : existingQuoteGroups) {
                if (!quoteToExistingGroupsMap.containsKey(grp.SBQQ__Quote__c)) {
                    quoteToExistingGroupsMap.put(grp.SBQQ__Quote__c, new List<SBQQ__QuoteLineGroup__c>());
                }
                quoteToExistingGroupsMap.get(grp.SBQQ__Quote__c).add(grp);
            }

            Map<Id, SBQQ__QuoteLineGroup__c> groupsToShiftMap = new Map<Id, SBQQ__QuoteLineGroup__c>();

            for (SBQQ__QuoteLineGroup__c newGrp : Trigger.new) {
                if (newGrp.SBQQ__Source__c != null && sourceGroups.containsKey(newGrp.SBQQ__Source__c)) {
                    SBQQ__QuoteLineGroup__c sourceGrp = sourceGroups.get(newGrp.SBQQ__Source__c);
                    Decimal sourceNum = (sourceGrp.SBQQ__Number__c != null) ? sourceGrp.SBQQ__Number__c : 1;
                    Decimal targetNum = sourceNum + 1;

                    List<SBQQ__QuoteLineGroup__c> siblings = quoteToExistingGroupsMap.get(newGrp.SBQQ__Quote__c);
                    if (siblings != null) {
                        for (SBQQ__QuoteLineGroup__c sibling : siblings) {
                            if (sibling.SBQQ__Number__c >= targetNum) {
                                sibling.SBQQ__Number__c = sibling.SBQQ__Number__c + 1;
                                groupsToShiftMap.put(sibling.Id, sibling);
                            }
                        }
                    }
                }
            }

            if (!groupsToShiftMap.isEmpty()) {
                QuoteLineGroupAsyncHelper.isExecuting = true;
                update groupsToShiftMap.values();
                QuoteLineGroupAsyncHelper.isExecuting = false;
            }
        }
    }

    // =========================================================================
    // BEFORE TRIGGER CALCULATIONS
    // =========================================================================
    if (Trigger.isBefore) {

        // 1. Fetch parent Quotes
        Map<Id, SBQQ__Quote__c> parentQuotes = new Map<Id, SBQQ__Quote__c>(
            [SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__SubscriptionTerm__c, 
                    SBQQ__Type__c, SBQQ__Opportunity2__r.Type, SBQQ__MasterContract__c
             FROM SBQQ__Quote__c 
             WHERE Id IN :quoteIds]
        );

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

        // 3. Query existing groups
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

        // SECTION 1: Sequential Date Calculation
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

                    if (triggerNewMap.containsKey(grp.Id)) {
                        triggerNewMap.get(grp.Id).SBQQ__SubscriptionTerm__c = defaultTerm;
                    } else if (grp.Id == null) {
                        grp.SBQQ__SubscriptionTerm__c = defaultTerm;
                    }
                }

                if (triggerNewMap.containsKey(grp.Id)) {
                    SBQQ__QuoteLineGroup__c target = triggerNewMap.get(grp.Id);
                    target.SBQQ__StartDate__c = calculatedStartDate;
                    target.SBQQ__EndDate__c = calculatedEndDate;
                } else if (grp.Id == null) {
                    grp.SBQQ__StartDate__c = calculatedStartDate;
                    grp.SBQQ__EndDate__c = calculatedEndDate;
                }
            }
        }

        // SECTION 2: Term Sum Validation (SAVE-TIME ONLY)
        for (Id qId : netNewQuoteIds) {
            SBQQ__Quote__c parentQuote = parentQuotes.get(qId);
            if (parentQuote == null || parentQuote.SBQQ__SubscriptionTerm__c == null) continue;

            Decimal quoteHeaderTerm = parentQuote.SBQQ__SubscriptionTerm__c;
            List<SBQQ__QuoteLineGroup__c> groupsForQuote = quoteToGroupsMap.get(qId);
            if (groupsForQuote == null) continue;

            Map<String, Decimal> productChainSums = new Map<String, Decimal>();
            String lastSeenRampedProductCode = fallbackProductCode;

            for (SBQQ__QuoteLineGroup__c grp : groupsForQuote) {
                SBQQ__QuoteLineGroup__c activeGrp = (grp.Id != null && triggerNewMap.containsKey(grp.Id)) 
                    ? triggerNewMap.get(grp.Id) 
                    : grp;

                Boolean isRamping = (activeGrp.Allow_Product_Ramping__c == true);
                Decimal termValue = (activeGrp.SBQQ__SubscriptionTerm__c != null) ? activeGrp.SBQQ__SubscriptionTerm__c : 0;

                if (isRamping) {
                    String prodKey = null;

                    if (activeGrp.Id != null && groupToProductCodeMap.containsKey(activeGrp.Id)) {
                        prodKey = groupToProductCodeMap.get(activeGrp.Id);
                    } 
                    else if (activeGrp.Name != null && groupNameToProductCodeMap.containsKey(activeGrp.Name)) {
                        prodKey = groupNameToProductCodeMap.get(activeGrp.Name);
                    }
                    else if (lastSeenRampedProductCode != null) {
                        prodKey = lastSeenRampedProductCode;
                    }

                    if (prodKey != null) {
                        lastSeenRampedProductCode = prodKey;

                        Decimal currentSum = productChainSums.containsKey(prodKey) ? productChainSums.get(prodKey) : 0;
                        productChainSums.put(prodKey, currentSum + termValue);
                    }
                }
            }

            Boolean isPureGroupInsertion = false;
            for (SBQQ__QuoteLineGroup__c newGrp : Trigger.new) {
                if (newGrp.Id == null) {
                    isPureGroupInsertion = true;
                    break;
                }
            }

            if (isPureGroupInsertion) {
                continue; // Allow UI cloning without blocking on insertion
            }

            List<String> errors = new List<String>();

            for (String prodKey : productChainSums.keySet()) {
                Decimal chainTotalTerm = productChainSums.get(prodKey);

                if (chainTotalTerm != quoteHeaderTerm) {
                    Decimal difference = quoteHeaderTerm - chainTotalTerm;

                    if (difference > 0) {
                        errors.add('RampedUp Group (' + prodKey + ') total term (' + chainTotalTerm.intValue() + 
                            ' months) must equal the Quote Header Term (' + quoteHeaderTerm.intValue() + 
                            ' months). You have ' + difference.intValue() + ' month(s) remaining unallocated.');
                    } else {
                        errors.add('Cannot clone additional rampup Group. The RampUp Group for Product Line # (' + prodKey + ')' +
                            ' (' + chainTotalTerm.intValue() + ' months) exceeds the maximum Quote Header Term (' + 
                            quoteHeaderTerm.intValue() + ' months). Please delete or reduce extra cloned groups.');
                    }
                }
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