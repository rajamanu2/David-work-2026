public class P_RMATriggerHandler extends GH_TriggerHandlerBase {

    protected override void beforeInsert() {}
    protected override void beforeUpdate(){}
    protected override void beforeDelete(){}
    protected override void afterInsert(){}
    protected override void afterUpdate(){}
    protected override void afterDelete(){}
    protected override void afterUndelete(){}

    private Map<Id, Work_Order__c> getWorkOrderMap(List<Id> assetIds) {
        List<String> excludedStatuses = new List<String>{'Completed', 'Work order cancelled'};
        List<Work_Order__c> workOrderList = [SELECT Possible_Repairs__c,Id, Asset__c, CreatedDate 
                                                FROM Work_Order__c 
                                                WHERE Asset__c in :assetIds 
                                                AND RecordType.Name = 'Repair Work Order'
                                                AND Status__c NOT in :excludedStatuses 
                                                ORDER BY CreatedDate DESC];
        Map<Id, Work_Order__c> workOrderMap = new Map<Id, Work_Order__c>();
        for(Work_Order__c w : workOrderList) {
            workOrderMap.put(w.Asset__c, w);
        }
        return workOrderMap;
    }
    
    private Map<String, ID> getContactMap(List<String> FSENames) {
        List<Contact> contactList = [SELECT Id, Name, Account.Name 
                                                FROM Contact 
                                                WHERE Name in :FSENames
                                                AND Account.Name = 'Probo Medical - Portal'
                                                ];
        Map<String, ID> contactMap = new Map<String, ID>();
        for(Contact c : contactList) {
            contactMap.put(c.Name, c.id);
        }
        return contactMap;
    }
    
    private Map<Id, PriceBookEntry> getPriceBookEntryMap(List<ProductItem__c> productItemList, List<String> currencyList2) {
        Set<ID> productIdSet = new Set<Id>();
        for(ProductItem__c pitem: productItemList){
            if(pitem.Product_Name__c != null && !productIdSet.contains(pitem.Product_Name__c)){
                productIdSet.add(pitem.Product_Name__c);
            }
            
        }
        system.debug('THIS IS THE PRODUCT ID SET FOR PBE >>> ' + productIdSet);
        system.debug('THIS IS THE CURRENCY LIST FOR PBE >>> ' + currencyList2);
        Id pbId = ProboCommonUtils.getStdPricebookId();
        
        
        List<PriceBookEntry> PBEList = [SELECT Id, Product2Id, CurrencyIsoCode, IsActive
                                                FROM PriceBookEntry WHERE Product2Id in:productIdSet AND 
                                                CurrencyIsoCode in:currencyList2 AND IsActive = true AND
                                                Pricebook2Id = :pbId
                                                ];
        Map<Id, PriceBookEntry> PBEMap = new Map<Id, PriceBookEntry>();
        for(ProductItem__c pitem2 : productItemList) {
            for(PriceBookEntry pbe: PBEList){
                if(pitem2.Product_Name__c == pbe.Product2Id){
                    PBEMap.put(pitem2.id, pbe);
                }
            }
            
            
        }
        return PBEMap;
    }

    public void processFromCreateApprovedRepairs(){
        System.debug('processFromCreateApprovedRepair');
        System.debug('CC processFromCreateApprovedRepairs start: ' + Limits.getQueries());   
        System.debug(Validator_Class.hasAlreadyDone16());
        if (Validator_Class.hasAlreadyDone16() < 1) {
            Map<Id, User> userMap = UserUtilities.GetActiveUsers();
            System.debug('CC....userMap: ' + userMap);
            List<String> order = new List<String>();
            List<String> FSENames = new List<String>();

            // get OppIDs so we can get the Contact_Name from OCRs
            Set<Id> oppIdsToGetOCRs = new Set<Id>();
            Set<Id> prodItemIdsToGet = new Set<Id>();
            Set<Id> oppIdsForOwnerEmails = new Set<Id>();
            List<Id> serviceContractIds = new List<Id>();

            // since this trigger only cares about certain RMA_Types, if we don't have one, then we can skip SOQL
            Boolean needToGetAllData = false;
            List<Id> assetIds = new List<Id>();
            for (RMA__c rma : (List<RMA__c>)newList) {
                System.debug('CC....' + rma.Opportunity__c);
                System.debug('CC....' + rma.Contact_Name__c);
                RMA__c oldRecord = oldMap != null ? (RMA__c)oldMap.get(rma.Id) : null;

                if (rma.Contact_Name__c == null) {
                    oppIdsToGetOCRs.add(rma.Opportunity__c);
                }
                System.debug('CC...oppIdsToGetOCRs' + oppIdsToGetOCRs);

                if (rma.ProductItem__c != null) {
                    prodItemIdsToGet.add(rma.ProductItem__c);
                }
                
                if (rma.Service_Contract__c != null) {
                    serviceContractIds.add(rma.Service_Contract__c);
                }
                
                system.debug('THIS IS THE SERVICE CONTRACT IDs >>> ' + serviceContractIds);
                
                if(rma.Field_Service_Engineer__c != null){
                    if(Trigger.isInsert){
                        FSENames.add(rma.Field_Service_Engineer__c);
                    }
                    if(Trigger.isUpdate){
                        if(rma.Field_Service_Engineer_Text__c != null){
                            FSENames.add(rma.Field_Service_Engineer_Text__c);
                        }
                        else{
                            FSENames.add(rma.Field_Service_Engineer__c);
                        }
                    }
                    
                    
                }

               	if (rma.RMA_Type__c == 'Customer Repair Evaluation' 
                        || (rma.RMA_Type__c == 'Warranty Claim' &&  (rma.Check_In_Type__c == 'Customer Repair' || rma.Check_In_Type__c == 'Warranty Repair'))) {
                    needToGetAllData = true;
                }

                if (rma.Opportunity__c != null && Trigger.isBefore
                        && (Trigger.isInsert || oldRecord.Opportunity__c == null)){
                    oppIdsForOwnerEmails.add(rma.Opportunity__c );
                }

                if(rma.ProductItem__c != null) {
                    assetIds.add(rma.ProductItem__c);
                }
            }
			system.debug('THESE ARE THE FSE NAMES >> ' + FSENames);
            Map<Id, Work_Order__c> workOrderMap = getWorkOrderMap(assetIds);
            Map<String, ID> contactMap = getcontactMap(FSENames);
            system.debug('THIS IS THE CONTACT MAP >> ' + contactMap);
            Map<Id, ServiceContract> serviceContractMap = new Map<Id, ServiceContract>();
            Map<Id, Opportunity> oppIDToOpp = new Map<Id, Opportunity>();

            if (!oppIdsForOwnerEmails.isEmpty()){
                oppIDToOpp = new Map<Id, Opportunity>([select Id, Owner.Email from Opportunity where Id in :oppIdsForOwnerEmails]);
            }


            Map<Id, String> oppIDtoContactName = new Map<Id, String>();

            if (Trigger.isBefore && Trigger.isUpdate && !oppIdsToGetOCRs.isEmpty()) {
                if(oppIdsToGetOCRs.size() > 0) {
                    for (OpportunityContactRole ocr : [SELECT Id, Contact.Name, OpportunityId
                    FROM OpportunityContactRole
                    WHERE OpportunityId = :oppIdsToGetOCRs
                    AND isPrimary = TRUE]) {
                        oppIDtoContactName.put(ocr.OpportunityId, ocr.Contact.Name);
                    }
                }
            }
            
            if (!serviceContractIds.isEmpty()) {
                serviceContractMap = new Map<Id, ServiceContract>([
                        SELECT Id, RMA_Status__c
                        FROM ServiceContract
                        WHERE Id = :serviceContractIds
                ]);
                system.debug('THIS IS THE SERVICE CONTRACT MAP>>> ' + serviceContractMap);
            }
		
            Map<Id, ProductItem__c> prodItemIDToProductItem = new Map<Id, ProductItem__c>();

            //Map<Id, List<Product_Repair__c>> itemIdToRepairlist = new Map<Id, List<Product_Repair__c>>();

            
            if (!prodItemIdsToGet.isEmpty() && needToGetAllData) {

                prodItemIDToProductItem = new Map<Id, ProductItem__c>([
                        SELECT Id, Name, Probe_Type__c, Possible_Cosmetic_Repairs__c, Possible_Functional_Repairs__c,
                                Approved_Repairs__c, Declined_Repairs__c, Needs_to_be_moved_to_this_location__c,
                                Added_to_Work_Order__c, Estimated_Lead_Time__c, Estimated_Repair_Time__c, Product2_Name__c
                        FROM ProductItem__c
                        WHERE Id = :prodItemIdsToGet
                ]);
            }


            RecordType RepairWOrderRecType;
            RecordType functionalRecordType;
            RecordType functionalTEERecordType;
            RecordType cosmeticRecordType;
            RecordType cosmeticTEERecordType;
            for (RecordType r : ProboCommonUtils.getRecordTypes('Work_Order__c')) {
                System.debug('CC....' + r.DeveloperName);
                if (r.DeveloperName == 'Repair_Work_Order') {
                    RepairWOrderRecType = r;
                    break;
                }
            }
            System.debug('CC...RepairWOrderRecType.' + RepairWOrderRecType);
            if (Trigger.isBefore && Trigger.isUpdate && needToGetAllData){


                for (RecordType r : ProboCommonUtils.getRecordTypes('Product_Repair__c')) {

                    switch on r.Name {

                        when 'Functional Repair' {
                            functionalRecordType = r;
                        }
                        when 'Functional TEE Repair' {
                            functionalTEERecordType = r;
                        }
                        when 'Cosmetic Repair' {
                            cosmeticRecordType = r;
                        }
                        when 'Cosmetic TEE Repair' {
                            cosmeticTEERecordType = r;
                        }
                    }
                }
            }

            List<Work_Order__c> workOrdersToUpsert = new List<Work_Order__c>();
            List<ProductItem__c> pItemsToUpdate = new List<ProductItem__c>();
            List<Product_Repair__c> insertrepair = new List<Product_Repair__c>();
            List<ServiceContract> serviceContractsToUpdate = new List<ServiceContract>();

            // This is the main trigger loop

            for (RMA__c rma : (List<RMA__c>)newList) {

                RMA__c oldRecord = oldMap != null ? (RMA__c)oldMap.get(rma.Id) : null;

                if (Trigger.isBefore && Trigger.isUpdate){
                    if (rma.Contact_Name__c == null && oppIDtoContactName.containsKey(rma.Opportunity__c)) {
                        rma.Contact_Name__c = oppIDtoContactName.get(rma.Opportunity__c);
                    }
                }
                
                ServiceContract serviceContractItem;
                if(rma.Service_Contract__c != null && serviceContractMap.containsKey(rma.Service_Contract__c)){
                    serviceContractItem = serviceContractMap.get(rma.Service_Contract__c);
                    system.debug('THIS IS THE SERVICE CONTRACT >>> ' + serviceContractItem);
                    if(Trigger.isInsert){
                        if(serviceContractItem.RMA_Status__c != 'Open RMA'){
                            serviceContractItem.RMA_Status__c = 'Open RMA';
                            if(!serviceContractsToUpdate.contains(serviceContractItem)){
                                serviceContractsToUpdate.add(serviceContractItem);
                            }
                        	
                        }
                        
                    }
                    if(Trigger.isUpdate && Trigger.isAfter){
                        system.debug('THIS IS THE GENERAL RMA STATUS >>> ' + rma.General_RMA_Status__c);
                        if(rma.General_RMA_Status__c == 'Closed RMA' && serviceContractItem.RMA_Status__c != 'Closed RMA'){
                            serviceContractItem.RMA_Status__c = 'Closed RMA';
                            if(!serviceContractsToUpdate.contains(serviceContractItem)){
                                serviceContractsToUpdate.add(serviceContractItem);
                            }
                        }
                     }
            		
                }
				

                System.debug('The following block is the code replacement for RMA WFR FUs');
                if (Trigger.isBefore) {

                    if (rma.Opportunity__c != null
                            && (Trigger.isInsert || oldRecord.Opportunity__c == null)) {
                        rma.Opportunity_Owner_Email__c = oppIDToOpp.get(rma.Opportunity__c).Owner.Email;
                    }

                    if (rma.Estimated_Ship_Date__c == null && rma.Current_Estimated_Ship_Date__c != null) {
                        rma.Estimated_Ship_Date__c = rma.Current_Estimated_Ship_Date__c;
                    }

                    if (rma.Account_Name__c != null){
                        rma.Account_Name_for_customer_portal__c = rma.Account_Name__c;
                    }
                    
                    if (rma.Field_Service_Engineer__c != null && (Trigger.isInsert || (Trigger.isUpdate && ((oldRecord.Field_Service_Engineer_Text__c != rma.Field_Service_Engineer_Text__c) || rma.FSE_Portal_Contact__c == null)))){
                        if(Trigger.isInsert){
                            rma.Field_Service_Engineer_Text__c = rma.Field_Service_Engineer__c;
                        }
                        try{
                            if(rma.Field_Service_Engineer_Text__c != null){
                                rma.FSE_Portal_Contact__c = contactMap.get(rma.Field_Service_Engineer_Text__c);
                            }
                            else{
                                rma.FSE_Portal_Contact__c = contactMap.get(rma.Field_Service_Engineer__c);
                            }
                        }
                        catch(DmlException e){
                            system.debug('Error finding FSE Portal Contact >>> ' + rma.Field_Service_Engineer_Text__c);
                        }
                     
                        
                    }
                   
                    // TODO: This came from a WFR but would only randomly work -- need to do a scheduled job?
                    if (rma.RMA_Type__c == 'Customer Repair Evaluation' && rma.Date_RMA_Item_Received__c == null
                            && rma.Days_since_RMA_created__c > 60){
                        rma.Probe_Never_Sent_In__c = true;
                    }
                }


                // This will insert the approved repairs for customer repairs. It will double check the field for possible
                // repairs to make sure it only adds possible repairs. It will categorize them into cosmetic and functional,
                // and then order them according to the mapping above.
                if (rma.RMA_Type__c == 'Customer Repair Evaluation'
                        || (rma.RMA_Type__c == 'Warranty Claim' && (rma.Check_In_Type__c == 'Customer Repair' || rma.Check_In_Type__c == 'Warranty Repair'))) {

                    ProductItem__c item;
                    if (rma.ProductItem__c != null && prodItemIDToProductItem.containsKey(rma.ProductItem__c)) {
                        item = prodItemIDToProductItem.get(rma.ProductItem__c);
                    }

                    System.debug('Found a ProductItem to work with: ' + item);

                    if (item != null) {
                            if (rma.Approved_Repairs__c != null && rma.Approved_Repairs__c != 'N/A - Customer opted for Exchange'
                                    && (Trigger.isInsert || oldRecord.Approved_Repairs__c != rma.Approved_Repairs__c) && Trigger.isBefore){
                                System.debug('CCC...241' +  rma.Approved_Repairs__c);
                                RepairLists repairLists = CreateApprovedRepairsHandler.GetRepairLists(rma.Approved_Repairs__c, item);
                                rma = CreateApprovedRepairsHandler.createApproved(rma, item, repairLists);
                                
                                Work_Order__c WO;
                                User rmaOwnerUser = userMap.get(rma.OwnerId);
                                String RMAOwner = '';
                                RMAOwner = rmaOwnerUser.FirstName + ' ' + rmaOwnerUser.LastName;
                                
                                // HERE IS WHERE WE WILL TRY TO FIND A WO   
                                WO = workOrderMap.get(item.Id);
                                //[SELECT Possible_Repairs__c,Id, Asset__c, CreatedDate FROM Work_Order__c WHERE Asset__c = :item.Id ORDER BY CreatedDate DESC LIMIT 1];
                                        
                                // This was in a later section - if approving repairs for the first time
                                if(((oldRecord != null && oldRecord.Approved_Repairs__c == null) || Trigger.IsInsert) && WO == null && rma.Approved_Repairs__c != 'NONE'){
                                	// do we need to search for WO here or just assume we need to create one? 
                                    WO = new Work_Order__c(RecordTypeId = RepairWOrderRecType.Id, Opportunity__c = rma.Opportunity__c,
                                                                            Asset__c = rma.ProductItem__c);
                                }

                                String WOrepairs = '';

                                System.debug('CCC...241' + repairLists.repairOrder);

                                //Get String value for order
                                for (Integer i : repairLists.repairOrderSorted) {
                                    order.add(ProboConstants.ReverseOrderRepairs.get(i));
                                }

                                System.debug('CCC...241 THIS IS THE ORDER >>>> ' + order);

                                for (String o : order) {
                                	if (String.IsNotBlank(o)) {
                                        WOrepairs += o.trim() + ';';
                                    }
                                }
                                        if(rma.Approved_Repairs__c != 'NONE'){
                                            WO.Work_Order_Repairs__c = WOrepairs;
                                            WO.New_Repairs__c = WOrepairs;
                                            if (WO.Possible_Repairs__c == null) {
                                                WO.Possible_Repairs__c = rma.Possible_Repairs__c;
                                            }
                                            if (rma.Estimated_Ship_Date__c != null) {
                                                WO.Estimated_Ready_Date__c = rma.Estimated_Ship_Date__c;
                                            }
                                            if (rma.Current_Estimated_Ship_Date__c != null) {
                                                WO.Estimated_Ready_Date__c = rma.Current_Estimated_Ship_Date__c;
                                            }
                                            WO.Repair_RMA__c = rma.Id;
                                            
                                            if(Test.isRunningTest()) {
                                                WO.Person_Requesting_WO__c = 'Adam Walter';
                                                //WO.Person_Requesting_WO__c = TestDataFactory.testUser();
                                            } else {
                                                WO.Person_Requesting_WO__c = RMAOwner;
                                            }
                                            
                                            
                                            workOrdersToUpsert.add(WO);
                                	}
                               
                                 Validator_Class.setAlreadyDone14();   
                                // This updates the asset page with the new repairs that have been approved or declined.
                            	item.Approved_Repairs__c = repairLists.ApprovedRepairs;
                                System.debug('CC...Item: ' + item.Approved_Repairs__c);
                        		item.Declined_Repairs__c = repairLists.declined;
                            	item.Repair_Status__c = 'Unassigned';
                            	item.Needs_to_be_moved_to_this_location__c = repairLists.newlocation;        
                                pItemsToUpdate.add(item);
                            }
							
                            //Integer electrical = 0;
                            //Integer cosmetic = 0;

                            if (Trigger.isUpdate) {
                                System.debug('CCCV...');
                                System.debug(rma.Approved_Repairs__c);
                                System.debug(oldRecord.Approved_Repairs__c);
                            }
                    } // RMA has a ProductItem__c
                }
            } // end of the RMA trigger loop

            
            system.debug('Upserting this many Work Orders: ' + workOrdersToUpsert.size());

            if (!workOrdersToUpsert.isEmpty()) {upsert workOrdersToUpsert;}
            
            //TO DO - the work order trigger handler also updates the pitem - need to make sure the pitem trigger doesn't loop - NB
            system.debug('Updating this many ProductItems: ' + pItemsToUpdate.size());
            if (!pItemsToUpdate.isEmpty()) {update pItemsToUpdate;}
            
            system.debug('Updating this many ServiceContracts: ' + serviceContractsToUpdate.size());
            if (!serviceContractsToUpdate.isEmpty()) {update serviceContractsToUpdate;}
        }
        if(Trigger.isUpdate) {
            Validator_Class.setAlreadyDone16();
        }
        System.debug('CC processFromCreateApprovedRepairs end: ' + Limits.getQueries()); 
    }

    public void processFromP_RMATrigger(){
        System.debug('CC processFromP_RMATrigger start: ' + Limits.getQueries()); 
        Map<Id, User> userMap = UserUtilities.GetActiveUsers();
        System.debug('CC...userMap: ' + userMap);
        System.debug('Start of P_RMATrigger ' + Validator_Class.hasAlreadyDone15());

        if (Validator_Class.hasAlreadyDone15() < 1) {

            System.debug('Inside the Validator check');

            Date workingDate;

            Set<Id> pidset = new Set<Id>();
            Set<Id> userIds = new Set<Id>();
            Set<Id> oppIds = new Set<Id>();
            

            for (RMA__c r : (List<RMA__c>)newList) {
                if (r.ProductItem__c != null) {
                    pidset.add(r.ProductItem__c);
                }

                userIds.add(r.OwnerId);

                if (r.Opportunity__c != null) {
                    oppIds.add(r.Opportunity__c);
                }
            }

            System.debug('ProductItems to find: ' + pidset);


            userIds.add(UserInfo.getUserId());

            // Sets new check in location based on where the user's location is
            User usr = userMap.get(UserInfo.getUserId());
            String newlocation = 'QA-Testing';
            if(usr.Location__c == 'Tampa, FL'){newlocation = 'Tampa, FL';}
            if(usr.Location__c == 'Tulsa, OK'){ newlocation = 'Tulsa - QA-Testing';}
            if(usr.Location__c == 'Harrisburg, PA'){newlocation = 'Harrisburg, PA';}
            if(usr.Location__c == 'Cleveland, OH'){ newlocation = 'Cleveland, OH';}

            Map<Id, Opportunity> rmaOppIDToOppDetails = new Map<Id, Opportunity>();
            Map<Id, Set<Id>> oppIdToAllProductItemIds = new Map<Id, Set<Id>>();
            Map<Id, Id> productItemIdToOLIIds = new Map<Id, Id>();
            List<String> currencyList = new List<String>();

            if (!oppIds.isEmpty()) {

                rmaOppIDToOppDetails = new Map<Id, Opportunity>([
                        select Id, Repair_Evaluation_Serial_Number__c, Bill_To_Account__c, BillingStreet__c, BillingCity__c, BillingState__c, 
                                BillingCountry__c, BillingPostalCode__c, Invoice_Number__c, AVA_SFCLOUD__Sales_Tax__c, Amount,
                                Related_Opportunity__c, CurrencyIsoCode, Date_Repair_Approved__c, Date_Repair_Evaluation_Sent__c
                        from Opportunity
                        where Id in :oppIds
                ]);
                for(Id oppID: rmaOppIDToOppDetails.keySet()){
    				if(!currencyList.contains(rmaOppIDToOppDetails.get(oppID).CurrencyIsoCode)){
                        currencyList.add(rmaOppIDToOppDetails.get(oppID).CurrencyIsoCode);
                    }
                    
				}

                for (OpportunityLineItem OLI : [
                        SELECT Id, ProductItem__c, OpportunityId, Product2Id
                        FROM OpportunityLineItem
                        WHERE OpportunityId IN :oppIds
                        AND ProductItem__c != NULL
                        ORDER BY CreatedDate DESC
                ]) {
                    if (!oppIdToAllProductItemIds.containsKey(OLI.OpportunityId)) {
                        oppIdToAllProductItemIds.put(OLI.OpportunityId, new Set<Id>());
                    }
                    oppIdToAllProductItemIds.get(OLI.OpportunityId).add(OLI.ProductItem__c);
                    productItemIdToOLIIds.put(OLI.ProductItem__c, OLI.Id);
                }

            }
            system.debug('THIS IS THE OPP ID TO ALL PRODUCT ITEM IDS >>> ' + oppIdToAllProductItemIds);
            

            Map<Id, ProductItem__c> pItemIDtoPItem = new Map<Id, ProductItem__c>([
                    SELECT Id, Name, sold__c, Model__c, Product_Name__c, Cosmetic_Rating__c, Purchasing_Approved__c,
                            Functional_Rating__c, Part_Number__c, Serial_No__c, Compatible_System__c, Repair_Due_Date__c,
                            Repair_Evaluation__c, Cosmetically_Repairable__c, Price__c, Functionally_Repairable__c,
                            Location__c, Functional_Notes__c, RMA_Date_Last_Test_Completed__c, Repair_Lead_Time_Remaining__c,
                            Check_In_Type__c, RMA_Owner__c, White_Glove_Service__c, RMA_Customer_Repair_Evaluation__c,
                            Cosmetic_Notes__c, Review_Status__c, Ship_Date__c, Reserved__c, Decontamination_Complete__c,
                            Cosmetically_unable_to_Improve__c, Functionally_unable_to_improve__c, Product2_Name__c, GL_Revenue_Account__c,
                            Approved_cosmetic_repairs_optimized__c, Approved_functional_repairs_optimized__c, Date_RMA_Item_Received__c, 
                			RMA_Quality_Issue_Reported__c, RMA_Number__c, Reserved_By__c, Reserved_Time_Stamp__c, Opportunity_Name__c,
                            Opportunity_Record_Type__c, Sales_Opportunity__c, Stage__c, Account_Name__c, Sales_Price__c

                    FROM ProductItem__c
                    WHERE Id IN :pidset OR (Product2_Name__c = 'Restock Fee' AND Check_In_Type__c = 'Generic') OR (Product2_Name__c = 'Sales Tax' AND Check_In_Type__c = 'Generic')
            ]);
            
            List<ProductItem__c> pitemList = new List<ProductItem__c>();
            ProductItem__c restockAsset;
            ProductItem__c salesTaxAsset;
            for(Id pitemID: pItemIDtoPItem.keySet()){
    				if(!pitemList.contains(pItemIDtoPItem.get(pitemID))){
                        pitemList.add(pItemIDtoPItem.get(pitemID));
                    }
                    
				}
            for(ProductItem__c pitem: pitemList){
                if(pitem.Product2_Name__c == 'Restock Fee'){
                    restockAsset = pitem;
                }
                if(pitem.Product2_Name__c == 'Sales Tax'){
                    salesTaxAsset = pitem;
                }
            }
            
            // make sure we have all the PriceBookEntries we need
            system.debug('THIS IS THE pitem LIST >>> ' + pitemList);
            Map<Id,PriceBookEntry> pitemtoPBEMap = New Map<Id,PriceBookEntry>();
            if(!currencyList.isEmpty() && !pitemList.isEmpty()){
                pitemtoPBEMap = getPriceBookEntryMap(pitemList, currencyList);
                system.debug('THIS IS THE pitemtoPBEMap >>> ' + pitemtoPBEMap);
            }

            
            Id stdPriceBookID = ProboCommonUtils.getStdPricebookId();

             Map<Id, Work_Order__c> pItemIDToMostRecentWorkOrderNotCompleted = new Map<Id, Work_Order__c>();

           
            for (Work_Order__c r : [
                    select Id, Asset__c, Estimated_Ready_Date__c, Status__c
                    from Work_Order__c
                    where Asset__c in :pidset
                    AND Status__c != 'Completed'
                    ORDER BY CreatedDate DESC
            ]) {
                if (!pItemIDToMostRecentWorkOrderNotCompleted.containsKey(r.Asset__c)) {
                    pItemIDToMostRecentWorkOrderNotCompleted.put(r.Asset__c, r);
                }
            }


            RecordType warrantyClaimRecType;
            RecordType custRepEvalRecType;
            RecordType depotRepEvalRecType;
            RecordType coreExchangeRecType;
            RecordType materialTransferRecType;
            RecordType loanerRecType;

            for (RecordType rt : ProboCommonUtils.getRecordTypes('RMA__c')) {

                switch on rt.DeveloperName {

                    when 'Warranty_Claim' {
                        warrantyClaimRecType = rt;
                    }
                    when 'Customer_Repair_Evaluation' {
                        custRepEvalRecType = rt;
                    }
                    when 'Depot_Repair' {
                        depotRepEvalRecType = rt;
                    }
                    when 'Core_Exchange' {
                        coreExchangeRecType = rt;
                    }
                    when 'Material_Transfer' {
                        materialTransferRecType = rt;
                    }
                    when 'Loaner_Return'{
                        loanerRecType = rt;
                    }
                        
                }
            }

            Map<Id, ProductItem__c> pitemUpdateMap = new Map<Id, ProductItem__c>();
            List<Work_Order__c> wosToUpdate = new List<Work_Order__c>();
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            List<OpportunityLineItem> olisToUpdate = new List<OpportunityLineItem>();
            List<Credit_Memo_Line_Item__c> cmlisToInsert = new List<Credit_Memo_Line_Item__c>();
            //list<Loaner__c> loanersToUpdate = new List<Loaner__c>();

            for (RMA__c rma : (List<RMA__c>)newList) {

                RMA__c oldData = oldMap != null ? (RMA__c)oldMap.get(rma.Id) : null;
                Opportunity RepairOpp;
                if(rma.Opportunity__c != null){
                    RepairOpp = rmaOppIDToOppDetails.get(rma.Opportunity__c);
                }
                system.debug('RMA ID: ' + rma.Id);
                system.debug('RMA RecTypeID is: ' + rma.RecordTypeId);
                system.debug('RMA ProductItem__c: ' + rma.ProductItem__c);
                System.debug('Old RMA Data' + oldData);

                if (rma.RecordTypeId == materialTransferRecType.Id
                        && rma.ProductItem__c != null
                        && (rma.Date_RMA_Item_Received__c != null
                        && (Trigger.isInsert || oldData.Date_RMA_Item_Received__c == null))){
					
                            ProductItem__c pi = pItemIDtoPItem.get(rma.ProductItem__c);
                    		
                            if (pi.Location__c != newlocation){
                                pi.Location__c = newlocation; 
                                System.debug('Adding to update list for Material Transfer: ' + pi);
                                pitemUpdateMap.put(pi.Id, pi);
                            }
                    


                } else if (rma.RecordTypeId != materialTransferRecType.Id && rma.RecordTypeId != coreExchangeRecType.Id) {

                    if (rma.ProductItem__c != null) {

                        Boolean piChanged = false; // flag to tell us if we need to update the ProductItem

                        ProductItem__c pi = pItemIDtoPItem.get(rma.ProductItem__c);

                        if (rma.Date_RMA_Item_Received__c != null && (Trigger.isInsert || oldData.Date_RMA_Item_Received__c == null)) {

                            // if any of the fields need to changed, just do them all
                            if ((pi.Cosmetic_Rating__c != '' && pi.Cosmetic_Rating__c != null)
                                    || (pi.Functional_Rating__c != '' && pi.Functional_Rating__c != null)
                                    || (pi.Repair_Evaluation__c != '' && pi.Repair_Evaluation__c != null)
                                    || (pi.Cosmetically_Repairable__c != '' && pi.Cosmetically_Repairable__c != null)
                                    || (pi.Functionally_Repairable__c != '' && pi.Functionally_Repairable__c != null)
                                    || (pi.Functional_Notes__c != '' && pi.Functional_Notes__c != null)
                                    || (pi.Cosmetic_Notes__c != '' && pi.Cosmetic_Notes__c != null)
                                    || (pi.Review_Status__c != '' && pi.Review_Status__c != null)
                                    || (pi.Location__c != newlocation)
                                    || (pi.Ship_Date__c != null)
                                    || (pi.Reserved__c) || (pi.Sold__c)
                                    || (pi.Decontamination_Complete__c)
                                    || (pi.Cosmetically_unable_to_Improve__c)
                                    || (pi.Functionally_unable_to_improve__c)
                                    || (pi.Approved_cosmetic_repairs_optimized__c)
                                    || (pi.Approved_functional_repairs_optimized__c)
                                    || (pi.Reserved_By__c != null)
                                    || (pi.Reserved_Time_Stamp__c != null)
                                    || (pi.Opportunity_Name__c != null)
                                    || (pi.Opportunity_Record_Type__c != null)
                                    || (pi.Sales_Opportunity__c != null)
                                    || (pi.Stage__c != null)
                                    || (pi.Account_Name__c != null)
                               		|| (pi.Date_RMA_Item_Received__c != rma.Date_RMA_Item_Received__c)){

                                piChanged = true;

                                // Case 00009998: receiving or editing an RMA must not remove the
                                // asset qualification values used to determine Available for Sale.
                                // The remaining check-in fields are still reset as before.
                                pi.Repair_Evaluation__c = '';
                                pi.Cosmetically_Repairable__c = '';
                                pi.Functionally_Repairable__c = '';
                                pi.Functional_Notes__c = '';
                                pi.Cosmetic_Notes__c = '';
                                if(pi.Check_In_Type__c != 'Equipment Storage'){
                                      pi.Location__c = newlocation;      
                                }
                                
                                        
                                if(pi.Check_In_Type__c == 'Equipment Storage'){
                                    pi.Reserved_By__c = '';
                                    pi.Reserved_Time_Stamp__c = null;
                                    pi.Opportunity_Name__c = '';
                                    pi.Opportunity_Record_Type__c = '';
                                    pi.Sales_Opportunity__c = null;
                                    pi.Stage__c = '';
                                    pi.Account_Name__c = '';
                                }
                                pi.Sub_Location__c = '';
                                //pi.ProboUK_Location__c = '';
                                //pi.Current_Location__c = '';
                                pi.Ship_Date__c = null;
                                pi.Reserved__c = false;
                                pi.Sold__c = false;
                                pi.Decontamination_Complete__c = false;
                                pi.Cosmetically_unable_to_Improve__c = false;
                                pi.Functionally_unable_to_improve__c = false;
                                pi.Approved_cosmetic_repairs_optimized__c = false;
                                pi.Approved_functional_repairs_optimized__c = false;
                                pi.Date_RMA_Item_Received__c = rma.Date_RMA_Item_Received__c;
                                pi.RMA_Record_Type__c = rma.Record_Type_Name__c;
                                pi.RMA_Quality_Issue_Reported__c = rma.Quality_Issue_Reported__c;
                               
                            }

                            if (rma.RecordTypeId == warrantyClaimRecType.Id) {

                                System.debug('Looking to work with ProductItem for WarrantyClaim:' + pi);
                                if(pi.RMA_Quality_Issue_Reported__c != rma.Quality_Issue_Reported__c){
                                    pi.RMA_Quality_Issue_Reported__c = rma.Quality_Issue_Reported__c;
                                    piChanged = true;
                                }
                                if (rma.Customer_Expectation__c == 'Customer wants Equipment Back') {
                                    System.debug('Customer Expectation is wants probe back');
                                    if (pi.Check_In_Type__c != 'Customer Repair' && pi.Check_In_Type__c != 'Warranty Repair') {pi.Check_In_Type__c = 'Warranty Repair';piChanged = true;}

                                }
                                if(rma.Customer_Expectation__c == 'Customer Does Not want Equipment Back'){
                                    if(pi.Check_In_Type__c == 'Customer Repair'){pi.Check_In_Type__c = 'Core Exchange'; piChanged=true;}
                                }
                                
                                
                            }
                        } // end date RMA item received changed
						system.debug('THIS IS THE RESTOCKING FEE >> ' + rma.Restocking_Fee_Amount__c + ' AND OWNER ENTITY >> ' + rma.Owner_Entity_Name__c + ' AND WARRANTY CLAIM >> ' + rma.RecordTypeId + ' ' + warrantyClaimRecType.Id + ' AND TRIGGER >>' + Trigger.IsAfter + ' AND WARRANTY CLAIM >> ' + rma.Warranty_Claim_Action__c + '  ' + rma.Warranty_Claim_Approved__c + ' AND DATE >> ' + rma.Date_RMA_Item_Received__c); 
                        // Generate new Credit Memo - restocking fee for warranty claim if approved for restocking fee      
                        if(rma.RecordTypeId == warrantyClaimRecType.Id && rma.Date_RMA_Item_Received__c != null && Trigger.isAfter && rma.Restocking_Fee_Amount__c != 0 && rma.Owner_Entity_Name__c.contains('US') && rma.Warranty_Claim_Action__c != null && rma.Warranty_Claim_Action__c.contains('restocking fee') && rma.Warranty_Claim_Approved__c != null && rma.Warranty_Claim_Approved__c == 'APPROVED' && (oldData.Warranty_Claim_Approved__c != 'APPROVED' || oldData.Warranty_Claim_Approved__c == null)){
                            system.debug('THIS IS THE RESTOCKING FEE AMOUNT >> ' + rma.Restocking_Fee_Amount__c);
                            
                            Double salesTax = 0;
                            if(RepairOpp.AVA_SFCLOUD__Sales_Tax__c != null){
                                salesTax = pi.Sales_Price__c * (RepairOpp.AVA_SFCLOUD__Sales_Tax__c/RepairOpp.Amount);
                            }
                            system.debug('THIS IS THE SALES TAX FOR CM >> ' + salesTax + ' AND ASSET >> ' + salesTaxAsset);
                            Decimal creditMemoAmount = pi.Sales_Price__c + salesTax - rma.Restocking_Fee_Amount__c;
                            String todayDate = String.valueOf(Date.today()).removeEnd(' 00:00:00');
                            Decimal restockFeePercent = ((rma.Restocking_Fee_Amount__c) / (rma.Restocking_Fee_Amount__c + creditMemoAmount))*100; 
                            String creditMemoNotes = 'Auto-generated credit memo with restocking fee percentage of ' + restockFeePercent.intvalue() + '% from warranty claim RMA ' + rma.Name + ' on ' + todayDate + '.';
                            if(rma.Restock_Fee_Percentage_Override__c != null){
                                creditMemoNotes += ' This restock fee percentage was a custom override.';
                            }
                            if(creditMemoAmount > 0){
                                Credit_Memo__c cmToAdd = new Credit_Memo__c(RMA__c = rma.Id, Opportunity__c = RepairOpp.Id, Credit_Memo_Amount__c = creditMemoAmount, Bill_To_Account__c = RepairOpp.Bill_To_Account__c, Invoice__c = RepairOpp.Invoice_Number__c, Credit_Memo_Notes__c = creditMemoNotes, GL_Posting_Date__c = Date.today(), Stage__c = 'Submitted for Approval');
                                Validator_Class.SetByPassOppTrigger(true);
                                Validator_Class.SetByPassRMATrigger(true);
                                Validator_Class.SetByPassProductItemTrigger(true);
                                system.debug('INSERTING CREDIT MEMO FOR RESTOCK FEE >> ' + cmToAdd);
                                insert cmToAdd; // need Id to add CM line item
                                system.debug('AFTER INSERT CM RESTOCK FEE >> ' + cmToAdd.Id);
                                Validator_Class.SetByPassOppTrigger(false);
                                Validator_Class.SetByPassRMATrigger(false);
                                Validator_Class.SetByPassProductItemTrigger(false);
                                Id oliId = productItemIdToOLIIds.get(pi.Id);
                                Credit_Memo_Line_Item__c cmLineItem = new Credit_Memo_Line_Item__c(Credit_Memo__c = cmToAdd.Id, Credit_Memo_Line_Amount__c = pi.Sales_Price__c, Custom_Product_Name__c = pi.Product2_Name__c, Intacct_Accounts__c = pi.GL_Revenue_Account__c, ProductItem__c = pi.Id, RMA__c = rma.Id, Opportunity_Product__c = oliId);  
                                cmlisToInsert.add(cmLineItem);
                                if(restockAsset != null){
                                    Double restockFee = -rma.Restocking_Fee_Amount__c;
                                    Credit_Memo_Line_Item__c restockLineItem = new Credit_Memo_Line_Item__c(Credit_Memo__c = cmToAdd.Id, Credit_Memo_Line_Amount__c = restockFee, Custom_Product_Name__c = restockAsset.Product2_Name__c, Intacct_Accounts__c = '47150--Restocking Fees', ProductItem__c = restockAsset.Id, RMA__c = rma.Id);  
                                    cmlisToInsert.add(restockLineItem);
                                }
                                
                                if(salesTax != null && salesTax != 0 && salesTaxAsset != null){
                                    Credit_Memo_Line_Item__c salesTaxLineItem = new Credit_Memo_Line_Item__c(Credit_Memo__c = cmToAdd.Id, Credit_Memo_Line_Amount__c = salesTax, Custom_Product_Name__c = salesTaxAsset.Product2_Name__c, Intacct_Accounts__c = '23100--Sales Tax Payable', ProductItem__c = salesTaxAsset.Id, RMA__c = rma.Id);  
                                    cmlisToInsert.add(salesTaxLineItem);
                                }
                            }
                            
                        }
                        System.debug('Ready to check workingDays');
                        if (rma.Date_Repair_Approved__c != null && pi.Repair_Lead_Time_Remaining__c != null) {

                            workingDate = NoWorkingDays.workingDays(rma.Date_Repair_Approved__c, Integer.valueOf(pi.Repair_Lead_Time_Remaining__c));

                            if (pi.Repair_Due_Date__c != workingDate){pi.Repair_Due_Date__c = workingDate;piChanged = true;
                            }
                        }

                        if (pi.White_Glove_Service__c != rma.White_Glove_Service__c) {
                            System.debug('Setting White Glove and adding to update list: ' + pi);pi.White_Glove_Service__c = rma.White_Glove_Service__c;piChanged = true;
                        }

                        if ((Trigger.isInsert || (Trigger.isUpdate && oldData.ProductItem__c == null)) && pi.RMA_Owner__c != (userMap.get(rma.OwnerId).FirstName + ' ' + userMap.get(rma.OwnerId).LastName)) {
                            pi.RMA_Owner__c = userMap.get(rma.OwnerId).FirstName + ' ' + userMap.get(rma.OwnerId).LastName;
                            system.debug('THIS IS THE NEW RMA OWNER >> ' + pi.RMA_Owner__c);
                            piChanged = true;
                        }
                        
                        if ((Trigger.isInsert || (Trigger.isUpdate && oldData.ProductItem__c == null)) && pi.RMA_Number__c != rma.Name) {
                            pi.RMA_Number__c = rma.Name;
                            piChanged = true;
                        }

                        if (piChanged) {
                            System.debug('Adding to update list: ' + pi);
                            pitemUpdateMap.put(pi.Id, pi);
                        }
                    }
                } 

                if (rma.RecordTypeId == warrantyClaimRecType.Id && rma.Customer_Expectation__c == 'Customer wants Equipment Back'){

                    GH_Logger.debug('Warranty RMA with Customer wants Equipment back');
                    if (rma.ProductItem__c != null && (Trigger.isInsert || oldData.ProductItem__c == null)) {

                        System.debug('ProductItem__c has a gotten a value from null');
                        ProductItem__c thisPItem;

                        if (pItemIDtoPItem.containsKey(rma.ProductItem__c)) {
                            thisPItem = pItemIDtoPItem.get(rma.ProductItem__c);
                        }

                        if (thisPItem != null && rma.Opportunity__c != null) {
                            RepairOpp.Repair_Evaluation_Serial_Number__c = thisPItem.Serial_No__c;
                            RepairOpp.Customer_Repair_Evaluation_RMA__c = rma.id;
                            oppsToUpdate.add(RepairOpp);

                            if (RepairOpp.Related_Opportunity__c != null) {
                                System.debug('Setting the Related Opp Related Asset to the RMAs ProductItem__c');
                                oppsToUpdate.add(new Opportunity(Id = RepairOpp.Related_Opportunity__c, Related_Asset__c = thisPItem.Id));
                            }
                        }

                        // Case 00010158: an RMA can be saved before an Opportunity is assigned.
                        // Only perform Opportunity Product synchronization when both records exist.
                        if(thisPItem != null && RepairOpp != null &&
                                (!oppIdToAllProductItemIds.containsKey(RepairOpp.Id) ||
                                !oppIdToAllProductItemIds.get(RepairOpp.Id).contains(thisPItem.Id))){
                            Id PricebookEntryID;
                            String oppCurrency = 'USD';
                            if(RepairOpp.CurrencyIsoCode != null){
                                oppCurrency = RepairOpp.CurrencyIsoCode;
                            }
                            
                            if(!pitemtoPBEMap.containsKey(thisPItem.id)){
                                
                            	PriceBookEntry newPBE = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = thisPItem.Product_Name__c, IsActive = true, UnitPrice = 0, CurrencyIsoCode = oppCurrency);
                                system.debug('THIS IS THE NEW PBE BEFORE INSERT >>> ' + newPBE);
                                insert newPBE;
                                system.debug('THIS IS THE NEW PBE AFTER INSERT >>> ' + newPBE);
                                PriceBookEntryID = newPBE.id;
                            
                            }
                            else{
                                PriceBookEntryID = pitemtoPBEMap.get(thisPItem.id).id;
                            }
                            system.debug('Adding product to repair opp');
                            OpportunityLineItem oliToAdd = new OpportunityLineItem(OpportunityId = RepairOpp.Id, ProductItem__c = thisPItem.Id,
                                    PricebookEntryId = PricebookEntryID, Model__c = thisPItem.Model__c, Part_Number__c = thisPItem.Part_Number__c,
                                    Serial_No__c = thisPItem.Serial_No__c, Quantity = 1, Actual_Price__c = 0, TotalPrice = 0,
                                    Compatible_System__c = thisPItem.Compatible_System__c, Functional_Rating__c = thisPItem.Functional_Rating__c,
                                    Functional_Rating_Notes__c = thisPItem.Functional_Notes__c, Asset_No__c = thisPItem.Name,
                                    Purchasing_Approved__c = thisPItem.Purchasing_Approved__c);
                            olisToUpdate.add(oliToAdd);
                        }
                    }
                }
                //end if RMA is Warranty

                if (Trigger.isUpdate) {

                    System.debug('P_RMATrigger isUpdate');

                    System.debug('old Est ShipDate: ' + oldData.Estimated_Ship_Date__c + ' and new Est ShipDate: ' + rma.Estimated_Ship_Date__c);

                    
                    
                    if ((oldData.Estimated_Ship_Date__c != rma.Estimated_Ship_Date__c && rma.Estimated_Ship_Date__c != null)
                            || ((oldData.Current_Estimated_Ship_Date__c != rma.Current_Estimated_Ship_Date__c)
                            && rma.Current_Estimated_Ship_Date__c != null)) {

                        System.debug('CURRENT or ESTIMATED SHIP DATEs have changed');
                        if (rma.Added_to_Work_Order__c == true) {

                            System.debug('RMA Added_to_Work_Order is TRUE');

                            Boolean woChanged = false;
                            Work_Order__c WO;

                            if (pItemIDToMostRecentWorkOrderNotCompleted.containsKey(rma.ProductItem__c)) {
                                WO = pItemIDToMostRecentWorkOrderNotCompleted.get(rma.ProductItem__c);
                            }

                            System.debug('THIS IS THE WO FOR RMA UPDATE> ' + WO);

                            if (WO != null) {
                                if (rma.Estimated_Ship_Date__c != null
                                        && WO.Estimated_Ready_Date__c != rma.Estimated_Ship_Date__c) {
                                    WO.Estimated_Ready_Date__c = rma.Estimated_Ship_Date__c;
                                    woChanged = true;
                                }
                                if (rma.Current_Estimated_Ship_Date__c != null
                                        && WO.Estimated_Ready_Date__c != rma.Current_Estimated_Ship_Date__c) {
                                    WO.Estimated_Ready_Date__c = rma.Current_Estimated_Ship_Date__c;
                                    woChanged = true;
                                }

                                if (woChanged) {
                                    wosToUpdate.add(WO);
                                }
                            }
                        }
                    }

                    if (rma.RecordTypeId == custRepEvalRecType.Id || rma.RecordTypeId == depotRepEvalRecType.Id) { // ADD DEPOT REPAIR?
						
                        
            			
                        
                        System.debug('RMA is a customer Repair Evaluation');
                        if(rma.ProductItem__c != null){
                            System.debug('ProductItem__c has a gotten a value from null');
                            ProductItem__c thisPItem;

                            if (pItemIDtoPItem.containsKey(rma.ProductItem__c)) {
                                thisPItem = pItemIDtoPItem.get(rma.ProductItem__c);
                            }

                            System.debug('The ProductItem related to the RMA: ' + thisPItem);

                            if (thisPItem != null && rma.Opportunity__c != null && oldData.ProductItem__c != null) {
                                if(rma.Date_Repair_Approved__c != null && oldData.Date_Repair_Approved__c != rma.Date_Repair_Approved__c){
                					if(RepairOpp.Date_Repair_Approved__c != rma.Date_Repair_Approved__c){
                                        RepairOpp.Date_Repair_Approved__c = rma.Date_Repair_Approved__c;
                                        oppsToUpdate.add(RepairOpp);
                                    }
                                    
        						}
                                   if(rma.Date_Repair_Evaluation_Sent__c != null && rma.Date_Repair_Evaluation_Sent__c != oldData.Date_Repair_Evaluation_Sent__c) {
                                   		
                                    	if(RepairOpp.Date_Repair_Evaluation_Sent__c != rma.Date_Repair_Evaluation_Sent__c){
                                        	RepairOpp.Date_Repair_Evaluation_Sent__c = rma.Date_Repair_Evaluation_Sent__c;
                                        	oppsToUpdate.add(RepairOpp);
                                    	}
                                   
                                   }
                            }
                        
                        if (oldData.ProductItem__c == null) {

                            if (thisPItem != null && rma.Opportunity__c != null) {
                                RepairOpp = rmaOppIDToOppDetails.get(rma.Opportunity__c);
                                 system.debug('INSIDE OLD DATA ITEM NULL >>> REPAIR OPP >>> ' + RepairOpp);
                                if(rma.Date_Repair_Approved__c != null && oldData.Date_Repair_Approved__c != rma.Date_Repair_Approved__c){
                					if(RepairOpp.Date_Repair_Approved__c != rma.Date_Repair_Approved__c){
                                        RepairOpp.Date_Repair_Approved__c = rma.Date_Repair_Approved__c;
                                    }
                                    
        						}
                                   if(rma.Date_Repair_Evaluation_Sent__c != null && rma.Date_Repair_Evaluation_Sent__c != oldData.Date_Repair_Evaluation_Sent__c) {
                                   		
                                    	if(RepairOpp.Date_Repair_Evaluation_Sent__c != rma.Date_Repair_Evaluation_Sent__c){
                                        	RepairOpp.Date_Repair_Evaluation_Sent__c = rma.Date_Repair_Evaluation_Sent__c;
                                        	
                                    	}
                                   
                                   }
                                RepairOpp.Repair_Evaluation_Serial_Number__c = thisPItem.Serial_No__c;
                                RepairOpp.Customer_Repair_Evaluation_RMA__c = rma.id;
                                
                                oppsToUpdate.add(RepairOpp);

                                if (RepairOpp.Related_Opportunity__c != null) {
                                    System.debug('Setting the Related Opp Related Asset to the RMAs ProductItem__c');
                                    oppsToUpdate.add(new Opportunity(Id = RepairOpp.Related_Opportunity__c, Related_Asset__c = thisPItem.Id));
                                }
                            }

                            // Case 00010158: Product Item selection is valid even when the RMA
                            // has no Opportunity. Skip Opportunity Product synchronization in that case.
                            if (thisPItem != null && RepairOpp != null) {
                            Id PricebookEntryID;
                            system.debug('THIS IS THE pitem TO PBE MAP >>> ' + pitemtoPBEMap);
                            if(!pitemtoPBEMap.containsKey(thisPItem.id)){
                                
                            	PriceBookEntry newPBE = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = thisPItem.Product_Name__c, IsActive = true, UnitPrice = 0, CurrencyIsoCode = RepairOpp.CurrencyIsoCode);
                                system.debug('THIS IS INSIDE THE NEW PBE LOOP BEFORE INSERT >>> ' + newPBE);
                                insert newPBE;
                                system.debug('THIS IS INSIDE THE NEW PBE LOOP AFTER INSERT >>> ' + newPBE);
                                PriceBookEntryID = newPBE.id;
                            
                            }
                            else{
                                system.debug('THIS IS INSIDE THE CURRENT PBE LOOP BEFORE INSERT >>> ' + pitemtoPBEMap.get(thisPItem.id));
                                PriceBookEntryID = pitemtoPBEMap.get(thisPItem.id).id;
                            }
                            
                            OpportunityLineItem AddProduct = new OpportunityLineItem(OpportunityId = RepairOpp.Id, ProductItem__c = thisPItem.Id,
                                    PricebookEntryId = PricebookEntryID, Model__c = thisPItem.Model__c, Part_Number__c = thisPItem.Part_Number__c,
                                    Serial_No__c = thisPItem.Serial_No__c, Quantity = 1, Actual_Price__c = 0, TotalPrice = 0,
                                    Compatible_System__c = thisPItem.Compatible_System__c, Functional_Rating__c = thisPItem.Functional_Rating__c,
                                    Functional_Rating_Notes__c = thisPItem.Functional_Notes__c, Asset_No__c = thisPItem.Name,
                                    Purchasing_Approved__c = thisPItem.Purchasing_Approved__c);
                            olisToUpdate.add(AddProduct);

                            System.debug('Creating a new OLI for the RepairOpp and RMA\'s ProductItem__c: ' + AddProduct);

                            Boolean piToUpdate = false;
                            if (thisPItem.RMA_Customer_Repair_Evaluation__c != rma.Name) {
                                thisPItem.RMA_Customer_Repair_Evaluation__c = rma.Name;
                                piToUpdate = true;
                            }

                            if (thisPItem.White_Glove_Service__c != rma.White_Glove_Service__c) {
                                thisPItem.White_Glove_Service__c = rma.White_Glove_Service__c;
                                piToUpdate = true;
                            }

                            if (thisPItem.RMA_Owner__c != userMap.get(rma.OwnerId).FirstName + ' ' + userMap.get(rma.OwnerId).LastName) {
                                thisPItem.RMA_Owner__c = userMap.get(rma.OwnerId).FirstName + ' ' + userMap.get(rma.OwnerId).LastName;
                                piToUpdate = true;
                            }
                            if (piToUpdate) {
                                pitemUpdateMap.put(thisPItem.Id, thisPItem);
                            }
                            }
                        }
                        }
                    }// end if RMA is a customer Repair Eval

                }
            } // end trigger loop

            
            if(Trigger.isAfter){
                                
                system.debug('Updating this many Work Orders in the RMA trigger: ' + wosToUpdate.size());
                if (!wosToUpdate.isEmpty()) {
                    update wosToUpdate;
                }
    
                system.debug('Updating this many Opportunities in the RMA trigger: ' + oppsToUpdate.size());
                if (!oppsToUpdate.isEmpty()) {
                    update oppsToUpdate;
                }
    
                system.debug('Inserting this many OpportunityLineItems in the RMA trigger: ' + olisToUpdate.size());
                if (!olisToUpdate.isEmpty()) {
                    insert olisToUpdate;
                }
    
                system.debug('Updating this many Product Items in the RMA trigger: ' + pitemUpdateMap.size());
                if (!pitemUpdateMap.isEmpty()) {
                    system.debug('THIS IS THE P ITEM UPDATE MAP >> ' + pitemUpdateMap);
                    update pitemUpdateMap.values();
                }
                /*
                if(!loanersToUpdate.isEmpty()){
                    update loanersToUpdate;
                }*/
                system.debug('Inserting this many Credit Memo Line Items in the RMA trigger: ' + cmlisToInsert.size());
                if (!cmlisToInsert.isEmpty()) {
                    insert cmlisToInsert;
                }
                
            }
            
        } // end validator

        Validator_Class.setAlreadyDone15();

        System.debug('End of P_RMATrigger');
        System.debug('CC processFromP_RMATrigger end: ' + Limits.getQueries()); 
    }
}
