@isTest
private class ContractRenewalSchedulersTest {

    @isTest
    static void testOpportunityScheduler() {

        Test.startTest();
        // Schedule the job to run in 30 minutes
        String cronExpression = '0 1 * * * ?';
        String jobID = System.schedule('Contract Renewal Opty Scheduler Test', cronExpression, new ContractRenewalOptyScheduler());
        Test.stopTest();

        // Query CronTrigger to ensure the job is scheduled
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger WHERE Id = :jobID];
        
        // Check that the job was scheduled correctly
        System.assertEquals(cronExpression, ct.CronExpression, 'The CRON expression should match the one scheduled.');
        System.assertEquals(0, ct.TimesTriggered, 'The job should not have been triggered yet.');
    }

    @isTest
    static void testQuoteScheduler() {

        Test.startTest();
        // Schedule the job to run in 30 minutes
        String cronExpression = '0 1 * * * ?';
        String jobID = System.schedule('Contract Renewal Opty Scheduler Test', cronExpression, new ContractRenewalQuoteScheduler());
        Test.stopTest();

        // Query CronTrigger to ensure the job is scheduled
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger WHERE Id = :jobID];
        
        // Check that the job was scheduled correctly
        System.assertEquals(cronExpression, ct.CronExpression, 'The CRON expression should match the one scheduled.');
        System.assertEquals(0, ct.TimesTriggered, 'The job should not have been triggered yet.');
    }
}