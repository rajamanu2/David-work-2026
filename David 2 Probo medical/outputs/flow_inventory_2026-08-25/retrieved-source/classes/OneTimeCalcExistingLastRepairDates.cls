global without sharing class OneTimeCalcExistingLastRepairDates implements Database.Batchable<sObject> {

    /* This is a 1-time only apex class to cause existing records to update ProductItem__c.Last_Repair__c fields
 */

    public String str_SOQL = 'SELECT Id, Product_Item__c, Repair_date__c FROM Product_Repair__c WHERE Product_Item__c != NULL AND Repair_date__c != NULL ORDER BY Product_Item__c';

    global OneTimeCalcExistingLastRepairDates() {
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(str_SOQL);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {

        Set<Id> pItemsToRecalcDates = new Set<Id>();

        for (Product_Repair__c pr : (List<Product_Repair__c>)scope) {
            pItemsToRecalcDates.add(pr.Product_Item__c);
        }

        calcProductItemLastRepairDates(pItemsToRecalcDates);
    }


    global void finish(Database.BatchableContext BC) {
    }

    private void calcProductItemLastRepairDates(Set<Id> pItemIds) {

        //  For each ProductItem__c record, find the most recent Repair_Date__c for child ProductRepair__c records

        GH_Logger.debug('Start of calcProductItemLastRepairDates()');

        if (pItemIds != null && !pItemIds.isEmpty()) {
            GH_Logger.debug('have pItemIDs to process: ' + pItemIds);

            Map<Id, Datetime> pItemToRepairDate = new Map<Id, Datetime>();

            GH_Logger.debug('init to null in case there are no more Product_Repairs__c on this ProductItem__c');
            for (Id thisPItemId : pItemIds) {
                pItemToRepairDate.put(thisPItemId, null);
            }

            for (Product_Repair__c pr : [
                    SELECT Id, Repair_date__c, Product_Item__c
                    FROM Product_Repair__c
                    WHERE Product_Item__c IN :pItemToRepairDate.keySet()
                    AND Repair_date__c != NULL
                    ORDER BY Repair_date__c DESC
            ]) {

                // only set the date for the most recent value
                if (pItemToRepairDate.get(pr.Product_Item__c) == null) {
                    pItemToRepairDate.put(pr.Product_Item__c, pr.Repair_date__c);
                }
            }

            List<ProductItem__c> pItemsToUpdate = new List<ProductItem__c>();
            for (Id pItemID : pItemToRepairDate.keySet()) {
                pItemsToUpdate.add(new ProductItem__c(Id = pItemID, Last_Repair__c = pItemToRepairDate.get(pItemId)));
            }

            DatabaseService.updateList(pItemsToUpdate);
        }
        GH_Logger.debug('End of calcProductItemLastRepairDates()');
    }

}