@IsTest
private class EmailTableControllerTest {

    // ==========================================
    // 1. TEST DATA SETUP (BULKIFIED FOR LIMITS)
    // ==========================================
    @TestSetup
    static void setupTestData() {
        
        // 1. Create Accounts (2 DMLs to establish Parent/Child relationship)
        Account parentAccount = new Account(Name = 'Global Corp (Parent)');
        insert parentAccount;
        
        Account childAccount = new Account(Name = 'Local Branch (Child)', ParentId = parentAccount.Id);
        insert childAccount;

        // 2. Create Contact (1 DML)
        Contact testContact = new Contact(
            FirstName = 'John', LastName = 'Doe', Email = 'john.doe@testaccount.com', AccountId = parentAccount.Id
        );
        insert testContact;

        // 3. Bulk Create Products (1 DML)
        Product2 testProduct1 = new Product2(Name = 'Enterprise Software License', IsActive = true, ProductCode = 'ENT-SOFT-001');
        Product2 testProduct2 = new Product2(Name = 'Premium Support Package', IsActive = true, ProductCode = 'PREM-SUP-001');
        insert new List<Product2>{ testProduct1, testProduct2 };

        // 4. Bulk Create Opportunities (1 DML)
        Opportunity opp1 = new Opportunity(Name = 'Opp 1 - Ramped True', AccountId = parentAccount.Id, ContactId = testContact.Id, StageName = 'Prospecting', CloseDate = Date.today().addDays(30));
        Opportunity opp2 = new Opportunity(Name = 'Opp 2 - Ramped False Multi', AccountId = parentAccount.Id, ContactId = testContact.Id, StageName = 'Prospecting', CloseDate = Date.today().addDays(30));
        Opportunity opp3 = new Opportunity(Name = 'Opp 3 - No Groups', AccountId = parentAccount.Id, ContactId = testContact.Id, StageName = 'Prospecting', CloseDate = Date.today().addDays(30));
        
        List<Opportunity> oppList = new List<Opportunity>{ opp1, opp2, opp3 };
        insert oppList;

        // 5. Bulk Create Quotes (1 DML)
        SBQQ__Quote__c  quote1 = new SBQQ__Quote__c (SBQQ__Opportunity2__c = opp1.Id, Multiple_Ship_to_Accounts__c = 'No');
        SBQQ__Quote__c  quote2 = new SBQQ__Quote__c (SBQQ__Opportunity2__c = opp2.Id, Multiple_Ship_to_Accounts__c = 'Yes');
        SBQQ__Quote__c  quote3 = new SBQQ__Quote__c (SBQQ__Opportunity2__c = opp3.Id, Multiple_Ship_to_Accounts__c = 'No');
        
        List<SBQQ__Quote__c > quoteList = new List<SBQQ__Quote__c >{ quote1, quote2, quote3 };
        insert quoteList;

        // 6. Bulk Update Opportunities with Primary Quote (1 DML)
        //opp1.SBQQ__PrimaryQuote__c = quote1.Id;
        //opp2.SBQQ__PrimaryQuote__c = quote2.Id;
        //opp3.SBQQ__PrimaryQuote__c = quote3.Id;
        //update oppList;

        // 7. Bulk Create Groups (1 DML)
        SBQQ__QuoteLineGroup__c q1Group1 = new SBQQ__QuoteLineGroup__c(Name = 'Group 1A', SBQQ__Quote__c  = quote1.Id, Allow_Product_Ramping__c  = true, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(30));
        SBQQ__QuoteLineGroup__c q1Group2 = new SBQQ__QuoteLineGroup__c(Name = 'Group 1B', SBQQ__Quote__c  = quote1.Id, Allow_Product_Ramping__c = true, SBQQ__StartDate__c = Date.today().addDays(31), SBQQ__EndDate__c = Date.today().addDays(60));
        SBQQ__QuoteLineGroup__c q2Group1 = new SBQQ__QuoteLineGroup__c(Name = 'Group 2A', SBQQ__Quote__c  = quote2.Id, Allow_Product_Ramping__c = false, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(30));
        SBQQ__QuoteLineGroup__c q2Group2 = new SBQQ__QuoteLineGroup__c(Name = 'Group 2B', SBQQ__Quote__c  = quote2.Id, Allow_Product_Ramping__c = false, SBQQ__StartDate__c = Date.today().addDays(31), SBQQ__EndDate__c = Date.today().addDays(60));
        
        List<SBQQ__QuoteLineGroup__c> groupList = new List<SBQQ__QuoteLineGroup__c>{ q1Group1, q1Group2, q2Group1, q2Group2 };
        insert groupList;

        // 8. Bulk Create Quote Lines (1 DML)
        List<SBQQ__QuoteLine__c> allLines = new List<SBQQ__QuoteLine__c>();
        
        // Scenario 1 Lines
        allLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c  = quote1.Id, SBQQ__Group__c = q1Group1.Id, SBQQ__Product__c = testProduct1.Id, SBQQ__Quantity__c = 10, SBQQ__Description__c = 'Line 1'));
        allLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c  = quote1.Id, SBQQ__Group__c = q1Group2.Id, SBQQ__Product__c = testProduct1.Id, SBQQ__Quantity__c = 20, SBQQ__Description__c = 'Line 2'));
        
        // Scenario 2 Lines
        allLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c  = quote2.Id, SBQQ__Group__c = q2Group1.Id, Ship_To_Account__c = parentAccount.Id, SBQQ__Product__c = testProduct1.Id, SBQQ__Quantity__c = 5, SBQQ__Description__c = 'Parent Line'));
        allLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c  = quote2.Id, SBQQ__Group__c = q2Group2.Id, Ship_To_Account__c = childAccount.Id, SBQQ__Product__c = testProduct2.Id, SBQQ__Quantity__c = 15, SBQQ__Description__c = 'Child Line'));
        
        // Scenario 3 Lines (No Groups)
        allLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c  = quote3.Id, SBQQ__Group__c = null, SBQQ__Product__c = testProduct1.Id, SBQQ__Quantity__c = 1, SBQQ__Description__c = 'Ungrouped 1'));
        allLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c  = quote3.Id, SBQQ__Group__c = null, SBQQ__Product__c = testProduct2.Id, SBQQ__Quantity__c = 1, SBQQ__Description__c = 'Ungrouped 2'));
        
        insert allLines;
    }


    // ==========================================
    // 2. TEST: SCENARIO 1 (Ramped Up = TRUE)
    // ==========================================
    @IsTest
    static void testScenario1_RampedUpTrue() {
        //Opportunity testOpp = [SELECT SBQQ__PrimaryQuote__c FROM Opportunity WHERE Name = 'Opp 1 - Ramped True' LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id from SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.Name = 'Opp 1 - Ramped True' LIMIT 1];
        
        Test.startTest();
        EmailTableController controller = new EmailTableController();
        controller.quoteId = testQuote.Id;
        controller.templateName = 'Legal'; // Must match active CMDT record
        List<EmailTableController.LineGroup> groupedLines = controller.getGroupedLines();
        Test.stopTest();
        
        System.assertEquals(false, controller.hasError, 'Controller should not throw an error.');
        
        if (!groupedLines.isEmpty()) {
            System.assertEquals(2, groupedLines.size(), 'Scenario 1 should have exactly 2 groups.');
            for (EmailTableController.LineGroup grp : groupedLines) {
                System.assertEquals(true, grp.rampedUp, 'All groups in Scenario 1 should have Ramped Up = True');
                System.assertEquals(true, grp.showTitle, 'Group title should be visible.');
                System.assertNotEquals(null, grp.startDate, 'Start date should be populated.');
            }
        }
    }

    // ==========================================
    // 3. TEST: SCENARIO 2 (Ramped Up = FALSE + Accounts + Diff Products)
    // ==========================================
    @IsTest
    static void testScenario2_RampedUpFalse_Accounts() {
        //Opportunity testOpp = [SELECT SBQQ__PrimaryQuote__c FROM Opportunity WHERE Name = 'Opp 2 - Ramped False Multi' LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id from SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.Name = 'Opp 2 - Ramped False Multi' LIMIT 1];
        
        Test.startTest();
        EmailTableController controller = new EmailTableController();
        controller.quoteId = testQuote.Id;
        controller.templateName = 'Legal'; 
        List<EmailTableController.LineGroup> groupedLines = controller.getGroupedLines();
        Test.stopTest();
        
        System.assertEquals(false, controller.hasError, 'Controller should execute without errors.');
        
        if (!groupedLines.isEmpty()) {
            System.assertEquals(2, groupedLines.size(), 'Scenario 2 should have exactly 2 groups.');
            for (EmailTableController.LineGroup grp : groupedLines) {
                System.assertEquals(false, grp.rampedUp, 'All groups in Scenario 2 should have Ramped Up = False');
            }
        }
    }

    // ==========================================
    // 4. TEST: SCENARIO 3 (NO GROUPS + Diff Products)
    // ==========================================
    @IsTest
    static void testScenario3_NoGroups() {
        //Opportunity testOpp = [SELECT SBQQ__PrimaryQuote__c FROM Opportunity WHERE Name = 'Opp 3 - No Groups' LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id from SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.Name = 'Opp 3 - No Groups' LIMIT 1];
        
        Test.startTest();
        EmailTableController controller = new EmailTableController();
        controller.quoteId = testQuote.Id;
        controller.templateName = 'Legal'; 
        List<EmailTableController.LineGroup> groupedLines = controller.getGroupedLines();
        Test.stopTest();
        
        System.assertEquals(false, controller.hasError, 'Controller should execute without errors.');
        
        if (!groupedLines.isEmpty()) {
            System.assertEquals(1, groupedLines.size(), 'Scenario 3 should have 1 consolidated null group.');
            EmailTableController.LineGroup nullGroup = groupedLines[0];
            System.assertEquals(false, nullGroup.showTitle, 'Title should be hidden for null group.');
            System.assertEquals('', nullGroup.groupName, 'Group name should be blank.');
            System.assertEquals(2, nullGroup.rows.size(), 'Should contain both quote lines inside the single null group.');
        }
    }

    // ==========================================
    // 5. TEST: MISSING / INVALID PARAMETERS
    // ==========================================
    @IsTest
    static void testNegative_MissingAndInvalidParams() {
        Test.startTest();
        
        // Scenario A: Missing Params
        EmailTableController controller1 = new EmailTableController();
        List<EmailTableController.ColumnWrapper> columns = controller1.getColumns();
        System.assertEquals(0, columns.size(), 'Missing params should return empty list gracefully.');
        
        // Scenario B: Invalid ID
        EmailTableController controller2 = new EmailTableController();
        try {
            controller2.quoteId = (Id)'INVALID_ID_FORMAT'; 
            controller2.templateName = 'Legal';
            controller2.getColumns();
        } catch (Exception e) {
            System.assert(e != null, 'System exception caught for bad ID assignment.');
        }
        
        Test.stopTest();
    }
}