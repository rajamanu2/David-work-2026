/**
 * @class       						   RecurringAbsenceControllerTest
 * @description 						   test class for RecurringAbsenceController
 * 
 * @author      						   Daniel Perez
 * @created     						   2026-07-20
 */
@IsTest
public class RecurringAbsenceControllerTest {
    
    @testSetup
    static void setupData() {
        User u = [SELECT Id FROM User WHERE isActive = true LIMIT 1];
        
        // Create a Service Resource (adjust required fields for your org)
        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource',
            IsActive = true,
            RelatedRecordId = u.Id
        );
        insert sr;
    }

    @isTest
    static void testSaveDailyRecurringAbsence() {
        User user = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        System.runAs(user) {
            ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];

            ApexPages.StandardController sc = new ApexPages.StandardController(
                new ResourceAbsence()
            );

            Test.setCurrentPage(Page.RecurringAbsence);

            ApexPages.currentPage().getParameters().put('id', sr.Id);

            RecurringAbsenceController controller = new RecurringAbsenceController(sc);

            controller.absence.ResourceId = sr.Id;
            controller.absence.Type = 'Vacation';
            controller.absence.FSL__GanttLabel__c = 'PTO';
            controller.absence.RecordTypeId = ResourceAbsence.SObjectType
                .getDescribe()
                .getRecordTypeInfosByName()
                .values()[0]
                .getRecordTypeId();

            controller.recurrenceType = 'Daily';
            controller.frequency = 1;
            controller.recurrenceEndType = 'Occurrences';
            controller.numberOfOccurrences = 3;

            controller.startDateInput = Date.today();
            controller.endDateInput = Date.today();

            controller.startTimeInput = '08:00';
            controller.endTimeInput = '17:00';
            
            Test.startTest();
            PageReference pr = controller.saveAbsences();
            Test.stopTest();

            System.assertNotEquals(null, pr);

            List<ResourceAbsence> absences = [
                SELECT Id, FSL__GanttLabel__c, Start, End
                FROM ResourceAbsence
                WHERE ResourceId = :sr.Id
            ];

            System.assertEquals(3, absences.size());

            for (ResourceAbsence ra : absences) {
                System.assertEquals('PTO', ra.FSL__GanttLabel__c);
            }
        }
    }

    @isTest
    static void testCancel() {
        User user = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        System.runAs(user) {
            ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];

            ApexPages.StandardController sc = new ApexPages.StandardController(
                new ResourceAbsence()
            );

            ApexPages.currentPage().getParameters().put('id', sr.Id);

            RecurringAbsenceController controller = new RecurringAbsenceController(sc);

            PageReference pr = controller.cancel();

            System.assertNotEquals(null, pr);
        }
    }

    @isTest
    static void testInvalidEndTime() {
        User user = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        System.runAs(user) {
            ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];

            ApexPages.StandardController sc = new ApexPages.StandardController(
                new ResourceAbsence()
            );

            ApexPages.currentPage().getParameters().put('id', sr.Id);

            RecurringAbsenceController controller = new RecurringAbsenceController(sc);

            controller.absence.ResourceId = sr.Id;
            controller.absence.Type = 'Vacation';

            controller.recurrenceType = 'Daily';
            controller.frequency = 1;
            controller.recurrenceEndType = 'Occurrences';
            controller.numberOfOccurrences = 1;

            controller.startDateInput = Date.today();
            controller.endDateInput = Date.today();

            controller.startTimeInput = '17:00';
            controller.endTimeInput = '08:00';

            Test.startTest();
            PageReference pr = controller.saveAbsences();
            Test.stopTest();

            System.assertEquals(null, pr);
            System.assert(ApexPages.hasMessages());
        }
    }

    @isTest
    static void testWeeklyValidation() {
        User user = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        System.runAs(user) {
            ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];

            ApexPages.StandardController sc = new ApexPages.StandardController(
                new ResourceAbsence()
            );

            ApexPages.currentPage().getParameters().put('id', sr.Id);

            RecurringAbsenceController controller = new RecurringAbsenceController(sc);

            controller.absence.ResourceId = sr.Id;
            controller.absence.Type = 'Vacation';

            controller.recurrenceType = 'Weekly';
            controller.frequency = 1;
            controller.numberOfOccurrences = 2;
            controller.recurrenceEndType = 'Occurrences';

            controller.startDateInput = Date.today();
            controller.endDateInput = Date.today();

            controller.startTimeInput = '08:00';
            controller.endTimeInput = '17:00';
            controller.selectedRecurrenceDays = '';

            Test.startTest();
            PageReference pr = controller.saveAbsences();
            Test.stopTest();

            System.assertEquals(null, pr);
            System.assert(ApexPages.hasMessages());
        }
    }
    
    @IsTest
    static void testMatchesMonthlyRule() {
        User user = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        System.runAs(user) {
            RecurringAbsenceController controller =
                new RecurringAbsenceController(
                    new ApexPages.StandardController(new ResourceAbsence())
                );

            Date monday = Date.newInstance(2026, 8, 3);
            Date saturday = Date.newInstance(2026, 8, 1);
            Date sunday = Date.newInstance(2026, 8, 2);
            
            System.assertEquals(
                true,
                controller.matchesMonthlyRule(monday, 'Day')
            );        
            System.assertEquals(
                true,
                controller.matchesMonthlyRule(monday, 'Weekday')
            );
            System.assertEquals(
                false,
                controller.matchesMonthlyRule(saturday, 'Weekday')
            );
            System.assertEquals(
                true,
                controller.matchesMonthlyRule(saturday, 'Weekend Day')
            );
            System.assertEquals(
                true,
                controller.matchesMonthlyRule(sunday, 'Sunday')
            );
            System.assertEquals(
                false,
                controller.matchesMonthlyRule(monday, 'Sunday')
            );
            System.assertEquals(
                true,
                controller.matchesMonthlyRule(monday, 'Monday')
            );
        }
    }
    
    @IsTest
    static void testMatchesRule() {
        User user = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        System.runAs(user) {
            RecurringAbsenceController controller =
                new RecurringAbsenceController(
                    new ApexPages.StandardController(new ResourceAbsence())
                );

            Date sunday = Date.newInstance(2026, 8, 2);
            Date monday = Date.newInstance(2026, 8, 3);
            Date tuesday = Date.newInstance(2026, 8, 4);
            Date wednesday = Date.newInstance(2026, 8, 5);
            Date thursday = Date.newInstance(2026, 8, 6);
            Date friday = Date.newInstance(2026, 8, 7);
            Date saturday = Date.newInstance(2026, 8, 1);
        
            System.assert(controller.matchesRule(monday, 'Day'));
            
            System.assert(controller.matchesRule(monday, 'Weekday'));
            System.assert(!controller.matchesRule(saturday, 'Weekday'));
            System.assert(!controller.matchesRule(sunday, 'Weekday'));
        
            System.assert(controller.matchesRule(saturday, 'Weekend Day'));
            System.assert(controller.matchesRule(sunday, 'Weekend Day'));
            System.assert(!controller.matchesRule(monday, 'Weekend Day'));
        
            System.assert(controller.matchesRule(sunday, 'Sunday'));
            System.assert(controller.matchesRule(monday, 'Monday'));
            System.assert(controller.matchesRule(tuesday, 'Tuesday'));
            System.assert(controller.matchesRule(wednesday, 'Wednesday'));
            System.assert(controller.matchesRule(thursday, 'Thursday'));
            System.assert(controller.matchesRule(friday, 'Friday'));
            System.assert(controller.matchesRule(saturday, 'Saturday'));
            System.assertEquals(false, controller.matchesRule(monday, 'Invalid'));
        }
    }

    @IsTest
    static void testGetNthWeekdayOfMonth() {
        User user = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        System.runAs(user) {
            RecurringAbsenceController controller =
                new RecurringAbsenceController(
                    new ApexPages.StandardController(new ResourceAbsence())
                );

            RecurringAbsenceController.DateInfo dateInfo =
                new RecurringAbsenceController.DateInfo(2026, 8);

            System.assertEquals(
                Date.newInstance(2026, 8, 2),
                controller.getNthWeekdayOfMonth(dateInfo, 'First', 'Sunday')
            );
            System.assertEquals(
                Date.newInstance(2026, 8, 9),
                controller.getNthWeekdayOfMonth(dateInfo, 'Second', 'Sunday')
            );
            System.assertEquals(
                Date.newInstance(2026, 8, 16),
                controller.getNthWeekdayOfMonth(dateInfo, 'Third', 'Sunday')
            );
            System.assertEquals(
                Date.newInstance(2026, 8, 23),
                controller.getNthWeekdayOfMonth(dateInfo, 'Fourth', 'Sunday')
            );
            System.assertEquals(
                Date.newInstance(2026, 8, 30),
                controller.getNthWeekdayOfMonth(dateInfo, 'Last', 'Sunday')
            );
            System.assertEquals(
                Date.newInstance(2026, 8, 3),
                controller.getNthWeekdayOfMonth(dateInfo, 'First', 'Weekday')
            );
            System.assertEquals(
                Date.newInstance(2026, 8, 1),
                controller.getNthWeekdayOfMonth(dateInfo, 'First', 'Weekend Day')
            );
            System.assertEquals(
                Date.newInstance(2026, 8, 1),
                controller.getNthWeekdayOfMonth(dateInfo, 'First', 'Day')
            );
        }
    }
    
    @IsTest
    static void testGetNextMonthlyOccurrence() {
        User user = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        System.runAs(user) {
            RecurringAbsenceController controller =
                new RecurringAbsenceController(
                    new ApexPages.StandardController(new ResourceAbsence())
                );
        
            DateTime current = DateTime.newInstance(2026, 1, 15, 8, 30, 0);
        
            controller.frequency = 1;
            controller.monthlyRecurringType = 'Date';
            controller.monthlyDayOfMonth = 20;
        
            DateTime result = controller.getNextMonthlyOccurrence(current);
        
            System.assertEquals(
                DateTime.newInstance(2026, 2, 20, 8, 30, 0),
                result
            );
        
            controller.monthlyDayOfMonth = 31;
        
            result = controller.getNextMonthlyOccurrence(current);
        
            System.assertEquals(
                DateTime.newInstance(2026, 2, 28, 8, 30, 0),
                result
            );
        
            controller.monthlyRecurringType = 'Day';
            controller.monthlyWeekPosition = 'First';
            controller.monthlyDayOfWeek = 'Monday';
        
            result = controller.getNextMonthlyOccurrence(current);
        
            System.assertEquals(
                DateTime.newInstance(2026, 2, 2, 8, 30, 0),
                result
            );
        
            controller.frequency = 2;
            controller.monthlyRecurringType = 'Date';
            controller.monthlyDayOfMonth = 15;
        
            result = controller.getNextMonthlyOccurrence(current);
        
            System.assertEquals(
                DateTime.newInstance(2026, 3, 15, 8, 30, 0),
                result
            );
        }
    }
    
    @IsTest
    static void testGetNextYearlyOccurrence() {
        User user = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        System.runAs(user) {
            RecurringAbsenceController controller =
                new RecurringAbsenceController(
                    new ApexPages.StandardController(new ResourceAbsence())
                );
            
            DateTime current = DateTime.newInstance(2026, 5, 10, 9, 45, 0);
            
            controller.frequency = 1;
            controller.yearlyRecurringType = 'Date';
            controller.yearlyMonth = 'March';
            controller.yearlyDayOfMonth = 15;
            
            DateTime result = controller.getNextYearlyOccurrence(current);
            
            System.assertEquals(
                DateTime.newInstance(2027, 3, 15, 9, 45, 0),
                result
            );

            controller.yearlyMonth = 'February';
            controller.yearlyDayOfMonth = 31;
        
            result = controller.getNextYearlyOccurrence(current);
            
            System.assertEquals(
                DateTime.newInstance(2027, 2, 28, 9, 45, 0),
                result
            );

            controller.yearlyRecurringType = 'Day';
            controller.yearlyWeekPosition = 'Second';
            controller.yearlyDayOfWeek = 'Tuesday';
            controller.yearlyWeekMonth = 'August';
        
            result = controller.getNextYearlyOccurrence(System.today());
        	//Date compareDate = System.today().addYears(1);
            //System.assertEquals(
           //     compareDate,
            //    result
            //);
        
            controller.frequency = 2;
            controller.yearlyRecurringType = 'Date';
            controller.yearlyMonth = 'January';
            controller.yearlyDayOfMonth = 5;
        
            result = controller.getNextYearlyOccurrence(current);
        
            System.assertEquals(
                DateTime.newInstance(2028, 1, 5, 9, 45, 0),
                result
            );
        }
    }
    
    @IsTest
    static void testMonthOptions() {
        User user = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        System.runAs(user) {
            RecurringAbsenceController controller =
                new RecurringAbsenceController(
                    new ApexPages.StandardController(new ResourceAbsence())
                );
        
            List<SelectOption> options = controller.monthOptions;
        
            System.assertNotEquals(null, options);
            System.assertEquals(12, options.size());
        
            System.assertEquals('January', options[0].getValue());
            System.assertEquals('January', options[0].getLabel());
        
            System.assertEquals('December', options[11].getValue());
            System.assertEquals('December', options[11].getLabel());
        
            System.assertEquals(options, controller.monthOptions);
        }
    }
    
    @IsTest
    static void testMonthlyDayOptions() {
        User user = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        System.runAs(user) {
            RecurringAbsenceController controller =
                new RecurringAbsenceController(
                    new ApexPages.StandardController(new ResourceAbsence())
                );
            
            List<SelectOption> options = controller.monthlyDayOptions;
        
            System.assertNotEquals(null, options);
            System.assertEquals(31, options.size());
        
            System.assertEquals('1', options[0].getValue());
            System.assertEquals('1', options[0].getLabel());
        
            System.assertEquals('31', options[30].getValue());
            System.assertEquals('31', options[30].getLabel());
            
            System.assertEquals(options, controller.monthlyDayOptions);
        }
    }
}