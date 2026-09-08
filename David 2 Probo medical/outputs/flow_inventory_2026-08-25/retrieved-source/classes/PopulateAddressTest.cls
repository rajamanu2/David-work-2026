@isTest
private class PopulateAddressTest{


    static testmethod void TestPopulateAddress() {

        Test.startTest();

        Account acc = TestDataFactory.createAccount(false);
        acc.BillingStreet = 'vvv';
        acc.BillingCity = 'XYZZY';
        acc.BillingState = 'CA';
        acc.BillingPostalCode = '95117';
        acc.BillingCountry = 'USA';
        acc.ShippingStreet = 'vvv';
        acc.ShippingCity = 'XYZZY';
        acc.ShippingState = 'CA';
        acc.ShippingPostalCode = '95117';
        acc.ShippingCountry = 'USA';
        insert acc;
        Opportunity opp = TestDataFactory.createOpportunity('Sales Opportunity', acc.Id, true);

        Test.stopTest();
    }
 }