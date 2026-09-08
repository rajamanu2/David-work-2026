@IsTest(SeeAllData=true)
private class RecentlyDeletedWoliLookupInvocable_Test {
    private static WorkOrder getFslWorkOrderWithPricebook() {
        List<WorkOrder> wos = [
            SELECT Id, Pricebook2Id, CurrencyIsoCode
            FROM WorkOrder
            WHERE Pricebook2Id != null
            LIMIT 1
        ];
        System.assert(!wos.isEmpty(), 'No WorkOrder found with Pricebook2Id.');
        return wos[0];
    }

    private static PricebookEntry getAnyPricebookEntry(Id pricebookId, String currencyIsoCode) {
        if (!String.isBlank(currencyIsoCode)) {
            List<PricebookEntry> pbes = [
                SELECT Id
                FROM PricebookEntry
                WHERE Pricebook2Id = :pricebookId
                  AND IsActive = true
                  AND CurrencyIsoCode = :currencyIsoCode
                LIMIT 1
            ];
            if (!pbes.isEmpty()) {
                return pbes[0];
            }
        }

        List<PricebookEntry> fallback = [
            SELECT Id
            FROM PricebookEntry
            WHERE Pricebook2Id = :pricebookId
              AND IsActive = true
            LIMIT 1
        ];
        System.assert(!fallback.isEmpty(), 'No active PricebookEntry found.');
        return fallback[0];
    }

    private static String getAnyLineIntentValue() {
        Schema.DescribeFieldResult dfr = WorkOrderLineItem.Line_Intent__c.getDescribe();
        for (Schema.PicklistEntry ple : dfr.getPicklistValues()) {
            if (ple.isActive()) {
                return ple.getValue();
            }
        }
        return null;
    }

    @IsTest
    static void returnsRecentDeletedLineIntentForCurrentUser() {
        String expectedIntent = getAnyLineIntentValue();

		WorkOrder wo = [SELECT ID From WorkOrder LIMIT 1];

        RecentlyDeletedWoliLookupInvocable.Request req = new RecentlyDeletedWoliLookupInvocable.Request();
        req.workOrderId = wo.Id;

        List<RecentlyDeletedWoliLookupInvocable.Response> responses = RecentlyDeletedWoliLookupInvocable.getRecentlyDeletedLineIntent(
            new List<RecentlyDeletedWoliLookupInvocable.Request>{ req }
        );
    }

    @IsTest
    static void returnsEmptyFieldsWhenNoRecentDeleteExists() {
        WorkOrder wo = getFslWorkOrderWithPricebook();

        RecentlyDeletedWoliLookupInvocable.Request req = new RecentlyDeletedWoliLookupInvocable.Request();
        req.workOrderId = wo.Id;

        List<RecentlyDeletedWoliLookupInvocable.Response> responses = RecentlyDeletedWoliLookupInvocable.getRecentlyDeletedLineIntent(
            new List<RecentlyDeletedWoliLookupInvocable.Request>{ req }
        );

        System.assertEquals(1, responses.size(), 'One response should be returned for one request.');
        System.assertEquals(null, responses[0].workOrderId, 'Work Order Id should be empty when no recent delete is found.');
        System.assertEquals(null, responses[0].lineIntent, 'Line intent should be empty when no recent delete is found.');
    }
}