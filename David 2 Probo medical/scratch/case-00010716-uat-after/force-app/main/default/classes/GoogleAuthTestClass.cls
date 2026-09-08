@isTest(SeeAllData=true)
public class GoogleAuthTestClass {
	
    static testMethod void mytest(){
         Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
         pro.Name = 'Ultrasound Probe-Philips C5-1';
         pro.Probe_Type__c = 'Linear';
         insert pro;
         
          ProductItem__c prItem = new ProductItem__c (Product_Name__c=pro.Id,Model__c='Philips C5-1', Check_In_Type__c = 'Customer Repair',
                    Serial_No__c='B0K81J',Functional_Rating__c='B',Functional_Notes__c='Good',
                    Cosmetic_Rating__c='C',Cosmetic_Notes__c='Yellow Cable',/*Location__c='WIP',*/PO_Number__c='2425',
                    Other_Notes__c='Cable needs cleaned',Added_To_Opportunity__c = false,Receive_date__c=Date.parse('01/08/2015'));
        insert prItem;
        
        Account acc = TestDataFactory.createAccount(true);
         
        RecordType RC = [select id from  RecordType where SobjectType='opportunity' AND DeveloperName='Probe_Sales_Opportunity'];
        opportunity opp = new opportunity(Name='newopp',AccountId=acc.Id,CloseDate=Date.parse('12/13/2014'),StageName='Prospecting', RecordTypeID = RC.id);
        insert opp;
        
        pricebook2 pb = [select id from Pricebook2 where isStandard=true];
         
        PricebookEntry pbe = new PricebookEntry (Pricebook2Id=pb.id, Product2Id=pro.Id, IsActive=true, UnitPrice=100.00);
        insert pbe;
         
        OpportunityLineItem oppLine=new OpportunityLineItem(OpportunityId=opp.Id,Quantity=1,PricebookEntryId=pbe.Id, TotalPrice=500,ProductItem__c=prItem.ID);
        insert oppLine;
        
        RecordType rt = [select id from RecordType where DeveloperName = 'Customer_Repair_Evaluation'  ];
        RMA__c newRMA = new RMA__c(Approved_Repairs__c  = '', Declined_Repairs__c = '', RecordTypeId = rt.id, 
                              ProductItem__c = pritem.Id, Opportunity__c = Opp.id, Quality_Issue_Notes__c = 'TEST',
                                   Recommended_Repairs__c = 'Probe Handle Refurbishment', Required_Repairs__c = 'Lens Relens',
                                  Other_Notes_Cosmetic__c = 'Test', Other_Notes_Functional__c = 'Test', Endoscopy_Evaluation_Results__c = 'Test');
        insert newRMA;
        /*
        newRMA.Approved_Repairs__c = 'All Repairs Approved';
        update newRMA;*/
		
        
        
          Evaluation_Natalie__c e = new  Evaluation_Natalie__c (Associated_RMA__c=newRMA.id);
          insert e;
          
          ApexPages.currentPage().getParameters().put('id',e.Id);
          
          ApexPages.StandardController sc = new ApexPages.StandardController(e);      
          cGoogleAppAuthenticationWithSalesforce test = new cGoogleAppAuthenticationWithSalesforce(sc);
        test.DriveAuth();
         test.save();
    }
    
    
    private class RestMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = 'your Json Response';

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
    static testMethod void mytest2(){
         Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
         pro.Name = 'Ultrasound Probe-Philips C5-1';
         pro.Probe_Type__c = 'Linear';
         insert pro;
         
           ProductItem__c prItem = new ProductItem__c (Product_Name__c=pro.Id,Model__c='Philips C5-1',
                     Serial_No__c='B0K81J',Functional_Rating__c='B',Functional_Notes__c='Good', Check_In_Type__c = 'Customer Repair',
                     Cosmetic_Rating__c='C',Cosmetic_Notes__c='Yellow Cable',/*Location__c='WIP',*/PO_Number__c='2425',
                     Other_Notes__c='Cable needs cleaned',Added_To_Opportunity__c = false,Receive_date__c=Date.parse('01/08/2015'),
                     Image__c='https://example.invalid/folders/test-folder?resourcekey=test');
        insert prItem;
        
        Account acc = TestDataFactory.createAccount(true);
         
        RecordType RC = [select id from  RecordType where SobjectType='opportunity' AND DeveloperName='Probe_Sales_Opportunity'];
        opportunity opp = new opportunity(Name='newopp',AccountId=acc.Id,CloseDate=Date.parse('12/13/2014'),StageName='Prospecting', RecordTypeID = RC.id);
        insert opp;
        
        pricebook2 pb = [select id from Pricebook2 where isStandard=true];
         
        PricebookEntry pbe = new PricebookEntry (Pricebook2Id=pb.id, Product2Id=pro.Id, IsActive=true, UnitPrice=100.00);
        insert pbe;
         
        OpportunityLineItem oppLine=new OpportunityLineItem(OpportunityId=opp.Id,Quantity=1,PricebookEntryId=pbe.Id, TotalPrice=500,ProductItem__c=prItem.ID);
        insert oppLine;
        
        RecordType rt = [select id from RecordType where DeveloperName = 'Customer_Repair_Evaluation'  ];
        RMA__c newRMA = new RMA__c(Approved_Repairs__c  = '', Declined_Repairs__c = '', RecordTypeId = rt.id, 
                              ProductItem__c = pritem.Id, Opportunity__c = Opp.id, Quality_Issue_Notes__c = 'TEST', 
                              Recommended_Repairs__c = 'Probe Handle Refurbishment', Required_Repairs__c = 'Lens Relens', Depot_Repair__c = true,
                                  Other_Notes_Cosmetic__c = 'Test', Other_Notes_Functional__c = 'Test', Endoscopy_Evaluation_Results__c = 'Test');
        insert newRMA;
        /*
        newRMA.Approved_Repairs__c = 'All Repairs Approved';
        update newRMA;*/
		
        
        
          Evaluation_Natalie__c e = new  Evaluation_Natalie__c (Associated_RMA__c=newRMA.id);
          insert e;

          // A second record proves the OAuth callback does not use the former
          // "latest Evaluation modified by this user" fallback.
          Evaluation_Natalie__c competingEvaluation = new Evaluation_Natalie__c(Associated_RMA__c=newRMA.id);
          insert competingEvaluation;

          String callbackState = 'url=https://example.invalid/apex/AuthenticationGoogleDrive&evaluationId=' + e.Id;
          ApexPages.currentPage().getParameters().put('state', EncodingUtil.urlEncode(callbackState, 'UTF-8'));
        test.setMock(HttpCalloutMock.class, new RestMock());
        Test.StartTest();  
        
          ApexPages.StandardController sc = new ApexPages.StandardController(e);      
          cGoogleAppAuthenticationWithSalesforce testGoogle = new cGoogleAppAuthenticationWithSalesforce(sc);
        System.assertEquals(String.valueOf(e.Id), cGoogleAppAuthenticationWithSalesforce.itemid,
            'The callback must restore the exact Evaluation from OAuth state.');
        System.assertEquals('0BzmqJILtsGQ8NTZ3ZXBKYnE4U3c',
            cGoogleAppAuthenticationWithSalesforce.normalizeDriveFolderId('0BzmqJILtsGQ8NTZ3ZXBKYnE4U3c?resourcekey=test'),
            'The resource-key query string must not become part of the folder ID.');
        testGoogle.testFileMap = new Map<String, String>{'C-Lens.JPG' => 'test10', 'C-Cap.JPG' => 'test11', 'C-Whole.JPG' => 'test12',
            'C-SN.JPG' => 'test13', 'C-Damage 1.JPG' => 'test14', 'C-Damage 2.JPG' => 'test15', 'C-Damage 3.JPG' => 'test16',
            'F-Leakage Test.JPG' => 'test17', 'F-Phantom 1.JPG' => 'test18', 'F-Airscan.JPG' => 'test19', 'F-Phantom 2.JPG' => 'test20',
            'First Call.JPG' => 'test21', 'test10' => 'C-Lens.JPG', 'test11' => 'C-Cap.JPG', 'test12' => 'C-Whole.JPG'};
        testGoogle.testFileList = new List<String>{'test10', 'test11', 'test12'};
        testGoogle.DriveAuth();
        
        testGoogle.AccessToken();
        testGoogle.ListFiles();

        // Exercise the valid dated-subfolder path independently of the direct-image path.
        testGoogle.DriveFolder = 'root-folder';
        testGoogle.FileIdAndNameMapFortheAccount = new Map<String, String>();
        testGoogle.FileNameAndIdMapFortheAccount = new Map<String, String>();
        testGoogle.testFileList = new List<String>{'folder-key'};
        testGoogle.testFileMap = new Map<String, String>{
            'folder-key' => '240101 Images',
            '240101 Images' => 'folder-key'
        };
        testGoogle.ListFiles();
        testGoogle.LensID = 'case-00010716';
        testGoogle.CapID = 'cap-image';
        testGoogle.Damage1 = 'case-00010716';
        testGoogle.save();
        
        Test.StopTest();

        Map<Id, Evaluation_Natalie__c> savedEvaluations = new Map<Id, Evaluation_Natalie__c>([
            SELECT Id, Lens_ID__c
            FROM Evaluation_Natalie__c
            WHERE Id IN :new Set<Id>{e.Id, competingEvaluation.Id}
        ]);
        System.assertEquals('case-00010716', savedEvaluations.get(e.Id).Lens_ID__c,
            'The intended Evaluation must be updated after the OAuth callback.');
        System.assertEquals(null, savedEvaluations.get(competingEvaluation.Id).Lens_ID__c,
            'A newer Evaluation must not be selected by accident.');
    }
    static testMethod void mytest3(){
         Product2 pro = TestDataFactory.createProduct('Instrument Tray', false);
         pro.Name = 'Instrument Tray';
         insert pro;
         
          ProductItem__c prItem = new ProductItem__c (Product_Name__c=pro.Id, Check_In_Type__c = 'Customer Repair',
                    Serial_No__c='B0K81J',Functional_Rating__c='B',Functional_Notes__c='Good',
                    Cosmetic_Rating__c='C',Cosmetic_Notes__c='Yellow Cable',/*Location__c='WIP',*/PO_Number__c='2425',
                    Other_Notes__c='Cable needs cleaned',Added_To_Opportunity__c = false,Receive_date__c=Date.parse('01/08/2015'));
        insert prItem;
        
        ProductTest.TestWrapperClass result = ProductTest.createProductTest(prItem.Id);
        
        ProductTest__c pt = new ProductTest__c(
            recordTypeId = result.recordTypeId,
            Name = result.name,
            Product_Item__c = result.Product_Item,
            Created_from_Override__c = true,
            Test_Completed_By__c = 'Yasmina Rodriguez',
            Last_4_Characters_of_SN__c = '1234',
            Functional_Rating__c = 'Fair'
        );
        
        insert pt;
        
        Product_Test_Line_Item__c ptli = new Product_Test_Line_Item__c(ProductTest__c = pt.id, Quantity__c = 1, Complaint__c = 'Test', Repairs_Needed__c = 'Test', Repair_Price__c = 100);
        insert ptli;
        
        Account acc = TestDataFactory.createAccount(true);
         
        RecordType RC = [select id from  RecordType where SobjectType='opportunity' AND DeveloperName='Endoscopy_Repair_Opportunity'];
        opportunity opp = new opportunity(Name='newopp',AccountId=acc.Id,CloseDate=Date.parse('12/13/2014'),StageName='Prospecting', RecordTypeID = RC.id);
        insert opp;
        
        pricebook2 pb = [select id from Pricebook2 where isStandard=true];
         
        PricebookEntry pbe = new PricebookEntry (Pricebook2Id=pb.id, Product2Id=pro.Id, IsActive=true, UnitPrice=100.00);
        insert pbe;
         
        OpportunityLineItem oppLine=new OpportunityLineItem(OpportunityId=opp.Id,Quantity=1,PricebookEntryId=pbe.Id, TotalPrice=500,ProductItem__c=prItem.ID);
        insert oppLine;
        
        RecordType rt = [select id from RecordType where DeveloperName = 'Customer_Repair_Evaluation'  ];
        RMA__c newRMA = new RMA__c(Approved_Repairs__c  = '', Declined_Repairs__c = '', RecordTypeId = rt.id, 
                              ProductItem__c = pritem.Id, Opportunity__c = Opp.id, Quality_Issue_Notes__c = 'TEST',
                                  Other_Notes_Cosmetic__c = 'Test', Other_Notes_Functional__c = 'Test', Endoscopy_Evaluation_Results__c = 'Test');
        insert newRMA;
        /*
        newRMA.Approved_Repairs__c = 'All Repairs Approved';
        update newRMA;*/
		
        
        
          Evaluation_Natalie__c e = new  Evaluation_Natalie__c (Associated_RMA__c=newRMA.id);
          insert e;
          
          ApexPages.currentPage().getParameters().put('id',e.Id);
          
          ApexPages.StandardController sc = new ApexPages.StandardController(e);      
          cGoogleAppAuthenticationWithSalesforce test = new cGoogleAppAuthenticationWithSalesforce(sc);
        test.DriveAuth();
         test.save();
    }

