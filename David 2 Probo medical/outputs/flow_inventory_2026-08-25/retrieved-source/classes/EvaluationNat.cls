global class EvaluationNat {
    List<string> approvalOptions = new List<string>{'Full Repairs (Recommended and Required)','Required Repairs Only','Exchange Probe - No Repairs','Declined All Options'};
    public List<String> required { get; set; }
    public List<String> recommended { get; set; }
    public List<String> endoscopyRequired { get; set; }
    public List<String> endoscopyResults { get; set; }
    public List<String> endoscopeEvaluationNotes { get; set; }
    public List<String> endoscopeInspectionTable { get; set; }
    public Boolean includeRecommended { get; set; }
    public List<String> CompletedRepairs { get; set; }
    // public static String evalid;
    public List<String> TestRecords { get; set; }
    public List<String> CRecords { get; set; }
    public List<String> FRecords { get; set; }
    public List<String> testItemRecords { get; set; }
    public String EstimatedTime { get; set; }
    public String RepairComments { get; set; }
    public String RepairCommentsForm { get; set; }
    public String fullRepPrice { get; set; }
    public String reqRepPrice { get; set; }
    public String excRepPrice { get; set; }
    public String LoanerPrice { get; set; }
    public String s_PONumber { get; set; }
    public String ApprovedPrice { get; set; }
    public String ApprovedBy { get; set; }
    public Evaluation_Natalie__c eval { get; set; }
    public String RMAName { get; set; }
    public String QuoteDateSent { get; set; }
    public String ExpirationDate { get; set; }
    public String AccountName { get; set; }
    public String OppNo { get; set; }
    public String Address1 { get; set; }
    public String Address2 { get; set; }
    public String CustomerPhone { get; set; }
    public String CustomerEmail { get; set; }
    public String CustomerEmailEVAL { get; set; }
    public String ProbeProductName {get; set;}
    public String ProbeModel { get; set; }
    public String ProbeSerial { get; set; }
    public String LoanerProductName { get; set; }
    public String LoanerProbeModel { get; set; }
    public String LoanerBrand {get; set; }
    public String LoanerSerial { get; set; }
    public String TechnicianComments { get; set; }
    public List<String> oddImagelist { get; set; }
    public List<String> evenImagelist { get; set; }
    public List<String> firstcalllist { get; set; }
    public String RMAOwner { get; set; }
    public String LogoID { get; set; }
    public String QRCode { get; set; }
    public String LoanerText { get; set; }
    public String LoanerHeader { get; set; }
    public Boolean Logo { get; set; }
    public Boolean CustomerInfo { get; set; }
    public String rodLenses { get; set; }
    public String repairLevel { get; set; }
    public String receivedWith { get; set; }
    public String evaluationSummary { get; set; }
    public Attachment ApprovedForm { get; set; }
    public String Approved { get; set; }
    public List<String> ApprovedRepairs { get; set; }
    public List<String> DeclinedRepairs { get; set; }
    public String DriveFolder { get; set; }
    public Boolean FCVisible { get; set; }
    public Boolean FCNotVisible { get; set; }
    public Boolean Repairable { get; set; }
    public Boolean NotRepairable { get; set; }
    public Boolean NoProblemsFound { get; set; }
    public String boxfull { get; set; }
    public String boxreq { get; set; }
    public String boxexc { get; set; }
    public Boolean notapproved { get; set; }
    public Boolean approvedboolean { get; set; }
    public Boolean notDepot { get; set; }
    public Boolean standardEndoscopy { get; set; }
    public Boolean endoscopyOther { get; set; }
    public Boolean standardEval { get; set; }
    public Date shipdate { get; set; }
    public Date approvedDate { get; set; }
    public Date itemReceivedDate { get; set; }
    public String alreadyapprovedPO { get; set; }
    public String alreadyapprovedby { get; set; }
    public String alreadyapprovedprice { get; set; }
    public Boolean declined { get; set; }
    public Boolean notdeclined { get; set; }
    public Boolean includeleakage { get; set; }
    public Boolean includefunctional { get; set; }
    public Boolean nofunctional { get; set; }
    public String Lens { get; set; }
    public String Whole { get; set; }
    public String SN { get; set; }
    public String Leakage { get; set; }
    public String Phantom { get; set; }
    public String Airscan { get; set; }
    public String FirstCall { get; set; }
    public String RepairsCompleted { get; set; }
    public Boolean PostRepair { get; set; }
    public Boolean NotPostRepair { get; set; }
    public List<String> ProboAddress { get; set; }
    public List<String> ProboAddressWebsite { get; set; }
    public String Brand { get; set; }
    public Boolean FieldServiceEngineer { get; set; }
    public string OpportunityOwner { get; set; }
    public string FSEEmail { get; set; }
    public string FSEPhone { get; set; }
    public string FSEName { get; set; }
    public string QualityIssue { get; set; }
    public list<string> CustomerAddress { get; set; }
    public boolean LoanerVisible { get; set; }
    public boolean ReplacementVisible { get; set; }
    public string LoanerRMA { get; set; }
    public List<evaluationWrapper> cosmeticEvaluationList { get; set; }
    public List<evaluationWrapper> functionalEvaluationList { get; set; }
    public List<otherEndoscopyWrapper> otherEndoscopyList { get; set; }
    
    private List<Product_Test_Line_Item__c> getTestItems(Id assetId) {
        ProductTest__c recentProductTest = [SELECT Id, Product_Item__c FROM ProductTest__c WHERE Product_Item__c = :assetId ORDER BY CreatedDate DESC LIMIT 1];
        system.debug('THIS IS THE TEST FOUND >> ' + recentProductTest);
        List<Product_Test_Line_Item__c> productTestItems = [SELECT Id, Quantity__c, Item_Description__c, ProductTest__c, Complaint__c, Repair_Technician__c, Repairs_Needed__c, Repair_Price__c
                                                           FROM Product_Test_Line_Item__c WHERE ProductTest__c = :recentProductTest.Id ORDER BY CreatedDate ASC];
        
        return productTestItems;
    }


    public EvaluationNat(ApexPages.StandardController controller) {
        if (!Test.isRunningTest()){
            controller.addFields(new list<String>{'Field_Service_Engineer_Template__c', 'Loaner_RMA_Name__c', 'Depot_Recommended_Repairs__c', 'Depot_Required_Repairs__c', 'Product_Family__c', 'Product_Item_ID__c', 'Endoscopy_Evaluation_Results__c', 'Endoscopy_Repairs_With_Notes__c', 'No_Problems_Found__c', 'Endoscopy_Required_Repairs__c', 'Endoscopy_Recommended_Repairs__c'});
        }  
        
        eval = (Evaluation_Natalie__c)controller.getRecord();
        system.debug('This is the product family >> ' + eval.Product_Family__c);
        
        //eval = [select id, Field_Service_Engineer_Template__c from Evaluation_Natalie__c where id=:eval.id];
        GH_Logger.debug('Inside the EvaluationNat ctor with this record: ' + eval);

        RMA__c associate;

        if (eval.Associated_RMA__c != null) {
            associate = [
                    SELECT Id, Name, Estimated_Ship_Date__c, Current_Estimated_Ship_Date__c, Check_In_Type__c, Owner.Email, Estimated_Time_for_Completion__c,
                				Opportunity_No__c, Opportunity_Owner__c, FSE_Email__c, FSE_Phone__c, Field_Service_Engineer__c, Quality_Issue_Notes__c, Loaner_Probe_Model__c,
                				Date_Repair_Approved__c, Date_RMA_Item_Received__c, Rod_Lenses_to_Replace__c, Repair_Level__c, Received_With__c, Endoscope_Evaluation_Notes__c
                    FROM RMA__c
                    WHERE Id = :eval.Associated_RMA__c
            ];
            System.debug('CC....associated RMA: ' + associate);

            if (associate.Estimated_Ship_Date__c != null) {
                shipdate = associate.Estimated_Ship_Date__c;
            }

            if (associate.Current_Estimated_Ship_Date__c != null) {
                shipdate = associate.Current_Estimated_Ship_Date__c;
            }
            if(associate.Estimated_Time_for_Completion__c != null){
                EstimatedTime = associate.Estimated_Time_for_Completion__c;
            }
            if(associate.Loaner_Probe_Model__c != null){
                LoanerProductName = associate.Loaner_Probe_Model__c;
            }
            if(associate.Date_Repair_Approved__c != null){
                approvedDate = associate.Date_Repair_Approved__c;
            }
            
            if(associate.Date_RMA_Item_Received__c != null){
                itemReceivedDate = associate.Date_RMA_Item_Received__c;
            }
            
            RMAName = associate.Name;
			OppNo = associate.Opportunity_No__c;
            OpportunityOwner = associate.Opportunity_owner__c;
            FSEEmail = associate.FSE_Email__c;
            FSEPhone = associate.FSE_Phone__c;
            FSEName = associate.Field_Service_Engineer__c;
            QualityIssue = associate.Quality_Issue_Notes__c;
            if(associate.Rod_Lenses_to_Replace__c != null){
                rodLenses = String.valueOf(associate.Rod_Lenses_to_Replace__c);
            }
            if(associate.Repair_Level__c != null){
                repairLevel = associate.Repair_Level__c;
            }
            if(associate.Received_With__c != null){
                receivedWith = associate.Received_With__c;
            }
            if(associate.Endoscope_Evaluation_Notes__c != null){
                endoscopeEvaluationNotes = associate.Endoscope_Evaluation_Notes__c.split(';');
            }
             
        }
		// address used on FSE forms
        ProboAddress = new List<String>{'Probo Medical','5735 Benjamin Center Dr','Tampa, FL 33634','P: 877-876-6427','www.probomedical.com'};
        //address used on form seen by customer for standard evals
        ProboAddressWebsite = new List<String>{'9715 Kincaid Drive Suite 1000', 'Fishers, IN 46037'};
         
        boxfull = 'pricingdiv';
        boxreq = 'pricingdiv';
        boxexc = 'pricingdiv';
        notapproved = true;
        approvedboolean = false;
        notDepot = true;
        standardEndoscopy = false;
        endoscopyOther = false;
        standardEval = true;
        declined = false;
        notdeclined = false;
        includefunctional = false;
        includeleakage = false;
        nofunctional = false;
        PostRepair = false;
        NotPostRepair = true;
        // for endoscopy - normally only has required until manually changed to include recommended
        includeRecommended = false;
       
        try{
            FieldServiceEngineer = eval.Field_Service_Engineer_Template__c;
        }
        catch(Exception e)
        {system.debug('THIS IS THE EXCEPTION >>> ' + e);}
        system.debug('THIS IS THE FSE >>> ' + FieldServiceEngineer);
        
       

        if (eval.Approved__c != null) {
            boxfull = 'pricingdivapprove';
            boxreq = 'pricingdivapprove';
            boxexc = 'pricingdivapprove';
            notapproved = false;
            approvedboolean = true;
            notdeclined = true;
            alreadyapprovedby = eval.Approved_By__c;
            alreadyapprovedPO = eval.PO_Number__c;
            alreadyapprovedprice = String.valueOf(eval.Approved_Price__c);
            if (eval.Approved__c.contains('Exchange')) {
                boxexc = 'pricingdivselect';
            }
            if (eval.Approved__c.contains('Full')) {
                boxfull = 'pricingdivselect';
            }
            if (eval.Approved__c.contains('Only')) {
                boxreq = 'pricingdivselect';
            }
            if (eval.Approved__c.contains('Declined')) {
                declined = true;
                notdeclined = false;
            }
        }

        DriveFolder = eval.Folder_ID__c;
        GH_Logger.debug('Eval RMA_Owner is: ' + eval.RMA_Owner__c);
        RMAOwner = eval.RMA_Owner__c;
        system.debug('THIS IS THE REPAIR COMMENTS >> ' + eval.Repair_Comments__c);
        if(eval.Repair_Comments__c != null && (eval.Repair_Comments__c.containsIgnoreCase('not repairable') || eval.Repair_Comments__c.containsIgnoreCase('not repairable.'))){
            NotRepairable = true;
        }
        QuoteDateSent = String.valueOf(eval.Quote_Date_When_Sent__c);
        ExpirationDate = String.valueOf(eval.Expiration_Date_When_Sent__c);

        fullRepPrice = '$' + String.valueOf(eval.Full_Repair_Price__c);
        reqRepPrice = '$' + String.valueOf(eval.Required_Repairs_Price__c);
        excRepPrice = '$' + String.valueOf(eval.Exchange_Probe_Price__c);
        LoanerPrice = '$' + String.valueOf(eval.Loaner_Price__c);

        if (associate != null){
            if (eval.Full_Repair_Price__c == 0 && associate.Check_In_Type__c != 'Warranty Repair') {
                fullRepPrice = 'N/A';
            }
            if (eval.Required_Repairs_Price__c == 0 && associate.Check_In_Type__c != 'Warranty Repair') {
                reqRepPrice = 'N/A';
            }
            
        }

        if (eval.Exchange_Probe_Price__c == 0) {
            excRepPrice = 'N/A';
        }
        if (eval.Loaner_Price__c == 0) {
            LoanerPrice = 'N/A';
        }
        if (eval.Account_Name__c == 'Conquest Imaging') {
            CustomerInfo = true;
            AccountName = 'CUSTOMER NAME';
            Address1 = 'ADDRESS';
            Address2 = 'CITY, ST ZIP';
            CustomerPhone = 'PHONE';
            CustomerEmail = 'EMAIL';
            LogoID = '0BzmqJILtsGQ8V20weVpOWWw3a00';  // TODO:  This needs to be retrieved not hardcoded if possible
            LoanerText = 'Fees for diminishing of the loaner probe:';
            LoanerHeader = 'Diminished Loaner';
        }
        Logo = true;
        FCVisible = true;
        FCNotVisible = false;
        Repairable = true;
        NotRepairable = false;
        NoProblemsFound = false;
        LoanerVisible = false;
        ReplacementVisible = true;
        if (eval.Do_not_include_First_Call__c == true) {
            FCVisible = false;
            FCNotVisible = true;
        }
        if (eval.Probe_is_unrepairable__c == true) {
            Repairable = false;
            NotRepairable = true;
            fullRepPrice = 'N/A';
            reqRepPrice = 'N/A';
        }
        if(eval.No_Problems_Found__c == true){
            NoProblemsFound = true;
        }
        if (eval.Post_Repair_Evaluation__c == true) {
            PostRepair = true;
            NotPostRepair = false;
        }
        CustomerInfo = true;
        if (eval.Account_Name__c != 'Conquest Imaging') {
            AccountName = eval.Account_Name__c;
            Address1 = eval.Customer_Address_Line_1__c;
            Address2 = eval.Customer_Address_Line_2__c;
            CustomerPhone = eval.Customer_Phone__c;
            CustomerEmail = eval.Customer_Email__c;
            if (eval.Remove_Probo_Medical_Logo__c == true) {
                Logo = false;
                CustomerInfo = false;
            }
            LogoID = '1x60eSHJ4qbpB-JmfuPbNlc8KHf9brrjO'; //'12nG_G7MNO1shhjBV2FBehym1ND3e_Pxs'; // TODO:  This needs to be retrieved not hardcoded if possible
            LoanerText = 'Max fee for loaner damage:';
            LoanerHeader = 'Loaner Damage';
            QRCode = '1VHorI1DeYIbPgo4mqKWfkF0XSmKiuTvI';
        }
        if (eval.Account_Name__c == 'Northfield Medical') {
            LogoID = '1zZMtMFvGgyKA9iky-u7uTatBS8bK2smy';// TODO:  This needs to be retrieved not hardcoded if possible
        }
        CustomerAddress = new list<string>{Address1, Address2, CustomerPhone, CustomerEmail};
        CustomerEmailEVAL = eval.Customer_Email__c;
        ProbeProductName = eval.Probe_Model__c;
        //This code splits the Make from the Model name:
        if(String.IsNotEmpty(eval.Probe_Model__c)) {
            ProbeModel = eval.Probe_Model__c.substringafter(' ');
            Brand = eval.Probe_Model__c.substringbefore(' ');
        }
        List<Product_Test_Line_Item__c> testItems = new List<Product_Test_Line_Item__c>();
        testItemRecords = new List<String> ();
        otherEndoscopyList = new List<otherEndoscopyWrapper>();
       
        if((eval.Probe_Type__c != null && eval.Probe_Type__c.contains('Endoscopy')) || (eval.Product_Family__c != null && eval.Product_Family__c.contains('Endoscopy')) || (eval.Product_Family__c != null && eval.Product_Family__c == 'Instrument Tray')){
            system.debug('INSIDE ENDOSCOPY SECTION >>>');
            evaluationSummary = 'Evaluation Summary - Repairs';
            if(repairLevel != null){
                evaluationSummary += ' - ' + repairLevel;
            }
            notDepot = false;
            standardEndoscopy = true;
            ProboAddressWebsite.clear();
            ProboAddressWebsite.add('10320 West McNab Rd.');
            ProboAddressWebsite.add('Tamarac, FL 33321');
            system.debug('THIS IS THE ENDOSCOPY EVAL RESULTS >> ' + eval.Endoscopy_Evaluation_Results__c);
        if (eval.Endoscopy_Evaluation_Results__c != null) {
            String list4 = '';
            list4 = eval.Endoscopy_Evaluation_Results__c;
            
            List<String> endoscopylist = list4.split(';');
            Set<String> endoscopyset = new Set<String>();
            endoscopyResults = new List<String>();
            for (String r : endoscopylist) {
               	endoscopyset.add(r);
                
            }
			system.debug('THIS IS THE ENDOSCOPY SET >>> ' + endoscopyset);
            endoscopyResults.addAll(endoscopyset);

        }

            // setting up table for rigid and flexible endoscopes
            if(eval.Probe_Type__c != null && eval.Probe_Type__c.contains('Endoscopy')){
                Map<String, List<String>> inspectionMap = new Map<String, List<String>>();
				
                system.debug('ENDOSCOPE EVALUATION NOTES >> ' + endoscopeEvaluationNotes);
                if(endoscopeEvaluationNotes != null){
                    endoscopeEvaluationNotes.sort();
                    for(string s:endoscopeEvaluationNotes){
                        s = s.trim();
                        string inspectionArea = s.substringBefore(':');
                        string inspectionResult = s.substringAfter(':') + ';';
                        if(!inspectionMap.containsKey(inspectionArea)) {
                            inspectionMap.put(inspectionArea, new List<String>());
                        }
                        inspectionMap.get(inspectionArea).add(inspectionResult);
                    }
                }
                endoscopeInspectionTable = new List<String>();
                for (String key : inspectionMap.keySet()) {
                    String inspectionArea = key;
                    system.debug('THIS IS THE INSPECTION TABLE KEY >>> ' + key);
                    List<String> inspectionResults = inspectionMap.get(key);
                    system.debug('THIS IS THE INSPECTION RESULTS >>> ' + inspectionResults);
                    endoscopeInspectionTable.add(inspectionArea);
                    String inspectionProblems = '';
                    String inspectionAction = '';
                    for(String result : inspectionResults){
                        system.debug('THIS IS THE INDIVIDUAL INSPECTION RESULT >> ' + result);
                        if(result.contains('Repair')){
                            inspectionAction = 'Repair';
                        }
                        else if(result.contains('Replace')){
                            inspectionAction = 'Replace';
                        }
                        else{
                            inspectionProblems += result;
                        }
                    }
                    if(inspectionArea == 'Contamination' && !inspectionResults.contains('No Problem')){
                        	inspectionAction = 'Removal';
                    }
                    endoscopeInspectionTable.add(inspectionAction);
                    endoscopeInspectionTable.add(inspectionProblems);
                    endoscopeInspectionTable.add('________');
                }
                if(!NotRepairable && endoscopyResults != null){
                    if(endoscopyResults.contains('Adhesive Replacement')){
                    	endoscopeInspectionTable.add('Adhesive, Replace, Adhesive Damage, ________');                   
                    }
                    if(endoscopyResults.contains('Fluid Removal')){
                        endoscopeInspectionTable.add('Fluid, Removal, Fluid Damage, ________');                   
                    }
                }
                
                
            }
            // setting up table for "Other" endoscopy products
            if(eval.Product_Family__c != null && ((eval.Probe_Type__c != null && (!eval.Probe_Type__c.contains('Endoscopy')) && eval.Product_Family__c.contains('Endoscopy')) || eval.Product_Family__c == 'Instrument Tray')){
                system.debug('INSIDE ENDOSCOPY OTHER SECTION >>>');
                testItems = getTestItems(eval.Product_Item_ID__c);
                system.debug('THESE ARE THE TEST LINE ITEMS >> ' + testItems);
                endoscopyOther = true;
                standardEndoscopy = false;
                standardEval = false;
                notDepot = false;
                if(testItems.size() != 0){
                    
                    for(Product_Test_Line_Item__c lineItem: testItems){
                        system.debug('THIS IS INSIDE FOR LOOP FOR TEST LINE ITEMS >>> ' + lineItem);
                        otherEndoscopyList.add(new otherEndoscopyWrapper((lineItem.Quantity__c == null) ? ' ' : String.valueof(lineItem.Quantity__c), lineItem.Item_Description__c ?? ' ', lineItem.Repairs_Needed__c ?? ' ', '$' + ((lineItem.Repair_Price__c == null) ? ' ' : String.valueof(lineItem.Repair_Price__c))));
                        testItemRecords.add((lineItem.Quantity__c == null) ? ' ' : String.valueof(lineItem.Quantity__c));
                        testItemRecords.add(lineItem.Item_Description__c ?? ' ');
                        testItemRecords.add(lineItem.Repairs_Needed__c ?? ' ');
                        testItemRecords.add((lineItem.Repair_Price__c == null) ? ' ' : String.valueof(lineItem.Repair_Price__c));
                        
                       
                    }
                }
                
                system.debug('THIS IS THE FINAL TEST ITEM RECORD LIST >> ' + testItemRecords);
                
            }
         
        }
        system.debug('THIS IS THE ENDOSCOPY OTHER BOOLEAN >> ' + endoscopyOther + ' AND THE STANDARD EVAL >> ' + standardEval + ' AND NOT DEPOT >> ' + notDepot);
        ProbeSerial = eval.Probe_Serial_Number__c;
        LoanerSerial = eval.Loaner_Serial_Number__c;
        try{
            LoanerRMA = eval.Loaner_RMA_Name__c;
        }
        catch(Exception e)
        {}
        
        if(LoanerRMA != null){
            if(LoanerProductName != null){
                LoanerProbeModel = LoanerProductName.substringafter(' ');
            	LoanerBrand = LoanerProductName.substringbefore(' ');
            }
            LoanerVisible = true;
            ReplacementVisible = false;
        } 
        system.debug('THIS IS LOANER VISIBLE >>> ' + LoanerVisible); 
        TechnicianComments = eval.Technician_Comments__c;
        evenImagelist = new List<String>();
        oddImagelist = new List<String>();
        if (eval.Lens_ID__c != null) {
            //Lens = 'https://drive.google.com/uc?id=' + eval.Lens_ID__c;
            Lens = 'https://drive.usercontent.google.com/download?id=' + eval.Lens_ID__c;
            oddImagelist.add(Lens);
        }

        if (eval.Whole_ID__c != null) {
            //Whole = 'https://drive.google.com/uc?id=' + eval.Whole_ID__c;
            Whole = 'https://drive.usercontent.google.com/download?id=' + eval.Whole_ID__c;
            oddImagelist.add(Whole);
        }

        if (eval.SN_ID__c != null) {
            //SN = 'https://drive.google.com/uc?id=' + eval.SN_ID__c;
            SN = 'https://drive.usercontent.google.com/download?id=' + eval.SN_ID__c;
            oddImagelist.add(SN);
        }


        if (eval.Leakage_Current_ID__c != null) {
            //Leakage = 'https://drive.google.com/uc?id=' + eval.Leakage_Current_ID__c;
            Leakage = 'https://drive.usercontent.google.com/download?id=' +  eval.Leakage_Current_ID__c;
            evenImagelist.add(Leakage);
            includeleakage = true;
        }

        if (eval.Phantom_ID__c != null) {
            //Phantom = 'https://drive.google.com/uc?id=' + eval.Phantom_ID__c;
            Phantom = 'https://drive.usercontent.google.com/download?id=' +  eval.Phantom_ID__c;
            evenImagelist.add(Phantom);
            includefunctional = true;
        }


        if (eval.Airscan_ID__c != null) {
            //Airscan = 'https://drive.google.com/uc?id=' + eval.Airscan_ID__c;
            Airscan = 'https://drive.usercontent.google.com/download?id=' + eval.Airscan_ID__c;
            evenImagelist.add(Airscan);
            includefunctional = true;
        }

        if (eval.Do_not_include_any_Functional_Images__c == true) {
            includefunctional = false;
            includeleakage = false;
            nofunctional = true;
        }
        
        if(eval.Depot_Recommended_Repairs__c != null || eval.Depot_Required_Repairs__c != null){
            notDepot = false;
        }

        //String FirstCall = 'https://drive.google.com/uc?id=' + eval.First_Call_ID__c;
        FirstCall = 'https://drive.usercontent.google.com/download?id=' + eval.First_Call_ID__c +'.jpg';

        firstcalllist = new List<String>();

        firstcalllist.add(FirstCall);

        System.debug('THIS IS THE EVAL ID >>>>> ' + eval.Id);

		if (eval.Required_Repairs__c != null || eval.Depot_Required_Repairs__c != null) {
            String list1 = '';
            if(eval.Required_Repairs__c != null){
                list1 = eval.Required_Repairs__c;
            }
            if(eval.Depot_Required_Repairs__c != null){
                list1 = eval.Depot_Required_Repairs__c;
            }
            List<String> requiredlist = list1.split(';');
            Set<String> requiredset = new Set<String>();
            required = new List<String>();
            // Removed Lens Relens from Functional Repair List per Adam's request. 08.14.22. NB
            for (String r : requiredlist) {
                if(r == 'Rod Lens Replacement'){
                    if(rodLenses != null){
                        r = 'Rod Lens Replacement - ' + rodLenses + ' Total';
                    }
                }
                requiredset.add(r);
                /*
                if (r != 'Lens Relens' && r != null) {
                    requiredset.add(r);
                }
                if (r == 'Lens Relens') {
                    requiredset.add('Relens');
                }*/
            }

            required.addAll(requiredset);

        }
        endoscopyRequired = new List<String>();
        if(eval.Endoscopy_Repairs_With_Notes__c != null){
            String list1b = '';
            if(eval.Endoscopy_Repairs_With_Notes__c != null){
                list1b = eval.Endoscopy_Repairs_With_Notes__c;
            }
            List<String> endoscopyRequiredList = list1b.split(';');
            Set<String> endoscopyRequiredSet = new Set<String>();
            
            for (String r : endoscopyRequiredList) {
                endoscopyRequiredSet.add(r);
               
            }

            endoscopyRequired.addAll(endoscopyRequiredSet);
            
        }
        else{
            endoscopyRequired = required;
        }
        // override above options if Endoscopy Required Repairs field filled in
        if(eval.Endoscopy_Required_Repairs__c != null){
            List<String> endoscopyRequiredList2 = eval.Endoscopy_Required_Repairs__c.split(';');
            Set<String> endoscopyRequiredSet2 = new Set<String>();
            for (String r : endoscopyRequiredList2) {
                endoscopyRequiredSet2.add(r);
               
            }
			endoscopyRequired.clear();
            endoscopyRequired.addAll(endoscopyRequiredSet2);
        }
        
        system.debug('THIS IS THE ENDOSCOPY REQUIRED LIST >> ' + endoscopyRequired + ' and IR? >> ' + includeRecommended);
        if (eval.Recommended_Repairs__c != null || eval.Depot_Recommended_Repairs__c != null || eval.Endoscopy_Recommended_Repairs__c != null) {
            String list2 = '';
            if(eval.Recommended_Repairs__c != null){
                list2 = eval.Recommended_Repairs__c;
            }
            if(eval.Depot_Recommended_Repairs__c != null){
                list2 = eval.Depot_Recommended_Repairs__c;
            }
            if(eval.Endoscopy_Recommended_Repairs__c != null){
                list2 = eval.Endoscopy_Recommended_Repairs__c;
                includeRecommended = true;
            }
            List<String> recommendedlist = list2.split(';');
            Set<String> recommendedset = new Set<String>();
            recommended = new List<String>();
            for (String r : recommendedlist) {
               	recommendedset.add(r);
                /*
                if (r != 'Lens Relens' && r != null) {
                    recommendedset.add(r);
                }
                if (r == 'Lens Relens') {
                    recommendedset.add('Relens');
                }*/
            }

            recommended.addAll(recommendedset);

        }
        
        system.debug('THIS IS THE INCLUDE RECOMMENDED >> ' + includeRecommended);
        if (eval.Repairs_Completed__c != null) {
            String list3 = eval.Repairs_Completed__c;
            CompletedRepairs = new List<String>();
            CompletedRepairs = list3.split(';');
        }
        
        System.debug('THIS IS THE REQUIRED >>>> ' + required);

        
        Map<String, String> rowresults = new Map<String, String>{
                'Airscan' => eval.Airscan_Results__c,
                'Articulation' => eval.Articulation_Results__c,
                'Bending Rubber' => eval.Bending_Rubber_Results__c,
                'Cable Jacket' => eval.Cable_Jacket_Results__c,
                'Cap' => eval.Cap_Results__c,
                'Color Artifacts' => eval.Color_Artifacts_Results__c,
                'Connector' => eval.Connector_Results__c,
                'Control Housing' => eval.Control_Housing_Results__c,
                'CW Artifacts' => eval.CW_Artifacts_Results__c,
                'CW Pulse' => eval.CW_Pulse_Results__c,
                'First Call' => eval.First_Call_Results__c,
                'Image' => eval.Image_Results__c,
                'Insertion Tube' => eval.Insertion_Tube_Results__c,
                'Interior' => eval.Interior_Results__c,
                'Leakage Current' => eval.Leakage_Current_Results__c,
                'Lens' => eval.Lens_Results__c,
                'Motor' => eval.Motor_Results__c,
                'Orientation' => eval.Orientation_Results__c,
                'Probe Handle' => eval.Probe_Handle_Results__c,
                'Strain Relief' => eval.Strain_Relief_Results__c,
                'Tip' => eval.Tip_Results__c
        };




        Map<String, String> rowsymptoms = new Map<String, String>{
                'Airscan' => eval.Airscan__c,
                'Articulation' => eval.Articulation__c,
                'Bending Rubber' => eval.Bending_Rubber__c,
                'Cable Jacket' => eval.Cable_Jacket__c,
                'Cap' => eval.Cap__c,
                'Color Artifacts' => eval.Color_Artifacts__c,
                'Connector' => eval.Connector__c,
                'Control Housing' => eval.Control_Housing__c,
                'CW Artifacts' => eval.CW_Artifacts__c,
                'CW Pulse' => eval.CW_Pulse__c,
                'First Call' => eval.First_Call__c,
                'Image' => eval.Image__c,
                'Insertion Tube' => eval.Insertion_Tube__c,
                'Interior' => eval.Interior__c,
                'Leakage Current' => eval.Leakage_Current__c,
                'Lens' => eval.Lens__c,
                'Motor' => eval.Motor__c,
                'Orientation' => eval.Orientation__c,
                'Probe Handle' => eval.Probe_Handle__c,
                'Strain Relief' => eval.Strain_Relief__c,
                'Tip' => eval.Tip__c
        };


        List<string> items = new List<String>();
        List<string> fitems = new List<string>{'Airscan', 'Articulation', 'Color Artifacts', 'CW Artifacts', 'CW Pulse', 'First Call', 'Image', 'Interior', 'Leakage Current', 'Motor', 'Orientation'};
        List<string> citems = new List<string>{'Bending Rubber', 'Cable Jacket', 'Cap', 'Connector', 'Control Housing', 'Lens', 'Probe Handle', 'Strain Relief', 'Tip'};    

        if (eval.Probe_Type__c == 'Convex' || eval.Probe_Type__c == 'Endocavitary' || eval.Probe_Type__c == 'Endovaginal' || eval.Probe_Type__c == 'Intraoperative' ||
                eval.Probe_Type__c == 'Linear' || eval.Probe_Type__c == 'Micro-Convex') {
            items.add('Airscan'); items.add('Cable Jacket'); items.add('Color Artifacts'); items.add('Connector'); 
                    items.add('First Call'); items.add('Image'); items.add('Leakage Current'); items.add('Lens'); 
                    items.add('Orientation'); items.add('Probe Handle'); items.add('Strain Relief');
              
        } else if (eval.Probe_Type__c == 'Convex 3D' || eval.Probe_Type__c == 'Endovaginal 3D' || eval.Probe_Type__c == 'Linear 3D') {
            items.add('Airscan'); items.add('Cable Jacket'); items.add('Cap'); items.add('Color Artifacts'); 
            items.add('Connector'); items.add('First Call'); items.add('Image'); items.add('Leakage Current'); 
            items.add('Motor'); items.add('Orientation'); items.add('Probe Handle'); items.add('Strain Relief');
             

        } else if (eval.Probe_Type__c == 'Phased Array') {
            items.add('Airscan'); items.add('Cable Jacket'); items.add('Color Artifacts'); items.add('Connector'); 
            items.add('CW Artifacts'); items.add('First Call'); items.add('Image'); items.add('Leakage Current');
            items.add('Lens'); items.add('Orientation'); items.add('Probe Handle'); items.add('Strain Relief');
            
        } else if (eval.Probe_Type__c == 'Pencil') {
            items.add('Cable Jacket'); items.add('CW Artifacts'); items.add('CW Pulse'); items.add('Leakage Current'); 
            items.add('Probe Handle');
            

        } else if (eval.Probe_Type__c == 'Transesophageal') {
            items.add('Airscan'); items.add('Articulation'); items.add('Bending Rubber'); items.add('Cable Jacket'); 
            items.add('Color Artifacts'); items.add('Connector'); items.add('Control Housing'); items.add('CW Artifacts'); 
            items.add('First Call'); items.add('Image'); items.add('Insertion Tube'); items.add('Interior'); 
            items.add('Leakage Current'); items.add('Motor'); items.add('Orientation'); items.add('Strain Relief'); 
            items.add('Tip');
              
        }

       TestRecords = new list<String>();
	   CRecords = new list<String>();
       FRecords = new list<String>();
        cosmeticEvaluationList = new List<evaluationWrapper>();
        functionalEvaluationList = new List<evaluationWrapper>();
        
        for (String i : items) {
            TestRecords.add(i + ': ' + rowsymptoms.get(i));
            //row results are formula fields so will always have a value
            if(citems.contains(i)){
                cosmeticEvaluationList.add(new evaluationWrapper(i, rowsymptoms.get(i)?.toLowerCase() ?? 'N/A', rowresults.get(i)));
                CRecords.add(i);
                CRecords.add(rowsymptoms.get(i)?.toLowerCase() ?? 'N/A');        
                CRecords.add(rowresults.get(i));
            }
            if(fitems.contains(i)){
                functionalEvaluationList.add(new evaluationWrapper(i, rowsymptoms.get(i)?.toLowerCase() ?? 'N/A', rowresults.get(i)));
                FRecords.add(i);
                FRecords.add(rowsymptoms.get(i)?.toLowerCase() ?? 'N/A');        
                FRecords.add(rowresults.get(i));
            }
            
        }
        
        RepairComments = '';
        RepairCommentsForm = '';

        if (eval.Repair_Comments__c != null) {
            RepairCommentsForm = eval.Repair_Comments__c;
            RepairComments = RepairCommentsForm.replaceAll(';', '<br/>');
            
        }

    }

    @RemoteAction
    public static String FullRepair(String fullRepPrice) {
        return fullRepPrice;
    }
    @RemoteAction
    public static String RequiredRepair(String reqRepPrice) {
        return reqRepPrice;
    }
    @RemoteAction
    public static String ExchangeRepair(String excRepPrice) {
        return excRepPrice;
    }

    public PageReference SaveCustomerApproval() {
        System.debug('CC...SaveCustomerApproval');
        eval.PO_Number__c = s_PONumber;
        eval.Approved_By__c = ApprovedBy;
        if (ApprovedPrice != 'N/A' && ApprovedPrice != null) {
            eval.Approved_Price__c = Decimal.valueOf(ApprovedPrice.right(ApprovedPrice.length() - 1));
        }

        eval.Approved__c = Approved;
        eval.Date_Repair_Approved__c = Datetime.now();
        System.debug('CC...Approved: ' + Approved);
        //CC Add some explicit actions and bypass trigger code to avoid SOQL limit error
        //2021-07-27 for now only do this if it's fully approved and it is not loaner turns to sale
        //TODO Ask Natalie how to tell if it's a loaner turn - for now assume we can check if the Loaner Price is null

        if(approvalOptions.contains(Approved)) {
        //if(Approved == 'Full Repairs (Recommended and Required)' || ) {
            System.debug('CC...Approved in list');
            //Set Validation class so that we can bypass trigger code
            Validator_Class.SetByPassOppTrigger(true);
            Validator_Class.SetByPassRMATrigger(true);
        }

        update eval;

        Validator_Class.SetByPassOppTrigger(false);
        Validator_Class.SetByPassRMATrigger(false);

        PageReference approvedattach = Page.ApprovalFormAttachment;
        approvedattach.getParameters().put('id', eval.Id);

        ApprovedForm = new Attachment();
        Blob b;
        // TODO: the tests need to handle this so we remove the code here
        if (Test.isRunningTest()) {
            b = Blob.valueOf('this is a pdf string');
        } else {
            // Take the PDF content
             b = approvedattach.getContent();
            // = approvedattach.getContentAsPDF();
        }
        //b = Blob.valueOf('this is a pdf string');
        ApprovedForm.Body = b;
        ApprovedForm.Name = 'Customer Repair Evaluation Approved.pdf';
        ApprovedForm.IsPrivate = false;

        ApprovedForm.ParentId = eval.Id; // the record the file is attached to
        insert ApprovedForm;

        System.debug('CC...Queries used: ' +  Limits.getQueries());
        return new PageReference('/apex/CustomerApprove');
    }
    public PageReference SendCustomerEmail() {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        String subject = eval.Probe_Model__c + ' SN #' + eval.Probe_Serial_Number__c + ' Repair Evaluation';
        String attachmentname = 'Repair Evaluation Form Attachment.doc';
        if (eval.Post_Repair_Evaluation__c == false) {
            eval.Date_Repair_Evaluation_Sent__c = Datetime.now();
            eval.Quote_Date_When_Sent__c = Date.today();
            eval.Expiration_Date_When_Sent__c = Date.today() + 7;
            update eval;
        }

        if (eval.Account_Name__c == 'Conquest Imaging') {
            subject = eval.Probe_Model__c + ' SN #' + eval.Probe_Serial_Number__c + ' RTV ' + eval.Customer_PO__c + ' Repair Evaluation';
        }

        Organization theOrg = [SELECT Id, IsSandbox FROM Organization LIMIT 1];
        String siteUrl;

        if (!theOrg.IsSandbox) {
           // siteUrl = 'https://probomedical.secure.force.com/ApprovalForm';
            siteUrl = 'https://probomedical.my.salesforce-sites.com/ApprovalForm/';
            
        } else {
            siteUrl = Url.getSalesforceBaseUrl().toExternalForm() + '/apex/ApprovalForm';
        }

        System.debug('Using this SiteURL: ' + siteUrl);

        if(Test.isRunningTest()) {
            RMAOwner = 'Test@Test.com';
        }

        String orgEmail = CustomerEmailEVAL;
        String s_email = RMAOwner;
        String Body = '<Html><body><div> Thank you for choosing Probo Medical! We have evaluated your probe. Attached, you will find the repair evaluation form. </div>' +
                '<div Style="margin-top:35px">Click here to review your repair evaluation and approve or decline your repairs: </div><div></div><a href="' + siteUrl + '?Id=' + eval.Id + '">' + 'Customer Repair Evaluation Form</a><div style="margin-top:35px">' +
                '<div Style="margin-top:35px">Click here to see all images taken during the repair evaluation:</div><div></div><a href="' + 'https://drive.google.com/drive/folders/' + DriveFolder + '?usp=sharing">' + 'Evaluation Images</a><div style="margin-top:35px">' +
                '<div Style="margin-top:10px">If you have any questions please don\'t hesitate to contact your Probo Medical representative. </div></body></Html>';

        if (eval.Post_Repair_Evaluation__c == true) {
            subject = eval.Probe_Model__c + ' SN #' + eval.Probe_Serial_Number__c + ' Post Repair Evaluation';
            if (eval.Account_Name__c == 'Conquest Imaging') {
                subject = eval.Probe_Model__c + ' SN #' + eval.Probe_Serial_Number__c + ' RTV ' + eval.Customer_PO__c + ' Post Repair Evaluation';
            }
            attachmentname = 'Post Repair Evaluation Attachment.doc';
            Body = '<Html><body><div> Thank you for choosing Probo Medical! We have repaired your probe. Attached, you will find the post repair evaluation. </div>' +
                    '<div Style="margin-top:35px">Click here to review your post repair evaluation: </div><div></div><a href="' + siteUrl + '?Id=' + eval.Id + '">' + 'Customer Post Repair Evaluation </a><div style="margin-top:35px">' +
                    '<div Style="margin-top:35px">Click here to see all images taken during the post repair evaluation:</div><div></div><a href="' + 'https://drive.google.com/drive/folders/' + DriveFolder + '?usp=sharing">' + 'Evaluation Images</a><div style="margin-top:35px">' +
                    '<div Style="margin-top:10px">If you have any questions please don\'t hesitate to contact your Probo Medical representative. </div></body></Html>';

        }

        PageReference pdf = Page.EvaluationNatalie;
        if((standardEndoscopy || endoscopyOther) && !FieldServiceEngineer){
            pdf = Page.EvaluationEndoscopy;
        }
        pdf.getParameters().put('id', eval.Id);
        pdf.setRedirect(true);

        Blob b;
        // TODO: the tests need to handle this so we remove the code here
        if (Test.isRunningTest()) {
            b = Blob.valueOf('this is a pdf string');
        } else {
            // Take the PDF content
            b = pdf.getContent();
        }
        // Create the email attachment
        Messaging.EmailFileAttachment pfile = new Messaging.EmailFileAttachment();
        pfile.setFileName(attachmentname);
        pfile.setBody(b);

        if (orgEmail != null) {
            email.setToAddresses(new String[]{
                    s_email, orgEmail
            });
        } else {
            email.setToAddresses(new String[]{
                    s_email
            });
        }

        email.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
        email.setTargetObjectId(UserInfo.getUserId());
        email.setSubject(subject);
        email.setHtmlBody(Body);
        email.setSaveAsActivity(false);

        email.setFileAttachments(new Messaging.EmailFileAttachment[]{
                pfile
        });

        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                email
        });

        GH_Logger.debug('Email sent results: ' + results);

        return new PageReference('/apex/EmailSent');
    }

    public PageReference SendCustomerEmailPDF() {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        String subject = eval.Probe_Model__c + ' SN #' + eval.Probe_Serial_Number__c + ' Repair Evaluation';
        String attachmentname = 'Repair Evaluation Form Attachment.pdf';
        if (eval.Post_Repair_Evaluation__c == false) {
            eval.Date_Repair_Evaluation_Sent__c = Datetime.now();
            eval.Quote_Date_When_Sent__c = Date.today();
            eval.Expiration_Date_When_Sent__c = Date.today() + 7;
            update eval;
        }

        if (eval.Account_Name__c == 'Conquest Imaging') {
            subject = eval.Probe_Model__c + ' SN #' + eval.Probe_Serial_Number__c + ' RTV ' + eval.Customer_PO__c + ' Repair Evaluation';
        }

        Organization theOrg = [SELECT Id, IsSandbox FROM Organization LIMIT 1];
        String siteUrl;

        if (!theOrg.IsSandbox) {
            //siteUrl = 'https://probomedical.secure.force.com/ApprovalForm';
            siteUrl = 'https://probomedical.my.salesforce-sites.com/ApprovalForm/';
        } else {
            siteUrl = Url.getSalesforceBaseUrl().toExternalForm() + '/apex/ApprovalForm';

        }

        System.debug('Using this SiteURL: ' + siteUrl);

        if(Test.isRunningTest()) {
            RMAOwner = 'Test@Test.com';
        }

        String orgEmail = CustomerEmailEVAL;
        String s_email = RMAOwner;
        String Body = '<Html><body><div> Thank you for choosing Probo Medical! We have evaluated your probe. Attached, you will find the repair evaluation form. </div>' +
                '<div Style="margin-top:35px">Click here to review your repair evaluation and approve or decline your repairs: </div><div></div><a href="' + siteUrl + '?Id=' + eval.Id + '">' + 'Customer Repair Evaluation Form</a><div style="margin-top:35px">' +
                '<div Style="margin-top:35px">Click here to see all images taken during the repair evaluation:</div><div></div><a href="' + 'https://drive.google.com/drive/folders/' + DriveFolder + '?usp=sharing">' + 'Evaluation Images</a><div style="margin-top:35px">' +
                '<div Style="margin-top:10px">If you have any questions please don\'t hesitate to contact your Probo Medical representative. </div></body></Html>';

        if (eval.Post_Repair_Evaluation__c == true) {
            subject = eval.Probe_Model__c + ' SN #' + eval.Probe_Serial_Number__c + ' Post Repair Evaluation';
            if (eval.Account_Name__c == 'Conquest Imaging') {
                subject = eval.Probe_Model__c + ' SN #' + eval.Probe_Serial_Number__c + ' RTV ' + eval.Customer_PO__c + ' Post Repair Evaluation';
            }
            attachmentname = 'Post Repair Evaluation Attachment.pdf';
            Body = '<Html><body><div> Thank you for choosing Probo Medical! We have repaired your probe. Attached, you will find the post repair evaluation. </div>' +
                    '<div Style="margin-top:35px">Click here to review your post repair evaluation: </div><div></div><a href="' + siteUrl + '?Id=' + eval.Id + '">' + 'Customer Post Repair Evaluation </a><div style="margin-top:35px">' +
                    '<div Style="margin-top:35px">Click here to see all images taken during the post repair evaluation:</div><div></div><a href="' + 'https://drive.google.com/drive/folders/' + DriveFolder + '?usp=sharing">' + 'Evaluation Images</a><div style="margin-top:35px">' +
                    '<div Style="margin-top:10px">If you have any questions please don\'t hesitate to contact your Probo Medical representative. </div></body></Html>';

        }

        PageReference pdf = Page.EvaluationPDF;
        //PageReference pdf = new PageReference(Site.getBaseUrl() + '/apex/EvaluationNatalie').getContentAsPDF();
        pdf.getParameters().put('id', eval.Id);
        pdf.setRedirect(true);

        Blob b;
        // TODO: the tests need to handle this so we remove the code here
        if (Test.isRunningTest()) {
            b = Blob.valueOf('this is a pdf string');
        } else {
            // Take the PDF content
            b = pdf.getContent();
        }
        // Create the email attachment
        Messaging.EmailFileAttachment pfile = new Messaging.EmailFileAttachment();
        pfile.setFileName(attachmentname);
        pfile.setBody(b);

        if (orgEmail != null) {
            email.setToAddresses(new String[]{
                    s_email, orgEmail
            });
        } else {
            email.setToAddresses(new String[]{
                    s_email
            });
        }

        email.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
        email.setTargetObjectId(UserInfo.getUserId());
        email.setSubject(subject);
        email.setHtmlBody(Body);
        email.setSaveAsActivity(false);

        email.setFileAttachments(new Messaging.EmailFileAttachment[]{
                pfile
        });

        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                email
        });

        GH_Logger.debug('Email sent results: ' + results);

        return new PageReference('/apex/EmailSent');
    }
    
    public PageReference redirect() {
        
        string returnstring = (FieldServiceEngineer ? '/apex/FSEEvaluation' : '/apex/EvaluationNatalie');
        if((standardEndoscopy || endoscopyOther) && !FieldServiceEngineer){
            Boolean isEndoscopy = false;
            if(standardEndoscopy || endoscopyOther){
                isEndoscopy = true;
            }
            returnstring = (isEndoscopy ? '/apex/EvaluationEndoscopy' : '/apex/EvaluationNatalie');
        }
        if(PostRepair && !FieldServiceEngineer){
            returnstring = (PostRepair ? '/apex/EvaluationPostRepair' : '/apex/EvaluationNatalie');
        }
        
//        returnstring += '?id=' + eval.Id;
        return new PageReference(returnstring);
    }
    
    public class otherEndoscopyWrapper {
            public String quantity { get; set; }
            public String itemDescription { get; set; }
        	public String repairsNeeded { get; set; }
        	public String repairPrice { get; set; }

            public otherEndoscopyWrapper(String quantity, String item, String repairs, String price) {
                this.quantity = quantity;
                this.itemDescription = item;
                this.repairsNeeded = repairs;
                this.repairPrice = price;
            }
        }
                                             
       public class evaluationWrapper {
            public String itemInfo { get; set; }
            public String results { get; set; }
            public String issuesFound { get; set; }

            public evaluationWrapper(String item, String results, String issues) {
                this.itemInfo = item;
                this.results = results;
                this.issuesFound = issues;
            }
        }
    
    

   
    

}