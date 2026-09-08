@isTest
private class FieldServiceReportControllerTest {

    // Helper: build a WorkOrderLineItem for a given type / intent / qty / price.
    //   Line_Type__c   -> drives the Labor/Travel/Shipping classification and,
    //                     via isRateLine(), keeps those lines out of the grid.
    //   Line_Intent__c -> drives the DOA / Unused / Cancel skip, via
    //                     isExcludedIntent(). Excluded lines are dropped from
    //                     BOTH the totals and the printed parts grid.
    // Type_Intent__c is a formula in this org, so it is never set directly. It
    // is still queried because the report prints it in the "Status | Type"
    // column, but it no longer drives any filtering.
    private static WorkOrderLineItem makeLine(Id woId, Id pbeId, String type, String intent,
                                              Decimal qty, Decimal price) {
        return new WorkOrderLineItem(
            WorkOrderId      = woId,
            PricebookEntryId = pbeId,
            Line_Type__c     = type,
            Line_Intent__c   = intent,
            Description      = intent + ' line',
            Quantity         = qty,
            UnitPrice        = price
        );
    }

    // Create a Product + active standard PricebookEntry, return the PBE id.
    private static Id makePricebookEntry() {
        Product2 prod = new Product2(Name = 'Service Item', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id   = prod.Id,
            UnitPrice    = 1,
            IsActive     = true
        );
        insert pbe;
        return pbe.Id;
    }

    // In-memory line item built via JSON so these helper tests don't need DML
    // and don't care whether the fields are writeable.
    private static WorkOrderLineItem stubLine(String intent, String type) {
        Map<String, Object> m = new Map<String, Object>{
            'attributes' => new Map<String, Object>{ 'type' => 'WorkOrderLineItem' }
        };
        if (intent != null) m.put('Line_Intent__c', intent);
        if (type   != null) m.put('Line_Type__c',   type);
        return (WorkOrderLineItem) JSON.deserialize(JSON.serialize(m), WorkOrderLineItem.class);
    }

    // =====================================================================
    //  Filter helpers -- pins the exclusion vocabulary so a picklist change
    //  that quietly stops matching shows up here rather than on an invoice.
    // =====================================================================
    @isTest
    static void testIsExcludedIntent() {
        // Bookkeeping lines: dropped from totals AND from the grid.
        for (String intent : new List<String>{
                'DOA', 'Part DOA', 'doa replacement',
                'Part Unused', 'Part Return | Unused', 'UNUSED',
                'Cancel', 'Repair Cancelled', 'Order Canceled' }) {
            System.assertEquals(true, FieldServiceReportController.isExcludedIntent(stubLine(intent, 'Part')),
                'should be excluded: ' + intent);
        }

        // Everything else counts and prints. Note 'Part Return' with no
        // "Unused" in it is deliberately KEPT -- it renders on the report and
        // counts toward Total Parts.
        for (String intent : new List<String>{
                'Outright Sale', 'Part Consumed', 'Part Return', 'Exchange' }) {
            System.assertEquals(false, FieldServiceReportController.isExcludedIntent(stubLine(intent, 'Part')),
                'should be counted: ' + intent);
        }

        // Null-safety: blank intent and a null record both fall through as billable.
        System.assertEquals(false, FieldServiceReportController.isExcludedIntent(stubLine(null, 'Part')));
        System.assertEquals(false, FieldServiceReportController.isExcludedIntent(stubLine('', 'Part')));
        System.assertEquals(false, FieldServiceReportController.isExcludedIntent(null));
    }

    @isTest
    static void testIsRateLine() {
        for (String type : new List<String>{ 'Labor', 'Travel', 'Shipping', 'Labor - Onsite' }) {
            System.assertEquals(true, FieldServiceReportController.isRateLine(stubLine('Outright Sale', type)),
                'belongs in the totals block, not the grid: ' + type);
        }
        for (String type : new List<String>{ 'Part Consumed', 'Probe Repair', 'Part Return', null }) {
            System.assertEquals(false, FieldServiceReportController.isRateLine(stubLine('Outright Sale', type)),
                'belongs in the parts grid: ' + type);
        }
        System.assertEquals(false, FieldServiceReportController.isRateLine(null));
    }

