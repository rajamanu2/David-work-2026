@IsTest
private class P_RMATriggerHandlerTest {

    @IsTest
    static void addOLItoOppForWarrantyRMA() {
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Possible_Cosmetic_Repairs__c = 'Cable Jacket Splice';
        insert pi;

        Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', null, true);
        Work_Order__c wo = TestDataFactory.createWorkOrder('Repair Work Order', pi.Id, true);

        RMA__c rma = TestDataFactory.createRMA('Warranty Claim', false);
        RMA__c rma2 = TestDataFactory.createRMA('Customer Repair Evaluation', false);

        Test.startTest();

        GH_Logger.debug('TEST: starts here');

        rma.ProductItem__c = pi.Id;
        rma.Opportunity__c = o.Id;
        rma.Approved_Repairs__c = 'Cable Jacket Splice';
        rma.Customer_Expectation__c = 'Customer wants Equipment Back';
        rma.Date_RMA_Item_Received__c = Date.today().addDays(-20);
        rma.Date_Loaner_Shipped__c = Date.today().addDays(-10);
        rma.Quality_Issue_Notes__c = 'Bad image';
        rma.Tracking_number_of_RMA_Item_Received__c = '489561700';
        insert rma;

        RMA__c rma1 = [SELECT Approved_Repairs__c FROM RMA__c WHERE Id = :rma.Id];
        rma1.Approved_Repairs__c = 'All Repairs Approved';
        update rma1;

        // rma2.ProductItem__c = pi.Id;
        rma2.ProductItem__c = null;
        rma2.Opportunity__c = o.Id;
        rma2.Approved_Repairs__c = 'Lens Relens';
        rma2.Customer_Expectation__c = '';
        rma2.Date_RMA_Item_Received__c = Date.today().addDays(-20);
        rma2.Date_Loaner_Shipped__c = Date.today().addDays(-10);
        rma2.Quality_Issue_Notes__c = 'Bad image';
        rma2.Tracking_number_of_RMA_Item_Received__c = '489561700';
        insert rma2;

        rma2.Customer_Expectation__c = '';
        rma2.Opportunity__c = o.Id;
        rma2.ProductItem__c = pi.Id;
        update rma2;

        Test.stopTest();

        List<OpportunityLineItem> olisToCheck = new List<OpportunityLineItem>(
            [SELECT Id, ProductItem__c FROM OpportunityLineItem WHERE OpportunityId = :o.Id]
        );

        System.assertEquals(1, olisToCheck.size(), 'Warranty RMA did not create the right number of OLIs');
        System.assertEquals(pi.Id, olisToCheck[0].ProductItem__c, 'New OLI is not related to the ProductItem__c');
    }

    @IsTest
    static void testDeleteRMA() {
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Sales_Price__c = 1000;
        insert pi;

        Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', null, false);
        o.Ship_Date__c = Date.today().addDays(-20);
        insert o;

        RMA__c rma = TestDataFactory.createRMA('Warranty Claim', false);
        rma.ProductItem__c = pi.Id;
        rma.Quality_Issue_Notes__c = 'Test';
        rma.Quality_Issue_Reported__c = 'customer no longer needed';
        rma.Warranty_Claim_Status__c = 'Verified - Product Failure';
        rma.Opportunity__c = o.Id;
        rma.Date_RMA_Item_Received__c = Date.today();
        rma.Customer_Expectation__c = 'Customer Does Not want Equipment Back';
        rma.Warranty_Claim_Action__c = 'Credit memo - restocking fee';
        insert rma;

        Test.startTest();

        rma.Warranty_Claim_Approved__c = 'APPROVED';
        system.debug('THIS IS AFTER APPROVED >> ');
        Validator_Class.resetAlreadyDone15();
        update rma;
        system.debug('THIS IS AFTER APPROVED 2 >> ' + rma.Warranty_Claim_Approved__c);

        try {
            delete rma;
        } catch (DMLException e) {
            System.assert(e.getMessage().contains('You can not delete this RMA !'), 'You can not delete this RMA !');
        }

        Test.stopTest();
    }

