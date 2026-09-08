@isTest
private class AddProductPortalTestClass{

    // Add a "Sales Opportunity" opportunity, a product, an Asset (ProductItem__c), a pbe, and an OLI
    // Use the addproductportal controller's searchProduct function to search for the added Asset
    // Use assertions to verify the search found the added product
    static testmethod void TestAddProductPortalTest1() {

        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity('Sales Opportunity', acc.Id, true);
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', 'Test Product', 'Ultrasound Probe', true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Purchasing_Approved__c = true;
        pi.Generic_Product__c = false;
        insert pi;
        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, true);

        Test.startTest();

        addproductportal addp = new addproductportal();
        addp.searchString = 'Test Product';
        addp.searchProduct();
        system.assert(addp.wlist.size() != 0, 'Assertion failed - searchProduct function did not return the expected Product');

        Test.stopTest();
    }
}