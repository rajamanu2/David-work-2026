public class WorkOrderHelper {

    public String errorText { get; set; }
    public String assetID { get; set; }

    private ProductItem__c theProductItem;
    private String currentID;
    private String pitemID;
    private String oppid;
    private String repairRecTypeId;
    private String repairs;
    private Set<String> repairlist = new Set<String>();
    private String currUserFullName;
    private String name;
    private String checkInType;
    private Boolean isPurchasingApproved;
    private Boolean addedtoworkorder;
    private Opportunity opp;
    private List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
    private List<Work_Order__c> allWorkOrders = new List<Work_Order__c>();
    private List<Work_Order__c> PreviousWorkOrders = new List<Work_Order__c>();
    private PageReference currPageRef = new PageReference('/');
    private RecordType woTestingRecType;

    public WorkOrderHelper(ApexPages.StandardController controller) {

        currentID = controller.getRecord().Id;
        GH_Logger.debug('CURRENT ID: ' + currentID);
        currPageRef = ApexPages.currentPage();
        if (ApexPages.currentPage().getParameters().get('CF00N0B0000066XXF_lkid') != null) {
            pitemID = ApexPages.currentPage().getParameters().get('CF00N0B0000066XXF_lkid');
        }
        if (ApexPages.currentPage().getParameters().get('CF00N0B0000066XXM_lkid') != null) {
            oppid = ApexPages.currentPage().getParameters().get('CF00N0B0000066XXM_lkid');
        }
        if (oppid == null && pitemID == null) {
            oppid = currentID;
        }

        assetID = Url.getSalesforceBaseUrl().toExternalForm() + '/' + pitemID;

        if (oppid != null) {
            opp = [SELECT Id, Estimated_Ready_Date__c, Quick_Repair_Selection__c, Name FROM Opportunity WHERE Id = :oppid];
            olis = [SELECT Id, ProductItem__c, OpportunityId, Added_to_Work_Order__c, Check_In_Type__c
                        FROM OpportunityLineItem
                        WHERE OpportunityId = :oppid
                        AND Check_In_Type__c != 'Generic'];
        }

        currUserFullName = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
        repairRecTypeId = ApexPages.currentPage().getParameters().get('RecordType');

        for (RecordType r : ProboCommonUtils.getRecordTypes('Work_Order__c')) {

            if (r.DeveloperName == 'Testing_Work_Order') {
                woTestingRecType = r;
            } else if (repairRecTypeId == null && r.DeveloperName == 'Repair_Work_Order') {
                repairRecTypeId = r.Id;
            }
        }

        GH_Logger.debug('Repair Record Type Id: ' + repairRecTypeId);
        GH_Logger.debug('pitemId: ' + pitemID);

        if (pitemID != null) {
            theProductItem = [
                    SELECT Id, Name, Product_Name__c, Possible_Cosmetic_Repairs__c, Possible_Functional_Repairs__c, Added_to_Work_Order__c,
                            Purchasing_Approved__c, Check_In_Type__c
                    FROM ProductItem__c
                    WHERE Id = :pitemID
            ];

            addedtoworkorder = theProductItem.Added_to_Work_Order__c;
            isPurchasingApproved = theProductItem.Purchasing_Approved__c;
            checkInType = theProductItem.Check_In_Type__c;

            for (Product_Repair__c pr : [SELECT Id, Repair_Activity__c, Repair_date__c, Product_Item__c, No_longer_needed__c
                                        FROM Product_Repair__c
                                        WHERE Product_Item__c = :theProductItem.Id
                                        AND Repair_date__c = NULL
                                        AND No_longer_needed__c = FALSE
                                        ORDER BY Repair_Activity__c ASC]) {
                repairlist.add(pr.Repair_Activity__c);
            }

            GH_Logger.debug('THE REPAIR LIST' + repairlist);
            repairs = '';
            for (String r : repairlist) {

                repairs += r + '; ';
            }

            name = theProductItem.Name;
        }
    }


    public PageReference newWorkOrder() {


        String urlname = '/a09/e?CF00N0B0000066XXF=' + name + '&CF00N0B0000066XXF_lkid=' + pitemID + '&retURL=' + pitemID + '&RecordType=' + repairRecTypeId;
        System.debug('THIS IS THE URL NAME >>> ' + urlname);
        PageReference pr1 = new PageReference(urlname);
        Boolean ErrorCondition = false;
        if (addedtoworkorder == true) {
            errorText = 'You cannot create a work order because there is already a work order on this asset.';
            ErrorCondition = true;
        }
		system.debug('THIS IS THE ERROR INFO >> ' + checkInType + ' , ' + isPurchasingApproved + ' , ' + repairRecTypeId + ' , ' + woTestingRecType.id);	
        if (checkInType != 'Warranty Repair' && checkInType != 'Customer Repair' && isPurchasingApproved == false && repairRecTypeId != woTestingRecType.Id) {

            errorText = 'You cannot create a work order because the asset is not purchasing approved.';
            ErrorCondition = true;

        }

        if (pitemID == null) {
            errorText = 'You cannot create a work order from this page. Please go to the asset page to create a work order.';
            ErrorCondition = true;
        }

        /* if(addedtoworkorder == false){
             p.added_to_work_order__c = true;
             update p;
         } */


        pr1.getParameters().put('nooverride', '1');


        pr1.getParameters().put('00N0B0000066XXP', repairs);
        pr1.getParameters().put('00N0B0000066XXO', currUserFullName);


        pr1.setRedirect(false);

        if (ErrorCondition == false) {
            return pr1;
        }

        if (ErrorCondition == true) {

            return new PageReference('/apex/ErrorMessage');
        }
        return null;
    }

    public PageReference newAllWorkOrders() {

        Set<Id> pItemIDsNeeded = new Set<Id>();
        Set<Id> pItemIDsNeededForWOs = new Set<Id>();

        for (OpportunityLineItem o : olis) {
            if (o.ProductItem__c != null) {

                if (o.Added_to_Work_Order__c == false) {
                    pItemIDsNeeded.add(o.ProductItem__c);
                } else {
                    pItemIDsNeededForWOs.add(o.ProductItem__c);
                }
            }
        }

        Map<Id, ProductItem__c> pItemIDToPItem = new Map<Id, ProductItem__c>();

        if (!pItemIDsNeeded.isEmpty()) {

            GH_Logger.debug('Get details of the related ProductItem__c records');
            pItemIDToPItem = new Map<Id, ProductItem__c>([
                    SELECT Id, Review_Status__c, Check_In_Type__c, Purchasing_Approved__c
                    FROM ProductItem__c
                    WHERE Id = :pItemIDsNeeded
            ]);
        }

        Map<Id, List<Work_Order__c>> pItemIDToWOList = new Map<Id, List<Work_Order__c>>();

        if (!pItemIDsNeededForWOs.isEmpty()) {
            GH_Logger.debug('Get details of the WOs related to the ProductItem__c records');
            for (Work_Order__c thisWO : [
                    SELECT Id, Asset__c, Status__c, Opportunity__c
                    FROM Work_Order__c
                    WHERE Asset__c = :pItemIDsNeededForWOs
                    AND Status__c != 'Completed'
                    AND Status__c != 'Work order cancelled'
                    AND RecordTypeId = :repairRecTypeId
                    AND Opportunity__c = NULL
            ]) {

                if (!pItemIDToWOList.containsKey(thisWO.Asset__c)) {
                    pItemIDToWOList.put(thisWO.Asset__c, new List<Work_Order__c>());
                }
                pItemIDToWOList.get(thisWO.Asset__c).add(thisWO);
            }
        }
		system.debug('THIS IS THE OLIS >>> ' + olis);
        for (OpportunityLineItem o : olis) {
            if (o.ProductItem__c != null) {
                if (o.Added_to_Work_Order__c == false) {

                    ProductItem__c p = pItemIDToPItem.get(o.ProductItem__c);

                    if (p.Review_Status__c != 'Finished Goods'
                            && (p.Check_In_Type__c == 'Warranty Repair' || p.Check_In_Type__c == 'Customer Repair'
                            || p.Purchasing_Approved__c == true)) {

                        Work_Order__c wo = new Work_Order__c();
                        wo.RecordTypeId = repairRecTypeId;
                        wo.Asset__c = o.ProductItem__c;
                        wo.Opportunity__c = o.OpportunityId;
                        wo.Estimated_Ready_Date__c = opp.Estimated_Ready_Date__c;
                        wo.Person_Requesting_WO__c = currUserFullName;
                        if (wo.Estimated_Ready_Date__c == System.today()) {
                            wo.Quick_Repair_Selection__c = 'Only Refurb';
                        }
                        if (wo.Estimated_Ready_Date__c == (System.today() + 1)) {
                            wo.Quick_Repair_Selection__c = 'Only Cosmetic';
                        }
                        if (opp.Quick_Repair_Selection__c != null) {
                            wo.Quick_Repair_Selection__c = opp.Quick_Repair_Selection__c;
                        }

                        allWorkOrders.add(wo);
                    }
                } else {

                    if (pItemIDToWOList.containsKey(o.ProductItem__c)){
                        for (Work_Order__c wo : pItemIDToWOList.get(o.ProductItem__c)) {
                            wo.Opportunity__c = opp.Id;
                            wo.Quick_Repair_Selection__c = opp.Quick_Repair_Selection__c;
                            wo.Estimated_Ready_Date__c = opp.Estimated_Ready_Date__c;
                            allWorkOrders.add(wo);
                        }
                    }
                }
            }
        }

        // changed to upsert so the new and existing can be processed in 1 DML
        upsert allWorkOrders;

        String urlname = '/' + oppid;

        PageReference pr1 = new PageReference(urlname);

        pr1.setRedirect(false);
        return pr1;
    }
}