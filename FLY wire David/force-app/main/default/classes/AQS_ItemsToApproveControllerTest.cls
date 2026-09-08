@isTest
private class AQS_ItemsToApproveControllerTest
{
    @isTest static void testDataInit()
    {
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User testUser = new User(Alias = 'test',
                                Email='testUser1@flywire.com', 
                                EmailEncodingKey='UTF-8',
                                LastName='TestLastName',
                                LanguageLocaleKey='en_US',
                                LocaleSidKey='en_US',
                                ProfileId = testProfile.Id,
                                TimeZoneSidKey='America/Los_Angeles',
                                UserName='userEmail4306@flywire.com');
        insert testUser;

        //add user to a group
        Group testGroup = new Group(Name = 'testGroup');
        insert testGroup;

        GroupMember testMember = new GroupMember(GroupId = testGroup.Id, UserOrGroupId = testUser.Id);
        insert testMember;


        System.runAs(testUser)
        {
            
            Product2 testProduct = new Product2(Name='Test Product');    
            insert testProduct;

            //Id pricebookId = Test.getStandardPricebookId();
            //insert pricebookId;
             
            Account testAccount = new Account(
                name='Test CPQAccount', 
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
            );
            Database.SaveResult insertedAcct = Database.insert(testAccount);
            
            Contact testContact = new Contact(FirstName = 'Test First Name',
                                                LastName='Test Last Name',
                                                Email = 'test@contact.com',
                                                //Billing_Contact__c = true,
                                                AccountId = insertedAcct.getId());
            Database.SaveResult sr = Database.insert(testContact);
            String contactId = sr.getId();
            
             AccountContactRelation existingAcr = [
        SELECT Id, Roles, Billing_Contact_For_Account__c 
        FROM AccountContactRelation 
        WHERE AccountId = :insertedAcct.Id 
        AND ContactId = :testContact.Id 
        LIMIT 1
    ];

    // 4. Update the existing ACR with your required values
    existingAcr.Roles = 'Decision Maker';
    existingAcr.Billing_Contact_For_Account__c = true;
    update existingAcr;
            
            
            
            Opportunity testOppty = new Opportunity(AccountId = testAccount.Id, 
                                                    Name='Test CPQOpp', StageName='Open',
                                                    CloseDate=Date.today().addDays(30));
            insert testOppty;
            
            OpportunityContactRole ocr = new OpportunityContactRole(
    		OpportunityId = testOppty.Id,
    	ContactId = testContact.Id,
    	Role = 'Decision Maker', // Satisfies your mandatory role requirement
    		IsPrimary = true        // Satisfies the 'Primary Contact Role' validation requirement
			);
			insert ocr;
            
            SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Account__c = testAccount.Id,
                                                    SBQQ__Opportunity2__c = testOppty.Id,
                                                    SBQQ__StartDate__c = Date.today(),
                                                    SBQQ__EndDate__c = Date.today().addMonths(12));
                                                   // Billing_Contact__c = contactId);
            insert testQuote;

            SBQQ__Quote__c testQuote2 = new SBQQ__Quote__c(SBQQ__Account__c = testAccount.Id,
                                                    SBQQ__Opportunity2__c = testOppty.Id,
                                                    SBQQ__StartDate__c = Date.today(),
                                                    SBQQ__EndDate__c = Date.today().addMonths(12));
                                                   // Billing_Contact__c = contactId);
            insert testQuote2;

            
            SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__StartDate__c = Date.today(),
                                                                    SBQQ__EndDate__c = Date.today().addMonths(12),
                                                                    SBQQ__Product__c = testProduct.Id,                                                      
                                                                    SBQQ__Quote__c = testQuote.Id);
            insert testQuoteLine;
            
            SBAA__ApprovalRule__c testApprovalRuleQuote = new SBAA__ApprovalRule__c(Name='Test Approval Rule',
                                                                                SBAA__TargetObject__c = 'SBQQ__Quote__c',
                                                                                SBAA__ApprovalStep__c = 10);
            insert testApprovalRuleQuote;

            
            SBAA__Approver__c testApprover = new SBAA__Approver__c(Name = UserInfo.getUserName(),
                                                                    SBAA__User__c = UserInfo.getUserId());
            insert testApprover;
            
            SBAA__Approval__c testQuoteApproval = new SBAA__Approval__c(SBAA__Status__c = 'Requested',
                                                                    SBAA__RecordField__c = 'AQS_Quote__c',
                                                                    SBAA__ApprovalStep__c = 10,
                                                                    SBAA__Rule__c = testApprovalRuleQuote.Id,
                                                                    SBAA__AssignedTo__c = UserInfo.getUserId(),
                                                                    AQS_Quote__c = testQuote.Id );

            insert testQuoteApproval;

            SBAA__Approval__c testQuoteApproval2 = new SBAA__Approval__c(SBAA__Status__c = 'Approved',
                                                                    SBAA__RecordField__c = 'AQS_Quote__c',
                                                                    SBAA__ApprovalStep__c = 10,
                                                                    SBAA__Rule__c = testApprovalRuleQuote.Id,
                                                                    SBAA__AssignedTo__c = UserInfo.getUserId(),
                                                                    AQS_Quote__c = testQuote2.Id );

            insert testQuoteApproval2;
          
             
            Test.startTest();
            AQS_ItemsToApproveController testController = new AQS_ItemsToApproveController(); 

            // Approval.ProcessSubmitRequest submitApproval = new Approval.ProcessSubmitRequest();
            // submitApproval.setObjectId(testQuote2.id);
            // submitApproval.setSubmitterId(testUser.Id);

            // submitApproval.setProcessDefinitionNameOrId('Approval_Process');
            // submitApproval.setSkipEntryCriteria(true);

            // Approval.ProcessResult result = Approval.process(submitApproval);
            // System.assert(result.isSuccess());

            // System.assertEquals(
            //     'Pending', result.getInstanceStatus(),   
            //     'Instance Status'+result.getInstanceStatus()
            //     );

            Test.stopTest();
        }
    }
}