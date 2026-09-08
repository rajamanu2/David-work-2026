public class P_OpportunityTriggerHandler extends GH_TriggerHandlerBase {

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

    private static RecordType materialTransferOpprt;
    private static RecordType PurchasingOpprt;
    private static RecordType BigIronPurchasingOpprt;
    private static RecordType ReturnsOpprt;
    //private static RecordType RepairOpprt;
    private static RecordType DepotOpprt;
    private static RecordType EquipmentStorageOpprt;
    private static Id salesOppRecTypeId;
    private static ID probeSalesRT;
    private static RecordType DEPOTrt;
    private static RecordType EVALrt;
    private static RecordType LOANrt;
    private static RecordType RentRetrt;
    private static RecordType EXTrt;
    private static RecordType MTrt;
    private static RecordType CORErt;

    // Account record IDs for locations
    public static Id proboFishers;
    public static Id proboTulsa;
    public static Id medCorp;
    public static Id probo;
    public static Id proboTampa;
    public static Id trisonics;

    private Map<Id, Set<Id>> prodItemIDtoVerbalOrProbeLoanOLI = new Map<Id, Set<Id>>();

    // Static query caches — populated once per transaction to prevent redundant SOQLs
    // when the trigger fires multiple times in a cascade (e.g. WOLI → OLI → ProductItem → Opp).
    // Safe because the queried fields are not modified by the cascade between runs.
    // ⚠ RMA cache: Core RMAs created during a Closed Won transition are guarded by setAlreadyDone1()
    //   and stage-change checks, so the stale cache does not cause duplicates in that path.
    private static Map<Id, Schema.Address>                 cachedAddresses         = new Map<Id, Schema.Address>();
    private static Map<Id, List<Work_Order__c>>            cachedWorkOrders        = new Map<Id, List<Work_Order__c>>();
    private static Map<Id, List<Sourcing_Request_Item__c>> cachedSRIs              = new Map<Id, List<Sourcing_Request_Item__c>>();
    private static Map<Id, List<RMA__c>>                   cachedRMAs              = new Map<Id, List<RMA__c>>();
    // cachedBeforeOLIs intentionally removed — OLIs can be inserted between trigger runs
    // (e.g. during test setup), making a cached empty list stale for stage-change RMA creation.
    private static Map<Id, ProductItem__c>                 cachedBeforePItemsById  = new Map<Id, ProductItem__c>();
    private static Map<Id, List<ProductItem__c>>           cachedBeforePItemsByOpp = new Map<Id, List<ProductItem__c>>();
    private static Map<Id, OpportunityHistory>             cachedOppHistory        = new Map<Id, OpportunityHistory>();
    // cachedAfterOLIs intentionally removed — same staleness risk as cachedBeforeOLIs.
    // If OLIs are inserted after the first After Update run, the cache would serve []
    // and sold__c / Reserved__c would never be set on ProductItems.
    private static Map<Id, ProductItem__c>                 cachedAfterPItems       = new Map<Id, ProductItem__c>();
    private static Map<Id, List<OpportunityLineItem>>      cachedStageCheckOLIs    = new Map<Id, List<OpportunityLineItem>>();

    public void doTriggerWork(List<Opportunity> newRecs, Map<Id, Opportunity> newRecMap, Map<Id, Opportunity> oldRecs) {
        System.debug('CC doTriggerWork begin: ' + Limits.getQueries());
        // This will be set if the trigger is called as a result of P_ProductItemTrigger insert field setting
        if (GH_CodeUtils.isFlagSet('Updating Opp Totals')) {
            return;
        }
  
        User theCurrentUser = ProboCommonUtils.getCurrentUser();

        if (Trigger.isBefore) {
            if (Trigger.isDelete) {
                checkDeletes(oldRecs);
            } else {
                
                if (Trigger.IsUpdate) {
                    // This prevents anyone from changing the status if it is synced to intacct.
                    for (Opportunity opp : newRecs) {
                        Boolean hasPermission = FeatureManagement.checkPermission('Manage_Intacct_Synced_Records');
                        if (oldRecs.get(opp.Id).Intacct_Shipper_Sync_Status__c == 'Synced' && opp.Intacct_Shipper_Sync_Status__c != 'Synced'  && !hasPermission) {
                            opp.addError('You can not change the status of an Opportunity that has been synced with Intacct');
                        }
                    }
                } 

                // make sure all the Opp fields are updated as needed
                stampOppFields(newRecs, oldRecs);

                // calling this here means the vars it sets are available in the entire transaction
                getRecordTypes();

                if (Trigger.isInsert) {
                    
                    system.debug('P_OpportunityTrigger Before Insert');
                    
                    Id currentUserId = UserInfo.getUserId();
                    String entityName = [SELECT Entity__c FROM User WHERE Id =: currentUserId LIMIT 1].Entity__c;
					getLocationAccountIds();

                    Set<Id> aset = new Set<Id>();
                    for (Opportunity o : newRecs) { 
                        aset.add(o.AccountId);
                        if(o.Bill_To_Account__c != null){
                            aset.add(o.Bill_To_Account__c);
                        }
                        //Created by EU/UK - PULLED FROM PB: Opportunity by BW on 8/16
                        if(o.CreatedBy.Location__c == 'Bristol, UK' || o.CreatedBy.Location__c == 'Dusseldorf, Germany' || o.CreatedBy.Location__c == 'Gloucester, UK' || o.CreatedBy.Location__c == 'Nantes, FR' || o.CreatedBy.Location__c == 'Nottingham, UK'){
                            o.Created_by_EU_UK__c = TRUE;
                        }
                        o.Entity__c = entityName;
                    }
                    P_OpportunityTriggerHandler2.AssignByContactLookup(newRecs);
                    system.debug('Account set: ' + aset);
                    setOppFieldsOnInsert(newRecs, getAccounts(aset));
                    

                } else if (Trigger.isUpdate) {

                    system.debug('P_OpportunityTrigger Before Update');
                    // Validator class prevents multiple loops of code which causes SOQL queries to hit the limit.
                    // Number 1 has to be set to <2 based on the loaner turned to sale process through the eval.
                    // Number 1 is reset each loop of this trigger. Number 3 comes from the UpdateOpportunity trigger.                   
                    Set<Id> oppIdset = new Set<Id>();
                    
                    // Fetch TSLs for Opps which need them
                    // Map<Id,Technician_Ship_Location__c> MapTSL = new Map<Id,Technician_Ship_Location__c>();
                    Map<Id,Schema.Address> MapTSL = new Map<Id,Schema.Address>();
                    Map<Id,Id> MapTSLIds = new Map<Id,Id>();
                    // Map<Id,Tech_Ship_Location_Junction__c> MapTSLJ = new Map<Id,Tech_Ship_Location_Junction__c>();
                    // Map<Id,Schema.Address> MapTSLJ = new Map<Id,Schema.Address>();
                    Set<Id> TSLIdSet = new Set<Id>();
                    // Set<Id> TSLJIdSet = new Set<Id>();
                    for (Opportunity opp : newRecs){
                        if(opp.Tech_Ship_Location_Address__c != NULL){
                            // TSLJIdSet.add(opp.Tech_Ship_Location_Address__c);
                            TSLIdSet.add(opp.Tech_Ship_Location_Address__c);
                        }
                    }
                    // if(TSLJIDSet.size()>0){
                    if(TSLIDSet.size()>0){
                        Set<Id> uncachedTSLIds = new Set<Id>();
                        for (Id addrId : TSLIdSet) {
                            if (!cachedAddresses.containsKey(addrId)) {
                                uncachedTSLIds.add(addrId);
                            }
                        }
                        if (!uncachedTSLIds.isEmpty()) {
                            for (Schema.Address tsl : [SELECT Id, Parent.Owner.Name, AddressType, State, Country, Street, City, StateCode, PostalCode, CountryCode, Parent.Name FROM Address WHERE Id IN :uncachedTSLIds]) {
                                cachedAddresses.put(tsl.Id, tsl);
                            }
                        }
                        for (Opportunity opp : newRecs) {
                            if (opp.Tech_Ship_Location_Address__c != null && cachedAddresses.containsKey(opp.Tech_Ship_Location_Address__c)) {
                                MapTSL.put(opp.Id, cachedAddresses.get(opp.Tech_Ship_Location_Address__c));
                            }
                        }
                        system.debug('MapTSL: '+MapTSL);
                    }
                    
                    for (Opportunity opp : newRecs) {
                        System.debug('CC: 88' + opp.Account.Tax_Exempt_States__c);
                        System.debug('CC: 89' + opp.ShippingState__c);
                        System.debug('CC: 90' + opp.Account.Tax_Exemption_Form_Attached__c);
                        System.debug('CC: 91' + opp.AVA_SFCLOUD__Sales_Tax__c);
                        System.debug('CC: 92' + opp.StageName);
                        System.debug('CC: 93' + opp.Account.Id);
                        System.debug('CC: 94' + opp.Account);
                        System.debug('CC: 95' + opp.AccountId);
                        
                        Opportunity oldO = oldRecs.get(opp.Id);
        //                if((opp.Account.Tax_Exempt_States__c != null && opp.Account.Tax_Exempt_States__c.contains(opp.ShippingState__c)) && opp.Account.Tax_Exemption_Form_Attached__c == true && opp.AVA_SFCLOUD__Sales_Tax__c > 0 && opp.StageName != 'Closed Won') {
        //                    opp.Sales_Tax__c = 0;
        //                }
        //                if((opp.Account.Tax_Exempt_States__c != null && opp.Account.Tax_Exempt_States__c.contains(opp.ShippingState__c) && opp.Account.Tax_Exemption_Form_Attached__c == true && opp.AVA_SFCLOUD__Sales_Tax__c > 0)){
        //                    opp.Sales_Tax__c = 0;
        //                }
                        if(((opp.AVA_SFCLOUD__AvaTax_Message__c != oldO.AVA_SFCLOUD__AvaTax_Message__c) || (opp.Tech_Ship_Location_Address__c != oldO.Tech_Ship_Location_Address__c)) && opp.AVA_SFCLOUD__AvaTax_Message__c == 'Sales Tax Current' && opp.Tech_Ship_Location_Address__c != NULL){                        
                            if(opp.Hold_Shipping_Address_Street__c == NULL){
                                opp.Hold_Ship_To_Account__c = opp.Ship_To_Account__c;
                                opp.Hold_Shipping_Address_Street__c = opp.ShippingStreet__c;
                                opp.Hold_Shipping_Address_City__c = opp.ShippingCity__c;
                                opp.Hold_Shipping_Address_State__c = opp.ShippingState__c;
                                opp.Hold_Shipping_Address_Postal_Code__c = opp.ShippingPostalCode__c;
                                opp.Hold_Shipping_Address_Country__c = opp.ShippingCountry__c;
                            }
                            // if(MapTSL.get(opp.id).Type__c == 'Home'){  
                            if(MapTSL.get(opp.Id).AddressType == 'Home'){
                                // opp.Ship_To_Account__c = MapTSLJ.get(opp.id).Technician__r.name;
                                opp.Ship_To_Account__c = MapTSL.get(opp.Id).Parent.Name;
                            }
                            // else if(MapTSL.get(opp.id).Type__c == 'FedEx'){
                            else if(MapTSL.get(opp.Id).AddressType == 'FedEx'){
                                opp.Ship_To_Account__c = 'FedEx Hold';
                            }
                            opp.ShippingStreet__c = MapTSL.get(opp.Id).Street;
                            opp.ShippingCity__c = MapTSL.get(opp.Id).City;
                            opp.ShippingState__c = MapTSL.get(opp.Id).State;
                            opp.ShippingPostalCode__c = MapTSL.get(opp.Id).PostalCode;
                            opp.ShippingCountry__c = MapTSL.get(opp.Id).Country;
                        }
                        if(opp.StageName != oldO.StageName) {
                            opp.Time_Stamp_of_Stage_Change__c = System.now();
                        }
                        if(opp.LeadSource != null && opp.LeadSource.tolowercase().left(4) == 'http') {
                            opp.LeadSource = 'Web Lead - Form Submission';
                        }
                        if(opp.Name == 'Material Transfer') {
                            opp.Name = opp.Opportunity_Number__c  + '_'  + opp.Shipping_FROM_Location__c + 'TO ' + opp.Shipping_TO_Location__c;
                        }
                        List<string> states = new List<string>{'AL', 'AK', 'AS', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'DC', 'FM', 'FL', 'GA', 'GU', 'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MH', 'MD', 'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY', 'NC', 'ND', 'MP', 'OH', 'OK', 'OR', 'PW', 'PA', 'PR', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VT', 'VI', 'VA', 'WA', 'WV', 'WI', 'WY' };
                        if(states.contains(opp.ShippingState__c) && opp.ShippingCountry__c != 'US') {
                            opp.ShippingCountry__c = 'US';
                        } 
                        if(opp.Signature_Type__c != null && opp.StageName != 'PO Received' && opp.Signature_Type__c != oldO.Signature_Type__c){
                            opp.StageName = 'PO Received';
                        }
                        if(opp.Deal_Type__c == 'System Deal' && opp.StageName == 'Sold but not Shipped' && opp.Ship_Date__c != null && opp.Ship_Date__c != oldO.Ship_Date__c){
                            opp.StageName = 'Closed Won';
                        }
                        if(opp.Ship_Type__c == 'Vendor Shipped' && opp.Ship_Type__c != oldO.Ship_Type__c) {
                            opp.Shipping_Cost__c = 0;
                        }
                        if((opp.RecordTypeId == PurchasingOpprt.id || opp.RecordTypeId == BigIronPurchasingOpprt.id) && String.IsNotBlank(opp.PO__c) && opp.Name.Left(3) != 'PO-') {
                            opp.Name = 'PO-' + opp.PO__c + ' - ' + opp.Name; 
                        }
                        if(opp.RecordTypeId == probeSalesRT && opp.StageName == 'Verbal Acceptance' && opp.Confirmation_number__c != null) {
                            opp.StageName = 'Finalize Transaction';
                        }
                        if(opp.Date_Repair_Evaluation_Sent_to_Customer__c != null && opp.Date_Repair_Evaluation_Sent_to_Customer__c != oldO.Date_Repair_Evaluation_Sent_to_Customer__c) {
                            opp.StageName = 'Pending Approval';
                        }
                        if(opp.Date_Repair_Evaluation_Sent__c != null && opp.Date_Repair_Evaluation_Sent__c != oldO.Date_Repair_Evaluation_Sent__c) {
                            opp.StageName = 'Evaluation Complete';
                        }
                        // Added clause for Stage Name not being Closed Lost to avoid changing Loaner Turned Exchange opps to Repair Approved 06.24.24
                        if(opp.Date_Repair_Approved__c != null && opp.Date_Repair_Approved__c != oldO.Date_Repair_Approved__c && opp.StageName != 'Closed Lost') {
                            opp.StageName = 'Repair Approved';
                        }
                        // Sets the FSR Datestamp whenever the FSR Attached or FSR Not Required checkbox is set to true.
                        if ((opp.FSR_Attached__c != oldO.FSR_Attached__c && opp.FSR_Attached__c == true) || (opp.FSR_Not_Required__c != oldO.FSR_Not_Required__c && opp.FSR_Not_Required__c == true)) {
                            
                            // Retrieve the current user's information
                            User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                        
                            if (currentUser != null) {
                                // Set the FSR_Checked_By__c field to the current user's full name
                                opp.FSR_Checked_By__c = currentUser.Name;
                            }
                        
                            // Moves the Site address location back to the ship location if a hold location is used.
                            // if (opp.Tech_Ship_Location__c != null) {
                            if (opp.Tech_Ship_Location_Address__c != null) {
                                opp.Ship_To_Account__c = opp.Hold_Ship_To_Account__c;
                                opp.ShippingStreet__c = opp.Hold_Shipping_Address_Street__c;
                                opp.ShippingCity__c = opp.Hold_Shipping_Address_City__c;
                                opp.ShippingState__c = opp.Hold_Shipping_Address_State__c;
                                opp.ShippingPostalCode__c = opp.Hold_Shipping_Address_Postal_Code__c;
                                opp.ShippingCountry__c = opp.Hold_Shipping_Address_Country__c;
                            }
                        }
                        // Removes the FSR Datestamp if it's populated and the FSR Attached AND FSR Not Required are both blank.
                        if((opp.FSR_Attached__c == false && opp.FSR_Not_Required__c == false) && opp.FSR_Datestamp__c != NULL){
                            opp.FSR_Datestamp__c = NULL;
                        }
                        Date d = Date.newInstance(2021, 1, 1);
                        System.debug('CHECK IF APPROVAL IS LOCKED');
                        
                        if(opp.IsClosed == true && opp.Iswon == true && opp.Field_Service_Engineer__c == NULL && opp.Ship_Date__c != null && opp.Ship_Date__c > d && opp.Intacct_Shipper_Sync_Status__c != 'Error' && opp.Intacct_Shipper_Sync_Status__c != 'Synced' && opp.Intacct_Shipper_Sync_Status__c != 'No Sync Needed' && opp.Intacct_Shipper_Sync_Status__c != 'Processing' && opp.RecordType.Name != 'Returns') {
                                opp.Intacct_Shipper_Sync_Status__c = 'Sync';
                        }                       
                       
                        if(opp.IsClosed == true && opp.Iswon == true && opp.Field_Service_Engineer__c != NULL && (opp.FSR_Attached__c || opp.FSR_Not_Required__c) && opp.Ship_Date__c != null && opp.Ship_Date__c > d && opp.Intacct_Shipper_Sync_Status__c != 'Error' && opp.Intacct_Shipper_Sync_Status__c != 'No Sync Needed' && opp.Intacct_Shipper_Sync_Status__c != 'Synced' && opp.Intacct_Shipper_Sync_Status__c != 'Processing' && opp.RecordType.Name != 'Returns') {
                                opp.Intacct_Shipper_Sync_Status__c = 'Sync';
                        }

                        if(opp.Field_Service_Engineer__c != null && oldO.Field_Service_Engineer__c != opp.Field_Service_Engineer__c){
                
                            List<String> engineer = opp.Field_Service_Engineer__c.split(' ');String secondPart ='';if(engineer.size () >= 2){secondPart = engineer[1];}   
                            
                            opp.FSE_Email__c = opp.Field_Service_Engineer__c.substring(0,1) + secondPart + '@probomedical.com';
                        }
                        
                        oppIdset.add(opp.Id); 

                        // Related Opps are always Sales Opps
                        if (opp.Related_Opportunity__c != null) {
                            oppIdset.add(opp.Related_Opportunity__c);
                        }
                    }


                    Map<Id, List<Work_Order__c>> oppIdToWorkOrders = new Map<Id, List<Work_Order__c>>();
                    Set<Id> uncachedWOOppIds = new Set<Id>();
                    for (Id oppId : oppIdset) {
                        if (!cachedWorkOrders.containsKey(oppId)) uncachedWOOppIds.add(oppId);
                    }
                    if (!uncachedWOOppIds.isEmpty()) {
                        for (Id oppId : uncachedWOOppIds) cachedWorkOrders.put(oppId, new List<Work_Order__c>());
                        for (Work_Order__c r : [
                                select Id, Status__c, Estimated_Ready_Date__c,
                                        Quick_Repair_Selection__c, Opportunity__c
                                from Work_Order__c
                                where Opportunity__c = :uncachedWOOppIds
                        ]) {
                            cachedWorkOrders.get(r.Opportunity__c).add(r);
                        }
                    }
                    for (Id oppId : oppIdset) oppIdToWorkOrders.put(oppId, cachedWorkOrders.get(oppId));


                    Map<Id, List<Sourcing_Request_Item__c>> oppIDtoSourceReqs = new Map<Id, List<Sourcing_Request_Item__c>>();
                    Set<Id> uncachedSRIOppIds = new Set<Id>();
                    for (Id oppId : oppIdset) {
                        if (!cachedSRIs.containsKey(oppId)) uncachedSRIOppIds.add(oppId);
                    }
                    if (!uncachedSRIOppIds.isEmpty()) {
                        for (Id oppId : uncachedSRIOppIds) cachedSRIs.put(oppId, new List<Sourcing_Request_Item__c>());
                        for (Sourcing_Request_Item__c r : [
                                select Id, Need_By_Date__c, Requesting_Opportunity__c
                                from Sourcing_Request_Item__c
                                where Requesting_Opportunity__c = :uncachedSRIOppIds
                        ]) {
                            cachedSRIs.get(r.Requesting_Opportunity__c).add(r);
                        }
                    }
                    for (Id oppId : oppIdset) oppIDtoSourceReqs.put(oppId, cachedSRIs.get(oppId));


                    // There will only ever be 1 RepairRMA on an Opp
                    Map<Id, RMA__c> oppIdToRepairRMA = new Map<Id, RMA__c>();
                    Map<Id, Set<Id>> oppIdToAllRepairRMAPItemIds = new Map<Id, Set<Id>>();
                    Map<Id, List<RMA__c>> oppIdToAllLoanerRMAs = new Map<Id, List<RMA__c>>();
                    Map<Id, Set<Id>> oppIdToAllLoanerRMAPItemIds = new Map<Id, Set<Id>>();
                    Map<Id, Set<Id>> oppIdToAllRentRetRMAPItemIds = new Map<Id, Set<Id>>();
                    Map<Id, List<RMA__c>> oppIdToAllCoreRMAs = new Map<Id, List<RMA__c>>();
                    Map<Id, Set<Id>> oppIdToAllExtRMAPItemIds = new Map<Id, Set<Id>>();
                    Map<Id, Set<Id>> oppIdToAllMatRMAPItemIds = new Map<Id, Set<Id>>();

                    Set<Id> pItemIDs = new Set<Id>();

                    // Populate RMA cache for any Opp IDs not yet seen this transaction
                    Set<Id> uncachedRMAOppIds = new Set<Id>();
                    for (Id oppId : oppIdset) {
                        if (!cachedRMAs.containsKey(oppId)) uncachedRMAOppIds.add(oppId);
                    }
                    if (!uncachedRMAOppIds.isEmpty()) {
                        for (Id oppId : uncachedRMAOppIds) cachedRMAs.put(oppId, new List<RMA__c>());
                        for (RMA__c r : [
                                select Id, ProductItem__c, Probe_Model__c, Opportunity__c, RecordTypeId,
                                        Core_Exchange_RMA__c, RMA_Item_Serial_Number__c
                                from RMA__c
                                where Opportunity__c = :uncachedRMAOppIds
                                ORDER BY CreatedDate Desc
                        ]) {
                            cachedRMAs.get(r.Opportunity__c).add(r);
                        }
                    }

                    // Build local RMA maps from the cache
                    for (Id oppId : oppIdset) {
                        for (RMA__c r : cachedRMAs.get(oppId)) {
                            if (r.RecordTypeId == EVALrt.Id) {
                                if (!oppIdToRepairRMA.containsKey(r.Opportunity__c)) {
                                    oppIdToRepairRMA.put(r.Opportunity__c, r);
                                    oppIdToAllRepairRMAPItemIds.put(r.Opportunity__c, new Set<Id>());
                                }
                                if (r.ProductItem__c != null) oppIdToAllRepairRMAPItemIds.get(r.Opportunity__c).add(r.ProductItem__c);
                            } else if (r.RecordTypeId == EXTrt.Id) {
                                if (!oppIdToAllExtRMAPItemIds.containsKey(r.Opportunity__c)) oppIdToAllExtRMAPItemIds.put(r.Opportunity__c, new Set<Id>());
                                if (r.ProductItem__c != null) oppIdToAllExtRMAPItemIds.get(r.Opportunity__c).add(r.ProductItem__c);
                            } else if (r.RecordTypeId == MTrt.Id) {
                                if (!oppIdToAllMatRMAPItemIds.containsKey(r.Opportunity__c)) oppIdToAllMatRMAPItemIds.put(r.Opportunity__c, new Set<Id>());
                                if (r.ProductItem__c != null) oppIdToAllMatRMAPItemIds.get(r.Opportunity__c).add(r.ProductItem__c);
                            } else if (r.RecordTypeId == LOANrt.Id) {
                                if (!oppIdToAllLoanerRMAs.containsKey(r.Opportunity__c)) {
                                    oppIdToAllLoanerRMAs.put(r.Opportunity__c, new List<RMA__c>());
                                    oppIdToAllLoanerRMAPItemIds.put(r.Opportunity__c, new Set<Id>());
                                }
                                oppIdToAllLoanerRMAs.get(r.Opportunity__c).add(r);
                                if (r.ProductItem__c != null) oppIdToAllLoanerRMAPItemIds.get(r.Opportunity__c).add(r.ProductItem__c);
                            } else if (r.RecordTypeId == RentRetrt.Id) {
                                if (r.ProductItem__c != null) {
                                    if (!oppIdToAllRentRetRMAPItemIds.containsKey(r.Opportunity__c)) oppIdToAllRentRetRMAPItemIds.put(r.Opportunity__c, new Set<Id>());
                                    oppIdToAllRentRetRMAPItemIds.get(r.Opportunity__c).add(r.ProductItem__c);
                                }
                            } else if (r.RecordTypeId == CORErt.Id) {
                                if (!oppIdToAllCoreRMAs.containsKey(r.Opportunity__c)) {
                                    system.debug('INSIDE ADDING RMA TO CORE MAP >>> ' + r);
                                    oppIdToAllCoreRMAs.put(r.Opportunity__c, new List<RMA__c>());
                                }
                                oppIdToAllCoreRMAs.get(r.Opportunity__c).add(r);
                            }
                            if (r.ProductItem__c != null) pItemIDs.add(r.ProductItem__c);
                        }
                    }

                    Map<Id, List<OpportunityLineItem>> oppIdtoOLIs = new Map<Id, List<OpportunityLineItem>>();
                    List<OpportunityLineItem> ollist = new List<OpportunityLineItem>();

                    for (OpportunityLineItem oli : [
                            SELECT Id, OpportunityId, ProductItem__c, Opportunity.RecordTypeId, Exchange__c,
                                    Check_In_Type__c, ProductItem__r.sold__c, ProductItem__r.Purchasing_Approved__c, Product_Family__c,
                                    ProductItem__r.Serial_No__c, Opportunity_Record_Type__c, Product_Name__c, Serial_No__c, TotalPrice, Name, UnitPrice
                            FROM OpportunityLineItem
                            WHERE OpportunityId = :oppIdset
                            ORDER BY CreatedDate DESC
                    ]) {

                        ollist.add(oli);

                        if (!oppIdtoOLIs.containsKey(oli.OpportunityId)) {
                            oppIdtoOLIs.put(oli.OpportunityId, new List<OpportunityLineItem>());
                        }
                        oppIdtoOLIs.get(oli.OpportunityId).add(oli);

                        GH_Logger.finer('checking for non PurchasingOpp');
                        if (oli.Opportunity.RecordTypeId != PurchasingOpprt.Id && oli.Opportunity.RecordTypeId != BigIronPurchasingOpprt.Id && oli.ProductItem__c != null) {
                            pItemIDs.add(oli.ProductItem__c);
                        }
                    }

                    Map<Id, ProductItem__c> pItemIdTopItem = new Map<Id, ProductItem__c>();
                    Map<Id, List<ProductItem__c>> oppIDToPItemList = new Map<Id, List<ProductItem__c>>();

                    system.debug('oppIdset: ' + oppIdset);
                    system.debug('pItemIDs: ' + pItemIDs);

                    Set<Id> uncachedPurchOppIds = new Set<Id>();
                    Set<Id> uncachedPItemIds    = new Set<Id>();
                    for (Id oppId : oppIdset) {
                        if (!cachedBeforePItemsByOpp.containsKey(oppId)) uncachedPurchOppIds.add(oppId);
                    }
                    for (Id piId : pItemIDs) {
                        if (!cachedBeforePItemsById.containsKey(piId)) uncachedPItemIds.add(piId);
                    }
                    if (!uncachedPurchOppIds.isEmpty() || !uncachedPItemIds.isEmpty()) {
                        for (Id oppId : uncachedPurchOppIds) cachedBeforePItemsByOpp.put(oppId, new List<ProductItem__c>());
                        for (ProductItem__c r : [
                                select Id, Name, Cost__c, Serial_No__c, Purchasing_Opportunity__c,
                                        Product2_Name__c, Location__c
                                from ProductItem__c
                                where Purchasing_Opportunity__c = :uncachedPurchOppIds
                                or Id in :uncachedPItemIds
                        ]) {
                            GH_Logger.finer('ProductItem__c: ' + r);
                            cachedBeforePItemsById.put(r.Id, r);
                            if (r.Purchasing_Opportunity__c != null) {
                                if (!cachedBeforePItemsByOpp.containsKey(r.Purchasing_Opportunity__c)) {
                                    cachedBeforePItemsByOpp.put(r.Purchasing_Opportunity__c, new List<ProductItem__c>());
                                }
                                cachedBeforePItemsByOpp.get(r.Purchasing_Opportunity__c).add(r);
                            }
                        }
                    }
                    // Build local maps from cache
                    for (Id piId : pItemIDs) {
                        if (cachedBeforePItemsById.containsKey(piId)) pItemIdTopItem.put(piId, cachedBeforePItemsById.get(piId));
                    }
                    for (Id oppId : oppIdset) {
                        if (cachedBeforePItemsByOpp.containsKey(oppId)) {
                            oppIDToPItemList.put(oppId, cachedBeforePItemsByOpp.get(oppId));
                            for (ProductItem__c r : cachedBeforePItemsByOpp.get(oppId)) pItemIdTopItem.put(r.Id, r);
                        }
                    }
                    system.debug('pItemIdToItem: ' + pItemIdTopItem);

                    Map<Id, OpportunityHistory> oppIdToMostRecentOppHistory = new Map<Id, OpportunityHistory>();

                    Set<Id> uncachedHistOppIds = new Set<Id>();
                    for (Id oppId : oppIdset) {
                        if (!cachedOppHistory.containsKey(oppId)) uncachedHistOppIds.add(oppId);
                    }
                    if (!uncachedHistOppIds.isEmpty()) {
                        // Pre-mark as cached so 0-result Opps aren't re-queried
                        for (Id oppId : uncachedHistOppIds) cachedOppHistory.put(oppId, null);
                        for (OpportunityHistory r : [
                                select Id, CreatedDate, OpportunityId, CloseDate, StageName
                                from OpportunityHistory
                                where OpportunityId = :uncachedHistOppIds
                                and StageName = 'Closed Won'
                                ORDER BY CreatedDate Asc
                        ]) {
                            if (cachedOppHistory.get(r.OpportunityId) == null) cachedOppHistory.put(r.OpportunityId, r);
                        }
                    }
                    for (Id oppId : oppIdset) {
                        if (cachedOppHistory.get(oppId) != null) oppIdToMostRecentOppHistory.put(oppId, cachedOppHistory.get(oppId));
                    }


                    Map<Id, List<OpportunityLineItem>> oppLineMap = new Map<Id, List<OpportunityLineItem>>();
                    List<OpportunityLineItem> ServiceFeesList = new List<OpportunityLineItem>();
                    List<OpportunityLineItem> storageBayList = new List<OpportunityLineItem>();
                    System.debug('Opp Line Items: ' + ollist);

                    // JMAY 11/20 - building the map of OppId to OLIList
                    for (OpportunityLineItem oli : ollist) {
                        if (!oppLineMap.containsKey(oli.OpportunityId)) {
                            oppLineMap.put(oli.OpportunityId, new List<OpportunityLineItem>());
                        }
                        if (oli.Name.contains('Credit Card Fee')){
                            ServiceFeesList.add(oli);
                        }
                        if(oli.Product_Family__c != null && oli.Product_Family__c.contains('Storage') && oli.Name.contains('Storage Bay') && oli.Check_In_Type__c != 'Generic'){
                            system.debug('OLI ADDED TO STORAGE BAY LIST >> ' + oli);
                            storageBayList.add(oli);
                        }

                        oppLineMap.get(oli.OpportunityId).add(oli);
                    }
                    
                    Double ServiceFeesTotal = 0.00;
                    if(ServiceFeesList.size()>0){
                        for(OpportunityLineItem oli : ServiceFeesList){
                            ServiceFeesTotal = ServiceFeesTotal + oli.TotalPrice;    
                        }
                    }
                    Double storageUnitPrice = 0.00;
                    Double storageInvoiceCharge = 0.00;
                    system.debug('THIS IS THE STORAGE BAY LIST >>> ' + storageBayList);
                    if(storageBayList.size()>0){
                        for(OpportunityLineItem oli : storageBayList){
                            storageUnitPrice += oli.UnitPrice;
                        }
                    }
                    
                    List<Move_Location__c> MoveLocationsToInsert = new List<Move_Location__c>();
                    List<RMA__c> rmasToUpsert = new List<RMA__c> ();
                    Set<Id> rmaIdsAlreadyAddedToUpsertList = new Set<Id>();
                    Map<Id, Opportunity> oppsToUpdateMap = new Map<Id, Opportunity>();
                    List<Sourcing_Request_Item__c> srcReqListsToUpdate = new List<Sourcing_Request_Item__c>();
                    Map<Id, Work_Order__c> wosToUpdateMap = new Map<Id, Work_Order__c>();

                    for (Opportunity opp : newRecs) {

                        GH_Logger.finer('Working on Opp ID for Opp field updates:' + opp);

                        Opportunity OldOpp = oldRecs.get(opp.Id);
                        String OppNameString = opp.Name;
                        
                        if(opp.Service_Fee_Amount__c != ServiceFeesTotal){
                                system.debug('Set the Service_Fee_Amount__c field to: '+ServiceFeesTotal);
                                opp.Service_Fee_Amount__c = ServiceFeesTotal;
                         }
                        
                        if(opp.RecordTypeId != null && EquipmentStorageOpprt != null && opp.RecordTypeId == EquipmentStorageOpprt.Id){
                            opp.Storage_Bay_Unit_Price__c = storageUnitPrice;
                            system.debug('THIS IS THE STORAGE BAY UNIT PRICE >> ' + storageUnitPrice);
                            if(opp.Number_of_Storage_Days_this_Invoice__c != null){
                                storageInvoiceCharge = storageUnitPrice * opp.Number_of_Storage_Days_this_Invoice__c;
                            }
                            // only autocalculate if invoice charge for storage bay has changed
                            // due to required validation rule, new field "Calculated Storage Bay Charge" updated instead of "Monthly Charge" field
                            if(OldOpp.Calculated_Storage_Bay_Charge__c != storageInvoiceCharge){
                                opp.Calculated_Storage_Bay_Charge__c = storageInvoiceCharge;
                            }
                            
                        }
                        
                        

                        // If opp is changed to closed won, this code checks to make sure none of the products
                        // (opportunity line items) are already sold. Also makes sure the product is purchasing approved.
                        if (opp.StageName == 'Closed Won' && OldOpp.StageName != 'Closed Won') {
                            System.debug('The Opp has just become Closed Won');

                            if (opp.RecordTypeId == PurchasingOpprt.Id || opp.RecordTypeId == BigIronPurchasingOpprt.Id) {
                                System.debug('Setting the CloseDate to today for Closed Won Purchasing Opp.');
                                opp.CloseDate = Date.today();
                            }
                                                        
                            
                            if (oppLineMap.containsKey(opp.Id)) {
                                system.debug('THIS IS THE CORE RMA ID MAP >>> ' + oppIdToAllCoreRMAs);
                                for (OpportunityLineItem thisOLI : oppLineMap.get(opp.Id)) {
                                    System.debug('Working with this OLI: ' + thisOLI);
                                    System.debug('Value of ProductItem__r.sold__c: ' + thisOLI.ProductItem__r.sold__c);
                                    boolean addCoreRMA = false;
                                    if(thisOLI.Exchange__c){
                                        RMA__c coreRMAtoInsert = new RMA__c(RecordTypeId = CORErt.Id, Opportunity__c = thisOLI.OpportunityId, Probe_Model_Text__c = thisOLI.Product_Name__c,
                                        ProductItem__c = thisOLI.ProductItem__c, RMA_Item_Serial_Number__c = thisOLI.Serial_No__c);
                                        addCoreRMA = true;
                                        system.debug('TESTING TO INSERT CORE RMA >>> ' + coreRMAtoInsert);
                                        if (oppIdToAllCoreRMAs.containsKey(opp.Id)) {
                                            for (RMA__c coreRMA : oppIdToAllCoreRMAs.get(opp.Id)) {
                                                system.debug('INSIDE TEST CORE RMA LOOP >>> ' + thisOLI.ProductItem__c + ' && ' + coreRMA.ProductItem__c);
                                                if(thisOLI.ProductItem__c == coreRMA.ProductItem__c){
                                                    addCoreRMA = false;
                                                }
                                        
                                            }
                                        }
                                        if(addCoreRMA){
                                            rmasToUpsert.add(coreRMAtoInsert);
                                        }
                                
                                    }
                                    
                                    
                                    // TODO: we need to review and remove the Validator_Class here and update code logic to only process as needed (or not recursively)
                                    System.debug('Checking if none of the products are already sold for Closed Won Opportunity ');
                                    if (thisOLI.ProductItem__r.sold__c == true && !Validator_Class.hasAlreadyDone4()) {
                                        System.debug('Not possible because product is already sold');
                                        opp.addError('Not possible because product is already sold');
                                    }

                                    System.debug('Checking to see if ProductItem__r.Purchasing_Approved__c is TRUE for a Closed Won Opportunity');
                                    if (thisOLI.ProductItem__r.Purchasing_Approved__c == false
                                            && thisOLI.Opportunity_Record_Type__c != 'Purchasing_Opportunity'
                                            && thisOLI.Opportunity_Record_Type__c != 'Big_Iron_Purchasing_Opportunity'
                                            && thisOLI.Check_In_Type__c != 'Customer Repair'
                                            && thisOLI.Check_In_Type__c != 'Vet – Customer Repair'
                                            && thisOLI.Check_In_Type__c != 'Vet – Warranty Repair'
                                            && thisOLI.Check_In_Type__c != 'Warranty Repair'
                                            && thisOLI.Check_In_Type__c != 'Generic') {

                                        system.debug('Not possible because product is not purchasing approved');
                                        opp.addError('Not possible because product is not purchasing approved');
                                    }

                                }
                                Validator_Class.setAlreadyDone1();
                            }

                            // For purchasing opps, checks to make sure that the cost field is filled in on any assets that have
                            // the purchasing opp field filled in with the opp that is set to Closed Won.

                            if (oppIDToPItemList.containsKey(opp.Id)) {
                                system.debug('Working with the Opp\'s ProductItems: ' + opp.Id);

                                for (ProductItem__c item : oppIDToPItemList.get(opp.Id)) {
                                    system.debug('Working with this ProductItems: ' + item);

                                    if (item.Cost__c == null) {
                                        System.debug('Not possible because assets are missing cost information');
                                        opp.addError('Not possible because assets are missing cost information');
                                        break;
                                    }
                                }
                            }
                        } else if (opp.StageName == 'Repair Evaluation' && OldOpp.StageName == 'Repair Evaluation' && oppIdToRepairRMA.containsKey(opp.Id)
                                && ((OldOpp.Opportunity_Notes__c == null && opp.Opportunity_Notes__c != null)
                                || (OldOpp.White_Glove_Service__c == false && opp.White_Glove_Service__c == true)
                                || (OldOpp.Customer_Probe__c == false && opp.Customer_Probe__c == true))
                                ) {

                            // Links opportunity notes, white glove service, and customer probe information to the repair evaluation RMA.
                            // only if opp StageName is not changed to Repair Evaluation

                            RMA__c RepairRMA = oppIdToRepairRMA.get(opp.Id);
                            system.debug('RepairRMA: ' + RepairRMA);
                            if (opp.Customer_Probe__c == true) {
                                RepairRMA.Customer_s_Probe__c = true;
                            }
                            if (opp.Related_Work_Order__c != null) {
                                RepairRMA.Work_Order__c = opp.Related_Work_Order__c;
                            }
                            if (opp.Opportunity_Notes__c != null) {
                                RepairRMA.Quality_Issue_Notes__c = opp.Opportunity_Notes__c;
                            }
                            if (opp.White_Glove_Service__c == true) {
                                RepairRMA.White_Glove_Service__c = true;
                                opp.Name = '***WGS*** ' + (RepairRMA.Probe_Model__c != null ? RepairRMA.Probe_Model__c : OppNameString);
                            }
                            if (opp.Related_Work_Order__c != null) {
                                RepairRMA.Opportunity__c = opp.Related_Work_Order__c;     
                            }

                            // make sure we are only adding each existing RMA to the Upsert list once
                            if (!rmaIdsAlreadyAddedToUpsertList.contains(RepairRMA.Id)) {
                                System.debug('Adding RepairRMA to upsert list: ' + RepairRMA.Id);
                                rmasToUpsert.add(RepairRMA);
                                rmaIdsAlreadyAddedToUpsertList.add(RepairRMA.Id);
                            }
                        } else if (opp.StageName == 'Repair Evaluation' && OldOpp.StageName != 'Repair Evaluation'
                                && !oppIdToRepairRMA.containsKey(opp.Id) && !GH_CodeUtils.isFlagSet('processedRepairRMAs')) {

                            GH_Logger.finer('Repair eval RMA of P_OpportunityTrigger');

                            // Automatically creates a repair eval RMA when stage is changed to repair evaluation
                            // as long as there is not already a RepairRMA on the Opp
                            GH_Logger.finer('Setting processedRepairRMAs');
                            GH_CodeUtils.setFlag('processedRepairRMAs');

                            if (opp.White_Glove_Service__c == true) {
                                opp.Name = '***WGS*** ' + OppNameString;
                                system.debug('#### opp.name should contain ***WGS*** : ' + opp.Name);
                            }

                            System.debug('Adding the newly-created RepairRMA to the map so it can be updated if needed');
                            rmasToUpsert.add(createRepairRMA(opp));

                        } 
                        else if (opp.StageName == 'External Repair / Testing' && OldOpp.StageName != 'External Repair / Testing'
                                && !GH_CodeUtils.isFlagSet('processedExternalRMAs')) {

                            GH_Logger.finer('Working on Opp ID for External RMA creation:' + opp);
                            System.debug('Setting processedExternalRMAs');
                            GH_CodeUtils.setFlag('processedExternalRMAs');

                            if (oppIdtoOLIs.containsKey(opp.Id)) {
                                for (OpportunityLineItem oli : oppIdtoOLIs.get(opp.Id)) {
                                    ProductItem__c thePItem = pItemIdTopItem.get(oli.ProductItem__c);
                                    // only create the RMA if the Opp doesn't already have one for this Asset.Id
                                    if (!oppIdToAllExtRMAPItemIds.containsKey(opp.Id) || !oppIdToAllExtRMAPItemIds.get(opp.Id).contains(thePItem.Id)) {
                                        rmasToUpsert.add(new RMA__c(RecordTypeId = EXTrt.Id, Opportunity__c = opp.Id, ProductItem__c = thePItem.Id, RMA_Item_Serial_Number__c = thePItem.Serial_No__c));
                                    }
                                    String usr_name = theCurrentUser.FirstName + ' ' + theCurrentUser.LastName;
                                    if(thePitem.Location__c != 'External Repair / Testing' && opp.Ship_Date__c != null){
                                        Move_Location__c newMove = new Move_Location__c(Old_Location__c = thePitem.Location__c, Note__c = 'External repair/testing shipped on ' + opp.Ship_Date__c, Related_Opportunity__c = opp.Id,
                                                                    /*External_Location__c = l.Ship_to_Account__c,*/ New_Location__c = 'External Repair / Testing', Geographic_Location__c = 'External Repair / Testing', Completed_By__c = usr_name,
                                                                    ProductItem__c = thePitem.Id);
                                        MoveLocationsToInsert.add(newMove);
                                    }
                                }
                            }
                        } else if (opp.StageName == 'Equipment Rental' && OldOpp.StageName != 'Equipment Rental'
                                && !GH_CodeUtils.isFlagSet('processedEquipRentalRMAs')) {

                            GH_Logger.finer('Working on Opp ID for External RMA creation:' + opp);

                            System.debug('Setting processedEquipRentalRMAs');
                            GH_CodeUtils.setFlag('processedEquipRentalRMAs');

                            if (oppIdtoOLIs.containsKey(opp.Id)) {
                                for (OpportunityLineItem o : oppIdtoOLIs.get(opp.Id)) {
                                    // JMAY 20190612 added for tw task: https://btekventures.teamwork.com/#/tasks/21546769?c=8748412&
                                    if (o.Check_In_Type__c != 'Generic'){
                                        ProductItem__c theAsset = pItemIdTopItem.get(o.ProductItem__c);
                                        // check if there is already a RentReturn RMA for this Opp and Asset.Id
                                        if (!oppIdToAllRentRetRMAPItemIds.containsKey(opp.Id) || !oppIdToAllRentRetRMAPItemIds.get(opp.Id).contains(theAsset.Id)) {
                                            rmasToUpsert.add(new RMA__c(RecordTypeId = RentRetrt.Id, Opportunity__c = opp.Id, ProductItem__c = theAsset.Id, RMA_Item_Serial_Number__c = theAsset.Serial_No__c));
                                        }
                                    }
                                }
                            }
                        }else if (opp.StageName == 'Probe Loan' && OldOpp.StageName != 'Probe Loan'
                                && !GH_CodeUtils.isFlagSet('processedLoanerRMAs')) {

                            GH_Logger.finer('Working on Opp ID for Loaner RMA creation:' + opp);

                            System.debug('Setting processedLoanerRMAs');
                            GH_CodeUtils.setFlag('processedLoanerRMAs');

                            if (oppIdtoOLIs.containsKey(opp.Id)) {
                                for (OpportunityLineItem o : oppIdtoOLIs.get(opp.Id)) {
                                    if (o.Check_In_Type__c != 'Generic'){
                                        ProductItem__c theAsset = pItemIdTopItem.get(o.ProductItem__c);
                                        // check if there is already a Loaner RMA for this Opp and Asset.Id
                                        if (!oppIdToAllLoanerRMAPItemIds.containsKey(opp.Id) || !oppIdToAllLoanerRMAPItemIds.get(opp.Id).contains(theAsset.Id)) {
                                            rmasToUpsert.add(new RMA__c(RecordTypeId = LOANrt.Id, Opportunity__c = opp.Id, ProductItem__c = theAsset.Id, RMA_Item_Serial_Number__c = theAsset.Serial_No__c));
                                        }
                                    }
                                }
                            }
                        }  else if (opp.StageName == 'Material Transfer' && OldOpp.StageName != 'Material Transfer'
                                && !GH_CodeUtils.isFlagSet('processedMatTransferRMAs')) {

                            GH_Logger.finer('Working on Opp ID for Material Transfer RMA creation:' + opp);

                            System.debug('Setting processedMaterialTransferRMAs');
                            GH_CodeUtils.setFlag('processedMaterialTransferRMAs');

                            if (oppIdtoOLIs.containsKey(opp.Id)) {
                                for (OpportunityLineItem oli : oppIdtoOLIs.get(opp.Id)) {
                                    // JMAY added check for !Generic per task: https://btekventures.teamwork.com/#tasks/21616463
                                    if (oli.Check_In_Type__c != 'Generic') {
                                        ProductItem__c thePItem = pItemIdTopItem.get(oli.ProductItem__c);

                                        // only create the RMA if the Opp doesn't already have one for this Asset.Id
                                        if (!oppIdToAllMatRMAPItemIds.containsKey(opp.Id) || !oppIdToAllMatRMAPItemIds.get(opp.Id).contains(thePItem.Id)) {
                                            rmasToUpsert.add(new RMA__c(RecordTypeId = MTrt.Id, Opportunity__c = opp.Id, ProductItem__c = thePItem.Id,
                                                    RMA_Item_Serial_Number__c = thePItem.Serial_No__c));
                                        }
                                        String usr_name = theCurrentUser.FirstName + ' ' + theCurrentUser.LastName;
                                        if(thePitem.Location__c != 'Material Transfer' && opp.Ship_Date__c != null){
                                            Move_Location__c newMove = new Move_Location__c(Old_Location__c = thePitem.Location__c, Note__c = 'Material Transfer shipped on ' + opp.Ship_Date__c, Related_Opportunity__c = opp.Id,
                                                                        /*External_Location__c = l.Ship_to_Account__c,*/ New_Location__c = 'Material Transfer', Geographic_Location__c = 'Material Transfer', Completed_By__c = usr_name,
                                                                        ProductItem__c = thePitem.Id);
                                            MoveLocationsToInsert.add(newMove);
                                        }
                                    }
                                }
                            }
                        }


                        // Updates the close date
                        // this sets the Close Date on any Edit to the earliest CloseDate if an Opp has ever been Closed Won
                        if ((opp.RecordTypeId == PurchasingOpprt.Id || opp.RecordTypeId == BigIronPurchasingOpprt.Id) && !(opp.StageName == 'Closed Won' && OldOpp.StageName != 'Closed Won')) {
                            if (oppIdToMostRecentOppHistory.containsKey(opp.Id)) {
                                System.debug('Setting the CloseDate to most recent History CloseDate.');
                                opp.CloseDate = oppIdToMostRecentOppHistory.get(opp.Id).CreatedDate.date();
                            }
                        }

                        GH_Logger.finer('Working on Opp ID for Repair_Eval_Serial_Number change:' + opp);

                        // Links repair eval serial number field to Repair Eval RMA
                        if ((opp.Repair_Evaluation_Serial_Number__c != OldOpp.Repair_Evaluation_Serial_Number__c)
                                && opp.Repair_Evaluation_Serial_Number__c != null
                                && oppIdToRepairRMA.containsKey(opp.Id)) {
                            System.debug('Updating RepairRMA for Repair_Evaluation_Serial_Number from opp');

                            RMA__c RepairRMA = oppIdToRepairRMA.get(opp.Id);
                                    system.debug('THIS IS THE OPP SERIAL NO >>> ' + opp.Repair_Evaluation_Serial_Number__c + ' && THIS IS THE RMA SERIAL NO >>> ' + RepairRMA.RMA_Item_Serial_Number__c);
                            if(opp.Repair_Evaluation_Serial_Number__c != RepairRMA.RMA_Item_Serial_Number__c){
                              RepairRMA.RMA_Item_Serial_Number__c = opp.Repair_Evaluation_Serial_Number__c;

                                if (opp.Opportunity_Notes__c != null) {
                                    RepairRMA.Quality_Issue_Notes__c = opp.Opportunity_Notes__c;
                                }
    
                                // make sure we are only adding each existing RMA to the Upsert list once
                                if (!rmaIdsAlreadyAddedToUpsertList.contains(RepairRMA.Id)) {
                                    System.debug('Adding RepairRMA to upsert list: ' + RepairRMA.Id);
                                    rmasToUpsert.add(RepairRMA);
                                    rmaIdsAlreadyAddedToUpsertList.add(RepairRMA.Id);
                                }          
                            }        
                            
                        }


                        // If ship date is entered on an opp, a move location is automatically added to the product
                        if (opp.Ship_Date__c != null && OldOpp.Ship_Date__c != opp.Ship_Date__c) {
                            
                            GH_Logger.debug('Working on Opp ID for Opp Ship Date changes:' + opp);
                            

                            if (opp.StageName == 'Probe Loan') {

                                if (OldOpp.Ship_Date__c == null && !GH_CodeUtils.isFlagSet('processedMoveLocations')) {

                                    GH_Logger.finer('Working on Opp ID for Move Location creation:' + opp);

                                    System.debug('Setting processedMoveLocations');
                                    GH_CodeUtils.setFlag('processedMoveLocations');

                                    System.debug('finding ALL the LoanerRMAs and creating Move_Locations__c');
                                    if (oppIdToAllLoanerRMAs.containsKey(opp.Id)) {
                                        for (RMA__c LoanerRMA : oppIdToAllLoanerRMAs.get(opp.Id)) {

                                            ProductItem__c theAsset = pItemIdTopItem.get(LoanerRMA.ProductItem__c);

                                            String usr_name = theCurrentUser.FirstName + ' ' + theCurrentUser.LastName;
                                            Date shipdate = Date.newInstance(opp.Ship_Date__c.year(), opp.Ship_Date__c.month(), opp.Ship_Date__c.day());
                                            String ship = String.valueOf(shipdate);
                                            
                                            Move_Location__c newMove = new Move_Location__c(Old_Location__c = theAsset.Location__c, Note__c = 'Loaner shipped on ' + ship, Related_Opportunity__c = opp.Id,
                                                   /* External_Location__c = opp.AccountId,*/ New_Location__c = 'Customer Loan / Demo', Geographic_Location__c = 'Customer Loan / Demo', Completed_By__c = usr_name,
                                                    ProductItem__c = theAsset.Id);
                                            MoveLocationsToInsert.add(newMove);
                                        }
                                    }
                                }
                           /*
                                if (opp.Related_Opportunity__c != null && oppIdToRepairRMA.containsKey(opp.Related_Opportunity__c)) {
                                    RMA__c RepairRMA = oppIdToRepairRMA.get(opp.Related_Opportunity__c);
                                    RepairRMA.Date_Loaner_Shipped__c = opp.Ship_Date__c;

                                    // make sure we are only adding each existing RMA to the Upsert list once
                                    if (!rmaIdsAlreadyAddedToUpsertList.contains(RepairRMA.Id)) {
                                        System.debug('Adding RepairRMA to upsert list: ' + RepairRMA.Id);
                                        rmasToUpsert.add(RepairRMA);
                                        rmaIdsAlreadyAddedToUpsertList.add(RepairRMA.Id);
                                    }
                                }*/
                            } 
                             else if (opp.StageName == 'Repair Evaluation') {

                                GH_Logger.debug('We have an Opp in Repair Evaluation Stage');
                                if (opp.Related_Opportunity__c != null && oppIdToAllLoanerRMAs.containsKey(opp.Related_Opportunity__c)) {
                                    GH_Logger.debug('it has at least 1 LoanerRMA');

                                    for (RMA__c LoanerRMA : oppIdToAllLoanerRMAs.get(opp.Related_Opportunity__c)) {
                                        GH_Logger.debug('setting LoanerRMA Date_Repaired_Probe_Shipped for RMA ' + LoanerRMA.Id);
                                        LoanerRMA.Date_Repaired_Probe_Shipped__c = opp.Ship_Date__c;

                                        // make sure we are only adding each existing RMA to the Upsert list once
                                        if (!rmaIdsAlreadyAddedToUpsertList.contains(LoanerRMA.Id)) {
                                            System.debug('Adding LoanerRMA to upsert list: ' + LoanerRMA.Id);
                                            rmasToUpsert.add(LoanerRMA);
                                            rmaIdsAlreadyAddedToUpsertList.add(LoanerRMA.Id);
                                        } else {
                                            GH_Logger.debug('LoanerRMA is already in the upsert list Not adding again');
                                        }
                                    }
                                }
                            } else if (opp.StageName == 'Equipment Rental') {
                                if (oppIdtoOLIs.containsKey(opp.Id)) {
                                    for (OpportunityLineItem oli : oppIdtoOLIs.get(opp.Id)) {

                                        ProductItem__c theAsset = pItemIdTopItem.get(oli.ProductItem__c);
                                        String usr_name = theCurrentUser.FirstName + ' ' + theCurrentUser.LastName;
                                        Date shipdate = Date.newInstance(opp.Ship_Date__c.year(), opp.Ship_Date__c.month(), opp.Ship_Date__c.day());
                                        String ship = String.valueOf(shipdate);
                                        if (oli.Check_In_Type__c != 'Generic') {
                                            Move_Location__c newMove = new Move_Location__c(Old_Location__c = theAsset.Location__c, Note__c = 'Rental shipped on ' + ship, Related_Opportunity__c = opp.Id,
                                                    External_Location__c = opp.AccountId, New_Location__c = 'On Rental', Geographic_Location__c = 'On Rental', Completed_By__c = usr_name,
                                                    ProductItem__c = theAsset.Id);
                                            MoveLocationsToInsert.add(newMove);
                                        }
                                    }
                                }
                            } else if(opp.StageName == 'Material Transfer' || opp.StageName == 'External Repair / Testing'){
                                if (oppIdtoOLIs.containsKey(opp.Id)) {
                                    for (OpportunityLineItem oli : oppIdtoOLIs.get(opp.Id)) {
                                    // JMAY added check for !Generic per task: https://btekventures.teamwork.com/#tasks/21616463
                                        if (oli.Check_In_Type__c != 'Generic') {
                                            ProductItem__c thePItem = pItemIdTopItem.get(oli.ProductItem__c);
                                            String usr_name = theCurrentUser.FirstName + ' ' + theCurrentUser.LastName;
                                            if(opp.StageName == 'Material Transfer'){
                                                if(thePitem.Location__c != 'Material Transfer'){
                                                    Move_Location__c newMove = new Move_Location__c(Old_Location__c = thePitem.Location__c, Note__c = 'Material Transfer shipped on ' + opp.Ship_Date__c, Related_Opportunity__c = opp.Id,
                                                                                /*External_Location__c = l.Ship_to_Account__c,*/ New_Location__c = 'Material Transfer', Geographic_Location__c = 'Material Transfer', Completed_By__c = usr_name,
                                                                                ProductItem__c = thePitem.Id);
                                                    MoveLocationsToInsert.add(newMove);
                                                }
                                            }
                                            if(opp.StageName == 'External Repair / Testing'){
                                                if(thePitem.Location__c != 'External Repair / Testing'){
                                                    Move_Location__c newMove = new Move_Location__c(Old_Location__c = thePitem.Location__c, Note__c = 'External Repair / Testing shipped on ' + opp.Ship_Date__c, Related_Opportunity__c = opp.Id,
                                                                                /*External_Location__c = opp.Ship_to_Account__c,*/ New_Location__c = 'External Repair / Testing', Geographic_Location__c = 'External Repair / Testing', Completed_By__c = usr_name,
                                                                                ProductItem__c = thePitem.Id);
                                                    MoveLocationsToInsert.add(newMove);
                                                }
                                            }
                                            
                                        }
                                    }
                                }
                                
                                
                                
                                
                            }else if (opp.StageName == 'Closed Won'){

                                GH_Logger.debug('We have an Opp in Closed Won Stage');
                                if (opp.Related_Opportunity__c != null && oppIdToAllLoanerRMAs.containsKey(opp.Related_Opportunity__c)) {
                                    GH_Logger.debug('it has at least 1 LoanerRMA');

                                    for (RMA__c LoanerRMA : oppIdToAllLoanerRMAs.get(opp.Related_Opportunity__c)) {
                                        GH_Logger.debug('setting LoanerRMA Date_Repaired_Probe_Shipped for RMA ' + LoanerRMA.Id);
                                        LoanerRMA.Date_Repaired_Probe_Shipped__c = opp.Ship_Date__c;

                                        // make sure we are only adding each existing RMA to the Upsert list once
                                        if (!rmaIdsAlreadyAddedToUpsertList.contains(LoanerRMA.Id)) {
                                            System.debug('Adding LoanerRMA to upsert list: ' + LoanerRMA.Id);
                                            rmasToUpsert.add(LoanerRMA);
                                            rmaIdsAlreadyAddedToUpsertList.add(LoanerRMA.Id);
                                        } else {
                                            GH_Logger.debug('LoanerRMA is already in the upsert list Not adding again');
                                        }
                                    }
                                }

                                 if (opp.RecordTypeId == ReturnsOpprt.id) {
                                     if (oppIdtoOLIs.containsKey(opp.Id)) {
                                         for (OpportunityLineItem oli : oppIdtoOLIs.get(opp.Id)) {

                                             ProductItem__c theAsset = pItemIdTopItem.get(oli.ProductItem__c);
                                             String usr_name = theCurrentUser.FirstName + ' ' + theCurrentUser.LastName;
                                             Date shipdate = Date.newInstance(opp.Ship_Date__c.year(), opp.Ship_Date__c.month(), opp.Ship_Date__c.day());
                                             String ship = String.valueOf(shipdate);
                                             if (oli.Check_In_Type__c != 'Generic') {
                                                 Move_Location__c newMove = new Move_Location__c(Old_Location__c = theAsset.Location__c, Note__c = 'Return shipped on ' + ship, Related_Opportunity__c = opp.Id,
                                                         External_Location__c = opp.AccountId, New_Location__c = 'Returned to Vendor/Cust', Geographic_Location__c = 'Returned to Vendor/Cust', Completed_By__c = usr_name,
                                                         ProductItem__c = theAsset.Id);
                                                 MoveLocationsToInsert.add(newMove);
                                             }
                                         }
                                     }
                                 }
                            }
                        }

                        // If estimated ready date is changed, update work orders and/or sourcing requests with new ready date
                        if ((opp.Estimated_Ready_Date__c != OldOpp.Estimated_Ready_Date__c && opp.Estimated_Ready_Date__c != null) ||
                                (opp.Quick_Repair_Selection__c != OldOpp.Quick_Repair_Selection__c && opp.Quick_Repair_Selection__c != null)) {

                            GH_Logger.finer('Working on Opp ID for Opp Estimated Ready Date change: ' + opp);

                            List<Work_Order__c> wolist = new List<Work_Order__c>();

                            if (oppIdToWorkOrders.containsKey(opp.Id)) {
                                wolist = oppIdToWorkOrders.get(opp.Id);
                            }

                            for (Work_Order__c wo : wolist) {
                                Boolean changed = false;
                                if (opp.Estimated_Ready_Date__c != OldOpp.Estimated_Ready_Date__c & opp.Estimated_Ready_Date__c != null) {
                                    wo.Estimated_Ready_Date__c = opp.Estimated_Ready_Date__c;
                                    changed = true;
                                }
                                if (opp.Quick_Repair_Selection__c != OldOpp.Quick_Repair_Selection__c && opp.Quick_Repair_Selection__c != null) {
                                    wo.Quick_Repair_Selection__c = opp.Quick_Repair_Selection__c;
                                    changed = true;
                                }

                                if (changed) {
                                    wosToUpdateMap.put(wo.Id, wo);
                                }
                            }

                            if (opp.Estimated_Ready_Date__c != null) {
                                List<Sourcing_Request_Item__c> requestlist = new List<Sourcing_Request_Item__c>();

                                if (oppIDtoSourceReqs.containsKey(opp.Id)) {
                                    requestlist = oppIDtoSourceReqs.get(opp.Id);
                                }
                                for (Sourcing_Request_Item__c SRI : requestlist) {
                                    SRI.Need_By_Date__c = opp.Estimated_Ready_Date__c;
                                }
                                srcReqListsToUpdate.addAll(requestlist);
                            }
                        }
                    } // end for trigger loop


                    System.debug('Inserting this many Move Locations in P_OpportunityTrigger: ' + MoveLocationsToInsert.size());
                    if (!MoveLocationsToInsert.isEmpty()) {
                        DatabaseService.insertList(MoveLocationsToInsert);
                    }

                    System.debug('Upserting this many RMAs in P_OpportunityTrigger: ' + rmasToUpsert.size());
                    if (!rmasToUpsert.isEmpty()) {
                        DatabaseService.upsertList(rmasToUpsert);
                    }

                    System.debug('Updating this many Opportunities in P_OpportunityTrigger: ' + oppsToUpdateMap.size());
                    if (!oppsToUpdateMap.isEmpty()) {
                        system.debug('OPP UPDATE FROM INSIDE OPP TRIGGER >> ' + oppsToUpdateMap);
                        DatabaseService.updateList(oppsToUpdateMap.values());
                        
                    }

                    System.debug('Updating this many Work Orders in P_OpportunityTrigger: ' + wosToUpdateMap.size());
                    if (!wosToUpdateMap.isEmpty()) {
                        DatabaseService.updateList(wosToUpdateMap.values());
                    }

                    System.debug('Updating this many Source Request Items in P_OpportunityTrigger: ' + srcReqListsToUpdate.size());
                    if (!srcReqListsToUpdate.isEmpty()) {
                        DatabaseService.updateList(srcReqListsToUpdate);
                    }
                }
            }
            
        } else { // isAfter

            if (Trigger.isInsert) {

                // automatically populates the Repair RMA if the stage of the opp starts out in Repair Eval.

                List<RMA__c> rmaToInsert = new List<RMA__c>();

                for (Opportunity opp : newRecs) {

                    System.debug('Checking Opp to see if it is Inserted as Repair Evaluation: ' + opp.Id);
                    System.debug('Stage: ' + opp.StageName);

                    if (opp.StageName == 'Repair Evaluation') {
                        System.debug('in Opp after insert - Setting processedRepairRMAs');
                        GH_CodeUtils.setFlag('processedRepairRMAs');
                        rmaToInsert.add(createRepairRMA(opp));
                    }
                }

                System.debug('Opp after insert has this many RMAs to insert: ' + rmaToInsert.size());
                if (!rmaToInsert.isEmpty()) {
                    DatabaseService.insertList(rmaToInsert);
                }

                createOCRs(newRecs);

            } else if (Trigger.isUpdate) {

                // The validator class forces this to only run through the code once. So if something in this code updates another
                // object and that in turn updates the opportunity, it won't run through the code a second time. We implemented this
                // because we were running into query limits. The validator class on this trigger also impacts BeforeUpdateOpportunity trigger.
                system.debug('starting P_OpportunityTrigger After Update');

                Set<Id> oppIdsToWorkWith = new Set<Id>();

                for (Opportunity o : newRecs) {
                    // do not update anything for Material Transfer Opps, including reserved/sold box
                    if (o.RecordTypeId != materialTransferOpprt.Id) {
                        oppIdsToWorkWith.add(o.Id);
                    	system.debug('adding opp to oppIdsToWorkWith: ' + o);    
                    }
                 
                }

                List<OpportunityLineItem> olisToCheck = new List<OpportunityLineItem>();
                Set<Id> prodItemIdSet = new Set<Id>();

                for (OpportunityLineItem oli : [
                        select Id, OpportunityId, ProductItem__c, UnitPrice,
                                ProductItem__r.sold__c, ProductItem__r.Reserved__c,
                                Sales_Product__c, Product__c, Name, Opportunity.RecordType.Name
                        from OpportunityLineItem
                        where OpportunityId in :oppIdsToWorkWith
                        and ProductItem__c != null
                ]) {

                    olisToCheck.add(oli);
                    prodItemIdSet.add(oli.ProductItem__c);
                }

                system.debug('olisToCheck : ' + olisToCheck);
                system.debug('prodItemIdSet : ' + prodItemIdSet);
                Map<Id, ProductItem__c> pitemMap;
                List<OpportunityLineItem> oliList;

                // this Set contains ProdItem Ids that ARE on other OLI (do not reset Reserved__c)
                // using a Map so we can confirm that the 'other OLI' are not the current ones
                Map<Id, Set<Id>> prodItemIDtoWonOpps = new Map<Id, Set<Id>>();

                if (!prodItemIdSet.isEmpty()) {
                    system.debug('THIS IS RIGHT BEFORE THE P ITEM MAP QUERY >>>');
                    // ProductItem cache — modifications made to these objects in this run persist
                    // in the cache reference, making subsequent runs idempotent rather than stale.
                    Set<Id> uncachedAfterPItemIds = new Set<Id>();
                    for (Id piId : prodItemIdSet) {
                        if (!cachedAfterPItems.containsKey(piId)) uncachedAfterPItemIds.add(piId);
                    }
                    if (!uncachedAfterPItemIds.isEmpty()) {
                        for (ProductItem__c pi : [
                                select Id, sold__c, Added_To_Opportunity__c, Reserved__c,
                                        Generic_Product__c, Product_Qty_Overstock__c, Location__c,
                                        Product_Name__c, Check_In_Type__c, Name
                                from ProductItem__c
                                where Id in :uncachedAfterPItemIds
                        ]) {
                            cachedAfterPItems.put(pi.Id, pi);
                        }
                    }
                    pitemMap = new Map<Id, ProductItem__c>();
                    for (Id piId : prodItemIdSet) {
                        if (cachedAfterPItems.containsKey(piId)) pitemMap.put(piId, cachedAfterPItems.get(piId));
                    }
                    system.debug('THIS IS THE P ITEM MAP QUERY RESULTS >>> ' + pitemMap);
                    // OLI stage-check cache — queries OLIs on OTHER Opps for the same ProductItems.
                    // Those Opps are not part of this transaction, so results are stable.
                    Set<Id> uncachedStageCheckPItemIds = new Set<Id>();
                    for (Id piId : prodItemIdSet) {
                        if (!cachedStageCheckOLIs.containsKey(piId)) uncachedStageCheckPItemIds.add(piId);
                    }
                    if (!uncachedStageCheckPItemIds.isEmpty()) {
                        for (Id piId : uncachedStageCheckPItemIds) cachedStageCheckOLIs.put(piId, new List<OpportunityLineItem>());
                        for (OpportunityLineItem oli : [
                                SELECT Id, ProductItem__c, ProductItem__r.Date_RMA_Item_Received__c, OpportunityId,
                                        Stage__c, Ship_Date__c
                                FROM OpportunityLineItem
                                WHERE ProductItem__c = :uncachedStageCheckPItemIds AND Check_In_Type__c != 'Generic'
                                AND (Stage__c = 'Verbal Acceptance' OR Stage__c = 'Probe Loan' OR Stage__c = 'PO Received' OR Stage__c = 'Sold but not shipped' OR
                                    Stage__c = 'Closed Won' OR Stage__c = 'Sourcing' OR Stage__c = 'Finalize Transaction' OR Stage__c = 'External Repair/Testing'
                                    OR Stage__c = 'Equipment Rental' OR Stage__c = 'Invoicing' OR Stage__c = 'Awaiting Payment')
                        ]) {
                            cachedStageCheckOLIs.get(oli.ProductItem__c).add(oli);
                        }
                    }
                    oliList = new List<OpportunityLineItem>();
                    for (Id piId : prodItemIdSet) oliList.addAll(cachedStageCheckOLIs.get(piId));
                    system.debug('THIS IS THE OLI LIST >>> ' + oliList);
                    for (OpportunityLineItem r: oliList) {
                        system.debug('THIS IS JUST INSIDE THE OLI QUERY >>> ' + r);
                        if (r.Stage__c == 'Verbal Acceptance' || r.Stage__c == 'Sourcing' || r.Stage__c == 'Finalize Transaction' || r.Stage__c == 'External Repair/Testing' || r.Stage__c == 'Equipment Rental' || r.Stage__c == 'Invoicing' || r.Stage__c == 'Awaiting Payment' ||
                            (r.Stage__c == 'Probe Loan' && (r.ProductItem__r.Date_RMA_Item_Received__c == null || r.ProductItem__r.Date_RMA_Item_Received__c < r.Ship_Date__c)) || r.Stage__c == 'PO Received' || r.Stage__c == 'Sold but not shipped' || (r.Stage__c == 'Closed Won' && r.Ship_Date__c == null)) {
                            system.debug('INSIDE CHECK LOOP');
                            if (!prodItemIDtoVerbalOrProbeLoanOLI.containsKey(r.ProductItem__c)) {
                                prodItemIDtoVerbalOrProbeLoanOLI.put(r.ProductItem__c, new Set<Id>());
                            }
                            prodItemIDtoVerbalOrProbeLoanOLI.get(r.ProductItem__c).add(r.Id);
                        }
            system.debug('THIS IS THE STAGE >> ' + r.Stage__c + ' AND THIS IS THE PRODITEM LIST >> ' + proditemIdtoVerbalorProbeLoanOLI);
                        if (r.Stage__c == 'Closed Won' && r.Ship_Date__c != null) {
                            if (!prodItemIDtoWonOpps.containsKey(r.ProductItem__c)) {
                                prodItemIDtoWonOpps.put(r.ProductItem__c, new Set<Id>());
                            }
                            prodItemIDtoWonOpps.get(r.ProductItem__c).add(r.OpportunityId);
                        }


                    }
                } else {
                    system.debug('Unable to find ProductItem__c for OLIs');
                    return;
                }

                Map<Id, ProductItem__c> pitemsToUpdateMap = new Map<Id, ProductItem__c>();
                List<Move_Location__c> MoveLocationsToInsert = new List<Move_Location__c>();

                Map<Id, OpportunityLineItem> oliToUpdateMap = new Map<Id, OpportunityLineItem>();
                // Sets reserved, sold box, and overstock probe when sold. Also linked field for sales product so opportunity
                // products are listed underneath the product page.
                Map<ID,ProductItem__c> ProductItemsToUpdate = new Map<ID,ProductItem__c>();
                for (OpportunityLineItem line : olisToCheck) {

                    if (pitemMap.containsKey(line.ProductItem__c)) {

                        system.debug('Found a ProductItem__c record for OLI: ' + line.Id + ' and this ProductItem: ' + pitemMap.get(line.ProductItem__c));
                        ProductItem__c pc = pitemMap.get(line.ProductItem__c);
                        

                        // Potential code written for only checking sold on Closed Won if ship date included. But issue currently
                        // exists even with current code for verbal acceptance or Probe Loan - if the same asset is on two different verbal
                        // acceptance opps, this code will uncheck the reserved box. But if it's still on another verbal acceptance
                        // or Probe Loan opp, then it needs to remain reserved. But using a query to look up all the opps an asset is on will
                        // only increase the number of queries, and the code currently is already hitting the limit of 101 with
                        // only 20-30 assets on one opp. Need to fix code.
                        system.debug('check if generic product');
                        if (pc.Generic_Product__c == false || pc.Check_In_Type__c != 'Generic') {
                        system.debug('not generic product');
                        system.debug('newRecMap.get(line.OpportunityId).StageName: ' + newRecMap.get(line.OpportunityId).StageName);
                            String usr_name = theCurrentUser.FirstName + ' ' + theCurrentUser.LastName;
                          
                            // checks sold box if repair declined and ship date entered to remove from inventory
                          
                            if (newRecMap.get(line.OpportunityId).StageName == 'Repair Declined' && (newRecMap.get(line.OpportunityID).Ship_Date__c != null
                                   && (newRecMap.get(line.OpportunityId).Ship_Date__c != oldRecs.get(line.OpportunityId).Ship_Date__c))) {
                                System.debug('Setting OLI ProductItem Sold to TRUE');
                                pc.sold__c = true;
                                pc.Ship_Date__c = newRecMap.get(line.OpportunityId).Ship_Date__c;       
                                if(pc.Location__c != 'Shipping' && pc.Location__c != 'Customer Loan / Demo'){
                                      Move_Location__c newMove = new Move_Location__c(Old_Location__c = pc.Location__c, Note__c = 'Shipped on ' + newRecMap.get(line.OpportunityId).Ship_Date__c, Related_Opportunity__c = newRecMap.get(line.OpportunityId).Id,
                                                                                           /*External_Location__c = l.Ship_to_Account__c,*/ New_Location__c = 'Shipping', Geographic_Location__c = 'Shipping', Completed_By__c = usr_name,
                                                                                           ProductItem__c = pc.Id);
                                      MoveLocationsToInsert.add(newMove);
                                }   
                                       
                            }
                            
                            if (newRecMap.get(line.OpportunityId).StageName == 'Closed Won') {
                                // Closed Won but no ship date
                                if(newRecMap.get(line.OpportunityId).Ship_Date__c == null){
                                    pc.Reserved__c = true;
                                }
                                // Closed Won with ship date
                                if(newRecMap.get(line.OpportunityID).Ship_Date__c != null
                                   && (newRecMap.get(line.OpportunityId).Ship_Date__c != oldRecs.get(line.OpportunityId).Ship_Date__c)){
                                System.debug('Opp is closed won and ship date was just added');
                
                                if (pc.Check_In_Type__c != 'Customer Repair'
                                        && newRecMap.get(line.OpportunityId).RecordTypeId != PurchasingOpprt.Id
                                        && newRecMap.get(line.OpportunityId).RecordTypeId != BigIronPurchasingOpprt.Id) {
                                    line.Sales_Product__c = pc.Product_Name__c;
                                    system.debug('Adding this OLI to be updated due to Opp Close Winning: ' + line);
                                    oliToUpdateMap.put(line.Id, line);
                                }

                                System.debug('Setting OLI ProductItem Sold to TRUE');
                                pc.sold__c = true;
                                if(pc.Location__c != 'Shipping' && pc.Location__c != 'Customer Loan / Demo'){
                                      Move_Location__c newMove = new Move_Location__c(Old_Location__c = pc.Location__c, Note__c = 'Shipped on ' + newRecMap.get(line.OpportunityId).Ship_Date__c, Related_Opportunity__c = newRecMap.get(line.OpportunityId).Id,
                                                                                           /*External_Location__c = l.Ship_to_Account__c,*/ New_Location__c = 'Shipping', Geographic_Location__c = 'Shipping', Completed_By__c = usr_name,
                                                                                           ProductItem__c = pc.Id);
                                      MoveLocationsToInsert.add(newMove);
                                }      
                                       
                                Validator_Class.setFlag('Product_Item Sold on ClosedWon with ShipDate');
                                       Validator_Class.setAlreadyDone4();
                                pc.Reserved__c = false;


                                

                                System.debug('Setting ProductItem Overstock_Probe_When_Sold__c based on Product_Qty_Overstock__c value of: ' + pc.Product_Qty_Overstock__c);
                                pc.Overstock_Probe_When_Sold__c = (pc.Product_Qty_Overstock__c > 0);
                                pc.Ship_Date__c = newRecMap.get(line.OpportunityId).Ship_Date__c;
                                   }
                                
                                if (line.UnitPrice != NULL && (line.Opportunity.RecordType.Name.contains('Sales') || line.Opportunity.RecordType.Name.contains('Repair'))) {
                                    system.debug('Set Sales Price of: ' + line.Name + ' to: ' + line.UnitPrice);
                                    pc.Sales_Price__c = line.UnitPrice;                                    
                                }
                                // TODO: Natalie will confirm with Zach if the PB set opp to Product item can be put here
                            } else if (newRecMap.get(line.OpportunityId).StageName != 'Closed Won') {

                                if (oldRecs.get(line.OpportunityId).StageName == 'Closed Won') {

                                    System.debug('Opp has just been re-opened');

                                    if (pc.Check_In_Type__c != 'Customer Repair')
                                    {

                                        if (line.Sales_Product__c != null) {
                                            line.Sales_Product__c = null;
                                            system.debug('Reset Sales_Product__c - adding to update due to Opp Re-Open: ' + line);
                                            oliToUpdateMap.put(line.Id, line);
                                        }

                                        if (line.Product__c != null) {
                                            line.Product__c = null;
                                            system.debug('Reset Purchasing Product (Product__c) - adding to update due to Opp Re-Open: ' + line);
                                            oliToUpdateMap.put(line.Id, line);
                                        }
                                        
                                    }
                  
                                    Boolean isOnWonOpp = false;
                                    if (prodItemIDtoWonOpps.containsKey(pc.Id)) {

                                        // look at all the OLI Ids that this is related to and see if there is one that is NOT the current Opp
                                        for (Id theOppId : prodItemIDtoWonOpps.get(pc.Id)) {
                                            if (theOppId != line.OpportunityId) {
                                                isOnWonOpp = true;
                                                break;
                                            }
                                        }
                                    }

                                if (!isOnWonOpp) {
                                        System.debug('Setting OLI ProductItem Sold to FALSE');
                                        pc.sold__c = false;
                                        if (line.UnitPrice != NULL) {
                                            pc.Sales_Price__c = null;
                                        }
                                }   
                                }
                                                               
                                 
                if ((newRecMap.get(line.OpportunityId).StageName == 'Verbal Acceptance' || 
                                     newRecMap.get(line.OpportunityId).StageName == 'PO Received' || 
                                     newRecMap.get(line.OpportunityId).StageName == 'Sold but not shipped' ||
                                     newRecMap.get(line.OpportunityId).StageName == 'Probe Loan'||
                                    newRecMap.get(line.OpportunityId).StageName == 'Sourcing' ||
                                    newRecMap.get(line.OpportunityId).StageName == 'Finalize Transaction' ||
                                    newRecMap.get(line.OpportunityId).StageName == 'Equipment Rental' ||
                                    newRecMap.get(line.OpportunityId).StageName == 'External Repair/Testing'||
                                    newRecMap.get(line.OpportunityId).StageName == 'Invoicing' ||
                                    newRecMap.get(line.OpportunityId).StageName == 'Awaiting Payment' ||
                                    newRecMap.get(line.OpportunityId).StageName == 'Material Transfer')) {

                                    System.debug('Opp is Verbal Acceptance, PO received, Sold but not shipped, Probe Loan, Sourcing, or Finalize Transaction');
                                    if (!canResetReserved(pc.Id, line.Id)) {
                                        if(newRecMap.get(line.OpportunityID).Deal_Type__c == 'System Deal'){
                                            newRecMap.get(line.OpportunityId).adderror('Asset ' + pc.name + ' is already reserved on another opp. Please swap out and try again.');
                                        }
                                    }
                                         system.debug('This is reserved >>> ' + pc.Reserved__c);
                                         if(!pc.Reserved__c){
                                             pc.Reserved__c = true;
                                         }   
                                    

                                } else if (newRecMap.get(line.OpportunityId).StageName != 'Verbal Acceptance'
                                        && newRecMap.get(line.OpportunityId).StageName != 'Probe Loan'
                                           &&newRecMap.get(line.OpportunityId).StageName != 'PO Received'
                                        && newRecMap.get(line.OpportunityId).StageName != 'Sold but not shipped'
                                        && newRecMap.get(line.OpportunityId).StageName != 'Sourcing'
                                           && newRecMap.get(line.OpportunityId).StageName != 'Finalize Transaction'
                                           && newRecMap.get(line.OpportunityId).StageName != 'Equipment Rental'
                                           && newRecMap.get(line.OpportunityId).StageName != 'External Repair/Testing'
                                           && newRecMap.get(line.OpportunityId).StageName != 'Invoicing'
                                           && newRecMap.get(line.OpportunityId).StageName != 'Awaiting Payment'
                                           && newRecMap.get(line.OpportunityId).StageName != 'Material Transfer'
                                        &&   (oldRecs.get(line.OpportunityId).StageName == 'Verbal Acceptance'
                                        || oldRecs.get(line.OpportunityId).StageName == 'Probe Loan'
                                           ||oldRecs.get(line.OpportunityId).StageName == 'PO Received'
                                        || oldRecs.get(line.OpportunityId).StageName == 'Sold but not shipped' ||
                                           oldRecs.get(line.OpportunityId).StageName == 'Sourcing' ||
                                    oldRecs.get(line.OpportunityId).StageName == 'Finalize Transaction' ||
                                             oldRecs.get(line.OpportunityId).StageName == 'Equipment Rental' ||
                                             oldRecs.get(line.OpportunityId).StageName == 'External Repair/Testing' || 
                                             oldRecs.get(line.OpportunityId).StageName == 'Invoicing' ||
                                             oldRecs.get(line.OpportunityId).StageName == 'Awaiting Payment' ||
                                             oldRecs.get(line.OpportunityId).StageName == 'Material Transfer')) {

                                    System.debug('Opp left Verbal Acceptance or Probe Loan but is still Open - need to update ProductItem: ' + pc.Id);

                                    if (canResetReserved(pc.Id, line.Id)) {
                                        System.debug('Opp that was just Verbal Acceptance or Probe Loan setting OLI ProductItem Reserved__c to FALSE');
                                        pc.Reserved__c = false;
                                    }
                                }
                            }
                        }
						
                        GH_Logger.finer('Setting fields from Opp to ProductItem (replaces PB Set opportunity field to product item -- which really sets PI from Opp fields');
                        // These are all formula fields referencing the Opp that OLI is on
                        GH_Logger.finer('Setting Product Item Account Name: ' + newRecMap.get(line.OpportunityId).Account_Name__c);
                        GH_Logger.finer('Setting Product Item Close_Date__c: ' + newRecMap.get(line.OpportunityId).CloseDate);
                        GH_Logger.finer('Setting Product Item Opportunity_Name__c: ' + newRecMap.get(line.OpportunityId).Name);
                        GH_Logger.finer('Setting Product Item Ship_Date__c: ' + newRecMap.get(line.OpportunityId).Ship_Date__c);
                        GH_Logger.finer('Setting Product Item Stage__c: ' + newRecMap.get(line.OpportunityId).StageName);
                        pc.Account_Name__c = newRecMap.get(line.OpportunityId).Account_Name__c;
                        pc.Close_Date__c = newRecMap.get(line.OpportunityId).CloseDate;
                        pc.Opportunity_Name__c = newRecMap.get(line.OpportunityId).Name;
                        pc.Sales_Opportunity__c = line.OpportunityId;
                        pc.Ship_Date__c = newRecMap.get(line.OpportunityId).Ship_Date__c;
                        pc.Stage__c = newRecMap.get(line.OpportunityId).StageName;

                        if (pitemsToUpdateMap.containsKey(pc.Id)) {
                            System.debug('P_OpportunityTrigger is adding the same ProductItem__c to be updated again: ');
                        }
                       
                        pitemsToUpdateMap.put(pc.Id, pc);
                    } else {
                        system.debug('Unable to find ProductItem__c for this OLI: ' + line.Id);
                    }
                }               

                System.debug('This many OLI to update:' + oliToUpdateMap.size());
                if (!oliToUpdateMap.isEmpty()) {
                    system.debug('OLI UPDATE FROM INSIDE OPP TRIGGER >> ' + oliToUpdateMap);
                    DatabaseService.updateList(oliToUpdateMap.values());
                }

                // Updates asset pages for all opp products
                System.debug('This many ProductItem__c to update:' + pitemsToUpdateMap.size());
                if (!pitemsToUpdateMap.isEmpty()) {
                    system.debug('PRODUCT ITEM UPDATE FROM INSIDE OPP TRIGGER >> ' + pitemsToUpdateMap);
                    DatabaseService.updateList(pitemsToUpdateMap.values());
                }
                System.debug('Inserting this many Move Locations in P_OpportunityTrigger2: ' + MoveLocationsToInsert.size());
                if (!MoveLocationsToInsert.isEmpty()) {
                    DatabaseService.insertList(MoveLocationsToInsert);
                }             

                Validator_Class.setAlreadyDone3();
                system.debug('end of updateOpportunity ');
            }
        }

        system.debug('end of P_OpportunityTrigger');
        System.debug('CC doTriggerWork end: ' + Limits.getQueries());    
    }

    private Boolean canResetReserved(Id prodItemId, Id oliID) {
        Boolean okToReset = true;
        system.debug('THIS IS THE VERBAL AND LOAN OLI LIST >> ' + prodItemIDtoVerbalOrProbeLoanOLI);
        if (prodItemIDtoVerbalOrProbeLoanOLI.containsKey(prodItemId)) {

            // look at all the OLI Ids that this is related to and see if there is one that is NOT the current line
            for (Id theOLI : prodItemIDtoVerbalOrProbeLoanOLI.get(prodItemId)) {
                if (theOLI != oliID) {
                    System.debug('Found another OLI for this ProductItem__c: ' + prodItemId);
                    okToReset = false;
                    
                    break;
                }
            }
        }
    system.debug('THIS IS THE OK TO RESET >> ' + OkToReset);
        return okToReset;
    }

    // This prevents anyone from deleted an opp that is in the stage of Closed Won.
    private void checkDeletes(Map<Id, Opportunity> oldRecs) {
        for (Opportunity op : oldRecs.values()) {
            if ((op.StageName == 'Closed Won')) {
                op.addError('You can not delete a Closed Won Opportunity !');
            } else if (op.Intacct_Shipper_Sync_Status__c != '' && op.Intacct_Shipper_Sync_Status__c != null) {
                if (!op.Allow_Delete__c) {
                    op.addError('You can not delete an Opportunity that has been synced with Intacct');
                } else {
                    Synced_Record_Delete_Log__c dl = new Synced_Record_Delete_Log__c(
                        Name=op.Name,
                        Record_Id__c=op.Id,
                        Record_Type__c='Opportunity'
                    );
                    insert dl;
                }
            }
        }
    }

    private void stampOppFields(List<Opportunity> newRecs, Map<Id, Opportunity> oldRecs) {
        // see if we need to stamp the 'Verified' fields
        for (Opportunity opp : newRecs) {

            if (opp.Verified_Asset_and_Serial_Numbers_Match__c
                    && (Trigger.isInsert || !oldRecs.get(opp.Id).Verified_Asset_and_Serial_Numbers_Match__c)) {

                opp.Timestamp_Verified_Asset_Serial_Match__c = DateTime.now();
                opp.Asset_Serial_Match_Verified_By__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
            }
        }
    }

    private void setOppFieldsOnInsert(List<Opportunity> newRecs, Map<Id, Account> acctMap) {

        for (Opportunity opp : newRecs) {

            if (opp.StageName == 'Repair Evaluation' && opp.White_Glove_Service__c == true) {
                opp.Name = '***WGS*** ' + opp.Name;
            }

            if (opp.Shipping_TO_Location__c != null && opp.RecordTypeId == materialTransferOpprt.Id) {

                Id AccountIDToUse = null;

                // The following code is for material transfer opps
                switch on opp.Shipping_TO_Location__c {
                    when 'Fishers, IN' {
                        AccountIDToUse = proboFishers;
                    }
                    when 'Tampa, FL' {
                        AccountIDToUse = medCorp;
                    }
                    when 'Tulsa, OK' {
                        AccountIDToUse = proboTulsa;
                    }
                }

                // This changes the account name in the material transfer opp based on the shipping to location
                opp.AccountId = AccountIDToUse;
            }
            if(opp.Bill_To_Account__c != null){
                Account billingAcct = acctMap.get(opp.Bill_To_Account__c);
                opp.BillingStreet__c = billingAcct.BillingStreet;
                opp.BillingCity__c = billingAcct.BillingCity;
                opp.BillingState__c = billingAcct.BillingState;
                opp.BillingPostalCode__c = billingAcct.BillingPostalCode;
                opp.BillingCountry__c = billingAcct.BillingCountry;
            }
            setOppFieldsFromAccount(opp, acctMap.get(opp.AccountId));
        }
    }

    private void setOppFieldsFromAccount(Opportunity opp, Account theAcct) {
        if (theAcct != null) {
            if(theAcct.ISO_Asset_Mgmt_Co__c != null){
                if (opp.BillingStreet__c == null && opp.BillingCity__c == null && opp.BillingState__c == null && opp.BillingPostalCode__c == null && opp.BillingCountry__c == null) {
                    opp.BillingStreet__c = theAcct.ISO_Asset_Mgmt_Co__r.BillingStreet;
                    opp.BillingCity__c = theAcct.ISO_Asset_Mgmt_Co__r.BillingCity;
                    opp.BillingState__c = theAcct.ISO_Asset_Mgmt_Co__r.BillingState;
                    opp.BillingPostalCode__c = theAcct.ISO_Asset_Mgmt_Co__r.BillingPostalCode;
                    opp.BillingCountry__c = theAcct.ISO_Asset_Mgmt_Co__r.BillingCountry;
                }
                if (opp.Bill_To_Account__c == null) {
                    opp.Bill_To_Account__c = theAcct.ISO_Asset_Mgmt_Co__c;
                }
            }
            else{
                if (opp.BillingStreet__c == null && opp.BillingCity__c == null && opp.BillingState__c == null && opp.BillingPostalCode__c == null && opp.BillingCountry__c == null) {
                    opp.BillingStreet__c = theAcct.BillingStreet;
                    opp.BillingCity__c = theAcct.BillingCity;
                    opp.BillingState__c = theAcct.BillingState;
                    opp.BillingPostalCode__c = theAcct.BillingPostalCode;
                    opp.BillingCountry__c = theAcct.BillingCountry;
                }
                if (opp.Bill_To_Account__c == null) {
                    opp.Bill_To_Account__c = theAcct.Id;
                }
            }
            
            if (opp.ShippingStreet__c == null && opp.ShippingCity__c == null && opp.ShippingState__c == null && opp.ShippingPostalCode__c == null && opp.ShippingCountry__c == null) {
                opp.ShippingStreet__c = theAcct.ShippingStreet;
                opp.ShippingCity__c = theAcct.ShippingCity;
                opp.ShippingState__c = theAcct.ShippingState;
                opp.ShippingPostalCode__c = theAcct.ShippingPostalCode;
                opp.ShippingCountry__c = theAcct.ShippingCountry;
            }
            if (opp.Ship_To_Account__c == null) {
                opp.Ship_To_Account__c = theAcct.Name;
            }
                
            
            if (opp.E_mail_for_Shipping_Confirmation__c == null) {
                opp.E_mail_for_Shipping_Confirmation__c = theAcct.Shipping_Confirmation_E_mail__c;
            }

            if (theAcct.Payment_Terms__c != null && opp.RecordTypeId == salesOppRecTypeId
                    && theAcct.Payment_Terms__c.containsIgnoreCase('NET')) {

                opp.Payment_Method__c = 'Terms';
            }
            
            //Sets "Ship with Probo Materials" to match the Account            
            opp.Ship_With_Probo_Materials__c = theAcct.Ship_With_Probo_Materials__c;
            
            
            opp.Field_Service_Engineer__c = theAcct.Field_Service_Engineer__c;
            if(opp.Field_Service_Engineer__c != null){
                
                List<String> engineer = opp.Field_Service_Engineer__c.split(' ');String secondPart ='';if(engineer.size () >= 2){secondPart = engineer[1];
                }   
                
                opp.FSE_Email__c = opp.Field_Service_Engineer__c.substring(0,1) + secondPart + '@probomedical.com';
            }
            

        }

    }

    public static void getRecordTypes() {
        for (RecordType r : ProboCommonUtils.getRecordTypes('Opportunity')) {
            switch on r.DeveloperName {
                when 'Purchasing_Opportunity' {
                    PurchasingOpprt = r;
                }
                when 'Big_Iron_Purchasing_Opportunity'{
                    BigIronPurchasingOpprt = r;
                }
                when 'Material_Transfer' {
                    materialTransferOpprt = r;
                }
                when 'Returns' {
                    ReturnsOpprt = r;
                }
               /* when 'Probe_Repair_Opportunity'{
                    RepairOpprt = r;
                }*/
                when 'Depot_Repair_Opportunity'{
                    DepotOpprt = r;
                }
                when 'Sales_Opportunity' {
                    salesOppRecTypeId = r.IsActive ? r.Id : null;
                }
                when 'Probe_Sales_Opportunity'{
                    probeSalesRT = r.Id;
                }
                when 'Equipment_Storage_Rental_Opportunity'{
                    EquipmentStorageOpprt = r;
                }
            }
        }

        for (RecordType r : ProboCommonUtils.getRecordTypes('RMA__c')) {
            switch on r.Name {
                when 'Customer Repair Evaluation' {
                    EVALrt = r;
                }
                when 'Depot Repair' {
                    DEPOTrt = r;
                }
                when 'Loaner Return' {
                    LOANrt = r;
                }
                when 'Rental Return' {
                    RentRetrt = r;
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
    }

    private Map<Id, Account> getAccounts(Set<Id> acctIds) {
        Map<Id, Account> retMap = new Map<Id, Account>([
                Select Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, Field_Service_Engineer__c, Ship_With_Probo_Materials__c,
                        BillingCountry, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,Shipping_Confirmation_E_mail__c,
                        Payment_Terms__c, ISO_Asset_Mgmt_Co__r.BillingStreet, ISO_Asset_Mgmt_Co__r.BillingCity, ISO_Asset_Mgmt_Co__r.BillingState,
                        ISO_Asset_Mgmt_Co__r.BillingPostalCode, ISO_Asset_Mgmt_Co__r.BillingCountry, ISO_Asset_Mgmt_Co__c 
                        
                from Account
                where Id in :acctIds
        ]);

        return retMap;
    }
        // Maurice Chesire 10/7/2019: Updated access modifier to static and added more locations
    public static void getLocationAccountIds() {
        // TODO: - create an Account picklist for Internal_Location__c

        for (Account bu : [Select Id, Name from Account where Name IN('Probo Medical - Tulsa', 'MedCorp LLC', 'Probo Medical - Indy', 'Probo Medical - Tampa', 'Probo Medical', 'Trisonics')]) {
            switch on bu.Name {
                when 'Probo Medical - Indy' {
                    proboFishers = bu.Id;
                }
                when 'Probo Medical - Tulsa' {
                    proboTulsa = bu.Id;
                }
                when 'MedCorp LLC' {
                    medCorp = bu.Id;
                }
                when 'Probo Medical - Tampa' {
                    proboTampa = bu.Id;
                }
                when 'Probo Medical' {
                    probo = bu.Id;
                }
                when 'Trisonics' {
                    trisonics = bu.Id;
                }
            }
        }
    }

    private RMA__c createRepairRMA(Opportunity opp) {

        id newRT = EVALrt.Id;
        if(opp.RecordTypeId == DepotOpprt.id){
            newRT = DEPOTrt.id;
        }
        RMA__c newRepairRMA = new RMA__c(RecordTypeId = newRT, Opportunity__c = opp.Id);

        if (opp.Customer_Probe__c == true) {
            newRepairRMA.Customer_s_Probe__c = true;
        }
        if (opp.White_Glove_Service__c == true) {
            newRepairRMA.White_Glove_Service__c = true;
        }
        if (opp.Opportunity_Notes__c != null) {
            newRepairRMA.Quality_Issue_Notes__c = opp.Opportunity_Notes__c;
        }
        if (opp.Repair_Evaluation_Serial_Number__c != null) {
            newRepairRMA.RMA_Item_Serial_Number__c = opp.Repair_Evaluation_Serial_Number__c;
        }

        return newRepairRMA;

    }

    private void createOCRs(List<Opportunity> newRecs) {

        List<OpportunityContactRole> ocrToInsert = new List<OpportunityContactRole>();

        for (Opportunity opp : newRecs) {
            // Using the new opp or quick opp through the visualforce pages, the only way to link it to the correct
            // contact is through the following code. The apex class behind the visualforce page saves the contact ID
            // to a field on the opp page. This portion of the code actually creates the contact role linked to the opp.
            if (opp.Primary_Contact_ID__c != null
                    && !opp.Primary_Contact_ID__c.startsWith('001')) {
                OpportunityContactRole newOCR = new OpportunityContactRole();
                newOCR.ContactId = opp.Primary_Contact_ID__c;
                newOCR.OpportunityId = opp.Id;
                newOCR.IsPrimary = true;
                ocrToInsert.add(newOCR);
            }
        }

        System.debug('Inserting this many OCR from P_OpportunityTrigger after insert: ' + ocrToInsert.size());
        if (!ocrToInsert.isEmpty()) {
            // JMAY 2019-04-22 - inserting what we can, ignore the rest - not logging since we don't track
            try {
                Database.insert(ocrToInsert, false);
            } catch (Exception e) {
            }
        }

    }
}