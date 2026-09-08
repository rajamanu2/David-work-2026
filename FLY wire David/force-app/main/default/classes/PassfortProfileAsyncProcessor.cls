public without sharing class PassfortProfileAsyncProcessor implements Queueable, Database.AllowsCallouts {
    List<Passfort_Webhook_Log__c> webHookLogs;
    List<Account> updatedAccounts;
    List<KYC_Application__c> kycApps;

    public PassfortProfileAsyncProcessor(List<Passfort_Webhook_Log__c> webHookLogs, Set<Account> updatedAccounts, List<KYC_Application__c> kycApps) {
        this.webHookLogs = webHookLogs;
        this.updatedAccounts = new List<Account>(updatedAccounts);
        this.kycApps = kycApps;
    }

    public void execute(QueueableContext context) {
        if (!webHookLogs.isEmpty()) {
            insert webHookLogs;
        }
        if (!updatedAccounts.isEmpty()) {
            update updatedAccounts;
        }
        if (!kycApps.isEmpty()) {
            upsert kycApps Application_ID__c;
        }        
    }
}