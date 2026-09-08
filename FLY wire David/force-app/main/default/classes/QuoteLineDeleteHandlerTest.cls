@IsTest
private class QuoteLineDeleteHandlerTest {

    @IsTest
    static void testResetPriceChangeOnSourceLine() {
        SBQQ.TriggerControl.disable();

        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        insert quote;

        SBQQ__QuoteLine__c sourceLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            Price_Change__c = true
        );
        insert sourceLine;

        SBQQ__QuoteLine__c clonedLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Source__c = sourceLine.Id
        );
        insert clonedLine;

        Test.startTest();
        delete clonedLine;
        Test.stopTest(); // Forces the Queueable to execute

        SBQQ__QuoteLine__c updatedSource = [
            SELECT Price_Change__c FROM SBQQ__QuoteLine__c WHERE Id = :sourceLine.Id
        ];
        System.assertEquals(false, updatedSource.Price_Change__c,
            'Price_Change__c should be reset to false when cloned line is deleted');
    }

    @IsTest
    static void testNoSourceLineDoesNothing() {
        SBQQ.TriggerControl.disable();

        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        insert quote;

        SBQQ__QuoteLine__c line = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id
        );
        insert line;

        Test.startTest();
        delete line;
        Test.stopTest();
    }
}