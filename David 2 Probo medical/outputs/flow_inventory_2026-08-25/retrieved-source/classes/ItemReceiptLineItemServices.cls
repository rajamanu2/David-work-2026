public class ItemReceiptLineItemServices {

    @AuraEnabled
    public static Object createItemReceiptLineItems(List<Object> selectedItems, String opportunityId) {
        system.debug('#### calling createItemReceiptLineItems method.');
        system.debug('#### item list: ' +selectedItems);
        String statusMessage;
        Opportunity opp;
        Item_Receipt__c ic;
        Id pbId;
        Map<String, String> resultMap = new Map<String, String>();
        List<ProductItem__c> listSelectedLineItems = new List<ProductItem__c>();
        Set<Id> setSelectedLineItemIds = new Set<Id>();
        Map<Id, ProductItem__c> mapSelectedLineItems = new Map<Id, ProductItem__c>();
        List<ProductItem__c> listProductItemsToUpdate = new List<ProductItem__c>();
        
        if (selectedItems != null && opportunityId != null ) {
            opp = [SELECT Id, Name, StageName, RecordTypeId, AccountId, Warranty_Term__c FROM Opportunity WHERE Id =: opportunityId];
        	system.debug('#### opp: ' + opp);
            ic =  new Item_Receipt__c(Opportunity__c=opp.Id);
            
            try {
                insert ic;
                resultMap.put('itemReceiptId', ic.Id);
            } catch (Exception e) {
                system.debug('#### Error occurred while inserting Item Receipt: ' + e.getMessage());
                statusMessage = 'Error occurred while inserting Item Receipt';
                resultMap.put('status', statusMessage);
                return resultMap;
            }
            
            listSelectedLineItems = (List<ProductItem__c>)JSON.deserialize(JSON.serialize(selectedItems), List<ProductItem__c>.class);
            for (ProductItem__c p: listSelectedLineItems) {
                setSelectedLineItemIds.add(p.Id);
                mapSelectedLineItems.put(p.Id, p);
            }
            
            if (!setSelectedLineItemIds.isEmpty() && ic != null) {
                for (ProductItem__c p: [SELECT Id, Cost__c, Purchasing_Approved__c, Probo_s_Offer__c, Item_Receipt__c 
                                         FROM ProductItem__c WHERE Id IN: setSelectedLineItemIds]) {
                                             
                    if (mapSelectedLineItems.containsKey(p.Id) && mapSelectedLineItems.get(p.Id).Cost__c != null)  {
                        p.Cost__c = mapSelectedLineItems.get(p.Id).Cost__c;                         
                    }                      
                	
                    if (opp.Warranty_Term__c != null) {
                        String warrantyTerm = opp.Warranty_Term__c + 's';
                        p.Vendor_Warranty_Length__c = warrantyTerm;
                    }
                                             
                    p.Purchasing_Approved__c = true;
                    p.Item_Receipt__c =  ic.Id;
                    listProductItemsToUpdate.add(p);                        
            	}
                
            }
            
            if (!listProductItemsToUpdate.isEmpty()) {
                try {
                    update listProductItemsToUpdate;
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

    public static Map<String, OpportunityLineItem> getOpportunityLineItems(String opportunityId) {
        Map<String, OpportunityLineItem> mapOppLineItems = new Map<String, OpportunityLineItem>(); 
        
        if (opportunityId != null) {
            for (OpportunityLineItem oli : [SELECT Id, ProductItem__c, Asset_No__c, Probo_s_Offer__c, Product2Id, Product2.Name FROM OpportunityLineItem WHERE OpportunityId =:opportunityId]) {
            system.debug('### getOpportunityLineItems method - oli.Product2.Name: ' + oli.Product2.Name);
            if (oli.Product2.Name != null) {
                	mapOppLineItems.put(oli.Product2.Name, oli);
                }        
            }
        }

        system.debug('### mapOppLineItems: ' + mapOppLineItems);
        return mapOppLineItems;
    }  
    
    @AuraEnabled
    public static List<Object> getProducts(String opportunityId) {
        List<ProductItem__c> listProductItems = new List<ProductItem__c>(); 
        Map<String, OpportunityLineItem> mapOppLineItems = new Map<String, OpportunityLineItem>(); 
        
        if (opportunityId != null) {
            mapOppLineItems = getOpportunityLineItems(opportunityId);
            
            
            String query = 'SELECT Id, Name, Product2_Name__c, Serial_No__c, Purchasing_Approved__c, Functional_Rating__c,' +
                                     ' Cosmetic_Rating__c, Sold__c, Sales_Price__c, Repair_Value__c, Cost__c ' +
                                     ' FROM ProductItem__c WHERE Purchasing_Opportunity__c =\'' + opportunityId + '\' AND Item_Receipt__c = null' +
                                     ' AND Purchasing_Approved__c = false ORDER BY Product2_Name__c';
            
            system.debug('query: ' + query);
            system.debug('mapOppLineItems: ' + mapOppLineItems);
            
            
            for (ProductItem__c p : Database.query(query)) {
                 system.debug('processing: ' + p.Id + ' name: ' + p.Name);
                if (mapOppLineItems.containsKey(p.Product2_Name__c) && mapOppLineItems.get(p.Product2_Name__c).Probo_s_Offer__c != null) {
                    system.debug('found probo offer: ' + mapOppLineItems.get(p.Product2_Name__c).Probo_s_Offer__c);
                    p.Cost__c = mapOppLineItems.get(p.Product2_Name__c).Probo_s_Offer__c;
                } 
                listProductItems.add(p);
            }
        }   
        
        return listProductItems;
    }    
}