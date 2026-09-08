public class ContractRenewalOppBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date contractEndDate180Days = Date.today().addDays(180);
        Date contractEndDate60Days  = Date.today().addDays(60);

        Set<String> renewalStatuses = new Set<String>{'FW_Activated_Draft', 'FW Activated', 'Activated'};
        Set<String> excludedStatuses = new Set<String>{'Terminated', 'Superseded', 'Terminated_Draft', 'Superseded_Draft', 'Expired_Draft', 'Expired'};

        // Query all required Account fields in the start method to avoid SOQL inside the loop
        return Database.getQueryLocator([
            SELECT Id, Auto_Renewal__c, SBQQ__RenewalForecast__c, EndDate, ContractNumber,
               AccountId, Billing_Contact__c, Pricebook2Id,
               Account.Name, 
               Account.Has_Billing_Contact__c,
               Account.Client_Legal_Entity_Name__c, 
               Account.Tax_ID__c, 
               Account.Separate_Legal_Entity_Tax_ID__c,
               Account.BillingStreet, Account.BillingCity, 
               Account.BillingState, Account.BillingPostalCode, Account.BillingCountry,
               Account.ShippingStreet, Account.ShippingCity, 
               Account.ShippingState, Account.ShippingPostalCode, Account.ShippingCountry,
               Account.Relationship_Manager__r.Email, Account.Owner.Email
            FROM Contract
            WHERE SBQQ__RenewalForecast__c = false
              AND Account.RecordType.DeveloperName != 'Strategic_Partner'
              AND Pricebook2.Name = 'CPQ'
              AND Status IN :renewalStatuses
              AND Status NOT IN :excludedStatuses
              AND (
                      (Auto_Renewal__c = 'No'  AND EndDate <= :contractEndDate180Days)
                   OR (Auto_Renewal__c = 'Yes' AND EndDate <= :contractEndDate60Days)
              )
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Contract> contractsToUpdate = new List<Contract>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        // Environment configuration calculated once per batch scope
        Boolean isSandbox = false;
        String baseUrl = 'https://login.salesforce.com';
        if (Test.isRunningTest()) {
            baseUrl = 'https://test.salesforce.com';
        } else {
            try {
                baseUrl = URL.getOrgDomainUrl().toExternalForm();
                isSandbox = baseUrl.contains('sandbox');
            } catch (Exception e) {}
        }
        String subjectPrefix = (Test.isRunningTest() || isSandbox ? 'No Action Required – ' : 'Action Required – ');

        for (Contract c : (List<Contract>) scope) {
            List<String> missingFields = new List<String>();
            Boolean hasValidBillingContact = (c.Account.Has_Billing_Contact__c == true);
            
            if (!hasValidBillingContact) missingFields.add('Billing Contact');
            if (String.isBlank(c.Account.Client_Legal_Entity_Name__c)) missingFields.add('Client Legal Entity Name');
            if (isInvalidTaxId(c.Account.Tax_ID__c)) missingFields.add('Tax ID');
            
            String sepPick = c.Account.Separate_Legal_Entity_Tax_ID__c;
            if (String.isBlank(sepPick) || sepPick == 'None') missingFields.add('Separate Legal Entity/Tax ID');

            if (String.isBlank(c.Account.BillingStreet) || String.isBlank(c.Account.BillingCity) || 
                String.isBlank(c.Account.BillingState) || String.isBlank(c.Account.BillingPostalCode) || 
                String.isBlank(c.Account.BillingCountry)) missingFields.add('Billing Address');

            if (String.isBlank(c.Account.ShippingStreet) || String.isBlank(c.Account.ShippingCity) || 
                String.isBlank(c.Account.ShippingState) || String.isBlank(c.Account.ShippingPostalCode) || 
                String.isBlank(c.Account.ShippingCountry)) missingFields.add('Shipping Address');

            // Build logic for emails if data is missing
            if (!missingFields.isEmpty()) {
                String missingFieldsHtml = '<ul>';
                for (String fieldName : missingFields) missingFieldsHtml += '<li>' + fieldName + '</li>';
                missingFieldsHtml += '</ul>';

                String emailBodyHtml = '<p>The following fields are missing for account ' +
                    '<a href="' + baseUrl + '/' + c.AccountId + '">' + c.Account.Name + '</a>. Please update them before ' +
                    String.valueOf(c.EndDate) + ' to prevent renewal issues.</p>' + missingFieldsHtml;

                if (!hasValidBillingContact) {
                    emailBodyHtml += '<p>Contract <a href="' + baseUrl + '/' + c.Id + '">' + c.ContractNumber + 
                    '</a> does not have a Billing Contact for an Account Set. ' +
                    'Either mark an existing Account contact for Billing contact for account to true or create a new Account contact with Billing Contact for Account = True on the account ' + 
                    '<a href="' + baseUrl + '/' + c.AccountId + '">' + c.Account.Name + '</a>.</p>';
                }

                Set<String> recipients = new Set<String>();
                if (c.Account.Relationship_Manager__r != null && !String.isBlank(c.Account.Relationship_Manager__r.Email)) recipients.add(c.Account.Relationship_Manager__r.Email);
                if (!String.isBlank(c.Account.Owner.Email)) recipients.add(c.Account.Owner.Email);

                for (String emailAddr : recipients) {
                    Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                    msg.setToAddresses(new String[]{emailAddr});
                    msg.setSubject(subjectPrefix + 'Missing Field Data for Contract Renewal: ' + c.ContractNumber);
                    msg.setHtmlBody(emailBodyHtml);
                    emails.add(msg);
                }
            }

            c.SBQQ__RenewalForecast__c = (missingFields.isEmpty() && hasValidBillingContact);
            c.Is_Schedule_Flow_Checked__c = c.SBQQ__RenewalForecast__c;
            contractsToUpdate.add(c);
        }

        if (!contractsToUpdate.isEmpty()) update contractsToUpdate;
        if (!emails.isEmpty() && !Test.isRunningTest()) Messaging.sendEmail(emails);
    }

    public void finish(Database.BatchableContext bc) {}

    private static Boolean isInvalidTaxId(String taxId) {
        if (String.isBlank(taxId)) return true;
        String digitsOnly = taxId.replaceAll('[^0-9]', '');
        return (!String.isBlank(digitsOnly) && digitsOnly.replaceAll('0','').length() == 0);
    }
}