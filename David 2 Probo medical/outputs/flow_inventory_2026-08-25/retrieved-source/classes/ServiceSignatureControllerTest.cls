@isTest
private class ServiceSignatureControllerTest {

    // ---- helpers ----
    private static WorkType wt(String name) {
        WorkType w = new WorkType(Name = name, EstimatedDuration = 1, DurationType = 'Hours');
        insert w;
        return w;
    }

    private static WorkOrder wo(String workType, String makeModel) {
        WorkOrder w = new WorkOrder(
            Subject            = 'Test WO',
            WorkTypeId         = wt(workType).Id,
            Make_Model__c      = makeModel,
            Service_Site_Name__c = 'Health Central'
        );
        insert w;
        return w;
    }

    // A Work Order with every field that getMissingRequiredFields() checks populated.
    // NOTE: StateCode/CountryCode are set (this org has State & Country Picklists on, so
    // State/Country derive from them). If PO_Number__c is a numeric field, or
    // Billing_State__c is a restricted picklist, adjust those two values to match.
    private static WorkOrder completeWo() {
        WorkOrder w = new WorkOrder(
            Subject              = 'Complete WO',
            WorkTypeId           = wt('Break Fix').Id,
            Make_Model__c        = 'GE Logiq',
            Service_Site_Name__c = 'Health Central',
            // Service address (set the codes; State/Country derive when picklists are on)
            Street      = '123 Main St',
            City        = 'Tampa',
            StateCode   = 'FL',
            CountryCode = 'US',
            PostalCode  = '33634',
            // Order
            PO_Number__c = 'PO-12345',                 // adjust if PO_Number__c is numeric
            // Billing (custom)
            Billing_Account_Name__c     = 'Acme Health',
            Billing_Street__c           = '500 Bill St',
            Billing_City__c             = 'Tampa',
            Billing_State__c            = 'FL',         // adjust if restricted picklist
            Billing_Zip_Postal_Code__c  = '33634'
        );
        insert w;
        return w;
    }

    // An active/inactive Service Resource pointing at the running user. Used by the
    // engineer-name tests. Pointing at the running user avoids creating a User,
    // which would mean mixed DML and profile/permission setup for no extra coverage.
    private static ServiceResource resource(String name, Boolean isActive) {
        ServiceResource sr = new ServiceResource(
            Name            = name,
            RelatedRecordId = UserInfo.getUserId(),
            ResourceType    = 'T',
            IsActive        = isActive
        );
        insert sr;
        return sr;
    }

    // plain base64 (no data: prefix)
    private static String img() {
        return EncodingUtil.base64Encode(Blob.valueOf('signature-bytes'));
    }
    // data-URI form, to exercise buildAttachment's comma-strip branch
    private static String dataImg() {
        return 'data:image/png;base64,' + EncodingUtil.base64Encode(Blob.valueOf('signature-bytes'));
    }

