public class P_OppLineItemTriggerHandler  extends GH_TriggerHandlerBase {


    protected override void beforeInsert(){
        System.debug('Not implemented yet');
    }
    protected override void beforeUpdate(){
        System.debug('Not implemented yet');
    }
    protected override void beforeDelete(){
        System.debug('Not implemented yet');
    }
    protected override void afterInsert(){
        System.debug('Not implemented yet');
    }
    protected override void afterUpdate(){
        System.debug('Not implemented yet');
    }
    protected override void afterDelete(){
        System.debug('Not implemented yet');
    }
    protected override void afterUndelete(){
        System.debug('Not implemented yet');
    }
    
     private Map<Id, ProductItem__c> getItemMap(List<Id> assetIds) {
        List<ProductItem__c> itemList = [SELECT Id, Check_In_Type__c, Product2_Name__c, Product_Family__c,
                                                Opportunity_Record_Type__c, Physical_Location__c
                                                FROM ProductItem__c 
                                                WHERE Id in :assetIds 
                                                ORDER BY CreatedDate DESC];
        Map<Id, ProductItem__c> itemMap = new Map<Id, ProductItem__c>();
        for(ProductItem__c n : itemList) {
            itemMap.put(n.id, n);
        }
        return itemMap;
    }

    public void processRecords(List<OpportunityLineItem> newRecs, Map<Id, OpportunityLineItem> oldRecs){
        User theCurrentUser = ProboCommonUtils.getCurrentUser();
        list<id> SalesOppRecordList = new list<id>(); 
             for (RecordType r : ProboCommonUtils.getRecordTypes('Opportunity')){
                 if (r.DeveloperName == 'Sales_Opportunity'|| r.DeveloperName == 'Big_Iron_Sales_Opportunity' || r.DeveloperName == 'C_Arm_Sales_Opportunity'
                    || r.DeveloperName == 'Parts_Sales_Opportunity' || r.DeveloperName == 'Probe_Sales_Opportunity' || r.DeveloperName == 'Rental_Opportunity'
                     || r.DeveloperName == 'Service_Sales_Opportunity'|| r.DeveloperName == 'System_Sales_Opportunity' || r.DeveloperName == 'Equipment_Storage_Rental_Opportunity'){
                    
                     SalesOppRecordList.add(r.id);
                        
                 }
             }
        
        
        Map<Id, ProductItem__c> newItemMap = new Map<Id, ProductItem__c>();
        List<Id> assetIds = new List<Id>();
        for(OpportunityLineItem n: newRecs){
                if(n.ProductItem__c != null){
                    assetIds.add(n.ProductItem__c);
                }
        }
        system.debug('THIS IS THE OLI ASSET LIST >> ' + assetIds);
        newItemMap = getItemMap(assetIds);
        system.debug('THIS IS THE NEW ITEM MAP >> ' + newItemMap);       
        
        /* moving before section to flow 04.23.25 NB
        if(Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {
            
            for(OpportunityLineItem n : newRecs) {
                System.debug('CC...' + n);
                System.debug('CC...' + n.OpportunityId);
                System.debug('CC...' + n.Opportunity_Record_Type_Name__c);
                System.debug('CC...' + n.Owner_Location__c);
                System.debug('CC...' + n.ProductItem__c);
                System.debug('CC...' + n.ProductItem__r.Physical_Location__c);
                System.debug('CC...' + n.ProductItem__r.Opportunity_Record_Type__c);
                if(n.OpportunityId != null && n.Sold__c != null && n.ProductItem__c != null && n.Opportunity_Record_Type_Name__c != null && n.Owner_Location__c != null) {
                    //n.ProductItem__r.Opportunity_Record_Type__c = n.Opportunity_Record_Type_Name__c;
                    //n.ProductItem__r.Physical_Location__c = n.Owner_Location__c;
                } 
                if(n.Asset_is_system__c == false && (n.Product_Family__c == 'Ultrasound System' || n.Product_Family_TXT__c == 'Ultrasound System')) {
                    n.Asset_is_system__c = true;
                }
                boolean changed = false;
                if(Trigger.isUpdate) {
                    OpportunityLineItem oldT = oldRecs.get(n.Id);
                    if(oldT.Product2Id != n.Product2Id || n.ProductItem__c != oldT.ProductItem__c) {
                        changed = true;
                    }
                }
                if(Trigger.isInsert || changed) {
                    system.debug('THIS IS THE INITIAL GET ITEM FROM ITEM MAP >> ' + newItemMap.get(n.ProductItem__c));
                    if(newItemMap.get(n.ProductItem__c) != null){
                        n.Check_In_Type_TXT__c = newItemMap.get(n.ProductItem__c).Check_In_Type__c;
                    	n.Product_Family_TXT__c = newItemMap.get(n.ProductItem__c).Product_Family__c;
                    	n.Model__c = newItemMap.get(n.ProductItem__c).Product2_Name__c;
                    	if(newItemMap.get(n.ProductItem__c).Check_In_Type__c.contains('Vet') || newItemMap.get(n.ProductItem__c).Product2_Name__c.contains('Vet')){
                        	n.Vet_Product__c = true;
                    	}
                    }
                    
                }
                                
            }

        }*/
        
        System.debug('start of non-Delete P_OppLineItemTrigger');

            // if we are just setting the Purchasing_Approved, then we have nothing else to do at this time
            if (GH_CodeUtils.isFlagSet('OLI Purchasing Approved set')){
                GH_Logger.debug('Only called because Purchasing Approved was set');
                for (OpportunityLineItem oli : newRecs){
                    updatePurchasingApproved(oli, oldRecs != null ? oldRecs.get(oli.Id) : null);
                }
                return;
            }

            if (Trigger.isBefore) {

                System.debug('P_OppLineItemTrigger before');
                for (OpportunityLineItem oli : newRecs) {

                    // prevents opp from being Closed Won if product is not purchasing approved or if costs are missing on assets linked to purchasing opp through link on asset page
                    if (oli.Stage__c == 'Closed Won' && oli.Purchasing_Approved__c == false
                            && oli.Opportunity_Record_Type__c != 'Purchasing_Opportunity'
                        	&& oli.Opportunity_Record_Type__c != 'Big_Iron_Purchasing_Opportunity'
                            && oli.Check_In_Type__c != 'Customer Repair'
                            && oli.Check_In_Type__c != 'Warranty Repair'
                            && oli.Check_In_Type__c != 'Vet – Customer Repair'
                            && oli.Check_In_Type__c != 'Vet – Warranty Repair'
                            && oli.Check_In_Type__c != 'Generic') {

                        oli.addError('Not possible because product is not purchasing approved');
                    }

                    if (oli.Stage__c == 'Closed Won' && oli.Cost__c == null
                            && (oli.Opportunity_Record_Type__c == 'Purchasing_Opportunity' || oli.Opportunity_Record_Type__c == 'Big_Iron_Purchasing_Opportunity')) {

                        oli.addError('Not possible because assets are missing cost information');
                    }

                    updatePurchasingApproved(oli, Trigger.isUpdate ? oldRecs.get(oli.Id) : null);
                    
                }
            } else { // isAfter Insert and Update

                System.debug('P_OppLineItemTrigger after');

                // new code to fix issue with sales price not being updated on asset page 08/14/18
                // this is only used in the After trigger
                Map<Id, Id> oliIDtoProductItemId = new Map<Id, Id>();
                Map<Id, Boolean> pItemIdToPurchApprovedValue = new Map<Id, Boolean>();
                Map<Id, ProductItem__c> productItemsToUpdateMap = new Map<Id, ProductItem__c>();
                List<ProductItem__c> items = new List<ProductItem__c>();
                Map<Id, List<String>> itemMap = new Map<Id, List<String>>();
                Integer counter = 0;
                for (OpportunityLineItem oli : newRecs) {
                    System.debug('CC...counter: ' + counter);
                    System.debug('CC...' + oli.OpportunityId);
                    System.debug('CC...' + oli.Opportunity_Record_Type_Name__c);
                    System.debug('CC...' + oli.Owner_Location__c);
                    System.debug('CC...' + oli.ProductItem__c);
                    System.debug('CC...' + oli.ProductItem__r.Id);
                    System.debug('CC...' + oli.ProductItem__r.Opportunity_Record_Type__c);
                    if(oli.OpportunityId != null && oli.Sold__c != null && oli.ProductItem__c != null && oli.Opportunity_Record_Type_Name__c != null && oli.Owner_Location__c != null) {
                        List<String> oppList = new List<String>();
                        oppList.add(oli.Opportunity_Record_Type_Name__c);
                        oppList.add(oli.Owner_Location__c);
                        itemMap.put(oli.ProductItem__c, oppList);
                        if(!items.contains(newItemMap.get(oli.ProductItem__c))){
                            items.add(newItemMap.get(oli.ProductItem__c));
                        }
                        
                        
                    } 
                    if (oli.ProductItem__c != null){
                        System.debug('Adding ProductItem__r from this OLI: ' + oli.Id + ' ProductItem ID: ' + oli.ProductItem__c);
                        oliIDtoProductItemId.put(oli.Id, oli.ProductItem__c);
                        // this is the replacement logic for the PB Update Processing Approved
                        Id pItemIdToUpdate = updatePurchasingApproved(oli, Trigger.isUpdate ? oldRecs.get(oli.Id) : null);
                        if (pItemIdToUpdate != null) {
                            pItemIdToPurchApprovedValue.put(pItemIdToUpdate, oli.Purchasing_Approved__c);
                        }
                        
                    }
                    counter++;
                }
                
               /* items = [SELECT Opportunity_Record_Type__c, Physical_Location__c
                            FROM ProductItem__c
                            WHERE Id in :itemMap.keySet()];*/
                
                for(ProductItem__c item : items) {
                    System.debug('CC...228' + item.Id);
                    item.Opportunity_Record_Type__c = itemMap.get(item.Id)[0];
                    item.Physical_Location__c = itemMap.get(item.Id)[1];
                    productItemsToUpdateMap.put(item.Id, item); //update items outside of loop
                }
                //update items; removing update items inside loop 07.24.23
                System.debug('Getting the ProductItems related to the OppLines: ' + oliIDtoProductItemId.values());
                Map<Id, ProductItem__c> pItemIDsToPItems = new Map<Id, ProductItem__c>([SELECT Id, Serial_No__c,
                        Purchasing_Approved__c, Purchasing_Approval_Time__c
                FROM ProductItem__c
                WHERE Id IN :oliIDtoProductItemId.values()]);

                
                // if any are on PurchaseApproved OLIs, set the PItem PurchasedApproved fields
                for (ProductItem__c pItem : pItemIDsToPItems.values()){
                    if (pItemIdToPurchApprovedValue.containsKey(pItem.Id)){
                        if (pItem.Purchasing_Approved__c != pItemIdToPurchApprovedValue.get(pItem.Id)){
                            System.debug('Setting ProductItem Purchasing_Approved for ' + pItem.Id);
                            pItem.Purchasing_Approved__c = pItemIdToPurchApprovedValue.get(pItem.Id);
                            productItemsToUpdateMap.put(pItem.Id, pItem);
                        }
                    }
                }

                //FOR NATALIE MAKE SURE THIS IS OK
                Map<Id, String> oppIDToSerialNum = new Map<Id, String>();

                for (OpportunityLineItem oli : newRecs) {

                    System.debug('Working with OLI: ' + oli);

                    System.debug('This line has a related ProductItem: ' + oliIDtoProductItemId.containsKey(oli.Id));

                    if (oliIDtoProductItemId.containsKey(oli.Id) && oliIDtoProductItemId.get(oli.Id) != null) {

                        ProductItem__c UpdatedAsset = pItemIDsToPItems.get(oliIDtoProductItemId.get(oli.Id));

                        Boolean needToUpdate = false;

                        System.debug('The OLI Stage is: ' + oli.Stage__c);
                        // new code to fix issue with sales price not being updated on asset page 08/14/18
                        if (oli.Stage__c == 'Closed Won' && oli.Ship_Date__c != null) {

                            System.debug('The OLI Unit Price is: ' + oli.UnitPrice);
                            System.debug('The Sales Price Has to be updated? ' + (Trigger.isInsert || (oli.UnitPrice != oldRecs.get(oli.Id).UnitPrice)));

                            // TODO: Natalie to ask Zach what to do if a non-0 OLI changes to 0 after ClosedWon
                            if (oli.UnitPrice != 0 && (Trigger.isInsert || (oli.UnitPrice != oldRecs.get(oli.Id).UnitPrice))) {
                                UpdatedAsset.Sales_Price__c = oli.UnitPrice;
                                needToUpdate = true;
                            }
                        }

                        if (needToUpdate) {
                            System.debug('Adding ProductItem to be updated: ' + UpdatedAsset);
                            productItemsToUpdateMap.put(UpdatedAsset.Id, UpdatedAsset);
                        }

                        //FOR NATALIE MAKE SURE THIS IS OK
                        if (Trigger.isInsert && (oli.Check_In_Type__c != 'Generic') && UpdatedAsset.Serial_No__c != null){
                            System.debug('If the OLI is being inserted and its Check_in_Type is not Generic, see if we need to update the Opp Name');
                            if (!oppIDToSerialNum.containsKey(oli.OpportunityId)){
                                System.debug('Adding Opp ID and Asset Serial_No__c entry');
                                oppIDToSerialNum.put(oli.OpportunityId, UpdatedAsset.Serial_No__c);
                            }
                        }
                        // TO DO NATALIE 08.11.24
                        /*if (oli.Name.contains('Storage Bay') && oli.UnitPrice != 0 && (Trigger.isInsert || (oli.UnitPrice != oldRecs.get(oli.Id).UnitPrice))) {
                        	
                        
                        }*/
                        
                    }
                }

                List<Opportunity> oppsToUpdate = new List<Opportunity>();
				
                
                if (!oppIDToSerialNum.isEmpty()){
                    System.debug('We might have to update Opp Names for Serial_No__c');
                    Set<Id> oppIDsWeAlreadyFound = new Set<Id>();
                    for (Opportunity opp : [SELECT Id, Name FROM Opportunity WHERE Id IN :oppIDToSerialNum.keySet()]){
                        // TODO: replace Name check with a flag that will be set in call to newWarrantyOpp()
                        if (opp.Name.endsWithIgnoreCase('WARRANTY SN #') && !oppIDsWeAlreadyFound.contains(opp.Id)){
                            System.debug('Found a Warranty Opp to update Name to include Serial_Number: ' + opp.Id + '(' + oppIDToSerialNum.get(opp.Id) + ')');
                            opp.Name = opp.Name + oppIDToSerialNum.get(opp.Id);
                            System.debug('Opp Name is now: ' + opp.Name);
                            oppsToUpdate.add(opp);
                            oppIDsWeAlreadyFound.add(opp.Id);
                        }
                    }
                }

                RecordType CORErt;
                for (RecordType rt : ProboCommonUtils.getRecordTypes('RMA__c')) {
                    if (rt.IsActive && rt.Name == 'Core Exchange') {
                        CORErt = rt;
                        break;
                    }
                }



                Set<Id> oppIdsNeeded = new Set<Id>();
				
                // generate a core exchange RMA if the exchange box is checked on the opportunity product
                for (OpportunityLineItem ol : newRecs) {
                    
                    if (ol.Exchange__c
                            && (Trigger.isInsert
                            || oldRecs.get(ol.Id).Exchange__c != ol.Exchange__c)) {
                        oppIdsNeeded.add(ol.OpportunityId);
                    }
                }
				
                List<RMA__c> rmasToInsert = new List<RMA__c>();

                if (!oppIdsNeeded.isEmpty()){

                    Map<Id, Opportunity> oppInfo = new Map<Id, Opportunity>();
                    oppInfo = new Map<Id, Opportunity>([SELECT Id, RecordTypeId FROM Opportunity WHERE Id IN :oppIdsNeeded]);
					
                    for (OpportunityLineItem ol : newRecs) {
                        if (SalesOppRecordList.contains(oppInfo.get(ol.OpportunityId).RecordTypeId)) {
                            system.debug('THIS IS THE OLI INSIDE CORE RMA LOOP >>> ' + ol);
                            if (ol.Exchange__c && ol.Stage__c == 'Closed Won') {
								system.debug('This is inserting the Core exchange based on OLI exchange checkbox');
                                RMA__c CoreRMA = new RMA__c(RecordTypeId = CORErt.Id, Opportunity__c = ol.OpportunityId, Probe_Model_Text__c = ol.Product_Name__c,
                                        ProductItem__c = ol.ProductItem__c, RMA_Item_Serial_Number__c = ol.Serial_No__c);

                                rmasToInsert.add(CoreRMA);
                            }
                        }
                    }
                }

                System.debug('Updating this many Opps (Name with Serial No): ' + oppsToUpdate.size());
                if (!oppsToUpdate.isEmpty()) {
                    Validator_Class.SetByPassOppTrigger(true);
                    system.debug('OPP UPDATE FROM INSIDE OLI TRIGGER >> ' + oppsToUpdate);
                    DatabaseService.updateList(oppsToUpdate);
                    
                    Validator_Class.SetByPassOppTrigger(false);
                }

                // new code to fix issue with sales price not being updated on asset page 08/14/18
                System.debug('Updating this many Assets: ' + productItemsToUpdateMap.size());
                if (!productItemsToUpdateMap.isEmpty()) {
                    system.debug('PRODUCT ITEM UPDATE FROM INSIDE OLI TRIGGER >> ' + productItemsToUpdateMap);
                    Validator_Class.SetByPassProductItemTrigger(true);
                    DatabaseService.updateList(productItemsToUpdateMap.values());
                    Validator_Class.SetByPassProductItemTrigger(false);
                    
                }

                System.debug('Inserting this many RMAs: ' + rmasToInsert.size());
                if (!rmasToInsert.isEmpty()) {
                    DatabaseService.insertList(rmasToInsert);
                }
                
                

            }



    }

    private Id updatePurchasingApproved(OpportunityLineItem newRec, OpportunityLineItem oldRec){

        // will only return an ID if the Purchasing_Approved changed in a meaningful way
        Id recIdForOtherUpdates;

        // if Purchasing_Approved is set on Insert
        // or is it being changed, set the date
        if ((Trigger.isInsert && newRec.Purchasing_Approved__c)
                || (Trigger.isUpdate && (newRec.Purchasing_Approved__c != oldRec.Purchasing_Approved__c))) {

            // only set the Purchasing_Approval_Time__c if the Purchasing_Approved is just going to 'true'
            if (Trigger.isBefore && newRec.Purchasing_Approved__c) {
                newRec.Purchasing_Approval_Time__c = Datetime.now();
            }

            if (newRec.ProductItem__c != null){
                recIdForOtherUpdates = newRec.ProductItem__c;
            }
        }

        return recIdForOtherUpdates;
    }
}