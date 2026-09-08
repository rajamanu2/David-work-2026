@isTest
private with sharing class PassfortFormExpiryAsyncSchedulerTest {
    
    @isTest
    private static void shouldScheduleAsyncJob() {

        Integer year = Date.today().year() + 1;
        String CRON_EXP = '0 0 0 1 1 ? ' + year;

        Test.startTest();
        String cronId = System.schedule('Test KYC Application form expiry checker', CRON_EXP, new PassfortFormExpiryAsyncScheduler());
        Test.stopTest();
    }
}