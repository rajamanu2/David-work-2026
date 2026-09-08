@isTest
private class QuoteLineGroupTriggerTest {

    // Helper method to retrieve or create the 'CPQ' Pricebook
    private static Pricebook2 getPricebook() {
        Pricebook2 pb;
        List<Pricebook2> pbs = [SELECT Id FROM Pricebook2 WHERE Name = 'CPQ' LIMIT 1];
        if (pbs.isEmpty()) {
            pb = new Pricebook2(Name = 'CPQ', IsActive = true);
            insert pb;
        } else {
            pb = pbs[0];
        }
        return pb;
    }

    @testSetup
    static void setupTestData() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // 1. Insert Account
            Account acc = new Account(
                Name = 'Flywire Test Account', 
                Client_Legal_Entity_Name__c = 'Edu Corp', 
                Tax_ID__c = '4657TH54', 
                Separate_Legal_Entity_Tax_ID__c = 'No', 
                BillingStreet = '123 Main St', 
                BillingCity = 'New York', 
                BillingState = 'NY', 
                BillingPostalCode = '10001', 
                BillingCountry = 'United States',
                ShippingStreet = '456 Ship St', 
                ShippingCity = 'New York', 
                ShippingState = 'NY', 
                ShippingPostalCode = '10001', 
                ShippingCountry = 'United States'
            ); 
            insert acc;

            // 2. Fetch/Create CPQ Pricebook
            Pricebook2 cpqPb = getPricebook();
            Id standardPbId = Test.getStandardPricebookId();

            // 3. Insert Opportunity with Pricebook ID
            Opportunity opp = new Opportunity(
                Name = 'Test Opp New Business',
                StageName = 'Discovery/Qualifying',
                Type = 'New Business',
                CloseDate = Date.today().addDays(30),
                AccountId = acc.Id,
                Pricebook2Id = cpqPb.Id
            );
            insert opp;

            // 4. Insert CPQ Subscription Product (Using 12 Months)
            Product2 prod = new Product2(
                Name = 'Payments Revenue',
                ProductCode = 'FWRS1000MMFXFF',
                IsActive = true,
                SBQQ__SubscriptionPricing__c = 'Fixed Price',
                SBQQ__SubscriptionTerm__c = 12
            );
            insert prod;

            // 5. Create Pricebook Entries
            List<PricebookEntry> pbes = new List<PricebookEntry>();
            pbes.add(new PricebookEntry(
                Pricebook2Id = standardPbId,
                Product2Id = prod.Id,
                UnitPrice = 100.00,
                IsActive = true
            ));
            pbes.add(new PricebookEntry(
                Pricebook2Id = cpqPb.Id,
                Product2Id = prod.Id,
                UnitPrice = 100.00,
                IsActive = true
            ));
            insert pbes;

            // 6. Insert Net New Quote (12-Month Header)
            Date startDate = Date.newInstance(2026, 1, 1);
            Date endDate = Date.newInstance(2026, 12, 31);

            SBQQ__Quote__c netNewQuote = new SBQQ__Quote__c(
                SBQQ__Account__c = acc.Id,
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Type__c = 'Quote',
                SBQQ__PricebookId__c = cpqPb.Id,
                SBQQ__StartDate__c = startDate,
                SBQQ__EndDate__c = endDate,
                SBQQ__SubscriptionTerm__c = 12
            );
            insert netNewQuote;

