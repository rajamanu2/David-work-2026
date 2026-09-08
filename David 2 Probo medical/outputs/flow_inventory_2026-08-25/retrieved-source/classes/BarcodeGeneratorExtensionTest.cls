@isTest
public class BarcodeGeneratorExtensionTest {

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
        
    }

    
    static testmethod void testExtension() {
        ProductItem__c pi = [SELECT Id FROM ProductItem__c WHERE Product_Name__r.Name = 'Siemens 8V' LIMIT 1];
        PageReference nextPage;
        
        Test.startTest();
        Test.setCurrentPage(Page.BarcodeGenerator);
        ApexPages.StandardController con = new ApexPages.StandardController(pi);
        BarcodeGeneratorExtension ext = new BarcodeGeneratorExtension(con);
        nextPage = ext.close();
        Test.stopTest();
        
        ProductItem__c piUpdated = [SELECT Label_Printed__c FROM ProductItem__c WHERE Id=: pi.Id];
        system.assert(nextPage.getUrl().contains(pi.Id), 'Page reference does not contain Product Item Id');
        system.assertEquals(true, piUpdated.Label_Printed__c, 'Product Item label not marked as printed');
    }    

}