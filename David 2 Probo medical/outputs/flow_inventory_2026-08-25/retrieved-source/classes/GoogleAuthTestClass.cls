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
                              Recommended_Repairs__c = 'Probe Handle Refurbishment', Required_Repairs__c = 'Lens Relens', Depot_Repair__c = true,
                                  Other_Notes_Cosmetic__c = 'Test', Other_Notes_Functional__c = 'Test', Endoscopy_Evaluation_Results__c = 'Test');
        insert newRMA;
        /*
        newRMA.Approved_Repairs__c = 'All Repairs Approved';
        update newRMA;*/
		
        
        
          Evaluation_Natalie__c e = new  Evaluation_Natalie__c (Associated_RMA__c=newRMA.id);
          insert e;
        
          //apexPages.currentPage().getParameters().put('id',e.Id);
        test.setMock(HttpCalloutMock.class, new RestMock());
        Test.StartTest();  
        
          ApexPages.StandardController sc = new ApexPages.StandardController(e);      
          cGoogleAppAuthenticationWithSalesforce testGoogle = new cGoogleAppAuthenticationWithSalesforce(sc);
        testGoogle.testFileMap = new Map<String, String>{'C-Lens.JPG' => 'test10', 'C-Cap.JPG' => 'test11', 'C-Whole.JPG' => 'test12',
            'C-SN.JPG' => 'test13', 'C-Damage 1.JPG' => 'test14', 'C-Damage 2.JPG' => 'test15', 'C-Damage 3.JPG' => 'test16',
            'F-Leakage Test.JPG' => 'test17', 'F-Phantom 1.JPG' => 'test18', 'F-Airscan.JPG' => 'test19', 'F-Phantom 2.JPG' => 'test20',
            'First Call.JPG' => 'test21', 'test10' => 'newtest', 'test11' => 'newtest2', 'test12' => 'newtest3'};
        testGoogle.testFileList = new List<String>{'test10', 'test11', 'test12'};
        testGoogle.DriveAuth();
        
        testGoogle.AccessToken();
        testGoogle.ListFiles();
        testGoogle.save();
        
        Test.StopTest();
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
    
    
  
}