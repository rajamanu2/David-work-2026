public with sharing class OpportunityLineItemTriggerHandler {

    /**
     * Entry point for triggering OpportunityLineItem updates directly from OLI Trigger.
     */
    public static void syncOpportunityLineId(List<OpportunityLineItem> newOlis) {
        if (newOlis == null || newOlis.isEmpty()) return;

        Set<Id> quoteLineIds = new Set<Id>();
        for (OpportunityLineItem oli : newOlis) {
            if (oli.SBQQ__QuoteLine__c != null) {
                quoteLineIds.add(oli.SBQQ__QuoteLine__c);
            }
        }

        if (quoteLineIds.isEmpty()) return;

        Set<Id> quoteIds = new Set<Id>();
        for (SBQQ__QuoteLine__c ql : [
            SELECT SBQQ__Quote__c 
            FROM SBQQ__QuoteLine__c 
            WHERE Id IN :quoteLineIds AND SBQQ__Quote__c != NULL
        ]) {
            quoteIds.add(ql.SBQQ__Quote__c);
        }

        if (!quoteIds.isEmpty()) {
            processOliIdSync(quoteIds);
        }
    }

    /**
     * OVERLOAD 1: PUBLIC METHOD FOR QUOTE LINE TRIGGER CALLERS
     * Accepts List<OpportunityLineItem> to fix "Method does not exist or incorrect signature" errors.
     */
    public static void processOliIdSync(List<OpportunityLineItem> oliList) {
        if (oliList == null || oliList.isEmpty()) return;

        Set<Id> quoteIds = new Set<Id>();
        for (OpportunityLineItem oli : oliList) {
            if (oli.SBQQ__QuoteLine__r != null && oli.SBQQ__QuoteLine__r.SBQQ__Quote__c != null) {
                quoteIds.add(oli.SBQQ__QuoteLine__r.SBQQ__Quote__c);
            } else if (oli.SBQQ__QuoteLine__c != null) {
                // Fallback for unqueried relationship fields
                quoteIds.add(oli.SBQQ__QuoteLine__c);
            }
        }

        if (!quoteIds.isEmpty()) {
            processOliIdSync(quoteIds);
        }
    }

    /**
     * OVERLOAD 2: CORE MAPPING ENGINE
     * Accepts Set<Id> quoteIds for optimized single-SOQL bulkified execution.
     */
    public static void processOliIdSync(Set<Id> quoteIds) {
        if (quoteIds == null || quoteIds.isEmpty()) return;

        // 1. Single Consolidated Query
        List<OpportunityLineItem> allQuoteOlis = [
            SELECT Id, Auto_Opp_Line_Id__c, Opportunity_Line_Id__c, SBQQ__QuoteLine__c, 
                   SBQQ__QuoteLine__r.SBQQ__Quote__c, SBQQ__QuoteLine__r.SBQQ__Product__c,
                   SBQQ__QuoteLine__r.SBQQ__ProductCode__c,
                   SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__ProductCode__c,
                   SBQQ__QuoteLine__r.Opportunity_Line_Id__c, SBQQ__QuoteLine__r.SBQQ__Group__c,
                   SBQQ__QuoteLine__r.SBQQ__Group__r.SBQQ__Number__c, SBQQ__QuoteLine__r.SBQQ__Source__c,
                   SBQQ__QuoteLine__r.SBQQ__Source__r.SBQQ__Group__c
            FROM OpportunityLineItem 
            WHERE SBQQ__QuoteLine__r.SBQQ__Quote__c IN :quoteIds
            ORDER BY SBQQ__QuoteLine__r.SBQQ__Group__r.SBQQ__Number__c ASC NULLS FIRST, CreatedDate ASC, Id ASC
        ];

        if (allQuoteOlis.isEmpty()) return;

        // 2. Map Lowest Group Number Per Composite Structure Key
        Map<String, Decimal> lowestGroupPerProduct = new Map<String, Decimal>();
        for (OpportunityLineItem oli : allQuoteOlis) {
            if (oli.SBQQ__QuoteLine__c == null) continue;

            Decimal grpNum = (oli.SBQQ__QuoteLine__r.SBQQ__Group__r.SBQQ__Number__c != null) 
                ? oli.SBQQ__QuoteLine__r.SBQQ__Group__r.SBQQ__Number__c 
                : 1;

            String prodCode = oli.SBQQ__QuoteLine__r.SBQQ__ProductCode__c;
            String parentProdCode = (oli.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r != null) 
                ? oli.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__ProductCode__c 
                : 'ROOT';

            String structKey = oli.SBQQ__QuoteLine__r.SBQQ__Quote__c + '-' + parentProdCode + '-' + prodCode;

            if (!lowestGroupPerProduct.containsKey(structKey) || grpNum < lowestGroupPerProduct.get(structKey)) {
                lowestGroupPerProduct.put(structKey, grpNum);
            }
        }

        // 3. Build Master ID Registry from Group 1 / Master Group
        Map<String, List<String>> masterProductIdsMap = new Map<String, List<String>>();
        for (OpportunityLineItem oli : allQuoteOlis) {
            if (oli.SBQQ__QuoteLine__c == null) continue;

            Decimal grpNum = (oli.SBQQ__QuoteLine__r.SBQQ__Group__r.SBQQ__Number__c != null) 
                ? oli.SBQQ__QuoteLine__r.SBQQ__Group__r.SBQQ__Number__c 
                : 1;

            String prodCode = oli.SBQQ__QuoteLine__r.SBQQ__ProductCode__c;
            String parentProdCode = (oli.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r != null) 
                ? oli.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__ProductCode__c 
                : 'ROOT';

            String structKey = oli.SBQQ__QuoteLine__r.SBQQ__Quote__c + '-' + parentProdCode + '-' + prodCode;
            Decimal masterGrpNum = lowestGroupPerProduct.get(structKey);

            Boolean isSameGroupClone = (oli.SBQQ__QuoteLine__r.SBQQ__Source__c != null && 
                                        oli.SBQQ__QuoteLine__r.SBQQ__Source__r.SBQQ__Group__c == oli.SBQQ__QuoteLine__r.SBQQ__Group__c);

            if (grpNum == masterGrpNum && !isSameGroupClone) {
                String masterId = String.isNotBlank(oli.Auto_Opp_Line_Id__c) ? oli.Auto_Opp_Line_Id__c : oli.Opportunity_Line_Id__c;
                if (String.isNotBlank(masterId)) {
                    if (!masterProductIdsMap.containsKey(structKey)) {
                        masterProductIdsMap.put(structKey, new List<String>());
                    }
                    masterProductIdsMap.get(structKey).add(masterId);
                }
            }
        }

        // 4. Assign Master IDs to Downstream Ramped Groups
        Map<Id, OpportunityLineItem> olisToUpdate = new Map<Id, OpportunityLineItem>();
        Map<Id, SBQQ__QuoteLine__c> quoteLinesToUpdate = new Map<Id, SBQQ__QuoteLine__c>();
        Map<String, Integer> groupOccurrenceCounter = new Map<String, Integer>();

        for (OpportunityLineItem oli : allQuoteOlis) {
            if (oli.SBQQ__QuoteLine__c == null) continue;

            Decimal grpNum = (oli.SBQQ__QuoteLine__r.SBQQ__Group__r.SBQQ__Number__c != null) 
                ? oli.SBQQ__QuoteLine__r.SBQQ__Group__r.SBQQ__Number__c 
                : 1;

            String prodCode = oli.SBQQ__QuoteLine__r.SBQQ__ProductCode__c;
            String parentProdCode = (oli.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r != null) 
                ? oli.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__ProductCode__c 
                : 'ROOT';

            String structKey = oli.SBQQ__QuoteLine__r.SBQQ__Quote__c + '-' + parentProdCode + '-' + prodCode;
            Decimal masterGrpNum = lowestGroupPerProduct.get(structKey);

            Boolean isSameGroupClone = (oli.SBQQ__QuoteLine__r.SBQQ__Source__c != null && 
                                        oli.SBQQ__QuoteLine__r.SBQQ__Source__r.SBQQ__Group__c == oli.SBQQ__QuoteLine__r.SBQQ__Group__c);

            String finalOppLineId = null;

            if (grpNum == masterGrpNum || isSameGroupClone) {
                finalOppLineId = oli.Auto_Opp_Line_Id__c;
            } else {
                String groupStructKey = grpNum + '-' + structKey;
                Integer currentSlotIndex = groupOccurrenceCounter.containsKey(groupStructKey) 
                    ? groupOccurrenceCounter.get(groupStructKey) 
                    : 0;

                if (masterProductIdsMap.containsKey(structKey)) {
                    List<String> masterIds = masterProductIdsMap.get(structKey);
                    finalOppLineId = (currentSlotIndex < masterIds.size()) 
                        ? masterIds.get(currentSlotIndex) 
                        : masterIds.get(masterIds.size() - 1);
                } else {
                    finalOppLineId = oli.Auto_Opp_Line_Id__c;
                }

                groupOccurrenceCounter.put(groupStructKey, currentSlotIndex + 1);
            }

            if (finalOppLineId != null && oli.Opportunity_Line_Id__c != finalOppLineId) {
                olisToUpdate.put(oli.Id, new OpportunityLineItem(Id = oli.Id, Opportunity_Line_Id__c = finalOppLineId));
            }

            if (finalOppLineId != null && oli.SBQQ__QuoteLine__r.Opportunity_Line_Id__c != finalOppLineId) {
                quoteLinesToUpdate.put(oli.SBQQ__QuoteLine__c, new SBQQ__QuoteLine__c(Id = oli.SBQQ__QuoteLine__c, Opportunity_Line_Id__c = finalOppLineId));
            }
        }

        // 5. Execute Guarded DML
        if (!quoteLinesToUpdate.isEmpty()) {
            QuoteLineTriggerHandler.isFirstRun = false;
            Database.update(quoteLinesToUpdate.values(), false);
            QuoteLineTriggerHandler.isFirstRun = true;
        }

        if (!olisToUpdate.isEmpty()) {
            Database.update(olisToUpdate.values(), false);
        }
    }
}