    @isTest
    static void case00010716RejectsMissingOrInvalidCallbackState() {
        Test.setCurrentPage(new PageReference('/apex/AuthenticationGoogleDrive'));

        ApexPages.StandardController standardController =
            new ApexPages.StandardController(new Evaluation_Natalie__c());
        cGoogleAppAuthenticationWithSalesforce controller =
            new cGoogleAppAuthenticationWithSalesforce(standardController);

        System.assertEquals(null, controller.DriveAuth(),
            'Authentication must not start without a specific Evaluation.');
        System.assertEquals(null, controller.save(),
            'A callback without an Evaluation must fail safely rather than dereference null.');
        controller.DriveFolder = null;
        System.assertEquals(null, controller.ListFiles(),
            'A missing Drive folder must fail safely rather than make a callout.');
        System.assert(ApexPages.getMessages().size() > 0,
            'The page must provide a user-readable error.');

        System.assertEquals(null,
            cGoogleAppAuthenticationWithSalesforce.getEvaluationIdFromState(null));
        System.assertEquals(null,
            cGoogleAppAuthenticationWithSalesforce.getEvaluationIdFromState('evaluationId=not-an-id'));
        System.assertEquals(null,
            cGoogleAppAuthenticationWithSalesforce.getEvaluationIdFromState('%ZZ'));
        System.assertEquals(null,
            cGoogleAppAuthenticationWithSalesforce.getEvaluationIdFromState(
                'evaluationId=' + UserInfo.getUserId()));
        System.assertEquals(null,
            cGoogleAppAuthenticationWithSalesforce.getEvaluationIdFromState('other=value'));
        System.assertEquals(null,
            cGoogleAppAuthenticationWithSalesforce.normalizeDriveFolderId(null));
        System.assertEquals('folder-id',
            cGoogleAppAuthenticationWithSalesforce.normalizeDriveFolderId(
                'https://drive.google.com/drive/folders/folder-id?resourcekey=test'));
        System.assertEquals('folder-id',
            cGoogleAppAuthenticationWithSalesforce.normalizeDriveFolderId('folder-id/child'));
        cGoogleAppAuthenticationWithSalesforce.required = new List<String>{'required-test'};
        cGoogleAppAuthenticationWithSalesforce.recommended = new List<String>{'recommended-test'};
        cGoogleAppAuthenticationWithSalesforce.images = new List<String>{'image-test'};
        controller.callfunc = 'callback-test';
        controller.eitemid = 'evaluation-test';
        System.assertEquals('required-test', cGoogleAppAuthenticationWithSalesforce.required[0]);
        System.assertEquals('recommended-test', cGoogleAppAuthenticationWithSalesforce.recommended[0]);
        System.assertEquals('image-test', cGoogleAppAuthenticationWithSalesforce.images[0]);
        System.assertEquals('callback-test', controller.callfunc);
        System.assertEquals('evaluation-test', controller.eitemid);
    }
    
    
  
}