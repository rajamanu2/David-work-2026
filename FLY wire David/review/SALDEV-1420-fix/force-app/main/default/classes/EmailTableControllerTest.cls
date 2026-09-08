@IsTest
private class EmailTableControllerTest {

    // ==========================================
    // 1. TEST DATA SETUP (BULKIFIED FOR LIMITS)
    // ==========================================
    @TestSetup
    static void setupTestData() {
        Test.startTest();
        
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

        // 7. Bulk Create Groups (1 DML) - Added SBQQ__SubscriptionTerm__c to support new header logic
        SBQQ__QuoteLineGroup__c q1Group1 = new SBQQ__QuoteLineGroup__c(Name = 'Group 1A', SBQQ__Quote__c  = quote1.Id, Allow_Product_Ramping__c  = true, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(30), SBQQ__SubscriptionTerm__c = 24);
        SBQQ__QuoteLineGroup__c q1Group2 = new SBQQ__QuoteLineGroup__c(Name = 'Group 1B', SBQQ__Quote__c  = quote1.Id, Allow_Product_Ramping__c = true, SBQQ__StartDate__c = Date.today().addDays(31), SBQQ__EndDate__c = Date.today().addDays(60), SBQQ__SubscriptionTerm__c = 12);
        SBQQ__QuoteLineGroup__c q2Group1 = new SBQQ__QuoteLineGroup__c(Name = 'Group 2A', SBQQ__Quote__c  = quote2.Id, Allow_Product_Ramping__c = false, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(30), SBQQ__SubscriptionTerm__c = 36);
        SBQQ__QuoteLineGroup__c q2Group2 = new SBQQ__QuoteLineGroup__c(Name = 'Group 2B', SBQQ__Quote__c  = quote2.Id, Allow_Product_Ramping__c = false, SBQQ__StartDate__c = Date.today().addDays(31), SBQQ__EndDate__c = Date.today().addDays(60)); // Left term blank to test fallback logic
        
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
        Test.stopTest();
    }


    // ==========================================
    // 2. TEST: SCENARIO 1 
    // ==========================================
    @IsTest
    static void testScenario1_RampedUpTrue() {
        SBQQ__Quote__c testQuote = [SELECT Id from SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.Name = 'Opp 1 - Ramped True' LIMIT 1];
        
        Test.startTest();
        EmailTableController controller = new EmailTableController();
        controller.quoteId = testQuote.Id;
        controller.templateName = 'Legal'; // Must match active CMDT record
        List<EmailTableController.LineGroup> groupedLines = controller.getGroupedLines();
        Test.stopTest();
        
        System.assertEquals(false, controller.hasError, 'Controller should not throw an error.');
        
        System.assert(!groupedLines.isEmpty(), 'Expected quote lines must not be silently omitted.');
        {
            System.assertEquals(2, groupedLines.size(), 'Scenario 1 should have exactly 2 groups.');
            for (EmailTableController.LineGroup grp : groupedLines) {
                System.assertEquals(true, grp.showTitle, 'Group title should be visible.');
                System.assert(grp.groupName.startsWith('Term'), 'Group name should contain the dynamically generated Term prefix.');
            }
        }
    }

    // ==========================================
    // 3. TEST: SCENARIO 2 
    // ==========================================
    @IsTest
    static void testScenario2_RampedUpFalse_Accounts() {
        SBQQ__Quote__c testQuote = [SELECT Id from SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.Name = 'Opp 2 - Ramped False Multi' LIMIT 1];
        
        Test.startTest();
        EmailTableController controller = new EmailTableController();
        controller.quoteId = testQuote.Id;
        controller.templateName = 'Legal'; 
        List<EmailTableController.LineGroup> groupedLines = controller.getGroupedLines();
        Test.stopTest();
        
        System.assertEquals(false, controller.hasError, 'Controller should execute without errors.');
        
        System.assert(!groupedLines.isEmpty(), 'Expected quote lines must not be silently omitted.');
        {
            System.assertEquals(2, groupedLines.size(), 'Scenario 2 should have exactly 2 groups.');
            for (EmailTableController.LineGroup grp : groupedLines) {
                System.assertEquals(true, grp.showTitle, 'Group title should be visible.');
                System.assert(grp.groupName.startsWith('Term'), 'Group name should contain the dynamically generated Term prefix.');
            }
        }
    }