    @isTest
    static void testTotalsAndExclusions() {

        Id pbeId = makePricebookEntry();

        // --- Account / Contact for the WO relationships (optional but realistic) ---
        Account acct = new Account(Name = 'Test Facility');
        insert acct;

        Contact con = new Contact(LastName = 'Ngo', AccountId = acct.Id);
        insert con;

        // --- Work Order (Pricebook2Id must match the line items' price book) ---
        WorkOrder wo = new WorkOrder(
            AccountId             = acct.Id,
            ContactId             = con.Id,
            Pricebook2Id          = Test.getStandardPricebookId(),
            Customer_PO_Number__c = 'TMXC2546130',
            Billing_Type__c       = 'Warranty',
            Make_Model__c         = 'Siemens/Acuson S2000',
            Software__c           = 'VE10B'
        );
        insert wo;

        // --- Line items ---
        //   Classification keys off Line_Type__c (1st arg): Labor/Travel/Shipping
        //   go to their own buckets and stay out of the grid.
        //   The skip keys off Line_Intent__c (2nd arg): DOA and Repair Cancelled
        //   are dropped from the totals AND from the grid. Lines 5 & 6 carry
        //   non-rate Line_Type__c values, so the ONLY thing keeping them off the
        //   report is the intent skip -- which is the regression this asserts.
        List<WorkOrderLineItem> lines = new List<WorkOrderLineItem>{
            makeLine(wo.Id, pbeId, 'Labor',         'Labor',            6, 171),  // 1026 / 6 hrs
            makeLine(wo.Id, pbeId, 'Travel',        'Travel',           4, 161),  //  644 / 4 hrs
            makeLine(wo.Id, pbeId, 'Shipping',      'Shipping',         1,  50),  //   50
            makeLine(wo.Id, pbeId, 'Part Consumed', 'Outright Sale',    2, 200),  //  400 -> totalParts, printed
            makeLine(wo.Id, pbeId, 'Part Return',   'DOA',              1, 999),  //   excluded (intent)
            makeLine(wo.Id, pbeId, 'Probe Repair',  'Repair Cancelled', 1, 888)   //   excluded (intent)
        };
        insert lines;

        // --- Service Appointment linked to the WO ---
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId  = wo.Id,
            SchedStartTime  = DateTime.now(),
            SchedEndTime    = DateTime.now().addHours(3),
            ActualStartTime = DateTime.now(),
            ActualEndTime   = DateTime.now().addHours(6)
        );
        insert sa;

        // --- Run the controller ---
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(wo);
        FieldServiceReportController ext = new FieldServiceReportController(sc);
        Test.stopTest();

        // --- Assertions (use == to avoid Integer/Decimal equals() pitfalls) ---
        System.assertEquals(6, ext.parts.size(), 'all 6 lines should be loaded -- parts is unfiltered');
        System.assertEquals(1, ext.appointments.size(), 'one appointment expected');

        // Classification is driven by Line_Type__c.
        System.assert(ext.laborTotal    == 1026, 'labor total');
        System.assert(ext.travelTotal   == 644,  'travel total');
        System.assert(ext.shippingTotal == 50,   'shipping total');
        System.assert(ext.totalParts    == 400,  'parts total (excluded lines dropped)');

        System.assert(ext.laborHours    == 6, 'labor hours');
        System.assert(ext.travelHours   == 4, 'travel hours');

        System.assert(ext.laborEffRate  == 171, 'effective labor rate');
        System.assert(ext.travelEffRate == 161, 'effective travel rate');

        // subtotal = 400 + 1026 + 644 + 50 = 2120
        System.assert(ext.subtotal == 2120, 'subtotal');

        // ---- The regression this file exists for ----
        // The grid now excludes BOTH the rate lines (Line_Type__c) and the
        // bookkeeping lines (Line_Intent__c), so only 'Outright Sale' prints.
        // Before the fix this was 3, because the DOA and Repair Cancelled lines
        // rendered at full price while contributing $0 to Total Parts.
        System.assertEquals(1, ext.displayParts.size(), 'only the billable part line prints');
        System.assertEquals('Outright Sale line', ext.displayParts[0].Description,
            'and it is the right one');
        for (WorkOrderLineItem li : ext.displayParts) {
            System.assert(!FieldServiceReportController.isExcludedIntent(li), 'no excluded intent in the grid');
            System.assert(!FieldServiceReportController.isRateLine(li),       'no rate line in the grid');
        }

