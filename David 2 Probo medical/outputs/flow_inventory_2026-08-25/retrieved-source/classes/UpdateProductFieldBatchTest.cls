@isTest
public class UpdateProductFieldBatchTest {
    static testmethod void TestUpdateProductFieldBatchTest1() {

        //TODO - query the picklist values for the Work_Order__c.Person_Requesting_WO__c field and grab one of the fields from the picklist values for this user
        User u = TestDataFactory.createUser('Adam', 'Walter', true);

        system.runas(u) {
            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
            ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
            pi.Sold__c = true;
            pi.Purchasing_Approved__c = true;
            pi.RMA_Number__c = '1234';
            insert pi;
            
            Account acc = TestDataFactory.createAccount(true);
            Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acc.id, true);
            opp.StageName = 'Closed Won';
            opp.Customer_PO__c = '1234';
            opp.Shipping_FROM_Location__c = 'Fishers, IN';
            //opp.Confirmation_number__c = '12345';
            update opp;
            PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
            OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, false);
            oli.Quantity = 1;
            oli.TotalPrice = 100;
            oli.Purchasing_Approved__c = true;
            insert oli;
        }

        Test.startTest();

        UpdateProductFieldBatch upfb = new UpdateProductFieldBatch();
        Database.executeBatch(upfb, 1);

        Test.stopTest();
    }

static testmethod void test1() {
	/*
    User theUser;
    try {
        theUser = [select id from User where alias = 'awalt' and isActive = true LIMIT 1];
    } catch (Exception e) {
        system.assert(false, 'Unable to find a user to RunAs.  Looking for Alias of dtrog');
    }*/
    
    User theUser = TestDataFactory.createUser('Adam', 'Walter', true);


    System.runAs(theUser) {

        Account acc = TestDataFactory.createAccount(true);

        Product2 pro = new Product2 (Name = 'Ultrasound Probe-Acuson 4V1C', Functionally_Good_Probes__c = 10, Qty_Ready_to_Ship__c = 5);
        insert pro;

        ProductItem__c prItem1 = new ProductItem__c(Product_Name__c = pro.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '10613003', Receive_date__c = Date.parse('01/08/2015'), Cost__c = 15000.00, Location__c = 'QA-Testing',
                Functional_Rating__c = 'Good', Cosmetic_Rating__c = 'Good', Purchasing_Approved__c = true, RMA_Number__c = '1234');
        insert prItem1;

       Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acc.id, true);
            opp.StageName = 'Closed Won';
            opp.Customer_PO__c = '1234';
            opp.Shipping_FROM_Location__c = 'Fishers, IN';
            //opp.Confirmation_number__c = '12345';
            update opp;

        Id pbId = test.getStandardPricebookId(); //[select id from Pricebook2 where isStandard=true];

        PricebookEntry pbe = new PricebookEntry (Pricebook2Id = pbId, Product2Id = pro.Id, IsActive = true, UnitPrice = 1000.00);
        insert pbe;

        OpportunityLineItem oppli = new OpportunityLineItem(opportunityId = opp.Id, PricebookEntryId = pbe.Id, ProductItem__c = prItem1.Id, Quantity = 1, TotalPrice = 1000.00, Purchasing_Approved__c = true);
        insert oppli;

        UpdateProductFieldBatch upfb = new UpdateProductFieldBatch();
        Database.executeBatch(upfb, 1);
        System.schedule('Scheduled Job 7', '0 0 * * * ?', new UpdateProductFieldBatch());

    }
}

}