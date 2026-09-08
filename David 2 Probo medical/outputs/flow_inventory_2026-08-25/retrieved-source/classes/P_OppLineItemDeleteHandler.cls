public class P_OppLineItemDeleteHandler {
	// This prevents anyone from deleting an OLI from an opp that is in the stage of Closed Won with a ship date and invoice.
    public void doBeforeDeleteWork(Map<Id, OpportunityLineItem> oldRecs) {
        for (OpportunityLineItem OLI : oldRecs.values()) {
            if (oli.Stage__c == 'Closed Won' && oli.Ship_Date__c != null && oli.Invoice__c != null) {
                oli.addError('You can not delete asset from a Closed Won Opportunity !');
            }
        }
    }
    public void doAfterDeleteWork(Map<Id, OpportunityLineItem> oldRecs) {
       
        System.debug('P_OppLineItemTrigger after Delete');
        
        Set<Id> pItemIdsToGet = new Set<Id>();
        Set<Id> soldpItems = new Set<Id>();
        Set<Id> reservedpItems = new Set<Id>();
        
        for (OpportunityLineItem oli : oldRecs.values()) {
            system.debug('THIS IS THE ITEM IN OLI OLD RECS >>> ' + oli);
            if (oli.Check_In_Type__c != 'Generic' && oli.ProductItem__c != null) {
                pItemIdsToGet.add(oli.ProductItem__c);
                if(oli.Stage__c == 'Closed Won' && oli.Ship_Date__c != null){
                    soldpItems.add(oli.ProductItem__c);
                    system.debug('OLI ADDED TO SOLD ITEM LIST');
                }
                if (oli.Stage__c == 'Verbal Acceptance' || oli.Stage__c == 'Probe Loan' || oli.Stage__c == 'Sold but not shipped' || 
                    oli.Stage__c == 'PO Received' || oli.Stage__c == 'Sourcing' || oli.Stage__c == 'Finalize Transaction' || 
                    oli.Stage__c == 'External Repair/Testing' || oli.Stage__c == 'Equipment Rental' || 
                     (oli.Stage__c == 'Closed Won'&& oli.Ship_Date__c == null)) {
                        reservedpItems.add(oli.ProductItem__c);
                        system.debug('OLI ADDED TO RESERVED ITEM LIST');
                    }
            }
        }
        System.debug('CC... pItemIdsToGet' +  pItemIdsToGet);
        if (!pItemIdsToGet.isEmpty()) {
            
            List<ProductItem__c> pItems = new List<ProductItem__c>([
                SELECT Id, Reserved__c, sold__c, Sales_Price__c, Location__c, Sub_Location__c
                FROM ProductItem__c
                WHERE Id IN :pItemIdsToGet
            ]);
            
            System.debug('Found this many ProductItems: ' + pItems);
            
            // get all the other OLIs for each ProductItem__c (any in the current trigger will not show up in the SOQL)
            Map<Id, List<OpportunityLineItem>> pItemIdToOLIList = new Map<Id, List<OpportunityLineItem>>();
            
            for (OpportunityLineItem r : [SELECT Id, ProductItem__c, Stage__c, UnitPrice, Ship_Date__c, ProductItem__r.Location__c, ProductItem__r.Sub_Location__c, OpportunityId FROM OpportunityLineItem WHERE ProductItem__c = :pItemIdsToGet]) {
                
                if (!pItemIdToOLIList.containsKey(r.ProductItem__c)) {
                    pItemIdToOLIList.put(r.ProductItem__c, new List<OpportunityLineItem>());
                }
                pItemIdToOLIList.get(r.ProductItem__c).add(r);
            }
            
            System.debug('check to see if ProductItems are on another oppLine >>> ' + pItemIdToOLIList);
            
            Map<Id, ProductItem__c> itemlistToUpdateMap = new Map<Id, ProductItem__c>();
            
            for (ProductItem__c thispItem : pItems) {
                System.debug('Working on pItem: ' + thispItem);
                
                String reservedValueToUse = '';
                String soldValueToUse = '';
                Double itemPriceToUse = null;
                if(reservedpItems.contains(thispItem.id)){
                    reservedValueToUse = 'no';
                }
                system.debug('SoldpItems: '+soldpItems);
                if(soldpItems.contains(thispItem.id)){
                    system.debug('soldValueToUse = no');
                    soldValueToUse = 'no';
                }
                
                // if this ProdItem is on another LineItem, see if it is still OK to reset it
                if (pItemIdToOLIList.containsKey(thispItem.Id)) {
                    
                    for (OpportunityLineItem oli : pItemIdToOLIList.get(thispItem.Id)) {
                        
                        System.debug('Looking at OLI: ' + oli);
                        System.debug('OLI Stage is: ' + oli.Stage__c);
                        
                        if (oli.Stage__c == 'Verbal Acceptance' || oli.Stage__c == 'Probe Loan' || oli.Stage__c == 'Sold but not shipped' || 
                            oli.Stage__c == 'PO Received' || oli.Stage__c == 'Sourcing' || oli.Stage__c == 'Finalize Transaction' ||
                            oli.Stage__c == 'External Repair/Testing' || oli.Stage__c == 'Equipment Rental'
                            || (oli.Stage__c == 'Closed Won'&& oli.Ship_Date__c == null)) {
                                reservedValueToUse = 'yes';
                            } /* // THIS CODE SECTION WAS CAUSING ISSUES WITH PREVIOUS CLOSED WON OPPS MARKING ITEMS AS SOLD. SHOULD NEVER BE ON TWO ACTIVE CLOSED WON OPPS.
                            else if (oli.Stage__c == 'Closed Won' && oli.Ship_Date__c != null) { 
                            // TODO: Natalie - thinks there might be an exception if Check_In_Type__c != 'Customer Repair' OR 'Warranty Repair'
                            soldValueToUse = true;
                            
                            
                            Validator_Class.setFlag('Product_Item Sold on ClosedWon');
                            Validator_Class.setAlreadyDone4();
                            itemPriceToUse = oli.UnitPrice;
                            } */
                        
                    }
                }
                
                System.debug('This ProductItem Reserved value to use: ' + reservedValueToUse);
                System.debug('This ProductItem Sold value to use: ' + soldValueToUse);
                
                Boolean doUpdate = false;
                
                if (reservedValueToUse != null){
                    if(reservedValueToUse == 'yes' && !thispItem.Reserved__c) {
                        thispItem.Reserved__c = true;
                        doUpdate = true;
                    }
                    if(reservedValueToUse == 'no' && thispItem.Reserved__c) {
                        thispItem.Reserved__c = false;
                        doUpdate = true;
                    }
                }
                
                system.debug('Item Sold? = '+thispItem.sold__c);
                system.debug('soldValueToUse = '+soldValueToUse);
                if (soldValueToUse != null){
                    if(soldValueToUse == 'no' && (thispItem.sold__c || thispItem.Sales_Price__c != null)) {
                        system.debug('SetSalesPriceToNull');
                        thispItem.sold__c = false;
                        thispItem.Sales_Price__c = null;
                        system.debug('pitemsalesprice: '+thispItem.Sales_Price__c);
                        doUpdate = true;
                    }
                }
                
                // THIS SECTION SHOULD NOT BE FOR SOMETHING BEING DELETED
                /*
                if (!soldValueToUse && thispItem.Sales_Price__c != null){
                thispItem.Sales_Price__c = null;
                doUpdate = true;
                } else if (soldValueToUse && (thispItem.Sales_Price__c != itemPriceToUse)){
                thispItem.Sales_Price__c = itemPriceToUse;
                doUpdate = true;
                }*/
                
                if (doUpdate){
                    itemlistToUpdateMap.put(thispItem.Id, thispItem);
                }
            }
            
            System.debug('Updating this many pItems: ' + itemlistToUpdateMap.size());
            if (!itemlistToUpdateMap.isEmpty()) {
                DatabaseService.updateList(itemlistToUpdateMap.values());
            }
            
        }
        
    
    }
}