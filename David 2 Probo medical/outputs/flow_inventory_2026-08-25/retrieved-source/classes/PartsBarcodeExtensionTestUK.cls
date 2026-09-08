@isTest
public class PartsBarcodeExtensionTestUK {
     @testSetup
    static void setup() {
        //Create Products
        Product2 p1 = testDataFactory.createProduct('Part','Siemens 8V','Ultrasound Part', false);
        p1.Part_Number__c = '32958821';
        p1.OEM__c = 'Siemens_Healthineers';
        p1.Part_Type__c = 'Assembly';
        p1.Modality__c = 'Ultrasound';
        p1.Compatible_System_OEM__c = 'Siemens Healthineers';
        p1.Compatible_System_Model__c = 'Premium Edition';
        p1.Compatible_System_Family__c = 'Antares';
        p1.Compatible_System_Software_Version__c = '4.0';
        insert p1;
        
        //Create Product Items
        ProductItem__c pi1 = testDataFactory.createProductItem(p1.id, false); 
        pi1.Check_In_Type__c = 'Harvest';
        pi1.Generic_Product__c = false;
        pi1.Location__c = 'QA-Testing';
        pi1.Functional_Rating__c = 'Good';
        pi1.Cosmetic_Rating__c = 'Good';
        pi1.Review_Status__c = 'Finished Goods';
        pi1.Domestic_Only__c = true;
        pi1.Purchasing_Approved__c = true;
        pi1.Posted_on_Ebay__c = false;
        pi1.Reserved__c = false;
        insert pi1;
        
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
        
        pi1.Harvest_Work_Order__c = ho.Id;
        update pi1;
        
    }
    
    static testmethod void testExtension() {
        Harvest_Work_Order__c ho = [SELECT Id FROM Harvest_Work_Order__c LIMIT 1];
        ProductItem__c pi = [SELECT Id, Name FROM ProductItem__c WHERE Harvest_Work_Order__c =:ho.Id LIMIT 1];
        PageReference nextPage;
        List<ProductItem__c> listSelectedItems = new List<ProductItem__c>();
        listSelectedItems.add(pi);
        
        Test.startTest();
        Test.setCurrentPage(Page.PartsBarcode_UK);
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(listSelectedItems);
        con.setSelected(listSelectedItems);
        PartsBarcodeExtensionUK ext = new PartsBarcodeExtensionUK(con);
        nextPage = ext.redir();
        Test.stopTest();
        
        system.assert(nextPage.getUrl().contains(pi.Id), 'Page reference does not contain Product Item Id');
        system.assert(nextPage.getUrl().contains(ho.Id), 'Page reference does not contain Harvest Work Order Id');
    }    

}