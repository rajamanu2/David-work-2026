public class LoanerLineItemServices {
    public static final Integer maxRows = 200;
    //public static Id salesRecordTypeId = RecordTypeUtility.getRecordTypeByName('Opportunity', 'Sales Opportunity');
    //public static Id purchasingRecordTypeId = RecordTypeUtility.getRecordTypeByName('Opportunity', 'Purchasing Opportunity');
    //public static Id repairRecordTypeId = RecordTypeUtility.getRecordTypeByName('Opportunity', 'External Repair / Testing');

    @AuraEnabled
    public static String createLoanerLineItems(List<Map<String, Object>> selectedItems, List<Map<String, Object>> selectedPurchasingItems,  List<Object> swapItems, String opportunityId, String loanerId) {
        system.debug('#### calling createLoanerLineItems method.');
        system.debug('#### item list: ' + selectedItems);
        system.debug('#### purchasing item list: ' + selectedPurchasingItems);
        system.debug('#### swap list: ' + swapItems);
        system.debug('#### Opportunity Id: ' + opportunityId);
        system.debug('#### Loaner Id: ' + loanerId);
        String statusMessage;
        Id pbId;
        List<ProductItem__c> pItemList = new List<ProductItem__c>();
        List<ProductItem__c> updatedItemList = new List<ProductItem__c>();
        Map<Id, ProductItem__c> pItemMap = new Map<Id, ProductItem__c>();
        Set<String> setProductNames = new Set<String>();
        Boolean isSwap = false;
        Boolean isOppUpdated = false;
        Opportunity currentOpp = new Opportunity();
        Map<String, String> mapOriginalIdToSelectedId = new Map<String, String>(); 
        Map<String, String> mapSelectedIdToOriginalId = new Map<String, String>();
        Set<Id> setSelectedItemsForSwap = new Set<Id>();
        Map<String, Id> mapProductToPriceBookEntryId = new Map<String, Id>();
        Map<String, Map<String, Object>> mapUpdatedProductItems = new Map<String, Map<String, Object>>();
        String recordIdList = '(';
        Opportunity opp = [SELECT Id, StageName, RecordTypeId FROM Opportunity WHERE Id =: opportunityId];
        List<Loaner_Asset__c> listLoanerAssetsToInsert = new List<Loaner_Asset__c>();
        List<Loaner_Asset__c> listLoanerAssetsToDelete = new List<Loaner_Asset__c>();
        Set<Id> setItemsToRemoveFromLoaner = new Set<Id>();
        system.debug('#### opp: ' + opp);
         
        for (Map<String, Object> o : selectedItems) {
            system.debug('#### object map: ' + o);
            Map<String, Object>  mapSalesProductItemValues = new Map<String, Object>();
            String recordId = String.valueOf(o.get('id'));
            system.debug('#### id: ' + recordId);
            recordIdList += '\'' + recordId + '\',';
            mapSalesProductItemValues.put('price', o.get('price'));
            mapSalesProductItemValues.put('cost', o.get('cost'));
            mapSalesProductItemValues.put('exchange', o.get('exchange'));
            mapUpdatedProductItems.put(recordId, mapSalesProductItemValues);
            system.debug('#### mapSalesProductItemValues: ' + mapSalesProductItemValues);
            system.debug('#### mapUpdatedProductItems: ' + mapUpdatedProductItems);
        }
        
        
        if (swapItems != null) {
            isSwap = true;
            
            for (Object o : swapItems) {
                system.debug('#### object : ' + o);
                String keyValue = String.valueOf(o);
                system.debug('#### key value : ' + keyValue);
                
                if (keyValue != null) {
                    String originalItemRecordId = keyValue.substringBefore('-');
                    system.debug('#### original id: ' + originalItemRecordId);
                    
                    String selectedItemRecordId =keyValue.substringAfter('-');
                    system.debug('#### selected id: ' + selectedItemRecordId);
                    if (!recordIdList.contains(originalItemRecordId)){
                    	recordIdList += '\'' + originalItemRecordId + '\',';
                    }    
                    setSelectedItemsForSwap.add(originalItemRecordId);
                
                	mapOriginalIdToSelectedId.put(originalItemRecordId, selectedItemRecordId);
                    mapSelectedIdToOriginalId.put(selectedItemRecordId, originalItemRecordId);
                }
                
                system.debug('#### mapOriginalIdToSelectedId : ' + mapOriginalIdToSelectedId);

        	} 
        } 
        
        recordIdList = recordIdList.removeEnd(',') + ')';
        String whereClause = ' WHERE Id IN ' + recordIdList;
        System.debug('#### createLoanerLineItems method whereClause: ' + whereClause);
        String query = AddProductServices.getProductQuery();  
      	query += whereClause;
        System.debug('#### createLoanerLineItems method query: ' + query);
        
        for(ProductItem__c p: Database.query(query)) {
        	pItemList.add(p);
            system.debug('#### item: ' + p);
            setProductNames.add(p.Product_Name__r.Name);
            pItemMap.put(p.Id, p);
        }
        
        system.debug('#### item list size: ' + pItemList.size()); 
        
        if (pItemList.size() != 0 ) {
            
            for (ProductItem__c p: pItemList) {
                ProductItem__c updatedProductItem;
                ProductItem__c removedProductItem;
                
                if (!setSelectedItemsForSwap.contains(p.Id)) {
                    system.debug('#### processing new line items');
                    Map<String, Object>  mapProductItemValues = mapUpdatedProductItems.get(p.Id);
                    updatedProductItem = updateProductItem(p, mapProductItemValues);
                    if (updatedProductItem != null && updatedProductItem.Id != null) {
                        updatedItemList.add(updatedProductItem);
                    }
                    Loaner_Asset__c la = new Loaner_Asset__c(Loaner__c=loanerId, ProductItem__c=p.Id);
                    listLoanerAssetsToInsert.add(la);
                } else if (isSwap && setSelectedItemsForSwap.contains(p.Id)) {
                    system.debug('#### processing asset swap');
                    //ProductItem__c originalProductItem = pItemMap.get(p.Id);
                    //system.debug('#### original asset: ' + originalProductItem);
                    //removedProductItem = removeProductItemFromLoaner(originalProductItem);
                    system.debug('#### removed asset Id: ' + p.Id);
                    setItemsToRemoveFromLoaner.add(p.Id);
                    //if (removedProductItem != null && removedProductItem.Id != null) {
                    //	updatedItemList.add(removedProductItem);
                	//}
                } 
            	
            } 
            
        } 
        
        //for (ProductItem__c p: updatedItemList) {
        //	system.debug('#### updated item in list: ' + p.Name + ' loaner Id: ' + p.Loaner__c);
        //} 
        
        if (!setItemsToRemoveFromLoaner.isEmpty() && loanerId != null) {
            for (Loaner_Asset__c la: [SELECT Id FROM Loaner_Asset__c WHERE ProductItem__c IN: setItemsToRemoveFromLoaner AND Loaner__c =: loanerId]) {
                listLoanerAssetsToDelete.add(la);
            }
        }      
        
        
        if (!updatedItemList.isEmpty()) {
            try { 
            	DatabaseService.updateList(updatedItemList);
                //statusMessage = 'success';
            }  catch (Exception e) {
                if (statusMessage != null){
                   statusMessage = 'error: '; 
                }
                statusMessage += e.getMessage().unescapeHtml4();
            }
        }
        
        if (!listLoanerAssetsToInsert.isEmpty()) {
              system.debug('#### about to insert this many loaner assets: ' + listLoanerAssetsToInsert.size());
            try { 
            	DatabaseService.insertList(listLoanerAssetsToInsert);
                statusMessage = 'success';
            }  catch (Exception e) {
                if (statusMessage != null && statusMessage == 'success'){
                   statusMessage = 'error: '; 
                }
                statusMessage += e.getMessage().unescapeHtml4();
            }
        }
        
        if (!listLoanerAssetsToDelete.isEmpty()) {
            system.debug('#### about to delete this many loaner assets: ' + listLoanerAssetsToDelete.size());
            try { 
            	DatabaseService.deleteList(listLoanerAssetsToDelete);
                statusMessage = 'success';
            }  catch (Exception e) {
                if (statusMessage != null && statusMessage == 'success'){
                   statusMessage = 'error: '; 
                }
                statusMessage += e.getMessage().unescapeHtml4();
            }
        }
        
        
        system.debug('#### createLoanerLineItems status message returned:' + statusMessage);
        return statusMessage;
    }

    private static ProductItem__c updateProductItem(ProductItem__c p, Map<String, Object>  mapProductItemValues) {
       ProductItem__c updatedProductItem = new ProductItem__c();
       Double cost = 0.0;
        
        if (p.Id != null) {
            //updatedProductItem = p.clone(true, true, false, true);
            
            if (p.Generic_Product__c == false) {
                p.Added_To_Opportunity__c = true;
                p.Reserved__c = true;
            }   
            
            //p.Loaner__c = loanerId;
        
        	if (mapProductItemValues != null && mapProductItemValues.containsKey('cost')) {
                cost = (Double)mapProductItemValues.get('cost');
                
                if (cost != null && cost != p.Cost__c) {
                   p.Cost__c = cost;
                }
            }
        }       
        
        return p;
    }
    
    /*private static ProductItem__c removeProductItemFromLoaner(ProductItem__c p) {
        ProductItem__c removedProductItem = new ProductItem__c();
        
        if (p.Id != null) {
            //removedProductItem = p.clone(true, true, false, true);
            p.Added_To_Opportunity__c = true;
            p.Reserved__c = true;
            p.Loaner__c = null;
        }    
        
        return p;
    }*/
    

}