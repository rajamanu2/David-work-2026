@isTest
private class NewWarrantyTest{

    static testMethod void TestNewWarrantyTest() {
        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity('Sales Opportunity', acc.Id, false);

        String theOppName = opp.Name;

        opp.StageName = 'Qualification';
        insert opp;
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Functionally_Good_Probes__c = 190;
        insert pro;
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, true);

        Test.startTest();

        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        ApexPages.currentPage().getParameters().put('id', opp.id);
        NewWarrantyOpp tester = new NewWarrantyOpp(sc);
        tester.newWarranty();

        Test.stopTest();

        List<Opportunity> oppsAfter = [
                select id, name, AccountId, LeadSource, Primary_Contact_ID__c, Related_Opportunity__c,
                        Account.ShippingStreet, Account.ShippingCity, Account.ShippingState, CloseDate,
                        Account.ShippingPostalCode, Account.ShippingCountry, SubType__c, StageName,
                        ShippingStreet__c, ShippingCity__c, ShippingState__c, ShippingPostalCode__c,
                        ShippingCountry__c
                from Opportunity
        ];
        Opportunity salesOppAfter = new Opportunity();
        Opportunity warrantyOppAfter = new Opportunity();

        System.debug('TEST: oppsAfter: ' + oppsAfter);

        for (Opportunity thisOpp : oppsAfter) {
            if (thisOpp.name.equals(theOppName)) {
                salesOppAfter = thisOpp;
            } else {
                warrantyOppAfter = thisOpp;
            }
        }

        System.assertEquals('Warranty', warrantyOppAfter.SubType__c, 'New Warranty Opp SubType__c field is not set correctly.');
        System.assertEquals('Proposal/Price Quote', warrantyOppAfter.StageName, 'New Warranty Opp StageName field is not set correctly.');
        System.assertEquals(Date.today(), warrantyOppAfter.CloseDate, 'New Warranty Opp CloseDate field is not set correctly.');
        System.assertEquals(salesOppAfter.AccountId, warrantyOppAfter.AccountId, 'New Warranty Opp AccountId field is not set correctly.');
        System.assertEquals(salesOppAfter.Account.ShippingStreet, warrantyOppAfter.ShippingStreet__c, 'New Warranty Opp ShippingStreet__c field is not set correctly.');
        System.assertEquals(salesOppAfter.Account.ShippingCity, warrantyOppAfter.ShippingCity__c, 'New Warranty Opp ShippingCity__c field is not set correctly.');
        System.assertEquals(salesOppAfter.Account.ShippingState, warrantyOppAfter.ShippingState__c, 'New Warranty Opp ShippingState__c field is not set correctly.');
        System.assertEquals(salesOppAfter.Account.ShippingPostalCode, warrantyOppAfter.ShippingPostalCode__c, 'New Warranty Opp ShippingPostalCode__c field is not set correctly.');
        System.assertEquals(salesOppAfter.Account.ShippingCountry, warrantyOppAfter.ShippingCountry__c, 'New Warranty Opp ShippingCountry__c field is not set correctly.');
        System.assertEquals(salesOppAfter.LeadSource, warrantyOppAfter.LeadSource, 'New Warranty Opp LeadSource field is not set correctly.');
        System.assertEquals(salesOppAfter.Primary_Contact_ID__c, warrantyOppAfter.Primary_Contact_ID__c, 'New Warranty Opp Primary_Contact_ID__c field is not set correctly.');

        System.assertEquals(warrantyOppAfter.Id, salesOppAfter.Related_Opportunity__c, 'Sales Opp Related_Opportunity__c field is not set correctly.');

    }
}