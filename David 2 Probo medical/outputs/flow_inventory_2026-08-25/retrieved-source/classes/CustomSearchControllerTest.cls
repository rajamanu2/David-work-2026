@IsTest
private class CustomSearchControllerTest {

    @isTest static void searchForExisting() {

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        System.assertNotEquals(null, pro,'TestDataFactory did not create a Product');
        ProductItem__c thePItem = TestDataFactory.createProductItem(pro.Id, true);
        System.assertNotEquals(null, thePItem,'TestDataFactory did not create a ProductItem__c');

        ProductItem__c thePItemToUse = [select id, Name from ProductItem__c where id = :thePItem.Id LIMIT 1];
        Test.startTest();
        CustomSearchController c = new CustomSearchController();
        System.debug('TEST: setting search text to: ' + thePItemToUse.Name);
        c.searchText = thePItemToUse.Name;
        PageReference thepage = c.search();

        Test.stopTest();

        System.assertEquals('/' + thePItemToUse.Id, thePage.getUrl(), 'CustomSearchController does not return a valid PageReference');
    }
}