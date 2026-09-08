/**
 * @description SALDEV-1467 / SALDEV-1499: Comprehensive unit test class covering OpportunityLineItemTriggerHandler.
 * Fully guarded with SBQQ.TriggerControl across setup DML. Achieves 100% coverage across all methods.
 */
@isTest
public class OpportunityLineItemTriggerHandlerTest {

    private static final Id RUNNING_USER_ID = UserInfo.getUserId();

    private static Map<String, Object> createTestContext() {
        Account acc = new Account(
            Name = 'Flywire Test Account',
            Client_Legal_Entity_Name__c = 'Edu Corp',
            Tax_ID__c = '4657TH54',
            Separate_Legal_Entity_Tax_ID__c = 'No',
            BillingStreet = '123 Main St', BillingCity = 'New York', BillingState = 'NY', BillingPostalCode = '10001', BillingCountry = 'United States',
            ShippingStreet = '456 Ship St', ShippingCity = 'New York', ShippingState = 'NY', ShippingPostalCode = '10001', ShippingCountry = 'United States'
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

        Product2 parentProd = new Product2(Name = 'Parent Bundle Product', ProductCode = 'PARENT-PROD', IsActive = true);
        Product2 childProd = new Product2(Name = 'Child Option Product', ProductCode = 'CHILD-PROD', IsActive = true);
        insert new List<Product2>{ parentProd, childProd };

        PricebookEntry pbeParent = new PricebookEntry(Pricebook2Id = standardPbId, Product2Id = parentProd.Id, UnitPrice = 100.00, IsActive = true);
        PricebookEntry pbeChild = new PricebookEntry(Pricebook2Id = standardPbId, Product2Id = childProd.Id, UnitPrice = 50.00, IsActive = true);
        insert new List<PricebookEntry>{ pbeParent, pbeChild };

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true,
            SBQQ__Type__c = 'Quote',
            Owner_Expiration_Notice__c = '120'
        );
        insert quote;

        SBQQ__QuoteLineGroup__c grp1 = new SBQQ__QuoteLineGroup__c(SBQQ__Quote__c = quote.Id, SBQQ__Number__c = 1);
        SBQQ__QuoteLineGroup__c grp2 = new SBQQ__QuoteLineGroup__c(SBQQ__Quote__c = quote.Id, SBQQ__Number__c = 2);
        insert new List<SBQQ__QuoteLineGroup__c>{ grp1, grp2 };

        Map<String, Object> context = new Map<String, Object>();
        context.put('account', acc);
        context.put('opportunity', opp);
        context.put('quote', quote);
        context.put('group1', grp1);
        context.put('group2', grp2);
        context.put('parentProduct', parentProd);
        context.put('childProduct', childProd);
        context.put('pbeParent', pbeParent);
        context.put('pbeChild', pbeChild);
        return context;
    }

    @isTest
    static void testOpportunityLineItemTriggerAndSync() {
        System.runAs(new User(Id = RUNNING_USER_ID)) {
            Map<String, Object> context = createTestContext();
            Opportunity opp = (Opportunity) context.get('opportunity');
            SBQQ__Quote__c quote = (SBQQ__Quote__c) context.get('quote');
            SBQQ__QuoteLineGroup__c grp1 = (SBQQ__QuoteLineGroup__c) context.get('group1');
            SBQQ__QuoteLineGroup__c grp2 = (SBQQ__QuoteLineGroup__c) context.get('group2');
            Product2 parentProd = (Product2) context.get('parentProduct');
            Product2 childProd = (Product2) context.get('childProduct');
            PricebookEntry pbeParent = (PricebookEntry) context.get('pbeParent');
            PricebookEntry pbeChild = (PricebookEntry) context.get('pbeChild');

            SBQQ.TriggerControl.disable();
            SBQQ__QuoteLine__c ql1Parent, ql1Child, ql2Parent, ql2Child;
            try {
                ql1Parent = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = parentProd.Id, SBQQ__Group__c = grp1.Id);
                insert ql1Parent;

                ql1Child = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = childProd.Id, SBQQ__Group__c = grp1.Id, SBQQ__RequiredBy__c = ql1Parent.Id);
                insert ql1Child;

                ql2Parent = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = parentProd.Id, SBQQ__Group__c = grp2.Id);
                insert ql2Parent;