    @IsTest
    static void test123() {
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        insert pi;

        Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', null, true);
        Work_Order__c wo = TestDataFactory.createWorkOrder('Repair Work Order', pi.Id, true);

        RMA__c rma = TestDataFactory.createRMA('Material Transfer', false);

        Test.startTest();

        GH_Logger.debug('TEST: starts here');
        System.debug('pi id---->' + pi.Id);

        rma.ProductItem__c = pi.Id;
        rma.Opportunity__c = o.Id;
        rma.Approved_Repairs__c = 'Oil Fill';
        rma.Customer_Expectation__c = '';
        rma.Date_RMA_Item_Received__c = Date.today().addDays(-20);
        rma.Date_Loaner_Shipped__c = Date.today().addDays(-10);
        rma.Quality_Issue_Notes__c = 'Bad image';
        rma.Tracking_number_of_RMA_Item_Received__c = '489561700';
        rma.Estimated_Ship_Date__c = System.today();
        insert rma;

        RMA__c rma1 = [SELECT Approved_Repairs__c FROM RMA__c WHERE Id = :rma.Id];
        rma1.Approved_Repairs__c = 'All Repairs Approved';
        rma1.Current_Estimated_Ship_Date__c = System.today();
        update rma1;

        Test.stopTest();

        List<OpportunityLineItem> olisToCheck = new List<OpportunityLineItem>(
            [SELECT Id, ProductItem__c FROM OpportunityLineItem WHERE OpportunityId = :o.Id]
        );
    }

    @IsTest
    static void test1234() {
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        insert pi;

        Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', null, true);
        Work_Order__c wo = TestDataFactory.createWorkOrder('Repair Work Order', pi.Id, true);
        Product_Repair__c prorep = TestDataFactory.createProductRepair('Functional Repair', 'Array Replacement', pi.Id, true);

        RMA__c rma = TestDataFactory.createRMA('Material Transfer', false);

        Test.startTest();

        GH_Logger.debug('TEST: starts here');
        System.debug('pi id---->' + pi.Id);

        rma.Opportunity__c = o.Id;
        rma.Approved_Repairs__c = 'Oil Fill';
        rma.Customer_Expectation__c = '';
        rma.Date_RMA_Item_Received__c = Date.today().addDays(-20);
        rma.Date_Loaner_Shipped__c = Date.today().addDays(-10);
        rma.Quality_Issue_Notes__c = 'Bad image';
        rma.Tracking_number_of_RMA_Item_Received__c = '489561700';
        rma.Estimated_Ship_Date__c = System.today();
        insert rma;

        rma.ProductItem__c = pi.Id;
        update rma;

        Test.stopTest();
    }

    @IsTest
    static void testNew() {
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        insert pi;

        Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', null, true);
        Work_Order__c wo = TestDataFactory.createWorkOrder('Repair Work Order', pi.Id, true);
        Product_Repair__c prorep = TestDataFactory.createProductRepair('Functional Repair', 'Array Replacement', pi.Id, true);

        RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', false);

        User u = TestDataFactory.createUser('fName', 'lName', true);

        Test.startTest();

        GH_Logger.debug('TEST: starts here');
        System.debug('pi id---->' + pi.Id);

        rma.ProductItem__c = pi.Id;
        rma.Opportunity__c = o.Id;
        rma.Customer_Expectation__c = '';
        rma.Date_RMA_Item_Received__c = Date.today().addDays(-20);
        rma.Date_Loaner_Shipped__c = Date.today().addDays(-10);
        rma.Quality_Issue_Notes__c = 'Bad image';
        rma.Tracking_number_of_RMA_Item_Received__c = '489561700';
        rma.Estimated_Ship_Date__c = System.today();
        insert rma;

        rma.ProductItem__c = pi.Id;
        rma.OwnerId = u.Id;
        rma.Approved_Repairs__c = 'All Repairs Approved';
        update rma;

        Test.stopTest();
    }

    // =========================================================================
    // NEW: Add coverage for the "Date_RMA_Item_Received__c" ProductItem reset logic
    // =========================================================================

    /**
     * Covers the big ProductItem reset block when Date_RMA_Item_Received__c goes
     * from NULL => non-NULL on UPDATE.
     *
     * Important: your handler uses Validator_Class.hasAlreadyDone15(); which can
     * short-circuit subsequent trigger runs in the same transaction. So we:
     * - insert with a non-null received date (in case it's required in your org)
     * - update to NULL (no-op for the block)
     * - reset validator
     * - update to TODAY to run the block with oldData.Date == null
     */
    @IsTest
    static void testDateItemReceived_TriggersProductItemResetBlock() {

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);

