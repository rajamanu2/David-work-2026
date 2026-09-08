public without sharing class WorkOrderTriggerHandler {

    // Still trying to figure out any pattern of business logic so make sure this class is rem'd
    public static void processWOs(List<Work_Order__c> newWOs, Map<Id, Work_Order__c> oldWOs) {

        Id repairWORecTypeId;
        Id harvestWORecTypeId;
        Id testingWORecTypeId;

        for (RecordType r : ProboCommonUtils.getRecordTypes('Work_Order__c')) {

            if (r.IsActive) {
                switch on r.DeveloperName {
                    when 'Repair_Work_Order' {
                        repairWORecTypeId = r.Id;
                    }
                    when 'Harvest_Work_Order' {
                        harvestWORecTypeId = r.Id;
                    }
                    when 'Testing_Work_Order' {
                        testingWORecTypeId = r.Id;
                    }
                }
            }
        }

        Id functionalRecordTypeId;
        Id functionalTEERecordTypeId;
        Id cosmeticRecordTypeId;
        Id cosmeticTEERecordTypeId;
        Id HarvestRTId;

        for (RecordType r : ProboCommonUtils.getRecordTypes('Product_Repair__c')) {

            if (r.IsActive) {
                switch on r.Name {
                    when 'Functional Repair' {
                        functionalRecordTypeId = r.Id;
                    }
                    when 'Functional TEE Repair' {
                        functionalTEERecordTypeId = r.Id;
                    }
                    when 'Cosmetic Repair' {
                        cosmeticRecordTypeId = r.Id;
                    }
                    when 'Cosmetic TEE Repair' {
                        cosmeticTEERecordTypeId = r.Id;
                    }
                    when 'Harvest' {
                        HarvestRTId = r.Id;
                    }
                }
            }
        }

        Set<Id> pItemsNeeded = new Set<Id>();
        Set<Id> rmasNeeded = new Set<Id>();

        // JMAY -- removed this since we have to update related Asset__c when WO is marked Completed
 //       Integer numJustCompleted = 0;

        for (Work_Order__c wo : newWOs) {
/*
            if (wo.Status__c == 'Completed' && (Trigger.isInsert || (oldWOs.get(wo.Id).Status__c != wo.Status__c))) {
                numJustCompleted++;
            }
*/
            if (wo.Asset__c != null) {
                pItemsNeeded.add(wo.Asset__c);
            }

            if (wo.Repair_RMA__c != null) {
                rmasNeeded.add(wo.Repair_RMA__c);
            }
        }
/*
        if (numJustCompleted == newWOs.size()) {
            System.debug('All WOs in the trigger were just marked as Completed - no work to do.');
            return;
        }
*/
        Map<Id, ProductItem__c> pItemIDTopItem = new Map<Id, ProductItem__c>();
        if (!pItemsNeeded.isEmpty()) {
            pItemIDTopItem = new Map<Id, ProductItem__c>([
                    SELECT Id, Name, Product_Name__c, Possible_Cosmetic_Repairs__c, Possible_Functional_Repairs__c,
                            Probe_Type__c, These_Repairs_Cannot_Be_Done__c, Added_to_Work_Order__c
                    FROM ProductItem__c
                    WHERE Id IN :pItemsNeeded
            ]);
        }

        Map<Id, RMA__c> rmaIDToRMA = new Map<Id, RMA__c>();
        if (!rmasNeeded.isEmpty()) {
            rmaIDToRMA = new Map<Id, RMA__c>([SELECT Id, Repairs_Completed__c FROM RMA__c WHERE Id IN :rmasNeeded]);
        }


        Map<Id, Map<Id, List<Product_Repair__c>>> woIDToPItemIdToProdRepair = new Map<Id, Map<Id, List<Product_Repair__c>>>();
        Map<Id, List<Product_Repair__c>> pItemToProdRepairList = new Map<Id, List<Product_Repair__c>>();

        // no sense querying in Insert since there are no related records (Work_Order__c in newWOs
        if (Trigger.isUpdate && !pItemsNeeded.isEmpty()) {

            for (Product_Repair__c pr : [
                    SELECT Id, Repair_Activity__c, Part_to_Harvest__c, Repair_date__c, Work_Order__c, Product_Item__c,
                            CreatedDate, No_longer_needed__c, Time_Stamp_No_Longer_Needed__c,
                            Reason_for_why_no_longer_needed__c, Added_to_work_order__c, Estimated_Repair_Time__c
                    FROM Product_Repair__c
                    WHERE Product_Item__c IN :pItemsNeeded
                    ORDER BY Repair_Activity__c ASC
            ]) {

                if (pr.Repair_Activity__c == 'Harvest' && pr.Repair_date__c == null
                        && Trigger.newMap.containsKey(pr.Work_Order__c)) {

                    if (!woIDToPItemIdToProdRepair.containsKey(pr.Work_Order__c)) {
                        woIDToPItemIdToProdRepair.put(pr.Work_Order__c, new Map<Id, List<Product_Repair__c>>());
                    }

                    if (!woIDToPItemIdToProdRepair.get(pr.Work_Order__c).containsKey(pr.Product_Item__c)) {
                        woIDToPItemIdToProdRepair.get(pr.Work_Order__c).put(pr.Product_Item__c, new List<Product_Repair__c>());
                    }

                    woIDToPItemIdToProdRepair.get(pr.Work_Order__c).get(pr.Product_Item__c).add(pr);
                }

                if (!pItemToProdRepairList.containsKey(pr.Product_Item__c)) {
                    pItemToProdRepairList.put(pr.Product_Item__c, new List<Product_Repair__c>());
                }
                pItemToProdRepairList.get(pr.Product_Item__c).add(pr);
            }
        }

        // END OF OVERALL TRIGGER SETUP

        Map<Id, ProductItem__c> pItemsToUpdateMap = new Map<Id, ProductItem__c>();
        List<Product_Repair__c> harvestrepairsToInsert = new List<Product_Repair__c>();
        List<Product_Repair__c> addedRepairListToUpdate = new List<Product_Repair__c>();
        List<Product_Repair__c> repairsToInsert = new List<Product_Repair__c>();
        Map<Id, Product_Repair__c> prodRepairsToUpdateMap = new Map<Id, Product_Repair__c>();

        for (Work_Order__c wo : newWOs) {

            Work_Order__c OldWO = Trigger.isInsert ? null : oldWOs.get(wo.Id);
            ProductItem__c pItemForthisWO;
            Set<String> cannotrepairs = new Set<String>();

            if (wo.Asset__c != null) {
                pItemForthisWO = pItemIDTopItem.get(wo.Asset__c);

                if (pItemForthisWO.These_Repairs_Cannot_Be_Done__c != null) {
                    for (String c : pItemForthisWO.These_Repairs_Cannot_Be_Done__c.split(';')) {
                        cannotrepairs.add(c);
                    }
                }
            }

            List<Product_Repair__c> allproductRepairlist = new List<Product_Repair__c>();
            RMA__c repairRMA;
            Set<String> allrepairset = new Set<String>();
            Set<Product_Repair__c> allProductRepairSet = new Set<Product_Repair__c>();
            Set<Product_Repair__c> neededProductRepairSet = new Set<Product_Repair__c>();
            Set<String> NeededProductRepairString = new Set<String>();

            if (wo.RecordTypeId == repairWORecTypeId) {

                if (pItemForthisWO != null && pItemToProdRepairList.containsKey(pItemForthisWO.Id)) {
                    allproductRepairlist = pItemToProdRepairList.get(pItemForthisWO.Id);
                }

                System.debug('THIS IS THE ALL PRODUCT REPAIR LIST: ' + allproductRepairlist);

                if (wo.Repair_RMA__c != null) {
                    repairRMA = rmaIDToRMA.get(wo.Repair_RMA__c);
                }

                // Adjusts repairs on work order based on what is listed in the work order repairs and also which have been marked as no longer needed.
                for (Product_Repair__c r : allproductRepairlist) {

                    System.debug('THIS IS THE REPAIR DATE: ' + r.Repair_date__c + ' AND THIS IS THE WO CREATED DATE: ' + wo.CreatedDate);

                    if ((r.Repair_date__c == null && r.No_longer_needed__c == false)
                            || (r.No_longer_needed__c == true && r.Time_Stamp_No_Longer_Needed__c > wo.CreatedDate)
                            || r.Repair_date__c != null && r.Repair_date__c > wo.CreatedDate) {

                        allProductRepairSet.add(r);
                        allrepairset.add(r.Repair_Activity__c);

                        if (r.No_longer_needed__c == false) {
                            neededProductRepairSet.add(r);
                            NeededProductRepairString.add(r.Repair_Activity__c);
                        }
                    }
                }
            }

            if (Trigger.isBefore) {

                // start of always Before
                if (wo.RecordTypeId == repairWORecTypeId) {

                    Decimal totaltime = 0;
                    Decimal completedtime = 0;

                    for (Product_Repair__c r : allproductRepairlist) {
                        if (r.No_longer_needed__c == false && r.Estimated_Repair_Time__c != null && (r.Repair_date__c == null || r.Repair_date__c > wo.CreatedDate)) {
                            totaltime += r.Estimated_Repair_Time__c;
                            if (r.Repair_date__c != null) {
                                completedtime += r.Estimated_Repair_Time__c;
                            }
                        }
                    }

                    // Calculates percent repairs completed - may need tweaking because some repairs are added to the asset but not perfectly synced on the work order.
                    if (totaltime != 0) {
                        wo.Percent_Repairs_Completed__c = (completedtime / totaltime) * 100;
                        // TODO: From Natalie - we want to fix this so the field is updated
                        if (repairRMA != null) {
                            repairRMA.Repairs_Completed__c = wo.Percent_Repairs_Completed__c;
                        }
                    }

                    String possiblerepairs = '';

                    for (String r : allrepairset) {
                        possiblerepairs += r + '; ';
                    }

                    wo.Possible_Repairs__c = possiblerepairs;

               //   same record type as above. removing 07.25.2021 
             //    } else if (wo.RecordTypeId == repairWORecTypeId) { 

                    // Automatically links repairs to work order and selects which repairs will be needed based on quick repair selection
                    if (wo.Quick_Repair_Selection__c != null && (Trigger.isInsert || (OldWO.Quick_Repair_Selection__c != wo.Quick_Repair_Selection__c))) {

                        List<String> repairlist = new List<String>();
                        List<String> finalrepairlist = new List<String>();
                        String finalrepairs = '';

                        System.debug('THIS IS THE QUICK REPAIR SELECTION >>>>> ' + wo.Quick_Repair_Selection__c);
                        System.debug('This is the repair list >>>> ' + repairlist);
                        for (String r : NeededProductRepairString) {

                            if (wo.Quick_Repair_Selection__c == 'All Repairs') {

                                finalrepairlist.add(r);
                                System.debug('This is for all repairs >>> ' + finalrepairlist);
                            }
                            if (wo.Quick_Repair_Selection__c == 'Only Cosmetic') {

                                if (ProboConstants.cosmetic_repair_list.contains(r)) {
                                    finalrepairlist.add(r);
                                    System.debug('This is for cosmetic repairs >>> ' + finalrepairlist);
                                }
                            }
                            if (wo.Quick_Repair_Selection__c == 'Only Refurb') {

                                if (r.contains('Refurbishment') || r.contains('Whitening') || r.contains('Paint') || r.contains('Polish')) {
                                    finalrepairlist.add(r);
                                    System.debug('This is for refurb repairs >>> ' + finalrepairlist);
                                }
                            }
                        }
                        for (String r : finalrepairlist) {
                            finalrepairs += r + '; ';
                        }
                        wo.Work_Order_Repairs__c = finalrepairs;

                        System.debug('THIS IS THE WORK ORDER REPAIRS >>>> ' + wo.Work_Order_Repairs__c);
                    }

                    // Checks if repairs are behind schedule - the estimated repair start date is not actively used in scheduling, but may be still be useful.
                    if (wo.Estimated_Ready_Date__c != null) {
                      if (wo.Work_Order_Type__c == 'Repair Work Order' && (wo.Estimated_Ready_Date__c < wo.Estimated_Repair_Start_Date__c) && wo.Status__c != 'Completed' && wo.Status__c != 'Repairs done; needs testing') {
                            wo.Status__c = 'Repairs behind schedule';
                        }
                    }
                }

               

                if (Trigger.isInsert) {
                    if (wo.RecordTypeId == testingWORecTypeId || wo.RecordTypeId == repairWORecTypeId) {
                        wo.Status__c = 'Work order placed';
                    }
                } else { // isUpdate

                    if (wo.RecordTypeId == repairWORecTypeId) {

                        System.debug('THIS IS THE WORK ORDER REPAIRS UPDATE >>> ' + wo.Work_Order_Repairs__c);
                        if (wo.Work_Order_Repairs__c != OldWO.Work_Order_Repairs__c && OldWO.Work_Order_Repairs__c != null) {
                            if (wo.Status__c == 'Repairs done; needs testing') {
                                wo.Status__c = 'Repairs in progress';
                            }
                            List<String> oldrepairlist = new List<String>();
                            Set <String> oldrepairset = new Set<String>();
                            List<String> newrepairlist = new List<String>();
                            Set<String> newrepairs = new Set<String>();

                            oldrepairlist = OldWO.Work_Order_Repairs__c.split(';');

                            if (wo.Work_Order_Repairs__c != null) {
                                newrepairlist = wo.Work_Order_Repairs__c.split(';');
                            } else {
                                newrepairlist.add('');
                            }

                            for (String o : oldrepairlist) {
                                oldrepairset.add(o);
                            }

                            if (newrepairlist.size() > 0) {
                                for (String n : newrepairlist) {
                                    if (!oldrepairset.contains(n)) {
                                        newrepairs.add(n);
                                    }
                                }
                            }

                            String newrepairstring = '';
                            for (String n : newrepairs) {
                                newrepairstring += n + '; ';
                            }

                            wo.New_Repairs__c = newrepairstring;
                        }
                    }
                }

                // end isBefore
            } else { // is After

                // start always after

                if (pItemForthisWO != null) {

                    // Unchecks added to work order box on asset - if box is checked, another work order cannot be created on the same asset
                    if (wo.Status__c == 'Work order cancelled') {
                        if (pItemForthisWO.Added_to_Work_Order__c) {
                            System.debug('Cancelled WO setting Added_to_Work_Order__c to false');
                            pItemForthisWO.Added_to_Work_Order__c = false;
                            pItemsToUpdateMap.put(pItemForthisWO.Id, pItemForthisWO);
                        }
                    } else if (wo.RecordTypeId == repairWORecTypeId && wo.Status__c == 'Completed'
                            && wo.Status__c != oldWOs.get(wo.Id).Status__c
                            && pItemForthisWO.Added_to_Work_Order__c != false) {

                            System.debug('Completed WO setting Added_to_Work_Order__c to false');
                            pItemForthisWO.Added_to_Work_Order__c = false;
                            pItemsToUpdateMap.put(pItemForthisWO.Id, pItemForthisWO);

                    } else if (!pItemForthisWO.Added_to_Work_Order__c) {
                        pItemForthisWO.Added_to_Work_Order__c = true;
                        pItemsToUpdateMap.put(pItemForthisWO.Id, pItemForthisWO);
                    }
                }


                if (wo.RecordTypeId == harvestWORecTypeId) {

                    if (wo.Parts_to_Harvest__c != null
                            && (Trigger.isInsert || oldWOs.get(wo.Id).Parts_to_Harvest__c == null)) {

                        List<String> harvestparts = wo.Parts_to_Harvest__c.split(';');

                        for (String h : harvestparts) {
                            Product_Repair__c pr = new Product_Repair__c();
                            pr.RecordTypeId = HarvestRTId;
                            pr.Product_Item__c = wo.Asset__c;
                            pr.Product_Repair_Name__c = 'Harvest';
                            pr.Repair_Activity__c = 'Harvest';
                            pr.Added_to_work_order__c = true;
                            pr.Work_Order__c = wo.Id;
                            pr.Part_to_Harvest__c = h;
                            harvestrepairsToInsert.add(pr);
                            Validator_Class.setFlag('WO caused the PR Update');
                        }
                    }
                } else if (wo.RecordTypeId == repairWORecTypeId) {

                    if (wo.Work_Order_Repairs__c != null) {

                        List<String> newrepairs2 = new List<String>();

                        if (wo.New_Repairs__c != null) {
                            newrepairs2 = wo.New_Repairs__c.split(';');
                        }

                        List<String> WorkOrderRepairs = wo.Work_Order_Repairs__c.split(';');
                        Set<String> WOrepairset = new Set<String>();
                        for (String r : WorkOrderRepairs) {
                            WOrepairset.add(r.trim());
                        }

                        // Actually inserts repairs if new repairs are needed (selected on the work order but not yet added to the asset page)
                        for (String r : newrepairs2) {

                            // we only care about those that can be repaired
                            if (!cannotrepairs.contains(r.trim()) && !allrepairset.contains(r.trim())) {

                                Product_Repair__c pr = new Product_Repair__c();
                                pr.Product_Item__c = wo.Asset__c;
                                pr.Product_Repair_Name__c = r.trim();
                                pr.Repair_Activity__c = r.trim();
                                pr.Added_to_work_order__c = true;
                                pr.Work_Order__c = wo.Id;
                                Validator_Class.setFlag('WO caused the PR Update');

                                if (ProboConstants.cosmetic_repair_list.contains(r.trim())) {

                                    if (pItemForthisWO.Probe_Type__c != 'Transesophageal') {
                                        pr.RecordTypeId = cosmeticRecordTypeId;
                                    } else {
                                        pr.RecordTypeId = cosmeticTEERecordTypeId;
                                    }

                                } else {

                                    if (pItemForthisWO.Probe_Type__c != 'Transesophageal') {
                                        pr.RecordTypeId = functionalRecordTypeId;
                                    } else {
                                        pr.RecordTypeId = functionalTEERecordTypeId;
                                    }
                                }

                                System.debug('THIS IS THE REPAIR to Insert >>>> ' + pr);
                                repairsToInsert.add(pr);
                                Validator_Class.setFlag('WO caused the PR Update');
                            }
                        }

                        System.debug('THIS IS THE REPAIR SET BEFORE DECISION >>> ' + WOrepairset);

                        // Pulls in repairs already listed on asset page; if not listed in work order repair field, automatically marked
                        // as no longer needed and notes added to explain why its marked as no longer needed. If "all repairs approved",
                        // all possible repairs are listed and any marked as no longer needed are unchecked.

                        for (Product_Repair__c pr : allProductRepairSet) {

                            Boolean changed = false;

                            if (pr.Work_Order__c != wo.Id) {
                                pr.Work_Order__c = wo.Id;
                                changed = true;
                            }

                            if (WOrepairset.contains(pr.Repair_Activity__c)) {
                                system.debug('THIS IS THE REPAIR TIME STAMP NO LONGER NEEDED >>> ' + pr.Time_Stamp_No_Longer_Needed__c + ' && THIS IS THE WO CREATED DATE >>> ' + wo.CreatedDate);
                                if (pr.No_longer_needed__c == false
                                        || (pr.No_longer_needed__c == true && pr.Time_Stamp_No_Longer_Needed__c < wo.CreatedDate)) {
									system.debug('THIS IS INSIDE NO LONGER NEEDED LOOP');
                                    if (pr.Added_to_work_order__c == false) {
                                        pr.Added_to_work_order__c = true;
                                        changed = true;
                                    }

                                    if (pr.No_longer_needed__c == true) {
                                        pr.No_longer_needed__c = false;
                                        changed = true;
                                    }

                                    if (pr.Reason_for_why_no_longer_needed__c != '' && pr.Reason_for_why_no_longer_needed__c != null) {
                                        pr.Reason_for_why_no_longer_needed__c = '';
                                        changed = true;
                                    }
                                }
                            } else {

                                if (pr.Repair_date__c != null) {
                                    if (pr.Repair_date__c > wo.CreatedDate) {

                                        if (pr.Added_to_work_order__c == false) {
                                            pr.Added_to_work_order__c = true;
                                            changed = true;
                                        }

                                        if (pr.No_longer_needed__c == true) {
                                            pr.No_longer_needed__c = false;
                                            changed = true;
                                        }

                                        if (pr.Reason_for_why_no_longer_needed__c != '' && pr.Reason_for_why_no_longer_needed__c != null) {
                                            pr.Reason_for_why_no_longer_needed__c = '';
                                            changed = true;
                                        }
                                    }
                                } else { // (pr.Repair_date__c == null) {

                                    if (pr.Added_to_work_order__c == true) {
                                        pr.Added_to_work_order__c = false;
                                        changed = true;
                                    }

                                    if (pr.No_longer_needed__c == false) {
                                        pr.No_longer_needed__c = true;
                                        changed = true;
                                    }

                                    if (pr.Reason_for_why_no_longer_needed__c != 'This repair was excluded from the Work Order for this probe.') {
                                        pr.Reason_for_why_no_longer_needed__c = 'This repair was excluded from the Work Order for this probe.';
                                        changed = true;
                                    }
                                }

                                if (wo.Work_Order_Repairs__c.contains('All Repairs Approved')) {

                                    if (pr.Added_to_work_order__c == false) {
                                        pr.Added_to_work_order__c = true;
                                        changed = true;
                                    }

                                    if (pr.No_longer_needed__c == true) {
                                        pr.No_longer_needed__c = false;
                                        changed = true;
                                    }

                                    if (pr.Reason_for_why_no_longer_needed__c != '' && pr.Reason_for_why_no_longer_needed__c != null) {
                                        pr.Reason_for_why_no_longer_needed__c = '';
                                        changed = true;
                                    }
                                }
                            }

                            if (changed) {
                                addedRepairListToUpdate.add(pr);
                                Validator_Class.setFlag('WO caused the PR Update');
                            }
                        }
                    }
                }

                // end always after

                if (Trigger.isUpdate) {

                    if (pItemForthisWO != null) {

                        if (wo.RecordTypeId == harvestWORecTypeId) {

                            if (oldWOs.get(wo.Id).Parts_to_Harvest__c != wo.Parts_to_Harvest__c
                                    && oldWOs.get(wo.Id).Parts_to_Harvest__c != null) {

                                Set<String> nolongerneeded = new Set<String>();

                                List<String> newharvestparts = new List<String>();
                                Set<String> newharvestset = new Set<String>();
                                List<String> oldharvestparts = new List<String>();
                                Set<String> oldharvestset = new Set<String>();

                                if (wo.Parts_to_Harvest__c != null) {
                                    newharvestparts = wo.Parts_to_Harvest__c.split(';');
                                    newharvestset.addAll(newharvestparts);
                                }

                                if (oldWOs.get(wo.Id).Parts_to_Harvest__c != null) {
                                    oldharvestparts = oldWOs.get(wo.Id).Parts_to_Harvest__c.split(';');
                                    oldharvestset.addAll(oldharvestparts);
                                }

                                // add any new as long as they are not in the old
                                for (String h : newharvestparts) {
                                    if (!oldharvestset.contains(h)) {
                                        Product_Repair__c pr = new Product_Repair__c();
                                        pr.RecordTypeId = HarvestRTId;
                                        pr.Product_Item__c = wo.Asset__c;
                                        pr.Product_Repair_Name__c = 'Harvest';
                                        pr.Repair_Activity__c = 'Harvest';
                                        pr.Added_to_work_order__c = true;
                                        pr.Work_Order__c = wo.Id;
                                        pr.Part_to_Harvest__c = h;
                                        harvestrepairsToInsert.add(pr);
                                        Validator_Class.setFlag('WO caused the PR Update');
                                    }
                                }

                                for (String h : oldharvestparts) {
                                    if (!newharvestset.contains(h)) {
                                        nolongerneeded.add(h);
                                    }
                                }

                                if (!nolongerneeded.isEmpty()) {

                                    for (Product_Repair__c r : woIDToPItemIdToProdRepair.get(wo.Id).get(pItemForthisWO.Id)) {
                                        if (nolongerneeded.contains(r.Part_to_Harvest__c)) {

                                            Boolean hasChanged = false;

                                            if (r.Added_to_work_order__c != false) {
                                                r.Added_to_work_order__c = false;
                                                hasChanged = true;
                                            }
                                            if (r.No_longer_needed__c != true) {
                                                r.No_longer_needed__c = true;
                                                hasChanged = true;
                                            }

                                            if (r.Reason_for_why_no_longer_needed__c != 'No longer needed for harvest work order.') {
                                                r.Reason_for_why_no_longer_needed__c = 'No longer needed for harvest work order.';
                                                hasChanged = true;
                                            }

                                            if (hasChanged) {
                                                prodRepairsToUpdateMap.put(r.Id, r);
                                            }
                                            Validator_Class.setFlag('WO caused the PR Update');
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }  // end isAfter

        } // end trigger for loop

            ////////////////   OLD CODE BELOW TO BE MOVED ABOVE HERE

/*
            if (Trigger.isInsert && Trigger.isBefore) {
                if (wo.RecordTypeId == testingWORecTypeId) {
                    wo.Status__c = 'Work order placed';
                }
            }
*/
/*

            ProductItem__c pItemForthisWO;

            Set<String> cannotrepairs = new Set<String>();

            if (wo.Asset__c != null) {
                pItemForthisWO = pItemIDTopItem.get(wo.Asset__c);

                if (pItemForthisWO.These_Repairs_Cannot_Be_Done__c != null) {
                    for (String c : pItemForthisWO.These_Repairs_Cannot_Be_Done__c.split(';')) {
                        cannotrepairs.add(c);
                    }
                }
            }
*/


/*
            if (Trigger.isAfter) {

                // Unchecks added to work order box on asset - if box is checked, another work order cannot be created on the same asset
                if (wo.Status__c == 'Work order cancelled') {
                    if (pItemForthisWO.Added_to_Work_Order__c) {
                        pItemForthisWO.Added_to_Work_Order__c = false;
                        pItemsToUpdateMap.put(pItemForthisWO.Id, pItemForthisWO);
                    }
                } else if (!pItemForthisWO.Added_to_Work_Order__c) {
                    pItemForthisWO.Added_to_Work_Order__c = true;
                    pItemsToUpdateMap.put(pItemForthisWO.Id, pItemForthisWO);
                }
            }
*/

            // For harvest work orders, automatically create harvest repairs based on harvest work order parts to harvest.
            // If parts to harvest changes, the repairs are updated accordingly. This code may be too complex and there are
            // probably ways to simplify.
            //         if (wo.RecordTypeId == harvestWORecTypeId) {

            //      if (Trigger.isAfter) {

/*
                    if (wo.Parts_to_Harvest__c != null
                            && (Trigger.isInsert || oldWOs.get(wo.Id).Parts_to_Harvest__c == null)) {

                        List<String> harvestparts = wo.Parts_to_Harvest__c.split(';');

                        for (String h : harvestparts) {
                            Product_Repair__c pr = new Product_Repair__c();
                            pr.RecordTypeId = HarvestRTId;
                            pr.Product_Item__c = wo.Asset__c;
                            pr.Product_Repair_Name__c = 'Harvest';
                            pr.Repair_Activity__c = 'Harvest';
                            pr.Added_to_work_order__c = true;
                            pr.Work_Order__c = wo.Id;
                            pr.Part_to_Harvest__c = h;
                            harvestrepairsToInsert.add(pr);
                            Validator_Class.setFlag('WO caused the PR Update');
                        }

                    }
*/

            //       if (Trigger.isUpdate) {

/*
                        if (oldWOs.get(wo.Id).Parts_to_Harvest__c != wo.Parts_to_Harvest__c
                                && oldWOs.get(wo.Id).Parts_to_Harvest__c != null) {

                            Set<String> nolongerneeded = new Set<String>();

                            List<String> newharvestparts = new List<String>();
                            Set<String> newharvestset = new Set<String>();
                            List<String> oldharvestparts = new List<String>();
                            Set<String> oldharvestset = new Set<String>();

                            if (wo.Parts_to_Harvest__c != null) {
                                newharvestparts = wo.Parts_to_Harvest__c.split(';');
                                newharvestset.addAll(newharvestparts);
                            }

                            if (oldWOs.get(wo.Id).Parts_to_Harvest__c != null) {
                                oldharvestparts = oldWOs.get(wo.Id).Parts_to_Harvest__c.split(';');
                                oldharvestset.addAll(oldharvestparts);
                            }

                            // add any new as long as they are not in the old
                            for (String h : newharvestparts) {
                                if (!oldharvestset.contains(h)) {
                                    Product_Repair__c pr = new Product_Repair__c();
                                    pr.RecordTypeId = HarvestRTId;
                                    pr.Product_Item__c = wo.Asset__c;
                                    pr.Product_Repair_Name__c = 'Harvest';
                                    pr.Repair_Activity__c = 'Harvest';
                                    pr.Added_to_work_order__c = true;
                                    pr.Work_Order__c = wo.Id;
                                    pr.Part_to_Harvest__c = h;
                                    harvestrepairsToInsert.add(pr);
                                    Validator_Class.setFlag('WO caused the PR Update');
                                }
                            }

                            for (String h : oldharvestparts) {
                                if (!newharvestset.contains(h)) {
                                    nolongerneeded.add(h);
                                }
                            }

                            if (!nolongerneeded.isEmpty()) {

                                for (Product_Repair__c r : woIDToPItemIdToProdRepair.get(wo.Id).get(pItemForthisWO.Id)) {
                                    if (nolongerneeded.contains(r.Part_to_Harvest__c)) {

                                        boolean hasChanged = false;

                                        if (r.Added_to_work_order__c != false) {
                                            r.Added_to_work_order__c = false;
                                            hasChanged = true;
                                        }
                                        if (r.No_longer_needed__c != true) {
                                            r.No_longer_needed__c = true;
                                            hasChanged = true;
                                        }

                                        if (r.Reason_for_why_no_longer_needed__c != 'No longer needed for harvest work order.') {
                                            r.Reason_for_why_no_longer_needed__c = 'No longer needed for harvest work order.';
                                            hasChanged = true;
                                        }

                                        if (hasChanged) {
                                            prodRepairsToUpdateMap.put(r.Id, r);
                                        }
                                        Validator_Class.setFlag('WO caused the PR Update');
                                    }
                                }
                            }
                        }
*/
            //    } // is Update
            //    } // is After
            //         } else
   //         if (wo.RecordTypeId == repairWORecTypeId) {

/*
                List<String> repairlist = new List<String>();
                List<String> finalrepairlist = new List<String>();
                String finalrepairs = '';
                Set<String> newrepairs = new Set<String>();

                List<Product_Repair__c> allproductRepairlist = new List<Product_Repair__c>();

                if (pItemForthisWO != null && pItemToProdRepairList.containsKey(pItemForthisWO.Id)) {
                    allproductRepairlist = pItemToProdRepairList.get(pItemForthisWO.Id);
                }

                System.debug('THIS IS THE ALL PRODUCT REPAIR LIST: ' + allproductRepairlist);

                RMA__c repairRMA;
                if (wo.Repair_RMA__c != null) {
                    repairRMA = rmaIDToRMA.get(wo.Repair_RMA__c);
                }
*/

/*
                Decimal totaltime = 0;
                Decimal completedtime = 0;
*/

//                if (Trigger.isBefore) {

/*
                    for (Product_Repair__c r : allproductRepairlist) {
                        if (r.No_longer_needed__c == false && r.Estimated_Repair_Time__c != null && (r.Repair_date__c == null || r.Repair_date__c > wo.CreatedDate)) {
                            totaltime += r.Estimated_Repair_Time__c;
                            if (r.Repair_date__c != null) {
                                completedtime += r.Estimated_Repair_Time__c;
                            }
                        }
                    }

                    // moved this inside the if before -- it would fail in an after trigger
                    // Calculates percent repairs completed - may need tweaking because some repairs are added to the asset but not perfectly synced on the work order.
                    if (totaltime != 0) {
                        wo.Percent_Repairs_Completed__c = (completedtime / totaltime) * 100;
                        // TODO: From Natalie - we want to fix this so the field is updated
                        if (repairRMA != null) {
                            repairRMA.Repairs_Completed__c = (completedtime / totaltime) * 100;
                        }
                    }
*/
                //               }


/*
                Set<String> allrepairset = new Set<String>();
                String possiblerepairs = '';

                Set<Product_Repair__c> AllProductRepairSet = new Set<Product_Repair__c>();
                Set<Product_Repair__c> NeededProductRepairSet = new Set<Product_Repair__c>();
                Set<String> NeededProductRepairString = new Set<String>();

                // Adjusts repairs on work order based on what is listed in the work order repairs and also which have been marked as no longer needed.
                for (Product_Repair__c r : allproductRepairlist) {

                    System.debug('THIS IS THE REPAIR DATE >>> ' + r.Repair_date__c + ' AND THIS IS THE WO CREATED DATE >>>> ' + wo.CreatedDate);

                    if ((r.Repair_date__c == null && r.No_longer_needed__c == false)
                            || (r.No_longer_needed__c == true && r.Time_Stamp_No_Longer_Needed__c > wo.CreatedDate)
                            || r.Repair_date__c != null && r.Repair_date__c > wo.CreatedDate) {

                        AllProductRepairSet.add(r);
                        allrepairset.add(r.Repair_Activity__c);

                        System.debug('THIS IS THE ALL REPAIR SET >>>>>' + allrepairset);

                        if (r.No_longer_needed__c == false) {
                            NeededProductRepairSet.add(r);
                            NeededProductRepairString.add(r.Repair_Activity__c);
                        }
                    }
                }
*/

   //             if (Trigger.isBefore) {

/*
                    for (String r : allrepairset) {
                        possiblerepairs += r + '; ';
                    }

                    wo.Possible_Repairs__c = possiblerepairs;
*/

     //               if (Trigger.isInsert) {
//                        System.debug('THIS IS THE ADDED TO WORK ORDER TRUE');

//                        wo.Status__c = 'Work order placed';

/*
                        // Automatically links repairs to work order and selects which repairs will be needed based on quick repair selection
                        if (wo.Quick_Repair_Selection__c != null) {
                            System.debug('THIS IS THE QUICK REPAIR SELECTION >>>>> ' + wo.Quick_Repair_Selection__c);
                            System.debug('This is the repair list >>>> ' + repairlist);
                            for (String r : NeededProductRepairString) {

                                if (wo.Quick_Repair_Selection__c == 'All Repairs') {

                                    finalrepairlist.add(r);
                                    System.debug('This is for all repairs >>> ' + finalrepairlist);
                                }
                                if (wo.Quick_Repair_Selection__c == 'Only Cosmetic') {

                                    if (ProboConstants.cosmetic_repair_list.contains(r)) {
                                        finalrepairlist.add(r);
                                        System.debug('This is for cosmetic repairs >>> ' + finalrepairlist);
                                    }
                                }
                                if (wo.Quick_Repair_Selection__c == 'Only Refurb') {

                                    if (r.contains('Refurbishment') || r.contains('Whitening') || r.contains('Paint') || r.contains('Polish')) {
                                        finalrepairlist.add(r);
                                        System.debug('This is for refurb repairs >>> ' + finalrepairlist);
                                    }
                                }
                            }
                            for (String r : finalrepairlist) {
                                finalrepairs += r + '; ';
                            }
                            wo.Work_Order_Repairs__c = finalrepairs;

                            System.debug('THIS IS THE WORK ORDER REPAIRS >>>> ' + wo.Work_Order_Repairs__c);
                        }

                        // Checks if repairs are behind schedule - the estimated repair start date is not actively used in scheduling, but may be still be useful.
                        if (wo.Estimated_Ready_Date__c != null) {
                            if (wo.Work_Order_Type__c == 'Repair Work Order' && (wo.Estimated_Ready_Date__c < wo.Estimated_Repair_Start_Date__c)) {
                                wo.Status__c = 'Repairs behind schedule';
                            }
                        }
*/
      //              }

                    // Similar code to above but for update instead of insert - should probably be combined to make code more efficient
       //             if (Trigger.isUpdate) {
/*
                        Work_Order__c OldWO = oldWOs.get(wo.Id);
                        System.debug('THIS IS THE WORK ORDER REPAIRS UPDATE >>> ' + wo.Work_Order_Repairs__c);
                        if (wo.Work_Order_Repairs__c != OldWO.Work_Order_Repairs__c && OldWO.Work_Order_Repairs__c != null) {
                            if (wo.Status__c == 'Repairs done; needs testing') {
                                wo.Status__c = 'Repairs in progress';
                            }
                            List<String> oldrepairlist = new List<String>();
                            Set <String> oldrepairset = new Set<String>();
                            List<String> newrepairlist = new List<String>();

                            oldrepairlist = OldWO.Work_Order_Repairs__c.split(';');
                            if (wo.Work_Order_Repairs__c != null) {
                                newrepairlist = wo.Work_Order_Repairs__c.split(';');
                            }
                            if (wo.Work_Order_Repairs__c == null) {
                                newrepairlist.add('');
                            }

                            for (String o : oldrepairlist) {
                                oldrepairset.add(o);
                            }


                            if (newrepairlist.size() > 0) {
                                for (String n : newrepairlist) {
                                    if (!oldrepairset.contains(n)) {
                                        newrepairs.add(n);

                                        System.debug('THIS IS THE NEW REPAIR LIST >>> ' + newrepairs);
                                    }
                                }
                            }
                            String newrepairstring = '';
                            for (String n : newrepairs) {
                                newrepairstring += n + '; ';
                            }

                            wo.New_Repairs__c = newrepairstring;


                        }
*/
/*
                        if (wo.Quick_Repair_Selection__c != null && OldWO.Quick_Repair_Selection__c != wo.Quick_Repair_Selection__c) {
                            for (String r : NeededProductRepairString) {
                                if (wo.Quick_Repair_Selection__c == 'All Repairs') {
                                    finalrepairlist.add(r);

                                }
                                if (wo.Quick_Repair_Selection__c == 'Only Cosmetic') {
                                    if (ProboConstants.cosmetic_repair_list.contains(r)) {
                                        finalrepairlist.add(r);
                                    }
                                }
                                if (wo.Quick_Repair_Selection__c == 'Only Refurb') {
                                    if (r.contains('Refurbishment') || r.contains('Whitening') || r.contains('Paint') || r.contains('Polish')) {
                                        finalrepairlist.add(r);
                                    }
                                }
                            }
                            for (String r : finalrepairlist) {
                                finalrepairs += r + '; ';
                            }
                            wo.Work_Order_Repairs__c = finalrepairs;
                            System.debug('THIS IS THE WORK ORDER REPAIRS >>>> ' + wo.Work_Order_Repairs__c);
                        }
                        if (wo.Estimated_Ready_Date__c != null) {
                            if (wo.Work_Order_Type__c == 'Repair Work Order' && (wo.Estimated_Ready_Date__c < wo.Estimated_Repair_Start_Date__c) && wo.Status__c != 'Completed' && wo.Status__c != 'Repairs done; needs testing') {
                                wo.Status__c = 'Repairs behind schedule';
                            }
                        }
*/

       //             }
      //          } else { // is After

/*
                    if (Trigger.isUpdate) {
                        Validator_Class.setAlreadyDone9();
                        System.debug('THIS IS THE WORK ORDER REPAIRS AFTER UPDATE 2 >>>> ' + wo.Work_Order_Repairs__c);

                        if (wo.Status__c == 'Completed' && wo.Status__c != oldWOs.get(wo.Id).Status__c
                                && pItemForthisWO.Added_to_Work_Order__c == true) {
                            System.debug('THIS IS THE ADDED TO WORK ORDER TURNING FALSE');
                            pItemForthisWO.Added_to_Work_Order__c = false;
                            pItemsToUpdateMap.put(pItemForthisWO.Id, pItemForthisWO);
                        }
                    }
*/

/*
                    if (wo.Work_Order_Repairs__c != null) {

                        List<String> newrepairs2 = new List<String>();

                        if (wo.New_Repairs__c != null) {
                            newrepairs2 = wo.New_Repairs__c.split(';');
                        }

                        List<String> WorkOrderRepairs = wo.Work_Order_Repairs__c.split(';');
                        Set<String> WOrepairset = new Set<String>();
                        for (String r : WorkOrderRepairs) {
                            WOrepairset.add(r.trim());
                        }

                        // Actually inserts repairs if new repairs are needed (selected on the work order but not yet added to the asset page)
                        for (String r : newrepairs2) {

                            // we only care about those that can be repaired
                            if (!cannotrepairs.contains(r.trim()) && !allrepairset.contains(r.trim())) {

                                Product_Repair__c pr = new Product_Repair__c();
                                pr.Product_Item__c = wo.Asset__c;
                                pr.Product_Repair_Name__c = r.trim();
                                pr.Repair_Activity__c = r.trim();
                                pr.Added_to_work_order__c = true;
                                pr.Work_Order__c = wo.Id;
                                Validator_Class.setFlag('WO caused the PR Update');

                                if (ProboConstants.cosmetic_repair_list.contains(r.trim())) {

                                    if (pItemForthisWO.Probe_Type__c != 'Transesophageal') {
                                        pr.RecordTypeId = cosmeticRecordTypeId;
                                    } else {
                                        pr.RecordTypeId = cosmeticTEERecordTypeId;
                                    }

                                } else {

                                    if (pItemForthisWO.Probe_Type__c != 'Transesophageal') {
                                        pr.RecordTypeId = functionalRecordTypeId;
                                    } else {
                                        pr.RecordTypeId = functionalTEERecordTypeId;
                                    }
                                }

                                System.debug('THIS IS THE REPAIR to Insert >>>> ' + pr);
                                repairsToInsert.add(pr);
                                Validator_Class.setFlag('WO caused the PR Update');
                            }
                        }

                        System.debug('THIS IS THE REPAIR SET BEFORE DECISION >>> ' + WOrepairset);

                        // Pulls in repairs already listed on asset page; if not listed in work order repair field, automatically marked
                        // as no longer needed and notes added to explain why its marked as no longer needed. If "all repairs approved",
                        // all possible repairs are listed and any marked as no longer needed are unchecked.

                        for (Product_Repair__c pr : AllProductRepairSet) {

                            Boolean changed = false;

                            if (pr.Work_Order__c != wo.Id) {
                                pr.Work_Order__c = wo.Id;
                                changed = true;
                            }

                            if (WOrepairset.contains(pr.Repair_Activity__c)) {
                                if (pr.No_longer_needed__c == false
                                        || (pr.No_longer_needed__c == true && pr.Time_Stamp_No_Longer_Needed__c < wo.CreatedDate)) {

                                    if (pr.Added_to_work_order__c == false) {
                                        pr.Added_to_work_order__c = true;
                                        changed = true;
                                    }

                                    if (pr.No_longer_needed__c == true) {
                                        pr.No_longer_needed__c = false;
                                        changed = true;
                                    }

                                    if (pr.Reason_for_why_no_longer_needed__c != '' && pr.Reason_for_why_no_longer_needed__c != null) {
                                        pr.Reason_for_why_no_longer_needed__c = '';
                                        changed = true;
                                    }
                                }
                            } else {

                                if (pr.Repair_date__c != null) {
                                    if (pr.Repair_date__c > wo.CreatedDate) {

                                        if (pr.Added_to_work_order__c == false) {
                                            pr.Added_to_work_order__c = true;
                                            changed = true;
                                        }

                                        if (pr.No_longer_needed__c == true) {
                                            pr.No_longer_needed__c = false;
                                            changed = true;
                                        }

                                        if (pr.Reason_for_why_no_longer_needed__c != '' && pr.Reason_for_why_no_longer_needed__c != null) {
                                            pr.Reason_for_why_no_longer_needed__c = '';
                                            changed = true;
                                        }
                                    }
                                } else { // (pr.Repair_date__c == null) {

                                    if (pr.Added_to_work_order__c == true) {
                                        pr.Added_to_work_order__c = false;
                                        changed = true;
                                    }

                                    if (pr.No_longer_needed__c == false) {
                                        pr.No_longer_needed__c = true;
                                        changed = true;
                                    }

                                    if (pr.Reason_for_why_no_longer_needed__c != 'This repair was excluded from the Work Order for this probe.') {
                                        pr.Reason_for_why_no_longer_needed__c = 'This repair was excluded from the Work Order for this probe.';
                                        changed = true;
                                    }
                                }

                                if (wo.Work_Order_Repairs__c.contains('All Repairs Approved')) {

                                    if (pr.Added_to_work_order__c == false) {
                                        pr.Added_to_work_order__c = true;
                                        changed = true;
                                    }

                                    if (pr.No_longer_needed__c == true) {
                                        pr.No_longer_needed__c = false;
                                        changed = true;
                                    }

                                    if (pr.Reason_for_why_no_longer_needed__c != '' && pr.Reason_for_why_no_longer_needed__c != null) {
                                        pr.Reason_for_why_no_longer_needed__c = '';
                                        changed = true;
                                    }
                                }
                            }

                            if (changed) {
                                addedRepairListToUpdate.add(pr);
                                Validator_Class.setFlag('WO caused the PR Update');
                            }
                        }
                    }
*/
      //          }
     //       }
     //   } // end for

        System.debug('Inserting this many Harvest Repairs: ' + harvestrepairsToInsert.size());
        System.debug('Updating this many added Repairs: ' + addedRepairListToUpdate.size());
        System.debug('Inserting this many Repairs: ' + repairsToInsert.size());
        System.debug('Updating this many Repairs: ' + prodRepairsToUpdateMap.size());

        if (!harvestrepairsToInsert.isEmpty() || !addedRepairListToUpdate.isEmpty()
                || !repairsToInsert.isEmpty() || !prodRepairsToUpdateMap.isEmpty()) {

            List<Product_Repair__c> allPRepairsToUpsert = new List<Product_Repair__c>();
            allPRepairsToUpsert.addAll(harvestrepairsToInsert);
            allPRepairsToUpsert.addAll(addedRepairListToUpdate);
            allPRepairsToUpsert.addAll(repairsToInsert);
            allPRepairsToUpsert.addAll(prodRepairsToUpdateMap.values());
            DatabaseService.upsertList(allPRepairsToUpsert);

        }

        System.debug('Updating this many ProductItems: ' + pItemsToUpdateMap.size());
        if (!pItemsToUpdateMap.isEmpty()) {
            DatabaseService.updateList(pItemsToUpdateMap.values());
        }


    }
}