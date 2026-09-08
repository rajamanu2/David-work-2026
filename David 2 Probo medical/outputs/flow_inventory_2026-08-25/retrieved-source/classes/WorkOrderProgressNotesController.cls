public class WorkOrderProgressNotesController {
    public WorkOrder wo { get; set; }
    public List<Progress_Note__c> progressNotes { get; set; }

    public WorkOrderProgressNotesController(ApexPages.StandardController controller) {
        wo = (WorkOrder)controller.getRecord();
        progressNotes = [
            SELECT Id, Name, Note__c, CreatedDate, CreatedBy.Name, Completed_Date_Time__c
            FROM Progress_Note__c
            WHERE Work_Order__c = :wo.Id
            ORDER BY Completed_Date_Time__c DESC
        ];
    }
}