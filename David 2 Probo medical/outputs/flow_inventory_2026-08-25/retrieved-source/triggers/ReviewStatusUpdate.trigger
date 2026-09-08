trigger ReviewStatusUpdate on Review_Status__c (after insert, after update) {
    if(!Validator_Class.ByPassReviewTrigger()) {
        System.debug('start of ReviewStatusUpdate trigger');

        Set<Id> pItemIds = new Set<Id>();
    
        for (Review_Status__c rs : Trigger.new) {
            if (rs.ProductItem__c != null){
                pItemIds.add(rs.ProductItem__c);
            }
        }
    
        Map<Id, List<Review_Status__c>> pItemToRevStatusList = new Map<Id, List<Review_Status__c>>();
        Map<Id, ProductItem__c> pItemIdToProductItem = new Map<Id, ProductItem__c>();
    
        if (!pItemIds.isEmpty()){
    
            // get all the Review_Status records for these ProductItems so the ProductItem can be updated if needed
            for (Review_Status__c r : [SELECT Id, Notes__c, CreatedDate, ProductItem__c
                                        FROM Review_Status__c
                                        WHERE ProductItem__c IN :pItemIds
                                        ORDER BY CreatedDate DESC]){
    
                if (!pItemToRevStatusList.containsKey(r.ProductItem__c)){
                    pItemToRevStatusList.put(r.ProductItem__c, new  List<Review_Status__c>());
                }
                pItemToRevStatusList.get(r.ProductItem__c).add(r);
            }
    
            for (ProductItem__c r : [SELECT Id, Review_Status__c, Last_Review_Status_Update__c, date_move_completed__c,
                                        date_review_status_completed__c,Days_in_current_location__c, Most_Recent_Review_Status_Notes__c,
                                        Review_Status_Notes__c, Functional_Repair_Queue_Obstacles__c, Parts_to_Harvest__c
                                        FROM ProductItem__c
                                        WHERE Id IN :pItemIds]){
    
                pItemIdToProductItem.put(r.Id, r);
            }
        }
    
        List<ProductItem__c> pItemsToUpdate = new List<ProductItem__c>();
    
        // Updates fields on asset page based on change in review status (a custom object to better track changes
        // and to write notes explaining the change)
        for (Review_Status__c rs : Trigger.new) {
    
            Id pItemID = rs.ProductItem__c;
            String tempReviewNotes = '';
    
            if (pItemID != null && pItemToRevStatusList.containsKey(pItemID)){
    
                for (Review_Status__c ppr : pItemToRevStatusList.get(pItemID)) {
                    if (ppr.Notes__c != null) {
                        tempReviewNotes = tempReviewNotes + ppr.Notes__c + ' ' + String.valueOf(ppr.CreatedDate.date()) + '; ';
                    }
                }
            }
    
            ProductItem__c productItemRecord;
    
            if (pItemID != null && pItemIdToProductItem.containsKey(rs.ProductItem__c)){
                productItemRecord = pItemIdToProductItem.get(rs.ProductItem__c);
            }
    
            if (productItemRecord != null) {
                Boolean pItemChanged = false;
    
                if (productItemRecord.Review_Status__c != rs.New_Review_Status__c){
                productItemRecord.Review_Status__c = rs.New_Review_Status__c;
                    pItemChanged = true;
                }
    
                if (productItemRecord.Last_Review_Status_Update__c != rs.Date_Review_Status_Completed__c.date()){
                    productItemRecord.Last_Review_Status_Update__c = rs.Date_Review_Status_Completed__c.date();
                    pItemChanged = true;
                }
    
                if (productItemRecord.date_review_status_completed__c != rs.Date_Review_Status_Completed__c){
                productItemRecord.date_review_status_completed__c = rs.Date_Review_Status_Completed__c;
                    pItemChanged = true;
                }
    
                if (productItemRecord.Review_Status_Notes__c != tempReviewNotes){
                productItemRecord.Review_Status_Notes__c = tempReviewNotes;
                    pItemChanged = true;
                }
    
                if (rs.Notes__c != null && productItemRecord.Most_Recent_Review_Status_Notes__c != rs.Notes__c) {
                    productItemRecord.Most_Recent_Review_Status_Notes__c = rs.Notes__c;
                    pItemChanged = true;
                }
    
                if (productItemRecord.Functional_Repair_Queue_Obstacles__c != rs.Functional_Repair_Queue_Obstacles__c){
                productItemRecord.Functional_Repair_Queue_Obstacles__c = rs.Functional_Repair_Queue_Obstacles__c;
                    pItemChanged = true;
                }
    
                if (productItemRecord.Parts_to_Harvest__c != rs.Parts_to_Harvest__c){
                productItemRecord.Parts_to_Harvest__c = rs.Parts_to_Harvest__c;
                    pItemChanged = true;
                }
    
                if (pItemChanged){
                    System.debug('Review Status Product Item to Update: ' + productItemRecord);
                pItemsToUpdate.add(productItemRecord);
                } else {
                    System.debug('Review Status Product Item does not need to be updated');
                }
            }
        }
    
        System.debug('Updating this many PItems: ' + pItemsToUpdate.size());
        if (!pItemsToUpdate.isEmpty()){
            update pItemsToUpdate;
        }
    
    }

    System.debug('end of ReviewStatusUpdate trigger');

}