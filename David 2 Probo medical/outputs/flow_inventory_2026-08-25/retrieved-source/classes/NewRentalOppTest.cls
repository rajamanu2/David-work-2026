@isTest
private class NewRentalOppTest {
    static testMethod void TestNewRentalTest() {
        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity('Sales Opportunity', acc.Id, false);

        String theOppName = opp.Name;

        opp.StageName = 'Proposal/Price Quote';
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
        NewRentalOpp tester = new NewRentalOpp(sc);
        tester.newRental();

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
        Opportunity rentalOppAfter = new Opportunity();

        System.debug('TEST: oppsAfter: ' + oppsAfter);

        for (Opportunity thisOpp : oppsAfter) {
            if (thisOpp.name.equals(theOppName)) {
                salesOppAfter = thisOpp;
            } else {
                rentalOppAfter = thisOpp;
            }
        }

        // Validate that the Opportunities were created or updated 
        System.assertEquals('Proposal/Price Quote', rentalOppAfter.StageName, 'New Rental Opp StageName field is not set correctly.');
        System.assertEquals(Date.today(), rentalOppAfter.CloseDate, 'New Rental Opp CloseDate field is not set correctly.');
        System.assertEquals(salesOppAfter.AccountId, rentalOppAfter.AccountId, 'New Rental Opp AccountId field is not set correctly.');
        System.assertEquals(salesOppAfter.Account.ShippingStreet, rentalOppAfter.ShippingStreet__c, 'New Rental Opp ShippingStreet__c field is not set correctly.');
        System.assertEquals(salesOppAfter.Account.ShippingCity, rentalOppAfter.ShippingCity__c, 'New Rental Opp ShippingCity__c field is not set correctly.');
        System.assertEquals(salesOppAfter.Account.ShippingState, rentalOppAfter.ShippingState__c, 'New Rental Opp ShippingState__c field is not set correctly.');
        System.assertEquals(salesOppAfter.Account.ShippingPostalCode, rentalOppAfter.ShippingPostalCode__c, 'New Rental Opp ShippingPostalCode__c field is not set correctly.');
        System.assertEquals(salesOppAfter.Account.ShippingCountry, rentalOppAfter.ShippingCountry__c, 'New Rentaly Opp ShippingCountry__c field is not set correctly.');
        System.assertEquals(salesOppAfter.LeadSource, rentalOppAfter.LeadSource, 'New Rental Opp LeadSource field is not set correctly.');
        System.assertEquals(salesOppAfter.Primary_Contact_ID__c, rentalOppAfter.Primary_Contact_ID__c, 'New Rental Opp Primary_Contact_ID__c field is not set correctly.');
        //System.assertEquals('Closed Lost', salesOppAfter.StageName, 'Sales Opp Stage field is not set to Closed Lost.');
        System.assertEquals(rentalOppAfter.Id, salesOppAfter.Related_Opportunity__c, 'Sales Opp Related_Opportunity__c field is not set correctly.');
    }

}