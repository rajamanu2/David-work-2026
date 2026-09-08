@isTest
public class CreateApprovedRepairsTestClass {

    static testmethod void TestCreateApprovedRepairsTest() {
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', true);

        Test.startTest();

        rma.Approved_Repairs__c = 'All Repairs Approved';
        update rma;

        rma.Approved_Repairs__c = 'Cable Replacement';
        update rma;

        Test.stopTest();
    }
}