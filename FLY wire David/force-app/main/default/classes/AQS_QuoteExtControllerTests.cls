@isTest
private class AQS_QuoteExtControllerTests {

    @TestSetup
    static void makeData() {
        Database.SaveResult acct = Database.insert(new Account(
            Name = 'Test Account',
            ShippingCountry = 'United States',
            ShippingState = 'MA',
            ShippingStreet = 'Suite 10, 141 Tremont Street',
            ShippingCity = 'Boston',
            ShippingPostalCode = '02111',
            BillingCountry = 'United States',
            BillingState = 'MA',
            BillingStreet = 'Suite 10, 141 Tremont Street',
            BillingCity = 'Boston',
            BillingPostalCode = '02111'
        ));

        Contact testContact = new Contact(
            FirstName = 'Test First Name',
            LastName='Test Last Name',
            Email = 'test@contact.com',
            //Billing_Contact__c = true,
            AccountId = acct.getId()
        );

        insert testContact;
        
        // 3. Query the existing ACR (instead of inserting a new one)
    AccountContactRelation existingAcr = [
        SELECT Id, Roles, Billing_Contact_For_Account__c 
        FROM AccountContactRelation 
        WHERE AccountId = :acct.Id 
        AND ContactId = :testContact.Id 
        LIMIT 1
    ];

    // 4. Update the existing ACR with your required values
    existingAcr.Roles = 'Decision Maker';
    existingAcr.Billing_Contact_For_Account__c = true;
    update existingAcr;

        Opportunity testOppty = new Opportunity(
            AccountId = acct.getId(), 
            Name='Test CPQOpp', StageName='Open',
            CloseDate=Date.today().addDays(30)
        );
        Database.SaveResult oppty = Database.insert(testOppty);
        
        // This satisfies the new Primary Contact Role validation rule
    OpportunityContactRole ocr = new OpportunityContactRole(
        OpportunityId = testOppty.Id,
        ContactId = testContact.Id,
        Role = 'Decision Maker', // Satisfies mandatory role requirement
        IsPrimary = true        // Satisfies 'Primary' requirement
    );
    insert ocr;

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acct.getId(),
            SBQQ__Opportunity2__c = oppty.getId(),
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addMonths(12)
            //Billing_Contact__c = contact.getId()
        );

        insert testQuote;
    }
    
    @isTest
    static void testSubmit() {
        SBQQ__Quote__c quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c LIMIT 1];
        
        Test.startTest();
        AQS_QuoteExtController con = new AQS_QuoteExtController(new ApexPages.StandardController(quote));
        con.onSubmit();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();

        System.assertEquals('Approved', quote.ApprovalStatus__c);
    }
    
    @isTest
    static void testErrorSubmit() {
        SBQQ__Quote__c quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c LIMIT 1];
        
        Test.startTest();
        AQS_QuoteExtController con = new AQS_QuoteExtController(new ApexPages.StandardController(quote));
        
        // Delete the quote in order to throw an error
        delete quote;
        
        con.onSubmit();
        Test.stopTest();
        
        con.onCancel();
    }
    
    @isTest
    static void testRecall() {
        SBQQ__Quote__c quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();
        AQS_QuoteExtController con = new AQS_QuoteExtController(new ApexPages.StandardController(quote));
        con.onRecall();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c LIMIT 1];
        Test.stopTest();

        System.assertEquals('Recalled', quote.ApprovalStatus__c);
    }
    
    @isTest
    static void testErrorRecall() {
        SBQQ__Quote__c quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c LIMIT 1];
        
        Test.startTest();
        AQS_QuoteExtController con = new AQS_QuoteExtController(new ApexPages.StandardController(quote));
        
        // Delete the quote in order to throw an error
        delete quote;
        
        con.onRecall();
        Test.stopTest();
              
        con.onCancel();
    }
}