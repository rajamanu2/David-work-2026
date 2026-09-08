@isTest
private class WorkOrderLineItemServicesTest {

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
        insert listProducts;
        
    	//Create Pricebook Entries for Products
    	List<PriceBookEntry> listPriceBookEntries = new List<PriceBookEntry>();
    	PriceBookEntry pbe1 = testDataFactory.createPricebookEntry(p1.id, false);
        listPriceBookEntries.add(pbe1);
        PriceBookEntry pbe2 = testDataFactory.createPricebookEntry(p2.id, false);
        listPriceBookEntries.add(pbe2);
        PriceBookEntry pbe3 = testDataFactory.createPricebookEntry(p4.id, false);
        listPriceBookEntries.add(pbe3);
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
        pi2.Generic_Product__c = true;
        pi2.Cost__c = NULL;
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
        insert listProductItems;
        
        // Create Business Units
        //List<Account> BUsToInsert = testDataFactory.createAccounts(3, false);
        //BUsToInsert[0].Name = 'Probo Medical - Tulsa';
        //BUsToInsert[1].Name = 'MedCorp LLC';
        //BUsToInsert[2].Name = 'Probo Medical - Indy';
        //insert BUsToInsert;
        
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
        //o1.RecordTypeId = WorkOrderLineItemServices.salesRecordTypeId;
        listOpportunities.add(o1);
        Opportunity o2 = testDataFactory.createOpportunity('Purchasing Opportunity', a.Id, false);
        o2.Name = 'TestPurchasingOpp';
        o2.Opportunity_Notes__c = 'Test Purchasing';
        o2.Pricebook2Id = stdPB;
        o2.Repair_Evaluation_Serial_Number__c = '78910';
        o2.Ship_Date__c = date.today() + 30;
        o2.CloseDate = date.today()+15;
        o2.Verified_Asset_and_Serial_Numbers_Match__c = true;
        //o2.RecordTypeId = WorkOrderLineItemServices.purchasingRecordTypeId;
        listOpportunities.add(o2);
        insert listOpportunities;
        
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
    	
    }

   static testmethod void testCreateWorkOrderLineItemsSalesOpp() {
       Map<String, Object> queryParams = new Map<String, Object>();
       Account a = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
       Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = 'TestSalesOpp' LIMIT 1];
       Product2 p = [SELECT Id, Name FROM Product2 WHERE Name = 'Acer Y9' LIMIT 1];
       ProductItem__c pItem = [SELECT Id, Name, Price__c FROM ProductItem__c WHERE Product_Name__c =: p.Id LIMIT 1];
       List<Map<String, Object>> listSelectedItems = new List<Map<String, Object>>();
       List<String> listSwapItems = new List<String>();
       List<Map<String, Object>> listPurchasingItems = new List<Map<String, Object>>();
       Map<String, Object> productItemRecord = new Map<String, Object>();
       Id workOrderId;
       sObject sWO = [SELECT Id, WorkOrderNumber, ServiceContractId, ServiceContract.Opportunity__c FROM WorkOrder WHERE AccountId =: a.Id LIMIT 1];
       workOrderId = (Id)sWO.get('Id');
       
       productItemRecord.put('id', pItem.Id);
       productItemRecord.put('price', pItem.Price__c);
       productItemRecord.put('cost', 1000.00);
       productItemRecord.put('exchange', false);
       
       listSelectedItems.add(productItemRecord);
       
       test.startTest();
       WorkOrderLineItemServices.createWorkOrderLineItems(listSelectedItems, listPurchasingItems, opp.Id, workOrderId);
       test.stopTest();
       
       List<WorkOrderLineItem> listWoli = [SELECT Id, Part_Used__c, Part_Name__c, UnitPrice, Sales_Opportunity__c FROM WorkOrderLineItem WHERE WorkOrderId =: workOrderId];
       system.assertEquals(1, listWoli.size(), 'Work Order line item size is not equal to 1');
       system.assertEquals(pItem.Id, listWoli[0].Part_Used__c, 'Work Order line part used is not equal to Product Item Id');
       system.assertEquals(pItem.Price__c, listWoli[0].UnitPrice, 'Work Order line item price is not equal to Product Item Price');
	   system.assertEquals(p.Id, listWoli[0].Part_Name__c, 'Work Order line part name is not equal to Product Id');       
       //system.assertEquals(opp.Id, listWoli[0].Sales_Opportunity__c, 'Work Order line sales Opportunity line does not match Opportunity Id');
       
   }
    
   static testmethod void testCreateWorkOrderLineItemsPurchasingOpp() {
       Map<String, Object> queryParams = new Map<String, Object>();
       Account a = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
       Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = 'TestPurchasingOpp' LIMIT 1];
       Product2 p = [SELECT Id, Name FROM Product2 WHERE Name = 'Connair C4-9T' LIMIT 1];
       ProductItem__c pItem = [SELECT Id, Name, Price__c FROM ProductItem__c WHERE Product_Name__c =: p.Id LIMIT 1];
       ServiceContract sc = [SELECT Id, Name,Opportunity__c FROM ServiceContract WHERE AccountId =: a.Id LIMIT 1];
       List<Map<String, Object>> listSelectedItems = new List<Map<String, Object>>();
       List<String> listSwapItems = new List<String>();
       List<Map<String, Object>> listPurchasingItems = new List<Map<String, Object>>();
       Map<String, Object> productItemRecord = new Map<String, Object>();
       Id workOrderId;
       sObject sWO = [SELECT Id, WorkOrderNumber, ServiceContractId, ServiceContract.Opportunity__c FROM WorkOrder WHERE AccountId =: a.Id LIMIT 1];
       workOrderId = (Id)sWO.get('Id');
       
       sc.Opportunity__c = opp.Id;
       update sc;
       
       productItemRecord.put('id', pItem.Id);
       productItemRecord.put('price', pItem.Price__c);
       productItemRecord.put('exchange', false);
       listPurchasingItems.add(productItemRecord);
       
       test.startTest();
       WorkOrderLineItemServices.createWorkOrderLineItems(listSelectedItems, listPurchasingItems, opp.Id, workOrderId);
       test.stopTest();
       
       List<WorkOrderLineItem> listWoli = [SELECT Id, Part_Used__c, Part_Name__c, UnitPrice, Purchasing_Opportunity__c FROM WorkOrderLineItem WHERE WorkOrderId =: workOrderId];
       system.assertEquals(1, listWoli.size(), 'Work Order line item size is not equal to 1');
       system.assertEquals(pItem.Id, listWoli[0].Part_Used__c, 'Work Order line part used is not equal to Product Item Id');
       system.assertEquals(pItem.Price__c, listWoli[0].UnitPrice, 'Work Order line item price is not equal to Product Item Price');
	   system.assertEquals(p.Id, listWoli[0].Part_Name__c, 'Work Order line part name is not equal to Product Id');       
       
   }
    
    @IsTest
    static void testDeleteWorkOrderLineItem() {
        Account a = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestSalesOpp' LIMIT 1];
        Product2 p = [SELECT Id FROM Product2 WHERE Name = 'Acer Y9' LIMIT 1];
        ProductItem__c pItem = [SELECT Id, Price__c FROM ProductItem__c WHERE Product_Name__c = :p.Id LIMIT 1];
        sObject sWO = [SELECT Id FROM WorkOrder WHERE AccountId = :a.Id LIMIT 1];
        Id workOrderId = (Id)sWO.get('Id');

        List<Map<String, Object>> listSelectedItems = new List<Map<String, Object>>();
        List<Map<String, Object>> listPurchasingItems = new List<Map<String, Object>>();
        Map<String, Object> productItemRecord = new Map<String, Object>();
        productItemRecord.put('id', pItem.Id);
        productItemRecord.put('price', pItem.Price__c);
        productItemRecord.put('cost', 1000.00);
        productItemRecord.put('exchange', false);
        listSelectedItems.add(productItemRecord);
        WorkOrderLineItemServices.createWorkOrderLineItems(listSelectedItems, listPurchasingItems, opp.Id, workOrderId);

        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId = :workOrderId LIMIT 1];

        Test.startTest();
        String result = WorkOrderLineItemServices.deleteWorkOrderLineItem(woli.Id);
        Test.stopTest();

        System.assertEquals('success', result, 'deleteWorkOrderLineItem should return success');
        List<WorkOrderLineItem> remaining = [SELECT Id FROM WorkOrderLineItem WHERE Id = :woli.Id];
        System.assertEquals(0, remaining.size(), 'WorkOrderLineItem should have been deleted');
    }

    @IsTest
    static void testGetWorkOrderItems_noAssert() {
        // Reuse WO from @testSetup
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
    
        Test.startTest();
        List<WorkOrderLineItem> rows = WorkOrderLineItemServices.getWorkOrderItems(wo.Id);
        Test.stopTest();
    
        // Touch returned fields to exercise access paths (no asserts as requested)
        for (WorkOrderLineItem r : rows) {
            String a = r.Part_Name_D__c;
            String b = r.Part_Number_D__c;
            String c = (r.Product2 != null) ? r.Product2.Name : null;
            String d = (r.PricebookEntry != null && r.PricebookEntry.Product2 != null)
                ? r.PricebookEntry.Product2.Name : null;
        }
    }


}