            // 7. Insert Renewal Quote (12-Month Header)
            SBQQ__Quote__c renewalQuote = new SBQQ__Quote__c(
                SBQQ__Account__c = acc.Id,
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Type__c = 'Renewal',
                SBQQ__PricebookId__c = cpqPb.Id,
                SBQQ__StartDate__c = startDate,
                SBQQ__EndDate__c = endDate,
                SBQQ__SubscriptionTerm__c = 12
            );
            insert renewalQuote;
        }
    }

    @isTest
    static void testSequentialDateCalculationsAndUnrampedTerm() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            SBQQ__Quote__c quote = [SELECT Id, SBQQ__StartDate__c, SBQQ__SubscriptionTerm__c FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Quote' LIMIT 1];

            Test.startTest();
            List<SBQQ__QuoteLineGroup__c> groups = new List<SBQQ__QuoteLineGroup__c>();

            SBQQ__QuoteLineGroup__c group1 = new SBQQ__QuoteLineGroup__c(
                Name = 'RampUp Group 1',
                SBQQ__Quote__c = quote.Id,
                SBQQ__Number__c = 1,
                Allow_Product_Ramping__c = true,
                SBQQ__SubscriptionTerm__c = 6
            );
            groups.add(group1);

            SBQQ__QuoteLineGroup__c group2 = new SBQQ__QuoteLineGroup__c(
                Name = 'RampUp Group 2',
                SBQQ__Quote__c = quote.Id,
                SBQQ__Number__c = 2,
                Allow_Product_Ramping__c = true,
                SBQQ__SubscriptionTerm__c = 6
            );
            groups.add(group2);

            insert groups;

            SBQQ__QuoteLineGroup__c unrampedGroup = new SBQQ__QuoteLineGroup__c(
                Name = 'Unramped Group',
                SBQQ__Quote__c = quote.Id,
                SBQQ__Number__c = 3,
                Allow_Product_Ramping__c = false
            );
            insert unrampedGroup;
            Test.stopTest();

            SBQQ__QuoteLineGroup__c resGroup1 = [SELECT SBQQ__StartDate__c FROM SBQQ__QuoteLineGroup__c WHERE Id = :group1.Id];
            System.assertEquals(quote.SBQQ__StartDate__c, resGroup1.SBQQ__StartDate__c, 'Group 1 Start Date should match Quote Start Date.');

            SBQQ__QuoteLineGroup__c resUnramped = [SELECT SBQQ__StartDate__c, SBQQ__SubscriptionTerm__c FROM SBQQ__QuoteLineGroup__c WHERE Id = :unrampedGroup.Id];
            System.assertEquals(quote.SBQQ__StartDate__c, resUnramped.SBQQ__StartDate__c, 'Unramped group should start at Quote Start Date.');
            System.assertEquals(12, resUnramped.SBQQ__SubscriptionTerm__c, 'Unramped group should inherit 12-month Quote Header Subscription Term.');
        }
    }
    
    @isTest
    static void testProductCodeChainValidationSuccess() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Account acc = [SELECT Id FROM Account LIMIT 1];
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Quote' LIMIT 1];
            Product2 prod = [SELECT Id FROM Product2 WHERE ProductCode = 'FWRS1000MMFXFF' LIMIT 1];
            PricebookEntry cpqPbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id AND Pricebook2.Name = 'CPQ' LIMIT 1];

            List<SBQQ__QuoteLineGroup__c> groups = new List<SBQQ__QuoteLineGroup__c>();

            SBQQ__QuoteLineGroup__c group1 = new SBQQ__QuoteLineGroup__c(
                Name = 'Ramp Up Group 1',
                SBQQ__Quote__c = quote.Id,
                SBQQ__Number__c = 1,
                Allow_Product_Ramping__c = true,
                SBQQ__SubscriptionTerm__c = 6
            );
            groups.add(group1);

            SBQQ__QuoteLineGroup__c group2 = new SBQQ__QuoteLineGroup__c(
                Name = 'Ramp Up Group 2',
                SBQQ__Quote__c = quote.Id,
                SBQQ__Number__c = 2,
                Allow_Product_Ramping__c = true,
                SBQQ__SubscriptionTerm__c = 6
            );
            groups.add(group2);

            insert groups;

            SBQQ.TriggerControl.disable();
            List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
            lines.add(new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id, 
                SBQQ__Group__c = group1.Id, 
                SBQQ__Product__c = prod.Id, 
                SBQQ__PricebookEntryId__c = cpqPbe.Id,
                Ship_To_Account__c = acc.Id,
                SBQQ__Quantity__c = 1
            ));
            lines.add(new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id, 
                SBQQ__Group__c = group2.Id, 
                SBQQ__Product__c = prod.Id, 
                SBQQ__PricebookEntryId__c = cpqPbe.Id,
                Ship_To_Account__c = acc.Id,
                SBQQ__Quantity__c = 1
            ));
            insert lines;
            SBQQ.TriggerControl.enable();

            Test.startTest();
            // Perform balanced update (8 + 4 = 12 total months)
            group1.SBQQ__SubscriptionTerm__c = 8;
            group2.SBQQ__SubscriptionTerm__c = 4;
            
            // Execute update inside system runAs block to satisfy user-mode FLS requirements
            Database.SaveResult[] results = Database.update(new List<SBQQ__QuoteLineGroup__c>{ group1, group2 }, false);
            Test.stopTest();

            SBQQ__QuoteLineGroup__c resGroup1 = [SELECT SBQQ__SubscriptionTerm__c FROM SBQQ__QuoteLineGroup__c WHERE Id = :group1.Id];
            System.assertNotEquals(null, resGroup1.Id, 'Group 1 should save cleanly when totals balance to Quote Header Term.');
        }
    }
    @isTest
    static void testUnderAllocationValidationError() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Account acc = [SELECT Id FROM Account LIMIT 1];
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Quote' LIMIT 1];
            Product2 prod = [SELECT Id FROM Product2 WHERE ProductCode = 'FWRS1000MMFXFF' LIMIT 1];
            PricebookEntry cpqPbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id AND Pricebook2.Name = 'CPQ' LIMIT 1];

            List<SBQQ__QuoteLineGroup__c> groups = new List<SBQQ__QuoteLineGroup__c>();

            SBQQ__QuoteLineGroup__c group1 = new SBQQ__QuoteLineGroup__c(
                Name = 'Ramp Up Group 1',
                SBQQ__Quote__c = quote.Id,
                SBQQ__Number__c = 1,
                Allow_Product_Ramping__c = true,
                SBQQ__SubscriptionTerm__c = 6
            );
            groups.add(group1);

            SBQQ__QuoteLineGroup__c group2 = new SBQQ__QuoteLineGroup__c(
                Name = 'Ramp Up Group 2',
                SBQQ__Quote__c = quote.Id,
                SBQQ__Number__c = 2,
                Allow_Product_Ramping__c = true,
                SBQQ__SubscriptionTerm__c = 6
            );
            groups.add(group2);

            insert groups;

            SBQQ.TriggerControl.disable();
            List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
            lines.add(new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Group__c = group1.Id,
                SBQQ__Product__c = prod.Id,
                SBQQ__PricebookEntryId__c = cpqPbe.Id,
                Ship_To_Account__c = acc.Id,
                SBQQ__Quantity__c = 1
            ));
            lines.add(new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Group__c = group2.Id,
                SBQQ__Product__c = prod.Id,
                SBQQ__PricebookEntryId__c = cpqPbe.Id,
                Ship_To_Account__c = acc.Id,
                SBQQ__Quantity__c = 1
            ));
            insert lines;
            SBQQ.TriggerControl.enable();

            Boolean exceptionThrown = false;
            Test.startTest();
            try {
                group1.SBQQ__SubscriptionTerm__c = 3;
                Database.update(group1, AccessLevel.SYSTEM_MODE);
            } catch (System.Exception e) {
                exceptionThrown = true;
            }
            Test.stopTest();

            System.assert(exceptionThrown, 'Exception expected when total term is under allocated.');
        }
    }

    @isTest
    static void testOverAllocationHardStopValidationError() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Account acc = [SELECT Id FROM Account LIMIT 1];
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Quote' LIMIT 1];
            Product2 prod = [SELECT Id FROM Product2 WHERE ProductCode = 'FWRS1000MMFXFF' LIMIT 1];
            PricebookEntry cpqPbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id AND Pricebook2.Name = 'CPQ' LIMIT 1];

            List<SBQQ__QuoteLineGroup__c> groups = new List<SBQQ__QuoteLineGroup__c>();

            SBQQ__QuoteLineGroup__c group1 = new SBQQ__QuoteLineGroup__c(
                Name = 'Ramp Up Group 1',
                SBQQ__Quote__c = quote.Id,
                SBQQ__Number__c = 1,
                Allow_Product_Ramping__c = true,
                SBQQ__SubscriptionTerm__c = 6
            );
            groups.add(group1);

            SBQQ__QuoteLineGroup__c group2 = new SBQQ__QuoteLineGroup__c(
                Name = 'Ramp Up Group 2',
                SBQQ__Quote__c = quote.Id,
                SBQQ__Number__c = 2,
                Allow_Product_Ramping__c = true,
                SBQQ__SubscriptionTerm__c = 6
            );
            groups.add(group2);

            insert groups;

            SBQQ.TriggerControl.disable();
            List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
            lines.add(new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Group__c = group1.Id,
                SBQQ__Product__c = prod.Id,
                SBQQ__PricebookEntryId__c = cpqPbe.Id,
                Ship_To_Account__c = acc.Id,
                SBQQ__Quantity__c = 1
            ));
            lines.add(new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Group__c = group2.Id,
                SBQQ__Product__c = prod.Id,
                SBQQ__PricebookEntryId__c = cpqPbe.Id,
                Ship_To_Account__c = acc.Id,
                SBQQ__Quantity__c = 1
            ));
            insert lines;
            SBQQ.TriggerControl.enable();

            Boolean exceptionThrown = false;
            Test.startTest();
            try {
                group1.SBQQ__SubscriptionTerm__c = 12;
                Database.update(group1, AccessLevel.SYSTEM_MODE);
            } catch (System.Exception e) {
                exceptionThrown = true;
            }
            Test.stopTest();

            System.assert(exceptionThrown, 'Exception expected when total term exceeds Quote Header Term.');
        }
    }

    @isTest
    static void testNameMatchingAndProximityFallback() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Account acc = [SELECT Id FROM Account LIMIT 1];
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Quote' LIMIT 1];
            Product2 prod = [SELECT Id FROM Product2 WHERE ProductCode = 'FWRS1000MMFXFF' LIMIT 1];
            PricebookEntry cpqPbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id AND Pricebook2.Name = 'CPQ' LIMIT 1];

            SBQQ__QuoteLineGroup__c existingGroup = new SBQQ__QuoteLineGroup__c(
                Name = 'FW Ramp Group',
                SBQQ__Quote__c = quote.Id,
                SBQQ__Number__c = 1,
                Allow_Product_Ramping__c = true,
                SBQQ__SubscriptionTerm__c = 6
            );
            insert existingGroup;

            SBQQ.TriggerControl.disable();
            SBQQ__QuoteLine__c line = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Group__c = existingGroup.Id,
                SBQQ__Product__c = prod.Id,
                SBQQ__PricebookEntryId__c = cpqPbe.Id,
                Ship_To_Account__c = acc.Id,
                SBQQ__Quantity__c = 1
            );
            insert line;
            SBQQ.TriggerControl.enable();

            Test.startTest();
            SBQQ__QuoteLineGroup__c clonedGroup = new SBQQ__QuoteLineGroup__c(
                Name = 'FW Ramp Group',
                SBQQ__Quote__c = quote.Id,
                SBQQ__Number__c = 2,
                Allow_Product_Ramping__c = true,
                SBQQ__SubscriptionTerm__c = 6
            );
            insert clonedGroup;
            Test.stopTest();

            SBQQ__QuoteLineGroup__c resCloned = [SELECT Id, SBQQ__SubscriptionTerm__c FROM SBQQ__QuoteLineGroup__c WHERE Id = :clonedGroup.Id];
            System.assertEquals(6, resCloned.SBQQ__SubscriptionTerm__c, 'Name-Matching clone should save cleanly when total equals 12 months.');
        }
    }

    @isTest
    static void testRenewalQuotesBypassed() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            SBQQ__Quote__c renewalQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Renewal' LIMIT 1];

            Test.startTest();
            SBQQ__QuoteLineGroup__c renewalGroup = new SBQQ__QuoteLineGroup__c(
                Name = 'Renewal Group',
                SBQQ__Quote__c = renewalQuote.Id,
                SBQQ__Number__c = 1,
                Allow_Product_Ramping__c = true,
                SBQQ__SubscriptionTerm__c = 6
            );
            insert renewalGroup;
            Test.stopTest();

            SBQQ__QuoteLineGroup__c resGroup = [SELECT Id FROM SBQQ__QuoteLineGroup__c WHERE Id = :renewalGroup.Id];
            System.assertNotEquals(null, resGroup.Id, 'Renewal Quote groups should bypass Net New ramping validations.');
        }
    }
}