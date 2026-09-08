@isTest
public class ContractRenewalQuoteBatchTest {

    @isTest
    static void testContractRenewalQuoteBatch() {
        // Setup: Create Account, Pricebook, and Contracts for testing
        Account testAccount = new Account(Name = 'Test Account 1');
        insert testAccount;  
        
        // Create Pricebook 'CPQ' for the test (Important for the query filter)
        Pricebook2 testPricebook = new Pricebook2(Name = 'CPQ', IsActive = true);
        insert testPricebook;  

        // Define contract end dates for manual and auto-renewal tests
        Date contractEndDate60Days = Date.today().addDays(60); 
        Date contractEndDate1Days = Date.today().addDays(1);  

        // Create a manual renewal contract (Auto_Renewal__c = 'No') within 60 days
        Contract manualRenewalQuote = new Contract(
            Auto_Renewal__c = 'No',  
            SBQQ__RenewalForecast__c = true,
            SBQQ__RenewalQuoted__c = false,
            EndDate = contractEndDate60Days, 
            Pricebook2Id = testPricebook.Id,
            OwnerExpirationNotice = '90',
            AccountId = testAccount.Id  
        );
        
        // Create an auto renewal contract (Auto_Renewal__c = 'Yes') within 1 days
        Contract autoRenewalQuote = new Contract(
            Auto_Renewal__c = 'Yes', 
            SBQQ__RenewalForecast__c = true,
            SBQQ__RenewalQuoted__c = false, 
            EndDate = contractEndDate1Days,  
            Pricebook2Id = testPricebook.Id, 
            OwnerExpirationNotice = '90',
            AccountId = testAccount.Id  
        );

        // Create a contract that will not meet the renewal criteria (no renewal)
        Contract expiredRenewalQuote = new Contract(
            Auto_Renewal__c = 'No', 
            SBQQ__RenewalForecast__c = true, 
            SBQQ__RenewalQuoted__c = false, 
            EndDate = Date.today().addDays(80),  
            Pricebook2Id = testPricebook.Id, 
            OwnerExpirationNotice = '90',
            AccountId = testAccount.Id 
        );

        // Insert contracts
        insert new List<Contract>{manualRenewalQuote, autoRenewalQuote, expiredRenewalQuote};

        // Run the batch
        Test.startTest();
        ContractRenewalQuoteBatch batch1 = new ContractRenewalQuoteBatch();
        Database.executeBatch(batch1, 200);  
        Test.stopTest();

        // Verify that the manual renewal contract was updated to true
        Contract updatedManualContract = [SELECT SBQQ__RenewalQuoted__c FROM Contract WHERE Id = :manualRenewalQuote.Id];
        System.assertEquals(true, updatedManualContract.SBQQ__RenewalQuoted__c, 
                            'The SBQQ__RenewalQuoted__c field for manual renewal contract should be true.');

        // Verify that the auto renewal contract was updated to true
        Contract updatedAutoContract = [SELECT SBQQ__RenewalQuoted__c FROM Contract WHERE Id = :autoRenewalQuote.Id];
        System.assertEquals(true, updatedAutoContract.SBQQ__RenewalQuoted__c, 
                            'The SBQQ__RenewalQuoted__c field for auto renewal contract should be true.');

        // Verify that the expired contract was NOT updated (still false)
        Contract updatedExpiredContract = [SELECT SBQQ__RenewalQuoted__c FROM Contract WHERE Id = :expiredRenewalQuote.Id];
        System.assertEquals(false, updatedExpiredContract.SBQQ__RenewalQuoted__c, 
                            'The SBQQ__RenewalQuoted__c field for expired contract should remain false.');
    }

    @isTest
    static void shouldNotRenewStrategicPartnerContract() {
        // Setup: Create Account, Pricebook, and Contracts for testing
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Strategic_Partner').getRecordTypeId();
        Account testAccount = new Account(Name = 'Test Account 1', RecordTypeId = rtId);
        insert testAccount;  
        
        // Create Pricebook 'CPQ' for the test (Important for the query filter)
        Pricebook2 testPricebook = new Pricebook2(Name = 'CPQ', IsActive = true);
        insert testPricebook;  

        // Define contract end dates for manual and auto-renewal tests
        Date contractEndDate60Days = Date.today().addDays(60); 
        Date contractEndDate1Days = Date.today().addDays(1);  

        // Create a manual renewal contract (Auto_Renewal__c = 'No') within 60 days
        Contract manualRenewalQuote = new Contract(
            Auto_Renewal__c = 'No',  
            SBQQ__RenewalForecast__c = true,
            SBQQ__RenewalQuoted__c = false,
            EndDate = contractEndDate60Days, 
            Pricebook2Id = testPricebook.Id,  
            OwnerExpirationNotice = '90',
            AccountId = testAccount.Id  
        );
        
        // Create an auto renewal contract (Auto_Renewal__c = 'Yes') within 1 days
        Contract autoRenewalQuote = new Contract(
            Auto_Renewal__c = 'Yes', 
            SBQQ__RenewalForecast__c = true,
            SBQQ__RenewalQuoted__c = false, 
            EndDate = contractEndDate1Days,  
            Pricebook2Id = testPricebook.Id, 
            OwnerExpirationNotice = '90',
            AccountId = testAccount.Id  
        );

        // Create a contract that will not meet the renewal criteria (no renewal)
        Contract expiredRenewalQuote = new Contract(
            Auto_Renewal__c = 'No', 
            SBQQ__RenewalForecast__c = true, 
            SBQQ__RenewalQuoted__c = false, 
            EndDate = Date.today().addDays(80),  
            Pricebook2Id = testPricebook.Id, 
            OwnerExpirationNotice = '90',
            AccountId = testAccount.Id 
        );

        // Insert contracts
        insert new List<Contract>{manualRenewalQuote, autoRenewalQuote, expiredRenewalQuote};

        // Run the batch
        Test.startTest();
        ContractRenewalQuoteBatch batch1 = new ContractRenewalQuoteBatch();
        Database.executeBatch(batch1, 200);  
        Test.stopTest();

        // Verify that the manual renewal contract was updated to false
        Contract updatedManualContract = [SELECT SBQQ__RenewalQuoted__c FROM Contract WHERE Id = :manualRenewalQuote.Id];
        System.assertEquals(false, updatedManualContract.SBQQ__RenewalQuoted__c, 
                            'The SBQQ__RenewalQuoted__c field for manual renewal contract should be false.');

        // Verify that the auto renewal contract was updated to false
        Contract updatedAutoContract = [SELECT SBQQ__RenewalQuoted__c FROM Contract WHERE Id = :autoRenewalQuote.Id];
        System.assertEquals(false, updatedAutoContract.SBQQ__RenewalQuoted__c, 
                            'The SBQQ__RenewalQuoted__c field for auto renewal contract should be false.');

        // Verify that the expired contract was NOT updated (still false)
        Contract updatedExpiredContract = [SELECT SBQQ__RenewalQuoted__c FROM Contract WHERE Id = :expiredRenewalQuote.Id];
        System.assertEquals(false, updatedExpiredContract.SBQQ__RenewalQuoted__c, 
                            'The SBQQ__RenewalQuoted__c field for expired contract should remain false.');
    }
}