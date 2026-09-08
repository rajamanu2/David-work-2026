public class PurchasingReturnLineItemServices {
    public static Id replacementRecordTypeId = RecordTypeUtility.getRecordTypeByName('Purchasing_Return__c', 'Replacement');
    public static Id returnToVendorRecordTypeId = RecordTypeUtility.getRecordTypeByName('Purchasing_Return__c', 'Return to Vendor');
    public static Id vendorWarrantyClaimRecordTypeId = RecordTypeUtility.getRecordTypeByName('Purchasing_Return__c', 'Vendor Warranty Claim');

    @AuraEnabled
    public static Object createPurchasingReturnLineItems(List<Object> selectedItems, String opportunityId, String recordTypeId) {
        system.debug('#### calling createPurchasingReturnLineItems method.');
        system.debug('#### item list: ' +selectedItems);
        String statusMessage;
        Opportunity opp;
        Purchasing_Return__c pr;
        Id pbId;
        Map<String, String> resultMap = new Map<String, String>();
        List<ProductItem__c> listSelectedLineItems = new List<ProductItem__c>();
        Set<Id> setSelectedLineItemIds = new Set<Id>();
        List<ProductItem__c> listProductItemsToUpdate = new List<ProductItem__c>();
        List<ProductItem__c> listProductItemsSoldUpdate = new List<ProductItem__c>();
        
        if (selectedItems != null && opportunityId != null ) {
            opp = [SELECT Id, Name, StageName, RecordTypeId, AccountId, Account.Name FROM Opportunity WHERE Id =: opportunityId];
        	system.debug('#### opp: ' + opp);
            pr =  new Purchasing_Return__c(Opportunity__c=opp.Id, RecordTypeId=recordTypeId);
            
            try {
                insert pr;
                resultMap.put('purchasingReturnId', pr.Id);
            } catch (Exception e) {
                system.debug('#### Error occurred while inserting Item Receipt: ' + e.getMessage());
                statusMessage = 'Error occurred while inserting Item Receipt';
                resultMap.put('status', statusMessage);
                return resultMap;
            }
            
            listSelectedLineItems = (List<ProductItem__c>)JSON.deserialize(JSON.serialize(selectedItems), List<ProductItem__c>.class);
            for (ProductItem__c p: listSelectedLineItems) {
                setSelectedLineItemIds.add(p.Id);
            }
            
            if (!setSelectedLineItemIds.isEmpty() && pr != null) {
                for (ProductItem__c p: [SELECT Id, Cost__c, RecordTypeId, Sold__c, Purchasing_Return__c 
                                         FROM ProductItem__c WHERE Id IN: setSelectedLineItemIds]) {
                    //if (recordTypeId == replacementRecordTypeId) {
                    //    p.Cost__c = 0;      
                    //}    
                	
                    p.Purchasing_Return__c =  pr.Id;
                    listProductItemsToUpdate.add(p);                        
            	}
                
            }
            
            if (!listProductItemsToUpdate.isEmpty()) {
                system.debug('#### number of Purchasing Return Line Items: ' + listProductItemsToUpdate.size());
                try {
                    update listProductItemsToUpdate;
                    
                    if (recordTypeId == replacementRecordTypeId  || recordTypeId == returnToVendorRecordTypeId) {
                        for (ProductItem__c p: listProductItemsToUpdate) {
                            p.Sold__c = true;
                        } 
                        
                        // Update to mark the Product Items as sold is done separately due to validation rules
                        update listProductItemsToUpdate;
                    }    
                    statusMessage = 'success';
                    resultMap.put('status', statusMessage);
                } catch (Exception e) {
                    system.debug('#### Error occurred while updating Product Items: ' + e.getMessage());
                    statusMessage = 'Error occurred while updating Product Items';
                    resultMap.put('status', statusMessage);
                    return resultMap;
                }
            }
            
        }     
        
        return resultMap;
    }     

}