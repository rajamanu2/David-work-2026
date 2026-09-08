trigger QuoteLineGroupTrigger on SBQQ__QuoteLineGroup__c (before insert, before update) {
    Set<Id> quoteIds = new Set<Id>();
    
    for (SBQQ__QuoteLineGroup__c grp : Trigger.new) {
        if (grp.SBQQ__Quote__c != null) {
            quoteIds.add(grp.SBQQ__Quote__c);
        }
    }

    if (quoteIds.isEmpty()) return;

    // 1. Fetch parent Quotes to get Header Start and End Dates
    Map<Id, SBQQ__Quote__c> parentQuotes = new Map<Id, SBQQ__Quote__c>(
        [SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c FROM SBQQ__Quote__c WHERE Id IN :quoteIds]
    );

    // 2. Fetch ALL groups for these quotes ordered by Group Number
    List<SBQQ__QuoteLineGroup__c> allQuoteGroups = [
        SELECT Id, SBQQ__Quote__c, SBQQ__Number__c, Allow_Product_Ramping__c, 
               SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__SubscriptionTerm__c
        FROM SBQQ__QuoteLineGroup__c
        WHERE SBQQ__Quote__c IN :quoteIds
        ORDER BY SBQQ__Quote__c ASC, SBQQ__Number__c ASC
    ];

    // Group the records by Quote ID
    Map<Id, List<SBQQ__QuoteLineGroup__c>> quoteToGroupsMap = new Map<Id, List<SBQQ__QuoteLineGroup__c>>();
    for (SBQQ__QuoteLineGroup__c grp : allQuoteGroups) {
        // Overlay in-flight updates from Trigger.new into the queried list
        for (SBQQ__QuoteLineGroup__c newGrp : Trigger.new) {
            if (grp.Id != null && grp.Id == newGrp.Id) {
                grp.Allow_Product_Ramping__c = newGrp.Allow_Product_Ramping__c;
                grp.SBQQ__SubscriptionTerm__c = newGrp.SBQQ__SubscriptionTerm__c;
            }
        }

        if (!quoteToGroupsMap.containsKey(grp.SBQQ__Quote__c)) {
            quoteToGroupsMap.put(grp.SBQQ__Quote__c, new List<SBQQ__QuoteLineGroup__c>());
        }
        quoteToGroupsMap.get(grp.SBQQ__Quote__c).add(grp);
    }

    // Include newly inserted groups that don't have an ID yet
    for (SBQQ__QuoteLineGroup__c newGrp : Trigger.new) {
        if (newGrp.Id == null && newGrp.SBQQ__Quote__c != null) {
            if (!quoteToGroupsMap.containsKey(newGrp.SBQQ__Quote__c)) {
                quoteToGroupsMap.put(newGrp.SBQQ__Quote__c, new List<SBQQ__QuoteLineGroup__c>());
            }
            quoteToGroupsMap.get(newGrp.SBQQ__Quote__c).add(newGrp);
        }
    }

    // 3. Sequential Date Calculation Loop
    for (Id qId : quoteToGroupsMap.keySet()) {
        SBQQ__Quote__c parentQuote = parentQuotes.get(qId);
        if (parentQuote == null || parentQuote.SBQQ__StartDate__c == null) continue;

        Date quoteStartDate = parentQuote.SBQQ__StartDate__c;
        Date quoteEndDate = parentQuote.SBQQ__EndDate__c;
        Date previousRampedGroupEndDate = null;

        List<SBQQ__QuoteLineGroup__c> groupsForQuote = quoteToGroupsMap.get(qId);

        for (SBQQ__QuoteLineGroup__c grp : groupsForQuote) {
            Boolean isRamping = grp.Allow_Product_Ramping__c == true;

            if (isRamping) {
                // RAMPING GROUP LOGIC
                if (previousRampedGroupEndDate == null) {
                    // Group 1 (First Ramped Group) -> Quote Start Date
                    grp.SBQQ__StartDate__c = quoteStartDate;
                } else {
                    // Group 2+ -> Previous Ramped Group End Date + 1 Day
                    grp.SBQQ__StartDate__c = previousRampedGroupEndDate.addDays(1);
                }

                // Calculate End Date = Start Date + Term (Months) - 1 Day
                if (grp.SBQQ__StartDate__c != null && grp.SBQQ__SubscriptionTerm__c != null && grp.SBQQ__SubscriptionTerm__c > 0) {
                    Integer termMonths = grp.SBQQ__SubscriptionTerm__c.intValue();
                    grp.SBQQ__EndDate__c = grp.SBQQ__StartDate__c.addMonths(termMonths).addDays(-1);
                }

                if (grp.SBQQ__EndDate__c != null) {
                    previousRampedGroupEndDate = grp.SBQQ__EndDate__c;
                }
            } else {
                // UNRAMPED GROUP LOGIC -> Match Quote Header
                grp.SBQQ__StartDate__c = quoteStartDate;
                grp.SBQQ__EndDate__c = quoteEndDate;
            }
        }
    }
}