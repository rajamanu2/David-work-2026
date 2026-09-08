@isTest(seeAllData=true)
public class RigidRepairEvalController_Test {

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
        RigidWorkRequestController controller = new RigidWorkRequestController(stdController);

        // Invoke public methods
        Test.stopTest();
    }
}