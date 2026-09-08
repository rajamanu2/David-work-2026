public class P_ProductItemDeleteHandler {
	// This prevents anyone from deleting an asset.
    public void checkDeletes(Map<Id, ProductItem__c> oldRecs) {
        for (ProductItem__c asset : oldRecs.values()) {
            asset.addError('You can not delete an asset.');
            
        }
    }

}