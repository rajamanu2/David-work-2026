// APXC
public with sharing class SaveCreditMemoPdfFileAction {

    public class Request {
        @InvocableVariable(required=true) public Id recordId;              // Credit_Memo__c Id
        @InvocableVariable public String fileTitle;                        // Optional custom title (without .pdf)
        @InvocableVariable public Id publishLocationId;                    // Optional record to publish file to immediately (e.g., Credit Memo, Invoice, Account)
    }

    public class Result {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
        @InvocableVariable public Id contentDocumentId;
        @InvocableVariable public Id contentVersionId;
        @InvocableVariable public String vfPageName;
        @InvocableVariable public String fileTitle;
        @InvocableVariable public String fileName;
        @InvocableVariable public Boolean isUk;
    }

    @InvocableMethod(
        label='Save Credit Memo PDF File'
        description='Renders the Credit Memo VF page as PDF (US or UK variant) and saves it as a File. Returns ContentDocumentId for later linking.'
    )
    public static List<Result> save(List<Request> requests) {
        List<Result> out = new List<Result>();
        if (requests == null || requests.isEmpty()) return out;

        Set<Id> cmIds = new Set<Id>();
        for (Request r : requests) {
            if (r != null && r.recordId != null) cmIds.add(r.recordId);
        }
        if (cmIds.isEmpty()) return out;

        // Pull the Credit Memo + Invoice fields needed to decide US vs UK
        Map<Id, Credit_Memo__c> cmById = new Map<Id, Credit_Memo__c>([
            SELECT
                Id,
                Name,
                Invoice__c,
                Invoice__r.Name,
                Invoice_Entity_Location__c
            FROM Credit_Memo__c
            WHERE Id IN :cmIds
        ]);

        for (Request req : requests) {
            Result res = new Result();
            out.add(res);

            try {
                if (req == null) throw new AuraHandledException('Request was null.');
                if (req.recordId == null) throw new AuraHandledException('recordId is required.');

                Credit_Memo__c cm = cmById.get(req.recordId);
                if (cm == null) throw new AuraHandledException('Credit Memo not found: ' + String.valueOf(req.recordId));

                // Decide UK vs US
                String loc = (cm.Invoice__c != null) ? cm.Invoice_Entity_Location__c : null;
                Boolean isUk = isUkInvoiceLocation(loc);
                String vfPageName = isUk ? 'Credit_Memo_UK_PDF' : 'Credit_Memo_PDF';

                // Determine file title and name
                String defaultTitle = buildDefaultTitle(cm, isUk);
                String title = String.isBlank(req.fileTitle) ? defaultTitle : req.fileTitle.trim();
                String fileName = title + '.pdf';

                // Build VF page reference
                PageReference pr = new PageReference('/apex/' + vfPageName);
                pr.getParameters().put('id', cm.Id);

                // Render as PDF
                Blob pdfBlob;
                if (Test.isRunningTest()) {
                    pdfBlob = Blob.valueOf('PDF TEST CONTENT');
                } else {
                    pdfBlob = pr.getContentAsPDF();
                }

                // Create ContentVersion
                ContentVersion cv = new ContentVersion(
                    Title = title,
                    PathOnClient = fileName,
                    VersionData = pdfBlob
                );

                // Publish immediately if requested
                if (req.publishLocationId != null) {
                    cv.FirstPublishLocationId = req.publishLocationId;
                }

                insert cv;

                // Retrieve ContentDocumentId
                cv = [
                    SELECT Id, ContentDocumentId
                    FROM ContentVersion
                    WHERE Id = :cv.Id
                    LIMIT 1
                ];

                res.success = true;
                res.message = 'PDF saved successfully.';
                res.contentDocumentId = cv.ContentDocumentId;
                res.contentVersionId = cv.Id;
                res.vfPageName = vfPageName;
                res.fileTitle = title;
                res.fileName = fileName;
                res.isUk = isUk;

            } catch (Exception e) {
                res.success = false;
                res.message = 'Error: ' + e.getMessage();
            }
        }

        return out;
    }

    /**
     * UK if Invoice_Entity_Location__c begins with 1400 or 1500.
     */
    private static Boolean isUkInvoiceLocation(String invoiceEntityLocation) {
        if (String.isBlank(invoiceEntityLocation)) return false;
        String v = invoiceEntityLocation.trim();
        return v.startsWith('1400') || v.startsWith('1500');
    }

    /**
     * Helper to create a safe and descriptive filename.
     */
    private static String buildDefaultTitle(Credit_Memo__c cm, Boolean isUk) {
        String cmNum = String.isBlank(cm.Name) ? 'CreditMemo' : 'CreditMemo_' + cm.Name;

        String inv = 'Invoice';
        if (cm.Invoice__r != null && !String.isBlank(cm.Invoice__r.Name)) {
            inv = 'Invoice_' + cm.Invoice__r.Name;
        }

        String region = isUk ? 'UK' : 'US';

        // Safe timestamp format for filenames: 20251017
        String d = DateTime.now().format('yyyyMMdd', 'GMT');

        return cmNum + '_' + inv + '_' + region + '_' + d;
    }
}