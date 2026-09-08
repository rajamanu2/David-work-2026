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

        ProductItem__c assetAfterRmaReceipt = [
            SELECT Cosmetic_Rating__c, Functional_Rating__c, Review_Status__c,
                   Repair_Evaluation__c, Functional_Notes__c, Cosmetic_Notes__c
            FROM ProductItem__c
            WHERE Id = :pi.Id
        ];
        System.assertEquals('A', assetAfterRmaReceipt.Cosmetic_Rating__c,
            'Case 00009998: RMA receipt must preserve Cosmetic Rating.');
        System.assertEquals('B', assetAfterRmaReceipt.Functional_Rating__c,
            'Case 00009998: RMA receipt must preserve Functional Rating.');
        System.assertEquals('In Review', assetAfterRmaReceipt.Review_Status__c,
            'Case 00009998: RMA receipt must preserve Review Status.');
        System.assertEquals(null, assetAfterRmaReceipt.Repair_Evaluation__c,
            'Other check-in evaluation fields must retain the existing reset behavior.');
        System.assertEquals(null, assetAfterRmaReceipt.Functional_Notes__c,
            'Functional notes must retain the existing reset behavior.');
        System.assertEquals(null, assetAfterRmaReceipt.Cosmetic_Notes__c,
            'Cosmetic notes must retain the existing reset behavior.');
    }

    /**
     * Case 00009998 regression and coverage for the Equipment Storage path.
     *
     * The first Product Item proves that asset qualification values are preserved
     * while the legacy Equipment Storage cleanup still runs. The second Product
     * Item reaches the final Date_RMA_Item_Received__c comparison without an
     * earlier OR condition short-circuiting the reset block.
     */
    @IsTest
    static void case00009998PreservesRatingsForEquipmentStorage() {
        Product2 productRecord = TestDataFactory.createProduct('Ultrasound Probe', true);
        List<ProductItem__c> productItems = TestDataFactory.createProductItems(2, productRecord.Id, false);

        ProductItem__c preservedItem = productItems[0];
        preservedItem.Check_In_Type__c = 'Equipment Storage';
        preservedItem.Cosmetic_Rating__c = 'A';
        preservedItem.Functional_Rating__c = 'B';
        preservedItem.Review_Status__c = 'In Review';
        preservedItem.Reserved_By__c = 'Case 00009998';
        preservedItem.Reserved_Time_Stamp__c = System.now();
        preservedItem.Opportunity_Name__c = 'Prior Opportunity';
        preservedItem.Opportunity_Record_Type__c = 'Prior Record Type';
        preservedItem.Stage__c = 'Prior Stage';
        preservedItem.Account_Name__c = 'Prior Account';

        User currentUser = [SELECT Location__c FROM User WHERE Id = :UserInfo.getUserId()];
        String expectedQaLocation = 'QA-Testing';
        if (currentUser.Location__c == 'Tampa, FL') {
            expectedQaLocation = 'Tampa, FL';
        } else if (currentUser.Location__c == 'Tulsa, OK') {
            expectedQaLocation = 'Tulsa - QA-Testing';
        } else if (currentUser.Location__c == 'Harrisburg, PA') {
            expectedQaLocation = 'Harrisburg, PA';
        } else if (currentUser.Location__c == 'Cleveland, OH') {
            expectedQaLocation = 'Cleveland, OH';
        }

        ProductItem__c lateConditionItem = productItems[1];
        lateConditionItem.Serial_No__c = 'CASE-00009998-LATE';
        lateConditionItem.Check_In_Type__c = 'Equipment Storage';
        lateConditionItem.Location__c = expectedQaLocation;
        insert productItems;

        Opportunity repairOpportunity = TestDataFactory.createOpportunity('Probe Sales Opportunity', null, true);
        List<RMA__c> rmas = new List<RMA__c>();
        for (ProductItem__c productItem : productItems) {
            RMA__c rmaRecord = TestDataFactory.createRMA('Warranty Claim', false);
            rmaRecord.ProductItem__c = productItem.Id;
            rmaRecord.Opportunity__c = repairOpportunity.Id;
            rmaRecord.Customer_Expectation__c = 'Customer wants Equipment Back';
            rmaRecord.Date_RMA_Item_Received__c = Date.today().addDays(-20);
            rmaRecord.Date_Loaner_Shipped__c = Date.today().addDays(-10);
            rmaRecord.Quality_Issue_Notes__c = 'Case 00009998 coverage';
            rmaRecord.Tracking_number_of_RMA_Item_Received__c = '489561700';
            rmas.add(rmaRecord);
        }
        // Insert separately so the second trigger invocation can reuse the
        // standard PricebookEntry created for the shared test product.
        for (RMA__c rmaRecord : rmas) {
            Validator_Class.resetAlreadyDone15();
            insert rmaRecord;
        }

        Validator_Class.resetAlreadyDone15();
        for (RMA__c rmaRecord : rmas) {
            rmaRecord.Date_RMA_Item_Received__c = null;
        }
        update rmas;

        Map<Id, ProductItem__c> itemsBeforeFinalReceipt = new Map<Id, ProductItem__c>([
            SELECT Cosmetic_Rating__c, Functional_Rating__c, Repair_Evaluation__c,
                   Cosmetically_Repairable__c, Functionally_Repairable__c,
                   Functional_Notes__c, Cosmetic_Notes__c, Review_Status__c,
                   Check_In_Type__c, Location__c, Ship_Date__c, Reserved__c, Sold__c,
                   Decontamination_Complete__c, Cosmetically_unable_to_Improve__c,
                   Functionally_unable_to_improve__c,
                   Approved_cosmetic_repairs_optimized__c,
                   Approved_functional_repairs_optimized__c, Reserved_By__c,
                   Reserved_Time_Stamp__c, Opportunity_Name__c,
                   Opportunity_Record_Type__c, Sales_Opportunity__c, Stage__c,
                   Account_Name__c, Date_RMA_Item_Received__c
            FROM ProductItem__c
            WHERE Id IN :productItems
        ]);
        preservedItem = itemsBeforeFinalReceipt.get(preservedItem.Id);
        preservedItem.Check_In_Type__c = 'Equipment Storage';
        preservedItem.Cosmetic_Rating__c = 'A';
        preservedItem.Functional_Rating__c = 'B';
        preservedItem.Review_Status__c = 'In Review';
        preservedItem.Reserved_By__c = 'Case 00009998';
        preservedItem.Reserved_Time_Stamp__c = System.now();
        preservedItem.Opportunity_Name__c = 'Prior Opportunity';
        preservedItem.Opportunity_Record_Type__c = 'Prior Record Type';
        preservedItem.Stage__c = 'Prior Stage';
        preservedItem.Account_Name__c = 'Prior Account';

        lateConditionItem = itemsBeforeFinalReceipt.get(lateConditionItem.Id);
        lateConditionItem.Check_In_Type__c = 'Equipment Storage';
        lateConditionItem.Cosmetic_Rating__c = null;
        lateConditionItem.Functional_Rating__c = null;
        lateConditionItem.Repair_Evaluation__c = null;
        lateConditionItem.Cosmetically_Repairable__c = null;
        lateConditionItem.Functionally_Repairable__c = null;
        lateConditionItem.Functional_Notes__c = null;
        lateConditionItem.Cosmetic_Notes__c = null;
        lateConditionItem.Review_Status__c = null;
        lateConditionItem.Location__c = expectedQaLocation;
        lateConditionItem.Ship_Date__c = null;
        lateConditionItem.Reserved__c = false;
        lateConditionItem.Sold__c = false;
        lateConditionItem.Decontamination_Complete__c = false;
        lateConditionItem.Cosmetically_unable_to_Improve__c = false;
        lateConditionItem.Functionally_unable_to_improve__c = false;
        lateConditionItem.Approved_cosmetic_repairs_optimized__c = false;
        lateConditionItem.Approved_functional_repairs_optimized__c = false;
        lateConditionItem.Reserved_By__c = null;
        lateConditionItem.Reserved_Time_Stamp__c = null;
        lateConditionItem.Opportunity_Name__c = null;
        lateConditionItem.Opportunity_Record_Type__c = null;
        lateConditionItem.Sales_Opportunity__c = null;
        lateConditionItem.Stage__c = null;
        lateConditionItem.Account_Name__c = null;
        Validator_Class.SetByPassProductItemTrigger(true);
        update new List<ProductItem__c>{ preservedItem, lateConditionItem };
        Validator_Class.SetByPassProductItemTrigger(false);

        Validator_Class.resetAlreadyDone15();
        Test.startTest();
        for (RMA__c rmaRecord : rmas) {
            rmaRecord.Date_RMA_Item_Received__c = Date.today();
        }
        update rmas;
        Test.stopTest();

        Map<Id, ProductItem__c> itemsAfterReceipt = new Map<Id, ProductItem__c>([
            SELECT Cosmetic_Rating__c, Functional_Rating__c, Review_Status__c,
                   Reserved_By__c, Reserved_Time_Stamp__c, Opportunity_Name__c,
                   Opportunity_Record_Type__c, Sales_Opportunity__c, Stage__c,
                   Account_Name__c, Date_RMA_Item_Received__c
            FROM ProductItem__c
            WHERE Id IN :productItems
        ]);
        ProductItem__c preservedAfterReceipt = itemsAfterReceipt.get(preservedItem.Id);
        System.assertEquals('A', preservedAfterReceipt.Cosmetic_Rating__c,
            'Case 00009998: Equipment Storage must preserve Cosmetic Rating.');
        System.assertEquals('B', preservedAfterReceipt.Functional_Rating__c,
            'Case 00009998: Equipment Storage must preserve Functional Rating.');
        System.assertEquals('In Review', preservedAfterReceipt.Review_Status__c,
            'Case 00009998: Equipment Storage must preserve Review Status.');
        System.assertEquals(null, preservedAfterReceipt.Reserved_By__c,
            'Equipment Storage must retain the existing reservation cleanup.');
        System.assertEquals(null, preservedAfterReceipt.Reserved_Time_Stamp__c,
            'Equipment Storage must retain the existing timestamp cleanup.');
        System.assertEquals(null, preservedAfterReceipt.Opportunity_Name__c,
            'Equipment Storage must retain the existing Opportunity cleanup.');
        System.assertEquals(Date.today(), itemsAfterReceipt.get(lateConditionItem.Id).Date_RMA_Item_Received__c,
            'The final received-date comparison must execute the reset block.');
    }

    /**
     * Covers the Warranty Claim branch inside the same Date_RMA_Item_Received__c block:
     * - Customer_Expectation__c = 'Customer wants Equipment Back'
     * - pi.Check_In_Type__c starts as 'Customer Repair'
     * - Date_RMA_Item_Received__c transitions NULL => non-NULL on UPDATE
     *
     * The assertions verify the intended Warranty Claim behavior and the
     * RMA quality-issue synchronization branch.
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

        ProductItem__c productItemBeforeFinalReceipt = [
            SELECT RMA_Quality_Issue_Reported__c
            FROM ProductItem__c
            WHERE Id = :pi.Id
        ];
        productItemBeforeFinalReceipt.RMA_Quality_Issue_Reported__c = null;
        Validator_Class.SetByPassProductItemTrigger(true);
        update productItemBeforeFinalReceipt;
        Validator_Class.SetByPassProductItemTrigger(false);

        Validator_Class.resetAlreadyDone15();

        Test.startTest();
        rma.Quality_Issue_Reported__c = 'customer no longer needed';
        rma.Date_RMA_Item_Received__c = Date.today();
        update rma;
        Test.stopTest();

        ProductItem__c productItemAfterReceipt = [
            SELECT Check_In_Type__c, RMA_Quality_Issue_Reported__c
            FROM ProductItem__c
            WHERE Id = :pi.Id
        ];
        System.assertEquals('Customer Repair', productItemAfterReceipt.Check_In_Type__c,
            'Warranty Claim receipt must retain an existing Customer Repair check-in type.');
        System.assertEquals('customer no longer needed', productItemAfterReceipt.RMA_Quality_Issue_Reported__c,
            'Warranty Claim receipt must synchronize the reported quality issue.');
    }
}
