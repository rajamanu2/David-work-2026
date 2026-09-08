/**
 * @author Delegate
 * @date 7/21/2021
 *
 * @description Breaking out of P_RMATriggerHandlerTest
 */
@IsTest
public with sharing class P_RMATriggerHandlerTest2 {

    @TestSetup
    static void makeData() {

        List<Account> accts = TestDataFactory.createAccountsWithContacts(1, 1);
        User u = TestDataFactory.createUser('Adam', 'Walter', true);

        Opportunity opp = TestDataFactory.createOpportunity(
            'Lost Probe Opportunity',
            accts[0].Id,
            true
        );

        Contact con = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];

        TestDataFactory.createOpportunityContactRole(
            opp.Id,
            con.Id,
            true,
            'Business User',
            true
        );

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Probe_Type__c = 'Linear';
        insert pro;

        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);

        Work_Order__c w = TestDataFactory.createWorkOrder(
            'Repair Work Order',
            pi.Id,
            false
        );
        insert w;

        RMA__c rma = TestDataFactory.createRMA(
            'Customer Repair Evaluation',
            false
        );
        rma.Opportunity__c = opp.Id;
        // rma.ProductItem__c = pi.Id;
        rma.Approved_Repairs__c = null;
        rma.OwnerId = u.Id;
        insert rma;

        RMA__c rma1 = [
            SELECT OwnerId
            FROM RMA__c
            LIMIT 1
        ];
        System.debug(rma1);
    }

    @IsTest
    static void testAddProductItem() {
        Test.startTest();

        RMA__c rma = [
            SELECT Contact_Name__c
            FROM RMA__c
            LIMIT 1
        ];

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Probe_Type__c = 'Linear';
        insert pro;

        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        rma.ProductItem__c = pi.Id;
        update rma;

        Test.stopTest();
    }

    @IsTest
    public static void TestContactNameIsNull() {
        Test.startTest();

        RMA__c rma = [
            SELECT Contact_Name__c
            FROM RMA__c
            LIMIT 1
        ];
        rma.Contact_Name__c = null;
        update rma;

        Test.stopTest();
    }

    @IsTest
    public static void TestApprovedRepairsChanged() {
        Test.startTest();

        RMA__c rma = [
            SELECT Contact_Name__c
            FROM RMA__c
            LIMIT 1
        ];
        rma.Approved_Repairs__c = 'Cable Replacement';
        update rma;

        Test.stopTest();
    }
}