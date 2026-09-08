@isTest
private class NewLoanerTest{

    static testMethod void TestNewLoaner() {
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
        NewLoanerOpp tester = new NewLoanerOpp(sc);
        tester.newLoaner();

        Test.stopTest();

        List<Opportunity> oppsAfter = [
                select id, name, AccountId, LeadSource, Primary_Contact_ID__c, Related_Opportunity__c,
                        Account.ShippingStreet, Account.ShippingCity, Account.ShippingState, CloseDate,
                        Account.ShippingPostalCode, Account.ShippingCountry, SubType__c, StageName,
                        ShippingStreet__c, ShippingCity__c, ShippingState__c, ShippingPostalCode__c,
                        ShippingCountry__c
                from Opportunity
        ];
        Opportunity repairOppAfter = new Opportunity();
        Opportunity loanerOppAfter = new Opportunity();

        System.debug('TEST: oppsAfter: ' + oppsAfter);

        for (Opportunity thisOpp : oppsAfter) {
            if (thisOpp.name.equals(theOppName)) {
                repairOppAfter = thisOpp;
            } else {
                loanerOppAfter = thisOpp;
            }
        }

        System.assertEquals('Loaner', loanerOppAfter.SubType__c, 'New Loaner Opp SubType__c field is not set correctly.');
        System.assertEquals('Proposal/Price Quote', loanerOppAfter.StageName, 'New Loaner Opp StageName field is not set correctly.');
        System.assertEquals(Date.today(), loanerOppAfter.CloseDate, 'New Loaner Opp CloseDate field is not set correctly.');
        System.assertEquals(repairOppAfter.AccountId, loanerOppAfter.AccountId, 'New Loaner Opp AccountId field is not set correctly.');
        System.assertEquals(repairOppAfter.Account.ShippingStreet, loanerOppAfter.ShippingStreet__c, 'New Loaner Opp ShippingStreet__c field is not set correctly.');
        System.assertEquals(repairOppAfter.Account.ShippingCity, loanerOppAfter.ShippingCity__c, 'New Loaner Opp ShippingCity__c field is not set correctly.');
        System.assertEquals(repairOppAfter.Account.ShippingState, loanerOppAfter.ShippingState__c, 'New Loaner Opp ShippingState__c field is not set correctly.');
        System.assertEquals(repairOppAfter.Account.ShippingPostalCode, loanerOppAfter.ShippingPostalCode__c, 'New Loaner Opp ShippingPostalCode__c field is not set correctly.');
        System.assertEquals(repairOppAfter.Account.ShippingCountry, loanerOppAfter.ShippingCountry__c, 'New Loaner Opp ShippingCountry__c field is not set correctly.');
        System.assertEquals(repairOppAfter.LeadSource, loanerOppAfter.LeadSource, 'New Loaner Opp LeadSource field is not set correctly.');
        System.assertEquals(repairOppAfter.Primary_Contact_ID__c, loanerOppAfter.Primary_Contact_ID__c, 'New Loaner Opp Primary_Contact_ID__c field is not set correctly.');

        System.assertEquals(loanerOppAfter.Id, repairOppAfter.Related_Opportunity__c, 'Repair Opp Related_Opportunity__c field is not set correctly.');

    }
}