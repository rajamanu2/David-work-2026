public with sharing class SaveFlexQCPDFController {
    private final ProductTest__c productTest;
    public String statusMessage { get; set; }

    public SaveFlexQCPDFController(ApexPages.StandardController controller) {
        this.productTest = (ProductTest__c)controller.getRecord();
    }

    public PageReference savePDF() {
        try {
            PageReference pdfPage = Page.FlexQCReportPDF;
            pdfPage.getParameters().put('id', productTest.Id);

            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Dummy PDF Content');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }

            Date today = Date.today();
            String mm = (today.month() < 10 ? '0' : '') + String.valueOf(today.month());
            String dd = (today.day() < 10 ? '0' : '') + String.valueOf(today.day());
            String yyyy = String.valueOf(today.year());
            String formattedDate = mm + '/' + dd + '/' + yyyy;

            ContentVersion cv = new ContentVersion();
            cv.Title = 'Flex QC Report - ' + formattedDate;
            cv.PathOnClient = 'FlexQCReport.pdf';
            cv.VersionData = pdfBlob;
            cv.IsMajorVersion = true;
            insert cv;

            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

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