@isTest
private class RmaUpdate_TestClass{

    static testmethod void TestRMAUpdateTest1() {
        Pricebook2 pricebookstd = new Pricebook2(Name = 'Standard Price Book', isActive = true);
        //ProboCommonUtils.getStdPricebookId();
        insert pricebookstd;
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        Opportunity o = TestDataFactory.createOpportunity('Sales Opportunity', null, true);

        system.debug('#### pi ' + pi);

        Test.startTest();

        RMA__c rma = TestDataFactory.createRMA('Warranty Claim', false);
        rma.ProductItem__c = pi.Id;
        rma.Opportunity__c = o.Id;
        rma.Customer_Expectation__c = 'Customer wants Equipment Back';
        rma.Date_RMA_Item_Received__c = system.today() - 20;
        rma.Date_Loaner_Shipped__c = system.today() - 10;
        rma.Quality_Issue_Notes__c = 'Bad image';
        rma.Tracking_number_of_RMA_Item_Received__c = '489561700';
        insert rma;

        Test.stopTest();
    }

    static testmethod void TestRMAUpdateTest2() {
        Pricebook2 pricebookstd = new Pricebook2(Name = 'Standard Price Book', isActive = true);
        //ProboCommonUtils.getStdPricebookId();
        insert pricebookstd;
        Opportunity o = TestDataFactory.createOpportunity('Sales Opportunity', null, true);
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);

        Test.startTest();

        RMA__c rma = TestDataFactory.createRMA('Loaner Return', false);
        rma.ProductItem__c = pi.Id;
        rma.Opportunity__c = o.Id;
        rma.Quality_Issue_Notes__c = 'Bad image';
        rma.Tracking_number_of_RMA_Item_Received__c = '489561700';
        rma.Date_Loaner_Shipped__c = system.today() - 10;
        insert rma;

        rma.Date_RMA_Item_Received__c = system.today() - 1;
        update rma;

        Test.stopTest();
    }

    static testmethod void TestRMAUpdateTest3() {
        Pricebook2 pricebookstd = new Pricebook2(Name = 'Standard Price Book', isActive = true);
        //ProboCommonUtils.getStdPricebookId();
        insert pricebookstd;
        Opportunity o = TestDataFactory.createOpportunity('Sales Opportunity', null, true);
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);

        Test.startTest();

        RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', false);
        rma.ProductItem__c = pi.Id;
        rma.Opportunity__c = o.Id;
        rma.Date_RMA_Item_Received__c = system.today() - 20;
        rma.Date_Loaner_Shipped__c = system.today() - 10;
        rma.Date_Repair_Approved__c = system.today() - 5;
        rma.Date_Last_Test_Completed__c = system.today();
        rma.Tracking_number_of_RMA_Item_Received__c = '489561700';
        insert rma;

        rma.ProductItem__c = pi.id;
        update rma;

        Test.stopTest();
    }
}