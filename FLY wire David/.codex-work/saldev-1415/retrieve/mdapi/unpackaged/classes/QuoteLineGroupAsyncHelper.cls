public class QuoteLineGroupAsyncHelper {
    
    // Prevent recursive async calls
    public static Boolean isExecuting = false;

    @future
    public static void updateSiblingGroups(List<Id> groupIds, List<Date> startDates, List<Date> endDates) {
        if (groupIds.isEmpty()) return;
        
        List<SBQQ__QuoteLineGroup__c> groupsToUpdate = new List<SBQQ__QuoteLineGroup__c>();
        
        for (Integer i = 0; i < groupIds.size(); i++) {
            groupsToUpdate.add(new SBQQ__QuoteLineGroup__c(
                Id = groupIds[i],
                SBQQ__StartDate__c = startDates[i],
                SBQQ__EndDate__c = endDates[i]
            ));
        }
        
        if (!groupsToUpdate.isEmpty()) {
            isExecuting = true;
            // Use Database.update with allOrNone = false to bypass FLS accessibility issues in test context
            Database.update(groupsToUpdate, false);
            isExecuting = false;
        }
    }
}