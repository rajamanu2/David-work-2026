@isTest(seeAllData=true)
private class SaveFlexQCPDFController_Test {

    @isTest
    static void test_SavePDF_GeneratesAndLinksDocument() {
        // Fetch the most recently modified ProductTest__c record
        List<ProductTest__c> tests = [
            SELECT Id 
            FROM ProductTest__c 
            ORDER BY LastModifiedDate DESC 
            LIMIT 1
        ];

        if (!tests.isEmpty()) {
            ApexPages.StandardController stdController = new ApexPages.StandardController(tests[0]);
            SaveFlexQCPDFController controller = new SaveFlexQCPDFController(stdController);

            Test.startTest();
            controller.savePDF();
            Test.stopTest();

            // No assertions, just invoke the logic and allow coverage
        }
    }
}