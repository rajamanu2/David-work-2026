@isTest
public class AddAssetServicesTest {
    @testSetup
    static void setup() {
        
    	//Create Products
    	List<Product2> listProducts = new List<Product2>();
        Product2 p1 = testDataFactory.createProduct('Part','Siemens 8V','Ultrasound Part', false);
        p1.Part_Number__c = '32958821';
        p1.OEM__c = 'Siemens_Healthineers';
        p1.Part_Type__c = 'Assembly';
        p1.Modality__c = 'Ultrasound';
        p1.Compatible_System_OEM__c = 'Siemens Healthineers';
        p1.Compatible_System_Model__c = 'Premium Edition';
        p1.Compatible_System_Family__c = 'Antares';
        p1.Compatible_System_Software_Version__c = '4.0';
        listProducts.add(p1);
        insert listProducts;
        
    	//Create Customer Account
    	Account a = testDataFactory.createAccount(false);
		a.Name = 'Test Account';
        insert a;
        
        //Create System Work Order
        System_Work_Order__c so = new System_Work_Order__c();
       	so.W_O_Status__c = 'Open';
        so.Intended_Use__c = 'Harvest';
        insert so;
        
    	//Create Harvest Work Order
        Harvest_Work_Order__c ho = new Harvest_Work_Order__c(); 
        ho.System_Work_Order__c = so.Id;
        ho.Status__c = 'In Process';
        insert ho;
        
    }

    static testmethod void testGetProductsPartsOnly() {
       Map<String, Object> queryParams = new Map<String, Object>();
       Product2 p = [SELECT Id, Name, OEM__c, Part_Type__c, Modality__c FROM Product2 WHERE Name = 'Siemens 8V' LIMIT 1];

       queryParams.put('partsOnly', true);
       queryParams.put('compatibleSystemOEM', 'Siemens Healthineers');
       queryParams.put('compatibleSystemFamily', 'Antares');
       queryParams.put('compatibleSystemModel', 'Premium Edition');
       queryParams.put('compatibleSystemSoftwareVersion', '4.0');
       queryParams.put('oem', 'Siemens_Healthineers');
       queryParams.put('partType', 'Assembly');
       queryParams.put('modality', 'Ultrasound');
       List<Object> listObjects = new List<Object>();                
       
       test.startTest();
       listObjects = AddAssetServices.getProducts(queryParams);
       test.stopTest();
        
       system.assertEquals(1, listObjects.size(), 'Product list size not equal to 1');
       Product2 p1 = (Product2)listObjects[0];
       system.assertEquals(p.Name, p1.Name, 'Product name does not match');
        
    }   
    
    static testmethod void testGetHarvestWorkOrderInfo() {
       Harvest_Work_Order__c ho = [SELECT Id, Name, Status__c, System_Work_Order__c FROM Harvest_Work_Order__c LIMIT 1];
       Map<String, String> harvestWorkOrderMap = new Map<String, String>();
       Object o;   
         
       test.startTest();
       o = AddAssetServices.getHarvestWorkOrderInfo(ho.Id);
       test.stopTest();
         
       harvestWorkOrderMap = (Map<String, String>) o; 
         
       system.assertEquals(ho.Status__c, harvestWorkOrderMap.get('status'), 'Status does not match');
       system.assertEquals(ho.System_Work_Order__c, harvestWorkOrderMap.get('systemWorkOrder'), 'System Work Order does not match');
         
     }  
    
     static testmethod void testCreateAssets() {
        Product2 p = [SELECT Id, Name, Part_Number__c FROM Product2 WHERE Name = 'Siemens 8V' LIMIT 1];
        Harvest_Work_Order__c ho = [SELECT Id, Name, Status__c, System_Work_Order__c FROM Harvest_Work_Order__c LIMIT 1];
        List<Map<String, Object>> listSelectedItems = new List<Map<String, Object>>();
        Map<String, Object> productRecord = new Map<String, Object>();
        String result;
        
        productRecord.put('id', p.Id);
        productRecord.put('quantity', 1);
        productRecord.put('partSubLocation', 'REFURB');
        productRecord.put('serialNumber', '44630');
        listSelectedItems.add(productRecord);
         
        test.startTest();
        result = AddAssetServices.createAssets(listSelectedItems, ho.Id);
        test.stopTest();
         
        List<ProductItem__c> listItems = [SELECT Id, Product_Name__c, Check_In_Type__c, Harvest_Work_Order__c FROM ProductItem__c WHERE Harvest_Work_Order__c =: ho.Id]; 
         
        system.assertEquals('success', result, 'Asset creation did not process successfully');
        system.assertEquals(1, listItems.size(), 'Product item list size is not equal to 1');
        system.assertEquals(p.Id, listItems[0].Product_Name__c, 'Product item product does not match');
         
    }    
}