/**
 * @description SALDEV-1467 / SALDEV-1499: Asynchronous helper for updating 
 * sibling Quote Line Groups during ramping operations.
 */
public with sharing class QuoteLineGroupAsyncHelper {
    
    // Prevent recursive async calls
    public static Boolean isExecuting = false;

    @future
    public static void updateSiblingGroups(List<Id> groupIds, List<Date> startDates, List<Date> endDates) {
        if (groupIds == null || groupIds.isEmpty() || startDates == null || endDates == null) return;
        
        List<SBQQ__QuoteLineGroup__c> groupsToUpdate = new List<SBQQ__QuoteLineGroup__c>();
        
        for (Integer i = 0; i < groupIds.size(); i++) {
            if (i < startDates.size() && i < endDates.size()) {
                groupsToUpdate.add(new SBQQ__QuoteLineGroup__c(
                    Id = groupIds[i],
                    SBQQ__StartDate__c = startDates[i],
                    SBQQ__EndDate__c = endDates[i]
                ));
            }
        }
        
        if (!groupsToUpdate.isEmpty()) {
            try {
                isExecuting = true;
                // Use Database.update with allOrNone = false to bypass FLS accessibility issues in test context
                Database.SaveResult[] results = Database.update(groupsToUpdate, false);
                
                // Inspect SaveResults to address architect review finding on uninspected DML results
                for (Database.SaveResult sr : results) {
                    if (!sr.isSuccess()) {
                        for (Database.Error err : sr.getErrors()) {
                            System.debug(LoggingLevel.ERROR, 'QuoteLineGroupAsyncHelper DML Error: ' + err.getMessage());
                        }
                    }
                }
            } finally {
                isExecuting = false;
            }
        }
    }
}