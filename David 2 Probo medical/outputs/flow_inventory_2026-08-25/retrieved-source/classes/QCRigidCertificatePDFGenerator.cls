public class QCRigidCertificatePDFGenerator {

    // Expose the method to be called from a Flow
    @InvocableMethod(label='Generate and Save QCRigid Certificate PDF' description='Generates and saves a QC Rigid Certificate PDF to a ProductTest record')
    public static void generateAndSavePDF(List<Id> productTestIds) {
        // Loop through the list of ProductTest IDs (Flow will pass a list of IDs)
        for (Id productTestId : productTestIds) {
            // Create a PageReference for the QCRigidCertificatePDF Visualforce page
            PageReference pdfPage = Page.QCRigidCertificatePDF;
            
            // Pass the ProductTest record ID to the page
            pdfPage.getParameters().put('id', productTestId);

            // Get the content of the Visualforce page as PDF
            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Mock PDF Content');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }

            // Get the current date
            Date today = Date.today();

            // Manually format the date as MM/dd/yyyy
            String month = (today.month() < 10) ? '0' + String.valueOf(today.month()) : String.valueOf(today.month());
            String day = (today.day() < 10) ? '0' + String.valueOf(today.day()) : String.valueOf(today.day());
            String year = String.valueOf(today.year());

            // Combine into MM/dd/yyyy format
            String formattedDate = month + '/' + day + '/' + year;

            // Create a ContentVersion record to store the PDF file with dynamic title
            ContentVersion cv = new ContentVersion();
            cv.Title = 'QA Certificate - ' + formattedDate;
            cv.PathOnClient = 'QA_Certificate_' + formattedDate + '.pdf';
            cv.VersionData = pdfBlob;
            cv.FirstPublishLocationId = productTestId;  // Link to the ProductTest__c record
            insert cv;

            // Query the ContentDocument to get the ContentDocumentId
            ContentDocument contentDoc = [SELECT Id FROM ContentDocument WHERE Id IN 
                                          (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id) LIMIT 1];

            // Check if the ContentDocument is already linked to the ProductTest record
            Integer existingLinkCount = [SELECT COUNT() FROM ContentDocumentLink 
                                         WHERE ContentDocumentId = :contentDoc.Id AND LinkedEntityId = :productTestId];

            // Only create the link if it does not already exist
            if (existingLinkCount == 0) {
                ContentDocumentLink link = new ContentDocumentLink();
                link.ContentDocumentId = contentDoc.Id;
                link.LinkedEntityId = productTestId;  // Link to the ProductTest__c record
                link.ShareType = 'V';  // Visible to the entity
                insert link;
            }
        }
    }
}