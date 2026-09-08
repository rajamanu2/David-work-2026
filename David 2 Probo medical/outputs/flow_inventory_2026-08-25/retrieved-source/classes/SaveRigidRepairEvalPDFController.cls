public with sharing class SaveRigidRepairEvalPDFController {
    private final ProductTest__c productTest;
    public String statusMessage { get; set; }

    public SaveRigidRepairEvalPDFController(ApexPages.StandardController controller) {
        this.productTest = (ProductTest__c)controller.getRecord();
    }

    public PageReference savePDF() {
        try {
            // Use the Rigid-specific PDF rendering page
            PageReference pdfPage = Page.RigidRepairEvaluationPDF;
            pdfPage.getParameters().put('id', productTest.Id);

            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Dummy PDF Content');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }

            // Format today's date as MM/DD/YYYY
            Date today = Date.today();
            String mm = (today.month() < 10 ? '0' : '') + String.valueOf(today.month());
            String dd = (today.day() < 10 ? '0' : '') + String.valueOf(today.day());
            String yyyy = String.valueOf(today.year());
            String formattedDate = mm + '/' + dd + '/' + yyyy;

            String fileName = 'Rigid Repair Evaluation - ' + formattedDate + '.pdf';

            // Step 1: Create ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Rigid Repair Evaluation - ' + formattedDate;
            cv.PathOnClient = fileName;
            cv.VersionData = pdfBlob;
            cv.IsMajorVersion = true;
            insert cv;

            // Step 2: Retrieve ContentDocumentId
            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

            // Step 3: Link file to ProductTest__c record
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = productTest.Id;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;

            statusMessage = 'PDF file saved successfully to the record!';
        } catch (Exception e) {
            statusMessage = 'Error saving PDF: ' + e.getMessage();
        }

        return null;
    }
}