trigger FWOpportunityLineItemTrigger on OpportunityLineItem (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        OpportunityLineItemTriggerHandler.syncOpportunityLineId(Trigger.new);
    }
}