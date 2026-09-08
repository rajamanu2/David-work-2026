@isTest

public class UpdateAccountBatchTestClass{

	

    static testmethod void test() {

        //TODO - query the picklist values for the Work_Order__c.Person_Requesting_WO__c field and grab one of the fields from the picklist values for this user
        User u = TestDataFactory.createUser('Casey', 'Trogden', true);

        system.runas(u) {
            Account a = testDataFactory.createAccount(true);
            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
            ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
            pi.Cost__c = 15000;
            pi.Location__c = 'Finished Goods';
            pi.Purchasing_Approved__c = true;
            insert pi;
            Opportunity opp = TestDataFactory.createOpportunity('Sales Opportunity', a.id, false);
            opp.StageName = 'Closed Won';
            opp.Customer_PO__c = '1234';
            opp.Shipping_FROM_Location__c = 'Fishers, IN';
            opp.Confirmation_number__c = '12345';
            opp.CloseDate = Date.today().addDays(-29);
            opp.Ship_date__c = Date.today();
            insert opp;
            PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
            OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, false);
            oli.Quantity = 1;
            oli.TotalPrice = 100;
            oli.Purchasing_Approved__c = true;
            insert oli;
        }

        Test.startTest();

/*
            UpdateAccountBatch upfb = new UpdateAccountBatch();
            Database.executeBatch(upfb,1);
             System.schedule('Scheduled Job 7', '0 0 * * * ?', new UpdateAccountBatch());*/
        UpdateAccountBatch upfb = new UpdateAccountBatch();
        Database.executeBatch(upfb, 1);

        Test.stopTest();
        }
}