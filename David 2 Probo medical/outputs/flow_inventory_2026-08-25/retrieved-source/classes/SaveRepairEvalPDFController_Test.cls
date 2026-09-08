@isTest(seeAllData=true)
private class SaveRepairEvalPDFController_Test {

    @isTest
    static void test_SavePDF_WithExistingProductTest() {
        List<ProductTest__c> records = [
            SELECT Id 
            FROM ProductTest__c 
            ORDER BY LastModifiedDate DESC 
            LIMIT 1
        ];

        if (!records.isEmpty()) {
            ApexPages.StandardController stdController = new ApexPages.StandardController(records[0]);
            SaveRepairEvalPDFController controller = new SaveRepairEvalPDFController(stdController);

            Test.startTest();
            controller.savePDF();
            Test.stopTest();
        }
    }
}