public class P_ProductRepairTriggerHandler extends GH_TriggerHandlerBase {

    protected override void beforeInsert() {
        System.debug('Not implemented yet');
    }
    protected override void beforeUpdate() {
        System.debug('Not implemented yet');
    }
    protected override void beforeDelete() {
        System.debug('Not implemented yet');
    }
    protected override void afterInsert() {
        System.debug('Not implemented yet');
    }
    protected override void afterUpdate() {
        System.debug('Not implemented yet');
    }
    protected override void afterDelete() {
        System.debug('Not implemented yet');
    }
    protected override void afterUndelete() {
        System.debug('Not implemented yet');
    }


    public void processRecords(List<Product_Repair__c> newRecs, Map<Id, Product_Repair__c> newRecMap, Map<Id, Product_Repair__c> oldRecs) {

        GH_Logger.debug('Start of P_ProductRepairTriggerHandler');

        // call the Harvest first since the rest of the processing currently has in-line 'returns' to stop processing
        if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
            processHarvestProductRepairs(newRecMap, oldRecs);
        }

        if (!Trigger.isDelete) {

            // now handle the rest of the trigger processing
            GH_Logger.debug('starting non-delete processing');
			User theCurrentUser = ProboCommonUtils.getCurrentUser();
            
            Set<Id> pItemIds = new Set<Id>();
            Set<String> userLastNames = new Set<String>();
            Set<Id> woIds = new Set<Id>();

            Integer postTestOnly = 0;
            Integer numJustAddedToWO = 0;
            Integer numAddedToWO = 0;

            RecordType functionalRecordType;
            RecordType functionalTEERecordType;
            RecordType cosmeticRecordType;
            RecordType cosmeticTEERecordType;
            RecordType harvestRecordType;

            for (RecordType rt : ProboCommonUtils.getRecordTypes('Product_Repair__c')) {

                switch on rt.Name {

                    when 'Functional Repair' {
                        functionalRecordType = rt;
                    }

                    when 'Functional TEE Repair' {
                        functionalTEERecordType = rt;
                    }

                    when 'Cosmetic Repair' {
                        cosmeticRecordType = rt;
                    }

                    when 'Cosmetic TEE Repair' {
                        cosmeticTEERecordType = rt;
                    }
                    when 'Harvest' {
                        harvestRecordType = rt;
                    }
                }
            }

            for (Product_Repair__c pr : newRecs) {

                if (pr.Added_to_work_order__c) {
                    numAddedToWO++;

                    if ((Trigger.isUpdate && oldRecs.get(pr.Id).Added_to_work_order__c == false)
                            || (Trigger.isInsert && pr.RecordTypeId == harvestRecordType.Id)) {
                        numJustAddedToWO++;
                    }
                }

                if (pr.Post_Test__c != null && (Trigger.isInsert || oldRecs.get(pr.Id).Post_Test__c == null)) {
                    postTestOnly++;
                }

                if (pr.Product_Item__c != null) {
                    GH_Logger.debug('This Product_Repair\'s Product_Item can be processed: ' + pr.Product_Item__c);
                    pItemIds.add(pr.Product_Item__c);
                }

                if (pr.Repair_Technician__c != null && (Trigger.isInsert || oldRecs.get(pr.Id).Repair_Technician__c != pr.Repair_Technician__c)) {

                    System.debug('Prod Repair Repair_Technician: ' + pr.Repair_Technician__c);
                    String last = pr.Repair_Technician__c.right(pr.Repair_Technician__c.length() - pr.Repair_Technician__c.indexOf(' '));
                    last = last.trim();
                    System.debug('adding lastname: "' + last + '"');
                    userLastNames.add(last);

                }

                if (pr.Work_Order__c != null) {
                    woIds.add(pr.Work_Order__c);
                }

                if (pr.Asset_used_during_repair__c != null) {
                    pItemIds.add(pr.Asset_used_during_repair__c);
                }

                if (pr.Second_Asset_used_during_repair__c != null) {
                    pItemIds.add(pr.Second_Asset_used_during_repair__c);
                }
            }

            // if all the PRs in the trigger are postTestOnly, we have no work to do
            GH_Logger.debug('Check if all PRs in the trigger were just marked as Post_Test - no work to do.');
            if (postTestOnly != newRecs.size()) {

                GH_Logger.debug('Check if all PRs in the Before trigger are just added to WorkOrders - no work to do.');
                if (Trigger.isAfter || numJustAddedToWO != newRecs.size()) {

                    Map<Id, Work_Order__c> workOrders = new Map<Id, Work_Order__c>();
                    Map<Id, List<Product_Repair__c>> workOrderIDToProductRepairs = new Map<Id, List<Product_Repair__c>>();

                    if (Trigger.isAfter && numAddedToWO > 0 && !woIds.isEmpty()) {
                        GH_Logger.debug('Only running SOQL if we have WOIds to use and at least 1 ProdRepair is Added_to_Work_Order__c');

                        for (Work_Order__c r : [
                                SELECT Id, Status__c, Work_Order_Type__c, Estimated_Ready_Date__c,
                                        Estimated_Repair_Start_Date__c, Estimated_days_to_repair__c
                                FROM Work_Order__c
                                WHERE Id IN :woIds
                        ]) {

                            workOrders.put(r.Id, r);
                        }

                        for (Product_Repair__c r : [
                                SELECT Id, Repair_Activity_Lead_Time__c, Work_Order__c, Repair_date__c,
                                        Repair_Result__c, Repair_Activity__c, No_longer_needed__c, RecordTypeId
                                FROM Product_Repair__c
                                WHERE No_longer_needed__c = FALSE AND Work_Order__c IN :woIds
                                ORDER BY CreatedDate
                        ]) {

                            if (!workOrderIDToProductRepairs.containsKey(r.Work_Order__c)) {
                                workOrderIDToProductRepairs.put(r.Work_Order__c, new List<Product_Repair__c>());
                            }
                            workOrderIDToProductRepairs.get(r.Work_Order__c).add(r);
                        }
                    }

                    Map<String, List<User>> lastNameToUserList = new Map<String, List<User>>();

                    GH_Logger.debug('Have these lastnames: ' + userLastNames);

                    if (Trigger.isBefore && !userLastNames.isEmpty()) {

                        System.debug('Getting User records for Repair Tech last names');
                        for (User r : [
                                SELECT Id, Name, ProfileId, Profile.Name, FirstName, LastName
                                FROM User
                                WHERE LastName IN :userLastNames
                        ]) {

                            if (!lastNameToUserList.containsKey(r.LastName)) {
                                lastNameToUserList.put(r.LastName, new List<User>());
                            }
                            lastNameToUserList.get(r.LastName).add(r);
                        }
                        System.debug('Found matching User records: ' + lastNameToUserList.size());
                    }

                    Map<Id, ProductItem__c> pItemMap = new Map<Id, ProductItem__c>();
                    Set<Id> prodIds = new Set<Id>();
                    Map<Id, List<OpportunityLineItem>> pItemToOLIs = new Map<Id, List<OpportunityLineItem>>();
                    Map<Id, List<RMA__c>> pItemToRMAs = new Map<Id, List<RMA__c>>();

                    // only used in After triggers
                    Map<Id, List<Product_Repair__c>> pItemToProdRepairs = new Map<Id, List<Product_Repair__c>>();

                    // only used in Before triggers
                    Map<Id, List<ProductTest__c>> pItemIDtoProductTests = new Map<Id, List<ProductTest__c>>();

                    GH_Logger.debug('Have these ProductItem__c IDs: ' + pItemIds);

                    if (!pItemIds.isEmpty()) {

                        pItemMap = new Map<Id, ProductItem__c>([
                                SELECT Id, Repair_Summary__c, Repair_Notes_Summary__c, Functional_Rating__c, Cosmetic_Rating__c,
                                        sold__c, Estimated_Lead_Time__c, Estimated_Repair_Time__c, Repair_Status__c, Product_Name__c,
                                        Cosmetic_Repair_Value__c, Functional_Repair_Value__c, Repair_Value__c, Check_In_Type__c,
                                        Review_Status__c, Date_Last_Test_Completed__c, Total_Repair_Value_Since_Item_Received__c,
                                        Total_Repair_Revenue_All_Time__c, Total_Repair_Rev_Since_Item_Received__c,
                                        Last_Functional_Repair_Date__c, Last_Cosmetic_Repair_Date__c,
                                        Total_Cost_of_Labor_All_Time__c, Total_Cost_of_Labor_Since_Item_Received__c,
                                        Total_Material_Cost_All_Time__c, Total_Material_Cost_Since_Item_Received__c,
                                        Total_Cost_of_Assets_Used_in_Repair__c, Added_to_Work_Order__c, Location__c
                                FROM ProductItem__c
                                WHERE Id = :pItemIds
                        ]);

                        for (ProductItem__c r : pItemMap.values()) {
                            if (r.Product_Name__c != null) {
                                prodIds.add(r.Product_Name__c);
                            }
                        }
                        GH_Logger.debug('Have these Product2 IDs: ' + prodIds);

                        for (OpportunityLineItem r : [
                                SELECT Id, TotalPrice, Ship_Date__c, Stage__c, ProductItem__c, Check_In_Type__c
                                FROM OpportunityLineItem
                                WHERE Stage__c = 'Closed Won' AND ProductItem__c IN :pItemIds
                                ORDER BY Ship_Date__c DESC
                        ]) {

                            if (!pItemToOLIs.containsKey(r.ProductItem__c)) {
                                pItemToOLIs.put(r.ProductItem__c, new List<OpportunityLineItem>());
                            }
                            pItemToOLIs.get(r.ProductItem__c).add(r);
                        }

                        if (Trigger.isBefore) {
                            GH_Logger.debug('Getting ProductTest related to these pItems: ' + pItemIds);

                            for (ProductTest__c r : [
                                    SELECT Id, Product_Item__c, LastModifiedDate, CreatedDate
                                    FROM ProductTest__c
                                    WHERE Product_Item__c IN :pItemIds
                                    ORDER BY CreatedDate DESC
                            ]) {

                                if (!pItemIDtoProductTests.containsKey(r.Product_Item__c)) {
                                    pItemIDtoProductTests.put(r.Product_Item__c, new List<ProductTest__c>());
                                }
                                pItemIDtoProductTests.get(r.Product_Item__c).add(r);
                            }
                        }

                        if (Trigger.isAfter) {
                            GH_Logger.debug('Getting RMAs related to these pItems: ' + pItemIds);

                            for (RMA__c r : [
                                    SELECT Id, Date_RMA_Item_Received__c, ProductItem__c
                                    FROM RMA__c
                                    WHERE ProductItem__c IN :pItemIds
                                    ORDER BY Date_RMA_Item_Received__c DESC
                            ]) {

                                if (!pItemToRMAs.containsKey(r.ProductItem__c)) {
                                    pItemToRMAs.put(r.ProductItem__c, new List<RMA__c>());
                                }
                                pItemToRMAs.get(r.ProductItem__c).add(r);
                            }

                            GH_Logger.debug('Getting other ProductRepairs related to these pItems: ' + pItemIds);
                            for (Product_Repair__c r : [
                                    SELECT Id, Name, Calculated_Cost_of_Part_Used__c, Actual_Cost_of_Assets_Used__c, Cost_of_Labor__c,
                                            Repair_Activity__c, Repair_Value__c, Repair_date__c, New_Repair_Date__c, Repair_Notes__c,
                                            Product_Item__c, Estimated_Repair_Time__c, Repair_Activity_Lead_Time__c, No_longer_needed__c,
                                            Repair_Technician__c, RecordTypeId
                                    FROM Product_Repair__c
                                    WHERE Product_Item__c IN :pItemIds
                                    ORDER BY Repair_date__c DESC
                            ]) {

                                if (!pItemToProdRepairs.containsKey(r.Product_Item__c)) {
                                    pItemToProdRepairs.put(r.Product_Item__c, new List<Product_Repair__c>());
                                }
                                pItemToProdRepairs.get(r.Product_Item__c).add(r);
                            }
                        }
                    }


                    Map<Id, Product2> prodMap = new Map<Id, Product2>();

                    if (!prodIds.isEmpty()) {

                        prodMap = new Map<Id, Product2>([
                                SELECT Id, Name,Cable_Advanced_Whitening__c,Cable_Jacket_Splice__c,Connector_Housing_Replacement__c, Connector_Housing_Paint__c,Refurb__c,
                                        Lens_Refurb__c, Lens_Remove__c, Lens_Relens__c, Strain_Relief_Remove__c, Strain_Relief_Replacement__c, Array_Replacement__c,
                                        Cable_Replacement__c, Cap_Replacement_with_Oil_Fill__c, Connector_Repair__c, Electrical__c, Motor_Repair__c, Oil_Fill__c,
                                        Probe_Handle_Close__c, Probe_Handle_Open__c, Probe_Handle_Replacement__c, Retermination__c, Bending_Rubber_Glue_Beads_Replacement__c,
                                        Control_Housing_Polish__c, Grommet_Replacement__c, Knob_Replacement__c, Lens_Remove_Coating_RTV_Seal_Replacement__c,
                                        RTV_Seal_Replacement__c, Tip_Polish__c, Array_Drive_Switch_or_Board_Replacement__c, Array_Drive_System_Replacement__c,
                                        Connector_Boards_Replacement__c, Control_Housing_Overhaul__c, Insertion_Tube_Replacement__c, Steering_Cable_Adjustment__c,
                                        Steering_Cable_Replacement__c, Tip_Overhaul__c, Cable_Prep__c, Flex_Bonding_Repair__c, Max_Non_Functional__c, Max_Repair__c,
                                        Re_lens__c, Strain_Relief__c, Mechanical__c, Re_paint_connector__c, Replace_Housing__c, Replace_Knob__c, Pins__c, Replace_Handle__c,
                                        Advanced_Cable_Whitening__c, Reverse_Probe_Handle__c, Re_termination__c, Oil_Fill_and_Cap_Replacement__c, Replace_Bending_Rubber__c,
                                        Replace_Glue_Beads__c, Re_coat_Re_label__c, Adjust_Steering_Cable__c, Motor_Replacement__c, Connector_Overhaul__c, Switch_Replacement_TEE__c,
                                        Tip_Replacement__c, Probe_Handle_Reverse__c, Tip_Lens_Film_Removal__c, Full_Overhaul__c, Swap__c, Array_Carriage_Replacement__c,
                                        Cable_Jacket_Refurbishment__c, Cap_Refurbishment__c, Connector_Refurbishment__c, Probe_Handle_Refurbishment__c,
                                        Strain_Relief_Refurbishment__c, Ferrule_Assembly__c, Oil_Bladder_Replacement__c, Carriage_Drive_Cable_Replacement__c,
                                        Wire_splice__c
                                FROM Product2
                                WHERE Id = :prodIds
                        ]);
                    }


                    // END OF THE TRIGGER SETUP

                    System.debug('Start of actual trigger code');

                    List<Review_Status__c> revStatToInsert = new List<Review_Status__c>();
                    Map<Id, ProductItem__c> pItemsToUpdateMap = new Map<Id, ProductItem__c>();
                    Map<Id, Work_Order__c> wosToUpdateMap = new Map<Id, Work_Order__c>();
                    List<Move_Location__c> MoveLocationsToInsert = new List<Move_Location__c>();

                    for (Product_Repair__c pr : newRecs) {

                        // Check this: if Post_Test__c is set and didn't used to be, skip any processing
                        // when that happens, only
                        if (pr.Post_Test__c != null && (Trigger.isInsert || oldRecs.get(pr.Id).Post_Test__c == null)) {
                            System.debug('This is PR is being set to Post_Test__c so no work to do ' + pr);
                            continue;
                        }
                        System.debug('This is PR is NOT being set to Post_Test__c ' + pr);

                        /*if (Trigger.isBefore) {

                            GH_Logger.debug('Checking Repair Owner and Repair Technician');
                            // Automatically change the repair owner to the repair technician - this allows reports and views for "my repairs" to sync with the repair tech
                            if (pr.Repair_Technician__c != null && (Trigger.isInsert || oldRecs.get(pr.Id).Repair_Technician__c != pr.Repair_Technician__c)) {

                                String last = pr.Repair_Technician__c.right(pr.Repair_Technician__c.length() - pr.Repair_Technician__c.indexOf(' '));
                                String first = pr.Repair_Technician__c.left(pr.Repair_Technician__c.indexOf(' '));

                                System.debug('Before trigger checking Repair Technician LAST: ' + last + 'AND FIRST: ' + first);
                                last = last.remove(' ');

                                if (lastNameToUserList.containsKey(last)) {
                                    List<User> matchingUsers = lastNameToUserList.get(last);
                                    System.debug('These users match: ' + matchingUsers);
                                    if (matchingUsers.size() == 1) {
                                        pr.OwnerId = matchingUsers[0].Id;
                                    } else if (matchingUsers.size() > 1) {
                                        for (User r : matchingUsers) {
                                            if (r.FirstName == first) {
                                                pr.OwnerId = r.Id;
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                        }*/

                        Decimal RepairValue = 0;
                        Decimal MaxNonFunctionalPrice = 0;
                        Decimal MaxRepairPrice = 0;
                        Map<String, Decimal> repairPriceMap = new Map<String, Decimal>();
                        Set<String> NonFunctionalSet = new Set<String>();
                        Set<String> FunctionalSet = new Set<String>();

                        Datetime Repairdate = pr.Repair_date__c;

                        ProductItem__c pitem;
                        Product2 productForPricing;

                        // only set the pItem variable if we plan to use it for this record.
                        // in Before triggers, we only care about when NOT added to WorkOrder
                        GH_Logger.debug('Checking if Adding to Work Order being set');

                        if ((pr.Product_Item__c != null)
                                && !((pr.Added_to_work_order__c == true && Trigger.isUpdate && oldRecs.get(pr.Id).Added_to_work_order__c == false)
                                || (pr.Added_to_work_order__c == true && Trigger.isInsert && pr.RecordTypeId == harvestRecordType.Id))) {

                            GH_Logger.debug('Adding to Work Order is being set now');

                            pitem = pItemMap.get(pr.Product_Item__c);

                            if (pitem.Product_Name__c != null) {
                                productForPricing = prodMap.get(pitem.Product_Name__c);
                            }
                        }


                        Map<String, String> nonFunctionalFldToStringMappings = new Map<String, String>{
                                'Cable_Advanced_Whitening__c' => 'Cable Advanced Whitening',
                                'Cable_Jacket_Splice__c' => 'Cable Jacket Splice',
                                'Connector_Housing_Paint__c' => 'Connector Housing Paint',
                                'Connector_Housing_Replacement__c' => 'Connector Housing Replacement',
                                'Refurb__c' => 'Refurb',
                                'Lens_Refurb__c' => 'Lens Refurbishment',
                                'Lens_Remove__c' => 'Lens Remove',
                                'Strain_Relief_Remove__c' => 'Strain Relief Remove',
                                'Strain_Relief_Replacement__c' => 'Strain Relief Replacement',
                                'Bending_Rubber_Glue_Beads_Replacement__c' => 'Bending Rubber/Glue Beads Replacement',
                                'Control_Housing_Polish__c' => 'Control Housing Polish',
                                'Grommet_Replacement__c' => 'Grommet Replacement',
                                'Knob_Replacement__c' => 'Knob Replacement',
                                'Lens_Remove_Coating_RTV_Seal_Replacement__c' => 'Lens Remove Coating/RTV Seal Replacement',
                                'RTV_Seal_Replacement__c' => 'RTV Seal Replacement',
                                'Tip_Polish__c' => 'Tip Polish',
                                'Re_lens__c' => 'Re-lens',
                                'Strain_Relief__c' => 'Strain Relief',
                                'Re_paint_connector__c' => 'Re-Paint Connector',
                                'Replace_Housing__c' => 'Replace Housing',
                                'Replace_Knob__c' => 'Replace Knob',
                                'Advanced_Cable_Whitening__c' => 'Advanced Cable Whitening',
                                'Replace_Bending_Rubber__c' => 'Replace Bending Rubber',
                                'Replace_Glue_Beads__c' => 'Replace Glue Beads',
                                'Re_coat_Re_label__c' => 'Re-coat / Re-label',
                                'Tip_Lens_Film_Removal__c' => 'Tip Lens Film Removal',
                                'Cable_Jacket_Refurbishment__c' => 'Cable Jacket Refurbishment',
                                'Cap_Refurbishment__c' => 'Cap Refurbishment',
                                'Connector_Refurbishment__c' => 'Connector Refurbishment',
                                'Probe_Handle_Refurbishment__c' => 'Probe Handle Refurbishment',
                                'Strain_Relief_Refurbishment__c' => 'Strain Relief Refurbishment'
                        };

                        Map<String, String> functionalFldToStringMappings = new Map<String, String>{
                                'Array_Replacement__c' => 'Array Replacement',
                                'Cable_Replacement__c' => 'Cable Replacement',
                                'Cap_Replacement_with_Oil_Fill__c' => 'Cap Replacement with Oil Fill',
                                'Connector_Repair__c' => 'Connector Repair',
                                'Electrical__c' => 'Electrical',
                                'Motor_Repair__c' => 'Motor Repair',
                                'Oil_Fill__c' => 'Oil Fill',
                                'Probe_Handle_Close__c' => 'Probe Handle Close',
                                'Probe_Handle_Open__c' => 'Probe Handle Open',
                                'Probe_Handle_Replacement__c' => 'Probe Handle Replacement',
                                'Retermination__c' => 'Retermination',
                                'Array_Drive_Switch_or_Board_Replacement__c' => 'Array Drive Switch or Board Replacement',
                                'Array_Drive_System_Replacement__c' => 'Array Drive System Replacement',
                                'Connector_Boards_Replacement__c' => 'Connector Boards Replacement',
                                'Control_Housing_Overhaul__c' => 'Control Housing Overhaul',
                                'Insertion_Tube_Replacement__c' => 'Insertion Tube Replacement',
                                'Steering_Cable_Adjustment__c' => 'Steering Cable Adjustment',
                                'Steering_Cable_Replacement__c' => 'Steering Cable Replacement',
                                'Tip_Overhaul__c' => 'Tip Overhaul',
                                'Cable_Prep__c' => 'Cable Prep',
                                'Flex_Bonding_Repair__c' => 'Flex Bonding/Repair',
                                'Mechanical__c' => 'Mechanical',
                                'Pins__c' => 'Replace Pins',
                                'Replace_Handle__c' => 'Replace Handle',
                                'Reverse_Probe_Handle__c' => 'Reverse Probe Handle',
                                'Re_termination__c' => 'Re-termination',
                                'Oil_Fill_and_Cap_Replacement__c' => 'Oil Fill and Cap Replacement',
                                'Adjust_Steering_Cable__c' => 'Adjust Steering Cable',
                                'Motor_Replacement__c' => 'Motor Replacement',
                                'Connector_Overhaul__c' => 'Connector Overhaul',
                                'Switch_Replacement_TEE__c' => 'Switch Replacement TEE',
                                'Tip_Replacement__c' => 'Tip Replacement',
                                'Probe_Handle_Reverse__c' => 'Probe Handle Reverse',
                                'Full_Overhaul__c' => 'Full Overhaul',
                                'Array_Carriage_Replacement__c' => 'Array Carriage Replacement',
                                'Ferrule_Assembly__c' => 'Ferrule Assembly',
                                'Carriage_Drive_Cable_Replacement__c' => 'Carriage Drive Cable Replacement',
                                'Oil_Bladder_Replacement__c' => 'Oil Bladder Replacement',
                                'Wire_splice__c' => 'Wire splice'
                        };

                        GH_Logger.debug('product for pricing: ' + productForPricing);

                        // Creates a map of prices for repairs and also sorts into functional and non functional repairs
                        if (productForPricing != null) {

                            Boolean prodItemHasChanged = false;

                            for (String thisField : nonFunctionalFldToStringMappings.keySet()) {
                                if (productForPricing.get(thisField) != null) {
                                    repairPriceMap.put(nonFunctionalFldToStringMappings.get(thisField), (Decimal) (productForPricing.get(thisField)));
                                    NonFunctionalSet.add(nonFunctionalFldToStringMappings.get(thisField));
                                }
                            }

                            for (String thisField : functionalFldToStringMappings.keySet()) {
                                if (productForPricing.get(thisField) != null) {
                                    repairPriceMap.put(functionalFldToStringMappings.get(thisField), (Decimal) (productForPricing.get(thisField)));
                                    FunctionalSet.add(functionalFldToStringMappings.get(thisField));

                                    if (thisField == 'Electrical__c') {
                                        repairPriceMap.put('Electrical - miscellaneous', (Decimal) (productForPricing.get(thisField)));
                                        FunctionalSet.add('Electrical - miscellaneous');
                                    }
                                }
                            }

                            if (Trigger.isBefore) {

                                GH_Logger.debug('Before trigger looking at Added to Work Order');

                                if (pr.Added_to_work_order__c == false
                                        || (pr.Added_to_work_order__c
                                        && ((Trigger.isInsert && pr.Repair_date__c != null)
                                        || (Trigger.isUpdate && (oldRecs.get(pr.Id).Added_to_work_order__c))))) {

                                    if (Trigger.isInsert) {

                                        GH_Logger.debug('Insert trigger setting PR Date_Last_Test_Completed from pItem: ' + pItem.Date_Last_Test_Completed__c);

                                        pr.Date_Last_Test_Completed__c = pItem.Date_Last_Test_Completed__c;

                                        // get the most recent CreatedDate to use
                                        if (pItemIDtoProductTests.containsKey(pItem.Id)) {
                                            ProductTest__c theLatestTest;
                                            theLatestTest = pItemIDtoProductTests.get(pItem.Id)[0];

                                            if (theLatestTest != null) {
                                                GH_Logger.debug('Insert trigger setting PR Previous_Test: ' + theLatestTest.Id);
                                                pr.Previous_Test__c = theLatestTest.Id;
                                            }
                                        }

                                        System.debug('THIS IS THE INSERT REPAIR DATE >>> ' + pr.Repair_date__c);
                                        System.debug('THIS IS THE ASSET USED >>> ' + pr.Asset_used_during_repair__c);

                                    } else if (Trigger.isUpdate) {

                                        GH_Logger.debug('Update trigger checking Repair_Date and Previous_Test');

                                        // Links previous test on repair with most recent test done before the repair
                                        if (pr.Repair_date__c != null && pr.Previous_Test__c == null) {

                                            GH_Logger.debug('Repair_Date not null; Previous_Test is null');

                                            // Links previous test on repair with most recent test done before the repair
                                            if (pItemIDtoProductTests.containsKey(pItem.Id)) {

                                                // get all the ProductTests for this ProdRepair, and
                                                // find the one with the most recent LastModifiedDate that is also created
                                                // before the RepairDate
                                                ProductTest__c prevTest;

                                                for (ProductTest__c r : pItemIDtoProductTests.get(pItem.Id)) {

                                                    if (r.CreatedDate <= Repairdate.addMinutes(1)
                                                            && (prevTest == null || prevTest.LastModifiedDate < r.LastModifiedDate)) {
                                                        prevTest = r;
                                                    }
                                                }

                                                GH_Logger.debug('Found a Previous_Test: ' + prevTest);

                                                //=== Rahul: One Minute is added to Repair_Date to remove the conflict during generation of 'Repair & Test' within a Minute.
                                                GH_Logger.debug('Update trigger setting PR Date_Last_Test_Completed from pItem: ' + pItem.Date_Last_Test_Completed__c);

                                                pr.Date_Last_Test_Completed__c = pItem.Date_Last_Test_Completed__c;

                                                if (prevTest != null) {
                                                    GH_Logger.debug('Update trigger setting PR Previous_Test: ' + prevTest.Id);
                                                    pr.Previous_Test__c = prevTest.Id;
                                                }
                                            }
                                        }
                                    }

                                    // Sets repair value - half of the price listed on the product page; for total repair value, compares against
                                    // non functional and total max prices (but cut in half)
                                    if (productForPricing.Max_Non_Functional__c != null) {
                                        MaxNonFunctionalPrice = productForPricing.Max_Non_Functional__c;
                                        if (MaxNonFunctionalPrice > 0) {
                                            MaxNonFunctionalPrice = (MaxNonFunctionalPrice * 50) / 100;
                                        }
                                    }
                                    if (productForPricing.Max_Repair__c != null) {
                                        MaxRepairPrice = productForPricing.Max_Repair__c;
                                        if (MaxRepairPrice > 0) {
                                            MaxRepairPrice = (MaxRepairPrice * 50) / 100;
                                        }
                                    }
                                    String repairName = pr.Product_Repair_Name__c;
                                    RepairValue = repairPriceMap.get(repairName);
                                    if (RepairValue != null) {
                                        if (RepairValue > 0) {
                                            RepairValue = (RepairValue * 50) / 100;
                                        }


                                        if (NonFunctionalSet.contains(repairName)) {
                                            if (RepairValue < MaxNonFunctionalPrice) {
                                                RepairValue = RepairValue;
                                            } else {
                                                RepairValue = MaxNonFunctionalPrice ;
                                            }
                                        }
                                        if (FunctionalSet.contains(repairName)) {
                                            if (RepairValue < MaxRepairPrice) {
                                                RepairValue = RepairValue;
                                            } else {
                                                RepairValue = MaxRepairPrice ;
                                            }
                                        }

                                        if (RepairValue != null && pr.Repair_date__c != null) {
                                            pr.Repair_Value__c = RepairValue;
                                        }
                                        if ((RepairValue == null || RepairValue == 0) && pr.Repair_date__c != null) {
                                            pr.Repair_Value__c = 0;
                                        }
                                    }
                                }

                            } else if (Trigger.isAfter) {

                                System.debug('Starting updateProductRepairTrigger After');

                                if (pr.Added_to_work_order__c == false
                                        || (pr.Added_to_work_order__c
                                        && (
                                        (Trigger.isInsert && pr.Repair_date__c != null)
                                                || (Trigger.isUpdate && (oldRecs.get(pr.Id).Added_to_work_order__c))
                                )
                                )) {

                                    System.debug('Added to Work Order is false OR its True on Insert with a Repair Date OR its still true');

                                    // Some of these repair lists could probably be combined to make the code more efficient
                                    //pItemToProdRepairs has all the Product_Repairs for this Item, so we just need to filter it into separate lists

                                    List<Product_Repair__c> repairlistWithRepairDates = new List<Product_Repair__c>(); // was repairList
                                    List<Product_Repair__c> repairlistWithoutRepairDates = new List<Product_Repair__c>();// was repairList2
                                    List<Product_Repair__c> cosmeticrepairlist = new List<Product_Repair__c>();
                                    List<Product_Repair__c> functionalrepairlist = new List<Product_Repair__c>();

                                    if (pItemToProdRepairs.containsKey(pItem.Id)) {

                                        for (Product_Repair__c r : pItemToProdRepairs.get(pItem.Id)) {

                                            if (r.Repair_date__c != null) {
                                                repairlistWithRepairDates.add(r);

                                                if (r.RecordTypeId == cosmeticRecordType.Id
                                                        || r.RecordTypeId == cosmeticTEERecordType.Id) {

                                                    cosmeticrepairlist.add(r);
                                                } else if (r.RecordTypeId == functionalRecordType.Id
                                                        || r.RecordTypeId == functionalTEERecordType.Id) {

                                                    functionalrepairlist.add(r);
                                                }
                                            } else {
                                                repairlistWithoutRepairDates.add(r);
                                            }
                                        }
                                    }

                                    List<RMA__c> RMAlist = new List<RMA__c>();

                                    if (pItemToRMAs.containsKey(pitem.Id)) {
                                        RMAlist = pItemToRMAs.get(pitem.Id);
                                    }


                                    GH_Logger.debug('Check Functional rating and maybe clear them');
                                    GH_Logger.debug('PR RecTypeID: ' + pr.RecordTypeId);
                                    GH_Logger.debug('Func RecTypeID: ' + functionalRecordType.Id);
                                    GH_Logger.debug('FuncTEE RecTypeID: ' + functionalTEERecordType.Id);
                                    GH_Logger.debug('PR Repair_date: ' + pr.Repair_date__c);
                                    GH_Logger.debug('Trigger is Insert: ' + Trigger.isInsert);
                                    GH_Logger.debug('Insert or prev Repair date is null: ' + (Trigger.isInsert || (oldRecs.get(pr.Id).Repair_date__c == null)));
                                    GH_Logger.debug('PItem Func Rating: ' + pitem.Functional_Rating__c);

                                    if ((pr.RecordTypeId == functionalRecordType.Id || pr.RecordTypeId == functionalTEERecordType.Id)
                                            && pr.Repair_date__c != null && (Trigger.isInsert || (oldRecs.get(pr.Id).Repair_date__c == null))
                                            && pitem.Functional_Rating__c != '' && pitem.Functional_Rating__c != null) {

                                        GH_Logger.debug('Clear functional rating if functional repair performed');
                                        pitem.Functional_Rating__c = '';
                                        prodItemHasChanged = true;
                                    }

                                    GH_Logger.debug('Check Functional rating and maybe clear them');
                                    GH_Logger.debug('PR RecTypeID: ' + pr.RecordTypeId);
                                    GH_Logger.debug('Cos RecTypeID: ' + cosmeticRecordType.Id);
                                    GH_Logger.debug('CosTEE RecTypeID: ' + cosmeticTEERecordType.Id);
                                    GH_Logger.debug('PR Repair_date: ' + pr.Repair_date__c);
                                    GH_Logger.debug('Trigger is Insert: ' + Trigger.isInsert);
                                    GH_Logger.debug('Insert or prev Repair date is null: ' + (Trigger.isInsert || (oldRecs.get(pr.Id).Repair_date__c == null)));
                                    GH_Logger.debug('PItem Cos Rating: ' + pitem.Cosmetic_Rating__c);

                                    if ((pr.RecordTypeId == cosmeticRecordType.Id || pr.RecordTypeId == cosmeticTEERecordType.Id)
                                            && pr.Repair_date__c != null && (Trigger.isInsert || (oldRecs.get(pr.Id).Repair_date__c == null))
                                            && pitem.Cosmetic_Rating__c != '' && pitem.Cosmetic_Rating__c != null) {

                                        GH_Logger.debug('clear cosmetic rating if cosmetic rating performed');
                                        pitem.Cosmetic_Rating__c = '';
                                        prodItemHasChanged = true;
                                    }

                                    GH_Logger.debug('Done checking F and C Rating');

                                    // For asset used in repair, mark as sold once repair date is entered - this consumes it from inventory
                                    if (pr.Asset_used_during_repair__c != null && pr.Repair_date__c != null
                                            && ((Trigger.isInsert || oldRecs.get(pr.Id).Asset_used_during_repair__c == null)
                                            || (pr.Repair_date__c != null && (Trigger.isInsert || oldRecs.get(pr.Id).Repair_date__c == null)))) {

                                        ProductItem__c thePItem;

                                        if (pItemMap.containsKey(pr.Asset_used_during_repair__c)) {
                                            Boolean add = false;
                                            thePItem = pItemMap.get(pr.Asset_used_during_repair__c);
                                            if (thePItem.Functional_Rating__c != null && thePItem.Functional_Rating__c != '') {
                                                thePItem.Functional_Rating__c = String.valueOf('');
                                                add = true;
                                            }
                                            if (thePItem.Cosmetic_Rating__c != null && thePItem.Cosmetic_Rating__c != '') {
                                                thePItem.Cosmetic_Rating__c = String.valueOf('');
                                                add = true;
                                            }

                                            if (thePItem.sold__c != true) {
                                                thePItem.sold__c = true;
                                                add = true;
                                            }
                                            String usr_name = theCurrentUser.FirstName + ' ' + theCurrentUser.LastName;
                                            Move_Location__c newMove = new Move_Location__c(Old_Location__c = thePItem.Location__c, Note__c = 'Consumed in product repair ' + pr.Name + ' on ' + pr.Repair_date__c,
                                                                    New_Location__c = 'Consumed', Geographic_Location__c = 'Consumed', Completed_By__c = usr_name,
                                                                    ProductItem__c = thePItem.Id);
                                        	MoveLocationsToInsert.add(newMove);

                                            if (add) {
                                                pItemsToUpdateMap.put(thePItem.Id, thePItem);
                                            }
                                        }
                                    }

                                    // Same thing but for second asset used in repair - this is currently disabled (not on page layout) but may use again in the future. Only disabled for accounting reasons.
                                    if (pr.Second_Asset_used_during_repair__c != null && pr.Repair_date__c != null
                                            && ((Trigger.isInsert || oldRecs.get(pr.Id).Second_Asset_used_during_repair__c == null)
                                            || (pr.Repair_date__c != null && (Trigger.isInsert || oldRecs.get(pr.Id).Repair_date__c == null)))) {

                                        ProductItem__c thePItem;

                                        if (pItemMap.containsKey(pr.Second_Asset_used_during_repair__c)) {
                                            boolean add = false;
                                            thePItem = pItemMap.get(pr.Second_Asset_used_during_repair__c);

                                            if (thePItem.Functional_Rating__c != null && thePItem.Functional_Rating__c != '') {
                                                thePItem.Functional_Rating__c = String.valueOf('');
                                                add = true;
                                            }
                                            if (thePItem.Cosmetic_Rating__c != null && thePItem.Cosmetic_Rating__c != '') {
                                                thePItem.Cosmetic_Rating__c = String.valueOf('');
                                                add = true;
                                            }

                                            if (thePItem.sold__c != true) {
                                                thePItem.sold__c = true;
                                                add = true;
                                            }
                                            
                                            String usr_name = theCurrentUser.FirstName + ' ' + theCurrentUser.LastName;
                                            Move_Location__c newMove = new Move_Location__c(Old_Location__c = thePItem.Location__c, Note__c = 'Consumed in product repair ' + pr.Name + ' on ' + pr.Repair_date__c,
                                                                    New_Location__c = 'Consumed', Geographic_Location__c = 'Consumed', Completed_By__c = usr_name,
                                                                    ProductItem__c = thePItem.Id);
                                        	MoveLocationsToInsert.add(newMove);

                                            if (add == true) {
                                                pItemsToUpdateMap.put(thePItem.Id, thePItem);
                                            }
                                        }
                                    }

                                    if (Trigger.isUpdate) {

                                        // If repair marked as fail, put back into repair queue (review status)
                                        if (pr.Repair_Result__c == 'FAIL' && oldRecs.get(pr.Id).Repair_Result__c == 'SUCCESS'
                                                && pitem.Review_Status__c != 'Repair Queue' && pitem.Review_Status__c != 'Cosmetic Repair Queue'
                                                && pitem.Check_In_Type__c != 'Customer Repair' && pitem.Check_In_Type__c != 'Warranty Repair') {

                                            User currUser = ProboCommonUtils.getCurrentUser();
                                            if (currUser.Profile.Name == 'QC/Inspection' || currUser.Profile.Name == 'QC Manager') {
                                                Review_Status__c NewRS = new Review_Status__c(ProductItem__c = pitem.Id, Old_Review_Status__c = pitem.Review_Status__c,
                                                        New_Review_Status__c = 'Repair Queue', Completed_By__c = currUser.Name,
                                                        Notes__c = 'Repair failed; moved to repair queue');

                                                revStatToInsert.add(NewRS);
                                            }
                                        }
                                    }

                                    Date dateItemReceived;

                                    if (!RMAlist.isEmpty()) {
                                        dateItemReceived = RMAlist[0].Date_RMA_Item_Received__c;
                                    }


                                    Decimal CosmeticValue = 0;
                                    Decimal FunctionalValue = 0;
                                    Decimal CosmeticValueShort = 0;
                                    Decimal FunctionalValueShort = 0;
                                    Decimal RepairValueShort = 0;
                                    Decimal RevenueTotal = 0;
                                    Decimal RevenueShort = 0;

                                    String temp = '';
                                    String tempRepairNoteSummary = '';
                                    Decimal CostofLaborAll = 0, CostofLaborShort = 0, MaterialCostAll = 0, MaterialCostShort = 0, ActualCostAll = 0;

                                    // The following calculates the material and labor cost fields as well as revenue and repair value (calculates cosmetic and functional values separately, then adds together for total - still compares against max repair values)
                                    for (Product_Repair__c repair : repairlistWithRepairDates) {

                                        RepairValue = repairPriceMap.get(String.valueOf(repair.Repair_Activity__c));

                                        if (RepairValue != Null) {
                                            if (RepairValue > 0) {
                                                RepairValue = (RepairValue * 50) / 100;
                                            }
                                        } else {
                                            RepairValue = 0;
                                        }


                                        if (ProboConstants.cosmetic_repair_list.contains(String.valueOf(repair.Repair_Activity__c))) {
                                            CosmeticValue += RepairValue;
                                        }
                                        if (ProboConstants.functional_repair_list.contains(String.valueOf(repair.Repair_Activity__c))) {
                                            FunctionalValue += RepairValue;
                                        }

                                        // REPAIR SUMMARY FIELDS
                                        String[] newDate = String.valueOf(repair.Repair_date__c).split(' ');
                                        temp = temp + repair.Repair_Activity__c + ' - ' + newDate[0] + '; ';
                                        if (repair.Repair_Notes__c != null) {
                                            tempRepairNoteSummary = tempRepairNoteSummary + repair.Repair_Notes__c + ' - ' + newDate[0] + ';';
                                        }

                                        // code for cost of labor and material cost
                                        if (!RMAlist.isEmpty()) {

                                            if (repair.New_Repair_Date__c > dateItemReceived || repair.New_Repair_Date__c == dateItemReceived) {
                                                CostofLaborShort += repair.Cost_of_Labor__c;
                                                if (repair.Calculated_Cost_of_Part_Used__c != null) {
                                                    MaterialCostShort += repair.Calculated_Cost_of_Part_Used__c;
                                                }
                                                if (ProboConstants.cosmetic_repair_list.contains(String.valueOf(repair.Repair_Activity__c))) {
                                                    CosmeticValueShort += RepairValue;
                                                }
                                                if (ProboConstants.functional_repair_list.contains(String.valueOf(repair.Repair_Activity__c))) {
                                                    FunctionalValueShort += RepairValue;
                                                }
                                            }
                                        }


                                        CostofLaborAll += repair.Cost_of_Labor__c;
                                        if (repair.Calculated_Cost_of_Part_Used__c != null) {
                                            MaterialCostAll += repair.Calculated_Cost_of_Part_Used__c;
                                        }
                                        System.debug('THIS IS THE COST OF ASSETS USED >> ' + repair.Repair_Activity__c + ' ' + repair.Actual_Cost_of_Assets_Used__c);
                                        if (repair.Actual_Cost_of_Assets_Used__c != null && repair.Actual_Cost_of_Assets_Used__c != 0.00) {
                                            System.debug('THIS IS THE COST OF ASSETS USED INSIDE IF STATEMENT>> ' + repair.Repair_Activity__c + ' ' + repair.Actual_Cost_of_Assets_Used__c);
                                            ActualCostAll += repair.Actual_Cost_of_Assets_Used__c;
                                        }
                                        // Short term is cost/values since probe came in (if probe has come back on RMA)
                                        if (!RMAlist.isEmpty()) {
                                            CostofLaborShort += repair.Cost_of_Labor__c;
                                            if (repair.Calculated_Cost_of_Part_Used__c != null) {
                                                MaterialCostShort += repair.Calculated_Cost_of_Part_Used__c;
                                            }
                                            if (ProboConstants.cosmetic_repair_list.contains(String.valueOf(repair.Repair_Activity__c))) {
                                                CosmeticValueShort += RepairValue;
                                            }
                                            if (ProboConstants.functional_repair_list.contains(String.valueOf(repair.Repair_Activity__c))) {
                                                FunctionalValueShort += RepairValue;
                                            }
                                        }
                                        if (productForPricing.Max_Non_Functional__c != null) {
                                            Decimal nonfunctionalshort = (productForPricing.Max_Non_Functional__c * 50) / 100;
                                            if (CosmeticValueShort < nonfunctionalshort) {
                                                CosmeticValueShort = CosmeticValueShort;
                                            } else {
                                                CosmeticValueShort = nonfunctionalshort;
                                            }
                                        }
                                        RepairValueShort = CosmeticValueShort + FunctionalValueShort;
                                        if (productForPricing.Max_Repair__c != null) {
                                            Decimal maxrepair = (productForPricing.Max_Repair__c * 50) / 100;
                                            if (RepairValueShort < maxrepair) {
                                                RepairValueShort = RepairValueShort;
                                            } else {
                                                RepairValueShort = maxrepair;
                                            }
                                        }
                                        System.debug('THIS IS THE ITEM RECEIVED DATE >>>> ' + dateItemReceived);
                                    }

                                    List<OpportunityLineItem> allOLIs = new List<OpportunityLineItem>();
                                    OpportunityLineItem theOLI;

                                    // we need all the OLIs for totalling,
                                    // but only need the most recent Ship_Date for processing
                                    if (pItemToOLIs.containsKey(pitem.Id)) {
                                        allOLIs = pItemToOLIs.get(pitem.Id);
                                        theOLI = allOLIs[0];
                                    }

                                    System.debug('THIS IS THE OLI >>> ' + theOLI);

                                    // Revenue totals are calculated from opps that the asset is on
                                    if (theOLI != null) {
                                        if (theOLI.Ship_Date__c > dateItemReceived || theOLI.Ship_Date__c == dateItemReceived) {
                                            RevenueShort = theOLI.TotalPrice;
                                            System.debug('THIS IS THE REVENUE SHORT IF GREATER >>> ' + RevenueShort);
                                        }
                                        if (theOLI.Ship_Date__c < dateItemReceived) {
                                            if (theOLI.Check_In_Type__c == 'Customer Repair') {
                                                RevenueShort = (RepairValueShort * 2);
                                                System.debug('THIS IS THE REVENUE SHORT IF LESS AND CUSTOMER >>> ' + RevenueShort);
                                            }
                                            if (theOLI.Check_In_Type__c != 'Customer Repair') {
                                                RevenueShort = (RepairValueShort);
                                                System.debug('THIS IS THE REVENUE SHORT IF LESS AND NOT CUSTOMER >>> ' + RevenueShort);
                                            }
                                        }
                                        if (dateItemReceived == null) {
                                            RevenueShort = theOLI.TotalPrice;
                                        }

                                        for (OpportunityLineItem o : allOLIs) {
                                            if (o.Id != theOLI.Id) {
                                                if (o.Ship_Date__c < dateItemReceived) {
                                                    RevenueTotal += o.TotalPrice;
                                                }
                                                System.debug('THIS IS THE REVENUE TOTAL INSIDE LOOP >>> ' + RevenueTotal);
                                            }
                                        }
                                        RevenueTotal += RevenueShort;
                                        System.debug('THIS IS THE REVENUE TOTAL AT END >>> ' + RevenueTotal);
                                    }


                                    if (productForPricing.Max_Non_Functional__c != null) {
                                        Decimal nonfunctional = (productForPricing.Max_Non_Functional__c * 50) / 100;
                                        if (CosmeticValue < nonfunctional) {
                                            CosmeticValue = CosmeticValue;
                                        } else {
                                            CosmeticValue = nonfunctional ;
                                        }
                                    }

                                    Decimal RepairTotal = CosmeticValue + FunctionalValue;
                                    if (productForPricing.Max_Repair__c != null) {
                                        Decimal maxrepair = (productForPricing.Max_Repair__c * 50) / 100;
                                        if (FunctionalValue < maxrepair) {
                                            FunctionalValue = FunctionalValue;
                                        } else {
                                            FunctionalValue = maxrepair;
                                        }
                                        RepairTotal = CosmeticValue + FunctionalValue;
                                        if (RepairTotal < maxrepair) {
                                            RepairTotal = RepairTotal;
                                        } else {
                                            RepairTotal = maxrepair;
                                        }
                                    }

                                    // If not on any opps, then takes a best guess for what the revenue will be by multiplying the repair values by 2 (this is the actual price values)
                                    if (theOLI == null) {
                                        if (pitem.Check_In_Type__c == 'Customer Repair') {
                                            RevenueShort = (RepairValueShort * 2);
                                            RevenueTotal = (RepairTotal * 2);
                                            System.debug('THIS IS IF OPP LIST IS ZERO, CUST REPAIR, REV SHORT >>> ' + RevenueShort + ' AND REV TOTAL >>> ' + RevenueTotal);
                                        }
                                        if (pitem.Check_In_Type__c != 'Customer Repair') {
                                            RevenueShort = (RepairValueShort);
                                            RevenueTotal = (RepairTotal);
                                            System.debug('THIS IS IF OPP LIST IS ZERO, NON CUST REPAIR, REV SHORT >>> ' + RevenueShort + ' AND REV TOTAL >>> ' + RevenueTotal);
                                        }
                                    }

                                    // Updates asset fields with all values calculated

                                    if (pitem.Cosmetic_Repair_Value__c != CosmeticValue) {
                                        pitem.Cosmetic_Repair_Value__c = CosmeticValue;
                                        prodItemHasChanged = true;
                                    }
                                    if (pitem.Functional_Repair_Value__c != FunctionalValue) {
                                        pitem.Functional_Repair_Value__c = FunctionalValue;
                                        prodItemHasChanged = true;
                                    }

                                    if (pitem.Repair_Value__c != RepairTotal) {
                                        pitem.Repair_Value__c = RepairTotal;
                                        prodItemHasChanged = true;
                                    }

                                    if (pitem.Total_Repair_Value_Since_Item_Received__c != RepairValueShort) {
                                        pitem.Total_Repair_Value_Since_Item_Received__c = RepairValueShort;
                                        prodItemHasChanged = true;
                                    }

                                    if (pitem.Total_Repair_Revenue_All_Time__c != RevenueTotal) {
                                        pitem.Total_Repair_Revenue_All_Time__c = RevenueTotal;
                                        prodItemHasChanged = true;
                                    }

                                    if (pitem.Total_Repair_Rev_Since_Item_Received__c != RevenueShort) {
                                        pitem.Total_Repair_Rev_Since_Item_Received__c = RevenueShort;
                                        prodItemHasChanged = true;
                                    }

                                    // Repair summary is list of all repairs; repair notes summary is list of all repair notes
                                    if (pitem.Repair_Summary__c != temp) {
                                        pitem.Repair_Summary__c = temp;
                                        prodItemHasChanged = true;
                                    }

                                    if (pitem.Repair_Notes_Summary__c != tempRepairNoteSummary) {
                                        pitem.Repair_Notes_Summary__c = tempRepairNoteSummary;
                                        prodItemHasChanged = true;
                                    }


                                    Datetime FunctionalRepairdate;
                                    Date FunctionalNewRepairDate;
                                    Datetime CosmeticRepairdate;
                                    Date CosmeticNewRepairDate;
                                    if (functionalrepairlist.size() > 0) {
                                        if (functionalrepairlist[0].Repair_date__c != null) {
                                            FunctionalRepairdate = functionalrepairlist[0].Repair_date__c;
                                            FunctionalNewRepairDate = Date.newInstance(FunctionalRepairdate.year(), FunctionalRepairdate.month(), FunctionalRepairdate.day());
                                        }
                                    }
                                    if (cosmeticrepairlist.size() > 0) {
                                        if (cosmeticrepairlist[0].Repair_date__c != null) {
                                            CosmeticRepairdate = cosmeticrepairlist[0].Repair_date__c;
                                            CosmeticNewRepairDate = Date.newInstance(CosmeticRepairdate.year(), CosmeticRepairdate.month(), CosmeticRepairdate.day());
                                        }
                                    }


                                    // These two fields may not be actively used, but were at one point, so may need to remain in the code
                                    if (pitem.Last_Functional_Repair_Date__c != FunctionalNewRepairDate) {
                                        pitem.Last_Functional_Repair_Date__c = FunctionalNewRepairDate;
                                        prodItemHasChanged = true;
                                    }

                                    if (pitem.Last_Cosmetic_Repair_Date__c != CosmeticNewRepairDate) {
                                        pitem.Last_Cosmetic_Repair_Date__c = CosmeticNewRepairDate;
                                        prodItemHasChanged = true;
                                    }

                                    Integer leadtime = 0;
                                    Decimal repairtime = 0;
                                    Integer assigned = 0;

                                    System.debug('THIS IS THE REPAIR LIST 2: ' + repairlistWithoutRepairDates);
                                    for (Product_Repair__c pr2 : repairlistWithoutRepairDates) {
                                        // Lead time and repair time may not be used currently.
                                        if (pr2.No_longer_needed__c == false) {
                                            leadtime += Integer.valueOf(pr2.Repair_Activity_Lead_Time__c);
                                            repairtime += pr2.Estimated_Repair_Time__c;
                                            if (pr2.Repair_Technician__c != null) {
                                                assigned += 1;
                                            }
                                        }
                                    }
                                    // Sets repair status
                                    if ((repairlistWithRepairDates.size() == 0 || assigned == 0) && pitem.Repair_Status__c != 'Unassigned') {
                                        pitem.Repair_Status__c = 'Unassigned';
                                        prodItemHasChanged = true;
                                    }

                                    if (assigned > 0 && pitem.Repair_Status__c != 'Assigned') {
                                        pitem.Repair_Status__c = 'Assigned';
                                        prodItemHasChanged = true;
                                    }

                                    if (repairlistWithoutRepairDates.size() == 0 && pitem.Repair_Status__c != 'Completed') {
                                        pitem.Repair_Status__c = 'Completed';
                                        prodItemHasChanged = true;
                                    }

                                    // Update item with calculated values
                                    if (pitem.Estimated_Lead_Time__c != leadtime) {
                                        pitem.Estimated_Lead_Time__c = leadtime;
                                        prodItemHasChanged = true;
                                    }

                                    if (pitem.Estimated_Repair_Time__c != repairtime) {
                                        pitem.Estimated_Repair_Time__c = repairtime;
                                        prodItemHasChanged = true;
                                    }

                                    if (pitem.Total_Cost_of_Labor_All_Time__c != CostofLaborAll) {
                                        pitem.Total_Cost_of_Labor_All_Time__c = CostofLaborAll;
                                        prodItemHasChanged = true;
                                    }

                                    if (pitem.Total_Cost_of_Labor_Since_Item_Received__c != CostofLaborShort) {
                                        pitem.Total_Cost_of_Labor_Since_Item_Received__c = CostofLaborShort;
                                        prodItemHasChanged = true;
                                    }

                                    if (pitem.Total_Material_Cost_All_Time__c != MaterialCostAll) {
                                        pitem.Total_Material_Cost_All_Time__c = MaterialCostAll;
                                        prodItemHasChanged = true;
                                    }

                                    if (pitem.Total_Material_Cost_Since_Item_Received__c != MaterialCostShort) {
                                        pitem.Total_Material_Cost_Since_Item_Received__c = MaterialCostShort;
                                        prodItemHasChanged = true;
                                    }

                                    if (pitem.Total_Cost_of_Assets_Used_in_Repair__c != ActualCostAll) {
                                        pitem.Total_Cost_of_Assets_Used_in_Repair__c = ActualCostAll;
                                        prodItemHasChanged = true;
                                    }


                                } // end if Added_To_Work_Order__c == false, etc

                                if (pr.Added_to_work_order__c == true && pr.Work_Order__c != null) {

                                    Boolean woChanged = false;
                                    Work_Order__c wo = workOrders.get(pr.Work_Order__c);

                                    List<Product_Repair__c> repairs = new List<Product_Repair__c>();

                                    if (workOrderIDToProductRepairs.containsKey(pr.Work_Order__c)) {
                                        repairs = workOrderIDToProductRepairs.get(pr.Work_Order__c);
                                    }

                                    // OLD COMMENT: Calculates percentage of repairs done. This needs some debugging. If new repairs are done but aren't listed in the work order, it gets confused.
                                    Integer repairsdone = 0;
                                    String repairactivity = '';
                                    Integer fail = 0;
                                    Boolean harvest = false;
                                    Decimal daystorepair = 0.00;

                                    for (Product_Repair__c r : repairs) {
                                        if (r.RecordTypeId == harvestRecordType.Id) {
                                            harvest = true;
                                        }
                                        if (repairactivity == r.Repair_Activity__c) {
                                            fail = fail - 1;
                                            repairactivity = '';
                                        }
                                        if (r.Repair_date__c != null) {
                                            repairsdone += 1;
                                        }
                                        if (r.Repair_date__c == null && r.RecordTypeId != harvestRecordType.Id) {
                                            daystorepair += r.Repair_Activity_Lead_Time__c;
                                        }
                                        if (r.Repair_Result__c == 'FAIL') {
                                            fail += 1;
                                            repairactivity = r.Repair_Activity__c;
                                        }
                                        System.debug('THIS IS THE FAIL >>> ' + fail + ' AND THIS IS THE ACTIVITY >>> ' + repairactivity);
                                    }

                                    if (!Validator_Class.isFlagSet('WO caused the PR Update')) {
                                        if (daystorepair > 0 && (wo.Estimated_days_to_repair__c != daystorepair)) {
                                            wo.Estimated_days_to_repair__c = daystorepair;
                                            woChanged = true;
                                        }
                                        // Updates work order status based on what percentage of repairs are done
                                        if (repairsdone > 0 && wo.Status__c != 'Repairs in progress'
                                                && wo.Status__c != 'Repairs done; needs testing'
                                                && wo.Status__c != 'Completed'
                                                && wo.Work_Order_Type__c == 'Repair Work Order') {
                                            wo.Status__c = 'Repairs in progress';
                                            woChanged = true;
                                        }
                                        if (repairs.size() == repairsdone && fail == 0
                                                && wo.Status__c != 'Repairs done; needs testing'
                                                && wo.Status__c != 'Completed'
                                                && wo.Work_Order_Type__c == 'Repair Work Order') {
                                            wo.Status__c = 'Repairs done; needs testing';
                                            woChanged = true;
                                        }
                                        if (wo.Status__c != 'Repairs behind schedule' && (fail > 0 && wo.Work_Order_Type__c == 'Repair Work Order')
                                                || (wo.Work_Order_Type__c == 'Repair Work Order'
                                                && (wo.Estimated_Ready_Date__c < wo.Estimated_Repair_Start_Date__c))) {
                                            wo.Status__c = 'Repairs behind schedule';
                                            woChanged = true;
                                        }
                                        if (harvest == true && repairsdone == 0 && wo.Status__c != 'Work order placed') {
                                            wo.Status__c = 'Work order placed';
                                            woChanged = true;
                                        }
                                    }

                                    if (harvest == true && repairsdone > 0) {

                                        // If all harvest repair activity is done, scrapped out parent asset. This may need to be changed to a manual process.
                                        if (repairs.size() == repairsdone) {
                                            if (!Validator_Class.isFlagSet('WO caused the PR Update') && wo.Status__c != 'Completed') {
                                                wo.Status__c = 'Completed';
                                                woChanged = true;
                                            }

                                            if (pitem.Added_to_Work_Order__c != false) {
                                                pitem.Added_to_Work_Order__c = false;
                                                prodItemHasChanged = true;
                                            }

                                            if (pitem.Functional_Rating__c != 'Scrap') {
                                                pitem.Functional_Rating__c = 'Scrap';
                                                prodItemHasChanged = true;
                                            }

                                            if (pitem.Cosmetic_Rating__c != 'Scrap') {
                                                pitem.Cosmetic_Rating__c = 'Scrap';
                                                prodItemHasChanged = true;
                                            }

                                            if (pitem.Location__c != 'Scrap') {
                                                pitem.Location__c = 'Scrap';
                                                prodItemHasChanged = true;
                                            }

                                            if (pitem.sold__c != true) {
                                                pitem.sold__c = true;
                                                prodItemHasChanged = true;
                                            }

                                        } else if (!Validator_Class.isFlagSet('WO caused the PR Update') && wo.Status__c != 'Harvesting in progress') {
                                            wo.Status__c = 'Harvesting in progress';
                                            woChanged = true;
                                        }
                                    }

                                    if (woChanged) {
                                        wosToUpdateMap.put(wo.Id, wo);
                                    }
                                }

                            } // end ifAfter

                            if (pitem != null && prodItemHasChanged == true) {
                                pItemsToUpdateMap.put(pitem.Id, pitem);
                            }
                        } // end ProdPrice != null OR we are in an After trigger or have a PR added_to_WO = false
                    }

                    System.debug('Have this many Review Status to insert: ' + revStatToInsert.size());
                    if (!revStatToInsert.isEmpty()) {
                        DatabaseService.insertList(revStatToInsert);
                    }

                    System.debug('Have this many ProductItems to update: ' + pItemsToUpdateMap.size());
                    if (!pItemsToUpdateMap.isEmpty()) {
                        DatabaseService.updateList(pItemsToUpdateMap.values());
                    }

                    System.debug('Have this many WorkOrders to update: ' + wosToUpdateMap.size());
                    if (!wosToUpdateMap.isEmpty()) {
                        DatabaseService.updateList(wosToUpdateMap.values());
                    }
                    
                    System.debug('Have this many Move Locations to insert: ' + MoveLocationsToInsert.size());
                    if (!MoveLocationsToInsert.isEmpty()) {
                        DatabaseService.insertList(MoveLocationsToInsert);
                    }
                }
            }
        }

