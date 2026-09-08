public class WorkOrderLineItemServices {
    //public static Id salesRecordTypeId = RecordTypeUtility.getRecordTypeByName('Opportunity', 'Sales Opportunity');
    //public static Id purchasingRecordTypeId = RecordTypeUtility.getRecordTypeByName('Opportunity', 'Purchasing Opportunity');

    //public static list<id> salesOppRecordList = new list<id>();
    public static list<id> purchasingOppRecordList = new list<id>();
   
    
    @AuraEnabled
    public static String createWorkOrderLineItems(List<Map<String, Object>> selectedItems, List<Map<String, Object>> selectedPurchasingItems, String opportunityId, String workOrderId) {
        // First get record types
        
        for (RecordType r : ProboCommonUtils.getRecordTypes('Opportunity')) {
            switch on r.DeveloperName{
                
                when 'Purchasing_Opportunity' {
                    purchasingOppRecordList.add(r.id);
                    
                }
                
                when 'Big_Iron_Purchasing_Opportunity'{
                    purchasingOppRecordList.add(r.id);
                }
            }
        }
        
        
        system.debug('#### calling createWorkOrderLineItems method.');
        system.debug('#### item list: ' + selectedItems);
        system.debug('#### purchasing item list: ' + selectedPurchasingItems);
        String statusMessage;
        //Pricebook2 pb;
        Id pbId;
        List<WorkOrderLineItem> woliToInsert = new List<WorkOrderLineItem>();
        List<ProductItem__c> pItemList = new List<ProductItem__c>();
        List<ProductItem__c> updatedItemList = new List<ProductItem__c>();
        Map<Id, ProductItem__c> pItemMap = new Map<Id, ProductItem__c>();
        Map<Id, OpportunityLineItem> mapLineItem = new Map<Id, OpportunityLineItem>();
        Set<String> setProductNames = new Set<String>();
        Boolean isOppUpdated = false;
        Opportunity currentOpp = new Opportunity();
        Set<Id> setSelectedItemsForSwap = new Set<Id>();
        Map<String, Id> mapProductToPriceBookEntryId = new Map<String, Id>();
        Map<String, Map<String, Object>> mapUpdatedProductItems = new Map<String, Map<String, Object>>();
        String recordIdList = '(';
        Opportunity opp;
        //sObject woSobject;
        WorkOrder updatedWO;
        Boolean isWoUpdated = false;
        Boolean skipReserved = false;
        
        if (opportunityId != null) {
            opp = [SELECT Id, StageName, RecordTypeId, CurrencyIsoCode FROM Opportunity WHERE Id =: opportunityId];
        	system.debug('#### opp: ' + opp);
        }
        
        if (opp != null && purchasingOppRecordList.contains(opp.RecordTypeId)) {
            for (Map<String, Object> o : selectedPurchasingItems) {
                system.debug('#### object map: ' + o);
                Map<String, Object>  mapPurchasingProductItemValues = new Map<String, Object>();
                String recordId = String.valueOf(o.get('id'));
                system.debug('#### id: ' + recordId);
                recordIdList += '\'' + recordId + '\',';
                mapPurchasingProductItemValues.put('price', o.get('price'));
                mapPurchasingProductItemValues.put('cost', o.get('cost'));
                mapPurchasingProductItemValues.put('offer', o.get('offer'));
                mapPurchasingProductItemValues.put('quote', o.get('quote'));
                mapPurchasingProductItemValues.put('exchange', o.get('exchange'));
                mapUpdatedProductItems.put(recordId, mapPurchasingProductItemValues);
                system.debug('#### mapPurchasingProductItemValues: ' + mapPurchasingProductItemValues);
                system.debug('#### mapUpdatedProductItems: ' + mapUpdatedProductItems);
            }
        } else {
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
        }
        
        recordIdList = recordIdList.removeEnd(',') + ')';
        String whereClause = ' WHERE Id IN ' + recordIdList;
        System.debug('#### createWorkOrderLineItems method whereClause: ' + whereClause);
        String query = AddProductServices.getProductQuery();  
      	query += whereClause;
        System.debug('#### createWorkOrderLineItems method query: ' + query);
        
        for(ProductItem__c p: Database.query(query)) {
        	pItemList.add(p);
            system.debug('#### item: ' + p);
            setProductNames.add(p.Product_Name__r.Name);
            pItemMap.put(p.Id, p);
        }
        
        if (test.isRunningTest()) {
            pbId = ProboCommonUtils.getStdPricebookId();
        } else {
            try {
                Pricebook2 pb = [select Id from PriceBook2 where isStandard = true and isActive = true limit 1];
                pbId = pb.Id;
            } catch (Exception e) {
                system.debug('#### Unable to find standard priceBook. Cannot continue.');
                statusMessage = 'Unable to find standard priceBook. Cannot continue.';
            } 
        }
        
        if (pbId != null && pItemList.size() != 0 && setProductNames.size() != 0) {
            system.debug('#### processing new line items');
            String updatedCurrency;
            if (workOrderId != null) {
                //for(sObject s : [SELECT Id, WorkOrderNumber, ServiceContractId, PriceBook2Id, CurrencyIsoCode FROM WorkOrder WHERE Id =: workOrderId]) {
                for(WorkOrder w: [SELECT Id, WorkOrderNumber, ServiceContractId, PriceBook2Id, CurrencyIsoCode, Country, RecordType.DeveloperName, Billing_Type__c FROM WorkOrder WHERE Id =: workOrderId]){
                    if (w.PriceBook2Id == null) {
                         system.debug('#### updating price book Id on Work Order: ' + pbId);
                         w.PriceBook2Id = pbId;
                         //woSobject = w;
                         updatedWO = w;
                         isWoUpdated = true;
                    }
                    if(w.CurrencyIsoCode != null){
                        updatedCurrency = w.CurrencyIsoCode;
                    }
                    String woCountry = w.Country;
                    skipReserved = (woCountry == 'United States' || woCountry == 'US')
                        && w.RecordType != null
                        && w.RecordType.DeveloperName == 'FSL_Work_Order'
                        && w.Billing_Type__c != 'Contract'
                        && w.Billing_Type__c != 'Warranty';
             }
            }
            
            if(opp != null && updatedCurrency == null){
                updatedCurrency = opp.CurrencyIsoCode;
            }
            
            mapProductToPriceBookEntryId = AddProductServices.createPriceBookEntries(pItemList, setProductNames, pbId, updatedCurrency);
            
            for (ProductItem__c p: pItemList) {
                Id priceBookEntryId;
                //OpportunityLineItem oli;
                WorkOrderLineItem woli;
                ProductItem__c updatedProductItem;
                
                if (mapProductToPriceBookEntryId != null && mapProductToPriceBookEntryId.containsKey(p.Product_Name__r.Name)) {
                    priceBookEntryId = mapProductToPriceBookEntryId.get(p.Product_Name__r.Name);  
                }
                
                Map<String, Object>  mapProductItemValues = mapUpdatedProductItems.get(p.Id);
                //oli = generateOpportunityLineItem(p, opp, priceBookEntryId, mapProductItemValues);
                //oliListToInsert.add(oli);
                woli = generateWorkOrderLineItem(p, opp, workOrderId, priceBookEntryId, mapProductItemValues);
                woliToInsert.add(woli);
                updatedProductItem = updateProductItem(p, opp, mapProductItemValues, skipReserved);
                if (updatedProductItem != null && updatedProductItem.Id != null) {
                    updatedItemList.add(updatedProductItem);
                }
            } 
            
        } 
        
        if (isWoUpdated) {
            system.debug('#### updating work order');
            try { 
            	//DatabaseService.updateRecord(woSobject);
            	update updatedWO;
            }  catch (Exception e) {
                statusMessage += 'error: ' + e.getMessage().unescapeHtml4();
            }
        }
        
        if (!woliToInsert.isEmpty()) {
            try { 
                system.debug('#### inserting work order line items');
            	DatabaseService.insertList(woliToInsert);
                statusMessage = 'success';
            }  catch (Exception e) {
                statusMessage += 'error: ' + e.getMessage().unescapeHtml4();
            }
        }
        
        if (!updatedItemList.isEmpty()) {
            try { 
            	DatabaseService.updateList(updatedItemList);
                statusMessage = 'success';
            }  catch (Exception e) {
                if (statusMessage != null && statusMessage == 'success'){
                   statusMessage = 'error: '; 
                }
                statusMessage += e.getMessage().unescapeHtml4();
            }
        }
        
        system.debug('createWorkOrderLineItems status message returned:' + statusMessage);
        return statusMessage;
    }
    
    private static WorkOrderLineItem generateWorkOrderLineItem(ProductItem__c p, Opportunity o, Id workOrderId, Id pbeId, Map<String, Object>  mapProductItemValues) {
       Double price = p.Price__c;
       if(mapProductItemValues != null) {
           price = (Double)mapProductItemValues.get('price');
       }
      WorkOrderLineItem woli = new WorkOrderLineItem(WorkOrderId = workOrderId, PricebookEntryId = pbeId,
                                Part_Used__c = p.Id, Part_Name__c = p.Product_Name__c, UnitPrice = price, Quantity = 1);

      String productName = (p.Product_Name__r != null) ? p.Product_Name__r.Name : null;
      if (String.isNotBlank(productName)) {
          String n = productName.toLowerCase();
          if (n.contains('labor')) {
              woli.Line_Type__c = 'Labor';
              woli.Line_Intent__c = 'Labor';
          } else if (n.contains('travel')) {
              woli.Line_Type__c = 'Travel';
              woli.Line_Intent__c = 'Travel';
          } else if (n.contains('ship')) {
              woli.Line_Type__c = 'Shipping';
              woli.Line_Intent__c = 'Shipping';
          } else if (n.contains('pm call')) {
              woli.Line_Type__c = 'PM Call';
              woli.Line_Intent__c = 'PM Call';
          } else {
              woli.Line_Type__c = 'Part Assigned';
              Boolean isExchange = mapProductItemValues != null && mapProductItemValues.get('exchange') == true;
              woli.Line_Intent__c = isExchange ? 'Exchange' : 'Outright Sale';
          }
      }

      system.debug('#### generated Work Order Line Item: ' + woli);
      return woli;

    }
  
    private static ProductItem__c updateProductItem(ProductItem__c p, Opportunity o, Map<String, Object>  mapProductItemValues, Boolean skipReserved) {
       ProductItem__c updatedProductItem = new ProductItem__c();
       Double cost = 0.0;
        
        if (p.Id != null) {
            updatedProductItem = p.clone(true, true, false, true);
            
            if (p.Generic_Product__c == false) {
                updatedProductItem.Added_To_Opportunity__c = true;
                if (!skipReserved) {
                    updatedProductItem.Reserved__c = true;
                }
            }     
        
        	if (mapProductItemValues != null && mapProductItemValues.containsKey('cost')) {
                cost = (Double)mapProductItemValues.get('cost');
                
                if (cost != null && cost != p.Cost__c) {
                    updatedProductItem.Cost__c = cost;
                }
            }
        }       
        
        return updatedProductItem;
    }
    
    /**
     * Minimal picker source for the LWC swap UI
     */
    @AuraEnabled(cacheable=true)
    public static List<WorkOrderLineItem> getWorkOrderItems(Id workOrderId) {
        return [
        SELECT
            Id,
            Part_Name_D__c,
            Part_Number_D__c,
            Product2.Name,
            PricebookEntry.Product2.Name
        FROM WorkOrderLineItem
        WHERE WorkOrderId = :workOrderId
        ORDER BY LineItemNumber
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<WrapperWoi> getWorkOrderItemsWrapped(Id workOrderId) {
        List<WrapperWoi> rows = new List<WrapperWoi>();
        for (WorkOrderLineItem w : [
            SELECT Id, Part_Name_D__c, Part_Number_D__c
            FROM WorkOrderLineItem
            WHERE WorkOrderId = :workOrderId
            ORDER BY LineItemNumber
        ]) {
            rows.add(new WrapperWoi(w.Id, w.Part_Name_D__c, w.Part_Number_D__c));
        }
        return rows;
    }



    @AuraEnabled
    public static String deleteWorkOrderLineItem(Id woliId) {
        try {
            if (woliId == null) return 'error: Missing Work Order Line Item Id.';
            delete [SELECT Id FROM WorkOrderLineItem WHERE Id = :woliId LIMIT 1];
            return 'success';
        } catch (Exception e) {
            return 'error: ' + e.getMessage().unescapeHtml4();
        }
    }
    
    public class WrapperWoi {
        @AuraEnabled public Id id;
        @AuraEnabled public String label;    // we'll use this for Part Name
        @AuraEnabled public String subLabel; // we'll use this for Part Number
        public WrapperWoi(Id i, String l, String s) { id = i; label = l; subLabel = s; }
    }
    

}