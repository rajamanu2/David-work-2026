public class EvalUpdateFieldsHandler {
    
    public void doInsertWork(List<Evaluation_Natalie__c> newRecs){
        Set<Id> rmaIdsNeeded = new Set<Id>();

        for (Evaluation_Natalie__c r : newRecs) {
            if (r.Associated_RMA__c != null) {
                rmaIdsNeeded.add(r.Associated_RMA__c);
            }
        }
        Map<Id, RMA__c> rmaIDToRMAs = new Map<Id, RMA__c>();
        if (!rmaIdsNeeded.isEmpty()){
            rmaIDToRMAs = new Map<Id, RMA__c>([select Id, RecordTypeId, Name, Approved_Repairs__c,
                    Declined_Repairs__c, ProductItem__c, Opportunity__c, Customer_Declined_all_Repairs__c,
                    Date_RMA_Item_Received__c, Repair_turned_to_Exchange__c,
                    Date_Repair_Evaluation_Sent__c, Date_Repair_Approved__c, Probe_Deemed_Unrepairable__c,
                    Date__c, Check_In_Type__c, No_Problems_Found__c
            from RMA__c
            WHERE Id in :rmaIdsNeeded]);
        }
        for (Evaluation_Natalie__c eval : newRecs) {
            RMA__c associatedRMA;
            // This pulls in the customer repair RMA that's linked to the eval.
            if (eval.Associated_RMA__c != null && rmaIDToRMAs.containsKey(eval.Associated_RMA__c)) {
                associatedRMA = rmaIDToRMAs.get(eval.Associated_RMA__c);
            }
            if(associatedRMA.Probe_Deemed_Unrepairable__c == true){
                eval.Probe_is_unrepairable__c = true;
            }
            if(associatedRMA.No_Problems_Found__c == true){
                eval.No_Problems_Found__c = true;
            }
        }
    }
    
    
    
    public void doUpdateWork(List<Evaluation_Natalie__c> newRecs, Map<Id, Evaluation_Natalie__c> oldRecs) {
        
    // SOQL in progress, DML to do.

    Set<Id> rmaIdsNeeded = new Set<Id>();

    for (Evaluation_Natalie__c r : newRecs) {
        if (r.Associated_RMA__c != null) {
            rmaIdsNeeded.add(r.Associated_RMA__c);
        }
    }

	PriceBook2 PriceBookStandard = [select id from PriceBook2 where Name = 'Standard Price Book' limit 1];
    //PriceBook2 PriceBookStandard = [select Id from PriceBook2 where isStandard = true and isActive = true limit 1];
    RecordType EVALrt;
    RecordType LOANrt;
    RecordType EXTrt;
    RecordType MTrt;
    RecordType CORErt;
    RecordType OPPrt;
    RecordType RepairWOrderRecType;
        
    for (RecordType r : ProboCommonUtils.getRecordTypes('Work_Order__c')) {
        System.debug('CC....' + r.DeveloperName);
        if (r.DeveloperName == 'Repair_Work_Order') {
            RepairWOrderRecType = r;
            break;
        }
    }
    for (RecordType r : ProboCommonUtils.getRecordTypes('RMA__c')) {
        switch on r.Name {
            when 'Customer Repair Evaluation' {
                EVALrt = r;
            }
            when 'Loaner Return' {
                LOANrt = r;
            }
            when 'External Repair / Testing' {
                EXTrt = r;
            }
            when 'Material Transfer' {
                MTrt = r;
            }
            when 'Core Exchange' {
                CORErt = r;
            }
        }
    }
	for (RecordType r : ProboCommonUtils.getRecordTypes('Opportunity')) {
            switch on r.DeveloperName {
                when 'Probe_Sales_Opportunity' {
                    OPPrt = r;
                }
                
            }
        }
	
    Map<Id, RMA__c> rmaIDToRMAs = new Map<Id, RMA__c>();
    Map<Id, ProductItem__c> pItemIDToPItem = new Map<Id, ProductItem__c>();
    Map<Id, List<Product_Repair__c>> pItemToProductRepairs = new Map<Id, List<Product_Repair__c>>();
    Map<Id, Product2> prod2IdsToProd2 = new Map<Id, Product2>();
    Map<Id, Opportunity> oppIdToOpp = new Map<Id, Opportunity>();
    Map<Id, List<OpportunityLineItem>> oppIDToOLIs = new Map<Id, List<OpportunityLineItem>>();

    if (!rmaIdsNeeded.isEmpty()){
        rmaIDToRMAs = new Map<Id, RMA__c>([select Id, RecordTypeId, Name, Approved_Repairs__c,
                Declined_Repairs__c, ProductItem__c, Opportunity__c, Customer_Declined_all_Repairs__c,
                Date_RMA_Item_Received__c, Repair_turned_to_Exchange__c,
                Date_Repair_Evaluation_Sent__c, Date_Repair_Approved__c, Probe_Deemed_Unrepairable__c,
                Date__c, Check_In_Type__c, No_Problems_Found__c
        from RMA__c
        WHERE Id in :rmaIdsNeeded]);

        Set<Id> pItemIdsToGet = new Set<Id>();
        Set<Id> oppIdsToGet = new Set<Id>();

        for (RMA__c r : rmaIDToRMAs.values()) {
            if (r.ProductItem__c != null) {
                pItemIdsToGet.add(r.ProductItem__c);
            }

            if (r.Opportunity__c != null) {
                oppIdsToGet.add(r.Opportunity__c);
            }
        }

        if (!pItemIdsToGet.isEmpty()){

            pItemIDToPItem = new Map<Id, ProductItem__c>([
                    select Name, Serial_No__c, Probe_Type__c, Id, Cosmetic_Rating__c, Cosmetically_Repairable__c, Functional_Rating__c,
                            Functionally_Repairable__c, Repair_Evaluation__c, Outsource__c, Product_Name__c, Check_In_Type__c,
                            Estimated_Lead_Time__c, Estimated_Repair_Time__c
                    from ProductItem__c
                    where Id in :pItemIdsToGet
            ]);

            for (Product_Repair__c pr : [
                    select Id, Repair_Activity__c, Repair_date__c, Product_Item__c, No_longer_needed__c
                    from Product_Repair__c
                    where Product_Item__c in :pItemIdsToGet
                    and No_longer_needed__c = false
                    order by Repair_date__c DESC
            ]) {

                if (!pItemToProductRepairs.containsKey(pr.Product_Item__c)) {
                    pItemToProductRepairs.put(pr.Product_Item__c, new List<Product_Repair__c>());
                }
                pItemToProductRepairs.get(pr.Product_Item__c).add(pr);
            }

            Set<Id> prod2IdsToGet = new Set<Id>();

            for (ProductItem__c p : pItemIDToPItem.values()) {
                if (p.Product_Name__c != null) {
                    prod2IdsToGet.add(p.Product_Name__c);
                }
            }

            if (!prod2IdsToGet.isEmpty()){
                prod2IdsToProd2 = new Map<Id, Product2>([
                        Select Id, Name, Cable_Advanced_Whitening__c, Cable_Jacket_Splice__c,
                                Connector_Housing_Replacement__c, Connector_Housing_Paint__c, Refurb__c,
                                Lens_Refurb__c, Lens_Remove__c, Lens_Relens__c, Strain_Relief_Remove__c,
                                Strain_Relief_Replacement__c, Array_Replacement__c, Cable_Replacement__c,
                                Cap_Replacement_with_Oil_Fill__c, Connector_Repair__c, Electrical__c, Motor_Repair__c, Oil_Fill__c,
                                Probe_Handle_Close__c, Probe_Handle_Open__c, Probe_Handle_Replacement__c, Retermination__c,
                                Bending_Rubber_Glue_Beads_Replacement__c, Control_Housing_Polish__c, Grommet_Replacement__c,
                                Knob_Replacement__c, Lens_Remove_Coating_RTV_Seal_Replacement__c, RTV_Seal_Replacement__c,
                                Tip_Polish__c, Array_Drive_Switch_or_Board_Replacement__c, Array_Drive_System_Replacement__c,
                                Connector_Boards_Replacement__c, Control_Housing_Overhaul__c, Insertion_Tube_Replacement__c,
                                Steering_Cable_Adjustment__c, Steering_Cable_Replacement__c, Tip_Overhaul__c,
                                Probe_Handle_Reverse__c, Cap_Refurbishment__c, Cable_Jacket_Refurbishment__c,
                                Connector_Refurbishment__c, Probe_Handle_Refurbishment__c, Strain_Relief_Refurbishment__c,
                                Wire_splice__c, Oil_Bladder_Replacement__c, Carriage_Drive_Cable_Replacement__c,
                                Array_Carriage_Replacement__c, Connector_Overhaul__c, Max_Repair__c, Max_Non_Functional__c
                        from Product2
                        where Id in :prod2IdsToGet
                ]);
            }
        }

        if (!oppIdsToGet.isEmpty()){
            oppIdToOpp = new Map<Id, Opportunity>([
                    select Id, Related_Opportunity__c,Related_Opportunity__r.Id,
                            Related_Opportunity__r.Loaner_Turned_to_Sale__c, Related_Opportunity__r.Amount,
                            Related_Opportunity__r.Customer_PO__c, Loaner__c, Shipping_From_Location__c, 
                			AccountId, Sales_Lead_Source__c, OwnerId, Warranty_Length__c, Bill_to_Account__c,
                            Field_Service_Engineer__c, FSE_Email__c, Ship_Type__c
                    from Opportunity
                    where Id in :oppIdsToGet
            ]);

            if (!pItemIdsToGet.isEmpty()){
                for (OpportunityLineItem oli : [
                        select Id, OpportunityId, TotalPrice, Asset_No__c, ProductItem__c, Check_In_Type__c
                        from OpportunityLineItem
                        where OpportunityId in :oppIdsToGet
                        and Check_In_Type__c != 'Generic'
                        and ProductItem__c in :pItemIdsToGet
                ]) {

                    if (!oppIDToOLIs.containsKey(oli.OpportunityId)) {
                        oppIDToOLIs.put(oli.OpportunityId, new List<OpportunityLineItem>());
                    }

                    oppIDToOLIs.get(oli.OpportunityId). add(oli);
                }
            }
        }
    }


    // end of trigger setup
    Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();
    //Map<Id, OpportunityLineItem> olisToUpdate = new Map<Id, OpportunityLineItem>();
    list<OpportunityLineItem> olisToUpsert = new list<OpportunityLineItem>();
    Map<Id, RMA__c> rmasToUpdate = new Map<Id, RMA__c>();
    Map<Id, ProductItem__c> pItemsToUpdate = new Map<Id, ProductItem__c>();


    for (Evaluation_Natalie__c eval : newRecs) {

        RMA__c associatedRMA;
        Boolean associatedRMANeedsUpdate = false;

        // This pulls in the customer repair RMA that's linked to the eval.
        if (eval.Associated_RMA__c != null && rmaIDToRMAs.containsKey(eval.Associated_RMA__c)) {
            associatedRMA = rmaIDToRMAs.get(eval.Associated_RMA__c);
        }


        if (associatedRMA.ProductItem__c != null && associatedRMA.Date_RMA_Item_Received__c != null
                && pItemToProductRepairs.containsKey(associatedRMA.ProductItem__c)) {

            String RepairsCompleted = '';

            // for each Product_Repair of this PItem, see if it is after the associate.Date_RMA_Item_Received
            for (Product_Repair__c repair : pItemToProductRepairs.get(associatedRMA.ProductItem__c)) {

                if (repair.Repair_date__c > Datetime.newInstance(associatedRMA.Date_RMA_Item_Received__c, Time.newInstance(0, 0, 0, 0))) {

                    if (repair.Repair_Activity__c != null
                            && !repair.Repair_Activity__c.containsIgnoreCase('Open')
                            && !repair.Repair_Activity__c.containsIgnoreCase('Close')
                            && !repair.Repair_Activity__c.containsIgnoreCase('Remove')) {
                        RepairsCompleted += repair.Repair_Activity__c + '; ';
                    }

                } else {
                    // once we find one that is older, all the rest will also be older (SOQL order by DESC)
                    System.debug('Got to older Product_Repair records so can stop.');
                    break;
                }
            }

            eval.Repairs_Completed__c = RepairsCompleted != null ? RepairsCompleted.left(255) : null;
        }


        ProductItem__c item;
        // This pulls in related objects that are needed later on
        if (associatedRMA.ProductItem__c != null && pItemIDToPItem.containsKey(associatedRMA.ProductItem__c)) {
            item = pItemIDToPItem.get(associatedRMA.ProductItem__c);
        }

        Opportunity RepairOpp;
        OpportunityLineItem productRepairOLI;

        if (associatedRMA.Opportunity__c != null && oppIdToOpp.containsKey(associatedRMA.Opportunity__c)) {
            System.debug('Getting RMA.Opportunity__c (RepairOpp) so we can check the Opps.Related_Opportunity__c later');
            RepairOpp = oppIdToOpp.get(associatedRMA.Opportunity__c);

            if (item != null && oppIDToOLIs.containsKey(associatedRMA.Opportunity__c)) {
                for (OpportunityLineItem oli : oppIDToOLIs.get(associatedRMA.Opportunity__c)) {
                    System.debug('Checking RepairOpp OLIs for a match ot the RMA.ProductItem__c: ' + oli.ProductItem__c );
                    if (oli.ProductItem__c == item.Id) {
                        System.debug('Found a match: ' + oli.Id);
                        productRepairOLI = oli;
                        break;
                    }
                }
            }
        }

        Product2 pItemRelatedProduct;
        Map<String, Decimal> RMap = new Map<String, Decimal>();

        if (item != null && item.Product_Name__c != null && prod2IdsToProd2.containsKey(item.Product_Name__c)) {
            pItemRelatedProduct = prod2IdsToProd2.get(item.Product_Name__c);
            System.debug('Found the ProductItem related Product2: ' + pItemRelatedProduct.Id);

            // This is the pricing map that links the price for each repair from the product page to the repair.
            RMap.put('Cable Advanced Whitening', pItemRelatedProduct.Cable_Advanced_Whitening__c); RMap.put('Cable Jacket Splice', pItemRelatedProduct.Cable_Jacket_Splice__c);
            RMap.put('Connector Housing Replacement', pItemRelatedProduct.Connector_Housing_Replacement__c); RMap.put('Connector Housing Paint', pItemRelatedProduct.Connector_Housing_Paint__c);
            RMap.put('Lens Refurbishment', pItemRelatedProduct.Lens_Refurb__c); RMap.put('Lens Relens', pItemRelatedProduct.Lens_Relens__c); RMap.put('Strain Relief Replacement', pItemRelatedProduct.Strain_Relief_Replacement__c);
            RMap.put('Array Replacement', pItemRelatedProduct.Array_Replacement__c); RMap.put('Cable Replacement', pItemRelatedProduct.Cable_Replacement__c); RMap.put('Motor Repair', pItemRelatedProduct.Motor_Repair__c);
            RMap.put('Cap Replacement with Oil Fill', pItemRelatedProduct.Cap_Replacement_with_Oil_Fill__c); RMap.put('Connector Repair', pItemRelatedProduct.Connector_Repair__c); RMap.put('Electrical', pItemRelatedProduct.Electrical__c);
            RMap.put('Oil Fill', pItemRelatedProduct.Oil_Fill__c); RMap.put('Probe Handle Replacement', pItemRelatedProduct.Probe_Handle_Replacement__c); RMap.put('Retermination', pItemRelatedProduct.Retermination__c);
            RMap.put('Bending Rubber/Glue Beads Replacement', pItemRelatedProduct.Bending_Rubber_Glue_Beads_Replacement__c); RMap.put('Control Housing Polish', pItemRelatedProduct.Control_Housing_Polish__c);
            RMap.put('Grommet Replacement', pItemRelatedProduct.Grommet_Replacement__c); RMap.put('Knob Replacement', pItemRelatedProduct.Knob_Replacement__c); RMap.put('Tip Polish', pItemRelatedProduct.Tip_Polish__c);
            RMap.put('Lens Remove Coating/RTV Seal Replacement', pItemRelatedProduct.Lens_Remove_Coating_RTV_Seal_Replacement__c); RMap.put('RTV Seal Replacement', pItemRelatedProduct.RTV_Seal_Replacement__c);
            RMap.put('Array Drive Switch or Board Replacement', pItemRelatedProduct.Array_Drive_Switch_or_Board_Replacement__c); RMap.put('Control Housing Overhaul', pItemRelatedProduct.Control_Housing_Overhaul__c);
            RMap.put('Array Drive System Replacement', pItemRelatedProduct.Array_Drive_System_Replacement__c); RMap.put('Steering Cable Adjustment', pItemRelatedProduct.Steering_Cable_Adjustment__c);
            RMap.put('Connector Boards Replacement', pItemRelatedProduct.Connector_Boards_Replacement__c); RMap.put('Insertion Tube Replacement', pItemRelatedProduct.Insertion_Tube_Replacement__c);
            RMap.put('Steering Cable Replacement', pItemRelatedProduct.Steering_Cable_Replacement__c); RMap.put('Tip Overhaul', pItemRelatedProduct.Tip_Overhaul__c);
            RMap.put('Probe Handle Reverse', pItemRelatedProduct.Probe_Handle_Reverse__c); RMap.put('Cable Jacket Refurbishment', pItemRelatedProduct.Cable_Jacket_Refurbishment__c);
            RMap.put('Connector Refurbishment', pItemRelatedProduct.Connector_Refurbishment__c); RMap.put('Probe Handle Refurbishment', pItemRelatedProduct.Probe_Handle_Refurbishment__c);
            RMap.put('Cap Refurbishment', pItemRelatedProduct.Cap_Refurbishment__c); RMap.put('Connector Overhaul', pItemRelatedProduct.Connector_Overhaul__c);
            RMap.put('Strain Relief Refurbishment', pItemRelatedProduct.Strain_Relief_Refurbishment__c); RMap.put('Array Carriage Replacement', pItemRelatedProduct.Array_Carriage_Replacement__c);
            RMap.put('Ferrule Assembly', 1); RMap.put('Electrical - miscellaneous', pItemRelatedProduct.Electrical__c); RMap.put('Carriage Drive Cable Replacement', pItemRelatedProduct.Carriage_Drive_Cable_Replacement__c);
            RMap.put('Oil Bladder Replacement', pItemRelatedProduct.Oil_Bladder_Replacement__c); RMap.put('Wire splice', pItemRelatedProduct.Wire_splice__c);

        }


        List<String> required = new List<String>();
        if (eval.Required_Repairs__c != null) {
            required = eval.Required_Repairs__c.split(';');
        }

        List<String> recommended = new List<String>();
        if (eval.Recommended_Repairs__c != null) {
            recommended = eval.Recommended_Repairs__c.split(';');
        }

        Evaluation_Natalie__c OldEval = oldRecs.get(eval.Id);
        Decimal requiredcost = 0;
        Decimal fullcost = 0;


        // If recommended or required repair lists are changed, recalculates the associated price fields
        // for full (required plus recommended) and required.
        if (OldEval.Recommended_Repairs__c != eval.Recommended_Repairs__c
                || OldEval.Required_Repairs__c != eval.Required_Repairs__c) {

            if (eval.Recommended_Repairs__c != null) {
                for (String r : recommended) {
                    if (r != null && RMap.get(r) != null) {
                        fullcost += RMap.get(r);
                    }
                }
            }
            if (eval.Required_Repairs__c != null) {
                for (String r : required) {
                    if (r != null && RMap.get(r) != null) {
                        fullcost += RMap.get(r);
                        requiredcost += RMap.get(r);
                    }
                }
            }

            // TODO: this assumes there will be a matching pItemRelatedProduct (Product2)
            if (requiredcost > pItemRelatedProduct.Max_Repair__c) {
                requiredcost = pItemRelatedProduct.Max_Repair__c;
            }

            Decimal recommendedcost = fullcost - requiredcost;

            if (recommendedcost > pItemRelatedProduct.Max_Non_Functional__c) {
                recommendedcost = pItemRelatedProduct.Max_Non_Functional__c;
            }
            fullcost = requiredcost + recommendedcost;


            if (fullcost > pItemRelatedProduct.Max_Repair__c) {
                fullcost = pItemRelatedProduct.Max_Repair__c;
            }
            if(eval.Covered_Under_Contract__c == true){
                 requiredcost = 0;
                 fullcost = 0;
            }        
            eval.Required_Repairs_Price__c = requiredcost;
            eval.Full_Repair_Price__c = fullcost;

        }

        List<String> ApprovedRepairs = new List<String>();
        List<String> DeclinedRepairs = new List<String>();

        System.debug('Looking at eval Approved field');
        if (OldEval.Approved__c != eval.Approved__c) {

            System.debug('Eval.Approved has changed to: ' + eval.Approved__c );

            switch on eval.Approved__c {

                when 'Full Repairs (Recommended and Required)'{
                    // Depot repairs are text format and not in list. Exclude this step for depot repairs.
                    if(eval.Depot_Recommended_Repairs__c == null && eval.Depot_Required_Repairs__c == null){
                        for (String r : recommended) {
                        	ApprovedRepairs.add(r);
                    	}

                    	DeclinedRepairs.add('NONE');
                    }
                    
                }

                when 'Required Repairs Only'{
					// Depot repairs are text format and not in list. Exclude this step for depot repairs.
                    if(eval.Depot_Recommended_Repairs__c == null && eval.Depot_Required_Repairs__c == null){
                        for (String r : recommended) {
                            DeclinedRepairs.add(r);
                        }
                    }
                }

                when 'Declined All Options'{
                    for (String r : recommended) {
                        DeclinedRepairs.add(r);
                    }
                    for (String r : required) {
                        DeclinedRepairs.add(r);
                    }

                    ApprovedRepairs.add('NONE');

                    if (!associatedRMA.Customer_Declined_all_Repairs__c) {
                        associatedRMA.Customer_Declined_all_Repairs__c = true;

                        associatedRMANeedsUpdate = true;
                    }

                    if(associatedRMA.Date__c == null && associatedRMA.Check_In_Type__c == 'Customer Repair'){
                        associatedRMA.Date__c = Date.TODAY();
                        associatedRMANeedsUpdate = true;
                    }
                }

                when 'Exchange Probe - No Repairs'{
                    // If customer chooses exchange, updates approved and declined list to N/A and also updated the repair opp and
                    // loaner opp to close everything out: marked repair turned to exchange on repair RMA, loaner turned to sale on
                    // loaner RMA, and inserts core exchange RMA. This was originally code in BeforeUpdateOpportunity trigger but it
                    // wouldn't work with the customer portal so we moved the code to the eval trigger and it worked. When in the opp
                    // trigger, it would only check the loaner turned to sale box on the opportunity, but it wouldn't actually update
                    // the RMAs due to the loop limits. But if the loop limits were increased, then some of the other processes in that
                    // code would create duplicate RMAs. So this was the best solution.


                    ApprovedRepairs.add('N/A - Customer opted for Exchange');
                    DeclinedRepairs.add('N/A - Customer opted for Exchange');

                    
						Id LoanerID = RepairOpp.Loaner__c;
                        Loaner__c Loaner = [select ID, Loaner_Asset__c, Repair_Opportunity__c, Repair_Opportunity_Number__c, Ship_Date_New__c, Tracking_Number__c,
                                            Shipping_Street__c, Shipping_City__c, Shipping_State__c, Shipping_Postal_Code__c, Shipping_Country__c, Ship_to_Account__c,
                                            Billing_Street__c, Billing_City__c, Billing_State__c, Billing_Postal_Code__c, Billing_Country__c, Attn__c from Loaner__c where id=: LoanerID];
                        system.debug('THIS IS THE LOANER ASSET >>> ' + Loaner.Loaner_Asset__c);
                        String oppname = 'Loaner for ' + loaner.Repair_Opportunity_Number__c;
                   
                        
                      
                    PriceBook2 StandardPriceBook = [select id, isstandard from PriceBook2 where isstandard = true];    
                    Opportunity LoanerOpp = new Opportunity(Pricebook2Id = StandardPricebook.Id, RecordTypeId = OPPrt.Id, Shipping_from_location__c = RepairOpp.Shipping_from_location__c, 
                                                            StageName = 'Closed Won', Name = OppName, CloseDate = Date.today(), AccountId = RepairOpp.AccountId, Loaner_turned_to_sale__c = true,
                                                            Sales_lead_source__c = RepairOpp.Sales_Lead_Source__c, Related_Opportunity__c = repairopp.id, CurrencyIsoCode = 'USD',
                                                           	ShippingStreet__c = Loaner.Shipping_Street__c, ShippingCity__c = Loaner.Shipping_City__c, ShippingState__c = Loaner.Shipping_State__c,
                											ShippingPostalCode__c = Loaner.Shipping_Postal_Code__c, ShippingCountry__c = Loaner.Shipping_Country__c, OwnerId = RepairOpp.OwnerId,
                                                            BillingStreet__c = Loaner.Billing_Street__c, BillingCity__c = Loaner.Billing_City__c, BillingState__c = Loaner.Billing_State__c,
                											BillingPostalCode__c = Loaner.Billing_Postal_Code__c, BillingCountry__c = Loaner.Billing_Country__c, Warranty_Length__c = RepairOpp.Warranty_Length__c,
                                                            Bill_to_Account__c = RepairOpp.Bill_to_Account__c, Attention__c = Loaner.Attn__c, Customer_PO__c = eval.PO_Number__c, 
                                                            Field_Service_Engineer__c = RepairOpp.Field_Service_Engineer__c, FSE_Email__c = RepairOpp.FSE_Email__c, Ship_to_Account__c = Loaner.Ship_to_Account__c,
                                                            Ship_Type__c = 'FedEx Priority P1 (Priority Overnight)'
                                                           );
                                                           
                    	insert LoanerOpp;
                       system.debug('THIS IS THE LOANER OPP CURRENCY >> ' + LoanerOpp.CurrencyIsoCode);
                    // current validation rule prevents shipping info from being inputted with ship date
                    	LoanerOpp.Ship_Date__c = loaner.Ship_Date_New__c;
                        LoanerOpp.Tracking__c = loaner.Tracking_Number__c;
                    	OppstoUpdate.put(LoanerOpp.id, LoanerOpp);
                    	ProductItem__c LoanerAsset = [select id, Product_Name__c, Serial_No__c from ProductItem__c where Name=: Loaner.Loaner_Asset__c];
                   // List<PriceBookEntry> priceBookList = [SELECT Id, Product2Id, Product2.Id, Product2.Name FROM PriceBookEntry WHERE Product2Id='certain_id' AND PriceBook2.isStandard=true LIMIT 1];	
                       PriceBookEntry ProductPriceBook = [select id, Product2Id, Product2.Id, Product2.Name from PriceBookEntry where Product2Id =: LoanerAsset.Product_Name__c AND PriceBook2.isstandard=true AND CurrencyIsoCode = 'USD'];
                    	system.debug('THIS IS THE LOANER OLI PRICE BOOK ENTRY >> ' + ProductPriceBook + ' AND THE PRODUCT NAME >> ' + LoanerAsset.Product_Name__c);
                    	OpportunityLineItem LoanerOppOLI = new OpportunityLineItem(OpportunityId = LoanerOpp.id, Quantity = 1, ProductItem__c = LoanerAsset.Id, Purchasing_Approved__c = true, TotalPrice = eval.Exchange_Probe_Price__c, 
                                                                                   Exchange__c = true, PriceBookEntryId = ProductPriceBook.Id, Product2Id = LoanerAsset.Product_Name__c, Serial_No__c = LoanerAsset.Serial_No__c);
                       	system.debug('THIS IS THE LOANER OLI >> ' + LoanerOppOLI);
                        system.debug('THIS IS THE LOANER OLI PRICEBOOK ENTRY >> ' + LoanerOppOLI.PriceBookEntry);
                        olisToUpsert.add(LoanerOppOLI);
                        system.debug('THIS IS THE OLIS TO UPSERT AFTER LOANER OLI >> ' + olisToUpsert);
                        RepairOpp.Related_Opportunity__c = LoanerOpp.id;
                    	RepairOpp.Loaner_Turned_to_Sale__c = true;
                        RepairOpp.StageName = 'Closed Lost';
                    if(RepairOpp.Ship_Type__c == null){
                        RepairOpp.Ship_Type__c = 'FedEx Priority P1 (Priority Overnight)';
                    }
                       // system.debug('THIS IS THE OPP LINE ITEM >>> ' + opplineitem);
                        OppstoUpdate.put(RepairOpp.Id, RepairOpp);
                        
                        /*
                        Id LoanerOppId = RepairOpp.Related_Opportunity__c;
                        System.debug('THIS IS THE LOANER OPP ID: ' + LoanerOppId);

                        // TODO: SOQL in loop
                        // TODO: This won't work if there are multiple non-Generic OLIs on the LoanerOpp
                        OpportunityLineItem loanerOppOLI = [select Id, Exchange__c, TotalPrice from OpportunityLineItem where OpportunityId = :LoanerOppId and Check_In_Type__c != 'Generic'];
                        loanerOppOLI.Exchange__c = true;
                        loanerOppOLI.TotalPrice = eval.Approved_Price__c;
                        olisToUpdate.put(loanerOppOLI.Id, loanerOppOLI);
						*/
                        // TODO: SOQL in loop
                        
                        RMA__c LoanerRMA = [select Id, ProductItem__c, RMA_Item_Serial_Number__c from RMA__c where Opportunity__c = :RepairOpp.Id AND RecordTypeId = :LOANrt.Id ORDER BY CreatedDate Desc limit 1];

                        System.debug('Updating LoanerRMA ProductItem to sold = true: ' + LoanerRMA.ProductItem__c);
                        pItemsToUpdate.put(LoanerRMA.ProductItem__c, new ProductItem__c(Id = LoanerRMA.ProductItem__c, sold__c = true));

                        if (!associatedRMA.Repair_turned_to_Exchange__c) {
                            associatedRMA.Repair_turned_to_Exchange__c = true;
                            associatedRMANeedsUpdate = true;
                        }

                        LoanerRMA.Loaner_changed_to_sale__c = true;
                        rmasToUpdate.put(LoanerRMA.Id, LoanerRMA);

                        
                        RMA__c CoreRMA = new RMA__c(RecordTypeId = CORErt.Id, Opportunity__c = LoanerOpp.Id, ProductItem__c = item.Id, RMA_Item_Serial_Number__c = item.Serial_No__c,
                                Loaner_Asset_Number__c = LoanerRMA.ProductItem__c, Date_RMA_Item_Received__c = Date.today(), Loaner_RMA__c = LoanerRMA.id);

                        // DML in loop - needs to stay until we heavily re-design this trigger
                        insert CoreRMA;
                    	system.debug('THIS IS THE CORE RMA FOR LOANER EXCHANGE >> ' + CoreRMA);
						pItemsToUpdate.put(item.id, new ProductItem__c(Id = item.id, Check_In_Type__c = 'Core Exchange'));
                        associatedRMA.Core_Exchange_RMA__c = CoreRMA.Id;
                        associatedRMANeedsUpdate = true;

                        
                        System.debug('Updating LoanerOpp Turned To Sale and Closed Won');
                        // TODO: Natalie - why are we setting the Stage to Closed Won here - I thought setting the Loaner_Turned_to_sale handled that?
                       /* oppsToUpdate.put(LoanerOppId, new Opportunity(Id = LoanerOppId, Loaner_Turned_to_Sale__c = true,
                                Customer_PO__c = eval.PO_Number__c, StageName = 'Closed Won'));*/
                    
                }
            }

            // do the common work
            if ((eval.Approved__c == 'Full Repairs (Recommended and Required)')
                    || (eval.Approved__c == 'Required Repairs Only')) {
				// Depot repairs are text format and not in list. Exclude this step for depot repairs.
                if(eval.Depot_Recommended_Repairs__c == null && eval.Depot_Required_Repairs__c == null){
                    for (String r : required) {
                        ApprovedRepairs.add(r);
                    }
                }

                if(productRepairOLI != null) {
                    productRepairOLI.TotalPrice = eval.Approved_Price__c;

                    System.debug('Eval.Approved change requires an OLI update for: ' + productRepairOLI.Id);
                    //olisToUpdate.put(productRepairOLI.Id, productRepairOLI);
                    olistoUpsert.add(ProductRepairOLI);
                }
                if(RepairOpp != null) {
                    oppsToUpdate.put(RepairOpp.Id, new Opportunity(Id = RepairOpp.Id, Customer_PO__c = eval.PO_Number__c, 
                                                                   Date_Repair_Approved__c = Date.today(), StageName = 'Repair Approved'));
                                                                   
             
                }
                
            }
        }

        System.debug('Approved Repairs: ' + ApprovedRepairs);
        System.debug('Declined Repairs: ' + DeclinedRepairs);

        String ApprovedRepairsString = '';
        String DeclinedRepairsString = '';
        for (String a : ApprovedRepairs) {
            if (a != null) {
                ApprovedRepairsString += a.trim() + ';';
            }

        }
        for (String d : DeclinedRepairs) {
            if (d != null) {
                DeclinedRepairsString += d.trim() + ';';
            }

        }
        eval.Approved_Repairs__c = ApprovedRepairsString;
        eval.Declined_Repairs__c = DeclinedRepairsString;

		system.debug('THIS IS THE LINK FOR LOANER RMA >>> ' + RepairOpp + ' ; ' + RepairOpp.Loaner__c);
        // Links loaner RMA information to eval if related opportunity is linked.
        if (RepairOpp != null && RepairOpp.Loaner__c != null) {

            // TODO: SOQL in loop
            Loaner__c Loaner = [select Id, RMA__c from Loaner__c where Repair_Opportunity__c = :RepairOpp.id ORDER BY CreatedDate DESC LIMIT 1];
            if (Loaner.RMA__c != null) {
                eval.Loaner_RMA__c = Loaner.RMA__c;
            }
        }

        // Links dates and probe is unrepairable fields from eval to RMA
        if (eval.Date_Repair_Evaluation_Sent__c != null
                && (associatedRMA.Date_Repair_Evaluation_Sent__c != Date.newInstance(eval.Date_Repair_Evaluation_Sent__c.year(), eval.Date_Repair_Evaluation_Sent__c.month(), eval.Date_Repair_Evaluation_Sent__c.day()))) {
            associatedRMA.Date_Repair_Evaluation_Sent__c = Date.newInstance(eval.Date_Repair_Evaluation_Sent__c.year(), eval.Date_Repair_Evaluation_Sent__c.month(), eval.Date_Repair_Evaluation_Sent__c.day());
            associatedRMANeedsUpdate = true;

        }
        if (eval.Date_Repair_Approved__c != null
                && (associatedRMA.Date_Repair_Approved__c != Date.newInstance(eval.Date_Repair_Approved__c.year(), eval.Date_Repair_Approved__c.month(), eval.Date_Repair_Approved__c.day()))) {
            associatedRMA.Date_Repair_Approved__c = Date.newInstance(eval.Date_Repair_Approved__c.year(), eval.Date_Repair_Approved__c.month(), eval.Date_Repair_Approved__c.day());
            associatedRMANeedsUpdate = true;
        }

        if (associatedRMA.Approved_Repairs__c != ApprovedRepairsString){
            associatedRMA.Approved_Repairs__c = ApprovedRepairsString;
            associatedRMANeedsUpdate = true;
        }

        if (associatedRMA.Declined_Repairs__c != DeclinedRepairsString){
            associatedRMA.Declined_Repairs__c = DeclinedRepairsString;
            system.debug('THIS IS THE DECLINED REPAIRS FOR RMA >>> ' + DeclinedRepairsString);
            associatedRMANeedsUpdate = true;
        }

        if (associatedRMA.Probe_Deemed_Unrepairable__c != eval.Probe_is_unrepairable__c){
            associatedRMA.Probe_Deemed_Unrepairable__c = eval.Probe_is_unrepairable__c;
            associatedRMANeedsUpdate = true;
        }

        if (associatedRMANeedsUpdate){
            system.debug('THIS IS THE FINAL RMA BEFORE EVAL UPDATE >>> ' + associatedRMA);
            rmasToUpdate.put(associatedRMA.Id, associatedRMA);
        }

    } // end trigger loop

    System.debug('This many RMAs to update: ' + rmasToUpdate.size());
    if (!rmasToUpdate.isEmpty()){
        DatabaseService.updateList(rmasToUpdate.values());
    }

    /*System.debug('This many OLIs to update: ' + olisToUpdate.size());
    if (!olisToUpdate.isEmpty()){
        DatabaseService.updateList(olisToUpdate.values());
    }*/
    system.debug('THIS IS THE OLI LIST TO UPSERT >>> ' + olisToUpsert);    
    if(!olisToUpsert.isEmpty()){
        system.debug('THIS IS THE OLI LIST TO UPSERT 2 >>> ' + olisToUpsert);
        DatabaseService.upsertList(olisToUpsert);
    }

    System.debug('This many Opps to update: ' + oppsToUpdate.size());
    if (!oppsToUpdate.isEmpty()){
        system.debug('THIS IS THE OPP LIST TO UPDATE >>> ' + oppstoUpdate);
        DatabaseService.updateList(oppsToUpdate.values());
    }

    System.debug('This many ProductItems to update: ' + pItemsToUpdate.size());
    if (!pItemsToUpdate.isEmpty()){
        system.debug('THIS IS THE ASSET LIST TO UPDATE >>> ' + pItemstoUpdate);
        DatabaseService.updateList(pItemsToUpdate.values());
    }

     }

}