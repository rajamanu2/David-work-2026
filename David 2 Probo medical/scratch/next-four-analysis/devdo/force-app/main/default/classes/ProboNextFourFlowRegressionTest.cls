@IsTest
private class ProboNextFourFlowRegressionTest {

    private static Account createAccount(String accountName) {
        Account accountRecord = TestDataFactory.createAccount(false);
        accountRecord.Name = accountName;
        insert accountRecord;
        return accountRecord;
    }

    private static Opportunity createOpportunity(Account accountRecord) {
        return TestDataFactory.createOpportunity(
            'Probe Sales Opportunity', accountRecord.Id, true
        );
    }

    private static WorkOrder createWorkOrder(
        Account accountRecord,
        Opportunity opportunityRecord,
        Id serviceContractId
    ) {
        opportunityRecord = [
            SELECT Id, Pricebook2Id
            FROM Opportunity
            WHERE Id = :opportunityRecord.Id
        ];
        WorkOrder workOrderRecord = new WorkOrder(
            Subject = 'Case regression Work Order',
            Status = 'New',
            Country = 'United States',
            AccountId = accountRecord.Id,
            Opportunity__c = opportunityRecord.Id,
            Pricebook2Id = opportunityRecord.Pricebook2Id,
            ServiceContractId = serviceContractId
        );
        insert workOrderRecord;
        return workOrderRecord;
    }

    @IsTest
    static void case00009589DispatchedAppointmentDoesNotReturnToInternal() {
        Account accountRecord = createAccount('Case 00009589 Account');
        Opportunity opportunityRecord = createOpportunity(accountRecord);
        WorkOrder workOrderRecord = createWorkOrder(accountRecord, opportunityRecord, null);
        ServiceAppointment appointment = new ServiceAppointment(
            Subject = 'Case 00009589 Dispatched Appointment',
            Status = 'Dispatched',
            ParentRecordId = workOrderRecord.Id,
            Work_Order__c = workOrderRecord.Id,
            Duration = 60,
            DurationType = 'Minutes'
        );
        insert appointment;

        Test.startTest();
        insert new Sourcing_Request_Item__c(
            Requesting_Opportunity__c = opportunityRecord.Id,
            Requesting_Work_Order__c = workOrderRecord.Id,
            Service_Appointment__c = appointment.Id
        );
        Test.stopTest();

        ServiceAppointment appointmentAfter = [
            SELECT Status
            FROM ServiceAppointment
            WHERE Id = :appointment.Id
        ];
        System.assertEquals('Dispatched', appointmentAfter.Status,
            'Case 00009589: creating or completing an SRI must not regress an active appointment to Internal.');
    }

    @IsTest
    static void case00010514CreatesOneConfiguredCoreExchangeRma() {
        Core_Exchange_Automation_Rule__mdt automationRule = [
            SELECT Account_Name__c, RMA_Record_Type_Developer_Name__c
            FROM Core_Exchange_Automation_Rule__mdt
            WHERE Active__c = true
            LIMIT 1
        ];
        Account accountRecord = createAccount(automationRule.Account_Name__c);
        Opportunity opportunityRecord = createOpportunity(accountRecord);
        ServiceContract serviceContractRecord = new ServiceContract(
            Name = 'Case 00010514 GE Contract',
            AccountId = accountRecord.Id,
            StartDate = Date.today()
        );
        insert serviceContractRecord;

        Test.startTest();
        WorkOrder workOrderRecord = createWorkOrder(
            accountRecord, opportunityRecord, serviceContractRecord.Id
        );
        workOrderRecord.Subject = 'Case 00010514 GE Work Order updated';
        update workOrderRecord;
        Test.stopTest();

        List<RMA__c> createdRmas = [
            SELECT Id, RecordType.DeveloperName, Work_Order__c, Opportunity__c,
                   Service_Contract__c, Account_Name__c
            FROM RMA__c
            WHERE Work_Order__c = :workOrderRecord.Id
            AND RecordType.DeveloperName = :automationRule.RMA_Record_Type_Developer_Name__c
        ];
        System.assertEquals(1, createdRmas.size(),
            'Case 00010514: exactly one Core Exchange RMA must be created per GE Work Order.');
        System.assertEquals(opportunityRecord.Id, createdRmas[0].Opportunity__c);
        System.assertEquals(serviceContractRecord.Id, createdRmas[0].Service_Contract__c);
        System.assertEquals(automationRule.Account_Name__c, createdRmas[0].Account_Name__c);
    }
}
