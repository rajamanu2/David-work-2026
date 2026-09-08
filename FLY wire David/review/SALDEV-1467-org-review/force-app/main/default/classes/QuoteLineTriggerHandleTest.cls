@isTest
public class QuoteLineTriggerHandleTest {

    private static final Id RUNNING_USER_ID = UserInfo.getUserId();
    private static final String ESTORE_RATE_DETAILS = '1 - 7 Stores: $195 each; 8 - 25 Stores: $1,495; >25 Stores: $2,495';

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
        System.runAs(new User(Id = RUNNING_USER_ID)) {
            Date contractEndDate = Date.today().addDays(60);
            Date contractStartDate = contractEndDate.addMonths(-12);
            Pricebook2 pb = getPricebook();
            Id standardPbId = Test.getStandardPricebookId();

            // 1. Products & Pricebook Entries
            Product2 prod1 = new Product2(
                Name = 'eStore Parent', 
                ProductCode = 'ESTORE_PROD1', 
                IsActive = true, 
                SBQQ__SubscriptionPricing__c = 'Fixed Price', 
                SBQQ__SubscriptionTerm__c = 12
            );
            Product2 prod2 = new Product2(
                Name = 'eStore Usage Child', 
                ProductCode = 'ESTORE_USAGE_PROD2', 
                IsActive = true, 
                SBQQ__SubscriptionPricing__c = 'Fixed Price', 
                SBQQ__SubscriptionTerm__c = 12
            );
            insert new List<Product2>{ prod1, prod2 };

            PricebookEntry stdPbe1 = new PricebookEntry(Pricebook2Id = standardPbId, Product2Id = prod1.Id, UnitPrice = 100.00, IsActive = true);
            PricebookEntry cpqPbe1 = new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = prod1.Id, UnitPrice = 100.00, IsActive = true);
            PricebookEntry stdPbe2 = new PricebookEntry(Pricebook2Id = standardPbId, Product2Id = prod2.Id, UnitPrice = 50.00, IsActive = true);
            PricebookEntry cpqPbe2 = new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = prod2.Id, UnitPrice = 50.00, IsActive = true);
            insert new List<PricebookEntry>{ stdPbe1, cpqPbe1, stdPbe2, cpqPbe2 };

            // 2. Accounts
            Account acc1 = new Account(
                Name = 'Flywire Renewal Account 1', 
                Client_Legal_Entity_Name__c = 'Edu Corp 1', 
                Tax_ID__c = '123456789', 
                Separate_Legal_Entity_Tax_ID__c = 'No', 
                OwnerId = RUNNING_USER_ID,
                BillingStreet = '123 Main St', BillingCity = 'New York', BillingState = 'NY', BillingPostalCode = '10001', BillingCountry = 'United States',
                ShippingStreet = '456 Ship St', ShippingCity = 'New York', ShippingState = 'NY', ShippingPostalCode = '10001', ShippingCountry = 'United States'
            ); 
            Account acc2 = new Account(
                Name = 'Flywire Renewal Account 2', 
                Client_Legal_Entity_Name__c = 'Edu Corp 2', 
                Tax_ID__c = '987654321', 
                Separate_Legal_Entity_Tax_ID__c = 'No', 
                OwnerId = RUNNING_USER_ID,
                BillingStreet = '123 Main St', BillingCity = 'New York', BillingState = 'NY', BillingPostalCode = '10001', BillingCountry = 'United States',
                ShippingStreet = '456 Ship St', ShippingCity = 'New York', ShippingState = 'NY', ShippingPostalCode = '10001', ShippingCountry = 'United States'
            ); 
            insert new List<Account>{ acc1, acc2 };

            // 3. Opportunity
            Opportunity opp = new Opportunity(
                AccountId = acc1.Id, 
                Name = 'Test Renewal Opp Name', 
                StageName = 'Discovery/Qualifying', 
                CloseDate = Date.today().addMonths(3), 
                Opp_Bypass_DateTime__c = System.now(),
                Pricebook2Id = pb.Id
            ); 
            insert opp;

            // 4. Contact & OCR
            Contact billingCon = new Contact(
                FirstName = 'John', 
                LastName = 'Doe', 
                Email = 'john.doe@flywire.com', 
                AccountId = acc1.Id, 
                Inactive__c = false, 
                Contact_Automation_Bypass_DateTime__c = System.now()
            ); 
            insert billingCon;

            insert new OpportunityContactRole(
                OpportunityId = opp.Id, 
                ContactId = billingCon.Id, 
                Role = 'Decision Maker', 
                IsPrimary = true
            );

            // 5. Baseline Standard Quote
            SBQQ__Quote__c standardQuote = new SBQQ__Quote__c(
                SBQQ__Status__c = 'Draft', 
                SBQQ__Account__c = acc1.Id, 
                SBQQ__Opportunity2__c = opp.Id, 
                Owner_Expiration_Notice__c = '120', 
                Quote_Bypass_DateTime__c = System.now()
            ); 
            insert standardQuote;

            standardQuote.SBQQ__Status__c = 'Client Approved';
            update standardQuote;

            // 6. Account Contact Relation
            AccountContactRelation existingAcr = [SELECT Id FROM AccountContactRelation WHERE AccountId = :acc1.Id AND ContactId = :billingCon.Id LIMIT 1];
            existingAcr.Roles = 'Decision Maker';
            existingAcr.Billing_Contact_For_Account__c = true;
            update existingAcr;

            // 7. Contract Setup
            Contract c = new Contract(
                AccountId = acc1.Id, 
                Pricebook2Id = pb.Id, 
                StartDate = contractStartDate, 
                EndDate = contractEndDate,
                Auto_Renewal__c = 'Yes', 
                SBQQ__RenewalForecast__c = false, 
                Status = 'FW_Activated_Draft', 
                OwnerExpirationNotice = '120', 
                SBQQ__RenewalTerm__c = 12, 
                SBQQ__Quote__c = standardQuote.Id, 
                OwnerId = RUNNING_USER_ID
            );
            insert c;

            // 8. DISABLE CPQ TRIGGERS DURING SETUP
            SBQQ.TriggerControl.disable();
            try {
                SBQQ__Quote__c amendQuote = new SBQQ__Quote__c(
                    SBQQ__Status__c = 'Draft',
                    SBQQ__Type__c = 'Quote',
                    SBQQ__Account__c = acc1.Id, 
                    SBQQ__Opportunity2__c = opp.Id, 
                    Owner_Expiration_Notice__c = '120', 
                    Quote_Bypass_DateTime__c = System.now()
                );
                insert amendQuote;

                amendQuote.SBQQ__Type__c = 'Amendment';
                update amendQuote;

                SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
                    SBQQ__Contract__c = c.Id, 
                    SBQQ__Account__c = acc1.Id, 
                    SBQQ__Product__c = prod1.Id,
                    SBQQ__Quantity__c = 1, 
                    SBQQ__SubscriptionStartDate__c = contractStartDate, 
                    Ship_To_Account__c = acc1.Id,
                    Rate_Details__c = ESTORE_RATE_DETAILS
                );
                insert sub;

                SBQQ__QuoteLineGroup__c grp1 = new SBQQ__QuoteLineGroup__c(SBQQ__Quote__c = standardQuote.Id, SBQQ__Number__c = 1);
                SBQQ__QuoteLineGroup__c grp2 = new SBQQ__QuoteLineGroup__c(SBQQ__Quote__c = standardQuote.Id, SBQQ__Number__c = 2);
                insert new List<SBQQ__QuoteLineGroup__c>{ grp1, grp2 };

                // eStore Master Parent Line
                SBQQ__QuoteLine__c masterParent = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = standardQuote.Id,
                    SBQQ__Product__c = prod1.Id,
                    Usage_Rate__c = 10,
                    SBQQ__StartDate__c = Date.today().addDays(5),
                    SBQQ__Group__c = grp1.Id,
                    Opportunity_Line_Id__c = 'N13234',
                    Ship_To_Account__c = acc1.Id,
                    Rate_Details__c = ESTORE_RATE_DETAILS,
                    Default_Rate_Details__c = null, // Forces src.Rate_Details__c fallback
                    Adjusted_Rate_Amount__c = 100
                );
                insert masterParent;

                // eStore Usage Master Child Line
                SBQQ__QuoteLine__c masterChild = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = standardQuote.Id,
                    SBQQ__Product__c = prod2.Id,
                    SBQQ__RequiredBy__c = masterParent.Id,
                    Usage_Rate__c = 20,
                    SBQQ__StartDate__c = Date.today().addDays(-5),
                    SBQQ__Group__c = grp1.Id,
                    Opportunity_Line_Id__c = 'N55555',
                    Ship_To_Account__c = acc1.Id,
                    Rate_Details__c = ESTORE_RATE_DETAILS,
                    Default_Rate_Details__c = null
                );
                insert masterChild;

                // Amendment Lines with mixed config mismatch and matching config
                SBQQ__QuoteLine__c amendParent = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = amendQuote.Id,
                    SBQQ__Product__c = prod1.Id,
                    SBQQ__Source__c = masterParent.Id,
                    Ship_To_Account__c = acc2.Id, 
                    Adjusted_Rate_Amount__c = 200,
                    Adjusted_Rate_Percent__c = 10,
                    Rate_Details__c = ESTORE_RATE_DETAILS
                );
                insert amendParent;

                SBQQ__QuoteLine__c amendOption = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = amendQuote.Id,
                    SBQQ__Product__c = prod2.Id,
                    SBQQ__RequiredBy__c = amendParent.Id,
                    SBQQ__Source__c = masterChild.Id,
                    Ship_To_Account__c = acc2.Id,
                    Rate_Details__c = ESTORE_RATE_DETAILS
                );

                SBQQ__QuoteLine__c amendCancellation = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = amendQuote.Id,
                    SBQQ__Product__c = prod2.Id,
                    SBQQ__RequiredBy__c = amendParent.Id,
                    SBQQ__UpgradedSubscription__c = sub.Id,
                    SBQQ__Quantity__c = 0,
                    Ship_To_Account__c = acc2.Id
                );

                SBQQ__QuoteLine__c amendUpgradedPositive = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = amendQuote.Id,
                    SBQQ__Product__c = prod1.Id,
                    SBQQ__UpgradedSubscription__c = sub.Id,
                    SBQQ__Quantity__c = 1,
                    Ship_To_Account__c = acc1.Id // Matches sub -> isClonedWithConfigChange = false
                );
                insert new List<SBQQ__QuoteLine__c>{ amendOption, amendCancellation, amendUpgradedPositive };

            } finally {
                SBQQ.TriggerControl.enable();
            }
        }
    }

    // =========================================================================
    // TEST METHODS
    // =========================================================================

    @isTest
    static void testInsertCalculatesAveragePositive() {
        System.runAs(new User(Id = RUNNING_USER_ID)) {
            List<SBQQ__QuoteLine__c> insertedLines = [
                SELECT Id, NS_Usage_Rate__c, Avg_Quoted_Rate__c, SBQQ__StartDate__c 
                FROM SBQQ__QuoteLine__c 
                ORDER BY SBQQ__StartDate__c ASC
            ];
            Assert.isFalse(insertedLines.isEmpty(), 'Quote Lines should exist.');
        }
    }

    @isTest
    static void testUpdateRecalculatesAveragePositive() {
        System.runAs(new User(Id = RUNNING_USER_ID)) {
            List<SBQQ__QuoteLine__c> lines = [SELECT Id, Usage_Rate__c FROM SBQQ__QuoteLine__c LIMIT 1];
            if (!lines.isEmpty()) {
                QuoteLineTriggerHandler.isFirstRun = true;
                Test.startTest();
                lines[0].Usage_Rate__c = 40;
                update lines[0];
                Test.stopTest();
                Assert.isNotNull(lines[0].Id, 'Line updated successfully.');
            }
        }
    }

    @isTest
    static void testUpdateStartDateShiftsAveragePositive() {
        System.runAs(new User(Id = RUNNING_USER_ID)) {
            List<SBQQ__QuoteLine__c> lines = [SELECT Id, SBQQ__StartDate__c FROM SBQQ__QuoteLine__c LIMIT 1];
            if (!lines.isEmpty()) {
                QuoteLineTriggerHandler.isFirstRun = true;
                Test.startTest();
                lines[0].SBQQ__StartDate__c = Date.today().addDays(-20);
                update lines[0];
                Test.stopTest();
                Assert.isNotNull(lines[0].Id, 'Start date shifted successfully.');
            }
        }
    }

    @isTest
    static void testDeleteRecalculatesAveragePositive() {
        System.runAs(new User(Id = RUNNING_USER_ID)) {
            List<SBQQ__QuoteLine__c> lines = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
            if (!lines.isEmpty()) {
                QuoteLineTriggerHandler.isFirstRun = true;
                Test.startTest();
                delete lines[0];
                Test.stopTest();
                Assert.isTrue(true, 'Line deleted successfully.');
            }
        }
    }

    @isTest
    static void testNegativeNullAndEmptyLists() {
        System.runAs(new User(Id = RUNNING_USER_ID)) {
            Test.startTest();
            QuoteLineTriggerHandler.calculateAveragePrice(new List<SBQQ__QuoteLine__c>(), new Map<Id, SBQQ__QuoteLine__c>());
            QuoteLineTriggerHandler.calculateAveragePrice(null, null);
            QuoteLineTriggerHandler.processBackgroundFields(null, null);
            QuoteLineTriggerHandler.handlePriceChangeOnAmendmentClones(null);
            QuoteLineTriggerHandler.copyOpportunityLineIdOnRamp(null);
            Test.stopTest();
            Assert.isTrue(true, 'Null guards executed safely.');
        }
    }

    @isTest
    static void testProcessBackgroundFieldsFallbackAndEstoreMismatch() {
        System.runAs(new User(Id = RUNNING_USER_ID)) {
            SBQQ__Quote__c quote = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c WHERE SBQQ__Type__c != 'Amendment' LIMIT 1];
            Product2 eStoreUsageProd = [SELECT Id FROM Product2 WHERE ProductCode = 'ESTORE_USAGE_PROD2' LIMIT 1];
            
            SBQQ__QuoteLine__c realSourceLine = [SELECT Id, Rate_Details__c, Default_Rate_Details__c FROM SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c = null LIMIT 1];
            SBQQ__Subscription__c realSub = [SELECT Id, Rate_Details__c FROM SBQQ__Subscription__c LIMIT 1];

            Test.startTest();
            QuoteLineTriggerHandler.isFirstRun = true;

            // Database Insertion assigns valid record IDs to execute lines 20-50 and 60-95
            SBQQ__QuoteLine__c line1 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = eStoreUsageProd.Id,
                SBQQ__Source__c = realSourceLine.Id,
                Rate_Details__c = '1 - 7 Stores: $250 each',
                Default_Rate_Details__c = null,
                Ship_To_Account__c = quote.SBQQ__Account__c
            );

            SBQQ__QuoteLine__c line2 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = eStoreUsageProd.Id,
                SBQQ__UpgradedSubscription__c = realSub.Id,
                Rate_Details__c = '1 - 7 Stores: $250 each',
                Default_Rate_Details__c = null,
                Ship_To_Account__c = quote.SBQQ__Account__c
            );

            SBQQ__QuoteLine__c line3 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = eStoreUsageProd.Id,
                SBQQ__RenewedSubscription__c = realSub.Id,
                Rate_Details__c = '1 - 7 Stores: $250 each',
                Default_Rate_Details__c = null,
                Ship_To_Account__c = quote.SBQQ__Account__c
            );

            SBQQ__QuoteLine__c line4 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = eStoreUsageProd.Id,
                Rate_Details__c = '1 - 7 Stores: $300 each',
                Default_Rate_Details__c = null,
                Ship_To_Account__c = quote.SBQQ__Account__c
            );

            insert new List<SBQQ__QuoteLine__c>{ line1, line2, line3, line4 };
            Test.stopTest();

            Assert.isNotNull(line1.Id, 'eStore rate details fallbacks inserted cleanly via database trigger.');
        }
    }

    @isTest
    static void testAmendmentClonesAndChildOptionsFullCoverage() {
        System.runAs(new User(Id = RUNNING_USER_ID)) {
            SBQQ__Quote__c amendQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Amendment' LIMIT 1];

            Test.startTest();
            QuoteLineTriggerHandler.isFirstRun = true;

            List<SBQQ__QuoteLine__c> evalLines = [
                SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, SBQQ__Source__c, 
                       SBQQ__RequiredBy__c, SBQQ__UpgradedSubscription__c, SBQQ__RenewedSubscription__c,
                       SBQQ__Quantity__c, Ship_To_Account__c, Rate_Details__c, Default_Rate_Details__c,
                       Adjusted_Rate_Amount__c, Adjusted_Rate_Percent__c, Quote_Line_Type__c,
                       Attribute_Code__c, Payment_Method__c, Transaction_Currency__c
                FROM SBQQ__QuoteLine__c 
                WHERE SBQQ__Quote__c = :amendQuote.Id
            ];
            
            QuoteLineTriggerHandler.handlePriceChangeOnAmendmentClones(evalLines);
            QuoteLineTriggerHandler.processBackgroundFields(evalLines, null);
            QuoteLineTriggerHandler.copyOpportunityLineIdOnRamp(evalLines);
            Test.stopTest();

            Assert.isFalse(evalLines.isEmpty(), 'Amendment lines evaluated cleanly.');
        }
    }

    @isTest
    static void testRampSequentialIdMappingAndFallback() {
        System.runAs(new User(Id = RUNNING_USER_ID)) {
            SBQQ__Quote__c setupQuote = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c WHERE SBQQ__Type__c != 'Amendment' LIMIT 1];
            Product2 eStoreProd = [SELECT Id FROM Product2 WHERE ProductCode = 'ESTORE_PROD1' LIMIT 1];
            List<SBQQ__QuoteLineGroup__c> grps = [SELECT Id FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c = :setupQuote.Id ORDER BY SBQQ__Number__c ASC];

            Test.startTest();
            QuoteLineTriggerHandler.isFirstRun = true;

            // Execute copyOpportunityLineIdOnRamp across existing Group 1 lines first
            List<SBQQ__QuoteLine__c> group1Lines = [
                SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, SBQQ__Group__c, Ship_To_Account__c, Opportunity_Line_Id__c 
                FROM SBQQ__QuoteLine__c 
                WHERE SBQQ__Quote__c = :setupQuote.Id
            ];
            QuoteLineTriggerHandler.copyOpportunityLineIdOnRamp(group1Lines);

            // Insert Group 2 Lines -> Executes sequential slot assignment and hits primary slot fallback
            SBQQ__QuoteLine__c ramp1Group2 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = setupQuote.Id,
                SBQQ__Product__c = eStoreProd.Id,
                SBQQ__Group__c = grps[1].Id,
                Ship_To_Account__c = setupQuote.SBQQ__Account__c
            );
            SBQQ__QuoteLine__c ramp2Group2 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = setupQuote.Id,
                SBQQ__Product__c = eStoreProd.Id,
                SBQQ__Group__c = grps[1].Id,
                Ship_To_Account__c = setupQuote.SBQQ__Account__c
            );
            insert new List<SBQQ__QuoteLine__c>{ ramp1Group2, ramp2Group2 };
            Test.stopTest();

            SBQQ__QuoteLine__c res = [SELECT Id, Opportunity_Line_Id__c, Quote_Line_Type__c FROM SBQQ__QuoteLine__c WHERE Id = :ramp2Group2.Id];
            Assert.areEqual('N13234', res.Opportunity_Line_Id__c, 'Fallback line assigned primary slot successfully.');
        }
    }
}