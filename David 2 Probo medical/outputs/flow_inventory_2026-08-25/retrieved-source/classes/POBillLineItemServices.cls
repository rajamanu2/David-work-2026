public class POBillLineItemServices {
    public static Id poBillRecordTypeId = RecordTypeUtility.getRecordTypeByName('PO_Bill__c', 'PO Bill');
    public static Id purchasingPriceAdjustmentRecordTypeId = RecordTypeUtility.getRecordTypeByName('PO_Bill__c', 'Purchasing Price Adjustment');
    
    @AuraEnabled
    public static Object createPOBill(String opportunityId, String recordTypeId) {
        system.debug('#### calling createPOBill method.');
        //system.debug('#### item list: ' +selectedItems);
        String statusMessage;
        Opportunity opp;
        PO_Bill__c po;
        Id pbId;
        Map<String, String> resultMap = new Map<String, String>();
        
        if (opportunityId != null && recordTypeId != null && recordTypeId == purchasingPriceAdjustmentRecordTypeId) {
            opp = [SELECT Id, Name, StageName, RecordTypeId, AccountId, Account.Name FROM Opportunity WHERE Id =: opportunityId];
        	system.debug('#### opp: ' + opp);
            po =  new PO_Bill__c(Opportunity__c=opp.Id, RecordTypeId=recordTypeId);
            
            try {
                insert po;
                resultMap.put('poBillId', po.Id);
                statusMessage = 'success';
                resultMap.put('status', statusMessage);
            } catch (Exception e) {
                system.debug('#### Error occurred while inserting PO Bill: ' + e.getMessage());
                statusMessage = 'Error occurred while inserting PO Bill';
                resultMap.put('status', statusMessage);
                return resultMap;
            }
        }   
        
        return resultMap;
    }    
    
    @AuraEnabled
    public static Object createPOBillLineItems(List<Object> selectedItems, String opportunityId, String recordTypeId) {
        system.debug('#### calling createPOBillLineItems.');
        system.debug('#### item list: ' +selectedItems);
        String statusMessage;
        Opportunity opp;
        PO_Bill__c po;
        Id pbId;
        Map<String, String> resultMap = new Map<String, String>();
        List<ProductItem__c> listSelectedLineItems = new List<ProductItem__c>();
        Set<Id> setSelectedLineItemIds = new Set<Id>();
        List<ProductItem__c> listProductItemsToUpdate = new List<ProductItem__c>();
        
        if (selectedItems != null && opportunityId != null && recordTypeId != null && recordTypeId == poBillRecordTypeId) {
            opp = [SELECT Id, Name, StageName, RecordTypeId, AccountId, Account.Name FROM Opportunity WHERE Id =: opportunityId];
        	system.debug('#### opp: ' + opp);
            po =  new PO_Bill__c(Opportunity__c=opp.Id, RecordTypeId=recordTypeId);
            
            try {
                insert po;
                resultMap.put('poBillId', po.Id);
            } catch (Exception e) {
                system.debug('#### Error occurred while inserting PO Bill: ' + e.getMessage());
                statusMessage = 'Error occurred while inserting PO Bill';
                resultMap.put('status', statusMessage);
                return resultMap;
            }
            
            listSelectedLineItems = (List<ProductItem__c>)JSON.deserialize(JSON.serialize(selectedItems), List<ProductItem__c>.class);
            for (ProductItem__c p: listSelectedLineItems) {
                setSelectedLineItemIds.add(p.Id);
            }
            
            if (!setSelectedLineItemIds.isEmpty() && po != null) {
                for (ProductItem__c p: [SELECT Id, PO_Bill__c 
                                         FROM ProductItem__c WHERE Id IN: setSelectedLineItemIds]) {
                      
                    p.PO_Bill__c =  po.Id;
                    listProductItemsToUpdate.add(p);                        
            	}
                
            }

          if (!listProductItemsToUpdate.isEmpty()) {
              system.debug('#### number of PO Bill Line Items: ' + listProductItemsToUpdate.size());
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

}