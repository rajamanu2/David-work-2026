/**
 * Test class for ContractRenewalOppBatch.
 * Validates renewal forecasting logic by verifying Account fields and 
 * AccountContactRelation (ACR) based Billing Contact requirements.
 * * Note: Slack notifications are bypassed via naming conventions ("Flywire" in Account Name, 
 * "Test" in Opportunity Name) as per the Record-Triggered Flow configuration.
 */
@IsTest
public class ContractRenewalOpportunityBatchTest {

    private static final Id RUNNING_USER_ID = UserInfo.getUserId();

    // --- MOCK IMPLEMENTATION (Required for all HTTP callouts) ---
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody('{"status": "success", "message": "Mock callout complete."}');
            return res;
        }
    }

    // --- Helper Methods ---

    /**
     * Safely retrieves a Record Type Id by Developer Name.
     * Uses your specific record types: Education, B2B, Travel, Strategic_Partner.
     */
    private static Id getAccountRecordTypeId(String developerName) {
        Id recordTypeId;
        try {
            recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
        } catch (Exception e) {
            // Fallback to name if developer name check fails
            for(Schema.RecordTypeInfo rt : Account.SObjectType.getDescribe().getRecordTypeInfos()) {
                if(rt.getName() == developerName) return rt.getRecordTypeId();
            }
            recordTypeId = Schema.SObjectType.Account.getRecordTypeInfos()[0].getRecordTypeId();
        }
        return recordTypeId;
    }

    /**
     * Helper to create a valid ACR for an Account and ensure the rollup flag is set.
     */
    private static void createValidACR(Account acc) {
        Contact con = new Contact(
            FirstName = 'John', 
            LastName = 'Billing', 
            Email = 'john.billing@flywire.com', 
            AccountId = acc.Id, 
            Inactive__c = false,
            Billing_Contact__c = true, // Satisfies potential rollup dependencies
            // 🛑 BYPASS logic for Contact automation
            Contact_Automation_Bypass_DateTime__c = System.now().addHours(-1)
        ); 
        insert con;

        // Fetch the ACR created automatically by the Contact insert
        AccountContactRelation acr = [
            SELECT Id, Billing_Contact_For_Account__c, Roles 
            FROM AccountContactRelation 
            WHERE AccountId = :acc.Id AND ContactId = :con.Id 
            LIMIT 1
        ];

        acr.Billing_Contact_For_Account__c = true;
        acr.Roles = 'Decision Maker;Business User'; // Satisfies VALID_ROLES check in Batch
        update acr;

        // Manually update the flag on Account as required by Batch Logic
        // Handled in try-catch in case it is a system-calculated Rollup Summary
        try {
            acc.Has_Billing_Contact__c = true;
            update acc;
        } catch (Exception e) {
            System.debug('Account Has_Billing_Contact__c update handled: ' + e.getMessage());
        }
    }

    // --- TEST METHODS ---
    
    /** ✅ Scenario 1: Valid Contract Renewal (Success Path) **/
    @IsTest
    static void testValidRenewalScenario() {
        // --- 1. SET MOCKS ---
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Date contractEndDate = Date.today().addDays(30);
        Date contractStartDate = contractEndDate.addMonths(-12);
        
        // --- 2. SETUP DATA ---
        // Record Type MUST be assigned and NOT Strategic_Partner for SOQL pickup
        Id eduRtId = getAccountRecordTypeId('Education');

        // Name contains 'Flywire' to satisfy flow bypass
        Account acc = new Account(
            Name = 'Flywire Renewal Account', 
            RecordTypeId = eduRtId,
            Client_Legal_Entity_Name__c = 'Edu Corp', 
            Tax_ID__c = 'TX123456', 
            Separate_Legal_Entity_Tax_ID__c = 'No', 
            OwnerId = RUNNING_USER_ID,
            Relationship_Manager__c = RUNNING_USER_ID, 
            BillingStreet = '123 Main St', BillingCity = 'New York', BillingState = 'NY', BillingPostalCode = '10001', BillingCountry = 'United States',
            ShippingStreet = '456 Ship St', ShippingCity = 'New York', ShippingState = 'NY', ShippingPostalCode = '10001', ShippingCountry = 'United States'
        ); 
        insert acc;

        createValidACR(acc);

        Pricebook2 pb = new Pricebook2(Name = 'CPQ', IsActive = true); 
        insert pb;
        
        // Opportunity: Name contains 'Test' to satisfy flow bypass
        Opportunity opp = new Opportunity(
            AccountId = acc.Id, 
            Name = 'Test Renewal Opp Name', 
            StageName = 'Discovery/Qualifying', 
            CloseDate = Date.today().addMonths(3), 
            Opp_Bypass_DateTime__c = System.now().addHours(-1) 
        );
        insert opp;
        
        // Quote Setup: Sequential status transition logic applied
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Status__c = 'Draft', 
            SBQQ__Account__c = acc.Id, 
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true, 
            Owner_Expiration_Notice__c = '90', // Required by Batch
            No_Approvals_Required__c = true
        ); 
        insert testQuote;

        // Transitions: Draft -> FW Approved -> Client_Approved (API Name)
        testQuote.SBQQ__Status__c = 'FW Approved';
        update testQuote;

        testQuote.SBQQ__Status__c = 'Client_Approved';
        update testQuote;

        Contract c = new Contract(
            AccountId = acc.Id, 
            Pricebook2Id = pb.Id, 
            StartDate = contractStartDate, 
            EndDate = contractEndDate,
            ContractTerm = 12,
            Auto_Renewal__c = 'Yes', 
            SBQQ__RenewalForecast__c = false, 
            Status = 'FW_Activated_Draft', 
            SBQQ__RenewalTerm__c = 12, 
            SBQQ__Quote__c = testQuote.Id, 
            OwnerId = RUNNING_USER_ID
        );
        insert c;

        // --- 3. EXECUTION ---
        Test.startTest();
            Database.executeBatch(new ContractRenewalOppBatch(), 1);
        Test.stopTest(); 

        // --- 4. ASSERTIONS ---
        Contract updated = [SELECT SBQQ__RenewalForecast__c FROM Contract WHERE Id = :c.Id];
        System.assertEquals(true, updated.SBQQ__RenewalForecast__c, 'Renewal Forecast should be TRUE when valid ACR and Account fields exist.');
    }
    
    /** ❌ Scenario 2: Strategic Partner Excluded **/
    @IsTest
    static void testStrategicPartnerExclusion() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Id partnerRtId = getAccountRecordTypeId('Strategic_Partner');
        Account acc = new Account(
            Name = 'Flywire Strategic Account', 
            RecordTypeId = partnerRtId, 
            Client_Legal_Entity_Name__c = 'Strategic Corp',
            Tax_ID__c = 'TX123456', Separate_Legal_Entity_Tax_ID__c = 'No', OwnerId = RUNNING_USER_ID,
            BillingStreet = '123 Main St', BillingCity = 'New York', BillingState = 'NY', BillingPostalCode = '10001', BillingCountry = 'United States',
            ShippingStreet = '456 Ship St', ShippingCity = 'New York', ShippingState = 'NY', ShippingPostalCode = '10001', ShippingCountry = 'United States'
        ); 
        insert acc;
        
        createValidACR(acc);
        Pricebook2 pb = new Pricebook2(Name = 'CPQ', IsActive = true); insert pb;
        
        Contract c = new Contract(
            AccountId = acc.Id, Pricebook2Id = pb.Id, StartDate = Date.today().addMonths(-12), 
            EndDate = Date.today().addDays(30), Auto_Renewal__c = 'Yes', 
            SBQQ__RenewalForecast__c = false, Status = 'FW_Activated_Draft'
        );
        insert c;

        Test.startTest();
            Database.executeBatch(new ContractRenewalOppBatch(), 1);
        Test.stopTest();

        Contract updated = [SELECT SBQQ__RenewalForecast__c FROM Contract WHERE Id = :c.Id];
        System.assertEquals(false, updated.SBQQ__RenewalForecast__c, 'Strategic Partner contracts must be skipped by the locator.');
    }

    /** ❌ Scenario 3: Missing Required Account Fields **/
    @IsTest
    static void testMissingRequiredAccountFields() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Id eduRtId = getAccountRecordTypeId('Education');
        Account acc = new Account(
            Name = 'Flywire Missing Fields Account', 
            RecordTypeId = eduRtId,
            Client_Legal_Entity_Name__c = null, Tax_ID__c = null, Separate_Legal_Entity_Tax_ID__c = 'No',
            BillingStreet = '123 Main St', BillingCity = 'New York', BillingState = 'NY', BillingPostalCode = '10001', BillingCountry = 'United States',
            ShippingStreet = '456 Ship St', ShippingCity = 'New York', ShippingState = 'NY', ShippingPostalCode = '10001', ShippingCountry = 'United States'
        ); 
        insert acc;
        
        createValidACR(acc);
        Pricebook2 pb = new Pricebook2(Name = 'CPQ', IsActive = true); insert pb;

        Contract c = new Contract(
            AccountId = acc.Id, Pricebook2Id = pb.Id, StartDate = Date.today().addMonths(-12), 
            EndDate = Date.today().addDays(30), Auto_Renewal__c = 'Yes', 
            SBQQ__RenewalForecast__c = false, Status = 'FW_Activated_Draft'
        );
        insert c;

        Test.startTest();
            Database.executeBatch(new ContractRenewalOppBatch(), 1);
        Test.stopTest();

        Contract updated = [SELECT SBQQ__RenewalForecast__c FROM Contract WHERE Id = :c.Id];
        System.assertEquals(false, updated.SBQQ__RenewalForecast__c, 'Forecast should be FALSE if Account fields are missing.');
    }
}