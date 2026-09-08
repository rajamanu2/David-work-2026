@isTest
private class QuoteLineGroupAsyncHelperTest {

    @isTest
    static void testUpdateSiblingGroupsAsync() {
        // Create Account & Opportunity
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

        // Create Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__SubscriptionTerm__c = 24
        );
        insert quote;

        // Create Quote Line Group
        SBQQ__QuoteLineGroup__c group1 = new SBQQ__QuoteLineGroup__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Number__c = 1,
            Allow_Product_Ramping__c = true,
            SBQQ__SubscriptionTerm__c = 12
        );
        insert group1;

        List<Id> groupIds = new List<Id>{ group1.Id };
        List<Date> startDates = new List<Date>{ Date.today() };
        List<Date> endDates = new List<Date>{ Date.today().addMonths(12).addDays(-1) };

        // Test Async Helper Execution
        Test.startTest();
        QuoteLineGroupAsyncHelper.updateSiblingGroups(groupIds, startDates, endDates);
        Test.stopTest(); // Flushes @future calls

        // Verify updates applied asynchronously
        SBQQ__QuoteLineGroup__c updatedGroup = [
            SELECT SBQQ__StartDate__c, SBQQ__EndDate__c 
            FROM SBQQ__QuoteLineGroup__c 
            WHERE Id = :group1.Id
        ];
        
        System.assertEquals(startDates[0], updatedGroup.SBQQ__StartDate__c, 'Start Date should match async update.');
        System.assertEquals(endDates[0], updatedGroup.SBQQ__EndDate__c, 'End Date should match async update.');
    }
}