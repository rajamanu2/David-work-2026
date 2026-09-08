/**
 * Contract Renewal Batch
 * Validates required Account fields and ensures at least one
 * ACTIVE Billing Contact (via ACR) with valid Role exists.
 * Sends notifications via the Automated Process user (default).
 */
public class ContractRenewalOpportunityBatch implements Database.Batchable<SObject> {

    private static final Set<String> VALID_ROLES = new Set<String>{
        'Business User',
        'Decision Maker',
        'Economic Buyer',
        'Economic Decision Maker',
        'Evaluator',
        'Executive Sponsor',
        'Influencer',
        'Technical Buyer',
        'Other',
        'Main Point Person'
    };

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date contractEndDate180Days = Date.today().addDays(180);
        Date contractEndDate60Days  = Date.today().addDays(60);

        Set<String> renewalStatuses = new Set<String>{
            'FW_Activated_Draft',
            'FW Activated',
            'Activated'
        };

        Set<String> excludedStatuses = new Set<String>{
            'Terminated',
            'Superseded',
            'Terminated_Draft',
            'Superseded_Draft',
            'Expired_Draft',
            'Expired'
        };

        return Database.getQueryLocator([
            SELECT Id, Auto_Renewal__c, SBQQ__RenewalForecast__c, EndDate, ContractNumber,
                   AccountId, Pricebook2Id,
                   Account.Name, Account.Relationship_Manager__c, 
                   Account.Relationship_Manager__r.Email, Account.Owner.Email,
                   Account.Client_Legal_Entity_Name__c, Account.Tax_ID__c, 
                   Account.Separate_Legal_Entity_Tax_ID__c,
                   Account.BillingStreet, Account.BillingCity, Account.BillingState, 
                   Account.BillingPostalCode, Account.BillingCountry,
                   Account.ShippingStreet, Account.ShippingCity, Account.ShippingState, 
                   Account.ShippingPostalCode, Account.ShippingCountry,
                   SBQQ__Quote__c
            FROM Contract
            WHERE SBQQ__RenewalForecast__c = false
              AND (Account.RecordType.DeveloperName != 'Strategic_Partner')
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
        List<Contract> contracts = (List<Contract>) scope;
        List<Contract> contractsToUpdate = new List<Contract>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        if (contracts.isEmpty()) return;

        // 1. Collect Account IDs
        Set<Id> accountIds = new Set<Id>();
        for (Contract c : contracts) {
            if (c.AccountId != null) accountIds.add(c.AccountId);
        }

        // 2. Query ACR records in bulk (Optimized)
        Map<Id, Boolean> accountHasValidBillingContact = new Map<Id, Boolean>();
        for (AccountContactRelation acr : [
            SELECT AccountId, Billing_Contact_For_Account__c, Roles, Contact.Inactive__c
            FROM AccountContactRelation
            WHERE AccountId IN :accountIds
        ]) {
            if (accountHasValidBillingContact.get(acr.AccountId) == true) continue;

            // Check if ACR is a valid Billing Contact
            Boolean isBilling = Boolean.valueOf(acr.Billing_Contact_For_Account__c);
            Boolean isActive = (acr.Contact != null && !Boolean.valueOf(acr.Contact.Inactive__c));
            
            if (isBilling && isActive && String.isNotBlank(acr.Roles)) {
                for (String role : acr.Roles.split(';')) {
                    if (VALID_ROLES.contains(role.trim())) {
                        accountHasValidBillingContact.put(acr.AccountId, true);
                        break;
                    }
                }
            }
        }

        // 3. Environment info (Optimized: outside loop)
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String subjectPrefix = (Test.isRunningTest() || isSandbox ? 'No Action Required – ' : 'Action Required – ');

        // 4. Validate Each Contract
        for (Contract c : contracts) {
            List<String> missingFields = new List<String>();

            // Billing Contact Validation via ACR logic
            if (accountHasValidBillingContact.get(c.AccountId) != true) {
                missingFields.add('Account has no Billing Contact associated to it (Active with valid Role)');
            }

            // Standard Field Validations
            if (String.isBlank(c.Account.Client_Legal_Entity_Name__c)) missingFields.add('Client Legal Entity Name');
            
            String sepPick = c.Account.Separate_Legal_Entity_Tax_ID__c;
            if (sepPick == null || sepPick == 'None') missingFields.add('Separate Legal Entity/Tax ID');

            if (String.isBlank(c.Account.BillingStreet) || String.isBlank(c.Account.BillingCity)) missingFields.add('Billing Address');
            if (String.isBlank(c.Account.ShippingStreet) || String.isBlank(c.Account.ShippingCity)) missingFields.add('Shipping Address');

            // Email Generation if Missing Data
            if (!missingFields.isEmpty()) {
                String accountLink = baseUrl + '/' + c.AccountId;
                String contractLink = baseUrl + '/' + c.Id;

                // Build HTML list efficiently
                List<String> htmlLines = new List<String>();
                htmlLines.add('<p>Please update the following missing information for account <a href="' + accountLink + '">' + c.Account.Name + '</a> before ' + c.EndDate + ' to prevent renewal issues:</p>');
                htmlLines.add('<ul>');
                for (String field : missingFields) { htmlLines.add('<li>' + field + '</li>'); }
                htmlLines.add('</ul>');
                htmlLines.add('<p>Contract: <a href="' + contractLink + '">' + c.ContractNumber + '</a></p>');
                htmlLines.add('<p>If you have any questions, please reach out to your Lead, RevOps, or submit a Salesforce ticket in Jira.</p>');

                String emailBodyHtml = String.join(htmlLines, '');

                Set<String> recipients = new Set<String>();
                if (c.Account.Relationship_Manager__r != null && String.isNotBlank(c.Account.Relationship_Manager__r.Email)) {
                    recipients.add(c.Account.Relationship_Manager__r.Email);
                }
                if (String.isNotBlank(c.Account.Owner.Email)) {
                    recipients.add(c.Account.Owner.Email);
                }

                for (String emailAddr : recipients) {
                    Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                    msg.setToAddresses(new String[]{emailAddr});
                    msg.setSubject(subjectPrefix + 'Missing Field Data for Contract Renewal: ' + c.ContractNumber);
                    msg.setHtmlBody(emailBodyHtml);
                    emails.add(msg);
                }
            }

            // Set renewal flags
            c.SBQQ__RenewalForecast__c = missingFields.isEmpty();
            c.Is_Schedule_Flow_Checked__c = c.SBQQ__RenewalForecast__c;
            contractsToUpdate.add(c);
        }

        if (!contractsToUpdate.isEmpty()) {
            Database.update(contractsToUpdate, false);
        }

        if (!emails.isEmpty() && !Test.isRunningTest()) {
            Messaging.sendEmail(emails);
        }
    }

    public void finish(Database.BatchableContext bc) { }
}