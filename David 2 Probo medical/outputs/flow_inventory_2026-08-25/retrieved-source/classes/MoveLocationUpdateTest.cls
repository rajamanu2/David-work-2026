@isTest
private class MoveLocationUpdateTest{

    static testmethod void TestMoveLocationUpdateTest() {
        Account acc = TestDataFactory.createAccount(true);
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Probe_Type__c = 'Linear';
        insert pro;
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Possible_Functional_Repairs__c = 'Cable Replacement';
        insert pi;

        Test.startTest();

        apexPages.currentPage().getParameters().put('CF00NU00000060eTa_lkid', pi.Id);
        Move_Location__c moveL = new Move_Location__c(ProductItem__c = pi.Id, External_Location__c = acc.ID, Note__c = 'Demo Note', Geographic_Location__c = 'Fishers, IN');
        Insert moveL;
        ApexPAges.StandardController sc = new ApexPages.StandardController(moveL);
        MoveLocation movetest = new MoveLocation(sc);
        movetest.newMoveLocation();

        Test.stopTest();
    }
}