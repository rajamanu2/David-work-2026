@IsTest(SeeAllData=true)
private class ProboFslCaseRegressionTest {
    private class FslContext {
        User technician;
        ServiceResource resource;
        ServiceTerritory territory;
    }

    private static FslContext createFslContext() {
        String uniqueSuffix = String.valueOf(Datetime.now().getTime());
        Profile profileRecord = [SELECT Id FROM Profile LIMIT 1];

        User technician = new User(
            ProfileId = profileRecord.Id,
            LastName = 'Regression Technician',
            Alias = 'regtech',
            Email = 'regtech' + uniqueSuffix + '@example.com',
            Username = 'regtech' + uniqueSuffix + '@example.com',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert technician;

        OperatingHours operatingHours;
        List<OperatingHours> configuredHours = [SELECT Id FROM OperatingHours LIMIT 1];
        if (configuredHours.isEmpty()) {
            operatingHours = new OperatingHours(
                Name = 'Regression Hours ' + uniqueSuffix,
                TimeZone = 'America/New_York'
            );
            insert operatingHours;
        } else {
            operatingHours = configuredHours[0];
        }

        ServiceTerritory territory = new ServiceTerritory(
            Name = 'Regression Territory ' + uniqueSuffix,
            IsActive = true,
            OperatingHoursId = operatingHours.Id
        );
        insert territory;

        ServiceResource resource = new ServiceResource(
            Name = 'Regression Resource ' + uniqueSuffix,
            IsActive = true,
            RelatedRecordId = technician.Id
        );
        insert resource;

        insert new ServiceTerritoryMember(
            ServiceTerritoryId = territory.Id,
            ServiceResourceId = resource.Id,
            EffectiveStartDate = Date.today().addDays(-1)
        );

        FslContext context = new FslContext();
        context.technician = technician;
        context.resource = resource;
        context.territory = territory;
        return context;
    }

    @IsTest
    static void twoSameDayAppointmentsRecoverMissingCalendarEvents() {
        FslContext context = createFslContext();
        Account accountRecord = new Account(Name = 'Calendar Regression Account');
        insert accountRecord;
        Contact contactRecord = new Contact(
            FirstName = 'Calendar',
            LastName = 'Regression',
            AccountId = accountRecord.Id
        );
        insert contactRecord;

        WorkOrder workOrderRecord = new WorkOrder(
            Subject = 'Calendar Regression Work Order',
            Status = 'New',
            AccountId = accountRecord.Id,
            ServiceTerritoryId = context.territory.Id,
            Street = '100 Test Street',
            City = 'Tampa',
            State = 'Florida',
            PostalCode = '33601',
            Country = 'United States'
        );
        insert workOrderRecord;

        Datetime firstStart = Datetime.newInstance(Date.today().addDays(2), Time.newInstance(9, 0, 0, 0));
        Datetime secondStart = firstStart.addHours(3);
        List<ServiceAppointment> appointments = new List<ServiceAppointment>{
            new ServiceAppointment(
                Subject = 'First same-day appointment',
                Description = 'First Service Appointment details',
                Status = 'New',
                ServiceTerritoryId = context.territory.Id,
                ParentRecordId = workOrderRecord.Id,
                Work_Order__c = workOrderRecord.Id,
                ContactId = contactRecord.Id,
                Appointment_Type__c = 'Site Visit',
                Duration = 60,
                DurationType = 'Minutes',
                City = 'Tampa'
            ),
            new ServiceAppointment(
                Subject = 'Second same-day appointment',
                Description = 'Second Service Appointment details',
                Status = 'New',
                ServiceTerritoryId = context.territory.Id,
                ParentRecordId = workOrderRecord.Id,
                Work_Order__c = workOrderRecord.Id,
                ContactId = contactRecord.Id,
                Appointment_Type__c = 'Site Visit',
                Duration = 60,
                DurationType = 'Minutes',
                City = 'Tampa'
            )
        };
        insert appointments;

        appointments[0].SchedStartTime = firstStart;
        appointments[0].SchedEndTime = firstStart.addHours(1);
        appointments[1].SchedStartTime = secondStart;
        appointments[1].SchedEndTime = secondStart.addHours(1);
        update appointments;

        insert new List<AssignedResource>{
            new AssignedResource(
                ServiceAppointmentId = appointments[0].Id,
                ServiceResourceId = context.resource.Id
            ),
            new AssignedResource(
                ServiceAppointmentId = appointments[1].Id,
                ServiceResourceId = context.resource.Id
            )
        };

        delete [SELECT Id FROM Event WHERE WhatId IN :appointments];

        appointments = [
            SELECT Id, Service_Resource__c, SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            WHERE Id IN :appointments
            ORDER BY SchedStartTime
        ];
        appointments[0].Service_Resource__c = context.resource.Name;
        appointments[0].SchedStartTime = appointments[0].SchedStartTime.addMinutes(5);
        appointments[0].SchedEndTime = appointments[0].SchedEndTime.addMinutes(5);
        appointments[1].Service_Resource__c = context.resource.Name;
        appointments[1].SchedStartTime = appointments[1].SchedStartTime.addMinutes(5);
        appointments[1].SchedEndTime = appointments[1].SchedEndTime.addMinutes(5);

        Test.startTest();
        update appointments;
        Test.stopTest();

        List<Event> recoveredEvents = [
            SELECT Id, WhatId, OwnerId, StartDateTime, Subject, Type
            FROM Event
            WHERE WhatId IN :appointments
            AND Type = 'Service Event'
        ];
        System.assertEquals(2, recoveredEvents.size(),
            'Each same-day appointment must have its own recovered calendar Event.');
        System.assertEquals(
            new Set<Id>{ appointments[0].Id, appointments[1].Id },
            new Set<Id>{ recoveredEvents[0].WhatId, recoveredEvents[1].WhatId },
            'Recovered Events must be keyed independently by Service Appointment.');
        for (Event recoveredEvent : recoveredEvents) {
            System.assertEquals(context.technician.Id, recoveredEvent.OwnerId,
                'Recovered Event must belong to the assigned technician.');
        }
    }

    @IsTest
    static void completedWorkOrderIsNotReopenedWhenRmaIsReceived() {
        Account accountRecord = TestDataFactory.createAccount(true);
        Product2 productRecord = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c productItem = TestDataFactory.createProductItem(productRecord.Id, true);
        Opportunity opportunityRecord = TestDataFactory.createOpportunity(
            'Probe Sales Opportunity', accountRecord.Id, true
        );
        opportunityRecord = [
            SELECT Id, Pricebook2Id
            FROM Opportunity
            WHERE Id = :opportunityRecord.Id
        ];

        WorkOrder workOrderRecord = new WorkOrder(
            Subject = 'Completed RMA Regression Work Order',
            Status = 'Completed WO',
            RecordTypeId = '012Ro000001eDqnIAE',
            Country = 'United States',
            AccountId = accountRecord.Id,
            Opportunity__c = opportunityRecord.Id,
            Pricebook2Id = opportunityRecord.Pricebook2Id
        );
        insert workOrderRecord;
        opportunityRecord.Related_Work_Order__c = workOrderRecord.Id;
        update opportunityRecord;

        RMA__c rmaRecord = TestDataFactory.createRMA('Warranty Claim', false);
        rmaRecord.ProductItem__c = productItem.Id;
        rmaRecord.Opportunity__c = opportunityRecord.Id;
        rmaRecord.Customer_Expectation__c = 'Customer wants Equipment Back';
        rmaRecord.Quality_Issue_Notes__c = 'Regression test';
        rmaRecord.Tracking_number_of_RMA_Item_Received__c = 'REG-COMPLETE-001';
        insert rmaRecord;

        Test.startTest();
        rmaRecord.Date_RMA_Item_Received__c = Date.today();
        update rmaRecord;
        Flow.Interview.Apply_RMA_Received_Date_to_Related_Work_Order completedFlow =
            new Flow.Interview.Apply_RMA_Received_Date_to_Related_Work_Order(
                new Map<String, Object>{ 'rmaId' => rmaRecord.Id }
            );
        completedFlow.start();
        Test.stopTest();

        WorkOrder workOrderAfter = [
            SELECT Status, Date_Probe_Received_for_Repair_Eval__c
            FROM WorkOrder
            WHERE Id = :workOrderRecord.Id
        ];
        System.assertEquals('Completed WO', workOrderAfter.Status,
            'Receiving a Warranty Claim RMA must not reopen a completed Work Order.');
        System.assertEquals(Date.today(), workOrderAfter.Date_Probe_Received_for_Repair_Eval__c,
            'The received date must still be copied to the completed Work Order.');
    }

    @IsTest
    static void openWorkOrderStillMovesToInProgressWhenRmaIsReceived() {
        Account accountRecord = TestDataFactory.createAccount(true);
        Product2 productRecord = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c productItem = TestDataFactory.createProductItem(productRecord.Id, true);
        Opportunity opportunityRecord = TestDataFactory.createOpportunity(
            'Probe Sales Opportunity', accountRecord.Id, true
        );
        opportunityRecord = [
            SELECT Id, Pricebook2Id
            FROM Opportunity
            WHERE Id = :opportunityRecord.Id
        ];

        WorkOrder workOrderRecord = new WorkOrder(
            Subject = 'Open RMA Regression Work Order',
            Status = 'New',
            RecordTypeId = '012Ro000001eDqnIAE',
            Country = 'United States',
            AccountId = accountRecord.Id,
            Opportunity__c = opportunityRecord.Id,
            Pricebook2Id = opportunityRecord.Pricebook2Id
        );
        insert workOrderRecord;
        opportunityRecord.Related_Work_Order__c = workOrderRecord.Id;
        update opportunityRecord;

        RMA__c rmaRecord = TestDataFactory.createRMA('Warranty Claim', false);
        rmaRecord.ProductItem__c = productItem.Id;
        rmaRecord.Opportunity__c = opportunityRecord.Id;
        rmaRecord.Customer_Expectation__c = 'Customer wants Equipment Back';
        rmaRecord.Quality_Issue_Notes__c = 'Regression test';
        rmaRecord.Tracking_number_of_RMA_Item_Received__c = 'REG-OPEN-001';
        insert rmaRecord;

        Test.startTest();
        rmaRecord.Date_RMA_Item_Received__c = Date.today();
        update rmaRecord;
        Flow.Interview.Apply_RMA_Received_Date_to_Related_Work_Order openFlow =
            new Flow.Interview.Apply_RMA_Received_Date_to_Related_Work_Order(
                new Map<String, Object>{ 'rmaId' => rmaRecord.Id }
            );
        openFlow.start();
        Test.stopTest();

        WorkOrder workOrderAfter = [
            SELECT Status, Date_Probe_Received_for_Repair_Eval__c
            FROM WorkOrder
            WHERE Id = :workOrderRecord.Id
        ];
        System.assertEquals('In Progress', workOrderAfter.Status,
            'Open Work Orders must preserve the existing transition to In Progress.');
        System.assertEquals(Date.today(), workOrderAfter.Date_Probe_Received_for_Repair_Eval__c,
            'The received date must be copied to the open Work Order.');
    }
}
