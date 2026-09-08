@IsTest
private class QuoteDeleteControllerTest {

    @TestSetup
    static void makeData(){
        // Create a common Account
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

        // Create billing contact
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

        // Create an Opportunity for most tests (New Business, Open)
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity - New Business',
            AccountId = acct.getId(),
            StageName = 'Discovery/Qualifying',
            CloseDate = Date.today().addMonths(1),
            Type = 'New Business'
        );
        Database.SaveResult oppty = Database.insert(opp);

        // Create a deletable quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acct.getId(),
            SBQQ__Opportunity2__c = oppty.getId(),
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addMonths(12)
            //Quote_Bypass_DateTime__c = System.now()
            //Billing_Contact__c = contact.getId()
        );
        insert testQuote;

        // Create an Opportunity that is Closed
        Opportunity closedOpp = new Opportunity(
            Name = 'Test Opportunity - Closed',
            AccountId = acct.getId(),
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Type = 'New Business',
            sbaa__ApprovalStatus__c = 'Approved'
        );
        Database.SaveResult insertedClosedOpp = Database.insert(closedOpp);

        // Create a Quote for the Closed Opportunity
        SBQQ__Quote__c quoteOnClosedOpp = new SBQQ__Quote__c(
            SBQQ__Account__c = acct.getId(),
            SBQQ__Opportunity2__c = insertedClosedOpp.getId(),
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addMonths(12)
            //Quote_Bypass_DateTime__c = System.now()
            //Billing_Contact__c = contact.getId()
        );
        insert quoteOnClosedOpp;
        


        // Create an Opportunity that is not 'New Business'
        Opportunity renewalTypeOpp = new Opportunity(
            Name = 'Test Opportunity - Amendment',
            AccountId = acct.getId(),
            StageName = 'Discovery/Qualifying',
            CloseDate = Date.today().addMonths(1),
            Type = 'Renewal'
        );
        Database.SaveResult insertedRenewalTypeOpp = Database.insert(renewalTypeOpp);

        // Create a Quote for the non 'New Business' Opportunity
        SBQQ__Quote__c quoteOnOtherTypeOpp = new SBQQ__Quote__c(
            SBQQ__Account__c = acct.getId(),
            SBQQ__Opportunity2__c = insertedRenewalTypeOpp.getId(),
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addMonths(12)
            //Quote_Bypass_DateTime__c = System.now()
            //Billing_Contact__c = contact.getId()
        );
        insert quoteOnOtherTypeOpp;

        // Create Quotes with various approval statuses on the main 'New Business' Opp
        SBQQ__Quote__c approvedQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acct.getId(),
            SBQQ__Opportunity2__c = oppty.getId(),
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addMonths(12),
            Quote_Bypass_DateTime__c = System.now(),
            //Billing_Contact__c = contact.getId(),
            ApprovalStatus__c = 'Approved'
        );
        insert approvedQuote;

        SBQQ__Quote__c pendingQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acct.getId(),
            SBQQ__Opportunity2__c = oppty.getId(),
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addMonths(12),
            Quote_Bypass_DateTime__c = System.now(),
            //Billing_Contact__c = contact.getId(),
            ApprovalStatus__c = 'Pending'
        );
        insert pendingQuote;

        SBQQ__Quote__c recalledQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acct.getId(),
            SBQQ__Opportunity2__c = oppty.getId(),
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addMonths(12),
            Quote_Bypass_DateTime__c = System.now(),
            //Billing_Contact__c = contact.getId(),
            ApprovalStatus__c = 'Recalled'
        );
        insert recalledQuote;
    }

    @IsTest
    static void testSuccessfulDeletion() {
        SBQQ__Quote__c deletableQuote = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE ApprovalStatus__c = null AND SBQQ__Opportunity2__r.Type = 'New Business' AND SBQQ__Opportunity2__r.IsClosed = false LIMIT 1];

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(deletableQuote);
        QuoteDeleteController controller = new QuoteDeleteController(stdController);
        PageReference pageRef = controller.tryDelete();
        Test.stopTest();

        System.assertEquals('success', controller.toastType, 'Toast type should be success.');
        System.assertEquals('The quote has been successfully deleted.', controller.toastMessage, 'Toast message for successful deletion is incorrect.');
        System.assert(pageRef == null, 'PageReference should be null as redirection is handled by toast message on component.');

        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE Id = :deletableQuote.Id];
        System.assertEquals(0, quotes.size(), 'Quote should have been deleted.');
        System.assert(!controller.getHasApexMessages(), 'There should be no Apex messages on successful deletion.');
    }

    @IsTest
    static void testDeleteOnClosedOpportunity() {
        SBQQ__Quote__c quoteOnClosedOpp = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.IsClosed = true LIMIT 1];

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(quoteOnClosedOpp);
        QuoteDeleteController controller = new QuoteDeleteController(stdController);
        PageReference pageRef = controller.tryDelete();
        Test.stopTest();

        System.assertEquals('error', controller.toastType, 'Toast type should be error.');
        System.assertEquals('You can\'t delete quotes on closed opportunities.', controller.toastMessage, 'Toast message for closed opportunity is incorrect.');
        System.assert(pageRef == null, 'PageReference should be null.');

        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE Id = :quoteOnClosedOpp.Id];
        System.assertEquals(1, quotes.size(), 'Quote should not have been deleted.');
    }

    @IsTest
    static void testDeleteWithApprovedStatus() {
        SBQQ__Quote__c approvedQuote = [SELECT Id FROM SBQQ__Quote__c WHERE ApprovalStatus__c = 'Approved' LIMIT 1];

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(approvedQuote);
        QuoteDeleteController controller = new QuoteDeleteController(stdController);
        PageReference pageRef = controller.tryDelete();
        Test.stopTest();

        System.assertEquals('error', controller.toastType, 'Toast type should be error.');
        System.assertEquals('You can\'t delete quotes that are approved or pending approval.', controller.toastMessage, 'Toast message for approved status is incorrect.');
        System.assert(pageRef == null, 'PageReference should be null.');

        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE Id = :approvedQuote.Id];
        System.assertEquals(1, quotes.size(), 'Quote should not have been deleted.');
    }

    @IsTest
    static void testDeleteWithPendingStatus() {
        SBQQ__Quote__c pendingQuote = [SELECT Id FROM SBQQ__Quote__c WHERE ApprovalStatus__c = 'Pending' LIMIT 1];

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(pendingQuote);
        QuoteDeleteController controller = new QuoteDeleteController(stdController);
        PageReference pageRef = controller.tryDelete();
        Test.stopTest();

        System.assertEquals('error', controller.toastType, 'Toast type should be error.');
        System.assertEquals('You can\'t delete quotes that are approved or pending approval.', controller.toastMessage, 'Toast message for pending status is incorrect.');
        System.assert(pageRef == null, 'PageReference should be null.');

        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE Id = :pendingQuote.Id];
        System.assertEquals(1, quotes.size(), 'Quote should not have been deleted.');
    }

    @IsTest
    static void testDeleteWithRecalledStatus() {
        SBQQ__Quote__c recalledQuote = [SELECT Id FROM SBQQ__Quote__c WHERE ApprovalStatus__c = 'Recalled' LIMIT 1];

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(recalledQuote);
        QuoteDeleteController controller = new QuoteDeleteController(stdController);
        PageReference pageRef = controller.tryDelete();
        Test.stopTest();

        System.assertEquals('error', controller.toastType, 'Toast type should be error.');
        System.assertEquals('You can\'t delete quotes that are approved or pending approval.', controller.toastMessage, 'Toast message for recalled status is incorrect.');
        System.assert(pageRef == null, 'PageReference should be null.');

        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE Id = :recalledQuote.Id];
        System.assertEquals(1, quotes.size(), 'Quote should not have been deleted.');
    }

    @IsTest
    static void testDeleteOnNonNewBusinessOpportunity() {
        SBQQ__Quote__c quoteOnOtherTypeOpp = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.Type = 'Renewal' LIMIT 1];

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(quoteOnOtherTypeOpp);
        QuoteDeleteController controller = new QuoteDeleteController(stdController);
        PageReference pageRef = controller.tryDelete();
        Test.stopTest();

        System.assertEquals('error', controller.toastType, 'Toast type should be error.');
        System.assertEquals('You can only delete quotes on New Business opportunities.', controller.toastMessage, 'Toast message for non-New Business opportunity is incorrect.');
        System.assert(pageRef == null, 'PageReference should be null.');

        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE Id = :quoteOnOtherTypeOpp.Id];
        System.assertEquals(1, quotes.size(), 'Quote should not have been deleted.');
    }

    @IsTest
    static void testExceptionDuringIsQuoteDeletable() {
        // Delete the quote before the controller ccan check if the quote is deletable.
        // This will cause the controller to throw an uncaught exception.
        SBQQ__Quote__c quoteToDelete = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        delete quoteToDelete;

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(quoteToDelete);
        QuoteDeleteController controller = new QuoteDeleteController(stdController);
        PageReference pageRef = controller.tryDelete();
        Test.stopTest();

        System.assertEquals('error', controller.toastType, 'Toast type should be error for query exception.');
        System.assert(controller.toastMessage.startsWith('An unexpected error occurred while checking if the quote can be deleted:'), 'Toast message for query exception is incorrect.');
        System.assert(pageRef == null, 'PageReference should be null.');
    }

    @IsTest
    static void testGetHasApexMessages() {
        SBQQ__Quote__c deletableQuote = [SELECT Id FROM SBQQ__Quote__c WHERE ApprovalStatus__c = null AND SBQQ__Opportunity2__r.Type = 'New Business' AND SBQQ__Opportunity2__r.IsClosed = false LIMIT 1];

        ApexPages.StandardController stdController = new ApexPages.StandardController(deletableQuote);
        QuoteDeleteController controller = new QuoteDeleteController(stdController);

        System.assert(!controller.getHasApexMessages(), 'Initially, there should be no Apex messages.');

        // Add a message to simulate a scenario where messages exist
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Test error message'));
        System.assert(controller.getHasApexMessages(), 'getHasApexMessages should return true when messages exist.');
    }
}