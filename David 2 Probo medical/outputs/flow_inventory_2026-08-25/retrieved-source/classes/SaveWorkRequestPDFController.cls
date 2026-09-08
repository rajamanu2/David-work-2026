public with sharing class SaveWorkRequestPDFController {
    private final ProductTest__c productTest;
    public String statusMessage { get; set; }

    public SaveWorkRequestPDFController(ApexPages.StandardController controller) {
        this.productTest = (ProductTest__c)controller.getRecord();
    }

    public PageReference saveWorkRequestPDF() {
        insertPDF(productTest.Id, 'Work Request');

        return null;
    }
    
    public PageReference saveQCPDF() {
        insertPDF(productTest.Id, 'QC');

        return null;
    }
    
    public void insertPDF(Id productTestId, String pageOption) {
        try {
            // Reference your existing PDF-rendering page
            PageReference pdfPage;
            String title = '';
            // Format today's date as MM/DD/YYYY with zero-padding
            Date today = Date.today();
            String mm = (today.month() < 10 ? '0' : '') + String.valueOf(today.month());
            String dd = (today.day() < 10 ? '0' : '') + String.valueOf(today.day());
            String yyyy = String.valueOf(today.year());
            String formattedDate = mm + '/' + dd + '/' + yyyy;
            if(pageOption == 'Work Request'){
                title = 'Work Request - ' + formattedDate;
                pdfPage = Page.WorkRequestPDF;
            }
            else if(pageOption == 'QC'){
                title = 'QC Report - ' + formattedDate;
                pdfPage = Page.QCReportPDF;
            }
            
            pdfPage.getParameters().put('id', productTestId);

            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Dummy PDF Content');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }

            String fileName = title + '.pdf';
            // Step 1: Insert ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.Title = title;
            cv.PathOnClient = fileName;
            cv.VersionData = pdfBlob;
            cv.IsMajorVersion = true;
            insert cv;

            // Step 2: Query for the ContentDocumentId
            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

            // Step 3: Relate the file to the ProductTest__c record
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = productTestId;
            cdl.ShareType = 'V'; // View access
            cdl.Visibility = 'AllUsers';
            insert cdl;

            statusMessage = 'PDF file saved successfully to the record!';
        } catch (Exception e) {
            statusMessage = 'Error saving PDF: ' + e.getMessage();
        }
        
    }
}