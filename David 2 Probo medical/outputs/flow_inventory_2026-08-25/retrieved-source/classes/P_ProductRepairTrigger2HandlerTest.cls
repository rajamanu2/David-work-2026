@isTest
public class P_ProductRepairTrigger2HandlerTest {

    @isTest
    public static void testMet(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 

        User u = new User(Alias = 'standt', Email='usertest@testorg.com', EmailEncodingKey='UTF-8', firstName='test', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='usertest@testorg.com');

        System.runAs(u){
           	Product2 product1= new Product2();
            product1.Name ='test1';
            product1.OEM__c ='Mindray';
            product1.Modality__c = 'Test';
            product1.Part_Type__c = 'Assembly';
            insert product1;

            ProductItem__c prodItem= new ProductItem__c();
            prodItem.Product_Name__c = product1.Id;
            prodItem.Receive_date__c= System.today();
            prodItem.Check_In_Type__c   = 'Generic';
            proditem.RMA_Owner__c ='test Owner';
            insert prodItem;
            

            Product_Repair__c create1 = new Product_Repair__c();
            create1.Repair_Activity__c = 'Cable Replacement';
            create1.No_longer_needed__c = true;
            create1.Repair_Technician__c = 'Monty Greb';
            create1.In_Process_Test_Complete__c = true;
            create1.Repair_Result__c = 'SUCCESS';
            create1.Product_Item__c = prodItem.Id;
            create1.Reason_for_why_no_longer_needed__c='test';
            insert create1;
            
            List<Product_Repair__c> prods= new List<Product_Repair__c>();
            prods.add(create1);
            Test.startTest();
            P_ProductRepairTrigger2Handler.beforeInsert1(prods);
            prodItem.RMA_Owner__c='tested';
            update prodItem;
            
            create1.Repair_Activity__c = 'Cable Replacement';
            create1.No_longer_needed__c = true;
            create1.Repair_Technician__c = 'Be Tran';
            create1.In_Process_Test_Complete__c = false;
            create1.Repair_Result__c = 'FAIL';
            create1.Repair_Notes__c='test2';
            Update create1;
            Map<Id, Product_Repair__c> mapd= new Map<Id, Product_Repair__c>();
            mapd.put(create1.Id,create1);
            prods.add(create1);
            P_ProductRepairTrigger2Handler.beforeUpdate1(prods,mapd);
            Test.stopTest();

        }
    }
}