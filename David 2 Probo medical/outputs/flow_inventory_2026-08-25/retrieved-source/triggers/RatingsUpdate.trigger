trigger RatingsUpdate on Ratings__c (after insert, after update) {

    // SOQL, DML, hardcoded are fixed - Deployed to devint

    // Changes fields on asset page when rating (a custom object) is changed. This is locked down on the asset page
    // so notes are required to explain why the rating is being changed.

    List<ProductItem__c> pItemsToUpdate = new List<ProductItem__c>();

    for (Ratings__c r : trigger.new) {

        if (r.Asset__c != null){

            ProductItem__c item = new ProductItem__c(Id = r.Asset__c);

            if (r.Cosmetic_or_Functional_Change__c == 'Cosmetic Rating') {
                item.Cosmetic_Rating__c = r.New_Rating__c;
            }
            if (r.Cosmetic_or_Functional_Change__c == 'Functional Rating') {
                item.Functional_Rating__c = r.New_Rating__c;
            }

            pItemsToUpdate.add(item);
        }
    }

    system.debug('Have this many pItems to Update: ' + pItemsToUpdate.size());
    if (!pItemsToUpdate.isEmpty()){update pItemsToUpdate;}
}