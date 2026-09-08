trigger MoveLocationUpdate on Move_Location__c (after insert, after update) {

    // SOQL, DML, hardcoded are fixed - Deployed to devint
    List<ProductItem__c> productItemList = new List<ProductItem__c>();

    // This updates the location and date move completed fields on the asset page from the move location.
    // The location field is locked so it forces everyone to use the move location custom object which allows 
    // more of an audit trail where the person moving can add notes about the move.
    for (Move_Location__c ml : Trigger.new) {

        if (ml.ProductItem__c != null){

            ProductItem__c thisItem = new ProductItem__c(Id = ml.ProductItem__c);
            if(ml.New_Location__c != NULL){
                thisItem.Location__c = ml.New_Location__c;
            }
            if(ml.New_Sub_Location__c != NULL){
                thisItem.Sub_Location__c = ml.New_Sub_Location__c;
            }
            if(ml.new_UK_Location__c != NULL){
            	thisItem.ProboUK_Location__c = ml.New_UK_Location__c;
            }
            if(ml.New_Location_Formula__c != NULL){
                thisItem.Current_Location__c = ml.New_Location_Formula__c;
            }
            thisItem.date_move_completed__c = ml.Date_Move_Completed__c;
            
            productItemList.add(thisItem);
        }
    }


    System.debug('Updating this many pItems: ' + productItemList.size());
    if (!productItemList.isEmpty()){update productItemList;}
}