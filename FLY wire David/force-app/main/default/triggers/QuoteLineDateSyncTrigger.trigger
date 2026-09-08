trigger QuoteLineDateSyncTrigger on SBQQ__QuoteLine__c (before insert, before update) {
    Set<Id> groupIds = new Set<Id>();

    for (SBQQ__QuoteLine__c line : Trigger.new) {
        if (line.SBQQ__Group__c != null) {
            groupIds.add(line.SBQQ__Group__c);
        }
    }

    if (groupIds.isEmpty()) return;

    Map<Id, SBQQ__QuoteLineGroup__c> groupMap = new Map<Id, SBQQ__QuoteLineGroup__c>(
        [SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__SubscriptionTerm__c FROM SBQQ__QuoteLineGroup__c WHERE Id IN :groupIds]
    );

    for (SBQQ__QuoteLine__c line : Trigger.new) {
        if (line.SBQQ__Group__c != null && groupMap.containsKey(line.SBQQ__Group__c)) {
            SBQQ__QuoteLineGroup__c parentGroup = groupMap.get(line.SBQQ__Group__c);
            
            line.SBQQ__StartDate__c = parentGroup.SBQQ__StartDate__c;
            line.SBQQ__EndDate__c = parentGroup.SBQQ__EndDate__c;
            line.SBQQ__SubscriptionTerm__c = parentGroup.SBQQ__SubscriptionTerm__c;
        }
    }
}