@isTest
public class POBillLineItemServicesTest {
    public static Id poBillRecordTypeId = RecordTypeUtility.getRecordTypeByName('PO_Bill__c', 'PO Bill');
    public static Id purchasingPriceAdjustmentRecordTypeId = RecordTypeUtility.getRecordTypeByName('PO_Bill__c', 'Purchasing Price Adjustment');

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
        
    	//Create Customer Account
    	Account a = testDataFactory.createAccount(false);
		a.Name = 'Test Account';
        insert a;
        
    	//Create Opportunities
    	List<Opportunity> listOpportunities = new List<Opportunity>();
    	Opportunity o1 = testDataFactory.createOpportunity('External Repair / Testing', a.Id, false);
        o1.Name = 'TestRepairOpp1';
        o1.Opportunity_Notes__c = 'This is what needs to be done';
        o1.Pricebook2Id = stdPB;
        o1.Repair_Evaluation_Serial_Number__c = '123456';
        o1.Ship_Date__c = date.today() + 30;
        o1.CloseDate = date.today()+15;
        o1.Verified_Asset_and_Serial_Numbers_Match__c = true;
        o1.Shipping_Cost__c = 20;
        listOpportunities.add(o1);
        Opportunity o2 = testDataFactory.createOpportunity('External Repair / Testing', a.Id, false);
        o2.Name = 'TestRepairOpp2';
        o2.Opportunity_Notes__c = 'Test Repair';
        o2.Pricebook2Id = stdPB;
        o2.Repair_Evaluation_Serial_Number__c = '78910';
        o2.Ship_Date__c = date.today() + 30;
        o2.CloseDate = date.today()+15;
        o2.Verified_Asset_and_Serial_Numbers_Match__c = true;
        o2.Shipping_Cost__c = 20;
        listOpportunities.add(o2);
        insert listOpportunities;
        
        //Create Item Receipt
        String itemReceiptName = o2.Name + ' ' + 'Item Receipt';
        Item_Receipt__c ic = new Item_Receipt__c(Opportunity__c=o2.Id);
        insert ic;
        pi1.Item_Receipt__c =  ic.Id;
        update pi1;

    }

    static testmethod void testCreatePOBill() {
       Map<String, Object> queryParams = new Map<String, Object>();
       Opportunity opp = [SELECT id, name FROM Opportunity WHERE name = 'TestRepairOpp1' LIMIT 1];
       Product2 p = [SELECT Id, Name FROM Product2 WHERE Name = 'Connair C4-9T' LIMIT 1];
       ProductItem__c pItem = [SELECT Id, Name, Price__c FROM ProductItem__c WHERE Product_Name__c =: p.Id LIMIT 1];
       List<Map<String, Object>> listSelectedItems = new List<Map<String, Object>>();
       Map<String, Object> productItemRecord = new Map<String, Object>();

       test.startTest();
       POBillLineItemServices.createPOBill(opp.Id, purchasingPriceAdjustmentRecordTypeId);
       test.stopTest();
        
       PO_Bill__c po = [SELECT Id, Opportunity__c FROM PO_Bill__c LIMIT 1];
        
       system.assert(po != null, 'PO Bill not created'); 
       system.assertEquals(opp.Id, po.Opportunity__c, 'Opportunity does not match');     
   }  
    
    
    static testmethod void testCreatePOBillLineItems() {
       Map<String, Object> queryParams = new Map<String, Object>();
       Opportunity opp = [SELECT id, name FROM Opportunity WHERE name = 'TestRepairOpp2' LIMIT 1];
       Product2 p = [SELECT Id, Name FROM Product2 WHERE Name = 'Acer Y9' LIMIT 1];
       ProductItem__c pItem = [SELECT Id, Name, Price__c, Item_Receipt__c FROM ProductItem__c WHERE Product_Name__c =: p.Id LIMIT 1];
       List<Map<String, Object>> listSelectedItems = new List<Map<String, Object>>();
       Map<String, Object> productItemRecord = new Map<String, Object>();

       productItemRecord.put('id', pItem.Id);
       productItemRecord.put('price', pItem.Price__c);
       productItemRecord.put('exchange', false);
       
       listSelectedItems.add(productItemRecord);
        
       test.startTest();
       POBillLineItemServices.createPOBillLineItems(listSelectedItems, opp.Id, poBillRecordTypeId);
       test.stopTest(); 
           
       PO_Bill__c po = [SELECT Id, Opportunity__c FROM PO_Bill__c LIMIT 1];
       ProductItem__c pItemUpdated = [SELECT Id, Name, Price__c, Item_Receipt__c, PO_Bill__c FROM ProductItem__c WHERE Id =: pItem.Id LIMIT 1];
        
       system.assert(po != null, 'PO Bill not created'); 
       system.assertEquals(opp.Id, po.Opportunity__c, 'Opportunity does not match'); 
       system.assertEquals(po.Id, pItemUpdated.PO_Bill__c, 'PO Bill does not match');
   }  
    
}