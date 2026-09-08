public without sharing class PassfortProfileBatchProcessor implements Database.Batchable<String>, Database.AllowsCallouts {
    private List<String> profileIds;
    private String reqBody;
    List<Passfort_Webhook_Log__c> webHookLogs = new List<Passfort_Webhook_Log__c>();

    public PassfortProfileBatchProcessor(Set<String> profileIds, String reqBody) {
        this.profileIds = new List<String>(profileIds);
        this.reqBody = reqBody;
    }

    public List<String> start(Database.BatchableContext bc) {
        return profileIds;
    }

    public void execute(Database.BatchableContext bc, List<String> scope) {
        Set<Account> updatedAccounts = new Set<Account>();
        List<KYC_Application__c> kycApps = new List<KYC_Application__c>();
        
        for (String currentProfileId : scope) {
            Passfort_Webhook_Log__c log = new Passfort_Webhook_Log__c();
            log.Request_body__c = reqBody;
            log.Extracted_Profile_Id__c = currentProfileId;
            try {
                PassfortUtil.PassfortProfileProcessingWrapper wrapper = PassfortUtil.updateAccout(log.Extracted_Profile_Id__c, log);
                log.Status__c = 'Success';
                log.Message__c = wrapper.logMessage;
                if (wrapper.acct != null) {
                    updatedAccounts.add(wrapper.acct);
                }
                if (!wrapper.apps.isEmpty()) {
                    kycApps.addAll(wrapper.apps);
                }
            } catch (PassfortWebhook.RequestBodyException e) {
                System.debug(e.getMessage());
                log.Status__c = 'Error';
                String logMessage = e.getMessage();
                logMessage = logMessage.length() > 131071 ? logMessage.substring(0, 131072) : logMessage;
                log.Message__c = logMessage;
            }
            webHookLogs.add(log);
        }
        System.enqueueJob(new PassfortProfileAsyncProcessor(webHookLogs, updatedAccounts, kycApps));
    }

    public void finish(Database.BatchableContext bc) {}
}