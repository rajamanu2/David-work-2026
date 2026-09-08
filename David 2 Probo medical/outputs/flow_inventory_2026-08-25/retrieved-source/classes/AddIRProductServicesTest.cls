@isTest
private class AddIRProductServicesTest {

	@testSetup
    static void setup() {
    	//Create Products
    	List<Product2> listProducts = new List<Product2>();
    	Product2 p1 = testDataFactory.createProduct('Part','Misc Part','Part', false);
        listProducts.add(p1);
        Product2 p2 = testDataFactory.createProduct('Ultrasound Probe','Acer Y9','Ultrasound Probe', false);
        listProducts.add(p2);
        insert listProducts;
        
        //Create Customer Account
    	Account a = testDataFactory.createAccount(false);
		a.Name = 'Test Account';
        insert a;
        
        //Create Opp
        Opportunity o1 = testDataFactory.createOpportunity('Purchasing Opportunity', a.Id, true);
        
        
        //Create IR
        Item_Receipt__c IR = new Item_Receipt__c(Opportunity__c = o1.id);
        insert IR;
        
        //Create IR Products
        List<IR_Product__c> listIRProducts = new List<IR_Product__c>();
        IR_Product__c irp1 = new IR_Product__c(Item_Receipt__c = IR.id, Lot_Number__c = 'Test123', Product2__c = p1.id, Quantity_Remaining__c = 5);
        listIRProducts.add(irp1);
        IR_Product__c irp2 = new IR_Product__c(Item_Receipt__c = IR.id, Lot_Number__c = 'Test111', Product2__c = p1.id, Quantity_Remaining__c = 5);
        listIRProducts.add(irp2);
        insert listIRProducts;
        
        // Create Product Item
        ProductItem__c pi1 = testDataFactory.createProductItem(p2.id, false);
        pi1.Check_In_Type__c = 'Purchase';
        insert pi1;
        
        //Create Product Repair
        Product_Repair__c pr1 = new Product_Repair__c(Product_Item__c = pi1.id, Repair_Activity__c = 'Tubing Replacement');
        insert pr1;
        system.debug('THIS IS THE PR1 >> ' + pr1);
        
        //Create PRLI
        Product_Repair_Line_Item__c prli1 = new Product_Repair_Line_Item__c(Product_Repair__c = pr1.id, IR_Product__c = irp1.id, Quantity__c = 2);
        insert prli1;
      
        
    }
    
   static testmethod void testGetProducts() {
       Map<String, Object> queryParams = new Map<String, Object>();
  	   IR_Product__c ir1 = [select Id, Name, Product_Name__c FROM IR_Product__c WHERE Product_Name__c = 'Misc Part' LIMIT 1];
       queryParams.put('queryString', 'Misc');
       
       List<Object> listObjects = new List<Object>();                
                       
       
       test.startTest();
       listObjects = AddIRProductServices.getIRProducts(queryParams);
       test.stopTest();
       
       system.assertEquals(2, listObjects.size(), 'Product Item list size not equal to 2');
       IR_Product__c ir2 = (IR_Product__c)listObjects[0];
       system.assertEquals(ir1.Product_Name__c, ir2.Product_Name__c, 'IR Product product name does not match');
   }    

   static testmethod void testCreateProductRepairLineItemsNoSwap() {
       Map<String, Object> queryParams = new Map<String, Object>();
       Product2 p = [SELECT Id, Name FROM Product2 WHERE Name = 'Acer Y9' LIMIT 1];
       ProductItem__c pItem = [SELECT Id, Name FROM ProductItem__c WHERE Product_Name__c =: p.Id AND Check_In_Type__c = 'Purchase' LIMIT 1];
       Product_Repair__c pr = [select Id, Repair_Activity__c, Product_Item__c FROM Product_Repair__c WHERE Product_Item__c =: pItem.id LIMIT 1];
	   IR_Product__c ir1 = [select Id, Name, Product_Name__c, Lot_Number__c FROM IR_Product__c WHERE Product_Name__c = 'Misc Part' AND Lot_Number__c = 'Test111' LIMIT 1];

       List<Map<String, Object>> listSelectedItems = new List<Map<String, Object>>();
       List<String> listSwapItems = new List<String>();
       Map<String, Object> itemReceiptProductRecord = new Map<String, Object>();
        
       itemReceiptProductRecord.put('id', ir1.Id);
       itemReceiptProductRecord.put('quantity', 2);
       
       listSelectedItems.add(itemReceiptProductRecord);
       
       test.startTest();
       AddIRProductServices.createProductRepairLineItems(listSelectedItems, listSwapItems, pr.Id);
       test.stopTest();
       
       List<Product_Repair_Line_Item__c> listPrli = [SELECT Id, Product_Repair__c, Quantity__c FROM Product_Repair_Line_Item__c WHERE Product_Repair__c =: pr.Id];
       system.debug('LIST PRLI from 172 >> ' + listPrli);
       system.assertEquals(2, listPrli.size(), 'Product repair line item size is not equal to 2');
       system.assertEquals(2, listPrli[0].Quantity__c, 'Product repair line item quantity is not equal to 2');
       
   }
    
   static testmethod void testCreateOpportunityLineItemsWithSwap() {
       Map<String, Object> queryParams = new Map<String, Object>();
       Product2 p = [SELECT Id, Name FROM Product2 WHERE Name = 'Acer Y9' LIMIT 1];
       ProductItem__c pItem = [SELECT Id, Name FROM ProductItem__c WHERE Product_Name__c =: p.Id AND Check_In_Type__c = 'Purchase' LIMIT 1];
       Product_Repair__c pr = [select Id, Repair_Activity__c, Product_Item__c FROM Product_Repair__c WHERE Product_Item__c =: pItem.id LIMIT 1];
	   IR_Product__c ir1 = [select Id, Name, Product_Name__c, Lot_Number__c FROM IR_Product__c WHERE Product_Name__c = 'Misc Part' AND Lot_Number__c = 'Test111' LIMIT 1];
	   Product_Repair_Line_Item__c prli1 = [select Id, IR_Product__c, Lot_Number__c FROM Product_Repair_Line_Item__c WHERE Lot_Number__c = 'Test123' LIMIT 1];
       List<Map<String, Object>> listSelectedItems = new List<Map<String, Object>>();
       List<String> listSwapItems = new List<String>();
       Map<String, Object> itemReceiptProductRecord = new Map<String, Object>();
        
       itemReceiptProductRecord.put('id', ir1.Id);
       itemReceiptProductRecord.put('quantity', 2);
       
       listSelectedItems.add(itemReceiptProductRecord);
       listSwapItems.add(prli1.Id + '-' + ir1.Id);
       
       test.startTest();
       AddIRProductServices.createProductRepairLineItems(listSelectedItems, listSwapItems, pr.Id);
       test.stopTest();
       

       List<Product_Repair_Line_Item__c> listPrli = [SELECT Id, Product_Repair__c, Lot_Number__c FROM Product_Repair_Line_Item__c WHERE Product_Repair__c =: pr.Id];
       system.assertEquals(1, listPrli.size(), 'Product repair line item size is not equal to 1');
       system.assertEquals(ir1.Lot_Number__c, listPrli[0].Lot_Number__c, 'PRLI lot number does not match with swapped item');

   }
 
   

}