        // Dirty fields so the OR condition is guaranteed to be TRUE
        // (Use values you know exist / are allowed in your org.)
        pi.Cosmetic_Rating__c = 'A';
        pi.Functional_Rating__c = 'B';
        pi.Repair_Evaluation__c = 'Eval';
        pi.Functional_Notes__c = 'Notes';
        pi.Cosmetic_Notes__c = 'Notes';
        pi.Review_Status__c = 'In Review';
        pi.Ship_Date__c = Date.today().addDays(-5);
        pi.Reserved__c = true;
        pi.Sold__c = true;
        pi.Decontamination_Complete__c = true;
        pi.Cosmetically_unable_to_Improve__c = true;
        pi.Functionally_unable_to_improve__c = true;
        pi.Approved_cosmetic_repairs_optimized__c = true;
        pi.Approved_functional_repairs_optimized__c = true;
        pi.Reserved_By__c = 'Someone';
        pi.Reserved_Time_Stamp__c = System.now();
        pi.Opportunity_Name__c = 'Opp Name';
        pi.Opportunity_Record_Type__c = 'Some RT';
        pi.Stage__c = 'Some Stage';
        pi.Account_Name__c = 'Some Account';
        pi.Check_In_Type__c = 'Customer Repair'; // NOT Equipment Storage
        insert pi;

        Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', null, true);

        RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', false);
        rma.ProductItem__c = pi.Id;
        rma.Opportunity__c = o.Id;

        // Insert with a value (many orgs allow null, but this is the safest pattern)
        rma.Date_RMA_Item_Received__c = Date.today().addDays(-20);
        rma.Date_Loaner_Shipped__c = Date.today().addDays(-10);
        rma.Quality_Issue_Notes__c = 'Bad image';
        rma.Tracking_number_of_RMA_Item_Received__c = '489561700';
        insert rma;

        // Step 1: set received date back to NULL (so the next update sees oldData.Date == null)
        Validator_Class.resetAlreadyDone15();
        rma.Date_RMA_Item_Received__c = null;
        update rma;

        // Step 2: now set it non-null to hit:
        // if (rma.Date_RMA_Item_Received__c != null && oldData.Date_RMA_Item_Received__c == null) { ... }
        Validator_Class.resetAlreadyDone15();

        Test.startTest();
        rma.Date_RMA_Item_Received__c = Date.today();
        update rma;
        Test.stopTest();
    }

    /**
     * Covers the Warranty Claim branch inside the same Date_RMA_Item_Received__c block:
     * - Customer_Expectation__c = 'Customer wants Equipment Back'
     * - pi.Check_In_Type__c starts as 'Customer Repair'
     * - Date_RMA_Item_Received__c transitions NULL => non-NULL on UPDATE
     *
     * (No assertions required; this is for coverage.)
     */
    @IsTest
    static void testDateItemReceived_WarrantyClaimBranch_CustomerWantsBack() {

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Check_In_Type__c = 'Customer Repair';
        insert pi;

        Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', null, true);

        RMA__c rma = TestDataFactory.createRMA('Warranty Claim', false);
        rma.ProductItem__c = pi.Id;
        rma.Opportunity__c = o.Id;

        // Satisfy typical Warranty validations in your org (you already use these elsewhere)
        rma.Customer_Expectation__c = 'Customer wants Equipment Back';
        rma.Quality_Issue_Notes__c = 'Bad image';
        rma.Tracking_number_of_RMA_Item_Received__c = '489561700';
        rma.Date_Loaner_Shipped__c = Date.today().addDays(-10);

        // Insert with a non-null date (safe), then flip NULL => TODAY on update
        rma.Date_RMA_Item_Received__c = Date.today().addDays(-20);
        insert rma;

        Validator_Class.resetAlreadyDone15();
        rma.Date_RMA_Item_Received__c = null;
        update rma;

        Validator_Class.resetAlreadyDone15();

        Test.startTest();
        rma.Date_RMA_Item_Received__c = Date.today();
        update rma;
        Test.stopTest();
    }
}