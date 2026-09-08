@isTest
public class WorkOrderProgressNotesControllerTest {
    @isTest
    static void testControllerWithProgressNotes() {
        // Create a test user to simulate CreatedBy
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'Standard User' LIMIT 1];

        // Create a test WorkOrder
        WorkOrder testWO = new WorkOrder(
            Status = 'New',
            Subject = 'Test Work Order'
        );
        insert testWO;

        // Create related Progress Notes
        List<Progress_Note__c> notes = new List<Progress_Note__c>();
        for (Integer i = 1; i <= 3; i++) {
            notes.add(new Progress_Note__c(
                Work_Order__c = testWO.Id,
                Note__c = 'This is test note #' + i
            ));
        }
        insert notes;

        // Instantiate StandardController with the test WorkOrder
        ApexPages.StandardController stdController = new ApexPages.StandardController(testWO);

        // Instantiate the extension
        WorkOrderProgressNotesController controller = new WorkOrderProgressNotesController(stdController);
    }
}