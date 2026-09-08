@isTest(seeAllData=true)
private class ProductTestImageUploadController_Test {

    @isTest
    static void test_uploadImages_basicSuccess() {
        List<ProductTest__c> tests = [
            SELECT Id 
            FROM ProductTest__c 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];

        if (!tests.isEmpty()) {
            ProductTest__c pt = tests[0];
            ApexPages.StandardController sc = new ApexPages.StandardController(pt);
            ProductTestImageUploadController controller = new ProductTestImageUploadController(sc);

            // Use at least 10KB of Blob data to simulate real image
            controller.beforeImage = Blob.valueOf('x'.repeat(10240));
            controller.afterImage = Blob.valueOf('y'.repeat(10240));

            Test.startTest();
            controller.uploadImages();
            Test.stopTest();
        }
    }

    @isTest
    static void test_uploadImages_existingBeforeDoc() {
        List<ProductTest__c> tests = [
            SELECT Id 
            FROM ProductTest__c 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
    
        if (!tests.isEmpty()) {
            ProductTest__c pt = tests[0];
            Blob validBlob = Blob.valueOf('z'.repeat(10240));
    
            // Insert original "Before Image"
            ContentVersion cv = new ContentVersion(
                Title = 'Before Image',
                PathOnClient = 'before_image.png',
                VersionData = validBlob,
                FirstPublishLocationId = pt.Id
            );
            insert cv;
    
            // Query it back so we have ContentDocumentId
            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
            
            // Insert original "After Image"
            ContentVersion cv2 = new ContentVersion(
                Title = 'After Image',
                PathOnClient = 'after_image.png',
                VersionData = validBlob,
                FirstPublishLocationId = pt.Id
            );
            insert cv2;
    
            // Query it back so we have ContentDocumentId
            cv2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id LIMIT 1];
    
            // No manual ContentDocumentLink insert needed
    
            ApexPages.StandardController sc = new ApexPages.StandardController(pt);
            ProductTestImageUploadController controller = new ProductTestImageUploadController(sc);
            controller.beforeImage = validBlob;
            controller.afterImage = validBlob;
    
            Test.startTest();
            controller.uploadImages();
            Test.stopTest();
        }
    }

}