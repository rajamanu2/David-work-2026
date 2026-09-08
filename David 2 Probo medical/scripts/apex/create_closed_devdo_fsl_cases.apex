Id salesforceCaseRecordTypeId = '0125b000000LWo1AAG';
Id currentUserId = UserInfo.getUserId();

List<Case> devCases = new List<Case>{
    new Case(
        RecordTypeId = salesforceCaseRecordTypeId,
        OwnerId = currentUserId,
        Assigned_To__c = currentUserId,
        Subject = '[DEVDO CLOSED - PROD 00008361] FSL calendar appointment delay',
        Status = 'Closed',
        Priority = 'High',
        Origin = 'Web',
        Classification__c = 'Other',
        Related_Object__c = 'Field Service Lightning',
        Description = 'Sandbox tracking case for Production case 00008361. When two appointments are assigned to the same engineer on the same day, a calendar Event could be delayed or missing.',
        Resolution_Notes__c = 'Completed in DevDO. The active Service Appointment Flow now creates a missing Event when an Assigned Resource exists. Focused regression test twoSameDayAppointmentsRecoverMissingCalendarEvents passed.'
    ),
    new Case(
        RecordTypeId = salesforceCaseRecordTypeId,
        OwnerId = currentUserId,
        Assigned_To__c = currentUserId,
        Subject = '[DEVDO CLOSED - PROD 00009312] Service Appointment details in FSL',
        Status = 'Closed',
        Priority = 'High',
        Origin = 'Web',
        Classification__c = 'Salesforce Improvement',
        Related_Object__c = 'Field Service Lightning',
        Description = 'Sandbox tracking case for Production case 00009312. The technician appointment view needed to show the Service Appointment number, subject, and description instead of relying only on Work Order details.',
        Resolution_Notes__c = 'Completed in DevDO. The Apex DTO and FSL LWCs now expose and display the Service Appointment number, subject, and description with Work Order fallback behavior. Focused DTO mapping test passed.'
    ),
    new Case(
        RecordTypeId = salesforceCaseRecordTypeId,
        OwnerId = currentUserId,
        Assigned_To__c = currentUserId,
        Subject = '[DEVDO CLOSED - PROD 00009704] Completed Work Order reopened by RMA',
        Status = 'Closed',
        Priority = 'High',
        Origin = 'Web',
        Classification__c = 'Salesforce Error',
        Related_Object__c = 'Work Order',
        SFDC_Object_of_Issue__c = 'Work Order',
        Error_Type__c = 'Flow Error',
        Error_Message__c = 'A completed Work Order was reopened when the related RMA received date was processed.',
        Description = 'Sandbox tracking case for Production case 00009704. Completed Work Orders must remain completed when a related RMA is received.',
        Resolution_Notes__c = 'Completed in DevDO. RMA processing now uses a shared Flow that updates the received date while preserving completed Work Orders; open Work Orders still move to In Progress. Both regression paths passed.'
    ),
    new Case(
        RecordTypeId = salesforceCaseRecordTypeId,
        OwnerId = currentUserId,
        Assigned_To__c = currentUserId,
        Subject = '[DEVDO CLOSED - PROD 00010409] New Service Appointment button',
        Status = 'Closed',
        Priority = 'High',
        Origin = 'Web',
        Classification__c = 'Salesforce Improvement',
        Related_Object__c = 'Work Order',
        SFDC_Object_of_Issue__c = 'Work Order',
        Description = 'Sandbox tracking case for Production case 00010409. Users needed a Work Order action that opens a Service Appointment screen with Work Order information prepopulated.',
        Resolution_Notes__c = 'Completed in DevDO. The active screen Flow, Work Order quick action, applicable layouts, and active Lightning page dynamic action were implemented. Live UI verification confirmed the action and prepopulated values.'
    )
};

insert devCases;

for (Case createdCase : [
    SELECT Id, CaseNumber, Subject, Status, IsClosed
    FROM Case
    WHERE Id IN :devCases
    ORDER BY Subject
]) {
    System.debug(LoggingLevel.ERROR,
        'CREATED_DEVDO_CASE|' + createdCase.CaseNumber + '|' + createdCase.Id + '|' +
        createdCase.Status + '|' + createdCase.IsClosed + '|' + createdCase.Subject
    );
}
