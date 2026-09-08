public class P_RMADeleteHandler {
	// This prevents anyone from deleting an RMA that has an item received date filled in.
    public void checkDeletes(Map<Id, RMA__c> oldRecs) {
        for (RMA__c checkRMA : oldRecs.values()) {
            if (checkRMA.Date_RMA_Item_Received__c != null) {
                checkRMA.addError('You can not delete this RMA !');
            }
        }
    }
}