@IsTest(SeeAllData=false)
private class LeadConversionController_NoAssert_Test {

    // ----- Helpers -----
    private static String openLeadStatus() {
        return [
            SELECT MasterLabel
            FROM LeadStatus
            WHERE IsConverted = false
            ORDER BY SortOrder
            LIMIT 1
        ].MasterLabel;
    }

    private static String anyOppStage() {
        return [SELECT MasterLabel FROM OpportunityStage ORDER BY SortOrder LIMIT 1].MasterLabel;
    }

    private static Lead makeLead(String lastName, String company) {
        return new Lead(
            LastName = lastName,
            Company  = company,
            Status   = openLeadStatus(),
            OwnerId  = UserInfo.getUserId()
        );
    }

    @testSetup
    static void data() {
        // Account seeded with billing address + payment terms for the rich account search
        Account a = new Account(
            Name            = 'Acme Medical',
            OwnerId         = UserInfo.getUserId(),
            BillingStreet   = '1 First St',
            BillingCity     = 'San Francisco',
            BillingState    = 'California',
            BillingCountry    = 'United States',
            BillingPostalCode = '94105'
        );
        a.Payment_Terms__c = 'Net 30'; // custom field used in search
        insert a;

        // A second account to broaden search results
        Account a2 = new Account(
            Name              = 'Beta Health',
            OwnerId           = UserInfo.getUserId(),
            BillingStreet     = '500 Market Ave',
            BillingCity       = 'San Jose',
            BillingState      = 'California',
            BillingCountry    = 'United States',
            BillingPostalCode = '95112'
        );
        a2.Payment_Terms__c = 'Prepay';
        insert a2;

        Contact c = new Contact(
            FirstName = 'Test',
            LastName  = 'Tester',
            AccountId = a.Id,
            Email     = 'test@example.com',
            OwnerId   = UserInfo.getUserId()
        );
        insert c;

        // Opp A
        Opportunity oA = new Opportunity(
            Name      = 'Existing Opp A',
            StageName = anyOppStage(),
            CloseDate = System.today().addDays(30),
            AccountId = a.Id,
            OwnerId   = UserInfo.getUserId()
        );
        insert oA;

        // Opp B
        Opportunity oB = new Opportunity(
            Name      = 'Existing Opp B',
            StageName = anyOppStage(),
            CloseDate = System.today().addDays(45),
            AccountId = a.Id,
            OwnerId   = UserInfo.getUserId()
        );
        insert oB;

        // Standard leads
        insert new List<Lead>{
            makeLead('ConvertToExisting', 'Acme Medical'),
            makeLead('CreateEverything',  'Brand New Co'),
            makeLead('CreateWithRT',      'Company With RT')
        };

        // Lead with prefill fields populated
        Lead prefillL = makeLead('PrefillLead', 'Prefill Co');
        prefillL.Related_Account__c = a.Id;
        prefillL.Matched_Contact__c = c.Id;
        prefillL.Opportunity__c     = 'O-0001';
        insert prefillL;
    }

    // ---------- Convert paths ----------

    @IsTest
    static void t_convert_withExisting() {
        Account a = [SELECT Id FROM Account WHERE Name = 'Acme Medical' LIMIT 1];
        Contact c = [SELECT Id FROM Contact WHERE AccountId = :a.Id LIMIT 1];
        Opportunity oA = [SELECT Id FROM Opportunity WHERE Name = 'Existing Opp A' LIMIT 1];
        Lead l = [SELECT Id FROM Lead WHERE LastName = 'ConvertToExisting' LIMIT 1];

        Test.startTest();
        LeadConversionController.convertLeadFlat(
            l.Id, a.Id, c.Id, oA.Id,
            /*createOpportunity*/ false,
            /*opportunityName*/  null,
            /*opportunityRecordTypeId*/ null
        );
        Test.stopTest();
    }

    @IsTest
    static void t_convert_createOpp_missingName() {
        Lead l = [SELECT Id FROM Lead WHERE LastName = 'ConvertToExisting' LIMIT 1];

        Test.startTest();
        LeadConversionController.convertLeadFlat(
            l.Id, null, null, null,
            /*createOpportunity*/ true,
            /*opportunityName*/  null,
            /*opportunityRecordTypeId*/ null
        );
        Test.stopTest();
    }

    @IsTest
    static void t_convert_createsNewOpp() {
        Lead l = [SELECT Id FROM Lead WHERE LastName = 'CreateEverything' LIMIT 1];

        Test.startTest();
        LeadConversionController.convertLeadFlat(
            l.Id, null, null, null,
            /*createOpportunity*/ true,
            /*opportunityName*/  'New Opp From Convert',
            /*opportunityRecordTypeId*/ null
        );
        Test.stopTest();
    }

