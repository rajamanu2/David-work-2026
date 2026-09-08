public class AddIRProductServices {
    public static final Integer maxRows = 200;
    
   
    
    @AuraEnabled
    public static List<Object> getIRProducts(Map<String, Object> queryParams) {
      List<IR_Product__c> listIRProducts = new List<IR_Product__c>(); 
      List<List<SObject>> searchList = new List<List<SObject>>();
      system.debug('#### queryParams: ' + queryParams);
       
      String strWhereClause;
        
      for (String p: queryParams.keySet()) {
          switch on p { // switch in place in case additional parameters are added to filter search
              when 'queryString' {
                  // Add search string to match Product Names and move product family to filters
                  system.debug('#### search string: ' + (String)queryParams.get('queryString'));
                  String searchStringValue = (String)queryParams.get('queryString');
                  strWhereClause = ' WHERE Product_Family__c like \'%' + 'Part' + '%\'';
                  strWhereClause += ' AND (Product_Name__c like \'%' + searchStringValue + '%\' OR ';
                  strWhereClause += ' Part_Number__c like \'%' + searchStringValue + '%\' OR ';
                  strWhereClause += ' Lot_Number__c like \'%' + searchStringValue + '%\')';
                  strWhereClause += ' AND Product2__r.IsActive = True';
                  
              }  
          }
      } 
        
      System.debug('#### getProducts method where clause: ' + strWhereClause); 
      String query = getIRProductQuery();  
      query += strWhereClause;
      query += ' ORDER BY Name ASC LIMIT ' + maxRows;
      System.debug('#### getProducts method query: ' + query); 
        
      for(IR_Product__c p: Database.query(query)) {
        system.debug('THIS IS THE IR PRODUCT >>> ' + p.Product_Name__c + ' ' + p.Lot_Number__c);
        listIRProducts.add(p); 
      }
        
        System.debug('#### getProducts listIRProducts: ' + listIRProducts);
        return listIRProducts;
    }

    public static String getIRProductQuery() {
        system.debug('inside get IR Product Query function >>');
        String query = 'SELECT Id,Product_Name__c, Part_Number__c, Lot_Number__c, Product_Family__c, Name, Quantity_Remaining__c, Product2__r.IsActive';
               query += ' FROM IR_Product__c';
        
        return query;
    }
    
     @AuraEnabled
    public static Object getProductRepairInfo(String productRepairId) {
        system.debug('#### getProductRepairInfo method.  Id: ' + productRepairId);
     	Product_Repair__c prodRepair; 
        Map<String, String> prodRepairMap = new Map<String, String>();
        if (productRepairId != null) {
        	prodRepair = [SELECT Id, Repair_Activity__c FROM Product_Repair__c WHERE Id =:productRepairId];
        }    
        
        prodRepairMap.put('repairActivity', prodRepair.Repair_Activity__c);
        
        system.debug('THIS IS THE PRODUCT REPAIR FROM ADD IR PRODUCT SERVICES >>> ' + prodRepairMap);
        
        return prodRepairMap;
    }   

    // It returns the existing product repair line items on the product repair and provides
    // the data to enable a user to select which items to swap.
    @AuraEnabled(cacheable=true)
    public static String getProductRepairLineItemsQuery(String productRepairId) {
        system.debug('#### calling getProductRepairLineItemsQuery method');
        String queryString = 'SELECT Id, IR_Product__c, IR_Product_Name__c, Lot_Number__c, Product_Repair__c, Quantity__c';
               queryString += ' FROM Product_Repair_Line_Item__c WHERE Product_Repair__c =\'' +  productRepairId + '\' ORDER BY IR_Product_Name__c';
 
        system.debug('#### existing product repair line items query returned:' + queryString);
        return queryString;
    } 
    
    // This method is used on the lightning version of the Add IR Product page.
    // It is called when the user saves the items they have selected.
    // It generates line items on the Product Repair.
    @AuraEnabled
    public static String createProductRepairLineItems(List<Map<String, Object>> selectedItems, List<Object> swapItems, String productRepairId) {
        system.debug('#### calling createProductRepairLineItems method.');
        system.debug('#### item list: ' + selectedItems);
         system.debug('#### swap list: ' + swapItems);
        system.debug('#### Product Repair Id: ' + productRepairId);
        String statusMessage;
        List<Product_Repair_Line_Item__c> prliListToInsert = new List<Product_Repair_Line_Item__c>();
        List<Product_Repair_Line_Item__c> prliListToDelete = new List<Product_Repair_Line_Item__c>();
        String prliQuery = getProductRepairLineItemsQuery(productRepairId);
        List<Product_Repair_Line_Item__c> prliList = Database.query(prliQuery);
        List<Id> itemReceiptProductIDList = new List<Id>();
        for(Product_Repair_Line_Item__c p: prliList){
            itemReceiptProductIDList.add(p.IR_Product__c);
        }
        List<IR_Product__c> itemReceiptProductList = new List<IR_Product__c>();
        List<IR_Product__c> updatedIRProductList = new List<IR_Product__c>();
        Map<Id, IR_Product__c> itemReceiptProductMap = new Map<Id, IR_Product__c>();
        Map<Id, Product_Repair_Line_Item__c> mapLineItem = new Map<Id, Product_Repair_Line_Item__c>();
        Set<String> setProductNames = new Set<String>();
        Boolean isSwap = false;
        Map<String, String> mapOriginalIdToSelectedId = new Map<String, String>(); 
        Map<String, String> mapSelectedIdToOriginalId = new Map<String, String>();
        Set<Id> setSelectedItemsForSwap = new Set<Id>();
        Map<String, Map<String, Object>> mapUpdatedIRProducts = new Map<String, Map<String, Object>>();
        String recordIdList = '(';
        
       
        for (Map<String, Object> o : selectedItems) {
            system.debug('#### object map: ' + o);
            
            Map<String, Object>  mapIRProductValues = new Map<String, Object>();
            String recordId = String.valueOf(o.get('id'));
            system.debug('THIS IS THE PRLI ID LIST >>> ' + itemReceiptProductIDList + ' AND RECORD ID >> ' + recordId);
            if(itemReceiptProductIDList.contains(recordId)){
                statusMessage += 'error: you cannot add the same IR product that is already on the repair; please choose a different IR product to swap';
                system.debug('CAUGHT SAME ID ERROR >> ' + recordId); 
            }
            system.debug('#### id: ' + recordId);
            recordIdList += '\'' + recordId + '\',';
            mapIRProductValues.put('quantity', o.get('quantity'));
            
            mapUpdatedIRPRoducts.put(recordId, mapIRProductValues);
            system.debug('#### mapIRProductValues: ' + mapIRProductValues);
            system.debug('#### mapUpdatedIRProducts: ' + mapUpdatedIRProducts);
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
                    if (!recordIdList.contains(selectedItemRecordId)){
                    	recordIdList += '\'' + selectedItemRecordId + '\',';
                    }    
                    setSelectedItemsForSwap.add(selectedItemRecordId);
                
                	mapOriginalIdToSelectedId.put(originalItemRecordId, selectedItemRecordId);
                    mapSelectedIdToOriginalId.put(selectedItemRecordId, originalItemRecordId);
                }
                
                system.debug('#### mapOriginalIdToSelectedId : ' + mapOriginalIdToSelectedId);
               	mapLineItem = new Map<Id, Product_Repair_Line_Item__c> ([SELECT Id, IR_Product__c, IR_Product_Name__c, Lot_Number__c, Product_Repair__c, Quantity__c FROM Product_Repair_Line_Item__c WHERE Product_Repair__c =: productRepairId AND Id IN: mapOriginalIdToSelectedId.keySet() ]);
            	system.debug('mapLineItem data: ' + mapLineItem.values());

        	} 
        } 
        
        recordIdList = recordIdList.removeEnd(',') + ')';
        String whereClause = ' WHERE Id IN ' + recordIdList;
        System.debug('#### createProductRepairLineItems method whereClause: ' + whereClause);
        String query = getIRProductQuery();  
      	query += whereClause;
        System.debug('#### createProductRepairLineItems method query: ' + query);
        
        for(IR_Product__c p: Database.query(query)) {
        	itemReceiptProductList.add(p);
            system.debug('#### IR Product: ' + p);
            setProductNames.add(p.Product_Name__c);
            itemReceiptProductMap.put(p.Id, p);
        }
        
       
        
        if (itemReceiptProductList.size() != 0 && setProductNames.size() != 0) {
            system.debug('#### processing new product repair line items');
            for (IR_Product__c p: itemReceiptProductList) {
                Product_Repair_Line_Item__c prli;
                IR_Product__c updatedIRProduct;
                
                Map<String, Object>  mapIRProductValues = mapUpdatedIRProducts.get(p.Id);
                prli = generateProductRepairLineItem(p, productRepairId, mapIRProductValues);
                /*if (isSwap && !mapSelectedIdToOriginalId.isEmpty() && !mapLineItem.isEmpty()) {
                    Id originalPrliId = mapSelectedIdToOriginalId.get(p.Id);
                    Product_Repair_Line_Item__c originalPrli = mapLineItem.get(originalPrliId);
                    prli = updateProductRepairLineItem(originalPrli, prli);
                }*/
                prliListToInsert.add(prli);
                updatedIRProduct = updateIRProduct(p, productRepairId, mapIRProductValues); 
                if (updatedIRProduct != null && updatedIRProduct.Id != null) {
                    system.debug('THIS IS THE QUANTITY REMAINING >> ' + updatedIRProduct.Quantity_Remaining__c);
                    if(updatedIRProduct.Quantity_Remaining__c < 0 || updatedIRProduct.Quantity_Remaining__c == null){
                        statusMessage += 'error: quantity too high for this product; please adjust the quantity or switch products';
            			system.debug('CAUGHT QUANTITY ERROR >>> ' + updatedIRProduct.Quantity_Remaining__c);
                    }
                    updatedIRProductList.add(updatedIRProduct);
                }
            } 
            
            
            
        } 
        
        if(isSwap) {
            system.debug('#### processing product repair line item swap');
            system.debug('map Line Item >> ' + mapLineItem + ' and original id to selected id >> ' + mapOriginalIdToSelectedId);
            if (!mapLineItem.isEmpty() && !mapOriginalIdToSelectedId.isEmpty()) {
                for (String originalItemRecordId : mapOriginalIdToSelectedId.keySet()){
                    Product_Repair_Line_Item__c existingLineItem = mapLineItem.get(originalItemRecordId);
                    system.debug('#### existing line item: ' + existingLineItem);
                    prliListToDelete.add(existingLineItem);
                }
            }
        }
         
        if (!prliListToInsert.isEmpty()) {
            try { 
                
                if(statusMessage == null){
                    
                    system.debug('THIS IS THE PRLI LIST TO INSERT FROM PRLI SERVICES >>> ' + prliListToInsert);
                    
                    DatabaseService.insertList(prliListToInsert);
                    system.debug('THIS IS THE NUMBER OF QUERIES SO FAR (PRLI) >>>' + Limits.getQueries());
                    statusMessage = 'success';
                }
            }  catch (Exception e) {
                statusMessage += 'error: ' + e.getMessage().unescapeHtml4();
            }
        }
        
        if (!updatedIRProductList.isEmpty()) {
            try { 
                system.debug('THIS IS THE IR PRODUCT LIST TO UPDATE FROM PRLI SERVICES >>> ' + updatedIRProductList);
                if(statusMessage == null || (statusMessage != null && statusMessage == 'success')){
                    DatabaseService.updateList(updatedIRProductList);
                    system.debug('THIS IS THE NUMBER OF QUERIES SO FAR (IR PRODUCT) >>>' + Limits.getQueries());
                    statusMessage = 'success';
                }
            }  catch (Exception e) {
                if (statusMessage != null && statusMessage == 'success'){
                   statusMessage = 'error: '; 
                }
                statusMessage += e.getMessage().unescapeHtml4();
            }
        }
        
        if (!prliListToDelete.isEmpty()) {
           try { 
               system.debug('THIS IS THE PRLI LIST TO DELETE FROM PRLI SERVICES >>> ' + prliListToDelete);
               if(statusMessage == null || (statusMessage != null && statusMessage == 'success')){
                    DatabaseService.deleteList(prliListToDelete);
                    system.debug('THIS IS THE NUMBER OF QUERIES SO FAR >>>' + Limits.getQueries());
                    statusMessage = 'success';
               }
            }  catch (Exception e) {
                if (statusMessage != null && statusMessage == 'success'){
                   statusMessage = 'error: '; 
                }
                statusMessage += e.getMessage();
            } 
        }
        
        system.debug('createProductRepairLineItems status message returned:' + statusMessage);
        return statusMessage;
    }
    
    // This method is used on the lightning version of the Add IR Product page.
    // It generates a product repair line item record as part of the line item creation process
    // and is called from the createProductRepairLineItems method.
    private static Product_Repair_Line_Item__c generateProductRepairLineItem(IR_Product__c p, Id productRepairId, Map<String, Object>  mapIRProductValues) {
      	Decimal quantity = 0.0;
        if(mapIRProductValues != null) {
           quantity = (Decimal)mapIRProductValues.get('quantity');
        }
       Product_Repair_Line_Item__c prli = new Product_Repair_Line_Item__c(Quantity__c = quantity, Product_Repair__c = productRepairId, IR_Product__c = p.id);
        
       return prli; 
        
    }
    /*
    private static Product_Repair_Line_Item__c updateProductRepairLineItem(Product_Repair_Line_Item__c originalPrli, Product_Repair_Line_Item__c newPrli) {
        
       if (originalPrli != null && newPrli != null && originalPrli.Quantity__c != null) {
          	newPrli.Quantity__c = originalPrli.Quantity__c;
       } 

       return newPrli;
    } */
    
    // This method is used on the lightning version of the Add IR Product page.
    // It updates a product item as part of the line item creation process
    // and is called from the createProductRepairLineItems method.
    private static IR_Product__c updateIRProduct(IR_Product__c p, Id productRepairId, Map<String, Object>  mapIRProductValues) {
       IR_Product__c updatedIRProduct = new IR_Product__c();
       Decimal quantity = 0.0;
        
        if (p.Id != null) {
            updatedIRProduct = p.clone(true, true, false, true);
            
        	if (mapIRProductValues != null && mapIRProductValues.containsKey('quantity')) {
                quantity = (Decimal)mapIRProductValues.get('quantity');
                system.debug('THIS IS THE DECIMAL QUANTITY >> ' + quantity + ' AND QTY REMAINING >> ' + updatedIRProduct.Quantity_Remaining__c);
                if (quantity != null) {
                    
                    updatedIRProduct.Quantity_Remaining__c = updatedIRProduct.Quantity_Remaining__c - quantity;
                }
            }

            
        }       
        
        return updatedIRProduct;
    }
    
    @AuraEnabled
    public static String deleteProductRepairLineItem(String itemReceiptProductId, String productRepairId) {
		String statusMessage;
        List<Product_Repair_Line_Item__c> prliListToDelete = new List<Product_Repair_Line_Item__c>();
        
        if (itemReceiptProductId != null && productRepairId != null) {
        	Product_Repair_Line_Item__c prli = [SELECT Id, IR_Product__c, IR_Product_Name__c, Product_Repair__c
                                       FROM Product_Repair_Line_Item__c WHERE Product_Repair__c =: productRepairId AND IR_Product__c =: itemReceiptProductId LIMIT 1];
            
            try { 
                prliListToDelete.add(prli);
            	DatabaseService.deleteList(prliListToDelete);
                statusMessage = 'success';
            }  catch (Exception e) {
                statusMessage += 'error: ' + e.getMessage().unescapeHtml4();
            } 
        }
        
        return statusMessage;
    }   
    
   /* @AuraEnabled
    public static String updateProductRepair(Id selectedItem, Id productRepairId, Boolean swapItem) { 
        system.debug('#### calling updateProductRepair method.' + selectedItem + ' and ID ' + productRepairId + ' is swap? ' + swapItem);
        String statusMessage;
        
        if(selectedItem != null && productRepairId != null){
            
            prodRepairId = productRepairId;
            getProductRepair();
            String query = getIRProductQuery();  
            
            IR_Product__c IRProduct;
            IR_Product__c swapIRProduct;
            List<IR_Product__c> updateIRProducts = new List<IR_Product__c>();
            Id recordId = selectedItem;
            Id swapRecordId = pr.IR_Product__c;
            system.debug('THIS IS THE IR PRODUCT ON PRODUCT REPAIR >> '  + pr.IR_Product__c);
            // cannot add same IR product in swap
            if(pr.IR_Product__c != null){
                if(recordId == swapRecordId){
                    
                    if(recordId == swapRecordId){
                        statusMessage += 'error: you cannot swap the same IR product that is already on the repair; please choose a different IR product to swap';
                	
                    }
                    system.debug('ERROR SWAP >> ' + statusMessage);
                }
                else {
                   
                    String swapWhereClause = ' WHERE Id = :swapRecordId'; 
                    String swapQuery = getIRProductQuery(); 
                    swapQuery += swapWhereClause;
                    System.debug('#### updateProductRepair method swap query: ' + swapQuery);
                    swapIRProduct = Database.query(swapQuery);
                    if(swapIRProduct != null){
                        swapIRProduct.Quantity_Remaining__c += 1;
                        updateIRProducts.add(swapIRProduct);
                    }
            	}
            }
            
            String whereClause = ' WHERE Id =:recordId';
            query += whereClause;
            System.debug('#### updateProductRepair method query: ' + query);
            IRProduct = Database.query(query);
            IRProduct.Quantity_Remaining__c = IRProduct.Quantity_Remaining__c - 1;
            updateIRProducts.add(IRProduct);
            pr.IR_Product__c = IRProduct.Id;
            
            try { 
                if(statusMessage == null){
                    system.debug('#### About to update product repair: ' + pr.Id);
                    DatabaseService.updateRecord(pr);
                    DatabaseService.updateList(updateIRProducts);
                    statusMessage = 'success';
                }
                
            }  catch (Exception e) {
                statusMessage += 'error: ' + e.getMessage().unescapeHtml4();
            }
       }
        system.debug('updateProductRepair status message returned:' + statusMessage);
        return statusMessage;
             
 	} */
    
    
}