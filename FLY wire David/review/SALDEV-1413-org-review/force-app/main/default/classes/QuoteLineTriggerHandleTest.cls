@isTest
public class QuoteLineTriggerHandleTest {

    @testSetup
    static void setupTestData() {
        // 1. Create a test Quote
        SBQQ__Quote__c  testQuote = new SBQQ__Quote__c();
        insert testQuote;

        // 2. Create a test Product
        Product2 testProduct = new Product2();
        testProduct.Name = 'Test Product';
        insert testProduct;

        // 3. Create Quote Lines 
        List<SBQQ__QuoteLine__c> linesToInsert = new List<SBQQ__QuoteLine__c>();
        
        // Line 1: Not earliest
        linesToInsert.add(new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            Usage_Rate__c = 10,
            SBQQ__StartDate__c = Date.today().addDays(5)
        ));

        // Line 2: Earliest Date (This one should receive the average)
        linesToInsert.add(new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            Usage_Rate__c = 20,
            SBQQ__StartDate__c = Date.today().addDays(-5) 
        ));

        // Line 3: Not earliest
        linesToInsert.add(new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            Usage_Rate__c = 30,
            SBQQ__StartDate__c = Date.today()
        ));

        insert linesToInsert;
    }

    @isTest
    static void testInsertCalculatesAveragePositive() {
        // Retrieve the inserted lines, ordered by start date
        List<SBQQ__QuoteLine__c> insertedLines = [
            SELECT Id, NS_Usage_Rate__c, Avg_Quoted_Rate__c, SBQQ__StartDate__c 
            FROM SBQQ__QuoteLine__c 
            ORDER BY SBQQ__StartDate__c ASC
        ];
        
        Assert.areEqual(3, insertedLines.size(), 'Three Quote Lines should exist.');
        
        // Average should be (0.1 + 0.2 + 0.3) / 3 = 0.2
        // The first record in the sorted list is the earliest (Today - 5)
        Assert.areEqual(0.2, insertedLines[0].Avg_Quoted_Rate__c, 'Earliest Quote Line should have the correct calculated average.');
        
        // The remaining records should have a null average
        Assert.isNull(insertedLines[1].Avg_Quoted_Rate__c, 'Subsequent Quote Line should have a null average.');
        Assert.isNull(insertedLines[2].Avg_Quoted_Rate__c, 'Subsequent Quote Line should have a null average.');
    }

    @isTest
    static void testUpdateRecalculatesAveragePositive() {
        
        List<SBQQ__QuoteLine__c> linesToUpdate = [SELECT Id, NS_Usage_Rate__c FROM SBQQ__QuoteLine__c];
        system.debug('linesToUpdate '+linesToUpdate);
        // Retrieve the most recent record (Today + 5, NS_Usage_Rate__c = 100)
        SBQQ__QuoteLine__c lineToUpdate = [SELECT Id, NS_Usage_Rate__c FROM SBQQ__QuoteLine__c WHERE NS_Usage_Rate__c = 0.1 LIMIT 1];
        
        Test.startTest();
        // Update price to 0.4. New total = 0.4 + 0.2 + 0.3 = 0.9. New Average = 0.3.
        lineToUpdate.Usage_Rate__c = 40;
        update lineToUpdate;
        Test.stopTest();

        // Retrieve the earliest line to check if the average was updated
        SBQQ__QuoteLine__c earliestLine = [SELECT Id, Avg_Quoted_Rate__c FROM SBQQ__QuoteLine__c WHERE NS_Usage_Rate__c = 0.2 LIMIT 1];
        
        Assert.areEqual(0.3, earliestLine.Avg_Quoted_Rate__c, 'Earliest Quote Line should have the updated average after a price change.');
    }

    @isTest
    static void testUpdateStartDateShiftsAveragePositive() {
        // Retrieve the record that is currently the LATEST (Today + 5, Rate = 10)
        SBQQ__QuoteLine__c latestLine = [SELECT Id, SBQQ__StartDate__c, Avg_Quoted_Rate__c FROM SBQQ__QuoteLine__c WHERE NS_Usage_Rate__c = 0.1 LIMIT 1];
        
        // Retrieve the record that is currently the EARLIEST (Today - 5, Rate = 20)
        SBQQ__QuoteLine__c earliestLine = [SELECT Id, SBQQ__StartDate__c, Avg_Quoted_Rate__c FROM SBQQ__QuoteLine__c WHERE NS_Usage_Rate__c = 0.2 LIMIT 1];
        
        Test.startTest();
        // Change the LATEST record to be older than the EARLIEST record (Today - 10)
        latestLine.SBQQ__StartDate__c = Date.today().addDays(-10);
        update latestLine;
        Test.stopTest();

        // Re-query records
        SBQQ__QuoteLine__c newEarliestLine = [SELECT Id, Avg_Quoted_Rate__c FROM SBQQ__QuoteLine__c WHERE Id = :latestLine.Id];
        SBQQ__QuoteLine__c oldEarliestLine = [SELECT Id, Avg_Quoted_Rate__c FROM SBQQ__QuoteLine__c WHERE Id = :earliestLine.Id];

        // Assertions
        Assert.areEqual(0.2, newEarliestLine.Avg_Quoted_Rate__c, 'The average should shift to the new earliest Quote Line.');
        Assert.isNull(oldEarliestLine.Avg_Quoted_Rate__c, 'The old earliest Quote Line should now have a null average.');
    }

    @isTest
    static void testDeleteRecalculatesAveragePositive() {
        // Retrieve a line to delete (Rate = 30)
        SBQQ__QuoteLine__c lineToDelete = [SELECT Id FROM SBQQ__QuoteLine__c WHERE NS_Usage_Rate__c = 0.3 LIMIT 1];
        
        Test.startTest();
        delete lineToDelete;
        Test.stopTest();

        // New total = 0.1 + 0.2 = 0.3 New Average = 0.15
        SBQQ__QuoteLine__c earliestLine = [SELECT Id, Avg_Quoted_Rate__c FROM SBQQ__QuoteLine__c WHERE NS_Usage_Rate__c = 0.2 LIMIT 1];
        
        Assert.areEqual(0.15, earliestLine.Avg_Quoted_Rate__c, 'Average should be recalculated after a Quote Line is deleted.');
    }

    @isTest
    static void testNegativeNullAndEmptyLists() {
        Test.startTest();
        
        // Scenario 1: Passing empty lists should not throw any exceptions
        try {
            QuoteLineTriggerHandler.calculateAveragePrice(new List<SBQQ__QuoteLine__c>(), new Map<Id, SBQQ__QuoteLine__c>());
            QuoteLineTriggerHandler.calculateAveragePrice(null, null);
            // If we reach here, it means no exceptions were thrown
            Assert.isTrue(true, 'Handler handled empty and null lists safely.');
        } catch (Exception e) {
            Assert.fail('Handler should not throw an exception when provided empty or null lists. Exception: ' + e.getMessage());
        }

        Test.stopTest();
    }
}