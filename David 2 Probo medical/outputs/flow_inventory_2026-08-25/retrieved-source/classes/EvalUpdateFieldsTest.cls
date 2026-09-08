@isTest
private class EvalUpdateFieldsTest {

    static testmethod void TestEvalUpdateFieldsTest1() {
        Pricebook2 pricebookstd = new Pricebook2(Name = 'Standard Price Book', isActive = true);
        //ProboCommonUtils.getStdPricebookId();
        insert pricebookstd;
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Probe_Type__c = 'Transesophageal';
        pro.Max_Repair__c = 1000;
        pro.Cable_Advanced_Whitening__c = 100;
        pro.Lens_Relens__c = 1000;
        pro.Lens_Refurb__c = 800;
        insert pro;
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Possible_Functional_Repairs__c = 'Cable Replacement';
        insert pi;
        Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', null, true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(o.Id, pbe.Id, pi.Id, true);

        Test.startTest();
		User u = TestDataFactory.createUser('Casey', 'Trogden', true);
        system.runas(u) {
        RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', false);
        rma.ProductItem__c = pi.Id;
        rma.Opportunity__c = o.Id;
        rma.OwnerId = u.id;
        insert rma;

        Evaluation_Natalie__c evalNat = TestDataFactory.createEvaluationNatalie(rma.Id, false);
        EvalNat.Recommended_Repairs__c = 'Cable Advanced Whitening';
        EvalNat.Required_Repairs__c = 'Lens Relens';
        EvalNat.Required_Repairs_Price__c = 500;
        EvalNat.Full_Repair_Price__c = 1000;
        EvalNat.Date_Repair_Evaluation_Sent__c = system.today() - 2;
        EvalNat.Date_Repair_Approved__c = system.today() - 2;
        EvalNat.Approved__c = 'Required Repairs Only';
        insert evalNat;

        EvalNat.Recommended_Repairs__c = 'Lens Refurbishment';
        EvalNat.Approved__c = 'Declined All Options';
        EvalNat.Probe_is_unrepairable__c = true;
        update EvalNat;


        Test.stopTest();
    }
    }
    
    static testmethod void TestEvalUpdateFieldsTest2() {
        Pricebook2 pricebookstd = new Pricebook2(Name = 'Standard Price Book', isActive = true);
        //ProboCommonUtils.getStdPricebookId();
        insert pricebookstd;
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Probe_Type__c = 'Transesophageal';
        pro.Max_Repair__c = 1000;
        pro.Cable_Advanced_Whitening__c = 100;
        pro.Lens_Relens__c = 1000;
        pro.Lens_Refurb__c = 800;
        insert pro;
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Possible_Functional_Repairs__c = 'Cable Replacement';
        insert pi;
        Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', null, true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(o.Id, pbe.Id, pi.Id, true);

        Test.startTest();
		User u = TestDataFactory.createUser('Casey', 'Trogden', true);
        system.runas(u) {
        RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', false);
        rma.ProductItem__c = pi.Id;
        rma.Opportunity__c = o.Id;
        rma.OwnerId = u.id;
        insert rma;

        Evaluation_Natalie__c evalNat = TestDataFactory.createEvaluationNatalie(rma.Id, false);
        EvalNat.Recommended_Repairs__c = 'Cable Advanced Whitening';
        EvalNat.Required_Repairs__c = 'Lens Relens';
        EvalNat.Required_Repairs_Price__c = 500;
        EvalNat.Full_Repair_Price__c = 1000;
        EvalNat.Date_Repair_Evaluation_Sent__c = system.today() - 2;
        EvalNat.Date_Repair_Approved__c = system.today() - 2;
        
        insert evalNat;


        EvalNat.Approved__c = 'Full Repairs (Recommended and Required)';
        EvalNat.Approved_Price__c = 1000;
        update EvalNat;
            
        

        Test.stopTest();
    	}
    }
    
    static testMethod void testInvocableEmail() {
        Pricebook2 pricebookstd = new Pricebook2(Name = 'Standard Price Book', isActive = true);
        //ProboCommonUtils.getStdPricebookId();
        insert pricebookstd;
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Probe_Type__c = 'Transesophageal';
        pro.Max_Repair__c = 1000;
        pro.Cable_Advanced_Whitening__c = 100;
        pro.Lens_Relens__c = 1000;
        pro.Lens_Refurb__c = 800;
        insert pro;
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Possible_Functional_Repairs__c = 'Cable Replacement';
        insert pi;
        Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', null, true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(o.Id, pbe.Id, pi.Id, true);

		User u = TestDataFactory.createUser('Casey', 'Trogden', true);
        system.runas(u) {
        RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', false);
        rma.ProductItem__c = pi.Id;
        rma.Opportunity__c = o.Id;
        rma.OwnerId = u.id;
        insert rma;

        Evaluation_Natalie__c evalNat = TestDataFactory.createEvaluationNatalie(rma.Id, false);
        EvalNat.Recommended_Repairs__c = 'Cable Advanced Whitening';
        EvalNat.Required_Repairs__c = 'Lens Relens';
        EvalNat.Required_Repairs_Price__c = 500;
        EvalNat.Full_Repair_Price__c = 1000;
        EvalNat.Date_Repair_Evaluation_Sent__c = system.today() - 2;
        EvalNat.Date_Repair_Approved__c = system.today() - 2;
        
        insert evalNat;
            
            Test.StartTest();

        EmailPostRepairEvalPDF.flowInput flowVariables = new EmailPostRepairEvalPDF.flowInput();
            
            flowVariables.eMail = 'nboger@probomedical.com';
            flowVariables.eSubject = 'Test Email';
            flowVariables.ebody = 'This is a test email.';
            flowVariables.currentRecordId = EvalNat.Id;
            EmailPostRepairEvalPDF.currentRecordID(new List<EmailPostRepairEvalPDF.flowInput> {flowVariables});

       
		Test.StopTest();
    }
}
}