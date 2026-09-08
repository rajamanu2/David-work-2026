@isTest

public class UpdateRMABatchTest{

	

    static testmethod void test() {

        
        
            Account a = testDataFactory.createAccount(true);
            RMA__c r = new RMA__c(Create_Shipment__c = true, Run_Shipment_Flow__c = false);
            insert r;
            
        

        Test.startTest();


        UpdateRMABatch upfb = new UpdateRMABatch();
        Database.executeBatch(upfb, 1);
        System.schedule('Scheduled Job 7', '0 0 * * * ?', new UpdateRMABatch());

        Test.stopTest();
        }
}