@isTest
public class AddProductServicesTest {
	@testSetup
    static void setup() {
    	//Get Standard Price Book
    	Id stdPB = ProboCommonUtils.getStdPricebookId();
        system.debug('TEST: standard price book id: '+stdPB);
        
    	//Create Products
    	List<Product2> listProducts = new List<Product2>();
    	Product2 p1 = testDataFactory.createProduct('Ultrasound Probe','Acer Y9','Ultrasound Probe', false);
        listProducts.add(p1);
        Product2 p2 = testDataFactory.createProduct('Ultrasound Probe','Sony BZ3','Ultrasound Probe', false);
        listProducts.add(p2);
        Product2 p3 = testDataFactory.createProduct('Ultrasound Probe','Sony BZ3','Ultrasound Probe', false);
        listProducts.add(p3);
    	Product2 p4 = testDataFactory.createProduct('Ultrasound Probe','Connair C4-9T','Ultrasound Probe', false);
        listProducts.add(p4);
        Product2 p5 = testDataFactory.createProduct('Part','Siemens 8V','Ultrasound Part', false);
        p5.Part_Number__c = '32958821';
        p5.OEM__c = 'Siemens_Healthineers';
        p5.Part_Type__c = 'Assembly';
        p5.Modality__c = 'Ultrasound';
        p5.Compatible_System_OEM__c = 'Siemens Healthineers';
        p5.Compatible_System_Model__c = 'Premium Edition';
        p5.Compatible_System_Family__c = 'Antares';
        p5.Compatible_System_Software_Version__c = '4.0';
        listProducts.add(p5);
        insert listProducts;
        
    	//Create Pricebook Entries for Products
    	List<PriceBookEntry> listPriceBookEntries = new List<PriceBookEntry>();
    	PriceBookEntry pbe1 = testDataFactory.createPricebookEntry(p1.id, false);
        listPriceBookEntries.add(pbe1);
        PriceBookEntry pbe2 = testDataFactory.createPricebookEntry(p2.id, false);
        listPriceBookEntries.add(pbe2);
        PriceBookEntry pbe3 = testDataFactory.createPricebookEntry(p3.id, false);
        listPriceBookEntries.add(pbe3);
        PriceBookEntry pbe4 = testDataFactory.createPricebookEntry(p4.id, false);
        listPriceBookEntries.add(pbe4);
        PriceBookEntry pbe5 = testDataFactory.createPricebookEntry(p5.id, false);
        listPriceBookEntries.add(pbe5);
        insert listPriceBookEntries;
        
        //Create Product Items
        List<ProductItem__c> listProductItems = new List<ProductItem__c>();
        ProductItem__c pi1 = testDataFactory.createProductItem(p1.id, false); 
        pi1.Check_In_Type__c = 'Purchase';
        pi1.Generic_Product__c = false;
        pi1.Location__c = 'QA-Testing';
        pi1.Functional_Rating__c = 'Good';
        pi1.Cosmetic_Rating__c = 'Good';
        pi1.Review_Status__c = 'Finished Goods';
        pi1.Domestic_Only__c = true;
        pi1.Purchasing_Approved__c = true;
        pi1.Posted_on_Ebay__c = false;
        pi1.Reserved__c = false;
        listProductItems.add(pi1);
        ProductItem__c pi2 = testDataFactory.createProductItem(p2.id, false); 
        pi2.Check_In_Type__c = 'Generic';
        pi2.Cost__c = 0;
        pi2.Generic_Product__c = true;
        listProductItems.add(pi2);
        ProductItem__c pi3 = testDataFactory.createProductItem(p3.id, false); 
        pi3.Check_In_Type__c = 'Purchase';
        pi3.Generic_Product__c = false;
        pi3.Location__c = 'QA-Testing';
        pi3.Functional_Rating__c = 'Good';
        pi3.Cosmetic_Rating__c = 'Good';
        pi3.Review_Status__c = 'Finished Goods';
        pi3.Domestic_Only__c = true;
        pi3.Purchasing_Approved__c = true;
        pi3.Posted_on_Ebay__c = false;
        pi3.Reserved__c = false;
        listProductItems.add(pi3);
        ProductItem__c pi4 = testDataFactory.createProductItem(p4.id, false); 
        pi4.Check_In_Type__c = 'Purchase';
        pi4.Generic_Product__c = false;
        pi4.Location__c = 'QA-Testing';
        pi4.Functional_Rating__c = 'Good';
        pi4.Cosmetic_Rating__c = 'Good';
        pi4.Review_Status__c = 'Finished Goods';
        pi4.Domestic_Only__c = true;
        pi4.Purchasing_Approved__c = true;
        pi4.Posted_on_Ebay__c = false;
        pi4.Reserved__c = false;
        listProductItems.add(pi4);
        ProductItem__c pi5 = testDataFactory.createProductItem(p5.id, false); 
        pi5.Check_In_Type__c = 'Purchase';
        pi5.Generic_Product__c = false;
        pi5.Location__c = 'QA-Testing';
        pi5.Functional_Rating__c = 'Good';
        pi5.Cosmetic_Rating__c = 'Good';
        pi5.Review_Status__c = 'Finished Goods';
        pi5.Domestic_Only__c = true;
        pi5.Purchasing_Approved__c = true;
        pi5.Posted_on_Ebay__c = false;
        pi5.Reserved__c = false;
        listProductItems.add(pi5);
        insert listProductItems;
        
    	//Create Customer Account
    	Account a = testDataFactory.createAccount(false);
		a.Name = 'Test Account';
        insert a;
        
    	//Create Opportunities
    	List<Opportunity> listOpportunities = new List<Opportunity>();
    	Opportunity o1 = testDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, false);
        o1.Name = 'TestSalesOpp';
        o1.Opportunity_Notes__c = 'This is what needs to be done';
        o1.Pricebook2Id = stdPB;
        o1.Repair_Evaluation_Serial_Number__c = '123456';
        o1.Ship_Date__c = date.today() + 30;
        o1.CloseDate = date.today()+15;
        o1.Verified_Asset_and_Serial_Numbers_Match__c = true;
        listOpportunities.add(o1);
        Opportunity o2 = testDataFactory.createOpportunity('External Repair / Testing', a.Id, false);
        o2.Name = 'TestRepairOpp';
        o2.Opportunity_Notes__c = 'Test Repair';
        o2.Pricebook2Id = stdPB;
        o2.Repair_Evaluation_Serial_Number__c = '78910';
        o2.Ship_Date__c = date.today() + 30;
        o2.CloseDate = date.today()+15;
        o2.Verified_Asset_and_Serial_Numbers_Match__c = true;
	    listOpportunities.add(o2);        
        Opportunity o3 = testDataFactory.createOpportunity('Rental Opportunity', a.Id, false);
        o3.Name = 'TestRentalOpp';
        o3.Opportunity_Notes__c = 'Test Rental';
        o3.Pricebook2Id = stdPB;
        o3.Repair_Evaluation_Serial_Number__c = '54612';
        o3.Ship_Date__c = date.today() + 30;
        o3.CloseDate = date.today()+15;
        o3.Verified_Asset_and_Serial_Numbers_Match__c = true;
        listOpportunities.add(o3);
        insert listOpportunities;
         
