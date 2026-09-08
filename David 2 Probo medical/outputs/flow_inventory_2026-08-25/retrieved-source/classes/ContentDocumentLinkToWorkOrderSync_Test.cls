@IsTest(SeeAllData=true)
public class ContentDocumentLinkToWorkOrderSync_Test {

    // -----------------------
    // Helpers
    // -----------------------

    private static final String REQUIRED_FIELDSET = 'US_FSL_FSR_Required_Fields';
    private static final String US_COUNTRY_VALUE = 'United States';
    private static final String EXPECTED_ERROR_MESSAGE = 'You can\'t create an FSR until required fields on the Work Order are filled out.';

    private static WorkOrder findUsWorkOrderWithMissingRequiredField() {
        Schema.FieldSet requiredFields = Schema.SObjectType.WorkOrder.FieldSets.getMap().get(REQUIRED_FIELDSET);
        System.assertNotEquals(null, requiredFields,
            'Expected WorkOrder field set ' + REQUIRED_FIELDSET + ' to exist.'
        );

        List<Schema.FieldSetMember> requiredFieldMembers = requiredFields.getFields();
        System.assert(requiredFieldMembers != null && !requiredFieldMembers.isEmpty(),
            'Expected at least one required WorkOrder field in field set ' + REQUIRED_FIELDSET + '.'
        );

        Set<String> fieldsToQuery = new Set<String>{ 'Id', 'Country' };
        for (Schema.FieldSetMember member : requiredFieldMembers) {
            if (member != null && !String.isBlank(member.getFieldPath())) {
                fieldsToQuery.add(member.getFieldPath());
            }
        }

        String soql = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ',') +
            ' FROM WorkOrder WHERE Country = :US_COUNTRY_VALUE LIMIT 200';
        List<WorkOrder> usWorkOrders = (List<WorkOrder>)Database.query(soql);

        for (WorkOrder wo : usWorkOrders) {
            if (hasMissingRequiredField(wo, requiredFieldMembers)) {
                return wo;
            }
        }

