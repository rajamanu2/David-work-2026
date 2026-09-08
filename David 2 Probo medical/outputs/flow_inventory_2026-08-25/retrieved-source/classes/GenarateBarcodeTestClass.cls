@isTest
private class GenarateBarcodeTestClass{


    static testmethod void TestBarCodesQRCodesTest1() {

        Test.startTest();

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Part_Number__c='123456789';
        pro.Compatible_System__c='Compatible system test_1';
        pro.Probe_Type__c = 'Transesophageal';
        pro.Max_Repair__c = 1000;
        pro.Cable_Advanced_Whitening__c = 100;
        insert pro;

        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Possible_Functional_Repairs__c = 'Cable Replacement';
        insert pi;

        ApexPages.StandardController sc = new ApexPages.standardController(pi);

        ProductItem__c pi2 = TestDataFactory.createProductItem(pro.Id, false);
        pi2.Possible_Functional_Repairs__c = 'Cable Replacement';
        insert pi2;

        GenarateBarcode gb = new GenarateBarcode(sc);
        GenarateBarcode2 gb2 = new GenarateBarcode2(sc);
        GenarateQRcode gqr = new GenarateQRcode(sc);

        Test.stopTest();
    }

    static testmethod void TestBarCodesQRCodesTest2() {

        Test.startTest();

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Part_Number__c = '12345678911111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111';
        pro.Compatible_System__c = 'Compatible system test_11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111';
        pro.Probe_Type__c = 'Transesophageal';
        pro.Max_Repair__c = 1000;
        pro.Cable_Advanced_Whitening__c = 100;
        insert pro;

        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Possible_Functional_Repairs__c = 'Cable Replacement';
        insert pi;

        ApexPages.StandardController sc = new ApexPages.standardController(pi);

        ProductItem__c pi2 = TestDataFactory.createProductItem(pro.Id, false);
        pi2.Possible_Functional_Repairs__c = 'Cable Replacement';
        insert pi2;

        GenarateBarcode2 gb2 = new GenarateBarcode2(sc);
        PageReference result = gb2.updateAsset();

        Test.stopTest();
    }
}