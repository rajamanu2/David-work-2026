public class cGoogleAppAuthenticationWithSalesforce {

    // Most of this code found online

    //Client ID to identify the app being used to connect to google drive.
    //for example any app being used to connect google drive for any purpose having these client ID and secret
    private String key = '836381745373-tq8on7q054gm80crmsqcce9m4kcrjgud.apps.googleusercontent.com' ;
    private String secret = '73lz6gTAzRLZxKKGQsl15rIV';
    //After receiving Authecation token for the app , will be redirected to this URL and one parameter in the URL will have to receive

    private String redirect_uri = Url.getSalesforceBaseUrl().toExternalForm() + '/apex/AuthenticationGoogleDrive'; // for Production

    // private string redirect_uri = 'https://probomedical.my.salesforce.com/apex/AuthenticationGoogleDrive'; // for Production
    //private string redirect_uri = 'https://c.cs13.visual.force.com/apex/AuthenticationGoogleDrive'; // for Sandbox

    //App Authentication token is stored in this variable
    private String codemeniaIdentificationToken ;

    //After App authentication by app user will have to provide its own google user name and password
    //which is different from App created for client id and client secret
    //for Example you have one google ID as admin@gmail.com and using this you created one app
    //now you wants to fetch files for user@gmail.com from google drive
    //so Client secret is created by admin@gmail.com and access token is received for user@gmail.com
    private String access_token;
    private List<String> FileLst;
    @TestVisible public List<String> testFileList { get; set; }
    public Map<String, String> FileIdAndNameMapFortheAccount { get; set; }
    public Map<String, String> FileNameAndIdMapFortheAccount { get; set; }
    @TestVisible public Map<String, String> testFileMap { get; set; }
    public static List<String> required { get; set; }
    public static List<String> recommended { get; set; }
    public static String itemid;
    public static String itemid2;
    public static List<String> images { get; set; }
    public String callfunc { get; set; }
    private ProductItem__c pitem;
    public String LensID { get; set; }
    public String CapID { get; set; }
    public String WholeID { get; set; }
    public String SNID { get; set; }
    public String LeakageCurrentID { get; set; }
    public String AirscanID { get; set; }
    public String PhantomID { get; set; }
    public String FirstCallID { get; set; }
    public String Damage1 { get; set; }
    public String Damage2 { get; set; }
    public String Damage3 { get; set; }
    public String DriveFolder { get; set; }
    public String eitemid { get; set; }
    public String RecommendedRepairs { get; set; }
    public String RequiredRepairs { get; set; }
    public String depotRecommendedRepairs { get; set; }
    public String depotRequiredRepairs { get; set; }
    public String RepairComments { get; set; }
    public String EndoscopyRepairsWithNotes { get; set; }
    public String EndoscopyResults { get; set; }
    public String EndoscopyResultsComments { get; set; }
    public String endoscopyRepairs { get; set; }
    public Decimal otherEndoscopyPrice { get; set; }
    private Evaluation_Natalie__c EVAL { get; set; }
    public Decimal FullPrice { get; set; }
    public Decimal ReqPrice { get; set; }
    public Decimal ExcPrice { get; set; }
    public Decimal LoanerPrice { get; set; }

    @TestVisible
    private static String getEvaluationIdFromState(String stateValue) {
        if (String.isBlank(stateValue)) {
            return null;
        }

        String decodedState = stateValue;
        try {
            decodedState = EncodingUtil.urlDecode(decodedState, 'UTF-8');
        } catch (Exception ignored) {
            return null;
        }

        for (String statePart : decodedState.split('&')) {
            List<String> nameAndValue = statePart.split('=', 2);
            if (nameAndValue.size() != 2 || nameAndValue[0] != 'evaluationId') {
                continue;
            }

            try {
                Id evaluationId = Id.valueOf(nameAndValue[1]);
                if (evaluationId.getSObjectType() == Evaluation_Natalie__c.SObjectType) {
                    return String.valueOf(evaluationId);
                }
            } catch (Exception ignored) {
                return null;
            }
        }
        return null;
    }

    private static void addPageError(String message) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
    }

    @TestVisible
    private static String normalizeDriveFolderId(String folderValue) {
        if (String.isBlank(folderValue)) {
            return null;
        }

        String normalizedValue = folderValue.trim();
        if (normalizedValue.contains('/folders/')) {
            normalizedValue = normalizedValue.substringAfter('/folders/');
        }
        if (normalizedValue.contains('?')) {
            normalizedValue = normalizedValue.substringBefore('?');
        }
        if (normalizedValue.contains('/')) {
            normalizedValue = normalizedValue.substringBefore('/');
        }
        return String.isBlank(normalizedValue) ? null : normalizedValue;
    }

    private List<Product_Test_Line_Item__c> getTestItems(Id assetId) {
        List<ProductTest__c> recentProductTests = [SELECT Id, Product_Item__c FROM ProductTest__c WHERE Product_Item__c = :assetId ORDER BY CreatedDate DESC LIMIT 1];
        if (recentProductTests.isEmpty()) {
            return new List<Product_Test_Line_Item__c>();
        }
        ProductTest__c recentProductTest = recentProductTests[0];
        system.debug('THIS IS THE TEST FOUND >> ' + recentProductTest);
        List<Product_Test_Line_Item__c> productTestItems = [SELECT Id, Quantity__c, Item_Description__c, ProductTest__c, Complaint__c, Repair_Technician__c, Repairs_Needed__c, Repair_Price__c
                                                           FROM Product_Test_Line_Item__c WHERE ProductTest__c = :recentProductTest.Id ORDER BY CreatedDate ASC];
        
        return productTestItems;
    }

    //Constructor
    public cGoogleAppAuthenticationWithSalesforce(ApexPages.StandardController controller) {
        itemid = ApexPages.currentPage().getParameters().get('id');
        if (String.isBlank(itemid)) {
            itemid = getEvaluationIdFromState(ApexPages.currentPage().getParameters().get('state'));
        }

        FileLst = new List<String>();
        FileIdAndNameMapFortheAccount = new Map<String, String>();
        FileNameAndIdMapFortheAccount = new Map<String, String>();

        if (String.isBlank(itemid)) {
            addPageError('The Evaluation could not be identified. Return to the Evaluation and start authentication again.');
            return;
        }

        List<Product_Test_Line_Item__c> testItems = new List<Product_Test_Line_Item__c>();
        Id pitemid;
        System.debug('THIS IS THE ITEM ID THROUGH THE PAGE >>>> ' + itemid);

        if (itemid != null) {
            List<Evaluation_Natalie__c> evaluations = [select Id, Product_Item_ID__c, Name, Product_Family__c, Probe_Type__c, Associated_RMA__c, Quote_Issue_Date__c from Evaluation_Natalie__c WHERE Id = :itemid LIMIT 1];
            if (evaluations.isEmpty()) {
                addPageError('The requested Evaluation is unavailable. Return to the Evaluation and start authentication again.');
                return;
            }
            EVAL = evaluations[0];

            if (EVAL.Associated_RMA__c == null) {
                addPageError('The Evaluation must have an associated RMA before authentication.');
                return;
            }

            List<RMA__c> associatedRMAs = [
                    select Id, Recommended_Repairs__c, Required_Repairs__c, Depot_Repair__c, Endoscopy_Evaluation_Results__c,
                            Full__c, Required__c, Exchange__c, Loaner__c, Other_Notes_Cosmetic__c, Other_Notes_Functional__c, Cause_of_Damage__c
                    from RMA__c
                    where Id = :EVAL.Associated_RMA__c
            ];
            if (associatedRMAs.isEmpty()) {
                addPageError('The Evaluation\'s associated RMA is unavailable.');
                return;
            }
            RMA__c associatedRMA = associatedRMAs[0];
            // setting up pricing for "Other" endoscopy products
            otherEndoscopyPrice = 0;
            endoscopyRepairs = '';
            if(eval.Product_Family__c != null && ((eval.Probe_Type__c != null && (!eval.Probe_Type__c.contains('Endoscopy')) && eval.Product_Family__c.contains('Endoscopy')) || eval.Product_Family__c == 'Instrument Tray')){
                testItems = getTestItems(eval.Product_Item_ID__c);
                
                if(testItems.size() != 0){
                    for(Product_Test_Line_Item__c lineItem: testItems){
                        system.debug('THIS IS INSIDE FOR LOOP FOR TEST LINE ITEMS >>> ' + lineItem);
                        if(lineItem.Repair_Price__c != null){
                            otherEndoscopyPrice += lineItem.Repair_Price__c;
                        }
                        if(lineItem.Repairs_Needed__c != null){
                            endoscopyRepairs += lineItem.Repairs_Needed__c + ';';
                        }
                    }
                }
            }

            if (String.isBlank(EVAL.Product_Item_ID__c)) {
                addPageError('The Evaluation must have a Product Item before authentication.');
                return;
            }
            try {
                pitemid = Id.valueOf(EVAL.Product_Item_ID__c);
            } catch (Exception ignored) {
                addPageError('The Evaluation contains an invalid Product Item reference.');
                return;
            }
            if(associatedRMA.Depot_Repair__c == false){
                RequiredRepairs = associatedRMA.Required_Repairs__c;
            	RecommendedRepairs = associatedRMA.Recommended_Repairs__c;
            }
            if(associatedRMA.Depot_Repair__c == true){
                depotRequiredRepairs = associatedRMA.Required_Repairs__c;
            	depotRecommendedRepairs = associatedRMA.Recommended_Repairs__c;
            }
            
            
            FullPrice = associatedRMA.Full__c;
            ReqPrice = associatedRMA.Required__c;
            ExcPrice = associatedRMA.Exchange__c;
            LoanerPrice = associatedRMA.Loaner__c;
            if(otherEndoscopyPrice != 0){
                FullPrice = otherEndoscopyPrice;
                ReqPrice = otherEndoscopyPrice;
            }
            RepairComments = '';
            EndoscopyResults = '';
            EndoscopyResultsComments = '';
            EndoscopyRepairsWithNotes = '';
            
            if(associatedRMA.Endoscopy_Evaluation_Results__c != null){
                system.debug('THIS IS THE ENDOSCOPY EVAL RESULTS >> ' + associatedRMA.Endoscopy_Evaluation_Results__c + ' AND REQUIRED REPAIRS >> ' + associatedRMA.Required_Repairs__c);
                List<String> endoscopyResultsList = associatedRMA.Endoscopy_Evaluation_Results__c.split(';');
                if(associatedRMA.Required_Repairs__c != null){
                    List<String> endoscopyRequiredRepairs = associatedRMA.Required_Repairs__c.split(';');
                    
                    for(String repair:endoscopyRequiredRepairs){
                        String notePrefix = '';
                        String resultsNote = '';
                        if(repair.contains('Repair')){
                            notePrefix = repair.substringBefore('Repair').trim();
                            if(endoscopyRequiredRepairs.contains(notePrefix + ' Replacement')){
                                continue;
                            }
                        }
                        else if(repair.contains('Replacement')){
                            notePrefix = repair.substringBefore('Replacement').trim();
                        }
                        if(notePrefix != null && notePrefix != ''){
                            notePrefix = notePrefix.deleteWhitespace();
                            
                            for(string result:endoscopyResultsList){
                                system.debug('THIS IS THE RESULT INSIDE LOOP >> ' + result + ' AND NOTE PREFIX >> ' + notePrefix);
                            
                                if(result.contains(notePrefix)){
                                    String notePrefixString = notePrefix + ':';
                                    resultsNote = ': ' + result.substringAfter(notePrefixString).trim();
                                }
                            }
                            system.debug('THIS IS THE ENDOSCOPY REPAIRS WITH NOTES >> ' + repair + ' >> ' + resultsNote + ' AND CURRENT FIELD VALUE >> ' + EndoscopyRepairsWithNotes);
                            EndoscopyRepairsWithNotes += repair + resultsNote + '; ';
                        }
                        else{
                            EndoscopyRepairsWithNotes += repair + '; ';
                        }
                         
                    }
                }
                
                EndoscopyResults = associatedRMA.Endoscopy_Evaluation_Results__c;
                /*EndoscopyResultsComments = EndoscopyResults.replaceAll(';', ',');
                EndoscopyResultsComments = EndoscopyResultsComments.RemoveEnd(',');
                RepairComments += 'Detailed Repair Evaluation: ' + EndoscopyResultsComments + '; ';*/
            }
            else{
                if(String.isNotBlank(endoscopyRepairs)){
                    EndoscopyResults = endoscopyRepairs;
                }
            }
            if (associatedRMA.Other_Notes_Cosmetic__c != null) {
                RepairComments += 'Cosmetic Notes: ' + associatedRMA.Other_Notes_Cosmetic__c + '; ';
            }
            if (associatedRMA.Other_Notes_Functional__c != null) {
                RepairComments += 'Functional Notes: ' + associatedRMA.Other_Notes_Functional__c + '; ';
            }
            if(associatedRMA.Cause_of_Damage__c != null){
                system.debug('THIS IS THE CAUSE OF DAMAGE >> ' + associatedRMA.Cause_of_Damage__c);
            
                RepairComments += 'Cause of Damage: ' + associatedRMA.Cause_of_Damage__c + '; ';
            }
            system.debug('THIS IS THE REPAIR COMMENTS >> ' + RepairComments);

        }


        System.debug('THIS IS THE PITEMID >>>> ' + pitemid);

        List<ProductItem__c> productItems = [select Id, Google_Drive_Folder_ID__c, Product_Family__c from ProductItem__c where Id = :pitemid LIMIT 1];
        if (productItems.isEmpty()) {
            addPageError('The Evaluation\'s Product Item is unavailable.');
            return;
        }
        pitem = productItems[0];
        
        
        DriveFolder = normalizeDriveFolderId(pitem.Google_Drive_Folder_ID__c);
        System.debug('THIS IS THE DRIVE FOLDER >>>> ' + DriveFolder);

        //Once Authentication is done again constructor is called and will have to receive the value for code parameter
        codemeniaIdentificationToken = ApexPages.currentPage().getParameters().get('code') ;


        FileLst = new List<String>();
        FileIdAndNameMapFortheAccount = new Map<String, String>();
        FileNameAndIdMapFortheAccount = new Map<String, String>();
        
        if ((codemeniaIdentificationToken != '' && codemeniaIdentificationToken != null)) {
            AccessToken();
        }
        
        System.debug('ITEM ID >>>>>>> ' + itemid);

    }


    public PageReference save() {

        if (EVAL == null) {
            addPageError('No Evaluation is available to save. Return to the Evaluation and try again.');
            return null;
        }

        EVAL.Lens_ID__c = LensID;

        if (CapID != null) {
            EVAL.Lens_ID__c = CapID;
        }
        if (Damage1 != null) {
            EVAL.Lens_ID__c = Damage1;
        }

        EVAL.Whole_ID__c = WholeID;
        if (Damage2 != null) {
            EVAL.Whole_ID__c = Damage2;
        }
        EVAL.SN_ID__c = SNID;
        if (Damage3 != null) {
            EVAL.SN_ID__c = Damage3;
        }
        EVAL.Leakage_Current_ID__c = LeakageCurrentID;
        EVAL.Airscan_ID__c = AirscanID;
        EVAL.Phantom_ID__c = PhantomID;
        EVAL.First_Call_ID__c = FirstCallID;
        EVAL.Depot_Recommended_Repairs__c = depotRecommendedRepairs;
        EVAL.Depot_Required_Repairs__c = depotRequiredRepairs;
        EVAL.Recommended_Repairs__c = RecommendedRepairs;
        EVAL.Required_Repairs__c = RequiredRepairs;
        EVAL.Full_Repair_Price__c = FullPrice;
        EVAL.Required_Repairs_Price__c = ReqPrice;
        EVAL.Exchange_Probe_Price__c = ExcPrice;
        EVAL.Loaner_Price__c = LoanerPrice;
        EVAL.Folder_ID__c = DriveFolder;
        EVAL.Repair_Comments__c = RepairComments;
        EVAL.Endoscopy_Evaluation_Results__c = EndoscopyResults;
        EVAL.Endoscopy_Repairs_With_Notes__c = EndoscopyRepairsWithNotes;
        System.debug('THIS IS THE LENS ID >>>>> ' + LensID);
        update EVAL;
        return null;
    }

    public PageReference DriveAuth() {

        if (String.isBlank(itemid)) {
            addPageError('The Evaluation could not be identified. Return to the Evaluation and try again.');
            return null;
        }

        PageReference pg = new PageReference(new cAuthURIForEval(key, redirect_uri, itemid).AuthenticationURI) ;

        return pg;

    }

    public void AccessToken() {
        //Getting access token from google
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        //End point for authentication
        req.setEndpoint('https://accounts.google.com/o/oauth2/token');
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        //Message body for Authentication
        String messageBody = 'code=' + codemeniaIdentificationToken + '&client_id=' + key + '&client_secret=' + secret + '&redirect_uri=' + redirect_uri + '&grant_type=authorization_code';
        req.setHeader('Content-length', String.valueOf(messageBody.length()));
        req.setBody(messageBody);
        req.setTimeout(60 * 1000);

        Http h = new Http();
        HttpResponse res = h.send(req);
        //Salesforce defined JSON Parser
        if(!Test.isRunningTest()){
            JSONParser parser = JSON.createParser(res.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')) {
                    parser.nextToken();
                    access_token = parser.getText();
                    break;
                }
            }
        }
        
        if (access_token != '' && access_token != null) {
            ListFiles();
        }
    }

    public PageReference ListFiles() {

        if (String.isBlank(DriveFolder)) {
            addPageError('The Product Item does not have a valid Google Drive folder.');
            return null;
        }


        HttpRequest req1 = new HttpRequest();
        req1.setMethod('GET');
        //End point for List of Files in Folder
        req1.setEndpoint('https://www.googleapis.com/drive/v2/files/' + DriveFolder + '/children');
        req1.setHeader('content-type', 'application/x-www-form-urlencoded');
        req1.setHeader('Content-length', '0');
        //Specific Authorization Syntax
        req1.setHeader('Authorization', 'Bearer' + ' ' + access_token);
        req1.setTimeout(60 * 1000);
        Http h2 = new Http();
        HttpResponse resl = h2.send(req1);
        System.debug('^^^^^' + resl.getBody());
        Map<String, String> FileIDNewMap = new Map<String, String>();
        String fileid = '';
        String filename = '';
        
        if(!Test.isRunningTest()){
            JSONParser parserD = JSON.createParser(resl.getBody());
            
            while (parserD.nextToken() != null) {
                system.debug('THIS IS THE PARSER GET TEXT >>> ' + parserD.getText());
                system.debug('THIS IS THE CURRENT TOKEN >>> ' + parserD.getCurrentToken ());
                if ((parserD.getCurrentToken() == JSONToken.FIELD_NAME) && (parserD.getText() == 'id')) {
                    parserD.nextToken();
                    FileLst.add(parserD.getText());
                    fileid = parserD.getText();
                }
                if ((parserD.getCurrentToken() == JSONToken.FIELD_NAME) && (parserD.getText() == 'name')) {
                    parserD.nextToken();
                    filename = parserD.getText();
                }
                FileIDNewMap.put(fileid, filename);
            }
        }
        
        System.debug('THIS IS THE FILE LIST >>>>> ' + FileLst);
        System.debug('THIS IS THE NEW FILE MAP >>>>> ' + FileIDNewMap);
        Map<String, String> FileIdAndNameMap = FileProperties();
        List<String> folderdate = new List<String>();
        
        System.debug('THIS IS THE FILE ID MAP >>>>> ' + FileIdAndNameMap);
        for (String s : FileLst) {
            String mappedFileName = FileIdAndNameMap.get(s);
            if (String.isBlank(mappedFileName)) {
                continue;
            }
            FileIdAndNameMapFortheAccount.put(s, mappedFileName);
            FileNameAndIdMapFortheAccount.put(mappedFileName, s);
            folderdate.add(mappedFileName);
        }
        if(Test.isRunningTest()){
            folderdate = testFileList.clone();
        }
        System.debug('FileId and Name Map for Account >>>>>>>> ' + FileIdAndNameMapFortheAccount);
        System.debug('File name and id map for account >>>>> ' + FileNameAndIdMapFortheAccount);
        Set<string> FileNameKeys = FileNameAndIdMapFortheAccount.keySet();
        Boolean correctFolder = false;
        system.debug('This is the File Name Keys >>> ' + FileNameKeys);
        for(string k:FileNameKeys){
            if(k != null){
                if(k.containsIgnoreCase('C-Whole') || k.containsIgnoreCase('C-SN') || k.containsIgnoreCase('C-Damage') || k.containsIgnoreCase('Photo 1')){
                	correctFolder = true;
            	}
            }
            
        }
        //if (FileNameAndIdMapFortheAccount.get('C-Whole.JPG') == null && FileNameAndIdMapFortheAccount.get('C-SN.JPG') == null && FileNameAndIdMapFortheAccount.get('C-Damage 1.JPG') == null) {
        if(correctFolder == false){    
        	Integer baseline = 0;
            String folderdateshort = '';
            String correctdate = '';
            for (String f : folderdate) {
                if (String.isBlank(f) || f.length() < 6) {
                    continue;
                }
                folderdateshort = f.left(6);
                if (folderdateshort.isNumeric()) {
                    if (Integer.valueOf(folderdateshort) > baseline) {
                        baseline = Integer.valueOf(folderdateshort);
                    }
                }
                System.debug('THIS IS THE SHORT DATE >>> ' + folderdateshort + ' AND THIS IS THE BASELINE >>> ' + baseline);
            }
            for (String f : folderdate) {
                if (String.isBlank(f) || f.length() < 6) {
                    continue;
                }
                if (f.left(6) == String.valueOf(baseline)) {
                    correctdate = f;
                }
            }
            DriveFolder = FileNameAndIdMapFortheAccount.get(correctdate);
            if (String.isBlank(DriveFolder)) {
                addPageError('No valid image folder was found in Google Drive.');
                return null;
            }
            System.debug('THIS IS THE DRIVE FOLDER ID >>>> ' + DriveFolder);
            HttpRequest req3 = new HttpRequest();
            req3.setMethod('GET');
            //End point for List of Files in Folder
            req3.setEndpoint('https://www.googleapis.com/drive/v2/files/' + DriveFolder + '/children');
            req3.setHeader('content-type', 'application/x-www-form-urlencoded');
            req3.setHeader('Content-length', '0');
            //Specific Authorization Syntax
            req3.setHeader('Authorization', 'Bearer' + ' ' + access_token);
            req3.setTimeout(60 * 1000);
            Http h4 = new Http();
            HttpResponse res3 = h4.send(req3);
            System.debug('^^^^^' + res3.getBody());
            if(!Test.isRunningTest()){
                JSONParser parserD2 = JSON.createParser(res3.getBody());

                while (parserD2.nextToken() != null) {
                    if ((parserD2.getCurrentToken() == JSONToken.FIELD_NAME) && (parserD2.getText() == 'id')) {
                        parserD2.nextToken();
                        FileLst.add(parserD2.getText());
                        fileid = parserD2.getText();
                    }
                    if ((parserD2.getCurrentToken() == JSONToken.FIELD_NAME) && (parserD2.getText() == 'name')) {
                        parserD2.nextToken();
                        filename = parserD2.getText();
                    }
                    FileIDNewMap.put(fileid, filename);
                }
            }
            
            System.debug('THIS IS THE FILE LIST >>>>> ' + FileLst);
            System.debug('THIS IS THE NEW FILE MAP >>>>> ' + FileIDNewMap);
            Map<String, String> FileIdAndNameMap2 = FileProperties();
            if(Test.isRunningTest()){
            	FileIdAndNameMap2 = testFileMap.clone();
        	}
            System.debug('THIS IS THE FILE ID MAP >>>>> ' + FileIdAndNameMap2);
            for (String s : FileLst) {
                System.debug('Checking S for Map: \'' + s + '\'');
                String nestedMappedFileName = FileIdAndNameMap2.get(s);
                if (String.isBlank(nestedMappedFileName)) {
                    continue;
                }
                nestedMappedFileName = nestedMappedFileName.trim();
                System.debug('Adding this Product to Map2: \'' + nestedMappedFileName + '\'');
                FileIdAndNameMapFortheAccount.put(s, nestedMappedFileName);
                FileNameAndIdMapFortheAccount.put(nestedMappedFileName, s);
            }
        }
        if(Test.isRunningTest()){
            FileNameAndIdMapFortheAccount = testFileMap.clone();
        }
        Set<string> FileNameKeys2 = FileNameAndIdMapFortheAccount.keySet();
        system.debug('This is the File Name Keys 2 >>> ' + FileNameKeys2);
        for(string k2:FileNameKeys2){
            if(k2 != null){
                if(k2.containsIgnoreCase('C-Lens') || k2.containsIgnoreCase('Photo 1')){
                    LensID = FileNameAndIdMapFortheAccount.get(k2);
                }
                else if(k2.containsIgnoreCase('C-Cap')){
                    CapID = FileNameAndIdMapFortheAccount.get(k2);
                }
                else if(k2.containsIgnoreCase('C-Whole') || k2.containsIgnoreCase('Photo 2')){
                    WholeID = FileNameAndIdMapFortheAccount.get(k2);
                }
                else if(k2.containsIgnoreCase('C-SN') || k2.containsIgnoreCase('Photo 3')){
                    SNID = FileNameAndIdMapFortheAccount.get(k2);
                }
                else if(k2.containsIgnoreCase('C-Damage 1')){
                    Damage1 = FileNameAndIdMapFortheAccount.get(k2);
                }
                else if(k2.containsIgnoreCase('C-Damage 2')){
                    Damage2 = FileNameAndIdMapFortheAccount.get(k2);
                }
                else if(k2.containsIgnoreCase('C-Damage 3')){
                    Damage3 = FileNameAndIdMapFortheAccount.get(k2);
                }
                else if(k2.containsIgnoreCase('F-Leakage Test') || k2.containsIgnoreCase('Photo 4')){
                    LeakageCurrentID = FileNameAndIdMapFortheAccount.get(k2);
                }
                else if(LeakageCurrentID == null && k2.containsIgnoreCase('F-Phantom 1')){
                    LeakageCurrentID = FileNameAndIdMapFortheAccount.get(k2);
                }
                else if(k2.containsIgnoreCase('F-Airscan') || k2.containsIgnoreCase('Photo 5')){
                    AirscanID = FileNameAndIdMapFortheAccount.get(k2);
                }
                else if(k2.containsIgnoreCase('F-Phantom 2') || k2.containsIgnoreCase('Photo 6')){
                    PhantomID = FileNameAndIdMapFortheAccount.get(k2);
                }
                else if(k2.containsIgnoreCase('First Call')){
                    FirstCallID = FileNameAndIdMapFortheAccount.get(k2);
                }
            }
                
        }
       /* LensID = FileNameAndIdMapFortheAccount.get('C-Lens.JPG');
        CapID = FileNameAndIdMapFortheAccount.get('C-Cap.JPG');
        WholeID = FileNameAndIdMapFortheAccount.get('C-Whole.JPG');
        SNID = FileNameAndIdMapFortheAccount.get('C-SN.JPG');
        Damage1 = FileNameAndIdMapFortheAccount.get('C-Damage 1.JPG');
        Damage2 = FileNameAndIdMapFortheAccount.get('C-Damage 2.JPG');
        Damage3 = FileNameAndIdMapFortheAccount.get('C-Damage 3.JPG');
        
        
        LeakageCurrentID = FileNameAndIdMapFortheAccount.get('F-Leakage Test.JPG');
        if (LeakageCurrentID == null) {
            System.debug('F-Leakage Test.JPG not found.  Looking for F-Phantom 1.JPG');
            LeakageCurrentID = FileNameAndIdMapFortheAccount.get('F-Phantom 1.JPG');
        }
        AirscanID = FileNameAndIdMapFortheAccount.get('F-Airscan.JPG');
        PhantomID = FileNameAndIdMapFortheAccount.get('F-Phantom 2.JPG');
        FirstCallID = FileNameAndIdMapFortheAccount.get('First Call.JPG');*/
		System.debug('THIS IS THE SN ID >>>>> ' + SNID);
        return null;
    }

    public Map<String, String> FileProperties() {
        Map<String, String> FilePropertiesDetails = new Map<String, String>();
        if(Test.isRunningTest()){
            FileLst = testFileList.clone();
        }
        for (String s : FileLst) {
            HttpRequest req2 = new HttpRequest();
            req2.setMethod('GET');
            //End point URL for All the files in the drive and its ID,Name value in JSON Response
            req2.setEndpoint('https://www.googleapis.com/drive/v3/files/' + s);
            req2.setHeader('content-type', 'application/x-www-form-urlencoded');
            req2.setHeader('Content-length', '0');
            req2.setHeader('Authorization', 'Bearer' + ' ' + access_token);
            req2.setTimeout(60 * 1000);
            Http h3 = new Http();
            HttpResponse resls = h3.send(req2);
            System.debug('^^^^^' + resls.getBody());
            if(!Test.isRunningTest()){
                JSONParser parserDr = JSON.createParser(resls.getBody());
                while (parserDr.nextToken() != null) {
                    String FileName = '';
                    String FileId = '';
                    if ((parserDr.getCurrentToken() == JSONToken.FIELD_NAME)) {
                        //First TOKEN is Id
                        if ((parserDr.getText() == 'id')) {
                            parserDr.nextToken();
                            FileId = parserDr.getText();
                        }
                        //Moving to Next Parser
                        parserDr.nextToken();
                        //Next Token is Name
                        if ((parserDr.getText() == 'name')) {
                            parserDr.nextToken();
                            FileName = parserDr.getText();
                        }
                        FilePropertiesDetails.put(FileId, FileName);
                    }
                }
            }
            
        }
        if (Test.isRunningTest() && testFileMap != null) {
            return testFileMap.clone();
        }
        return FilePropertiesDetails;
    }
}
