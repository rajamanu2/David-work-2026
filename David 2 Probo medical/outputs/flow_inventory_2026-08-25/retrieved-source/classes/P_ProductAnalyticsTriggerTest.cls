@IsTest
public class P_ProductAnalyticsTriggerTest {
    
      @IsTest
    static void testDeleteProductAnalytics(){

        List<Product2> pToInsert = new List<Product2>();

        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'test';
        p.Probe_Type__c = 'Linear';
        p.Family = 'Ultrasound Probe';
        insert p;
        
        Product_Analytics__c prodAnalytics = [SELECT Id,Name, Product__c FROM Product_Analytics__c WHERE Product__c =: p.id LIMIT 1];
        

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'QA-Testing', Receive_date__c = Date.today(), Posted_on_Ebay__c = true, Product_Analytics__c = prodAnalytics.id);
        insert pi;


        Test.startTest();

         try{
            delete prodAnalytics;
        }Catch (DMLException e){
            System.assert(e.getMessage().contains('Product Analytics records cannot be deleted.'), 'Product Analytics records cannot be deleted.');
        }
        Test.stopTest();

    }

}