    private static Integer sigCount(Id woId) {
        return [SELECT COUNT() FROM Service_Signature__c WHERE Work_Order__c = :woId];
    }
    private static Integer attCount(Id woId) {
        return [SELECT COUNT() FROM Attachment
                WHERE ParentId IN (SELECT Id FROM Service_Signature__c WHERE Work_Order__c = :woId)];
    }
    private static String latestTitle(Id docId) {
        return [SELECT Title FROM ContentVersion
                WHERE ContentDocumentId = :docId AND IsLatest = true LIMIT 1].Title;
    }
    private static void expectFail(Id woId, String en, String ei, Boolean cu, String cn, String ci) {
        Boolean threw = false;
        try {
            ServiceSignatureController.saveSignatures(woId, en, ei, cu, cn, ci);
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Expected a validation exception');
    }

    // ===================================================================
    //  saveSignatures
    // ===================================================================
    @isTest static void saveSignatures_bothPresent() {
        WorkOrder w = wo('Break Fix', 'GE Logiq');

        Test.startTest();
        // engineer uses a data: URI, customer uses plain base64 -> both buildAttachment branches
        ServiceSignatureController.saveSignatures(w.Id, 'Mindy Bender', dataImg(), false, 'John Smith', img());
        Test.stopTest();

        System.assertEquals(2, sigCount(w.Id), 'Engineer + customer records');
        System.assertEquals(2, attCount(w.Id), 'One signature image each');
    }

    @isTest static void saveSignatures_customerUnavailable() {
        WorkOrder w = wo('Break Fix', 'x');

        Test.startTest();
        ServiceSignatureController.saveSignatures(w.Id, 'Eng', img(), true, null, null);
        Test.stopTest();

        System.assertEquals(2, sigCount(w.Id), 'Customer row still created, marked unavailable');
        Service_Signature__c cust = [
            SELECT Unavailable__c FROM Service_Signature__c
            WHERE Work_Order__c = :w.Id AND Signer_Type__c = 'Customer' LIMIT 1
        ];
        System.assertEquals(true, cust.Unavailable__c);
        System.assertEquals(1, attCount(w.Id), 'Only the engineer signature is attached');
    }

    @isTest static void saveSignatures_replacesPriorSet() {
        WorkOrder w = wo('Break Fix', 'x');
        ServiceSignatureController.saveSignatures(w.Id, 'E1', img(), false, 'C1', img());

        Test.startTest();
        ServiceSignatureController.saveSignatures(w.Id, 'E2', img(), false, 'C2', img());
        Test.stopTest();

        System.assertEquals(2, sigCount(w.Id), 'Re-run replaces, not appends');
        String engName = [
            SELECT Signer_Name__c FROM Service_Signature__c
            WHERE Work_Order__c = :w.Id AND Signer_Type__c = 'Engineer' LIMIT 1
        ].Signer_Name__c;
        System.assertEquals('E2', engName);
    }

    @isTest static void saveSignatures_validation() {
        WorkOrder w = wo('Break Fix', 'x');
        expectFail(w.Id, '',    img(), false, 'C',  img());   // blank engineer name
        expectFail(w.Id, 'E',   '',    false, 'C',  img());   // blank engineer image
        expectFail(w.Id, 'E',   img(), false, '',   img());   // blank customer name
        expectFail(w.Id, 'E',   img(), false, 'C',  '');      // blank customer image
        System.assertEquals(0, sigCount(w.Id), 'Validation fails before any DML');
    }

    // ===================================================================
    //  getMissingRequiredFields (the signature-screen gate)
    // ===================================================================
    @isTest static void getMissingRequiredFields_reportsBlanks() {
        WorkOrder w = wo('Break Fix', 'x');   // address / PO / billing all empty

        Test.startTest();
        List<String> missing = ServiceSignatureController.getMissingRequiredFields(w.Id);
        Test.stopTest();

        System.assert(!missing.isEmpty(), 'Expected missing fields on a bare Work Order');
        // Custom fields unlikely to be auto-populated by any insert automation:
        System.assert(missing.contains('PO Number'), 'Missing list: ' + missing);
        System.assert(missing.contains('Billing Account Name'), 'Missing list: ' + missing);
    }

    @isTest static void getMissingRequiredFields_allPresentReturnsEmpty() {
        WorkOrder w = completeWo();

        Test.startTest();
        List<String> missing = ServiceSignatureController.getMissingRequiredFields(w.Id);
        Test.stopTest();

        System.assert(missing.isEmpty(), 'Expected no missing fields, got: ' + missing);
    }

    // ===================================================================
    //  getSignatureContext (gate + engineer name on one round trip)
    //
    //  These assert that the context MIRRORS getMissingRequiredFields rather than
    //  restating which fields are required. Adding or removing a required field
    //  should only ever break the two gate tests above, never these.
    // ===================================================================
    @isTest static void getSignatureContext_mirrorsGateOnBareWorkOrder() {
        WorkOrder w = wo('Break Fix', 'x');
        List<String> expected = ServiceSignatureController.getMissingRequiredFields(w.Id);

        Test.startTest();
        ServiceSignatureController.SignatureContext ctx =
            ServiceSignatureController.getSignatureContext(w.Id);
        Test.stopTest();

        System.assertNotEquals(null, ctx, 'A context should always come back');
        System.assertNotEquals(null, ctx.missingFields, 'missingFields must never be null — the LWC iterates it');
        System.assertEquals(expected, ctx.missingFields, 'Context must report exactly what the gate reports');
        System.assert(ctx.missingFields.contains('PO Number'), 'Missing list: ' + ctx.missingFields);
    }

    @isTest static void getSignatureContext_completeWorkOrderHasNoMissingFields() {
        WorkOrder w = completeWo();

        Test.startTest();
        ServiceSignatureController.SignatureContext ctx =
            ServiceSignatureController.getSignatureContext(w.Id);
        Test.stopTest();

        System.assert(ctx.missingFields.isEmpty(), 'Expected no missing fields, got: ' + ctx.missingFields);
    }

    @isTest static void getSignatureContext_prefersServiceResourceName() {
        WorkOrder w = wo('Break Fix', 'x');
        resource('Dale Technician', true);

        Test.startTest();
        ServiceSignatureController.SignatureContext ctx =
            ServiceSignatureController.getSignatureContext(w.Id);
        Test.stopTest();

        System.assertEquals('Dale Technician', ctx.engineerName,
            'The active Service Resource name should pre-fill the engineer field');
    }

    @isTest static void getSignatureContext_fallsBackToRunningUserName() {
        WorkOrder w = wo('Break Fix', 'x');
        // No Service Resource exists for the running user (no SeeAllData, so the
        // table starts empty) — this is the dispatcher/admin path.

        Test.startTest();
        ServiceSignatureController.SignatureContext ctx =
            ServiceSignatureController.getSignatureContext(w.Id);
        Test.stopTest();

        System.assertEquals(UserInfo.getName(), ctx.engineerName,
            'Someone with no Service Resource should get their own user name');
    }

    @isTest static void getSignatureContext_neverReturnsBlankName() {
        WorkOrder w = wo('Break Fix', 'x');

        ServiceSignatureController.SignatureContext ctx =
            ServiceSignatureController.getSignatureContext(w.Id);

        System.assert(String.isNotBlank(ctx.engineerName),
            'A blank name would render an unattributed signature on the service report');
    }

    @isTest static void getSignatureContext_deletedWorkOrderThrowsFriendlyError() {
        // The gate assigns Database.query() to a single sObject, so a Work Order
        // that no longer exists throws rather than returning nothing.
        WorkOrder ghost = wo('Break Fix', 'x');
        Id ghostId = ghost.Id;
        delete ghost;

        Boolean threw = false;
        String message = null;
        Test.startTest();
        try {
            ServiceSignatureController.getSignatureContext(ghostId);
        } catch (AuraHandledException e) {
            threw = true;
            message = e.getMessage();
        }
        Test.stopTest();

        System.assert(threw, 'A missing Work Order should surface as AuraHandledException');
        System.assert(String.isNotBlank(message) && !message.contains('List has no rows'),
            'The engineer should see a readable message, not a raw Apex error: ' + message);
    }

    @isTest static void resolveEngineerName_ignoresInactiveServiceResource() {
        resource('Retired Resource', false);

        Test.startTest();
        String name = ServiceSignatureController.resolveEngineerName();
        Test.stopTest();

        System.assertEquals(UserInfo.getName(), name,
            'An inactive Service Resource must not be used — that name would be wrong on the report');
    }

    // ===================================================================
    //  markReadyForClose (final-report status advance)
    //  Requires the 'Ready for Close' value to exist on the Work Order Status
    //  picklist in this org. If org validation rules require extra fields to reach
    //  that status, populate them in a helper before calling.
    // ===================================================================
    @isTest static void markReadyForClose_setsStatus() {
        WorkOrder w = wo('Break Fix', 'x');

        Test.startTest();
        ServiceSignatureController.markReadyForClose(w.Id);
        Test.stopTest();

        WorkOrder after = [SELECT Status FROM WorkOrder WHERE Id = :w.Id LIMIT 1];
        System.assertEquals('Ready for Close', after.Status, 'WO should advance to Ready for Close');
    }

    // ===================================================================
    //  Signature read model (getters / SignatureView)
    // ===================================================================
    @isTest static void getters_present() {
        WorkOrder w = wo('Break Fix', 'x');
        ServiceSignatureController.saveSignatures(w.Id, 'Mindy', img(), false, 'John', img());

        Test.startTest();
        ServiceSignatureController c = new ServiceSignatureController(new ApexPages.StandardController(w));
        Test.stopTest();

        System.assertEquals('Mindy', c.getEngineerSig().signerName);
        System.assertEquals('John',  c.getCustomerSig().signerName);
        System.assert(c.getEngineerSigPresent());
        System.assert(c.getCustomerSigPresent());
        System.assert(!c.getCustomerSigUnavailable());
        System.assert(String.isNotBlank(c.getEngineerSig().signedAtText), 'signedAtText should format');
    }

    @isTest static void getters_customerUnavailable() {
        WorkOrder w = wo('Break Fix', 'x');
        ServiceSignatureController.saveSignatures(w.Id, 'Eng', img(), true, null, null);

        ServiceSignatureController c = new ServiceSignatureController(new ApexPages.StandardController(w));
        System.assert(c.getEngineerSigPresent());
        System.assert(c.getCustomerSigUnavailable());
        System.assert(!c.getCustomerSigPresent(), 'No customer image when unavailable');
    }

    // ===================================================================
    //  Routing
    // ===================================================================
    @isTest static void reportPageFor_routesByTypeAndModel() {
        WorkOrder bf = wo('Break Fix', 'GE Logiq');
        WorkOrder pm = wo('PPM', 'GE Logiq E10');
        WorkOrder tr = wo('PPM', 'Nanosonics Trophon EPR');

        System.assertEquals('/apex/FSL_US_FSR', ServiceSignatureController.reportPageFor(bf.Id));
        System.assertEquals('/apex/FSL_US_PPM', ServiceSignatureController.reportPageFor(pm.Id));

        String trPage = ServiceSignatureController.reportPageFor(tr.Id);
        System.assertNotEquals('/apex/FSL_US_PPM', trPage, 'Trophon routes to its own page');
        System.assert(trPage.toUpperCase().contains('TROPHON'), trPage);
    }

    @isTest static void modelContainsTrophon_cases() {
        System.assert(ServiceSignatureController.modelContainsTrophon('GE Trophon EPR'));
        System.assert(ServiceSignatureController.modelContainsTrophon('nanosonics trophon'));
        System.assert(!ServiceSignatureController.modelContainsTrophon('GE Logiq'));
        System.assert(!ServiceSignatureController.modelContainsTrophon(null));
    }

    @isTest static void routingFlags() {
        WorkOrder pm = wo('PPM', 'GE Logiq');
        WorkOrder tr = wo('PPM', 'Trophon Unit');
        WorkOrder bf = wo('Break Fix', 'x');

        ServiceSignatureController cpm = new ServiceSignatureController(new ApexPages.StandardController(pm));
        System.assert(cpm.getIsPpm());
        System.assert(!cpm.getIsTrophon());
        System.assert(!cpm.getIsBreakFix());

        ServiceSignatureController ctr = new ServiceSignatureController(new ApexPages.StandardController(tr));
        System.assert(ctr.getIsPpm());
        System.assert(ctr.getIsTrophon());

        ServiceSignatureController cbf = new ServiceSignatureController(new ApexPages.StandardController(bf));
        System.assert(cbf.getIsBreakFix());
        System.assert(!cbf.getIsPpm());
    }

    // ===================================================================
    //  saveReportVersion (versioned File naming + PMR/Prelim prefixes)
    // ===================================================================
    @isTest static void saveReportVersion_incrementsVersion() {
        WorkOrder wo = wo('Break Fix', 'x');

        Test.startTest();
        Id doc1 = ServiceSignatureController.saveReportVersion(wo.Id, Blob.valueOf('PDF-1'), false);
        Id doc2 = ServiceSignatureController.saveReportVersion(wo.Id, Blob.valueOf('PDF-2'), false);
        Test.stopTest();

        // Same report key -> same File (this is the new contract)
        System.assertEquals(doc1, doc2, 'Regeneration should version the SAME File');

        // ...but a new version was added behind it
        List<ContentVersion> versions = [
            SELECT Title, VersionNumber, IsLatest
            FROM ContentVersion
            WHERE ContentDocumentId = :doc1
            ORDER BY CreatedDate ASC
        ];
        System.assertEquals(2, versions.size(), 'Two generations -> two versions on one File');
        System.assert(versions[1].Title.endsWith(' v2'), 'Newest title should carry v2');
        System.assert(versions[1].IsLatest, 'Newest version should be current');
    }

    @isTest static void saveReportVersion_breakFixNamesFsr() {
        WorkOrder w = wo('Break Fix', 'GE Logiq');

        Test.startTest();
        Id d = ServiceSignatureController.saveReportVersion(w.Id, Blob.valueOf('PDF'), false);
        Test.stopTest();

        System.assert(latestTitle(d).startsWith('FSR-'), latestTitle(d));
    }

    @isTest static void saveReportVersion_ppmNamesPmr() {
        WorkOrder w = wo('PPM', 'GE Logiq');

        Test.startTest();
        Id d = ServiceSignatureController.saveReportVersion(w.Id, Blob.valueOf('PDF'), false);
        Test.stopTest();

        System.assert(latestTitle(d).startsWith('PMR-'), latestTitle(d));
    }

    @isTest static void saveReportVersion_preliminaryPrefix() {
        WorkOrder w = wo('Break Fix', 'x');

        Test.startTest();
        Id d = ServiceSignatureController.saveReportVersion(w.Id, Blob.valueOf('PDF'), true);
        Test.stopTest();

        System.assert(latestTitle(d).startsWith('Prelim FSR-'), latestTitle(d));
    }

    // ===================================================================
    //  generateAndSaveReport  (Test.isRunningTest short-circuits the render)
    //  NOTE: delete these two tests if you've removed generateAndSaveReport.
    // ===================================================================
    @isTest static void generateAndSaveReport_filesAReport() {
        WorkOrder w = wo('Break Fix', 'x');

        Test.startTest();
        Id docId = ServiceSignatureController.generateAndSaveReport(w.Id, false);
        Test.stopTest();

        System.assertNotEquals(null, docId);
        System.assertEquals(1, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :w.Id]);
        System.assert(latestTitle(docId).startsWith('FSR-'), latestTitle(docId));
    }

    @isTest static void generateAndSaveReport_preliminary() {
        WorkOrder w = wo('PPM', 'x');

        Test.startTest();
        Id docId = ServiceSignatureController.generateAndSaveReport(w.Id, true);
        Test.stopTest();

        System.assertNotEquals(null, docId);
        System.assert(latestTitle(docId).startsWith('Prelim PMR-'), latestTitle(docId));
    }
}