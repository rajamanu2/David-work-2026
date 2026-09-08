@IsTest
public class ContractRenewalOppBatchTest {

    private static final Id RUNNING_USER_ID = UserInfo.getUserId();

    // --- MOCK IMPLEMENTATION FOR HTTP ---
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody('{"status": "success"}');
            return res;
        }
    }

    private static Id getAccountRecordTypeId(String developerName) {
        return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
    }

    // Helper method to generate common setup requirements
    private static Pricebook2 getPricebook() {
        Pricebook2 pb;
        List<Pricebook2> pbs = [SELECT Id FROM Pricebook2 WHERE Name = 'CPQ' LIMIT 1];
        if (pbs.isEmpty()) {
            pb = new Pricebook2(Name = 'CPQ', IsActive = true);
            insert pb;
        } else {
            pb = pbs[0];
        }
        return pb;
    }

    /** ✅ Scenario 1: Valid Contract Renewal (Success Path) **/
    @IsTest
    static void testValidRenewalScenario() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Date contractEndDate = Date.today().addDays(60);
        Date contractStartDate = contractEndDate.addMonths(-12);
        Pricebook2 pb = getPricebook();
        
        Account acc = new Account(
            Name = 'Flywire Renewal Account', 
            Client_Legal_Entity_Name__c = 'Edu Corp', 
            Tax_ID__c = '123456789', 
            Separate_Legal_Entity_Tax_ID__c = 'No', 
            OwnerId = RUNNING_USER_ID,
            BillingStreet = '123 Main St', BillingCity = 'New York', BillingState = 'NY', BillingPostalCode = '10001', BillingCountry = 'United States',
            ShippingStreet = '456 Ship St', ShippingCity = 'New York', ShippingState = 'NY', ShippingPostalCode = '10001', ShippingCountry = 'United States'
        ); 
        insert acc;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id, Name = 'Test Renewal Opp Name', StageName = 'Discovery/Qualifying', 
            CloseDate = Date.today().addMonths(3), Opp_Bypass_DateTime__c = System.now() 
        ); 
        insert opp;

        Contact billingCon = new Contact(
            FirstName = 'John', LastName = 'Doe', Email = 'john.doe@flywire.com', 
            AccountId = acc.Id, Inactive__c = false, Contact_Automation_Bypass_DateTime__c = System.now()
        ); 
        insert billingCon;

        insert new OpportunityContactRole(OpportunityId = opp.Id, ContactId = billingCon.Id, Role = 'Decision Maker', IsPrimary = true);

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Status__c = 'Draft', SBQQ__Account__c = acc.Id, SBQQ__Opportunity2__c = opp.Id, 
            Owner_Expiration_Notice__c = '90', Quote_Bypass_DateTime__c = System.now()
        ); 
        insert testQuote;
        
        testQuote.SBQQ__Status__c = 'Client Approved';
        update testQuote;

        AccountContactRelation existingAcr = [SELECT Id FROM AccountContactRelation WHERE AccountId = :acc.Id AND ContactId = :billingCon.Id LIMIT 1];
        existingAcr.Roles = 'Decision Maker';
        existingAcr.Billing_Contact_For_Account__c = true;
        update existingAcr;

        Contract c = new Contract(
            AccountId = acc.Id, Pricebook2Id = pb.Id, StartDate = contractStartDate, EndDate = contractEndDate,
            Auto_Renewal__c = 'Yes', SBQQ__RenewalForecast__c = false, Status = 'FW_Activated_Draft', 
            OwnerExpirationNotice = '90', SBQQ__RenewalTerm__c = 12, SBQQ__Quote__c = testQuote.Id, OwnerId = RUNNING_USER_ID
        );
        insert c;

        Product2 prod = new Product2(Name = 'Payments', IsActive = true, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__SubscriptionTerm__c = 12);
        insert prod;

        SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
            SBQQ__Contract__c = c.Id, SBQQ__Account__c = acc.Id, SBQQ__Product__c = prod.Id,
            SBQQ__Quantity__c = 1, SBQQ__SubscriptionStartDate__c = contractStartDate, Ship_To_Account__c = acc.Id 
        );
        insert sub;

        Test.startTest();
            Database.executeBatch(new ContractRenewalOppBatch(), 1);
        Test.stopTest(); 

        Contract updated = [SELECT SBQQ__RenewalForecast__c FROM Contract WHERE Id = :c.Id];
        System.assertEquals(true, updated.SBQQ__RenewalForecast__c, 'Forecast should be TRUE.');
    }

    /** ❌ Scenario 2: Strategic Partner Excluded **/
    @IsTest
    static void testStrategicPartnerExclusion() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Id partnerRtId = getAccountRecordTypeId('Strategic_Partner');
        Pricebook2 pb = getPricebook();
        
        Account acc = new Account(
            Name = 'Flywire Strategic Account', RecordTypeId = partnerRtId, Client_Legal_Entity_Name__c = 'Strategic Corp',
            Tax_ID__c = 'TX123456', Separate_Legal_Entity_Tax_ID__c = 'No', OwnerId = RUNNING_USER_ID,
            BillingStreet = '123 St', BillingCity = 'NY', BillingState = 'NY', BillingPostalCode = '10001', BillingCountry = 'United States',
            ShippingStreet = '123 St', ShippingCity = 'NY', ShippingState = 'NY', ShippingPostalCode = '10001', ShippingCountry = 'United States'
        ); insert acc;

        Opportunity opp = new Opportunity(AccountId = acc.Id, Name = 'Strategic Opp', StageName = 'Discovery/Qualifying', CloseDate = Date.today().addMonths(3), Opp_Bypass_DateTime__c = System.now());
        insert opp;

        Contact billingCon = new Contact(FirstName = 'Strategic', LastName = 'Rep', Email = 'strat@flywire.com', AccountId = acc.Id, Contact_Automation_Bypass_DateTime__c = System.now());
        insert billingCon;

        insert new OpportunityContactRole(OpportunityId = opp.Id, ContactId = billingCon.Id, Role = 'Decision Maker', IsPrimary = true);

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Status__c = 'Client Approved', SBQQ__Account__c = acc.Id, SBQQ__Opportunity2__c = opp.Id, Quote_Bypass_DateTime__c = System.now());
        insert testQuote;

        // CRITICAL FIX: Added Pricebook2Id and OwnerExpirationNotice
        Contract c = new Contract(
            AccountId = acc.Id, Pricebook2Id = pb.Id, StartDate = Date.today().addMonths(-12), 
            EndDate = Date.today().addDays(60), Auto_Renewal__c = 'Yes', Status = 'FW_Activated_Draft', 
            OwnerExpirationNotice = '90', SBQQ__RenewalTerm__c = 12, SBQQ__Quote__c = testQuote.Id
        );
        insert c;

        Test.startTest();
            Database.executeBatch(new ContractRenewalOppBatch(), 1);
        Test.stopTest();

        Contract updated = [SELECT SBQQ__RenewalForecast__c FROM Contract WHERE Id = :c.Id];
        System.assertEquals(false, updated.SBQQ__RenewalForecast__c, 'Strategic Partner should be excluded.');
    }

    /** ❌ Scenario 3: Missing Required Account Fields & Invalid Tax ID Helper Path **/
    @IsTest
    static void testMissingRequiredAccountFields() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Pricebook2 pb = getPricebook();
        
        // Setup an Account with completely empty details and a generic '00000' Tax ID to hit the isInvalidTaxId block
        Account acc = new Account(
            Name = 'Missing Fields Account',  
            Tax_ID__c = '000-00'
        );
        insert acc;

        Opportunity opp = new Opportunity(AccountId = acc.Id, Name = 'Missing Opp', StageName = 'Discovery/Qualifying', CloseDate = Date.today().addMonths(3), Opp_Bypass_DateTime__c = System.now());
        insert opp;

        Contact billingCon = new Contact(FirstName = 'Test', LastName = 'User', AccountId = acc.Id, Contact_Automation_Bypass_DateTime__c = System.now());
        insert billingCon;

        insert new OpportunityContactRole(OpportunityId = opp.Id, ContactId = billingCon.Id, Role = 'Decision Maker', IsPrimary = true);

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Status__c = 'Client Approved', SBQQ__Account__c = acc.Id, SBQQ__Opportunity2__c = opp.Id, Quote_Bypass_DateTime__c = System.now());
        insert testQuote;

        // CRITICAL FIX: Added Pricebook2Id and OwnerExpirationNotice
        Contract c = new Contract(
            AccountId = acc.Id, Pricebook2Id = pb.Id, StartDate = Date.today().addMonths(-12), 
            EndDate = Date.today().addDays(60), Auto_Renewal__c = 'Yes', Status = 'FW_Activated_Draft', 
            OwnerExpirationNotice = '90', SBQQ__RenewalTerm__c = 12, SBQQ__Quote__c = testQuote.Id
        );
        insert c;

        Test.startTest();
            Database.executeBatch(new ContractRenewalOppBatch(), 1);
        Test.stopTest();

        Contract updated = [SELECT SBQQ__RenewalForecast__c FROM Contract WHERE Id = :c.Id];
        System.assertEquals(false, updated.SBQQ__RenewalForecast__c, 'Should remain false due to validation failures');
    }
}