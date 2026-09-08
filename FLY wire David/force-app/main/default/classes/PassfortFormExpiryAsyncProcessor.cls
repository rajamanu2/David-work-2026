public with sharing class PassfortFormExpiryAsyncProcessor implements Database.Batchable<SObject>, Database.AllowsCallouts {

    // When a new application form is created the KYC application can be created or not 
    // depending on the questions answered by the client.
    // 1. If the application is created, the account KYC status will be Applied
    // 2. If the application is not created on the account, the KYC status will be null.
    public final String query = 
        'SELECT Id, Passfort_Profile_Id__c, KYC_Status__c ' +
        'FROM Account ' + 
        'WHERE Passfort_KYC_Form__c != null AND KYC_Status__c IN (\'Applied\',null)';

    public PassfortFormExpiryAsyncProcessor() {}

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('batch start');
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        System.debug('Batch execute - scope size: ' + scope.size());
        Map<String,Boolean> areExpired = PassfortApplicationFormExpiryChecker.areExpired((List<Account>)scope);

        List<Account> scopeAccounts = (List<Account>)scope;
        List<Account> accountsWithExpiredForms = new List<Account>();

        for (Account currentAccount : scopeAccounts) {
            if (areExpired.get(currentAccount.Id)) {
                currentAccount.Passfort_KYC_Form__c = null;
                accountsWithExpiredForms.add(currentAccount);
            }
        }

        update accountsWithExpiredForms;
    }

    public void finish(Database.BatchableContext bc) {}
}