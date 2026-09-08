public class P_ProductItemTriggerHandler extends GH_TriggerHandlerBase {

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
    
      private Map<Id, Id> getProductMap(List<Id> productAnalyticsIds) {
        List<Product2> productList = [SELECT Id, IsActive, Product_Analytics__c 
                                                FROM Product2 
                                                WHERE IsActive = true AND 
                                                      Product_Analytics__c in :productAnalyticsIds 
                                                ];
        Map<Id, Id> productMap = new Map<Id, Id>();
        for(Product2 prod : productList) {
            productMap.put(prod.Product_Analytics__c, prod.Id);
        }
        return productMap;
    }
    
    private Map<Id, Id> getProductAnalyticsMap(List<Id> productIds) {
        List<Product_Analytics__c> productAnalyticsList = [SELECT Id, Product__c 
                                                FROM Product_Analytics__c
                                                WHERE Product__c in :productIds 
                                                ];
        Map<Id, Id> productAnalyticsMap = new Map<Id, Id>();
        for(Product_Analytics__c prodAnalytics : productAnalyticsList) {
            productAnalyticsMap.put(prodAnalytics.Product__c, prodAnalytics.Id);
        }
        return productAnalyticsMap;
    }
    
    private String getUserLocation(Id currentUserId) {
        User currentUser = [SELECT Id, Location__c, Entity__c 
                                                FROM User 
                                                WHERE Id =: currentUserId 
                                                ];
        String currentEntity = '';
        if(currentUser.Entity__c != null){
            currentEntity = currentUser.Entity__c;
        }
        return currentEntity;
    }

    public void processRecords(List<ProductItem__c> newRecs,  Map<Id, ProductItem__c> newRecMap, Map<Id, ProductItem__c> oldRecs){
        String debug = '';
        if(Trigger.isbefore) {
            debug = 'CC...before';
        } else {
            debug = 'CC...after';
        }
        if(Trigger.isInsert) {
            debug += ' Insert ';
        } else {
            debug += ' Update ';
        }

        System.debug(debug + 'Start of P_ProductItemTrigger' );
        List<ProductItem__c> updateItems = new List<ProductItem__c>();
        List<Id> updateTestPriority = new List<Id>();
        Integer returnDays;

        //No. of Days Until Due Date Calculation
        // TODO: Move this check down into the loop so a mix of added and not-added can be processed
        // This field is never manually 'checked', so the only time this is set is as a result of a trigger

        Boolean addedtoworkorder = false;
        List<Id> prodIds = new List<Id>();
        List<Id> prodAnalyticsIds = new List<Id>();
        for (ProductItem__c item : newRecs) {
            if(item.Product_Name__c != null){
                prodIds.add(item.Product_Name__c);
            }
            
            if(item.Product_Analytics__c != null){
                prodAnalyticsIds.add(item.Product_Analytics__c);
            }
        }
        system.debug('THIS IS THE TOTAL PROD IDS >> ' + prodIds + ' AND PRODUCT ANALYTIC IDS >> ' + prodAnalyticsIds);
        Map<Id, Id> prodMap = getProductMap(prodAnalyticsIds);
        Map<Id, Id> prodAnalyticsMap = getProductAnalyticsMap(prodIds);
        system.debug('THIS IS THE PROD MAP >> ' + prodMap + ' AND PRODUCT ANALYTIC MAP >> ' + prodAnalyticsMap);
            
        
        for (ProductItem__c p : newRecs) {

            if (p.Added_to_Work_Order__c == true
                    && (Trigger.isInsert || oldRecs.get(p.Id).Added_to_Work_Order__c == false)) {
                addedtoworkorder = true;
            }

            //Logic copied from PB Assets2  
            if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
                ProductItem__c oldItem = null;
                if(Trigger.isUpdate) {
                    oldItem = oldRecs.get(p.Id);
                }
                List<String> properties = new List<String>{'Date_Last_Test_Completed__c','Last_Cosmetic_Repair_Date__c','Functional_Rating__c','Cosmetic_Rating__c'};
                if((Trigger.isInsert || Delegate_ObjUntils.CheckPropertyChanged(p, oldItem,properties)) && p.Date_Last_Test_Completed__c > p.Last_Cosmetic_Repair_Date__c && p.Functional_Rating__c != null && p.Cosmetic_Rating__c != null) {
                    p.QC_Bump__c = false;
                }
                properties = new List<String>{'Image__c'};
                if((Trigger.isInsert || Delegate_ObjUntils.CheckPropertyChanged(p, oldItem,properties)) && p.Image__c != null && p.Image__c.length() > 43) {
                    String baseUrl = 'https://drive.google.com/open?id=';
                    String piUrlString = p.Image__c.substring(43, p.Image__c.length());
                    String updatedUrl = baseUrl + piUrlString;
                    p.Image_Link_for_Customer_Portal__c = updatedUrl;
                }
                properties = new List<String>{'Vendor_Name__c'};
                if((Trigger.isInsert || Delegate_ObjUntils.CheckPropertyChanged(p, oldItem,properties)) && p.Vendor_Name__c != null && p.Vendor_Name__c.contains('Ambassador')) {
                    p.Domestic_Only__c = true;
                }
                properties = new List<String>{'Product_Name__c'};
                if(p.Product_Name__c != null && (Trigger.isInsert || Delegate_ObjUntils.CheckPropertyChanged(p, oldItem,properties))) {
                    system.debug('THIS IS THE PRODUCT ANALYTICS FIELD >> ' + p.Product_Name__c + ' AND MAP >> ' + prodAnalyticsMap.get(p.Product_Name__c));
                    if(Trigger.IsUpdate){
                        system.debug('THIS IS THE PRODUCT NAME FIELD OLD >> ' + oldItem.Product_Name__c);
                    }
                    
                    // rewrite field if null OR if Product Analytics doesn't match Product ONLY IF product analytics field was not manually changed by user
                    if(p.Product_Analytics__c == null || (Trigger.IsUpdate && (p.Product_Analytics__c != prodAnalyticsMap.get(p.Product_Name__c) && p.Product_Analytics__c == oldItem.Product_Analytics__c))){
                        p.Product_Analytics__c = prodAnalyticsMap.get(p.Product_Name__c);
                    }
                }
                properties = new List<String>{'Product_Analytics__c'};
                if(p.Product_Analytics__c != null && (Trigger.isInsert || Delegate_ObjUntils.CheckPropertyChanged(p, oldItem,properties))) {
                    system.debug('THIS IS THE PRODUCT NAME FIELD >> ' + p.Product_Analytics__c + ' AND MAP >> ' + prodMap.get(p.Product_Analytics__c));
                    if(Trigger.IsUpdate){
                        system.debug('THIS IS THE PRODUCT NAME FIELD OLD >> ' + oldItem.Product_Analytics__c);
                    }
                    
                    // rewrite field if null OR if Product doesn't match Product Analytics ONLY IF product name field was not manually changed by user
                    if(p.Product_Name__c == null || (Trigger.isUpdate && (p.Product_Name__c != prodMap.get(p.Product_Analytics__c) && p.Product_Name__c == oldItem.Product_Name__c))){
                        p.Product_Name__c = prodMap.get(p.Product_Analytics__c);
                    }
                }
                
                if(Trigger.isInsert && p.Entity__c == null){
                    p.Entity__c = getUserLocation(UserInfo.getUserId());
                }
                
                
            }
        }
        System.debug('added to WO: ' + addedtoworkorder);

        
        if (addedtoworkorder == false && Validator_Class.hasAlreadyDone17() < 3) {

            // all of the following was in the existing trigger before we added beforeInsert
            // which means it is not needed on beforeInsert
            Map<Id, List<OpportunityLineItem>> oppIdToOLIs = new Map<Id, List<OpportunityLineItem>>();
            Map<Id, List<ProductItem__c>> oppIdToPItems = new Map<Id, List<ProductItem__c>>();
            Set<Id> oppIds = new Set<Id>();
            Set<Id> productIds = new Set<Id>();

            if (Trigger.isAfter || (Trigger.isBefore && Trigger.isUpdate)) {

                Set<Id> pItemIDsForLineItems = new Set<Id>();

                for (ProductItem__c item : newRecs) {
                    system.debug('PURCHASING OPPORTUNITY: '+ item.Purchasing_Opportunity__c);
                    String PurchasingOppId = item.Purchasing_Opportunity__c;
                    if (item.Purchasing_Opportunity__c != null && !String.isBlank(PurchasingOppId) && PurchasingOppId.length()>0) {
                        system.debug('Added Purchasing Opportuntiy: '+item.Purchasing_Opportunity__c);
                        productIds.add(item.Product_Name__c);
                        oppIds.add(item.Purchasing_Opportunity__c);
                    }

                    // this is the replacement logic for the PB Update Processing Approved
                    // if an ID is returned, then the conditions are met where we have to update the OLI
                    Id IdToUpdateOLIs = updatePurchasingApproved(item, Trigger.isUpdate ? oldRecs.get(item.Id) : null);
                    if (IdToUpdateOLIs != null) {
                        pItemIDsForLineItems.add(IdToUpdateOLIs);
                    }
                }

                if (!oppIds.isEmpty() || !pItemIDsForLineItems.isEmpty()) {

                    List<OpportunityLineItem> oliForPurchasingApproved = new List<OpportunityLineItem>();

                    // TODO: why are we getting all Lines for the Opps, not just the lines for the trigger ones?
                    for (OpportunityLineItem oli : [
                            select Id, Product2Id, OpportunityId, Product_Name__c, ProductItem__c,
                                    Probo_s_Offer__c, Check_In_Type__c, Quantity, Purchasing_Approved__c
                            from OpportunityLineItem
                            where OpportunityId in :oppids
                            OR ProductItem__c in :pItemIDsForLineItems
                            ORDER BY Probo_s_Offer__c DESC
                    ]) {

                        if (oppIds.contains(oli.OpportunityId)) {
                            if (!oppIdToOLIs.containsKey(oli.OpportunityId)) {
                                oppIdToOLIs.put(oli.OpportunityId, new List<OpportunityLineItem>());
                            }
                            oppIdToOLIs.get(oli.OpportunityId).add(oli);
                        }

                        // do we need to update the Purchasing_Approved__c field
                        // and also the WFR Update Purchasing Approval Time
                        if (pItemIDsForLineItems.contains(oli.ProductItem__c)
                                && newRecMap.get(oli.ProductItem__c).Purchasing_Approved__c != oli.Purchasing_Approved__c) {
                            oli.Purchasing_Approved__c = newRecMap.get(oli.ProductItem__c).Purchasing_Approved__c ;
                            oliForPurchasingApproved.add(oli);
                        }
                    }

                    if (!oliForPurchasingApproved.isEmpty() && Trigger.isAfter){
                        GH_Logger.debug('Updating OLIs as Purchasing_Approved');
                        GH_CodeUtils.setFlag('OLI Purchasing Approved set');
                        system.debug('OLI UPDATE FROM INSIDE PRODUCT ITEM TRIGGER >> ' + oliForPurchasingApproved);
                        DatabaseService.updateList(oliForPurchasingApproved);
                        
                        GH_CodeUtils.clearFlag('OLI Purchasing Approved set');
                    }

                    // only do this if we have Opps
                    if (!oppIds.isEmpty()){

                        // TODO: why are we getting all ProductItems for the Opps instead of just the trigger ones? - BW added criteria for product specific search
                        for (ProductItem__c pItem : [
                                select Id, Rating_Points__c, Cost__c, Product2_Name__c, sold__c,
                                        Probo_s_Offer__c, Purchasing_Opportunity__c
                                from ProductItem__c
                                where Purchasing_Opportunity__c in :oppIds AND Product_Name__c in :productIds
                                ORDER BY Rating_Points__c
                        ]) {

                            if (!oppIdToPItems.containsKey(pItem.Purchasing_Opportunity__c)) {
                                oppIdToPItems.put(pItem.Purchasing_Opportunity__c, new List<ProductItem__c>());
                            }
                            oppIdToPItems.get(pItem.Purchasing_Opportunity__c).add(pItem);
                        }
                    }
                }
            }

            if (Trigger.isBefore) {

                System.debug('Checking all updates from old WFR FUs');
                for (ProductItem__c item : newRecs) {
                    // Removed automatically marking purchasing approved as true for harvested parts, but left in process for Component. 08.11.24
                    if (item.Check_In_Type__c == 'Harvested' && item.Product_Family__c != null
                            && item.Product_Family__c.containsIgnoreCase('Component')
                            && !item.Purchasing_Approved__c) {
                        item.Purchasing_Approved__c = true;
                    }

                    if (item.Location__c == 'Scrap') {
                        item.Cosmetic_Rating__c = 'Scrap';
                        item.Functional_Rating__c = 'Scrap';
                        item.Sold__c = true;
                    }

                    if (item.Reserved__c
                            && (Trigger.isInsert || (item.Reserved__c != oldRecs.get(item.Id).Reserved__c))) {
                        item.Reserved_Time_Stamp__c = DateTime.now();
                        item.Reserved_By__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
                    }

                    if ((item.Sold__c && Trigger.isInsert)
                            || (Trigger.isUpdate && item.Sold__c != oldRecs.get(item.Id).sold__c)) {
                        item.Time_Stamp_Sold__c = DateTime.now();
                        item.Sold_Box_Changed_By__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
                    }

                    // JMAY 20190130 - change to handling Warranty_Start_Date
                    if (item.Vendor_Warranty_Length__c != null && item.Vendor_Warranty_Start_Date__c == null) {
                        item.Vendor_Warranty_Start_Date__c = item.Receive_date__c;
                    }

                    if (item.Decontamination_Complete__c
                            && (Trigger.isInsert || item.Decontamination_Complete__c != oldRecs.get(item.Id).Decontamination_Complete__c)) {
                        item.Time_Decontamination_Completed__c = DateTime.now();
                    }

                    if (item.Check_In_Type__c == 'Core Exchange' && !item.Purchasing_Approved__c) {
                        item.Purchasing_Approved__c = true;
                    }

                    updatePurchasingApproved(item, Trigger.isUpdate ? oldRecs.get(item.Id) : null);

                    if (item.Added_to_Work_Order__c
                            && (Trigger.isInsert || item.Added_to_Work_Order__c != oldRecs.get(item.Id).Added_to_Work_Order__c)) {
                        item.Time_Stamp_Work_Order_Status_Changed__c = DateTime.now();
                    }

                    if (Trigger.isInsert) {
                        if (item.Original_Condition_New__c) {
                            item.Functional_Rating__c = 'Good - New';
                            item.Cosmetic_Rating__c = 'Good - New';
                            item.Review_Status__c = 'Finished Goods';
                        }
                    }

                    if (item.Posted_on_Ebay__c
                            && (Trigger.isInsert || item.Posted_on_Ebay__c != oldRecs.get(item.Id).Posted_on_Ebay__c)) {
                        item.Posted_on_Ebay_Timestamp__c = DateTime.now();
                        item.Posted_on_Ebay_By__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
                    }
                }

                if (Trigger.isUpdate) {

                    List<ProductItem__c> pItemsToUpdate = new List<ProductItem__c>();

                    // Build PricingMaps once per (oppId|productName) — avoids rebuilding identically for each trigger item
                    Map<String, Map<Integer, Decimal>> pricingMapByKey = new Map<String, Map<Integer, Decimal>>();
                    Map<String, Integer> placementCountByKey = new Map<String, Integer>();
                    for (Id oppId : oppIdToOLIs.keySet()) {
                        for (OpportunityLineItem line : oppIdToOLIs.get(oppId)) {
                            System.debug('THIS IS THE OLI LINE FOR PRICING MAP >> ' + line.Product_Name__c);
                            if (line.Check_In_Type__c == 'Generic') {
                                String key = String.valueOf(oppId) + '|' + line.Product_Name__c;
                                if (!pricingMapByKey.containsKey(key)) {
                                    pricingMapByKey.put(key, new Map<Integer, Decimal>());
                                    placementCountByKey.put(key, 0);
                                }
                                Map<Integer, Decimal> pm = pricingMapByKey.get(key);
                                Integer slotCount = placementCountByKey.get(key);
                                system.debug('PRICING MAP BY KEY SET UP FOR >> ' + line + ' >> ' + key);
                                for (Integer i = 0; i < line.Quantity; i++) {
                                    slotCount += 1;
                                    pm.put(slotCount, line.Probo_s_Offer__c);
                                }
                                system.debug('CURRENT PRICING MAP BY KEY >> ' + pm);
                                placementCountByKey.put(key, slotCount);
                            }
                        }
                    }

                    for (ProductItem__c item : newRecs) {

                        ProductItem__c OldItem = oldRecs.get(item.Id);
                        if ((item.Purchasing_Opportunity__c != null && OldItem.Purchasing_Opportunity__c == null)
                                || (item.Purchasing_Opportunity__c != null && OldItem.Initial_Functional_Rating__c != item.Initial_Functional_Rating__c)
                                || (item.Purchasing_Opportunity__c != null && OldItem.Initial_Cosmetic_Rating__c != item.Initial_Cosmetic_Rating__c)) {

                            Validator_Class.setAlreadyDone17();

                            String pricingKey = item.Purchasing_Opportunity__c + '|' + item.Product2_Name__c;
                            Map<Integer, Decimal> PricingMap = pricingMapByKey.containsKey(pricingKey)
                                    ? pricingMapByKey.get(pricingKey)
                                    : new Map<Integer, Decimal>();
							System.debug('THIS IS THE PRICING MAP >> ' + PricingMap);
                            List<ProductItem__c> AssetList = new List<ProductItem__c>();
                            if (oppIdToPItems.containsKey(item.Purchasing_Opportunity__c)) {
                                AssetList = oppIdToPItems.get(item.Purchasing_Opportunity__c);
                            }
							system.debug('THIS IS THE ASSET LIST >> ' + AssetList);
                            Integer Placement = 0;
                            Boolean CurrentItemUpdated = false;
                            for (ProductItem__c asset : AssetList) {

                                if (asset.Id != item.Id) {
                                    Placement += 1;
                                }
								if (((item.Rating_Points__c > asset.Rating_Points__c) || (item.Rating_Points__c == asset.Rating_Points__c)) && CurrentItemUpdated == false && asset.Id != item.Id) {
                                    item.Probo_s_Offer__c = PricingMap.get(Placement);
                                    Placement += 1;
                                    CurrentItemUpdated = true;
                                }
								System.debug('INSIDE ASSET LOOP FOR PRICING MAP >> ' + asset.Probo_s_Offer__c + ' AND ASSET ID >> ' + asset.Id + ' AND ITEM ID >> ' + item.Id);
                                
                                if (asset.Probo_s_Offer__c != PricingMap.get(Placement) && asset.Id != item.Id) {
                                    asset.Probo_s_Offer__c = PricingMap.get(Placement);
                                    pItemsToUpdate.add(asset);
                                }
                            }

                            if (AssetList.isEmpty()) {
                                item.Probo_s_Offer__c = PricingMap.get(Placement);
                            }
                        }

                        if (item.Repair_Due_Date__c != null) {
                            returnDays = NoWorkingDays.betweenWorkingDays(item.Repair_Due_Date__c);
                        }

                        item.No_of_Days_Until_Due_Date__c = returnDays;
                    } // end trigger loop

                    System.debug('Updating this many PItems from RMA Before Update: ' + pItemsToUpdate.size());
                    if (!pItemsToUpdate.isEmpty()) {
                        Validator_Class.SetByPassProductItemTrigger(true);
                        system.debug('PRODUCT ITEM UPDATE FROM INSIDE PRODUCT ITEM TRIGGER >> ' + pItemsToUpdate);
                        DatabaseService.updateList(pItemsToUpdate);

                        Validator_Class.SetByPassProductItemTrigger(false);
                    }

                }
            } /*else { // Trigger.isAfter

                RecordType purchasingOppRecType;

                for (RecordType r : ProboCommonUtils.getRecordTypes('Opportunity')) {
                    if (r.DeveloperName == 'Purchasing_Opportunity') {
                        purchasingOppRecType = r;
                        break;
                    }
                }

                Map<Id, Opportunity> oppIdToOpp = new Map<Id, Opportunity>();

                if (!oppIds.isEmpty()) {

                    oppIdToOpp = new Map<Id, Opportunity>([select Id, RecordTypeId from Opportunity where Id in :oppIds]);

                    Set<Id> pItemIdsForTests = new Set<Id>();
                    for (Id theOpp : oppIdToPItems.keySet()) {
                        for (ProductItem__c pi : oppIdToPItems.get(theOpp)) {
                            pItemIdsForTests.add(pi.Id);
                        }
                    }
                }

                if (Trigger.isInsert) {

                    Map<Id, Opportunity> oppsToUpdateMap = new Map<Id, Opportunity>();

                    for (ProductItem__c item : newRecs) {

                        if (item.Purchasing_Opportunity__c != null) {

                            Validator_Class.setAlreadyDone17();

                            if (oppIdToOpp.get(item.Purchasing_Opportunity__c).RecordTypeId == purchasingOppRecType.Id) {

                                Opportunity opp = oppIdToOpp.get(item.Purchasing_Opportunity__c);

                                List<ProductItem__c> checkedinlist = new List<ProductItem__c>();

                                if (oppIdToOLIs.containsKey(opp.Id)) {
                                    checkedinlist = oppIdToPItems.get(opp.Id);
                                }
                                System.debug('THESE ARE THE PRODUCT ITEMS (MAX 1000): ' + checkedinlist);

                                Decimal totalcost = 0, totalcostunsold = 0;
                                for (ProductItem__c lineitem : checkedinlist) {
                                    if (lineitem.Cost__c != null) {
                                        totalcost += lineitem.Cost__c;
                                    }

                                    if (lineitem.sold__c == false) {
                                        if (lineitem.Cost__c != null) {
                                            totalcostunsold += lineitem.Cost__c;
                                        }
                                    }
                                }
                                opp.Number_of_Checked_In_Items__c = checkedinlist.size();
                                opp.Total_Cost_of_Assets__c = totalcost;
                                opp.Total_Cost_of_Unsold_Assets__c = totalcostunsold;
                                oppsToUpdateMap.put(opp.Id, opp);
                            }
                        }
                    }

                    system.debug('Updating this many Opps after RMA insert: ' + oppsToUpdateMap.size());
                    if (!oppsToUpdateMap.isEmpty()) {
                        // setting this flag since the only change on the Opps is the fields we are setting.  No more calc needed
                        GH_CodeUtils.setFlag('Updating Opp Totals');
                        Validator_Class.SetByPassOppTrigger(true);
                        DatabaseService.updateList(oppsToUpdateMap.values());
                        Validator_Class.SetByPassOppTrigger(false);
                    }

                } else if (Trigger.isUpdate) {

                    Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();
                    for (ProductItem__c item : newRecs) {

                        ProductItem__c OldItem = oldRecs.get(item.Id);
                        system.debug('THIS IS THE ITEM PURCH OPP >> ' + item.Purchasing_Opportunity__c + ' AND THIS IS THE ITEM ID >> ' + item.id);
                        if (item.Purchasing_Opportunity__c != null && (OldItem.Purchasing_Opportunity__c == null
                                || (OldItem.Cost__c != item.Cost__c) || (OldItem.sold__c != item.sold__c))) {

                            System.debug('ProductItem has a Purchasing_Opportunity__c or the Cost or Sold is being set');
                            Validator_Class.setAlreadyDone17();

                            Opportunity opp = oppIdToOpp.get(item.Purchasing_Opportunity__c);

                            if (opp.RecordTypeId == purchasingOppRecType.Id) {

                                System.debug('The Purchasing_Opportunity has the right record type');
                                List<ProductItem__c> checkedinlist = new List<ProductItem__c>();

                                // TODO: this seems like a bug - why are we checking if the OLI has the key, but then getting the PItems?
                                // JMAY - 11/30 - added the containsKey to the right map
                                if (oppIdToOLIs.containsKey(opp.Id) && oppIdToPItems.containsKey(opp.Id)) {
                                    System.debug('Getting the ProductItems related to the Line Items of the Opp');
                                    checkedinlist = oppIdToPItems.get(opp.Id);
                                }
                                System.debug('THIS IS THE PRODUCT ITEM list: ' + checkedinlist);

                                Decimal totalcost = 0, totalcostunsold = 0;

                                for (ProductItem__c lineitem : checkedinlist) {
                                    System.debug('ProductItem Cost: ' + lineitem.Cost__c);
                                    if (lineitem.Cost__c != null) {
                                        totalcost += lineitem.Cost__c;

                                        System.debug('ProductItem Sold: ' + lineitem.Sold__c);
                                        if (lineitem.sold__c == false) {
                                            totalcostunsold += lineitem.Cost__c;
                                        }
                                    }
                                }

                                System.debug('Setting Purchasing Opp fields for: ' + opp.Id);
                                System.debug('Number of Checked in Items: ' + checkedinlist.size());
                                System.debug('Total Cost of Assets: ' + totalcost);
                                System.debug('Total Cost of Unsold Assets: ' + totalcostunsold);
                                opp.Number_of_Checked_In_Items__c = checkedinlist.size();
                                opp.Total_Cost_of_Assets__c = totalcost;
                                opp.Total_Cost_of_Unsold_Assets__c = totalcostunsold;
                                if (oppsToUpdate.containsKey(opp.Id)) {
                                    System.debug('UpdateRMA trigger after update is adding this Opp to the list of updates again: ' + opp.Id);
                                }
                                oppsToUpdate.put(opp.Id, opp);
                            }
                        }
                    } // end trigger loop

                    system.debug('Updating this many Opps after RMA update: ' + oppsToUpdate.size());
                    if (!oppsToUpdate.isEmpty()) {
                        Validator_Class.SetByPassOppTrigger(true);
                        DatabaseService.updateList(oppsToUpdate.values());
                        Validator_Class.SetByPassOppTrigger(false);
                    }
                } // end afterUpdate
            }*/ // end if after
        } // end if validator

        System.debug('End of P_ProductItemTrigger');

    }


    private Id updatePurchasingApproved(ProductItem__c newRec, ProductItem__c oldRec) {

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

            if (newRec.Added_To_Opportunity__c && newRec.Check_In_Type__c == 'Purchase') {
                recIdForOtherUpdates = newRec.Id;
            }
        }

        return recIdForOtherUpdates;
    }

}