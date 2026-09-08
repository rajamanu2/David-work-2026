@isTest(seeAllData=true)
private class FlexQCReportController2_Test {

    @isTest
    static void test_ControllerConstructorAndGetters() {
        // Retrieve the most recently modified ProductTest__c record
        List<ProductTest__c> tests = [
            SELECT Id 
            FROM ProductTest__c 
            ORDER BY LastModifiedDate DESC 
            LIMIT 1
        ];

        if (!tests.isEmpty()) {
            ApexPages.StandardController stdController = new ApexPages.StandardController(tests[0]);

            Test.startTest();
            FlexQCReportController2 controller = new FlexQCReportController2(stdController);
            controller.getItems();
            controller.getInspectionResults();
            controller.getActions();
            controller.getQcPassed();
            Test.stopTest();
        }
    }

    @isTest
    static void test_SaveAsPDFMethod() {
        // Retrieve the most recently modified ProductTest__c record
        List<ProductTest__c> tests = [
            SELECT Id 
            FROM ProductTest__c 
            ORDER BY LastModifiedDate DESC 
            LIMIT 1
        ];

        if (!tests.isEmpty()) {
            ApexPages.StandardController stdController = new ApexPages.StandardController(tests[0]);
            FlexQCReportController2 controller = new FlexQCReportController2(stdController);

            Test.startTest();
            controller.saveAsPDF();
            Test.stopTest();
        }
    }
}