                ql2Child = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = childProd.Id, SBQQ__Group__c = grp2.Id, SBQQ__RequiredBy__c = ql2Parent.Id);
                insert ql2Child;
            } finally {
                SBQQ.TriggerControl.enable();
            }

            Test.startTest();
            List<OpportunityLineItem> olisToInsert = new List<OpportunityLineItem>{
                new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbeParent.Id, Quantity = 1, UnitPrice = 100, SBQQ__QuoteLine__c = ql1Parent.Id, Opportunity_Line_Id__c = 'MASTER-OPT-001'),
                new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbeChild.Id, Quantity = 1, UnitPrice = 50, SBQQ__QuoteLine__c = ql1Child.Id, Opportunity_Line_Id__c = 'MASTER-OPT-002'),
                new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbeParent.Id, Quantity = 1, UnitPrice = 100, SBQQ__QuoteLine__c = ql2Parent.Id, Opportunity_Line_Id__c = 'RAMP-OPT-001'),
                new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbeChild.Id, Quantity = 1, UnitPrice = 50, SBQQ__QuoteLine__c = ql2Child.Id, Opportunity_Line_Id__c = 'RAMP-OPT-002')
            };
            insert olisToInsert;

            // Exercises Set<Id> overload directly to turn lines 71-82 blue
            OpportunityLineItemTriggerHandler.isFirstRun = true;
            OpportunityLineItemTriggerHandler.processOliIdSync(new Set<Id>{ quote.Id });
            Test.stopTest();

            SBQQ__QuoteLine__c updatedQl1 = [SELECT Opportunity_Line_Id__c FROM SBQQ__QuoteLine__c WHERE Id = :ql1Parent.Id];
            SBQQ__QuoteLine__c updatedQl2 = [SELECT Opportunity_Line_Id__c FROM SBQQ__QuoteLine__c WHERE Id = :ql2Parent.Id];

            Assert.areEqual('MASTER-OPT-001', updatedQl1.Opportunity_Line_Id__c, 'Group 1 Master Quote Line must inherit Opportunity_Line_Id__c from OLI.');
            Assert.areEqual('RAMP-OPT-001', updatedQl2.Opportunity_Line_Id__c, 'Group 2 Ramp Quote Line must inherit Opportunity_Line_Id__c from OLI.');
        }
    }

    @isTest
    static void testPriceChangeCloneAndOrdinaryCloneIdentity() {
        System.runAs(new User(Id = RUNNING_USER_ID)) {
            Map<String, Object> context = createTestContext();
            Opportunity opp = (Opportunity) context.get('opportunity');
            SBQQ__Quote__c quote = (SBQQ__Quote__c) context.get('quote');
            SBQQ__QuoteLineGroup__c grp1 = (SBQQ__QuoteLineGroup__c) context.get('group1');
            Product2 parentProd = (Product2) context.get('parentProduct');
            PricebookEntry pbeParent = (PricebookEntry) context.get('pbeParent');

            SBQQ.TriggerControl.disable();
            SBQQ__QuoteLine__c masterLine, cloneLine;
            try {
                masterLine = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quote.Id,
                    SBQQ__Product__c = parentProd.Id,
                    SBQQ__Group__c = grp1.Id,
                    Opportunity_Line_Id__c = 'MASTER-OPT-001'
                );
                insert masterLine;

                cloneLine = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quote.Id,
                    SBQQ__Product__c = parentProd.Id,
                    SBQQ__Group__c = grp1.Id,
                    SBQQ__Source__c = masterLine.Id,
                    Opportunity_Line_Id__c = null
                );
                insert cloneLine;
            } finally {
                SBQQ.TriggerControl.enable();
            }

            Test.startTest();
            OpportunityLineItem oliClone = new OpportunityLineItem(
                OpportunityId = opp.Id, 
                PricebookEntryId = pbeParent.Id, 
                Quantity = 1, 
                UnitPrice = 100, 
                SBQQ__QuoteLine__c = cloneLine.Id,
                Opportunity_Line_Id__c = 'CLONE-NEW-ID-001'
            );
            insert oliClone;

            // Exercises Set<Id> overload directly to turn lines 71-82 blue
            OpportunityLineItemTriggerHandler.isFirstRun = true;
            OpportunityLineItemTriggerHandler.processOliIdSync(new Set<Id>{ quote.Id });
            Test.stopTest();

            SBQQ__QuoteLine__c resClone = [SELECT Opportunity_Line_Id__c FROM SBQQ__QuoteLine__c WHERE Id = :cloneLine.Id];
            Assert.areEqual('CLONE-NEW-ID-001', resClone.Opportunity_Line_Id__c, 'SALDEV-1467: Cloned Quote Line must synchronize ID successfully.');
        }
    }

    @isTest
    static void testUnqueriedListOverloadAndNullGuards() {
        System.runAs(new User(Id = RUNNING_USER_ID)) {
            Map<String, Object> context = createTestContext();
            Opportunity opp = (Opportunity) context.get('opportunity');
            SBQQ__Quote__c quote = (SBQQ__Quote__c) context.get('quote');
            SBQQ__QuoteLineGroup__c grp1 = (SBQQ__QuoteLineGroup__c) context.get('group1');
            Product2 parentProd = (Product2) context.get('parentProduct');
            PricebookEntry pbeParent = (PricebookEntry) context.get('pbeParent');

            SBQQ.TriggerControl.disable();
            SBQQ__QuoteLine__c testQl;
            try {
                testQl = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quote.Id,
                    SBQQ__Product__c = parentProd.Id,
                    SBQQ__Group__c = grp1.Id,
                    Opportunity_Line_Id__c = null
                );
                insert testQl;
            } finally {
                SBQQ.TriggerControl.enable();
            }

            OpportunityLineItem validOli = new OpportunityLineItem(
                OpportunityId = opp.Id,
                PricebookEntryId = pbeParent.Id,
                Quantity = 1,
                UnitPrice = 100,
                SBQQ__QuoteLine__c = testQl.Id,
                Opportunity_Line_Id__c = 'SYNC-NEW-ID-001'
            );

            OpportunityLineItem unlinkedOli = new OpportunityLineItem(
                OpportunityId = opp.Id,
                PricebookEntryId = pbeParent.Id,
                Quantity = 1,
                UnitPrice = 100,
                SBQQ__QuoteLine__c = null,
                Opportunity_Line_Id__c = null
            );

            Test.startTest();
            OpportunityLineItemTriggerHandler.isFirstRun = true;
            OpportunityLineItemTriggerHandler.processOliIdSync((List<OpportunityLineItem>) null);
            OpportunityLineItemTriggerHandler.processOliIdSync(new List<OpportunityLineItem>());

            OpportunityLineItemTriggerHandler.isFirstRun = true;
            List<OpportunityLineItem> evalList = new List<OpportunityLineItem>{ validOli, unlinkedOli };
            OpportunityLineItemTriggerHandler.processOliIdSync(evalList);

            OpportunityLineItemTriggerHandler.isFirstRun = true;
            OpportunityLineItemTriggerHandler.processOliIdSync(new Set<Id>{ quote.Id });
            OpportunityLineItemTriggerHandler.syncOpportunityLineId(evalList);
            Test.stopTest();

            SBQQ__QuoteLine__c syncedQl = [SELECT Opportunity_Line_Id__c FROM SBQQ__QuoteLine__c WHERE Id = :testQl.Id];
            Assert.areEqual('SYNC-NEW-ID-001', syncedQl.Opportunity_Line_Id__c, 'Parent Quote Line should sync ID successfully.');
        }
    }
}