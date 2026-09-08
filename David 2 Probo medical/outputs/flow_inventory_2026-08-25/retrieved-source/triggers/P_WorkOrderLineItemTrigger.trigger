trigger P_WorkOrderLineItemTrigger on WorkOrderLineItem (after insert, after update, before delete) {
    
    private List<ProductItem__c> getAssetList(list<ID> workOrderLineItemList) {
        if (workOrderLineItemList.isEmpty()) return new List<ProductItem__c>();

        List<ProductItem__c> AssetList = [SELECT ID, Reserved__c, Sold__c, Check_In_Type__c
                                                FROM ProductItem__c
                                                WHERE ID in: workOrderLineItemList
                                         		AND Check_In_Type__c != 'Generic'];

        return assetList;
    }
    
   
    
    private Map<ID, WorkOrder> getWOMap(list<ID> WOList) {

        List<WorkOrder> workOrderList = [SELECT ID, Ship_Date__c, Asset2__c, Country, RecordType.DeveloperName, Billing_Type__c
                                                FROM WorkOrder
                                                WHERE ID in: WOList ];
        Map<ID, WorkOrder> WOMap = new Map<ID, WorkOrder>();
        
        for(WorkOrder WOs: workOrderList){
            WOMap.put(WOs.id, WOs);
        }
       
        return WOMap;
    }
    
    
    list<ID> workOrderLineItemList = new list<ID>();
    list<ID> WOList = new list<ID>();
   
    //Setting ID lists to get all work orders and product items.
    if(Trigger.IsInsert || Trigger.IsUpdate){
        for(WorkOrderLineItem wo: Trigger.New){
            if(wo.WorkOrderId != null){
                WOList.add(wo.WorkOrderID);
            }
            if(wo.Part_Used__c != null && (Trigger.IsInsert || (Trigger.IsUpdate && Trigger.oldMap.get(wo.Id).Part_Used__c != wo.Part_Used__c))){
                workOrderLineItemList.add(wo.Part_Used__c);
            }
        
    	}
        system.debug('THIS IS THE WO LIST INSIDE FIRST LOOP >>> ' + WOList);
    }
    if(Trigger.IsDelete){
        for(WorkOrderLineItem wo: Trigger.Old){
            if(wo.WorkOrderId != null){
                WOList.add(wo.WorkOrderID);
            }
        }
    }
    
    
    Map<ID, WorkOrder> workOrderMap = getWOMap(WOList);
    List<ID> deletedAssetList = new list<ID>();
    List<WorkOrder> WOsToUpdate = new list<WorkOrder>();
   
   
    
    //Actual trigger loop
    
    if(Trigger.IsInsert || Trigger.IsUpdate){
         system.debug('THIS IS THE WO LIST INSIDE SECOND LOOP >>> ' + WOList);
        
        system.debug('THIS IS THE WORK ORDER MAP >> ' + workOrderMap);
        for(WorkOrderLineItem woli:Trigger.New){
            WorkOrder WOtoUpdate = workOrderMap.get(woli.WorkOrderId);
            system.debug('THIS IS THE WO TO UPDATE >> ' + WOtoUpdate);
            if(WOtoUpdate != null){
                if(WOtoUpdate.Asset2__c == null){
                WOtoUpdate.Asset2__c = woli.Part_Used__c;
                if(!WOsToUpdate.contains(WOtoUpdate)){
                    WOsToUpdate.add(WOtoUpdate);
                }
            }
            }
            
        }
        system.debug('THIS IS THE FINAL WO LIST TO UPDATE >> ' + WOsToUpdate);
    }

    Set<Id> skipReserveProductItems = new Set<Id>();
    if (Trigger.IsInsert || Trigger.IsUpdate) {
        for (WorkOrderLineItem woli : Trigger.New) {
            if (woli.Part_Used__c == null) continue;
            WorkOrder wo = workOrderMap.get(woli.WorkOrderId);
            if (wo == null) continue;
            String country = wo.Country;
            if ((country == 'United States' || country == 'US')
                    && wo.RecordType != null
                    && wo.RecordType.DeveloperName == 'FSL_Work_Order'
                    && wo.Billing_Type__c != 'Contract'
                    && wo.Billing_Type__c != 'Warranty') {
                skipReserveProductItems.add(woli.Part_Used__c);
            }
        }
    }

    if(Trigger.IsDelete){
        for(WorkOrderLineItem woli:Trigger.Old){
        	WorkOrder wo = workOrderMap.get(woli.WorkOrderId);
            if(wo.Ship_Date__c != null){
                System.debug('You cannot delete an item that has shipped');
            	woli.addError('You cannot delete an item that has shipped');
            }
            
            if(wo.Ship_Date__c == null && woli.Part_Used__c != null){
                deletedAssetList.add(woli.Part_Used__c);
            }
            
    	}
    }
    List<ProductItem__c> assetsToCheck = getAssetList(workOrderLineItemList);
    List<ProductItem__c> assetsToUncheck = getAssetList(deletedAssetList);
    List<ProductItem__c> assetsToUpdate = new List<ProductItem__c>();
    
    for(ProductItem__c p: assetsToCheck){
        if (!skipReserveProductItems.contains(p.Id)) {
            p.Reserved__c = true;
            assetstoUpdate.add(p);
        }
    }
    
    for(ProductItem__c p: assetsToUncheck){
        p.Reserved__c = false;
        assetstoUpdate.add(p);
    }
    
    if(assetstoUpdate.size() != 0){
        update assetstoUpdate;
    }
    if(WOstoUpdate.size() != 0){
        update WOstoUpdate;
    }
    

}