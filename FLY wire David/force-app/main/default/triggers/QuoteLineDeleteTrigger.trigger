trigger QuoteLineDeleteTrigger on SBQQ__QuoteLine__c (after delete) {
    QuoteLineDeleteHandler.resetPriceChangeOnSource(Trigger.old);
}