    // ==========================================
    // 4. TEST: SCENARIO 3 (NO GROUPS)
    // ==========================================
    @IsTest
    static void testScenario3_NoGroups() {
        SBQQ__Quote__c testQuote = [SELECT Id from SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.Name = 'Opp 3 - No Groups' LIMIT 1];
        
        Test.startTest();
        EmailTableController controller = new EmailTableController();
        controller.quoteId = testQuote.Id;
        controller.templateName = 'Legal'; 
        List<EmailTableController.LineGroup> groupedLines = controller.getGroupedLines();
        Test.stopTest();
        
        System.assertEquals(false, controller.hasError, 'Controller should execute without errors.');
        
        System.assert(!groupedLines.isEmpty(), 'Expected quote lines must not be silently omitted.');
        {
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

    private static List<EmailTableController.LineGroup> rendered(Id quoteId, String context) {
        EmailTableController c = new EmailTableController();
        c.quoteId = quoteId;
        c.templateName = context;
        List<EmailTableController.LineGroup> groups = c.getGroupedLines();
        System.assertEquals(false, c.hasError, c.errorMessage);
        System.assert(!groups.isEmpty(), 'Expected populated output for ' + context);
        return groups;
    }

    @IsTest
    static void testMixedTermsChronologyAndTies() {
        Test.startTest();
        Id quoteId = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.Name = 'Opp 1 - Ramped True' LIMIT 1].Id;
        Id productId = [SELECT Id FROM Product2 WHERE ProductCode = 'ENT-SOFT-001' LIMIT 1].Id;
        delete [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quoteId];
        delete [SELECT Id FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c = :quoteId];
        Date start = Date.newInstance(2026, 1, 1);
        List<SBQQ__QuoteLineGroup__c> groups = new List<SBQQ__QuoteLineGroup__c>();
        List<Integer> months = new List<Integer>{24,12,36,72,72,6};
        List<Integer> years = new List<Integer>{0,2,3,0,0,4};
        for (Integer i=0; i<months.size(); i++) {
            groups.add(new SBQQ__QuoteLineGroup__c(
                Name = i == 3 ? 'Z first equal term' : 'A group ' + i,
                SBQQ__Quote__c = quoteId, SBQQ__Number__c = i+1,
                SBQQ__StartDate__c = start.addYears(years[i]),
                SBQQ__SubscriptionTerm__c = months[i],
                Allow_Product_Ramping__c = i < 3));
        }
        insert groups;
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        for (Integer i=0; i<groups.size(); i++) {
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteId, SBQQ__Group__c=groups[i].Id,
                SBQQ__Product__c=productId, SBQQ__Quantity__c=1, SBQQ__Number__c=i+1,
                External_Description__c='Group marker '+i, SBQQ__Description__c='Group marker '+i));
        }
        insert lines;
        for (String context : new List<String>{'Legal','Quote Approval','Revenue Approval'}) {
            List<EmailTableController.LineGroup> result = rendered(quoteId,context);
            System.assertEquals(6,result.size());
            List<Integer> expected = new List<Integer>{3,4,0,1,2,5};
            for (Integer i=0;i<expected.size();i++) {
                System.assertEquals('Term '+(i+1)+': '+months[expected[i]]+' months',result[i].groupName);
                System.assertEquals(1,result[i].rows.size());
                System.assert(result[i].rows[0].cellValues.contains('Group marker '+expected[i]), 'Exact date, term and QLE tie order');
            }
        }
    }

    @IsTest
    static void testQleSequenceWithNestedBundleAndUngrouped() {
        Id quoteId = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.Name = 'Opp 3 - No Groups' LIMIT 1].Id;
        delete [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quoteId];
        List<Product2> products = new List<Product2>();
        for (String name : new List<String>{'Z parent','Z child','A sibling','A standalone','Nested child'}) {
            products.add(new Product2(Name=name,IsActive=true));
        }
        insert products;
        SBQQ__QuoteLine__c parentLine = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteId,SBQQ__Product__c=products[0].Id,SBQQ__Quantity__c=1,SBQQ__Number__c=1);
        insert parentLine;
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        for (Integer i=1;i<4;i++) {
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteId,SBQQ__Product__c=products[i].Id,
                SBQQ__Quantity__c=1,SBQQ__Number__c=i+1,SBQQ__RequiredBy__c=i<3?parentLine.Id:null));
        }
        insert lines;
        insert new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteId,SBQQ__Product__c=products[4].Id,
            SBQQ__Quantity__c=1,SBQQ__Number__c=5,SBQQ__RequiredBy__c=lines[0].Id);
        Test.startTest();
        for (String context : new List<String>{'Legal','Quote Approval','Revenue Approval'}) {
            List<EmailTableController.LineGroup> result = rendered(quoteId,context);
            System.assertEquals(1,result.size());
            System.assertEquals(false,result[0].showTitle);
            List<String> expected = new List<String>{'Z parent','Z child','Nested child','A sibling','A standalone'};
            System.assertEquals(expected.size(),result[0].rows.size());
            for(Integer i=0;i<expected.size();i++) {
                System.assertEquals(expected[i],result[0].rows[i].cellValues[0],'QLE sequence with hierarchy');
            }
        }
    }

    @IsTest
    static void testDescriptionBlankRateAndColumnOrder() {
        EmailTableController.ColumnWrapper column = new EmailTableController.ColumnWrapper('Description','CONCAT: External_Description__c, Rate_Details__c');
        SBQQ__QuoteLine__c line = new SBQQ__QuoteLine__c(External_Description__c=' Description ',Rate_Details__c=' Rate ');
        System.assertEquals('Description; Rate',column.extractCellValue(line));
        line.Rate_Details__c='   ';
        System.assertEquals('Description',column.extractCellValue(line));
        line.External_Description__c=null;
        System.assertEquals('',column.extractCellValue(line));
        line.Rate_Details__c='Rate';
        System.assertEquals('Rate',column.extractCellValue(line));
        Id quoteId = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.Name = 'Opp 3 - No Groups' LIMIT 1].Id;
        EmailTableController c=new EmailTableController(); c.quoteId=quoteId; c.templateName='Quote Approval';
        List<EmailTableController.ColumnWrapper> columns=c.getColumns();
        System.assertEquals(false,c.hasError);
        System.assertEquals(8,columns.size());
        System.assertEquals('Billing Frequency',columns[4].header);
        System.assertEquals('Subscription Type',columns[5].header);
    }

}
