@isTest
private class UpdateOpportunityTest {

    static testMethod void mytest() {


        Test.startTest();

        //TODO - query the picklist values for the Work_Order__c.Person_Requesting_WO__c field and grab one of the fields from the picklist values for this user
        User u = TestDataFactory.createUser('Casey', 'Trogden', true);

        system.runas(u) {
            Account acc = TestDataFactory.createAccount(false);
            acc.Accounting_Contact_E_mail__c = 'Test@Test.com';
            insert acc;
            Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acc.Id, false);
            opp.StageName = 'Verbal Acceptance';
            opp.Shipping_FROM_Location__c = 'Fishers, IN';
            insert opp;
            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
            pro.Functionally_Good_Probes__c = 190;
            insert pro;
            ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
            pi.Purchasing_Approved__c = true;
            insert pi;
            PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
            OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, false);
            oli.Quantity = 100;
            oli.TotalPrice = 500;
            oli.Probo_s_Offer__c = 100;
            oli.Supplier_s_Quote__c = 100;
            oli.Purchasing_Approved__c = true;
            insert oli;

            opp.StageName = 'Closed Won';
            opp.Customer_PO__C = '1234';
            opp.Confirmation_number__c = '12345';
            update opp;
            
            try{
            	delete opp;           
        	}Catch (DMLException e){
            	System.assert(e.getMessage().contains('You can not delete a Closed Won Opportunity !'), 'You can not delete a Closed Won Opportunity !');
        	}

        }

        Test.stopTest();
    }
   
    static testMethod void TestOLIDelete() {


        Test.startTest();

        //TODO - query the picklist values for the Work_Order__c.Person_Requesting_WO__c field and grab one of the fields from the picklist values for this user
        User u = TestDataFactory.createUser('Casey', 'Trogden', true);

        system.runas(u) {
            Account acc = TestDataFactory.createAccount(false);
            acc.Accounting_Contact_E_mail__c = 'Test@Test.com';
            insert acc;
            Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acc.Id, false);
            opp.StageName = 'Verbal Acceptance';
            opp.Shipping_FROM_Location__c = 'Fishers, IN';
            insert opp;
            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
            pro.Functionally_Good_Probes__c = 190;
            insert pro;
            ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
            pi.Purchasing_Approved__c = true;
            insert pi;
            PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
            OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, false);
            oli.Quantity = 100;
            oli.TotalPrice = 500;
            oli.Probo_s_Offer__c = 100;
            oli.Supplier_s_Quote__c = 100;
            oli.Purchasing_Approved__c = true;
            insert oli;
            
            Invoice__c invoice = new invoice__c(Opportunity__c = opp.id, payment_confirmation__c = '12345');
            insert invoice;
            opp.StageName = 'Closed Won';
            opp.Customer_PO__C = '1234';
            opp.Confirmation_number__c = '12345';
            opp.Ship_Date__c = date.today();
            opp.Invoice_Number__c = invoice.id;
            
            update opp;
            
            try{
            	delete oli;           
        	}Catch (DMLException e){
            	System.assert(e.getMessage().contains('You can not delete asset from a Closed Won Opportunity !'), 'You can not delete asset from a Closed Won Opportunity !');
        	}	

        }
		
        Test.stopTest();
    }
}