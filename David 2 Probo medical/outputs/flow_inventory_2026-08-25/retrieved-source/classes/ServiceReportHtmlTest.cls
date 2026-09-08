@isTest
private class ServiceReportHtmlTest {

    // The only guessed picklist value in this file. Set it to the real
    // Line_Intent__c value your engineers pick for a scrapped part -- confirm
    // with:  WorkOrderLineItem.Line_Intent__c.getDescribe().getPicklistValues()
    private static final String SCRAP_INTENT = 'Scrap';

    private static WorkType makeWorkType(String name) {
        WorkType wt = new WorkType(Name = name, EstimatedDuration = 1, DurationType = 'Hours');
        insert wt;
        return wt;
    }

    // Product + active standard PricebookEntry, returns the PBE id.
    private static Id makePricebookEntry() {
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id   = prod.Id,
            UnitPrice    = 100,
            IsActive     = true
        );
        insert pbe;
        return pbe.Id;
    }

    // Line item with explicit Line_Type__c and Line_Intent__c. buildFsr no
    // longer filters anything itself -- it renders FieldServiceReportController
    // .displayParts, which drops rate lines (Line_Type__c) and bookkeeping lines
    // (Line_Intent__c). Type_Intent__c is a formula and is not set directly.
    private static WorkOrderLineItem woli(Id woId, Id pbeId, String type, String intent,
                                          Decimal qty, Decimal price) {
        return new WorkOrderLineItem(
            WorkOrderId      = woId,
            PricebookEntryId = pbeId,
            Line_Type__c     = type,
            Line_Intent__c   = intent,
            Quantity         = qty,
            UnitPrice        = price
        );
    }

    private static Integer links(Id woId) {
        return [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :woId];
    }

    private static String latestTitle(Id docId) {
        return [SELECT Title FROM ContentVersion
                WHERE ContentDocumentId = :docId AND IsLatest = true LIMIT 1].Title;
    }

    @isTest static void generatesFsrForBreakFix() {
        Id pricebookId = Test.getStandardPricebookId();
        WorkOrder wo = new WorkOrder(
            Subject      = 'BF',
            WorkTypeId   = makeWorkType('Break Fix').Id,
            Pricebook2Id = pricebookId);
        insert wo;

        Id pbeId = makePricebookEntry();

        // Labor/Travel/Shipping are excluded from the FSR parts grid by their
        // Line_Type__c; the 'Part Consumed' line is the one that renders.
        insert new List<WorkOrderLineItem>{
            woli(wo.Id, pbeId, 'Labor',         'Labor',         2, 150),
            woli(wo.Id, pbeId, 'Travel',        'Travel',        1, 100),
            woli(wo.Id, pbeId, 'Shipping',      'Shipping',      1,  25),
            woli(wo.Id, pbeId, 'Part Consumed', 'Outright Sale', 1,  40)
        };

        Test.startTest();
        Id docId = ServiceReportHtml.generateReport(wo.Id, false);
        Test.stopTest();

        System.assertNotEquals(null, docId);
        System.assertEquals(1, links(wo.Id), 'FSR should be filed');
        System.assert(latestTitle(docId).startsWith('FSR-'), latestTitle(docId));
    }

    // =====================================================================
    //  The regression test for the original defect: a return line rendered on
    //  the FSR at full price while contributing $0 to Total Parts.
    //  generateReport() only hands back a ContentDocumentId, so this asserts
    //  against build() -- the HTML itself -- where the row either is or isn't.
    //
    //  Reminder on the two fields, because the display value merges them:
    //      Type_Intent__c (formula) = Line_Type__c + ' | ' + Line_Intent__c
    //  So the "Part Return | Unused" rows that started this are
    //  Line_Type__c = 'Part Return', Line_Intent__c = 'Unused'. Only the
    //  intent half drives isExcludedIntent().
    //
    //  This test uses ONLY Line_Intent__c values already proven valid by
    //  FieldServiceReportControllerTest.testTotalsAndExclusions -- 'DOA' and
    //  'Repair Cancelled'. The full DOA/Unused/Cancel vocabulary is covered
    //  without DML in testIsExcludedIntent(), so no picklist value has to be
    //  guessed here. Scrap is NOT excluded -- see keepsScrapOnFsr().
    // =====================================================================
    @isTest static void excludedLinesDoNotRenderOnFsr() {
        WorkOrder wo = new WorkOrder(
            Subject      = 'BF',
            WorkTypeId   = makeWorkType('Break Fix').Id,
            Pricebook2Id = Test.getStandardPricebookId());
        insert wo;

        Id pbeId = makePricebookEntry();

        insert new List<WorkOrderLineItem>{
            woli(wo.Id, pbeId, 'Part Consumed', 'Outright Sale',    1,  40),   // renders
            woli(wo.Id, pbeId, 'Part Return',   'DOA',              1, 999),   // must not render
            woli(wo.Id, pbeId, 'Probe Repair',  'Repair Cancelled', 1, 888)    // must not render
        };

        Test.startTest();
        FieldServiceReportController c = new FieldServiceReportController(
            new ApexPages.StandardController(wo));
        String html = ServiceReportHtml.build(wo.Id);
        Test.stopTest();

        // The filtering guarantee, asserted where it is deterministic. Currency
        // strings are not asserted here -- Decimal.format() is locale-dependent
        // and TotalPrice is platform-calculated, neither of which this test is
        // about.
        System.assertEquals(1, c.displayParts.size(), 'only the billable line reaches the grid');
        System.assertEquals('Outright Sale', c.displayParts[0].Line_Intent__c, 'and it is the right one');
        System.assert(c.totalParts == 40, 'Total Parts excludes the DOA and cancelled lines');

        // The rendered HTML: right layout, and the excluded rows are absent.
        // A negative assertion can't be broken by number formatting.
        System.assert(html.contains('FIELD SERVICE REPORT'), 'FSR layout selected');
        System.assert(!html.contains('DOA'), 'the DOA row must not render');
        System.assert(!html.contains('Cancelled'), 'the cancelled repair row must not render');
    }

    @isTest static void keepsReturnTypeWithBillableIntentOnFsr() {
        WorkOrder wo = new WorkOrder(
            Subject      = 'BF',
            WorkTypeId   = makeWorkType('Break Fix').Id,
            Pricebook2Id = Test.getStandardPricebookId());
        insert wo;

        Id pbeId = makePricebookEntry();

        // Line_Type__c = 'Part Return' but the intent is billable, so nothing
        // excludes it. The skip reads ONLY Line_Intent__c -- a 'Part Return'
        // type on its own is not enough to drop a line. Intentional: these
        // print and they count.
        insert new List<WorkOrderLineItem>{
            woli(wo.Id, pbeId, 'Part Return', 'Outright Sale', 1, 321)
        };

        Test.startTest();
        FieldServiceReportController c = new FieldServiceReportController(
            new ApexPages.StandardController(wo));
        String html = ServiceReportHtml.build(wo.Id);
        Test.stopTest();

        System.assertEquals(1, c.displayParts.size(),
            'a Part Return line with a billable intent still prints');
        System.assert(c.totalParts == 321, 'and it still counts toward Total Parts');
        System.assert(html.contains('FIELD SERVICE REPORT'), 'FSR layout selected');
    }

    // Scrapped parts were consumed on the job, so they belong on the report and
    // in Total Parts. This test exists so that re-adding 'Scrap' to
    // isExcludedIntent() fails loudly instead of quietly shrinking an invoice.
    @isTest static void keepsScrapOnFsr() {
        WorkOrder wo = new WorkOrder(
            Subject      = 'BF',
            WorkTypeId   = makeWorkType('Break Fix').Id,
            Pricebook2Id = Test.getStandardPricebookId());
        insert wo;

        Id pbeId = makePricebookEntry();

        insert new List<WorkOrderLineItem>{
            woli(wo.Id, pbeId, 'Part Consumed', SCRAP_INTENT, 1, 543)
        };

        Test.startTest();
        FieldServiceReportController c = new FieldServiceReportController(
            new ApexPages.StandardController(wo));
        String html = ServiceReportHtml.build(wo.Id);
        Test.stopTest();

        System.assertEquals(1, c.displayParts.size(),
            'a scrapped part should print on the FSR');
        System.assert(c.totalParts == 543, 'and count toward Total Parts');
        System.assert(html.contains('FIELD SERVICE REPORT'), 'FSR layout selected');
    }

    @isTest static void generatesPpm() {
        WorkOrder wo = new WorkOrder(Subject = 'PM', WorkTypeId = makeWorkType('PPM').Id,
                                     Make_Model__c = 'GE LOGIQ E10');
        insert wo;

        Test.startTest();
        Id docId = ServiceReportHtml.generateReport(wo.Id, false);
        Test.stopTest();

        System.assertNotEquals(null, docId);
        System.assertEquals(1, links(wo.Id), 'PPM should be filed');
        System.assert(latestTitle(docId).startsWith('PMR-'), latestTitle(docId));
    }

    @isTest static void generatesTrophon() {
        WorkOrder wo = new WorkOrder(Subject = 'PM', WorkTypeId = makeWorkType('PPM').Id,
                                     Make_Model__c = 'Nanosonics Trophon EPR');
        insert wo;

        Test.startTest();
        Id docId = ServiceReportHtml.generateReport(wo.Id, false);
        Test.stopTest();

        System.assertNotEquals(null, docId);
        System.assertEquals(1, links(wo.Id), 'Trophon PM should be filed');
        // Trophon is still a PPM Work Type, so the file name token is PMR.
        System.assert(latestTitle(docId).startsWith('PMR-'), latestTitle(docId));
    }

    @isTest static void generatesPreliminary() {
        WorkOrder wo = new WorkOrder(Subject = 'BF', WorkTypeId = makeWorkType('Break Fix').Id);
        insert wo;

        Test.startTest();
        Id docId = ServiceReportHtml.generateReport(wo.Id, true);
        Test.stopTest();

        System.assertNotEquals(null, docId);
        System.assertEquals(1, links(wo.Id), 'Preliminary report should be filed');
        System.assert(latestTitle(docId).startsWith('Prelim FSR-'), latestTitle(docId));
    }
}