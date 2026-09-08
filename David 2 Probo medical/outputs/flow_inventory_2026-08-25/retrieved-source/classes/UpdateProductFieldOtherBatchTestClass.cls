@isTest
private class UpdateProductFieldOtherBatchTestClass {

    static testmethod void TestUpdateProductFieldOtherBatchTest1() {

        //TODO - query the picklist values for the Work_Order__c.Person_Requesting_WO__c field and grab one of the fields from the picklist values for this user
        User u = TestDataFactory.createUser('Casey', 'Trogden', true);

        system.runas(u) {
            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
            pro.Functionally_Good_Probes__c = 190;
            insert pro;
            ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
            pi.Sold__c = true;
            pi.Purchasing_Approved__c = true;
            insert pi;
            Opportunity opp = TestDataFactory.createOpportunity('Sales Opportunity', null, false);
            opp.StageName = 'Closed Won';
            opp.Customer_PO__c = '1234';
            opp.Shipping_FROM_Location__c = 'Fishers, IN';
            opp.Confirmation_number__c = '12345';
            insert opp;
            PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
            OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, false);
            oli.Quantity = 1;
            oli.TotalPrice = 100;
            oli.Purchasing_Approved__c = true;
            insert oli;
        }

        Test.startTest();

        UpdateProductFieldOtherBatch upfb = new UpdateProductFieldOtherBatch();
        Database.executeBatch(upfb, 1);

        Test.stopTest();
    }

    static testmethod void TestUpdateProductFieldOtherBatchTest2() {

        //TODO - query the picklist values for the Work_Order__c.Person_Requesting_WO__c field and grab one of the fields from the picklist values for this user
        User u = TestDataFactory.createUser('Casey', 'Trogden', true);

        system.runas(u) {
            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
            pro.Name = 'Ultrasound Probe-Acuson 4V1C';
            pro.Functionally_Good_Probes__c = 10;
            pro.Qty_Ready_to_Ship__c = 5;
            insert pro;
            ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
            pi.Cost__c = 15000.00;
            pi.Location__c='Finished Goods';
            pi.Functional_Rating__c = 'Good';
            pi.Cosmetic_Rating__c = 'Good';
            pi.Purchasing_Approved__c = true;
            insert pi;
            Opportunity opp = TestDataFactory.createOpportunity('Sales Opportunity', null, false);
            opp.StageName = 'Closed Won';
            opp.Customer_PO__c = '1234';
            opp.Shipping_FROM_Location__c = 'Fishers, IN';
            opp.Confirmation_number__c = '12345';
            insert opp;
            PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
            OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, false);
            oli.Quantity = 1;
            oli.TotalPrice = 1000;
            oli.Purchasing_Approved__c = true;
            insert oli;
        }

        Test.startTest();

        UpdateProductFieldOtherBatch upfb = new UpdateProductFieldOtherBatch();
        Database.executeBatch(upfb, 1);
        System.schedule('Scheduled Job 7', '0 0 * * * ?', new UpdateProductFieldOtherBatch());

        Test.stopTest();
    }

}