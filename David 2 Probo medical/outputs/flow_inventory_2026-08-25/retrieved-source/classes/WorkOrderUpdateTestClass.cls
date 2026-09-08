@isTest
private class WorkOrderUpdateTestClass {

    static testmethod void TestWorkOrderUpdateTest1() {

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Other_Notes__c = 'Cable needs cleaned';
        pi.Repair_Due_Date__c = system.today() + 3;
        insert pi;
        
        Test.startTest();

        User u = TestDataFactory.createUser('Casey', 'Trogden', true);
        system.runas(u) {
            Work_Order__c wo = TestDataFactory.createWorkOrder('Repair Work Order', pi.Id, false);
            wo.Possible_Repairs__c = 'Cable Advanced Whitening';
            wo.Estimated_Ready_Date__c = system.today() + 3;
            wo.Quick_Repair_Selection__c = 'Only Cosmetic'; // this part may not be working 07.25.2021 NB but I don't think it is being used by end users right now.
            insert wo;
            Product_Repair__c pr = TestDataFactory.createProductRepair('Cosmetic Repair', 'Cable Advanced Whitening', pi.Id, false);
			pr.Work_Order__c = wo.id;
            insert pr;
            wo.Work_Order_Repairs__c = 'Cable Advanced Whitening';
            update wo;
            Work_Order__c wo1 = [SELECT Work_Order_Repairs__c FROM Work_Order__c];

            system.assert(wo1.Work_Order_Repairs__c == 'Cable Advanced Whitening', 'Assertion failed, Work Order was not updated as expected.');
        }

        Test.stopTest();
    }

    static testmethod void TestWorkOrderUpdateTest1B() {

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Other_Notes__c = 'Cable needs cleaned';
        pi.Repair_Due_Date__c = system.today() + 3;
        insert pi;

        Test.startTest();

        User u = TestDataFactory.createUser('Casey', 'Trogden', true);
        system.runas(u) {
            Work_Order__c wo = TestDataFactory.createWorkOrder('Repair Work Order', pi.Id, false);
            wo.Estimated_Ready_Date__c = system.today() + 3;
            insert wo;
            wo.Work_Order_Repairs__c = 'Strain Relief Replacement';
            update wo;
            Work_Order__c wo1 = [SELECT Work_Order_Repairs__c FROM Work_Order__c];

            system.assert(wo1.Work_Order_Repairs__c == 'Strain Relief Replacement', 'Assertion failed, Work Order was not updated as expected.');
        }

        Test.stopTest();
    }

    static testmethod void TestWorkOrderUpdateTest2() {

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Other_Notes__c = 'Cable needs cleaned';
        pi.Repair_Due_Date__c = system.today() + 3;
        insert pi;

        Test.startTest();

        User u = TestDataFactory.createUser('Casey', 'Trogden', true);
        system.runas(u) {
            Work_Order__c wo = TestDataFactory.createWorkOrder('Harvest Work Order', pi.Id, false);
            wo.Estimated_Ready_Date__c = system.today() + 3;
            insert wo;
            wo.Parts_to_Harvest__c = 'Cable';
            update wo;
            WO.Parts_to_Harvest__c = 'Array';
            update wo;
            Work_Order__c wo1 = [SELECT Parts_to_Harvest__c FROM Work_Order__c];

            system.assert(wo1.Parts_to_Harvest__c == 'Array', 'Assertion failed, Work Order was not updated as expected.');
        }

        Test.stopTest();
    }

    static testmethod void TestWorkOrderUpdateTest3() {

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Other_Notes__c = 'Cable needs cleaned';
        pi.Repair_Due_Date__c = system.today() + 3;
        insert pi;

        Test.startTest();

        User u = TestDataFactory.createUser('Casey', 'Trogden', true);
        system.runas(u) {
            Work_Order__c wo = TestDataFactory.createWorkOrder('Harvest Work Order', pi.Id, false);
            wo.Estimated_Ready_Date__c = system.today() + 3;
            wo.Parts_to_Harvest__c = 'Cable';
            insert wo;
            Work_Order__c wo1 = [SELECT Parts_to_Harvest__c FROM Work_Order__c];

            system.assert(wo1.Parts_to_Harvest__c == 'Cable', 'Assertion failed, Work Order was not created as expected.');
        }

        Test.stopTest();
    }
}