@isTest
public class DataTableServicesTest {

    @testSetup static void setup() {
    	//Get Standard Price Book
    	Id stdPB = ProboCommonUtils.getStdPricebookId();
        system.debug('TEST: standard price book id: '+stdPB);
        
    	//Create Products
    	List<Product2> listProducts = new List<Product2>();
    	Product2 p1 = testDataFactory.createProduct('Ultrasound Probe','Acer Y9','Ultrasound Probe', false);
        listProducts.add(p1);
        Product2 p2 = testDataFactory.createProduct('Ultrasound Probe','Sony BZ3','Ultrasound Probe', false);
        listProducts.add(p2);
        insert listProducts;
        
    	//Create Pricebook Entries for Products
    	List<PriceBookEntry> listPriceBookEntries = new List<PriceBookEntry>();
    	PriceBookEntry pbe1 = testDataFactory.createPricebookEntry(p1.id, false);
        listPriceBookEntries.add(pbe1);
        PriceBookEntry pbe2 = testDataFactory.createPricebookEntry(p2.id, false);
        listPriceBookEntries.add(pbe2);
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
        insert listProductItems;
        
    	//Create Customer Account
    	Account a = testDataFactory.createAccount(false);
		a.Name = 'Test Account Z5';
        insert a;
        
    	//Create Opportunities
    	List<Opportunity> listOpportunities = new List<Opportunity>();
    	Opportunity o1 = testDataFactory.createOpportunity('Sales Opportunity', a.Id, false);
        o1.Name = 'TestSalesOpp';
        o1.Opportunity_Notes__c = 'This is what needs to be done';
        o1.Pricebook2Id = stdPB;
        o1.Repair_Evaluation_Serial_Number__c = '123456';
        o1.Ship_Date__c = date.today() + 30;
        o1.CloseDate = date.today()+15;
        o1.Verified_Asset_and_Serial_Numbers_Match__c = true;
        listOpportunities.add(o1);
        insert listOpportunities;
    }    
    
    static testmethod void testGetDataTableColumnsAndRecordsWithQuery() {
        Account a = [SELECT Id, Name From Account WHERE Name = 'Test Account Z5' LIMIT 1];
        String query = 'SELECT Id, Name From Account WHERE Name = \'Test Account Z5\' LIMIT 1';
        String objectName = 'Account';
        DataTableServices.DataTableResponse response;
        
        Test.startTest();
        response = DataTableServices.getDataTableColumnsAndRecordsWithQuery(objectName, query);
        Test.stopTest();
        
       	system.assertNotEquals(null, response.lstDataTableColumns, 'No columns retuned');
       	system.assertNotEquals(null, response.lstDataTableData, 'No data retuned');

    }   
    
     static testmethod void testGetDataTableColumnsAndRecords() {
       Product2 p = [SELECT Id, Name FROM Product2 WHERE Name = 'Acer Y9' LIMIT 1];
       ProductItem__c pItem = [SELECT Id, Name, Product_Name__c FROM ProductItem__c WHERE Product_Name__c =: p.Id LIMIT 1];
       String objectName = 'ProductItem__c';
       String fieldSetName = 'Ultrasound_Part_Fields_To_Show';
       String whereClause = 'Product_Name__c = \'' + pItem.Id + '\'';
       DataTableServices.DataTableResponse response;
         
       Test.startTest();
       response = DataTableServices.getDataTableColumnsAndRecords(objectName, fieldSetName, whereClause);
       Test.stopTest();  
         
       system.assertNotEquals(null, response.lstDataTableColumns, 'No columns retuned');
       system.assertNotEquals(null, response.lstDataTableData, 'No data retuned');
  
     }   
    
    static testmethod void testGetFieldNames() {
        String objectName = 'ProductItem__c';
        String fieldSetName = 'Ultrasound_Part_Fields_To_Show';
        List<String> response;
        
        Test.startTest();
        response = DataTableServices.getFieldNames(objectName, fieldSetName);
        Test.stopTest();  
        
        system.assertNotEquals(null, response, 'No field names retuned');

    }    
}