        // 6 fixed rows - 1 shown = 5 blank padding rows.
        System.assertEquals(5, ext.blankRows.size(), 'five padding rows expected');
    }

    @isTest
    static void testNoLineItems() {
        // Work Order with no line items -> totals 0, rates guarded, full padding
        WorkOrder wo = new WorkOrder();
        insert wo;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(wo);
        FieldServiceReportController ext = new FieldServiceReportController(sc);
        Test.stopTest();

        System.assertEquals(0, ext.parts.size(), 'no line items');
        System.assert(ext.laborTotal    == 0, 'labor total zero');
        System.assert(ext.travelTotal   == 0, 'travel total zero');
        System.assert(ext.shippingTotal == 0, 'shipping total zero');
        System.assert(ext.totalParts    == 0, 'parts total zero');
        System.assert(ext.subtotal      == 0, 'subtotal zero');

        // divide-by-zero guard should return 0, not throw
        System.assert(ext.laborEffRate  == 0, 'labor rate guarded');
        System.assert(ext.travelEffRate == 0, 'travel rate guarded');

        System.assertEquals(0, ext.displayParts.size(), 'empty grid');

        // 6 fixed rows - 0 shown = 6 padding rows
        System.assertEquals(6, ext.blankRows.size(), 'full padding expected');
    }

    @isTest
    static void testGridNeverOverPads() {
        // More printable lines than FIXED_PART_ROWS must not produce negative
        // padding -- the loop bound has to tolerate a negative difference.
        Id pbeId = makePricebookEntry();
        WorkOrder wo = new WorkOrder(Pricebook2Id = Test.getStandardPricebookId());
        insert wo;

        List<WorkOrderLineItem> many = new List<WorkOrderLineItem>();
        for (Integer i = 0; i < 8; i++) {
            many.add(makeLine(wo.Id, pbeId, 'Part Consumed', 'Outright Sale', 1, 10));
        }
        insert many;

        Test.startTest();
        FieldServiceReportController ext =
            new FieldServiceReportController(new ApexPages.StandardController(wo));
        Test.stopTest();

        System.assertEquals(8, ext.displayParts.size(), 'all eight print');
        System.assertEquals(0, ext.blankRows.size(),    'no negative padding');
    }

@isTest
    static void testMaintenanceSignaturesAndApptRows() {

        WorkOrder wo = new WorkOrder(Make_Model__c = 'GE/Logiq E9');
        insert wo;

        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId  = wo.Id,
            SchedStartTime  = DateTime.now(),
            SchedEndTime    = DateTime.now().addHours(2),
            ActualStartTime = DateTime.now(),
            ActualEndTime   = DateTime.now().addHours(2)
        );
        insert sa;

        // One record per canonical Type + one unmapped type. P/F values as the
        // full words so abbreviatePF() hits its replacement branch (Pass -> P).
        insert new List<Maintenance_Item__c>{
            new Maintenance_Item__c(Service_Appointment__c = sa.Id, Type__c = 'Preliminary Checks',      Verify_Power_Up__c = 'Pass'),
            new Maintenance_Item__c(Service_Appointment__c = sa.Id, Type__c = 'Electric Tests',          Test_Lead_Isolation_P_F__c = 'Fail'),
            new Maintenance_Item__c(Service_Appointment__c = sa.Id, Type__c = 'Preliminary  Trophon',    Self_Test__c = 'Not Applicable'),
            new Maintenance_Item__c(Service_Appointment__c = sa.Id, Type__c = 'Findings',                Cycle_Count__c = 1200),
            new Maintenance_Item__c(Service_Appointment__c = sa.Id, Type__c = 'Corrective Action Note',  Corrective_Action_Required__c = 'Pass'),
            new Maintenance_Item__c(Service_Appointment__c = sa.Id, Type__c = 'Transducer',              Transducer_Model__c = 'C1-5', P_F__c = 'Pass'),
            new Maintenance_Item__c(Service_Appointment__c = sa.Id, Type__c = 'Peripheral',              Peripheral_Name__c = 'Printer', Peripheral_P_F__c = 'Pass'),
            new Maintenance_Item__c(Service_Appointment__c = sa.Id, Type__c = 'Test Equipment',          Test_Equipment_Model_Name__c = 'Fluke ESA612')
        };

        // Files-backed signatures so loadSignatures() runs end to end.
        insertSignature(wo.Id, 'Engineer');
        insertSignature(sa.Id, 'Customer');

        Test.startTest();
        FieldServiceReportController ext =
            new FieldServiceReportController(new ApexPages.StandardController(wo));
        List<FieldServiceReportController.ApptRow> rows = ext.getAppointmentRows();
        Test.stopTest();

        System.assertEquals('P', ext.prelimChecks.Verify_Power_Up__c, 'Pass -> P via abbreviatePF');
        System.assertEquals(1, ext.transducers.size(),   'one transducer row');
        System.assertEquals(1, ext.peripherals.size(),   'one peripheral row');
        System.assertEquals(1, ext.testEquipment.size(), 'one test-equipment row');

        System.assertEquals(1, rows.size(), 'one appointment row');
        System.assert(String.isNotBlank(rows[0].range), 'range string built');

        // loadSignatures() runs with real DigitalSignature records for coverage.
        // The Document-file link + SignatureType routing are org-specific and
        // don't reliably resolve an image in a test transaction, so no hard
        // assert on the resolved signature here.
    }

        // DigitalSignature's Document file field auto-creates the linked File that
    // loadSignatures() resolves, so no manual ContentVersion/Link is needed.
    private static void insertSignature(Id parentId, String sigType) {
        insert new DigitalSignature(
            ParentId            = parentId,
            SignatureType       = sigType,
            DocumentName        = sigType + '.png',
            DocumentContentType = 'image/png',
            DocumentBody        = Blob.valueOf('fake-png-bytes')
        );
    }
}