        if (Trigger.isAfter || (Trigger.isBefore && Trigger.isDelete)) {
            GH_Logger.debug('About to call updateRelatedProductItems');
            updateRelatedProductItems(newRecs, oldRecs);
            if(Trigger.isDelete){
                checkdeletes(oldRecs);
            }
        }
    }

    @TestVisible
    private void processHarvestProductRepairs(Map<Id, Product_Repair__c> recsToProcess, Map<Id, Product_Repair__c> oldRecValues) {

        GH_Logger.debug('Start of processHarvestProductRepairs()');

        // Validator class prevents multiple loops of code
        if (!Validator_Class.isFlagSet('Harvest Parts Trigger')) {

            GH_Logger.debug('Setting flag for Harvest Parts Trigger');
            Validator_Class.setFlag('Harvest Parts Trigger');

            Id harvestRecTypeId;

            for (RecordType rt : ProboCommonUtils.getRecordTypes('Product_Repair__c')) {

                if (rt.IsActive && rt.DeveloperName == 'Harvest') {
                    harvestRecTypeId = rt.Id;
                    break;
                }
            }
			
            

            Set<Id> pRepairIdsToProcess = new Set<Id>();
            Map<Id, ProductItem__c> pRepTopItemToInsert = new Map<Id, ProductItem__c>();
            List<String> productNames = new List<String>();
            for (Product_Repair__c pr: recsToProcess.values()){
                // Some parts are for more than one model. But only one model can be linked. Most of the time, this applies
                // to products that are the same name but for different systems. The products are named "Philips X5-1 for XXX"
                // so the code pulls in the information to filter for the array for Philips X5-1, instead of the full name.
                // This allows one part to be used for multiple products.
                String ShortProductName = pr.Product_Name__c;
                
                if (ShortProductName != null){
                    productNames.add(pr.Product_Name__c);
                    Integer ForNumber = ShortProductName.indexOfIgnoreCase('for');
                    if (ForNumber > 0) {
                        ShortProductName = ShortProductName.left(ForNumber);
                    }
                    productNames.add(ShortProductName);
                }
                if(pr.Part_to_Harvest__c != null){
                    productNames.add(pr.Part_to_Harvest__c);
                }
                
            }
            
            List<Product2> prodList = new List<Product2>([
                    SELECT Id, Name, Parent_Product__c, Parent_Product__r.Name
                    FROM Product2 WHERE Name IN:productNames
            ]);
            for (Product_Repair__c pr : recsToProcess.values()) {

                // This is only for harvest repairs. This will look up the product name that is linked to the parent product.
                // But if none is found, then it does a general search using the short product name (explained above).
                // All part product names use the convention of "Part - Product Name", so this code searches accordingly.

                if (pr.RecordTypeId == harvestRecTypeId && pr.Part_to_Harvest__c != null) {

                    Id ProductID;

                    GH_Logger.debug('The pr.Part_to_Harvest__c is ' + pr.Part_to_Harvest__c);
                    // if this is a Product we want to look up

                    for (Product2 p : prodList) {
                        if (p.Name.containsIgnoreCase(pr.Part_to_Harvest__c) && p.Parent_Product__r.Name == pr.Product_Name__c) {
                            GH_Logger.debug('Matched on pr.Part_to_Harvest__c and Parent_Product_Name: ' + p.Parent_Product__r.Name);
                            ProductID = p.Id;
                            break;
                        }
                    }

                    if (ProductID == null
                            && (pr.Part_to_Harvest__c == 'Array' || pr.Part_to_Harvest__c == 'Array Carriage')) {

                        GH_Logger.debug('Working with an Array or Array Carriage');
                        String ShortProductName = pr.Product_Name__c;
                
                        if (ShortProductName != null){
                            Integer ForNumber = ShortProductName.indexOfIgnoreCase('for');
                            if (ForNumber > 0) {
                                ShortProductName = ShortProductName.left(ForNumber);
                            }
                        }
                        for (Product2 p : prodList) {
                            if (p.Name.containsIgnoreCase(pr.Part_to_Harvest__c) && ShortProductName != null
                                    && p.Name.containsIgnoreCase(ShortProductName)) {
                                GH_Logger.debug('Matched on Name and pr.Part_to_Harvest__c: ' + p.Name);
                                ProductID = p.Id;
                                break;
                            }
                        }
                    }

                    GH_Logger.debug('THIS IS THE PRODUCT ID >>>>> ' + ProductID);

                    // This creates the new asset for the part that was harvested and assigns it to the correct part product.
                    // It links it to the asset it was harvested from through the harvested_probe__c field. Then the notes in the
                    // repair are updated with the new asset number of this part. If the part product was not found, the notes will
                    // reflect this to inform the tech that they still need to manually create the new part that was harvested.

                    if (pr.Repair_date__c != null && (oldRecValues == null || oldRecValues.get(pr.Id).Repair_date__c == null)) {

                        pRepairIdsToProcess.add(pr.Id);

                        if (ProductID != null) {

                            ProductItem__c item = new ProductItem__c(Product_Name__c = ProductID,
                                    Receive_date__c = Date.today(),
                                    Harvested_Probe__c = pr.Product_Item__c,
                                    Check_In_Type__c = 'Harvested');

                            pRepTopItemToInsert.put(pr.Id, item);
                        }
                    }
                }
            }

            // now we can update pRepairs as needed
            if (!pRepairIdsToProcess.isEmpty()) {

                Map<Id, ProductItem__c> pitemInfoMap = new Map<Id, ProductItem__c>();

                GH_Logger.debug('We have this many pItems to Insert: ' + pRepTopItemToInsert.size());
                if (!pRepTopItemToInsert.isEmpty()) {

                    // insert the pItems
                    insert pRepTopItemToInsert.values();

                    // query them back so we can get their Name (AutoNumber) values
                    pitemInfoMap = new Map<Id, ProductItem__c>([
                            SELECT Id, Name
                            FROM ProductItem__c
                            WHERE Id IN :pRepTopItemToInsert.values()
                    ]);
                }

                List<Product_Repair__c> pRepairsToUpdate = new List<Product_Repair__c>();

                // for all the PReps we need to update
                for (Id thispRepId : pRepairIdsToProcess) {

                    Product_Repair__c pr = new Product_Repair__c(Id = thispRepId);
                    String repNoteMessage = '';

                    // if they have a ProductID, reference it in the Repair_Notes__c
                    if (pRepTopItemToInsert.containsKey(thispRepId)
                            && pitemInfoMap.containsKey(pRepTopItemToInsert.get(thispRepId).Id)) {

                        repNoteMessage = 'THE NEW PART NUMBER IS: ' + pitemInfoMap.get(pRepTopItemToInsert.get(thispRepId).Id).Name;

                    } else {
                        repNoteMessage = 'NO PRODUCT WAS FOUND FOR THE PART. PLEASE MANUALLY CREATE THE NEW ASSET NUMBER FOR THIS PART';
                    }

                    if (recsToProcess.get(thispRepId).Repair_Notes__c != null) {
                        pr.Repair_Notes__c = recsToProcess.get(thispRepId).Repair_Notes__c + '\n\n' + repNoteMessage;
                    } else {
                        pr.Repair_Notes__c = repNoteMessage;
                    }

                    pRepairsToUpdate.add(pr);
                }

                GH_Logger.debug('We have this many pRepairs to update: ' + pRepairsToUpdate.size());

                if (!pRepairsToUpdate.isEmpty()) {
                    DatabaseService.updateList(pRepairsToUpdate);
                }
            }
        }

        GH_Logger.debug('End of processHarvestProductRepairs()');
    }

    @TestVisible
    @future
    private static void calcProductItemLastRepairDates(Set<Id> pItemIds) {

        //  For each ProductItem__c record, find the most recent Repair_Date__c for child ProductRepair__c records

        GH_Logger.debug('Start of calcProductItemLastRepairDates()');

        if (pItemIds != null && !pItemIds.isEmpty()) {
            GH_Logger.debug('have pItemIDs to process: ' + pItemIds);

            Map<Id, Datetime> pItemToRepairDate = new Map<Id, Datetime>();

            GH_Logger.debug('init to null in case there are no more Product_Repairs__c on this ProductItem__c');
            for (Id thisPItemId : pItemIds) {
                pItemToRepairDate.put(thisPItemId, null);
            }

            for (Product_Repair__c pr : [
                    SELECT Id, Repair_date__c, Product_Item__c
                    FROM Product_Repair__c
                    WHERE Product_Item__c IN :pItemToRepairDate.keySet()
                    AND Repair_date__c != NULL
                    ORDER BY Repair_date__c DESC
            ]) {

                // only set the date for the most recent value
                if (pItemToRepairDate.get(pr.Product_Item__c) == null) {
                    pItemToRepairDate.put(pr.Product_Item__c, pr.Repair_date__c);
                }
            }

            List<ProductItem__c> pItemsToUpdate = new List<ProductItem__c>();
            for (Id pItemID : pItemToRepairDate.keySet()) {
                pItemsToUpdate.add(new ProductItem__c(Id = pItemID, Last_Repair__c = pItemToRepairDate.get(pItemId)));
            }

            DatabaseService.updateList(pItemsToUpdate);
        }
        GH_Logger.debug('End of calcProductItemLastRepairDates()');
    }

    @TestVisible
    private void updateRelatedProductItems(List<Product_Repair__c> newValues, Map<Id, Product_Repair__c> oldRecs) {

        GH_Logger.debug('Start of updateRelatedProductItems()');

        GH_Logger.debug('submitting recalc request for ProductItem__c.Last_Repair__c date');
        List<Product_Repair__c> recsToCheck = Trigger.isAfter ? newValues : oldRecs.values();

        Set<Id> pItemsToRecalcDates = new Set<Id>();

        for (Product_Repair__c pr : recsToCheck) {

            if (pr.Product_Item__c != null
                    && (
                    ((Trigger.isInsert || Trigger.isDelete) && pr.Repair_date__c != null)
                            ||
                            (Trigger.isUpdate  && pr.Repair_date__c != oldRecs.get(pr.Id).Repair_date__c)
            )
                    ) {
                pItemsToRecalcDates.add(pr.Product_Item__c);
            }
        }

        if (!pItemsToRecalcDates.isEmpty()) {
            calcProductItemLastRepairDates(pItemsToRecalcDates);
        }

        GH_Logger.debug('finished submitting recalc request for ProductItem__c.Last_Repair__c date');

        GH_Logger.debug('End of updateRelatedProductItems()');
    }
    
     // This prevents anyone from deleting a completed repair.
    private void checkDeletes(Map<Id, Product_Repair__c> oldRecs) {
        for (Product_Repair__c repair : oldRecs.values()) {
            if ((repair.Repair_date__c != null)) {
                repair.addError('You can not delete a repair once it has been completed !');
            }
        }
    }

}