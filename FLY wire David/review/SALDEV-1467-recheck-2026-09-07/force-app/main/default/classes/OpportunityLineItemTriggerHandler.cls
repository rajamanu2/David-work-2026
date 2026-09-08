/**
 * @description SALDEV-1467 / SALDEV-1499: Core Sync Engine.
 * Synchronizes OpportunityLineItem Auto_Opp_Line_Id__c / Opportunity_Line_Id__c
 * directly onto SBQQ__QuoteLine__c records and downstream ramped OLIs safely.
 */
public with sharing class OpportunityLineItemTriggerHandler {

    public static Boolean isFirstRun = true;

    public static void syncOpportunityLineId(List<OpportunityLineItem> newOlis) {
        processOliIdSync(newOlis);
    }

    public static void processOliIdSync(List<OpportunityLineItem> oliList) {
        if (oliList == null || oliList.isEmpty() || !isFirstRun) return;

        Map<Id, String> oliIdMapByQuoteLineId = new Map<Id, String>();
        for (OpportunityLineItem oli : oliList) {
            if (oli != null && oli.SBQQ__QuoteLine__c != null) {
                String targetId = String.isNotBlank(oli.Opportunity_Line_Id__c) 
                    ? oli.Opportunity_Line_Id__c 
                    : oli.Auto_Opp_Line_Id__c;

                if (String.isNotBlank(targetId)) {
                    oliIdMapByQuoteLineId.put(oli.SBQQ__QuoteLine__c, targetId);
                }
            }
        }

        if (oliIdMapByQuoteLineId.isEmpty()) return;

        // Query parent Quote Lines that require synchronization
        List<SBQQ__QuoteLine__c> parentQuoteLines = [
            SELECT Id, Opportunity_Line_Id__c 
            FROM SBQQ__QuoteLine__c 
            WHERE Id IN :oliIdMapByQuoteLineId.keySet()
        ];

        List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
        for (SBQQ__QuoteLine__c ql : parentQuoteLines) {
            String incomingId = oliIdMapByQuoteLineId.get(ql.Id);
            if (String.isBlank(ql.Opportunity_Line_Id__c) || ql.Opportunity_Line_Id__c != incomingId) {
                quoteLinesToUpdate.add(new SBQQ__QuoteLine__c(
                    Id = ql.Id,
                    Opportunity_Line_Id__c = incomingId
                ));
            }
        }

        if (!quoteLinesToUpdate.isEmpty()) {
            Boolean previousQuoteLineRun = QuoteLineTriggerHandler.isFirstRun;
            try {
                isFirstRun = false;
                QuoteLineTriggerHandler.isFirstRun = false;
                Database.SaveResult[] results = Database.update(quoteLinesToUpdate, false);
                for (Database.SaveResult sr : results) {
                    if (!sr.isSuccess()) {
                        for (Database.Error err : sr.getErrors()) {
                            System.debug(LoggingLevel.ERROR, 'SALDEV-1467 Sync Error: ' + err.getMessage());
                        }
                    }
                }
            } finally {
                QuoteLineTriggerHandler.isFirstRun = previousQuoteLineRun;
                isFirstRun = true;
            }
        }
    }

    public static void processOliIdSync(Set<Id> quoteIds) {
        if (quoteIds == null || quoteIds.isEmpty() || !isFirstRun) return;

        List<OpportunityLineItem> olis = [
            SELECT Id, Auto_Opp_Line_Id__c, Opportunity_Line_Id__c, SBQQ__QuoteLine__c 
            FROM OpportunityLineItem 
            WHERE SBQQ__QuoteLine__r.SBQQ__Quote__c IN :quoteIds AND SBQQ__QuoteLine__c != NULL
        ];

        if (!olis.isEmpty()) {
            processOliIdSync(olis);
        }
    }
}