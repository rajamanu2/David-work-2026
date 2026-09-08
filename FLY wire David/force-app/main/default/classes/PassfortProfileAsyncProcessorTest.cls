@isTest
public with sharing class PassfortProfileAsyncProcessorTest {
    @TestSetup
    static void makeData() {
        insert (new Account(Name = 'Test Acct'));
    }

    @isTest
    static void shouldPerformDMLOperations() {
        List<Passfort_Webhook_Log__c> logBeforeProcessing = [SELECT Id FROM Passfort_Webhook_Log__c];
        List<Account> accountBeforeProcessing = [SELECT Id, Name FROM Account];
        List<KYC_Application__c> kycAppsBeforeProcessing = [SELECT Id FROM KYC_Application__c];
        
        Assert.isTrue(logBeforeProcessing.isEmpty());
        Assert.isTrue(!accountBeforeProcessing.isEmpty());
        Assert.isTrue(kycAppsBeforeProcessing.isEmpty());

        accountBeforeProcessing[0].Passfort_Profile_Id__c = 'test_profile_id';

        List<Passfort_Webhook_Log__c> logs = new List<Passfort_Webhook_Log__c>();
        Passfort_Webhook_Log__c log = new Passfort_Webhook_Log__c(
            Status__c = 'Success'
        );
        logs.add(log);

        List<KYC_Application__c> kycApps = new List<KYC_Application__c>();
        KYC_Application__c app = new KYC_Application__c(
            Account__c = accountBeforeProcessing[0].Id,
            Application_ID__c = 'test_app_id'
        );
        kycApps.add(app);

        Test.startTest();
        System.enqueueJob(new PassfortProfileAsyncProcessor(logs, new Set<Account>(accountBeforeProcessing), kycApps));
        Test.stopTest();
        
        List<Passfort_Webhook_Log__c> logAfterProcessing = [SELECT Id, Status__c, Request_Body__c, Extracted_Profile_Id__c FROM Passfort_Webhook_Log__c];
        List<Account> accountsAfterProcessing = [SELECT Id, Passfort_Profile_Id__c FROM Account];
        List<KYC_Application__c> kycAppsAfterProcessing = [SELECT Id, Status__c, Account__c FROM KYC_Application__c];
        
        Assert.isFalse(logAfterProcessing.isEmpty());
        Assert.areEqual('Success', logAfterProcessing[0].Status__c);
        Assert.areEqual('test_profile_id', accountsAfterProcessing[0].Passfort_Profile_Id__c);
        Assert.isFalse(kycAppsAfterProcessing.isEmpty());
        Assert.areEqual(accountsAfterProcessing[0].Id, kycAppsAfterProcessing[0].Account__c);
    }
}