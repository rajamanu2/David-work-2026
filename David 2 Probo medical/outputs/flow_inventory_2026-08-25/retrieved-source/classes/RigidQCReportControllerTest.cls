@isTest(seeAllData=true)
private class RigidQCReportControllerTest {

    @isTest
    static void testWithExistingProductTest() {
        // Get an existing ProductTest__c record from the org
        ProductTest__c existingTest = [
            SELECT Id FROM ProductTest__c LIMIT 1
        ];
        
        existingTest.Tube_Length__c = 10;
        existingTest.Marker_Plate__c = 'Repair';
		update existingTest;

        // Initialize the controller with the record
        ApexPages.StandardController stdController = new ApexPages.StandardController(existingTest);
        Test.startTest();
        RigidQCReportController controller = new RigidQCReportController(stdController);

        // Invoke public methods
        controller.getItems();
        controller.getInspectionResults();
        controller.getActions();
        controller.getQcPassed();
        Test.stopTest();
    }
}