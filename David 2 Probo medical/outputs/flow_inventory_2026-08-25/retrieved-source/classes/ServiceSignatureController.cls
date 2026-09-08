/**
 * Backs the signature-capture + report-generation LWC, and the Visualforce
 * service report (as a second page extension). Requires connectivity.
 *
 * saveSignatures takes FLAT primitive parameters (not a wrapper type) because
 * that is the most reliable LWC -> Apex binding.
 */
public with sharing class ServiceSignatureController {

    private static final String REPORT_PAGE = '/apex/FSL_US_FSR';
    private static final String STATUS_READY_FOR_CLOSE = 'Ready for Close';

    public Id workOrderId { get; set; }
    private List<SignatureView> sigCache;

    public ServiceSignatureController(ApexPages.StandardController stdCtrl) {
        this.workOrderId = stdCtrl.getId();
    }

    // AuraHandledException whose message reliably reaches the LWC.
    private static AuraHandledException err(String msg) {
        AuraHandledException e = new AuraHandledException(msg);
        e.setMessage(msg);
        return e;
    }

    // ----- Step 0: required-field gate (call before showing the signature screen) -----
    // Returns the friendly labels of any required fields still empty.
    // Empty list => everything required is filled in and the signature screen may open.
    // Skip this entirely for a Preliminary report (the LWC just doesn't call it).
    @AuraEnabled
    public static List<String> getMissingRequiredFields(Id workOrderId) {
        // API name -> label the engineer sees.
        Map<String, String> required = new Map<String, String>{
            // --- Service address (standard WorkOrder Address compound) ---
            'Street'                     => 'Service Street',
            'City'                       => 'Service City',
            'State'                      => 'Service State',
            'StateCode'                  => 'Service State Code',
            'Country'                    => 'Service Country',
            'PostalCode'                 => 'Service Postal Code',
            // --- Order ---
            'PO_Number__c'               => 'PO Number',
            // --- Billing (custom) ---
            'Billing_Account_Name__c'    => 'Billing Account Name',
            'Billing_Street__c'          => 'Billing Street',
            'Billing_City__c'            => 'Billing City',
            'Billing_State__c'           => 'Billing State',
            'Billing_Zip_Postal_Code__c' => 'Billing Zip / Postal Code'
        };

        String soql = 'SELECT ' + String.join(new List<String>(required.keySet()), ', ')
                    + ' FROM WorkOrder WHERE Id = :workOrderId LIMIT 1';
        WorkOrder wo = Database.query(soql);

        List<String> missing = new List<String>();
        for (String api : required.keySet()) {
            Object val = wo.get(api);
            if (val == null || String.isBlank(String.valueOf(val))) {
                missing.add(required.get(api));
            }
        }
        return missing;
    }

    // ----- Step 0b: everything the capture screen needs, on one round trip -----
    // The required-field gate PLUS the engineer's display name, so the LWC does
    // not make a second request (or a wire call) just to pre-fill a name.
    //
    // Deliberately NOT cacheable=true. The documented recovery path is "close
    // this window, complete the fields on the Work Order, then reopen" — a
    // cached response would replay the stale missing-field list on reopen and
    // tell the engineer to fix fields they just fixed.
    @AuraEnabled
    public static SignatureContext getSignatureContext(Id workOrderId) {
        SignatureContext ctx = new SignatureContext();

        try {
            ctx.missingFields = getMissingRequiredFields(workOrderId);
        } catch (QueryException qe) {
            // Database.query above assigns to a single sObject, so a deleted or
            // unreachable Work Order throws rather than returning nothing.
            throw err('This Work Order could not be read. Close this window and reopen it from the Work Order.');
        }
        if (ctx.missingFields == null) {
            ctx.missingFields = new List<String>();
        }

        // A name is a convenience, never a gate: if it cannot be resolved the
        // engineer simply types it. Failing here would block signing outright.
        try {
            ctx.engineerName = resolveEngineerName();
        } catch (Exception e) {
            ctx.engineerName = '';
        }

        return ctx;
    }

    /**
     * Prefer the Service Resource name — that is the engineer as Field Service
     * knows them, and what the customer expects to see on the report. Falls back
     * to the running user's name, which covers a dispatcher, admin, or anyone
     * without an active Service Resource record.
     *
     * Plain SOQL (no WITH SECURITY_ENFORCED) to match the rest of this class and
     * so a technician profile without explicit FLS on ServiceResource.Name still
     * gets a pre-filled name rather than a silent blank.
     */
    @TestVisible
    private static String resolveEngineerName() {
        List<ServiceResource> resources = [
            SELECT Name
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
              AND IsActive = true
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        if (!resources.isEmpty() && String.isNotBlank(resources[0].Name)) {
            return resources[0].Name;
        }
        return UserInfo.getName();
    }

    // Returned to the LWC by getSignatureContext.
    public class SignatureContext {
        @AuraEnabled public String engineerName { get; set; }
        @AuraEnabled public List<String> missingFields { get; set; }

        public SignatureContext() {
            this.engineerName = '';
            this.missingFields = new List<String>();
        }
    }

    // ----- Step 1: save signatures (flat params) -----
    @AuraEnabled
    public static void saveSignatures(Id parentId,
                                      String engineerName,
                                      String engineerImage,
                                      Boolean customerUnavailable,
                                      String customerName,
                                      String customerImage) {
        // Split checks so the error names exactly what didn't arrive.
        if (String.isBlank(engineerName))  throw err('Engineer NAME did not reach the server (binding issue).');
        if (String.isBlank(engineerImage)) throw err('Engineer SIGNATURE image did not reach the server (capture issue).');
        if (customerUnavailable != true) {
            if (String.isBlank(customerName))  throw err('Customer NAME did not reach the server (binding issue).');
            if (String.isBlank(customerImage)) throw err('Customer SIGNATURE image did not reach the server (capture issue).');
        }

        // Re-running replaces prior signatures for this Work Order.
        delete [SELECT Id FROM Service_Signature__c WHERE Work_Order__c = :parentId];

        Service_Signature__c eng = new Service_Signature__c(
            Work_Order__c = parentId,
            Signer_Type__c = 'Engineer',
            Signer_Name__c = engineerName,
            Signed_At__c   = System.now()
        );

        Service_Signature__c cust = new Service_Signature__c(
            Work_Order__c = parentId,
            Signer_Type__c = 'Customer',
            Signed_At__c   = System.now()
        );
        if (customerUnavailable == true) {
            cust.Unavailable__c = true;
        } else {
            cust.Signer_Name__c = customerName;
        }

        insert new List<Service_Signature__c>{ eng, cust };

        List<Attachment> atts = new List<Attachment>();
        atts.add(buildAttachment(eng.Id, 'Engineer', engineerImage));
        if (customerUnavailable != true) {
            atts.add(buildAttachment(cust.Id, 'Customer', customerImage));
        }
        insert atts;
    }

    // ----- Step 2: render report to PDF and save as a File on the WO -----
    // preliminary == true  -> no signatures expected, file is prefixed "Prelim ".
    // preliminary == false -> normal final report.
    @AuraEnabled
    public static Id generateAndSaveReport(Id workOrderId, Boolean preliminary) {
        try {
            PageReference pdf = new PageReference(reportPageFor(workOrderId));
            pdf.getParameters().put('id', workOrderId);

            Blob body = Test.isRunningTest() ? Blob.valueOf('TEST-PDF')
                                             : pdf.getContentAsPDF();

            return saveReportVersion(workOrderId, body, preliminary == true);
        } catch (Exception e) {
            throw err('Report generation failed: ' + e.getMessage());
        }
    }

    // ----- Step 3: advance the Work Order (final reports only) -----
    // Called by the LWC only when the engineer did NOT check Preliminary.
    @AuraEnabled
    public static void markReadyForClose(Id workOrderId) {
        update new WorkOrder(Id = workOrderId, Status = STATUS_READY_FOR_CLOSE);
    }

    // ===================================================================
    //  Report variant routing (WorkType.Name + Make/Model)
    //  Break Fix  -> /apex/FSL_US_FSR        (current report; the default)
    //  PPM        -> /apex/FSL_US_PPM
    //  PPM+Trophon-> /apex/FSL_US_TROPHONPM (Make/Model contains "trophon", any case)
    // ===================================================================

    // Loads the fields that drive routing. ONE place to set the Make/Model field.
    private static WorkOrder loadRouting(Id woId) {
        return [
            SELECT WorkType.Name, Make_Model__c
            //                    ^^^^^^^^^^^^^ replace with your real Make/Model field API name.
            //   If Make/Model lives on a related record, use the path instead, e.g.
            //   Asset.Product2.Name or Asset.Name, and reference that below in modelOf().
            FROM WorkOrder WHERE Id = :woId LIMIT 1
        ];
    }

    private static String modelOf(WorkOrder w) {
        return w.Make_Model__c;   // <-- match the field/path used in loadRouting()
    }

    public static Boolean modelContainsTrophon(String makeModel) {
        return makeModel != null && makeModel.toLowerCase().contains('trophon');
    }

    // Used by the generator to pick which Visualforce page to render.
    public static String reportPageFor(Id woId) {
        WorkOrder w = loadRouting(woId);
        String wt = (w.WorkType != null) ? w.WorkType.Name : null;
        if (wt == 'PPM') {
            return modelContainsTrophon(modelOf(w)) ? '/apex/FSL_US_TROPHONPPM'
                                                     : '/apex/FSL_US_PPM';
        }
        return REPORT_PAGE; // Break Fix / anything else -> current report
    }

    // True when the Work Order's WorkType is PPM (incl. PPM+trophon).
    // Drives the "PMR" vs "FSR" file-name token.
    private static Boolean isPpm(WorkOrder w) {
        return w.WorkType != null && w.WorkType.Name == 'PPM';
    }

    // Page-side conditionals, in case you'd rather branch sections inside one page
    // (e.g. {!isTrophon}) instead of using separate pages.
    private WorkOrder routingCache;
    private WorkOrder routingWO() {
        if (routingCache == null) routingCache = loadRouting(workOrderId);
        return routingCache;
    }
    public Boolean getIsPpm() {
        WorkOrder w = routingWO();
        return w.WorkType != null && w.WorkType.Name == 'PPM';
    }
    public Boolean getIsTrophon() {
        return getIsPpm() && modelContainsTrophon(modelOf(routingWO()));
    }
    public Boolean getIsBreakFix() { return !getIsPpm(); }

    /**
     * Saves a report PDF as a File on the Work Order using the naming convention
     *   {Prelim }{FSR|PMR} - {WorkOrderNumber} - {Service Site Name} - {yyyy-MM-dd} - v{N}
     *
     *   - PPM Work Types name as "PMR"; everything else stays "FSR".
     *   - Preliminary reports get a leading "Prelim " and version on their own
     *     sequence (a Prelim file never bumps the final report's version, and
     *     vice-versa) because "Prelim " is part of the base name.
     *
     * Each generation is its own file; {N} increments per day for the Work Order
     * (first report of the day is v1, next v2, and so on). A new day starts again at
     * v1 because the date is part of the name. Existing version numbers are scanned so
     * a deleted file never causes a duplicate number.
     * Returns the ContentDocumentId.
     */
    public static Id saveReportVersion(Id workOrderId, Blob pdf) {
        // Back-compat for existing callers: a final, non-preliminary report.
        return saveReportVersion(workOrderId, pdf, false);
    }

    public static Id saveReportVersion(Id workOrderId, Blob pdf, Boolean preliminary) {
        WorkOrder wo = [
            SELECT WorkOrderNumber, Service_Site_Name__c, WorkType.Name
            FROM WorkOrder WHERE Id = :workOrderId LIMIT 1
        ];
        String woNum   = (wo.WorkOrderNumber != null) ? wo.WorkOrderNumber : String.valueOf(workOrderId);
        String site    = String.isNotBlank(wo.Service_Site_Name__c) ? wo.Service_Site_Name__c : 'Site';
        String docType = isPpm(wo) ? 'PMR' : 'FSR';
        String dateStr = Datetime.now().format('yyyy-MM-dd');

        // Stable identity — no date, no version. Stored on the custom field; matching
        // reads this, never the title.
        String matchKey = (preliminary == true ? 'Prelim ' : '')
                        + docType + '-' + woNum + '-' + site;

        // Locate the existing file by its stable key, and figure out the next version.
        Id existingDocId = null;
        Integer nextVer  = 1;
        List<ContentVersion> matches = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Report_Key__c = :matchKey AND IsLatest = true
            LIMIT 1
        ];
        if (!matches.isEmpty()) {
            existingDocId = matches[0].ContentDocumentId;
            nextVer = [SELECT COUNT() FROM ContentVersion WHERE ContentDocumentId = :existingDocId] + 1;
        }

        // Display title carries the date AND the version so the list shows it's updated.
        String title = matchKey + '-' + dateStr + ' v' + nextVer;

        ContentVersion cv = new ContentVersion(
            Title          = title,
            PathOnClient   = title + '.pdf',
            VersionData    = pdf,
            Report_Key__c  = matchKey      // set on EVERY version so IsLatest always carries it
        );
        if (existingDocId != null) {
            cv.ContentDocumentId = existingDocId;      // new native version on the SAME file
        } else {
            cv.FirstPublishLocationId = workOrderId;   // first time: new file linked to the WO
        }
        insert cv;

        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
    }

    private static Attachment buildAttachment(Id parentId, String label, String base64) {
        String raw = base64;
        if (raw != null && raw.contains(',')) raw = raw.substringAfter(',');
        return new Attachment(
            ParentId    = parentId,
            Name        = label + '_signature.png',
            ContentType = 'image/png',
            Body        = EncodingUtil.base64Decode(raw)
        );
    }

    // ----- Read model for the report (newest signature of each type wins) -----
    private List<SignatureView> getSignatureList() {
        if (sigCache != null) return sigCache;
        sigCache = new List<SignatureView>();
        for (Service_Signature__c s : [
                SELECT Signer_Type__c, Signer_Name__c, Signed_At__c, Unavailable__c,
                       (SELECT Id FROM Attachments ORDER BY CreatedDate DESC LIMIT 1)
                FROM Service_Signature__c
                WHERE Work_Order__c = :workOrderId
                ORDER BY CreatedDate DESC
        ]) {
            SignatureView v = new SignatureView();
            v.signerType   = s.Signer_Type__c;
            v.signerName   = s.Signer_Name__c;
            v.signedAt     = s.Signed_At__c;
            v.unavailable  = s.Unavailable__c;
            v.attachmentId = s.Attachments.isEmpty() ? null : s.Attachments[0].Id;
            sigCache.add(v);
        }
        return sigCache;
    }

    private SignatureView findSig(String signerType) {
        for (SignatureView v : getSignatureList()) {
            if (v.signerType == signerType) return v;
        }
        return null;
    }

    public SignatureView getEngineerSig() { return findSig('Engineer'); }
    public SignatureView getCustomerSig() { return findSig('Customer'); }
    public Boolean getEngineerSigPresent() { SignatureView v = getEngineerSig(); return v != null && v.attachmentId != null; }
    public Boolean getCustomerSigPresent() { SignatureView v = getCustomerSig(); return v != null && v.attachmentId != null; }
    public Boolean getCustomerSigUnavailable() { SignatureView v = getCustomerSig(); return v != null && v.unavailable == true; }

    public class SignatureView {
        public String   signerType   { get; set; }
        public String   signerName   { get; set; }
        public Datetime signedAt     { get; set; }
        public Boolean  unavailable  { get; set; }
        public Id       attachmentId { get; set; }

        // Date + time in the running user's timezone, e.g. "06/15/2026 2:34 PM".
        // Use {!engineerSig.signedAtText} / {!customerSig.signedAtText} in the page.
        public String signedAtText {
            get { return signedAt == null ? '' : signedAt.format('MM/dd/yyyy h:mm a'); }
        }
    }
}