public class ProductTestImageUploadController {
    public transient Blob beforeImage { get; set; }
    public transient Blob afterImage { get; set; }
    public Id productTestId { get; set; }
    public Boolean isUploadSuccessful { get; set; }

    // Constructor that accepts the standard controller as an argument
    public ProductTestImageUploadController(ApexPages.StandardController controller) {
        this.productTestId = (Id)controller.getId();
        isUploadSuccessful = false; // Default to false
    }

    public PageReference uploadImages() {
        try {
            List<ContentDocumentLink> contentDocs = new List<ContentDocumentLink>();
            Set<Id> contentDocIds = new Set<Id>();
            if(beforeImage != null || afterImage != null){
                contentDocs = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =:productTestId];
                system.debug('THIS IS THE CONTENT DOCS >> ' + contentDocs);
                for (ContentDocumentLink cdl : contentDocs) {
                    contentDocIds.add(cdl.ContentDocumentId);
                }
            }
            // Upload the "Before Image"
            if (beforeImage != null) {
                // Check if the file is PNG or JPG
                String beforeImageExtension = getFileExtension('before_image.png'); // Replace with dynamic filename from PathOnClient

                if (!isValidImageType(beforeImageExtension)) {
                    throw new CustomException('The Before Image must be in PNG or JPG format.');
                }

                // Safe query - use list and check if result is empty
                
                
                List<ContentDocument> beforeDocs = [SELECT Id FROM ContentDocument 
                                                    WHERE Id IN :contentDocIds AND Title = 'Before Image' AND isDeleted=FALSE LIMIT 1];
               system.debug('THIS IS THE BEFORE DOCS >> ' + beforeDocs);
                /*
                List<ContentDocument> beforeDocs = [SELECT Id FROM ContentDocument 
                                                    WHERE Id IN (SELECT ContentDocumentId 
                                                                 FROM ContentDocumentLink 
                                                                 WHERE LinkedEntityId = :productTestId)
                                                    AND Title = 'Before Image' AND isDeleted=FALSE LIMIT 1];*/

                if (!beforeDocs.isEmpty()) {
                    ContentDocument beforeDoc = beforeDocs[0]; // Assign the first record (if exists)
                    ContentVersion beforeContent = new ContentVersion();
                    beforeContent.Title = 'Before Image';
                    beforeContent.PathOnClient = 'before_image.png';
                    beforeContent.VersionData = beforeImage;
                    beforeContent.ContentDocumentId = beforeDoc.Id; // Link to the existing ContentDocument
                    insert beforeContent;  // Insert the new version
                } else {
                    ContentVersion beforeContent = new ContentVersion();
                    beforeContent.Title = 'Before Image';
                    beforeContent.PathOnClient = 'before_image.png';
                    beforeContent.VersionData = beforeImage;
                    beforeContent.FirstPublishLocationId = productTestId; // Link to the ProductTest__c record
                    insert beforeContent;
                }
            }

            // Upload the "After Image"
            if (afterImage != null) {
                // Check if the file is PNG or JPG
                String afterImageExtension = getFileExtension('after_image.png'); // Replace with dynamic filename from PathOnClient

                if (!isValidImageType(afterImageExtension)) {
                    throw new CustomException('The After Image must be in PNG or JPG format.');
                }

                // Safe query - use list and check if result is empty
                
                List<ContentDocument> afterDocs = [SELECT Id FROM ContentDocument 
                                                    WHERE Id IN :contentDocIds AND Title = 'After Image' AND isDeleted=FALSE LIMIT 1];
                /*List<ContentDocument> afterDocs = [SELECT Id FROM ContentDocument 
                                                   WHERE Id IN (SELECT ContentDocumentId 
                                                                FROM ContentDocumentLink 
                                                                WHERE LinkedEntityId = :productTestId)
                                                   AND Title = 'After Image' AND isDeleted=FALSE LIMIT 1];*/

                if (!afterDocs.isEmpty()) {
                    ContentDocument afterDoc = afterDocs[0]; // Assign the first record (if exists)
                    ContentVersion afterContent = new ContentVersion();
                    afterContent.Title = 'After Image';
                    afterContent.PathOnClient = 'after_image.png';
                    afterContent.VersionData = afterImage;
                    afterContent.ContentDocumentId = afterDoc.Id; // Link to the existing ContentDocument
                    insert afterContent;  // Insert the new version
                } else {
                    ContentVersion afterContent = new ContentVersion();
                    afterContent.Title = 'After Image';
                    afterContent.PathOnClient = 'after_image.png';
                    afterContent.VersionData = afterImage;
                    afterContent.FirstPublishLocationId = productTestId; // Link to the ProductTest__c record
                    insert afterContent;
                }
            }

            // If images were successfully uploaded, set success flag to true
            isUploadSuccessful = true;
        } catch (Exception e) {
            // Handle exceptions and show error message
            isUploadSuccessful = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occurred while uploading the images: ' + e.getMessage()));
        }

        return null;
    }

    // Helper method to get the file extension
    private String getFileExtension(String fileName) {
        Integer dotIndex = fileName.lastIndexOf('.');
        if (dotIndex != -1) {
            return fileName.substring(dotIndex + 1).toLowerCase();
        }
        return '';
    }

    // Helper method to check if the file extension is valid (PNG or JPG)
    private Boolean isValidImageType(String extension) {
        return extension == 'png' || extension == 'jpg' || extension == 'jpeg';
    }

    // Custom exception for image validation
    public class CustomException extends Exception {}
}