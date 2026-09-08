@isTest
public class updateRMA_test{

    static testmethod void TestUpdateRMATest1() {

        Test.startTest();

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        Opportunity opp = TestDataFactory.createOpportunity('Purchasing Opportunity', null, false);
        opp.StageName = 'Prospecting';
        opp.Shipping_FROM_Location__c = 'Fishers, IN';
        insert opp;
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Other_Notes__c='Cable needs cleaned';
        pi.PO_Number__c = '1234';
        pi.Purchasing_Opportunity__c = opp.Id;
        pi.Other_Notes__c = 'Cable needs cleaned';
        pi.Repair_Due_Date__c = system.today();
        pi.Added_to_Work_Order__c = false;
        insert pi;

        RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', false);
        rma.ProductItem__c = pi.Id;
        insert rma;
        
        rma.Approved_Repairs__c = 'Lens Relens; Retermination';
        rma.Current_Estimated_Ship_Date__c = date.today();
        update rma;

        ProductItem__c pi1 = TestDataFactory.createProductItem(pro.Id, false);
        pi1.Reserved__c = false;
        pi1.PO_Number__c = '1234';
        pi1.Other_Notes__c = 'Cable needs cleaned';
        pi1.Repair_Due_Date__c = system.today();
        insert pi1;

        pi1.Purchasing_Opportunity__c = opp.id;
        system.debug('THIS IS THE PURCHASING OPP >> ' + opp.id);
        update pi1;

        Test.stopTest();
    }

    static testmethod void TestUpdateRMATest2() {
        Test.startTest();
        User u = TestDataFactory.createUser('Casey', 'Trogden', true);

        system.runas(u) {
            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
            pro.Max_Repair__c = 800;
            pro.Max_Non_Functional__c = 800;
            insert pro;
            System.debug('CC...Test: estUpdateRMATest2 Number of Queries: ' + Limits.getQueries());
            Account acct = TestDataFactory.createAccount(false); 
            acct.Accounting_Contact_E_mail__c = 'Test@Test.com';
            insert acct;
            Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, false);
            opp.StageName = 'Closed Won';
            opp.Customer_PO__c = '1234';
            //opp.Ship_Date__c = system.today() + 3;
            opp.Shipping_FROM_Location__c = 'Fishers, IN';
            opp.Confirmation_number__c = '12345';
            insert opp;
            System.debug('CC...Test: estUpdateRMATest2 Number of Queries: ' + Limits.getQueries());
            PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
            System.debug('CC...Test: estUpdateRMATest2 Number of Queries: ' + Limits.getQueries());
            ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
            pi.PO_Number__c = '2345';
            pi.Purchasing_Opportunity__c = opp.Id;
            pi.Other_Notes__c = 'Cable needs cleaned';
            pi.Repair_Due_Date__c = system.today() - 1;
            pi.Purchasing_Opportunity__c = opp.Id;
            pi.Possible_Functional_Repairs__c = 'Retermination';
            pi.Possible_Cosmetic_Repairs__c = 'Strain Relief Refurbishment';
            insert pi;
            System.debug('CC...Test: estUpdateRMATest2 Number of Queries: ' + Limits.getQueries());
            Product_Repair__c newRepair = TestDataFactory.createProductRepair('Cosmetic Repair', 'Cable Advanced Whitening', pi.Id, true);
/*
            OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, false);
            oli.Quantity = 1;
            oli.TotalPrice = 500;
            oli.Purchasing_Approved__c = true;
            insert oli;*/

            RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', false);
            
            insert rma;
            System.debug('CC...Test: estUpdateRMATest2 Number of Queries: ' + Limits.getQueries());
            rma.ProductItem__c = pi.Id;
            rma.Opportunity__c = opp.id;
             rma.Approved_Repairs__c = 'All Repairs Approved';
            rma.Date_RMA_Item_Received__c = system.today() - 1;
            /*update rma;
            System.debug('CC...Test: estUpdateRMATest2 Number of Queries: ' + Limits.getQueries());
            pi.Cosmetic_Notes__c = 'TEST';
            System.debug('CC...Test: estUpdateRMATest2 Number of Queries: ' + Limits.getQueries());
            
			system.debug('TEST: start updateRMA_test.TestUpdateRMATest2()');
            update pi;

            System.debug('CC...Test: estUpdateRMATest2 Number of Queries: ' + Limits.getQueries());
            Test.stopTest();*/
        }
    }

}