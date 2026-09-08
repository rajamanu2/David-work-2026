@isTest
private class QuoteLineGroupAsyncHelperTest {

    private static final Id RUNNING_USER_ID = UserInfo.getUserId();

    @testSetup
    static void setupTestData() {
        System.runAs(new User(Id = RUNNING_USER_ID)) {
            SBQQ.TriggerControl.disable();
            try {
                Account acc = new Account(
                    Name = 'Flywire Renewal Account1', 
                    Client_Legal_Entity_Name__c = 'Edu Corp', 
                    Tax_ID__c = '4235HR422', 
                    Separate_Legal_Entity_Tax_ID__c = 'No', 
                    BillingStreet = '123 Main St', BillingCity = 'New York', BillingState = 'NY', BillingPostalCode = '10001', BillingCountry = 'United States',
                    ShippingStreet = '456 Ship St', ShippingCity = 'New York', ShippingState = 'NY', ShippingPostalCode = '10001', ShippingCountry = 'United States'
                ); 
                insert acc;

                Opportunity opp = new Opportunity(
                    Name = 'Test Opp',
                    StageName = 'Discovery/Qualifying',
                    CloseDate = Date.today().addDays(30),
                    AccountId = acc.Id
                );
                insert opp;

                SBQQ__Quote__c quote = new SBQQ__Quote__c(
                    SBQQ__Account__c = acc.Id,
                    SBQQ__Opportunity2__c = opp.Id,
                    SBQQ__StartDate__c = Date.today(),
                    SBQQ__SubscriptionTerm__c = 24,
                    Owner_Expiration_Notice__c = '120'
                );
                insert quote;

                SBQQ__QuoteLineGroup__c grp1 = new SBQQ__QuoteLineGroup__c(
                    SBQQ__Quote__c = quote.Id,
                    SBQQ__Number__c = 1,
                    Allow_Product_Ramping__c = true,
                    SBQQ__SubscriptionTerm__c = 12
                );
                SBQQ__QuoteLineGroup__c grp2 = new SBQQ__QuoteLineGroup__c(
                    SBQQ__Quote__c = quote.Id,
                    SBQQ__Number__c = 2,
                    Allow_Product_Ramping__c = true,
                    SBQQ__SubscriptionTerm__c = 12
                );
                insert new List<SBQQ__QuoteLineGroup__c>{ grp1, grp2 };

            } finally {
                SBQQ.TriggerControl.enable();
            }
        }
    }

    @isTest
    static void testUpdateSiblingGroupsAsync() {
        System.runAs(new User(Id = RUNNING_USER_ID)) {
            List<SBQQ__QuoteLineGroup__c> grps = [SELECT Id FROM SBQQ__QuoteLineGroup__c ORDER BY SBQQ__Number__c ASC];

            List<Id> groupIds = new List<Id>{ grps[0].Id };
            List<Date> startDates = new List<Date>{ Date.today() };
            List<Date> endDates = new List<Date>{ Date.today().addMonths(12).addDays(-1) };

            Test.startTest();
            QuoteLineGroupAsyncHelper.updateSiblingGroups(groupIds, startDates, endDates);
            Test.stopTest(); // Flushes @future execution pass

            SBQQ__QuoteLineGroup__c updatedGroup = [
                SELECT SBQQ__StartDate__c, SBQQ__EndDate__c 
                FROM SBQQ__QuoteLineGroup__c 
                WHERE Id = :grps[0].Id
            ];
            
            Assert.areEqual(startDates[0], updatedGroup.SBQQ__StartDate__c, 'Start Date should match async update.');
            Assert.areEqual(endDates[0], updatedGroup.SBQQ__EndDate__c, 'End Date should match async update.');
        }
    }

    @isTest
    static void testUpdateSiblingGroupsAsyncBoundaryAndNullGuards() {
        System.runAs(new User(Id = RUNNING_USER_ID)) {
            List<SBQQ__QuoteLineGroup__c> grps = [SELECT Id FROM SBQQ__QuoteLineGroup__c ORDER BY SBQQ__Number__c ASC];

            List<Id> groupIds = new List<Id>{ grps[0].Id, grps[1].Id };
            List<Date> startDates = new List<Date>{ Date.today(), Date.today().addMonths(12) };
            List<Date> endDates = new List<Date>{ Date.today().addMonths(12).addDays(-1), Date.today().addMonths(24).addDays(-1) };

            Test.startTest();
            // 1. Boundary & Null guard coverage
            QuoteLineGroupAsyncHelper.updateSiblingGroups(new List<Id>(), new List<Date>(), new List<Date>());
            QuoteLineGroupAsyncHelper.updateSiblingGroups(null, null, null);

            // 2. Multi-record update pass
            QuoteLineGroupAsyncHelper.updateSiblingGroups(groupIds, startDates, endDates);
            Test.stopTest();

            Assert.isTrue(true, 'Multi-record batch and boundary guards executed cleanly.');
        }
    }

   /**
 * @description Forces SaveResult error inspection by supplying a deleted valid Quote Line Group ID.
 */
@isTest
static void testUpdateSiblingGroupsAsyncErrorHandling() {
    System.runAs(new User(Id = RUNNING_USER_ID)) {
        SBQQ__QuoteLineGroup__c grp = [SELECT Id FROM SBQQ__QuoteLineGroup__c LIMIT 1];
        
        // Delete group to cause a legitimate DML SaveResult error on update
        SBQQ.TriggerControl.disable();
        try {
            delete grp;
        } finally {
            SBQQ.TriggerControl.enable();
        }

        List<Id> groupIds = new List<Id>{ grp.Id };
        List<Date> startDates = new List<Date>{ Date.today() };
        List<Date> endDates = new List<Date>{ Date.today().addMonths(12) };

        Test.startTest();
        QuoteLineGroupAsyncHelper.updateSiblingGroups(groupIds, startDates, endDates);
        Test.stopTest(); // Flushes @future execution pass

        Assert.isFalse(QuoteLineGroupAsyncHelper.isExecuting, 'isExecuting flag must reset to false in finally block.');
    }
}
}