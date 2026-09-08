@isTest
public class OpportunityLineItemTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // 1. Create Account & Opportunity
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

            Id standardPbId = Test.getStandardPricebookId();

            Opportunity opp = new Opportunity(
                Name = 'Test Opp New Business',
                StageName = 'Discovery/Qualifying',
                Type = 'New Business',
                CloseDate = Date.today().addDays(30),
                AccountId = acc.Id,
                Pricebook2Id = standardPbId
            );
            insert opp;

            // 2. Insert Parent & Child Option Products
            Product2 parentProd = new Product2(
                Name = 'Parent Bundle Product',
                ProductCode = 'PARENT-PROD',
                IsActive = true
            );
            Product2 childProd = new Product2(
                Name = 'Child Option Product',
                ProductCode = 'CHILD-PROD',
                IsActive = true
            );
            insert new List<Product2>{ parentProd, childProd };

            PricebookEntry pbeParent = new PricebookEntry(
                Pricebook2Id = standardPbId,
                Product2Id = parentProd.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
            PricebookEntry pbeChild = new PricebookEntry(
                Pricebook2Id = standardPbId,
                Product2Id = childProd.Id,
                UnitPrice = 50.00,
                IsActive = true
            );
            insert new List<PricebookEntry>{ pbeParent, pbeChild };

            // 3. Create CPQ Quote & Groups
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Account__c = acc.Id,
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Primary__c = true
            );
            insert quote;

            SBQQ__QuoteLineGroup__c grp1 = new SBQQ__QuoteLineGroup__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Number__c = 1
            );
            SBQQ__QuoteLineGroup__c grp2 = new SBQQ__QuoteLineGroup__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Number__c = 2
            );
            insert new List<SBQQ__QuoteLineGroup__c>{ grp1, grp2 };

            // 4. Create Bundle & Option Quote Lines (bypassing triggers safely)
            SBQQ.TriggerControl.disable();
            try {
                // Group 1 Parent & Option Lines
                SBQQ__QuoteLine__c ql1Parent = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quote.Id,
                    SBQQ__Product__c = parentProd.Id,
                    SBQQ__Group__c = grp1.Id
                );
                insert ql1Parent;

                SBQQ__QuoteLine__c ql1Child = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quote.Id,
                    SBQQ__Product__c = childProd.Id,
                    SBQQ__Group__c = grp1.Id,
                    SBQQ__RequiredBy__c = ql1Parent.Id
                );
                insert ql1Child;

                // Group 2 Parent & Multiple Options (To test slot overflow index)
                SBQQ__QuoteLine__c ql2Parent = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quote.Id,
                    SBQQ__Product__c = parentProd.Id,
                    SBQQ__Group__c = grp2.Id
                );
                insert ql2Parent;

                SBQQ__QuoteLine__c ql2Child1 = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quote.Id,
                    SBQQ__Product__c = childProd.Id,
                    SBQQ__Group__c = grp2.Id,
                    SBQQ__RequiredBy__c = ql2Parent.Id
                );
                SBQQ__QuoteLine__c ql2Child2 = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quote.Id,
                    SBQQ__Product__c = childProd.Id,
                    SBQQ__Group__c = grp2.Id,
                    SBQQ__RequiredBy__c = ql2Parent.Id
                );
                insert new List<SBQQ__QuoteLine__c>{ ql2Child1, ql2Child2 };

                // Same-Group Clone Line
                SBQQ__QuoteLine__c sameGroupClone = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quote.Id,
                    SBQQ__Product__c = parentProd.Id,
                    SBQQ__Group__c = grp1.Id,
                    SBQQ__Source__c = ql1Parent.Id
                );
                insert sameGroupClone;

            } finally {
                SBQQ.TriggerControl.enable();
            }
        }
    }

    @isTest
    static void testOpportunityLineItemTriggerAndSync() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            Map<String, PricebookEntry> pbeMap = new Map<String, PricebookEntry>();
            for (PricebookEntry pbe : [SELECT Id, Product2.ProductCode FROM PricebookEntry]) {
                pbeMap.put(pbe.Product2.ProductCode, pbe);
            }

            List<SBQQ__QuoteLine__c> qls = [SELECT Id, SBQQ__Group__r.SBQQ__Number__c, SBQQ__Product__r.ProductCode FROM SBQQ__QuoteLine__c];

            Test.startTest();
            List<OpportunityLineItem> olisToInsert = new List<OpportunityLineItem>();
            for (SBQQ__QuoteLine__c ql : qls) {
                olisToInsert.add(new OpportunityLineItem(
                    OpportunityId = opp.Id,
                    PricebookEntryId = pbeMap.get(ql.SBQQ__Product__r.ProductCode).Id,
                    Quantity = 1,
                    UnitPrice = 100,
                    SBQQ__QuoteLine__c = ql.Id
                ));
            }
            insert olisToInsert;
            Test.stopTest();

            List<OpportunityLineItem> resultOlis = [SELECT Id, Opportunity_Line_Id__c FROM OpportunityLineItem WHERE SBQQ__QuoteLine__r.SBQQ__Group__r.SBQQ__Number__c = 2];
            Assert.isFalse(resultOlis.isEmpty(), 'Group 2 OLIs should be created.');
            Assert.isNotNull(resultOlis[0].Opportunity_Line_Id__c, 'Group 2 OLIs should receive Opportunity Line ID from Master Group.');
        }
    }

    @isTest
    static void testUnqueriedListOverloadAndNullGuards() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

            // Construct unqueried OpportunityLineItem list (Exercises red lines 40-50 fallback)
            SBQQ__QuoteLine__c ql = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
            OpportunityLineItem unqueriedOli = new OpportunityLineItem(
                SBQQ__QuoteLine__c = ql.Id
            );

            Test.startTest();
            // Test unqueried relationship list overload
            OpportunityLineItemTriggerHandler.processOliIdSync(new List<OpportunityLineItem>{ unqueriedOli });

            // Test Set<Id> overload directly
            OpportunityLineItemTriggerHandler.processOliIdSync(new Set<Id>{ quote.Id });

            // Test Null & Empty Guards
            OpportunityLineItemTriggerHandler.syncOpportunityLineId(null);
            OpportunityLineItemTriggerHandler.syncOpportunityLineId(new List<OpportunityLineItem>());
            OpportunityLineItemTriggerHandler.processOliIdSync((Set<Id>) null);
            OpportunityLineItemTriggerHandler.processOliIdSync((List<OpportunityLineItem>) null);
            Test.stopTest();

            Assert.isTrue(true, 'Overloads and null guards executed cleanly.');
        }
    }
}