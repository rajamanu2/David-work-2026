global class setCustomModifyDate implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts {

    String Query;

    global Database.QueryLocator start(Database.BatchableContext bc) {

        Query = 'Select Id,LastModifiedDate,date_move_completed__c,date_review_status_completed__c from ProductItem__c';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<ProductItem__c> pItemlist) {
        List<ProductItem__c> pItemsToUpdate = new List<ProductItem__c> ();
        for (ProductItem__c pi : pItemlist) {
            boolean changed = false;

            if (pi.date_move_completed__c == null) {
                pi.date_move_completed__c = pi.LastModifiedDate;
                changed = true;
            }

            if (pi.date_review_status_completed__c == null) {
                pi.date_review_status_completed__c = pi.LastModifiedDate;
                changed = true;
            }

            if (changed){
                pItemsToUpdate.add(pi);
            }
        }

        if (!pItemsToUpdate.isEmpty()){
            update pItemsToUpdate;
        }
    }

    global void execute(SchedulableContext sc) {
        setCustomModifyDate bc = new setCustomModifyDate();

        database.executebatch(bc, 10);
    }

    global void finish(Database.BatchableContext bc) {
        system.debug('This method is required by the interface.');
    }
}