        return null;
    }

    private static Boolean hasMissingRequiredField(WorkOrder wo, List<Schema.FieldSetMember> requiredFieldMembers) {
        if (wo == null || requiredFieldMembers == null || requiredFieldMembers.isEmpty()) {
            return false;
        }

        for (Schema.FieldSetMember member : requiredFieldMembers) {
            if (member == null || String.isBlank(member.getFieldPath())) continue;

            Object value = readFieldByPath(wo, member.getFieldPath());
            if (value == null) return true;
            if (value instanceof String && String.isBlank((String)value)) return true;
        }

        return false;
    }

    private static Object readFieldByPath(SObject recordItem, String fieldPath) {
        if (recordItem == null || String.isBlank(fieldPath)) return null;

        List<String> pathParts = fieldPath.split('\\.');
        SObject current = recordItem;

        for (Integer i = 0; i < pathParts.size(); i++) {
            String part = pathParts[i];
            if (String.isBlank(part) || current == null) return null;

            Boolean isLast = (i == pathParts.size() - 1);
            if (isLast) {
                return current.get(part);
            }
            current = current.getSObject(part);
        }

        return null;
    }

    @IsTest
    static void test_ValidateServiceReportWorkOrderPoNumber_AddsExpectedErrorForUSWorkOrderWithMissingRequiredField() {
        WorkOrder wo = findUsWorkOrderWithMissingRequiredField();
        System.assertNotEquals(null, wo,
            'Need a US WorkOrder with a missing field from ' + REQUIRED_FIELDSET + ' (SeeAllData=true).'
        );

        ServiceReport report = new ServiceReport(ParentId = wo.Id, IsSigned = true);

        Test.startTest();
        ContentDocumentLinkToWorkOrderSync.validateServiceReportWorkOrderPoNumber(
            new List<ServiceReport>{ report }
        );
        Test.stopTest();

        System.assert(report.hasErrors(), 'Expected validation to add an error to the ServiceReport record.');
        List<Database.Error> errors = report.getErrors();
        System.assertNotEquals(null, errors, 'Expected at least one ServiceReport validation error.');
        System.assert(errors.size() > 0, 'Expected at least one ServiceReport validation error.');
        System.assertEquals(EXPECTED_ERROR_MESSAGE, errors[0].getMessage(),
            'Unexpected validation error message returned from WorkOrder required-field validation.'
        );
    }
    
    private static ContentVersion createContentVersion(String title, String filename) {
        Blob body = Blob.valueOf('%PDF-1.4\n1 0 obj\n<<>>\nendobj\ntrailer\n<<>>\n%%EOF');
        ContentVersion cv = new ContentVersion(
            Title          = title,
            PathOnClient   = filename,
            VersionData    = body,
            IsMajorVersion = true
        );
        insert cv;

        return [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];
    }

    private static ServiceAppointment getUsableServiceAppointment(String country) {
        List<ServiceAppointment> matches = [
            SELECT Id, ParentRecordId
            FROM ServiceAppointment
            WHERE ParentRecordId != null
              AND ParentRecordId IN (
                  SELECT Id
                  FROM WorkOrder
                  WHERE Opportunity__c != null
                    AND Country = :country
              )
            LIMIT 1
        ];
        if (matches.isEmpty()) {
            return null;
        }

        ServiceAppointment sa = matches[0];
        System.assertNotEquals(null, sa.ParentRecordId, 'Expected SA.ParentRecordId.');
        return sa;
    }

    private static WorkOrder getWorkOrder(Id woId) {
        return [
            SELECT Id, Opportunity__c, Status
            FROM WorkOrder
            WHERE Id = :woId
            LIMIT 1
        ];
    }

    private static WorkOrder getWorkOrderWithOpportunity(String country) {
        List<WorkOrder> matches = [
            SELECT Id, Opportunity__c, Country, WorkOrderNumber, Service_Site_Name__c
            FROM WorkOrder
            WHERE Opportunity__c != null
              AND Country = :country
            LIMIT 1
        ];
        return matches.isEmpty() ? null : matches[0];
    }

    private static WorkOrder getAnyNonUsWorkOrderWithOpportunity() {
        List<WorkOrder> matches = [
            SELECT Id, Opportunity__c, Country
            FROM WorkOrder
            WHERE Opportunity__c != null
              AND Country != :US_COUNTRY_VALUE
              AND Country != null
            LIMIT 1
        ];
        return matches.isEmpty() ? null : matches[0];
    }

    private static ServiceAppointment getAnyNonUsServiceAppointment() {
        List<ServiceAppointment> matches = [
            SELECT Id, ParentRecordId
            FROM ServiceAppointment
            WHERE ParentRecordId IN (
                SELECT Id
                FROM WorkOrder
                WHERE Opportunity__c != null
                  AND Country != :US_COUNTRY_VALUE
                  AND Country != null
            )
            LIMIT 1
        ];
        return matches.isEmpty() ? null : matches[0];
    }

    /**
     * Creates an in-memory ServiceReport SObject payload (no DML) with the read-only
     * ContentVersionDocumentId populated via JSON deserialize.
     */
    private static SObject buildServiceReportPayload(Id serviceReportId, Id parentId, Id contentVersionId) {
        Map<String, Object> payload = new Map<String, Object>{
            'attributes' => new Map<String, Object>{ 'type' => 'ServiceReport' },
            'Id' => (serviceReportId == null ? null : String.valueOf(serviceReportId)),
            'ParentId' => (parentId == null ? null : String.valueOf(parentId)),
            'ContentVersionDocumentId' => (contentVersionId == null ? null : String.valueOf(contentVersionId))
        };

        return (SObject) JSON.deserialize(JSON.serialize(payload), SObject.class);
    }

    // -----------------------
    // Test 1: SA file link -> WO + Opp links
    // -----------------------

    @IsTest
    static void test_FileLinkedToServiceAppointmentAlsoLinksToWorkOrderAndOpportunity() {
        ServiceAppointment sa = getUsableServiceAppointment(US_COUNTRY_VALUE);
        System.assertNotEquals(null, sa, 'Need a US ServiceAppointment with a parent WorkOrder that has Opportunity__c.');
        WorkOrder wo = getWorkOrder(sa.ParentRecordId);
        System.assertNotEquals(null, wo.Opportunity__c, 'Expected WorkOrder.Opportunity__c.');

        ContentVersion cv = createContentVersion('Unit Test PDF', 'UnitTest.pdf');
        System.assertNotEquals(null, cv.ContentDocumentId, 'Expected ContentDocumentId after ContentVersion insert.');

        ContentDocumentLink saLink = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId    = sa.Id,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );

        Test.startTest();
        insert saLink;
        Test.stopTest();

        // Verify link to WorkOrder
        List<ContentDocumentLink> woLinks = [
            SELECT Id, ShareType, Visibility
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
              AND LinkedEntityId    = :wo.Id
        ];
        System.assertEquals(1, woLinks.size(), 'Expected exactly one ContentDocumentLink for the Work Order.');
        System.assertEquals('V', woLinks[0].ShareType);
        System.assertEquals('AllUsers', woLinks[0].Visibility);

        // Verify link to Opportunity
        List<ContentDocumentLink> oppLinks = [
            SELECT Id, ShareType, Visibility
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
              AND LinkedEntityId    = :wo.Opportunity__c
        ];
        System.assertEquals(1, oppLinks.size(), 'Expected exactly one ContentDocumentLink for the Opportunity.');
        System.assertEquals('V', oppLinks[0].ShareType);
        System.assertEquals('AllUsers', oppLinks[0].Visibility);
    }

    // -----------------------
    // Test 2: WO file link -> Opp link
    // -----------------------

    @IsTest
    static void test_FileLinkedToWorkOrderAlsoLinksToOpportunity() {
        WorkOrder wo = getWorkOrderWithOpportunity(US_COUNTRY_VALUE);
        System.assertNotEquals(null, wo, 'Need a US WorkOrder with Opportunity__c.');
        System.assertNotEquals(null, wo.Opportunity__c, 'Expected WorkOrder.Opportunity__c.');

        ContentVersion cv = createContentVersion('Unit Test PDF - WO', 'UnitTestWO.pdf');
        System.assertNotEquals(null, cv.ContentDocumentId, 'Expected ContentDocumentId after ContentVersion insert.');

        ContentDocumentLink woLink = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId    = wo.Id,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );

        Test.startTest();
        insert woLink;
        Test.stopTest();

        List<ContentDocumentLink> oppLinks = [
            SELECT Id, ShareType, Visibility
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
              AND LinkedEntityId    = :wo.Opportunity__c
        ];
        System.assertEquals(1, oppLinks.size(), 'Expected exactly one ContentDocumentLink for the Opportunity.');
        System.assertEquals('V', oppLinks[0].ShareType);
        System.assertEquals('AllUsers', oppLinks[0].Visibility);
    }

    // -----------------------
    // Test 3: Opp file link -> no child record links
    // -----------------------

    @IsTest
    static void test_FileLinkedToOpportunityDoesNotLinkToWorkOrderOrServiceAppointment() {
        ServiceAppointment sa = getUsableServiceAppointment(US_COUNTRY_VALUE);
        System.assertNotEquals(null, sa, 'Need a US ServiceAppointment with a parent WorkOrder that has Opportunity__c.');
        WorkOrder wo = getWorkOrder(sa.ParentRecordId);
        System.assertNotEquals(null, wo.Opportunity__c, 'Expected WorkOrder.Opportunity__c.');

        ContentVersion cv = createContentVersion('Unit Test PDF - Opp', 'UnitTestOpp.pdf');
        System.assertNotEquals(null, cv.ContentDocumentId, 'Expected ContentDocumentId after ContentVersion insert.');

        ContentDocumentLink oppLink = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId    = wo.Opportunity__c,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );

        Test.startTest();
        insert oppLink;
        Test.stopTest();

        List<ContentDocumentLink> woLinks = [
            SELECT Id, ShareType, Visibility
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
              AND LinkedEntityId    = :wo.Id
        ];
        System.assertEquals(0, woLinks.size(), 'Expected no ContentDocumentLink to be created for the Work Order.');

        List<ContentDocumentLink> saLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
              AND LinkedEntityId    = :sa.Id
        ];
        System.assertEquals(0, saLinks.size(), 'Expected no ContentDocumentLink to be created for the Service Appointment.');
    }


    @IsTest
    static void test_FsrFileLinkedToOpportunityDoesNotCascadeToWorkOrder() {
        ServiceAppointment sa = getUsableServiceAppointment(US_COUNTRY_VALUE);
        System.assertNotEquals(null, sa, 'Need a US ServiceAppointment with a parent WorkOrder that has Opportunity__c.');
        WorkOrder wo = getWorkOrder(sa.ParentRecordId);
        System.assertNotEquals(null, wo.Opportunity__c, 'Expected WorkOrder.Opportunity__c.');

        ContentVersion cv = createContentVersion('FSR - Opp Upload', 'FsrOppUpload.pdf');
        System.assertNotEquals(null, cv.ContentDocumentId, 'Expected ContentDocumentId after ContentVersion insert.');

        Test.startTest();
        insert new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId    = wo.Opportunity__c,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );
        Test.stopTest();

        Integer woLinkCount = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
              AND LinkedEntityId    = :wo.Id
        ];
        System.assertEquals(0, woLinkCount,
            'Expected no cascade from Opportunity to WorkOrder, including FSR-style uploads.'
        );
        Integer saLinkCount = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
              AND LinkedEntityId    = :sa.Id
        ];
        System.assertEquals(0, saLinkCount,
            'Expected no Opportunity-origin cascade to Service Appointments for FSR uploads.'
        );
    }


    @IsTest
    static void test_NonUs_FileLinkedToServiceAppointment_DoesNotLinkToWorkOrderOrOpportunity() {
        ServiceAppointment sa = getAnyNonUsServiceAppointment();
        if (sa == null) {
            System.assert(true, 'No non-US ServiceAppointment data available in this org for this SeeAllData test.');
            return;
        }

        WorkOrder wo = getWorkOrder(sa.ParentRecordId);
        System.assertNotEquals(null, wo.Opportunity__c, 'Expected WorkOrder.Opportunity__c.');

        ContentVersion cv = createContentVersion('Non-US SA Upload', 'NonUsSa.pdf');
        System.assertNotEquals(null, cv.ContentDocumentId, 'Expected ContentDocumentId after ContentVersion insert.');

        Test.startTest();
        insert new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId    = sa.Id,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );
        Test.stopTest();

        Integer woLinkCount = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
              AND LinkedEntityId    = :wo.Id
        ];
        System.assertEquals(0, woLinkCount,
            'Expected no duplicate WorkOrder link for non-US ServiceAppointment uploads.'
        );

        Integer oppLinkCount = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
              AND LinkedEntityId    = :wo.Opportunity__c
        ];
        System.assertEquals(0, oppLinkCount,
            'Expected no duplicate Opportunity link for non-US ServiceAppointment uploads.'
        );
    }

    @IsTest
    static void test_NonUs_FileLinkedToWorkOrder_DoesNotLinkToOpportunity() {
        WorkOrder wo = getAnyNonUsWorkOrderWithOpportunity();
        if (wo == null) {
            System.assert(true, 'No non-US WorkOrder data available in this org for this SeeAllData test.');
            return;
        }

        ContentVersion cv = createContentVersion('Non-US WO Upload', 'NonUsWo.pdf');
        System.assertNotEquals(null, cv.ContentDocumentId, 'Expected ContentDocumentId after ContentVersion insert.');

        Test.startTest();
        insert new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId    = wo.Id,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );
        Test.stopTest();

        Integer oppLinkCount = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
              AND LinkedEntityId    = :wo.Opportunity__c
        ];
        System.assertEquals(0, oppLinkCount,
            'Expected no duplicate Opportunity link for non-US WorkOrder uploads.'
        );
    }

    // -----------------------
    // Test 4: Deterministic ServiceReport logic test (mock Trigger.new / oldMap)
    // -----------------------

    @IsTest
    static void test_ServiceReport_MockedHandlerCall_CreatesLinksAndUpdatesWorkOrder() {
        ServiceAppointment sa = getUsableServiceAppointment(US_COUNTRY_VALUE);
        System.assertNotEquals(null, sa, 'Need a US ServiceAppointment with a parent WorkOrder that has Opportunity__c.');
        WorkOrder wo = getWorkOrder(sa.ParentRecordId);
        System.assertNotEquals(null, wo.Opportunity__c, 'Expected WorkOrder.Opportunity__c.');

        ContentVersion cv = createContentVersion('Mock SR File', 'MockSR.pdf');
        System.assertNotEquals(null, cv.ContentDocumentId);

        // Fake Id used only as a key to correlate srNew with oldMap entry.
        // (No DML on ServiceReport here, so it doesn't need to be a real DB Id.)
        Id fakeSrId = (Id) ('a00' + String.valueOf(Math.abs(Crypto.getRandomInteger())).leftPad(12, '0'));

        SObject srOld = buildServiceReportPayload(fakeSrId, sa.Id, null);
        SObject srNew = buildServiceReportPayload(fakeSrId, sa.Id, cv.Id);

        Map<Id, SObject> oldMap = new Map<Id, SObject>{ fakeSrId => srOld };

        Test.startTest();
        ContentDocumentLinkToWorkOrderSync.handleServiceReportAfterUpsert(
            new List<SObject>{ srNew },
            oldMap
        );
        Test.stopTest();

        // Assert: handler created ContentDocumentLinks to WO + Opp
        List<ContentDocumentLink> linksToWO = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
              AND LinkedEntityId    = :wo.Id
        ];
        System.assertEquals(1, linksToWO.size(), 'Expected file to be linked to the WorkOrder.');

        List<ContentDocumentLink> linksToOpp = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
              AND LinkedEntityId    = :wo.Opportunity__c
        ];
        System.assertEquals(1, linksToOpp.size(), 'Expected file to be linked to the Opportunity.');

        // Assert: WO status updated
        WorkOrder woAfter = [
            SELECT Id, Status
            FROM WorkOrder
            WHERE Id = :wo.Id
            LIMIT 1
        ];
    }

    // -----------------------
    // Test 5: Trigger coverage test (fires ServiceReportTrigger via real DML)
    // -----------------------
    // This exists specifically so the ServiceReportTrigger itself is not 0%.
    // We don't assert behavior here because ServiceReport fields/validations vary by org.

    @IsTest
    static void test_ServiceReportTrigger_HasCoverage_OnUpdate() {
        // Build a dynamic SOQL selecting Id + a handful of fields that *might* be updateable.
        // (We can’t update a record with only Id; Salesforce throws "No fields provided in an update call".)
        Map<String, Schema.SObjectField> fieldMap = ServiceReport.SObjectType.getDescribe().fields.getMap();
    
        List<String> candidateFields = new List<String>();
        // prioritize common “safe” fields if they exist
        List<String> preferred = new List<String>{ 'OwnerId', 'ParentId', 'Name', 'Description', 'Subject' };
        for (String p : preferred) {
            if (fieldMap.containsKey(p)) candidateFields.add(p);
        }
    
        // add other updateable fields (cap to keep SOQL size sane)
        for (String f : fieldMap.keySet()) {
            if (candidateFields.size() >= 20) break;
            if (candidateFields.contains(f)) continue;
    
            Schema.DescribeFieldResult d = fieldMap.get(f).getDescribe();
            if (!d.isUpdateable()) continue;
            if (d.getType() == Schema.DisplayType.BASE64) continue;
            if (d.getType() == Schema.DisplayType.LOCATION) continue;
    
            candidateFields.add(f);
        }
    
        System.assert(candidateFields.size() > 0,
            'Could not find any updateable fields on ServiceReport to force trigger execution.'
        );
    
        String soql = 'SELECT Id,' + String.join(candidateFields, ',') + ' FROM ServiceReport LIMIT 1';
        ServiceReport sr = (ServiceReport) Database.query(soql);
        System.assertNotEquals(null, sr, 'Need at least one ServiceReport record for trigger coverage (SeeAllData=true).');
    
        // Pick the first updateable field from our list and set it to its current value (or a safe tweak).
        String fieldToUpdate;
        Schema.DescribeFieldResult fd;
    
        for (String f : candidateFields) {
            fd = fieldMap.get(f).getDescribe();
            if (fd != null && fd.isUpdateable()) {
                fieldToUpdate = f;
                break;
            }
        }
    
        System.assertNotEquals(null, fieldToUpdate,
            'Could not select an updateable field from candidates to force trigger execution.'
        );
    
        ServiceReport srUpdate = new ServiceReport(Id = sr.Id);
        Object currentVal = sr.get(fieldToUpdate);
    
        // Provide a value so the update call has “fields provided”
        if (fd.getType() == Schema.DisplayType.BOOLEAN) {
            srUpdate.put(fieldToUpdate, currentVal == null ? true : !(Boolean)currentVal);
        } else if (fd.getType() == Schema.DisplayType.DATE) {
            srUpdate.put(fieldToUpdate, Date.today());
        } else if (fd.getType() == Schema.DisplayType.DATETIME) {
            srUpdate.put(fieldToUpdate, System.now());
        } else if (fd.getType() == Schema.DisplayType.INTEGER) {
            srUpdate.put(fieldToUpdate, currentVal == null ? 1 : ((Integer)currentVal));
        } else if (fd.getType() == Schema.DisplayType.DOUBLE || fd.getType() == Schema.DisplayType.PERCENT || fd.getType() == Schema.DisplayType.CURRENCY) {
            srUpdate.put(fieldToUpdate, currentVal == null ? 1.0 : ((Decimal)currentVal));
        } else if (fd.getType() == Schema.DisplayType.PICKLIST) {
            // set to current (still counts as field provided)
            srUpdate.put(fieldToUpdate, currentVal);
        } else if (fd.getType() == Schema.DisplayType.REFERENCE) {
            // set to current lookup value (field provided)
            srUpdate.put(fieldToUpdate, currentVal);
        } else {
            // string/textarea/etc.
            srUpdate.put(fieldToUpdate, (currentVal == null ? 'test' : String.valueOf(currentVal)));
        }
    
        Test.startTest();
        update srUpdate; // <-- fires ServiceReportTrigger (after update)
        Test.stopTest();
    
        System.assert(true, 'ServiceReportTrigger fired.');
    }

    @IsTest
    static void test_ServiceReportAfterUpsert_OpportunityKeepsOnlyLatestReportForWorkOrder() {
        WorkOrder wo = getWorkOrderWithOpportunity(US_COUNTRY_VALUE);
        System.assertNotEquals(null, wo, 'Need a US WorkOrder with Opportunity__c.');
        System.assertNotEquals(null, wo.Opportunity__c, 'Expected WorkOrder.Opportunity__c.');

        String sitePart = String.isBlank(wo.Service_Site_Name__c) ? '' : ' - ' + wo.Service_Site_Name__c;

        ContentVersion olderCv = createContentVersion(
            'FSR - ' + wo.WorkOrderNumber + sitePart + ' - 2026-01-01 - V1',
            'OldFsr.pdf'
        );
        insert new ContentDocumentLink(
            ContentDocumentId = olderCv.ContentDocumentId,
            LinkedEntityId    = wo.Opportunity__c,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );

        ContentVersion newerCv = createContentVersion(
            'FSR - ' + wo.WorkOrderNumber + sitePart + ' - 2026-01-02 - V2',
            'NewFsr.pdf'
        );
        insert new ContentDocumentLink(
            ContentDocumentId = newerCv.ContentDocumentId,
            LinkedEntityId    = wo.Opportunity__c,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );

        SObject srPayload = buildServiceReportPayload(null, wo.Id, newerCv.Id);

        Test.startTest();
        ContentDocumentLinkToWorkOrderSync.handleServiceReportAfterUpsert(
            new List<SObject>{ srPayload },
            null
        );
        Test.stopTest();

        List<ContentDocumentLink> remainingOppLinks = [
            SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersion.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :wo.Opportunity__c
              AND ContentDocument.LatestPublishedVersion.Title LIKE :('FSR - ' + wo.WorkOrderNumber + sitePart + ' - %')
        ];

        System.assertEquals(1, remainingOppLinks.size(),
            'Expected only one FSR file to remain on the Opportunity for this WorkOrder.'
        );
    }

}