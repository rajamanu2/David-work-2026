/**
 * @description SALDEV-1467 / SALDEV-1499: Triggers on OpportunityLineItem after insert to 
 * synchronize Opportunity_Line_Id__c onto parent SBQQ__QuoteLine__c records safely.
 */
trigger FWOpportunityLineItemTrigger on OpportunityLineItem (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        // SALDEV-1467: Synchronizes OLI Auto ID to Opportunity_Line_Id__c on parent Quote Lines
        OpportunityLineItemTriggerHandler.processOliIdSync(Trigger.new);
    }
}