    	//Add Opportunity Products
    	OpportunityLineItem oli = testDataFactory.createOpportunityLineItem(o1.id, pbe2.Id, pi2.Id, false);
        insert oli;
        
        //Create Service Contract
        ServiceContract sc = new ServiceContract();
        sc.AccountId = a.Id;
        sc.Opportunity__c = o1.Id;
        sc.Name = 'Test Service Contract';
        insert sc;
        
    	//Create Work Order
    	Schema.SObjectType workOrderType = Schema.getGlobalDescribe().get('WorkOrder');
        sObject sWo = workOrderType.newSObject(); 
        sWo.put('AccountId', a.Id);
        sWo.put('ServiceContractId', sc.Id);
        insert sWo;
        
        //Create Loaner
        Loaner__c lo = new Loaner__c();
        lo.Repair_Opportunity__c = o2.Id;
        insert lo;
        
        //Create Rental Order
        Rental_Order__c ro = new Rental_Order__c();
        ro.Opportunity__c = o3.Id;
        insert ro;

    }
    
   static testmethod void testGetProducts() {
       Map<String, Object> queryParams = new Map<String, Object>();
       Opportunity opp = [SELECT id, name FROM Opportunity WHERE name = 'TestSalesOpp' LIMIT 1];
       Product2 p = [SELECT Id, Name FROM Product2 WHERE Name = 'Acer Y9' LIMIT 1];
       ProductItem__c pItem = [SELECT Id, Name, Product_Name__c FROM ProductItem__c WHERE Product_Name__c =: p.Id LIMIT 1];
       
       queryParams.put('partsOnly', false);
       queryParams.put('queryString', 'Acer Y9');
       List<String> listFamily = new List<String>();
       listFamily.add('Ultrasound Probe');
       queryParams.put('family', listFamily);
       List<String> listRating = new List<String>();
       listRating.add('Good');
       queryParams.put('functionalRating', listRating);
       queryParams.put('cosmeticRating', listRating);
       List<String> listCheckInType = new List<String>();
       listCheckInType.add('Purchase');
       queryParams.put('checkInType', listCheckInType);
       List<String> listReviewStatus = new List<String>();
       listReviewStatus.add('Finished Goods');
       queryParams.put('reviewStatus', listReviewStatus);
       queryParams.put('domestic', true);
       queryParams.put('available', true);
       List<Object> listObjects = new List<Object>();                
       
       test.startTest();
       listObjects = AddProductServices.getProducts(queryParams);
       test.stopTest();
       
       system.assertEquals(1, listObjects.size(), 'Product Item list size not equal to 1');
       ProductItem__c pItem1 = (ProductItem__c)listObjects[0];
       system.assertEquals(pItem.Product_Name__c, pItem1.Product_Name__c, 'Product Item product name does not match');
   }    

   static testmethod void testGetProductsPartsOnly() {
       Map<String, Object> queryParams = new Map<String, Object>();
       Opportunity opp = [SELECT id, name FROM Opportunity WHERE name = 'TestSalesOpp' LIMIT 1];
       Product2 p = [SELECT Id, Name, OEM__c, Part_Type__c, Modality__c FROM Product2 WHERE Name = 'Siemens 8V' LIMIT 1];
       ProductItem__c pItem = [SELECT Id, Name, Product_Name__c FROM ProductItem__c WHERE Product_Name__c =: p.Id LIMIT 1];
       
       queryParams.put('partsOnly', true);
       List<String> listRating = new List<String>();
       listRating.add('Good');
       queryParams.put('functionalRating', listRating);
       queryParams.put('cosmeticRating', listRating);
       List<String> listCheckInType = new List<String>();
       listCheckInType.add('Purchase');
       queryParams.put('checkInType', listCheckInType);
       List<String> listReviewStatus = new List<String>();
       listReviewStatus.add('Finished Goods');
       queryParams.put('reviewStatus', listReviewStatus);
       queryParams.put('domestic', true);
       queryParams.put('available', true);
       
       queryParams.put('compatibleSystemOEM', 'Siemens Healthineers');
       queryParams.put('compatibleSystemFamily', 'Antares');
       queryParams.put('compatibleSystemModel', 'Premium Edition');
       queryParams.put('compatibleSystemSoftwareVersion', '4.0');
       queryParams.put('oem', 'Siemens_Healthineers');
       queryParams.put('partType', 'Assembly');
       queryParams.put('modality', 'Ultrasound');
       List<Object> listObjects = new List<Object>();                
       
       test.startTest();
       listObjects = AddProductServices.getProducts(queryParams);
       test.stopTest();
       
       system.assertEquals(1, listObjects.size(), 'Product Item list size not equal to 1');
       ProductItem__c pItem1 = (ProductItem__c)listObjects[0];
       system.assertEquals(pItem.Product_Name__c, pItem1.Product_Name__c, 'Product Item product name does not match');
   }    

    
   static testmethod void testGetOpportunityInfo() {
       Opportunity opp = [SELECT id, name FROM Opportunity WHERE name = 'TestSalesOpp' LIMIT 1];
       Map<String, String> opportunityMap = new Map<String, String>();
       Object o;
       
       test.startTest();
       o = AddProductServices.getOpportunityInfo(opp.Id);
       test.stopTest();
       
       opportunityMap = (Map<String, String>) o;
       
       system.assertEquals('Probe_Sales_Opportunity', opportunityMap.get('recordTypeName'), 'Record type name is not equal to Probe_Sales_Opportunity');
   }
    
   static testmethod void testGetWorkOrderInfo() {
       Account a = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
       Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = 'TestSalesOpp' LIMIT 1];
       ServiceContract sc = [SELECT Id, Name FROM ServiceContract WHERE Opportunity__c =: opp.Id LIMIT 1];
       Id workOrderId;
       sObject sWO = [SELECT Id, WorkOrderNumber, ServiceContractId, ServiceContract.Opportunity__c FROM WorkOrder WHERE AccountId =: a.Id LIMIT 1];
       workOrderId = (Id)sWO.get('Id');
       Map<String, String> workOrderInfo = new Map<String, String>();

       test.startTest();
       workOrderInfo = (Map<String, String>)AddProductServices.getWorkOrderInfo(workOrderId);
       test.stopTest();
       
       system.assert(!workOrderInfo.isEmpty(), 'Work Order info not retrieved');
       system.assertEquals(sc.Id, workOrderInfo.get('serviceContractId'),'Work Order Service Contract Id does not match Service Contract Id'); 
       system.assertEquals(opp.Id, workOrderInfo.get('oppId'), 'Work Order Opportunity Id does not match Opportunity Id');
   }    

   static testmethod void testGetLoanerInfo() {
       Account a = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
       Opportunity opp = [SELECT Id, Name, RecordTypeId FROM Opportunity WHERE Name = 'TestRepairOpp' LIMIT 1];
       Loaner__c lo = [SELECT Id, Name FROM Loaner__c WHERE Repair_Opportunity__c =: opp.Id LIMIT 1];
       Map<String, String> loanerInfo = new Map<String, String>();
       
       test.startTest();
       loanerInfo = (Map<String, String>)AddProductServices.getLoanerInfo(lo.Id);
       test.stopTest();

	   system.assert(!loanerInfo.isEmpty(), 'Loaner info not retrieved');    
       system.assertEquals(lo.Name, loanerInfo.get('name'),'Loaner name does not match'); 
       system.assertEquals(opp.Id, loanerInfo.get('oppId'), 'Loaner Opportunity Id does not match Opportunity Id');
    }  
    
    
    static testmethod void testRentalOrderInfo() {
       Account a = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
       Opportunity opp = [SELECT Id, Name, RecordTypeId FROM Opportunity WHERE Name = 'TestRentalOpp' LIMIT 1];
       Rental_Order__c ro = [SELECT Id, Name FROM Rental_Order__c WHERE Opportunity__c =: opp.Id LIMIT 1];
       Map<String, String> rentalOrderInfo = new Map<String, String>();
        
       test.startTest();
       rentalOrderInfo = (Map<String, String>)AddProductServices.getRentalOrderInfo(ro.Id);
       test.stopTest(); 
        
       system.assert(!rentalOrderInfo.isEmpty(), 'Rental order info not retrieved');    
       system.assertEquals(ro.Name, rentalOrderInfo.get('name'),'Rental order name does not match'); 
       system.assertEquals(opp.Id, rentalOrderInfo.get('oppId'), 'Rental order Opportunity Id does not match Opportunity Id'); 
   }    
    
   static testmethod void testCheckPriceFieldAccess() {
       String fieldAccess;
       
       test.startTest();
       fieldAccess = AddProductServices.checkPriceFieldAccess();
       test.stopTest();
       
       system.assertNotEquals(null, fieldAccess, 'No field access returned');
   }

   static testmethod void testCheckCostFieldAccess() {
       String fieldAccess;
       
       test.startTest();
       fieldAccess = AddProductServices.checkCostFieldAccess();
       test.stopTest();
       
       system.assertNotEquals(null, fieldAccess, 'No field access returned');
   }   
    
   static testmethod void testGetPickListOptions() {
       Map<String, List<String>> options = new Map<String, List<String>>(); 
       
       test.startTest();
       options = (Map<String, List<String>>) AddProductServices.getPickListOptions();
       test.stopTest();
       
       system.assertNotEquals(null, options, 'No picklist values returned');
       
   }   

}