    @IsTest
    static void t_convert_createOpp_withRecordTypeIfAvailable() {
        Lead l = [SELECT Id FROM Lead WHERE LastName = 'CreateWithRT' LIMIT 1];
        Id rtId = null;
        List<RecordType> rts = [
            SELECT Id FROM RecordType
            WHERE SobjectType = 'Opportunity' AND IsActive = true
            ORDER BY Name ASC LIMIT 1
        ];
        if (!rts.isEmpty()) rtId = rts[0].Id;

        Test.startTest();
        LeadConversionController.convertLeadFlat(
            l.Id, null, null, null,
            /*createOpportunity*/ true,
            /*opportunityName*/  'Opp With RT',
            /*opportunityRecordTypeId*/ rtId
        );
        Test.stopTest();
    }

    // createOpportunity == true with existing OppId -> must also pass that Opp's AccountId
    @IsTest
    static void t_convert_useExistingOpp_evenWhenCreateTrue() {
        Opportunity oB = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Existing Opp B' LIMIT 1];
        Lead l = [SELECT Id FROM Lead WHERE LastName = 'ConvertToExisting' LIMIT 1];

        Test.startTest();
        LeadConversionController.convertLeadFlat(
            l.Id,
            /* accountId */ oB.AccountId,
            /* contactId  */ null,
            /* opportunityId */ oB.Id,
            /* createOpportunity */ true,
            /* opportunityName  */ null,
            /* opportunityRecordTypeId */ null
        );
        Test.stopTest();
    }

    @IsTest
    static void t_convert_nullLeadId() {
        Test.startTest();
        LeadConversionController.convertLeadFlat(
            /*leadId*/ null, null, null, null, false, null, null
        );
        Test.stopTest();
    }

    // ---------- Lookups & picklists ----------

    @IsTest
    static void t_lookup_contacts_for_account() {
        Account a = [SELECT Id FROM Account WHERE Name = 'Acme Medical' LIMIT 1];

        Test.startTest();
        LeadConversionController.searchContactsForAccount(a.Id, 'Test', 10);
        Test.stopTest();
    }

    @IsTest
    static void t_lookup_contacts_edgecases() {
        Account a = [SELECT Id FROM Account WHERE Name = 'Acme Medical' LIMIT 1];

        Test.startTest();
        LeadConversionController.searchContactsForAccount(a.Id, '', 10);   // blank term
        LeadConversionController.searchContactsForAccount(null, 'Test', 10); // null account
        Test.stopTest();
    }

    @IsTest
    static void t_lookup_opportunities_by_number_variants() {
        Test.startTest();
        LeadConversionController.searchOpportunitiesByNumber('O-0001', 10); // non-numeric
        LeadConversionController.searchOpportunitiesByNumber('0001', 10);   // numeric (exact -> maybe fallback)
        LeadConversionController.searchOpportunitiesByNumber('12345', 10);  // numeric exact
        LeadConversionController.searchOpportunitiesByNumber('', 10);       // blank term
        Test.stopTest();
    }

    @IsTest
    static void t_get_opportunity_record_types() {
        Test.startTest();
        LeadConversionController.getOpportunityRecordTypes();
        Test.stopTest();
    }

    // ---------- Prefill ----------

    @IsTest
    static void t_getLeadPrefill_populated() {
        Lead l = [SELECT Id FROM Lead WHERE LastName = 'PrefillLead' LIMIT 1];

        Test.startTest();
        LeadConversionController.getLeadPrefill(l.Id);
        Test.stopTest();
    }

    @IsTest
    static void t_getLeadPrefill_null() {
        Test.startTest();
        LeadConversionController.getLeadPrefill(null);
        Test.stopTest();
    }

    // ---------- NEW: Account rich search (name, address, payment terms) ----------

    @IsTest
    static void t_searchAccountsRich_byName() {
        Test.startTest();
        LeadConversionController.searchAccountsRich('Acme', 10);
        Test.stopTest();
    }

    @IsTest
    static void t_searchAccountsRich_byAddress() {
        Test.startTest();
        LeadConversionController.searchAccountsRich('San Jose', 10);      // city
        LeadConversionController.searchAccountsRich('94105', 10);         // postal from Acme
        LeadConversionController.searchAccountsRich('Market', 10);        // street from Beta
        Test.stopTest();
    }

    @IsTest
    static void t_searchAccountsRich_byPaymentTerms_and_blank() {
        Test.startTest();
        LeadConversionController.searchAccountsRich('Net 30', 10);  // Payment_Terms__c
        LeadConversionController.searchAccountsRich('', 10);        // early return
        Test.stopTest();
    }
}