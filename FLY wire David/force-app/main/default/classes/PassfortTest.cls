@IsTest
private class PassfortTest {
    
    @testSetup static void setup() {
        
		Id educationRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Education').getRecordTypeId();
    
        list<Account> accList = new list<account>();    
        Account testAccVar = new Account();
        testAccVar.Name = 'Test Account';
        testAccVar.RecordTypeId = educationRecordTypeId;
        testAccVar.Passfort_Profile_Id__c = 'e3e8d2c3-62cd-4cb2-9dfd-26bac7ecead5';
        //insert testAccVar;        
        accList.add(testAccVar);
        
        
        Account testAccVar1 = new Account();
        testAccVar1.Name = 'Test Account';
        testAccVar1.RecordTypeId = educationRecordTypeId;
        testAccVar1.Passfort_Profile_Id__c = passfortprofileId;
        accList.add(testAccVar1);
        insert accList;        
    }
    
    
    // Test the successful processing of a valid webhook request
    @IsTest static void testValidWebhookRequest() {
        // Mock a valid request
        Test.setMock(HttpCalloutMock.class, new PassfortWebhookMock());
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        
        req.requestBody = Blob.valueOf('[{"id":"a05452d3-f269-11ee-a1db-ce02ad84a102","event":"CUSTOMER_REQUEST_CHANGED","data":{"profile_id":"e3e8d2c3-62cd-4cb2-9dfd-26bac7ecead5"}}]');

        Test.startTest();
        // Call the method to test
        PassfortWebhook.handlePostBatch();
        Test.stopTest();
        
        // Verify the response
        System.assertEquals(200, res.statusCode);
        System.debug(res.responseBody.toString());
        //System.assert(res.responseBody.toString().contains('"success":true'));

        // Verify that a log record was created
        Passfort_Webhook_Log__c logRecord = [SELECT Id, Request_body__c, Message__c, Status__c FROM Passfort_Webhook_Log__c LIMIT 1];
        System.assertNotEquals(null, logRecord);
    }
    
    // Test handling of an invalid request (request missing profileIds)
    @IsTest static void testNoProfileIdsWebhookRequest() {
        // Mock an invalid request (no 'data' object)
        Test.setMock(HttpCalloutMock.class, new PassfortWebhookMock());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        req.requestBody = Blob.valueOf('[{"id":"a05452d3-f269-11ee-a1db-ce02ad84a102","event":"CUSTOMER_REQUEST_CHANGED"}]');
        
        Test.startTest();
        // Call the method to test
        PassfortWebhook.handlePostBatch();
        Test.stopTest();
        
        // Verify the response
        System.assertEquals(200, res.statusCode);
		System.debug(res.responseBody.toString());
        System.assert(res.responseBody.toString().contains('"success":false'));
        System.assert(res.responseBody.toString().contains('profileIds not found'));
    }

	// Test handling of an invalid request (missing 'data' object)
    @IsTest static void testInvalidWebhookRequest() {
        // Mock an invalid request (no 'data' object)
        Test.setMock(HttpCalloutMock.class, new PassfortWebhookMock());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        req.requestBody = Blob.valueOf('{"id":"a05452d3-f269-11ee-a1db-ce02ad84a102","event":"CUSTOMER_REQUEST_CHANGED","data":{"profile_id":"e3e8d2c3-62cd-4cb2-9dfd-26bac7ecead5"}}');
        
        Test.startTest();
        // Call the method to test
        PassfortWebhook.handlePostBatch();
        Test.stopTest();
        
        // Verify the response
        System.assertEquals(500, res.statusCode);
        System.assert(res.responseBody.toString().contains('"success":false'));
		// request should be an array of items, not single item
        System.assert(res.responseBody.toString().contains('Invalid conversion from runtime'));
    }
    

    @isTest static void testGetProfileDetails() {
        // Set the mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        Test.startTest();
        HttpResponse response = Passfort.getProfileDetails('profile123');
        Test.stopTest();
        
        // Verify mock response is returned
        String contentType = response.getHeader('Content-Type');
        System.assertEquals('application/json', contentType);
        String actualValue = response.getBody();
        String expectedValue = '{"profile": {"id": "profile123", "name": "John Doe"}}';
        System.assertEquals(expectedValue, actualValue);
        System.assertEquals(200, response.getStatusCode());
    }

    @isTest static void testGetProfileApplications() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        HttpResponse response = Passfort.getProfileApplications('profile123');
        Test.stopTest();
        
        String actualValue = response.getBody();
        String expectedValue = '{"applications": [{"id": "app123", "status": "completed"}]}';
        System.assertEquals(expectedValue, actualValue);
        System.assertEquals(200, response.getStatusCode());
    }

    @isTest static void testGetProductApplication() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        HttpResponse response = Passfort.getProductApplication('profile123', 'app123');
        Test.stopTest();
        
        String actualValue = response.getBody();
        String expectedValue = '{"application": {"id": "app123", "status": "completed"}}';
        System.assertEquals(expectedValue, actualValue);
        System.assertEquals(200, response.getStatusCode());
    }
    
    
    @isTest static void testGetProfileDetailsException() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        HttpResponse response = Passfort.getProfileDetails('errorProfile');
        Test.stopTest();

        // Verify that the response indicates an error
        System.assertEquals(500, response.getStatusCode());
        System.assert(response.getBody().contains('Callout error: Intentional Callout Exception'));
    }

    @isTest static void testGetProfileApplicationsException() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        HttpResponse response = Passfort.getProfileApplications('errorProfile');
        Test.stopTest();

        System.assertEquals(500, response.getStatusCode());
        System.assert(response.getBody().contains('Callout error: Intentional Callout Exception'));
    }

    @isTest static void testGetProductApplicationException() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        HttpResponse response = Passfort.getProductApplication('errorProfile', 'app123');
        Test.stopTest();

        System.assertEquals(500, response.getStatusCode());
        System.assert(response.getBody().contains('Callout error: Intentional Callout Exception'));
    }

    

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String endpoint = req.getEndpoint();
            
            // Condition to simulate a callout exception
            if (endpoint.contains('errorProfile')) {
                throw new System.CalloutException('Intentional Callout Exception');
            }
            
            if(endpoint.contains('applications')) {
                if(endpoint.endsWith('applications')) {
                    res.setBody('{"applications": [{"id": "app123", "status": "completed"}]}');
                } else {
                    res.setBody('{"application": {"id": "app123", "status": "completed"}}');
                }
            } else {
                res.setBody('{"profile": {"id": "profile123", "name": "John Doe"}}');
            }
            res.setStatusCode(200);
            return res;
        }
    }
    
    private class PassfortMockResponse implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(passfortResponseJSONString);
            res.setStatusCode(200); 
            return res;
        }
    }
   
    private class PassfortWebhookMock implements HttpCalloutMock {
        // This method is required by the HttpCalloutMock interface
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            // Determine the response based on the request body
            String reqBody = req.getBody();
            if(reqBody.contains('data:')) {
                // Simulate a success response
                res.setBody('{"success": true, "message": "Profile updated successfully", "profileId": "e3e8d2c3-62cd-4cb2-9dfd-26bac7ecead5"}');
                res.setStatusCode(200);
            } else {
                // Simulate a failure response
                res.setBody('{"success": false, "message": "Error in updating Account/KYC record.", "profileId": ""}');
                res.setStatusCode(400); // Use appropriate status code for failure
            }
    
            return res;
        }
    }
    /*
    static testMethod void testPassfortProfileDeserialization() {
        // Define the JSON string
        String jsonString = '{' +
            '"id": "e3e8d2c3-62cd-4cb2-9dfd-26bac7ecead5",' +
            '"collected_data": {' +
                '"custom_fields_data": {' +
                    '"s_address_check": "Passed",' +
                    '"s_delivery_channel": "Online",' +
                    '"s_entity_type": "INDIVIDUAL",' +
                    '"d_review_date": "2023-04-01",' +
            		'"s_company_id": "salesforce_account_id",' +
            
                    '"s_website_url": "http://example.com"' +
                '},' +
                '"customer_ref": "CUST12345",' +
                '"entity_type": "INDIVIDUAL",' +
                '"personal_details": {' +
                    '"name": {' +
                        '"given_names": ["John", "Alexander"],' +
                        '"family_name": "Doe"' +
                    '},' +
                    '"dob": "1980-01-01",' +
                    '"nationality": "GBR",' +
                    '"gender": "M"' +
                '},' +
                '"address_history": [{' +
                    '"address": {' +
                        '"type": "STRUCTURED",' +
                        '"country": "GBR",' +
                        '"postal_code": "W1 2ZT",' +
                        '"locality": "London",' +
                        '"route": "Crown Street",' +
                        '"street_number": "38"' +
                    '},' +
                    '"start_date": "2015-01",' +
                    '"end_date": "2023-03"' +
                '}]' +
            '},' +
            '"applications": [{' +
                '"id": "app123",' +
                '"product": {' +
                    '"name": "Standard Checking"' +
                '},' +
                '"status": "APPLIED"' +
            '}],' +
            '"risk": {' +
                '"overall_risk": {' +
                    '"category": "Low",' +
                    '"score": 2.5' +
                '}' +
            '},' +
            '"checks": [{' +
                '"check_type": "Identity Verification",' +
                '"output_data": {' +
                    '"metadata": {' +
                        '"name": "John Doe",' +
                        '"incorporation_date": "1999-05-21"' +
                    '}' +
                '}' +
            '}]' +
        '}';

        // Deserialize the JSON string into an instance of PassfortProfile
        PassfortProfile profile = PassfortProfile.parse(jsonString);
        
        // Assert various properties to ensure they have been deserialized correctly
        System.assertEquals('e3e8d2c3-62cd-4cb2-9dfd-26bac7ecead5', profile.id);
        System.assertEquals('Passed', profile.collected_data.custom_fields_data.s_address_check);
        System.assertEquals('INDIVIDUAL', profile.collected_data.entity_type);
        System.assertEquals('John', profile.collected_data.personal_details.name.given_names[0]);
        System.assertEquals('Low', profile.risk.overall_risk.category);

        // Add more assertions as necessary to cover the fields you're interested in
    }
    */
    
    static testMethod void testPassfortProfileDeserialization1() {
      
        // Deserialize the JSON string into an instance of PassfortProfile
        PassfortProfile profile = PassfortProfile.parse(passfortResponseJSONString);
        
        // Assert various properties to ensure they have been deserialized correctly
        System.assertEquals('ede087b2-c8de-406f-bce4-876af7922acd', profile.id);
        System.assertEquals('yes', profile.collected_data.custom_fields_data.s_address_check);
        System.debug('history: ' + profile.applications[0].history);
        Assert.isNotNull(profile.applications[0].history[0].statusDate);
    }
    
    @isTest
    static void testUpdateAccountWithValidProfileId() {
        
        Test.setMock(HttpCalloutMock.class, new PassfortMockResponse());

        // Mock Account
        //Account account = new Account(Name = 'Test Account', Passfort_Profile_Id__c = passfortprofileId);
        //insert account;

        // Test
        Test.startTest();
        try{
			Passfort_Webhook_Log__c log = new Passfort_Webhook_Log__c();
            PassfortUtil.PassfortProfileProcessingWrapper wrapper = PassfortUtil.updateAccout(passfortprofileId, log);
        }catch(Exception e){
            system.debug('exception thrown in testUpdateAccountWithValidProfileId'+e.getmessage());
        }
        
        Test.stopTest();

        // Verify
        //Account updatedAccount = [SELECT Passfort_Profile_Id__c, KYC_Risk_Level__c, KYC_Risk_Score__c FROM Account WHERE Id = :account.Id];
        //System.assertEquals(profileId, updatedAccount.Passfort_Profile_Id__c);
        //System.assert(logMessage.contains('Updated Account Id: ' + account.Id));
    }

    
    private static String passfortprofileId = 'ede087b2-c8de-406f-bce4-876af7922acd';
    private static String passfortResponseJSONString = '{'+
		'    \"applications\": ['+
		'        {'+
		'            \"approval_blockers\": ['+
		'                {'+
		'                    \"blocker_type\": \"INCOMPLETE_TASK\",'+
		'                    \"task_type\": \"COMPANY_ASSESS_OWNERSHIP\",'+
		'                    \"task_variant\": {'+
		'                        \"id\": \"c776efb7-9ba9-4014-a788-b94e81ffd4e9\",'+
		'                        \"name\": \"Assess company ownership\",'+
		'                        \"task_type\": \"COMPANY_ASSESS_OWNERSHIP\"'+
		'                    }'+
		'                },'+
		'                {'+
		'                    \"blocker_type\": \"INCOMPLETE_TASK\",'+
		'                    \"task_type\": \"COMPANY_IDENTIFY_OFFICERS\",'+
		'                    \"task_variant\": {'+
		'                        \"id\": \"c24e5746-0bfd-4f25-8e40-a0217d1614f1\",'+
		'                        \"name\": \"Identify officers\",'+
		'                        \"task_type\": \"COMPANY_IDENTIFY_OFFICERS\"'+
		'                    }'+
		'                },'+
		'                {'+
		'                    \"blocker_type\": \"INCOMPLETE_TASK\",'+
		'                    \"task_type\": \"COMPANY_IDENTIFY_AUTHORIZED_PERSONS\",'+
		'                    \"task_variant\": {'+
		'                        \"id\": \"2da1b064-e972-4484-a8b5-bb484634a91c\",'+
		'                        \"task_type\": \"COMPANY_IDENTIFY_AUTHORIZED_PERSONS\"'+
		'                    }'+
		'                },'+
		'                {'+
		'                    \"blocker_type\": \"INCOMPLETE_TASK\",'+
		'                    \"task_type\": \"COMPANY_MANUAL_TASK\",'+
		'                    \"task_variant\": {'+
		'                        \"description\": \"Evaluate whether the customer has a complex ownership structure.\",'+
		'                        \"id\": \"8ef6479b-407f-4874-830a-886706d3c926\",'+
		'                        \"name\": \"Structure Complexity\",'+
		'                        \"task_type\": \"COMPANY_MANUAL_TASK\"'+
		'                    }'+
		'                }'+
		'            ],'+
		'            \"assignments\": ['+
		'                {'+
		'                    \"application_id\": \"cd8328f6-194b-4f9c-9e99-8a9077a7fb8a\",'+
		'                    \"assignee\": {'+
		'                        \"assignee_type\": \"USER\",'+
		'                        \"email\": \"allison@qvcreative.com+staging\",'+
		'                        \"id\": \"cc047689-bc4a-4bc8-bc30-202c1de68c0d\",'+
		'                        \"name\": \"Allison Campbell\"'+
		'                    },'+
		'                    \"assigner\": {'+
		'                        \"email\": \"monish.mahalingam@flywire.com+staging\",'+
		'                        \"id\": \"480069f0-6e4d-4543-a5cb-de943d92113e\",'+
		'                        \"is_active\": true,'+
		'                        \"name\": \"Monish Mahalingam\"'+
		'                    },'+
		'                    \"creation_date\": \"2024-05-03 19:02:25\",'+
		'                    \"id\": \"58ae49ad-2e14-4eeb-900a-13ea564522e6\"'+
		'                }'+
		'            ],'+
		'            \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'            \"flag_history\": ['+
		'                {'+
		'                    \"date\": \"2024-02-22 13:25:13\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-02-22 13:25:32\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-02-22 13:28:37\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-02-22 13:28:43\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-02-22 13:29:17\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-02-22 13:29:18\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-02-22 13:29:19\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-02-22 13:29:29\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-02-22 13:29:32\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-02-22 13:29:50\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-02-22 13:29:54\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-02-22 13:30:05\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-02-22 13:30:06\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-02-22 13:30:13\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-03-24 02:34:13\",'+
		'                    \"flag\": \"RECALCULATING_RISK\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-03-24 02:34:13\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-03-24 02:34:19\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-03-24 03:44:43\",'+
		'                    \"flag\": \"RECALCULATING_RISK\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-03-24 03:44:44\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-03-24 03:44:50\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-03-24 05:03:33\",'+
		'                    \"flag\": \"RECALCULATING_RISK\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-03-24 05:03:34\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-03-24 05:03:50\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-03-25 15:34:38\",'+
		'                    \"flag\": \"RECALCULATING_RISK\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-03-25 15:34:39\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-03-25 15:34:44\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-03-25 15:58:51\",'+
		'                    \"flag\": \"RECALCULATING_RISK\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-03-25 15:58:51\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-03-25 16:00:44\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-04-10 02:02:23\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-04-10 02:02:40\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-04-10 02:02:43\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-04-10 02:02:50\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-02 16:22:59\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-02 16:24:21\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-03 19:20:36\",'+
		'                    \"flag\": \"RECALCULATING_RISK\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-03 19:20:36\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-03 19:20:45\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-03 19:20:47\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-03 19:20:47\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-03 19:40:13\",'+
		'                    \"flag\": \"RECALCULATING_RISK\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-03 19:40:13\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-03 19:40:19\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-03 21:18:36\",'+
		'                    \"flag\": \"RECALCULATING_RISK\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-03 21:18:37\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-03 21:18:46\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-03 21:23:26\",'+
		'                    \"flag\": \"RECALCULATING_RISK\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-03 21:23:26\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-03 21:23:33\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-03 21:30:19\",'+
		'                    \"flag\": \"RECALCULATING_RISK\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-03 21:30:20\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-03 21:30:28\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-06 13:43:01\",'+
		'                    \"flag\": \"RECALCULATING_RISK\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-06 13:43:01\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-06 13:43:06\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-06 14:34:35\",'+
		'                    \"flag\": \"RECALCULATING_RISK\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-06 14:34:35\",'+
		'                    \"flag\": \"AUTOMATING\",'+
		'                    \"status\": \"APPLIED\"'+
		'                },'+
		'                {'+
		'                    \"date\": \"2024-05-06 14:34:44\",'+
		'                    \"flag\": \"REQUIRES_MANUAL_TASK_COMPLETION\",'+
		'                    \"status\": \"APPLIED\"'+
		'                }'+
		'            ],'+
		'            \"hidden\": false,'+
		'"history":[{"date":"2024-02-22 13:25:13","status":"APPROVED"}],'+
		'            \"id\": \"cd8328f6-194b-4f9c-9e99-8a9077a7fb8a\",'+
		'            \"policy_result\": {},'+
		'            \"product\": {'+
		'                \"alias\": \"Flywire_KYC\",'+
		'                \"automatically_approve\": false,'+
		'                \"id\": \"a1da14b6-164b-4dd3-a0e1-656cd8e094e7\",'+
		'                \"name\": \"Client\"'+
		'            },'+
		'            \"required_tasks\": ['+
		'                {'+
		'                    \"alias\": \"company_verify_identityverify_company_details\",'+
		'                    \"id\": \"7ac98b0b-3786-4a29-8ed9-1d3fc0f11f26\",'+
		'                    \"name\": \"Verify company details\",'+
		'                    \"task_type\": \"COMPANY_VERIFY_IDENTITY\"'+
		'                },'+
		'                {'+
		'                    \"alias\": \"company_assess_ownershipdefault\",'+
		'                    \"id\": \"c776efb7-9ba9-4014-a788-b94e81ffd4e9\",'+
		'                    \"name\": \"Assess company ownership\",'+
		'                    \"task_type\": \"COMPANY_ASSESS_OWNERSHIP\"'+
		'                },'+
		'                {'+
		'                    \"alias\": \"company_assess_media_and_sanctions_exposuredefault\",'+
		'                    \"id\": \"f605f872-304b-4a25-a5e8-db6d422a5658\",'+
		'                    \"name\": \"Assess sanctions and adverse media\",'+
		'                    \"task_type\": \"COMPANY_ASSESS_MEDIA_AND_SANCTIONS_EXPOSURE\"'+
		'                },'+
		'                {'+
		'                    \"alias\": \"company_identify_officersdefault\",'+
		'                    \"id\": \"c24e5746-0bfd-4f25-8e40-a0217d1614f1\",'+
		'                    \"name\": \"Identify officers\",'+
		'                    \"task_type\": \"COMPANY_IDENTIFY_OFFICERS\"'+
		'                },'+
		'                {'+
		'                    \"alias\": \"company_identify_authorized_personsdefault\",'+
		'                    \"id\": \"2da1b064-e972-4484-a8b5-bb484634a91c\",'+
		'                    \"task_type\": \"COMPANY_IDENTIFY_AUTHORIZED_PERSONS\"'+
		'                },'+
		'                {'+
		'                    \"alias\": \"company_manual_taskstructure_complexity\",'+
		'                    \"description\": \"Evaluate whether the customer has a complex ownership structure.\",'+
		'                    \"id\": \"8ef6479b-407f-4874-830a-886706d3c926\",'+
		'                    \"name\": \"Structure Complexity\",'+
		'                    \"task_type\": \"COMPANY_MANUAL_TASK\"'+
		'                }'+
		'            ],'+
		'            \"risk\": {'+
		'                \"breakdown\": {'+
		'                    \"category_grouping\": ['+
		'                        {'+
		'                            \"combined_score\": 79.0,'+
		'                            \"group_config\": {'+
		'                                \"category_ids\": ['+
		'                                    \"48570bb6-08ca-45d2-960d-4d8223c6902c\",'+
		'                                    \"902d6ef0-704c-4511-b0c7-366e3662e960\",'+
		'                                    \"212b3805-9439-4085-acde-a417fe307a74\",'+
		'                                    \"2aee112e-439d-443f-ba3e-fb686707bac3\",'+
		'                                    \"187bd4ec-c560-4702-a8a5-3ab0ae2e4c06\",'+
		'                                    \"625f27fc-eff4-4f79-a45a-fe36e3356127\",'+
		'                                    \"889e9b06-79ee-4903-90cc-9ffeadbf3870\",'+
		'                                    \"b8f7c185-516b-4251-8598-8e23a6ae00b9\",'+
		'                                    \"b2b30bf6-deac-41fb-919d-837b30231b2a\",'+
		'                                    \"ab551685-5f30-49c4-9ea6-daafd2133521\",'+
		'                                    \"2eabb51a-f367-48b8-8969-977ab90c6104\",'+
		'                                    \"e4240562-e369-4aea-810c-30e7ddd60bc9\",'+
		'                                    \"5530c2da-f0d3-476b-9b72-3221ece84c24\",'+
		'                                    \"df2341be-953e-4e3f-8793-a402078f6199\",'+
		'                                    \"5755bbe1-2d80-438b-9bc5-58b7abee53a1\",'+
		'                                    \"409ae488-4446-4b54-a5fc-f346573c9087\",'+
		'                                    \"e740d399-11d2-469d-979e-af7e043b3925\"'+
		'                                ],'+
		'                                \"name\": \"risk group\",'+
		'                                \"operator\": \"SUM\"'+
		'                            }'+
		'                        },'+
		'                        {'+
		'                            \"group_config\": {'+
		'                                \"category_ids\": ['+
		'                                    \"b1eba284-07b0-4250-aeed-296e41e2ade3\",'+
		'                                    \"33233f1e-edf6-431b-9c1f-ec65e732cb03\"'+
		'                                ],'+
		'                                \"name\": \"Pep risk\",'+
		'                                \"operator\": \"MAX\"'+
		'                            }'+
		'                        },'+
		'                        {'+
		'                            \"combined_score\": 4.0,'+
		'                            \"group_config\": {'+
		'                                \"category_ids\": ['+
		'                                    \"c06ca4ba-97ae-45c6-bb7e-2c68a0e2a42d\",'+
		'                                    \"90533d24-7bf4-41fa-8b91-b34baa13b2d8\",'+
		'                                    \"58f6fcba-f327-4d7f-b9d2-c03f5151f2f7\",'+
		'                                    \"f7e45975-b17a-431f-b1f2-7a5e372cc60b\",'+
		'                                    \"ab6d0fcd-fb17-44bb-9fe6-0f764bd33c37\",'+
		'                                    \"482fbfa1-8c5f-4a52-af6f-57f0860c3da3\"'+
		'                                ],'+
		'                                \"name\": \"Transaction country scoring\",'+
		'                                \"operator\": \"MAX\"'+
		'                            }'+
		'                        },'+
		'                        {'+
		'                            \"combined_score\": 1.0,'+
		'                            \"group_config\": {'+
		'                                \"category_ids\": ['+
		'                                    \"26381351-6c90-4a79-839f-a74fea2ababf\",'+
		'                                    \"f763b591-6936-49a9-9b24-a48474f1e23c\"'+
		'                                ],'+
		'                                \"name\": \"Incorp\",'+
		'                                \"operator\": \"MAX\"'+
		'                            }'+
		'                        }'+
		'                    ],'+
		'                    \"components\": ['+
		'                        {'+
		'                            \"category\": {'+
		'                                \"type\": \"EVENTS\"'+
		'                            },'+
		'                            \"category_id\": \"2eabb51a-f367-48b8-8969-977ab90c6104\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                            \"name\": \"Adverse Media flag\",'+
		'                            \"raw_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                            \"required\": false,'+
		'                            \"score\": 0.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"type\": \"ASSOCIATES\"'+
		'                            },'+
		'                            \"category_id\": \"48570bb6-08ca-45d2-960d-4d8223c6902c\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                            \"name\": \"Associates (Authorized Persons/Beneficial Owners/Company Secretaries/Controlling Shareholders/Directors/Global Ultimate Owners/Others/Partners/Resigned Officers/Shareholders/Trustees) - Adverse Media flag\",'+
		'                            \"raw_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                            \"required\": false,'+
		'                            \"score\": 0.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"type\": \"ASSOCIATES\"'+
		'                            },'+
		'                            \"category_id\": \"902d6ef0-704c-4511-b0c7-366e3662e960\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                            \"name\": \"Associates (Authorized Persons/Beneficial Owners/Company Secretaries/Controlling Shareholders/Directors/Global Ultimate Owners/Others/Partners/Resigned Officers/Shareholders/Trustees) - PEP flag\",'+
		'                            \"raw_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                            \"required\": false,'+
		'                            \"score\": 0.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"type\": \"ASSOCIATES\"'+
		'                            },'+
		'                            \"category_id\": \"b1eba284-07b0-4250-aeed-296e41e2ade3\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"\",'+
		'                            \"name\": \"Associates (Authorized Persons/Beneficial Owners/Company Secretaries/Controlling Shareholders/Directors/Global Ultimate Owners/Others/Partners/Resigned Officers/Shareholders/Trustees) - Pep Risk\",'+
		'                            \"raw_value\": \"\",'+
		'                            \"required\": false'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"type\": \"ASSOCIATES\"'+
		'                            },'+
		'                            \"category_id\": \"212b3805-9439-4085-acde-a417fe307a74\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                            \"name\": \"Associates (Authorized Persons/Beneficial Owners/Company Secretaries/Controlling Shareholders/Directors/Global Ultimate Owners/Others/Partners/Resigned Officers/Shareholders/Trustees) - Sanction flag\",'+
		'                            \"raw_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                            \"required\": false,'+
		'                            \"score\": 0.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"type\": \"COUNTRY_OF_INCORPORATION\"'+
		'                            },'+
		'                            \"category_id\": \"2aee112e-439d-443f-ba3e-fb686707bac3\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"United States of America\",'+
		'                            \"matched_rule_name\": \"Low Risk Country\",'+
		'                            \"name\": \"Country Of Incorporation\",'+
		'                            \"raw_value\": \"USA\",'+
		'                            \"required\": false,'+
		'                            \"score\": 10.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"custom_field_name\": \"m_transaction_representation_country\",'+
		'                                \"type\": \"CUSTOM_FIELD\"'+
		'                            },'+
		'                            \"category_id\": \"482fbfa1-8c5f-4a52-af6f-57f0860c3da3\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"[AFG, ALB]\",'+
		'                            \"matched_rule_name\": \"High\",'+
		'                            \"name\": \"Custom Field (m_transaction_representation_country)\",'+
		'                            \"raw_value\": \"[AFG, ALB]\",'+
		'                            \"required\": false,'+
		'                            \"score\": 4.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"custom_field_name\": \"s_complex_structure\",'+
		'                                \"type\": \"CUSTOM_FIELD\"'+
		'                            },'+
		'                            \"category_id\": \"187bd4ec-c560-4702-a8a5-3ab0ae2e4c06\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"More than 3 levels of ownership\",'+
		'                            \"matched_rule_name\": \"No score\",'+
		'                            \"name\": \"Custom Field (s_complex_structure)\",'+
		'                            \"raw_value\": \"More than 3 levels of ownership\",'+
		'                            \"required\": false,'+
		'                            \"score\": 4.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"custom_field_name\": \"s_delivery_channel\",'+
		'                                \"type\": \"CUSTOM_FIELD\"'+
		'                            },'+
		'                            \"category_id\": \"625f27fc-eff4-4f79-a45a-fe36e3356127\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"\",'+
		'                            \"name\": \"Custom Field (s_delivery_channel)\",'+
		'                            \"raw_value\": \"\",'+
		'                            \"required\": false'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"custom_field_name\": \"s_entity_type\",'+
		'                                \"type\": \"CUSTOM_FIELD\"'+
		'                            },'+
		'                            \"category_id\": \"b8f7c185-516b-4251-8598-8e23a6ae00b9\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"Private\",'+
		'                            \"matched_rule_name\": \"\",'+
		'                            \"name\": \"Custom Field (s_entity_type)\",'+
		'                            \"raw_value\": \"Private\",'+
		'                            \"required\": false,'+
		'                            \"score\": 65.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"custom_field_name\": \"s_pep_risk\",'+
		'                                \"type\": \"CUSTOM_FIELD\"'+
		'                            },'+
		'                            \"category_id\": \"33233f1e-edf6-431b-9c1f-ec65e732cb03\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"\",'+
		'                            \"name\": \"Custom Field (s_pep_risk)\",'+
		'                            \"raw_value\": \"\",'+
		'                            \"required\": false'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"custom_field_name\": \"s_product\",'+
		'                                \"type\": \"CUSTOM_FIELD\"'+
		'                            },'+
		'                            \"category_id\": \"889e9b06-79ee-4903-90cc-9ffeadbf3870\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"\",'+
		'                            \"name\": \"Custom Field (s_product)\",'+
		'                            \"raw_value\": \"\",'+
		'                            \"required\": false'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"custom_field_name\": \"s_prohibited_ownership\",'+
		'                                \"type\": \"CUSTOM_FIELD\"'+
		'                            },'+
		'                            \"category_id\": \"409ae488-4446-4b54-a5fc-f346573c9087\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"No\",'+
		'                            \"matched_rule_name\": \"\",'+
		'                            \"name\": \"Custom Field (s_prohibited_ownership)\",'+
		'                            \"raw_value\": \"No\",'+
		'                            \"required\": false,'+
		'                            \"score\": 0.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"custom_field_name\": \"s_prohibited_services\",'+
		'                                \"type\": \"CUSTOM_FIELD\"'+
		'                            },'+
		'                            \"category_id\": \"e740d399-11d2-469d-979e-af7e043b3925\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"No\",'+
		'                            \"matched_rule_name\": \"\",'+
		'                            \"name\": \"Custom Field (s_prohibited_services)\",'+
		'                            \"raw_value\": \"No\",'+
		'                            \"required\": false,'+
		'                            \"score\": 0.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"custom_field_name\": \"s_reduction\",'+
		'                                \"type\": \"CUSTOM_FIELD\"'+
		'                            },'+
		'                            \"category_id\": \"e4240562-e369-4aea-810c-30e7ddd60bc9\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"No change\",'+
		'                            \"matched_rule_name\": \"\",'+
		'                            \"name\": \"Custom Field (s_reduction)\",'+
		'                            \"raw_value\": \"No change\",'+
		'                            \"required\": false,'+
		'                            \"score\": 0.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"custom_field_name\": \"s_regulatory_status\",'+
		'                                \"type\": \"CUSTOM_FIELD\"'+
		'                            },'+
		'                            \"category_id\": \"b2b30bf6-deac-41fb-919d-837b30231b2a\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"\",'+
		'                            \"name\": \"Custom Field (s_regulatory_status)\",'+
		'                            \"raw_value\": \"\",'+
		'                            \"required\": false'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"custom_field_name\": \"s_sic_code\",'+
		'                                \"type\": \"CUSTOM_FIELD\"'+
		'                            },'+
		'                            \"category_id\": \"ab551685-5f30-49c4-9ea6-daafd2133521\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"6732 - Educational, religious, and charitable trusts\",'+
		'                            \"name\": \"Custom Field (s_sic_code)\",'+
		'                            \"raw_value\": \"6732 - Educational, religious, and charitable trusts\",'+
		'                            \"required\": false,'+
		'                            \"score\": 0.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"custom_field_name\": \"s_tansaction_representation_country_1\",'+
		'                                \"type\": \"CUSTOM_FIELD\"'+
		'                            },'+
		'                            \"category_id\": \"c06ca4ba-97ae-45c6-bb7e-2c68a0e2a42d\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"GBR\",'+
		'                            \"matched_rule_name\": \"Low\",'+
		'                            \"name\": \"Custom Field (s_tansaction_representation_country_1)\",'+
		'                            \"raw_value\": \"GBR\",'+
		'                            \"required\": false,'+
		'                            \"score\": 1.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"custom_field_name\": \"s_tansaction_representation_country_2\",'+
		'                                \"type\": \"CUSTOM_FIELD\"'+
		'                            },'+
		'                            \"category_id\": \"90533d24-7bf4-41fa-8b91-b34baa13b2d8\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"VNM\",'+
		'                            \"matched_rule_name\": \"Medium\",'+
		'                            \"name\": \"Custom Field (s_tansaction_representation_country_2)\",'+
		'                            \"raw_value\": \"VNM\",'+
		'                            \"required\": false,'+
		'                            \"score\": 1.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"custom_field_name\": \"s_tansaction_representation_country_3\",'+
		'                                \"type\": \"CUSTOM_FIELD\"'+
		'                            },'+
		'                            \"category_id\": \"58f6fcba-f327-4d7f-b9d2-c03f5151f2f7\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"FRA\",'+
		'                            \"matched_rule_name\": \"Low\",'+
		'                            \"name\": \"Custom Field (s_tansaction_representation_country_3)\",'+
		'                            \"raw_value\": \"FRA\",'+
		'                            \"required\": false,'+
		'                            \"score\": 1.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"custom_field_name\": \"s_tansaction_representation_country_4\",'+
		'                                \"type\": \"CUSTOM_FIELD\"'+
		'                            },'+
		'                            \"category_id\": \"f7e45975-b17a-431f-b1f2-7a5e372cc60b\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"NAM\",'+
		'                            \"matched_rule_name\": \"High\",'+
		'                            \"name\": \"Custom Field (s_tansaction_representation_country_4)\",'+
		'                            \"raw_value\": \"NAM\",'+
		'                            \"required\": false,'+
		'                            \"score\": 4.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"custom_field_name\": \"s_transaction_representation_country_5\",'+
		'                                \"type\": \"CUSTOM_FIELD\"'+
		'                            },'+
		'                            \"category_id\": \"ab6d0fcd-fb17-44bb-9fe6-0f764bd33c37\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"ATA\",'+
		'                            \"name\": \"Custom Field (s_transaction_representation_country_5)\",'+
		'                            \"raw_value\": \"ATA\",'+
		'                            \"required\": false'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"custom_field_name\": \"d_incorporation_date\",'+
		'                                \"type\": \"CUSTOM_FIELD_DATE_TO_MONTHS\"'+
		'                            },'+
		'                            \"category_id\": \"f763b591-6936-49a9-9b24-a48474f1e23c\",'+
		'                            \"errors\": [],'+
		'                            \"expiry\": \"2024-05-10\",'+
		'                            \"input_value\": \"402\",'+
		'                            \"matched_rule_name\": \"\",'+
		'                            \"name\": \"Custom Field (d_incorporation_date)\",'+
		'                            \"raw_value\": \"1990-10-10\",'+
		'                            \"required\": false,'+
		'                            \"score\": 1.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"type\": \"EVENTS\"'+
		'                            },'+
		'                            \"category_id\": \"5530c2da-f0d3-476b-9b72-3221ece84c24\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                            \"name\": \"Events (REFER_FLAG)\",'+
		'                            \"raw_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                            \"required\": false,'+
		'                            \"score\": 0.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"type\": \"EVENTS\"'+
		'                            },'+
		'                            \"category_id\": \"df2341be-953e-4e3f-8793-a402078f6199\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                            \"name\": \"PEP flag\",'+
		'                            \"raw_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                            \"required\": false,'+
		'                            \"score\": 0.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"type\": \"EVENTS\"'+
		'                            },'+
		'                            \"category_id\": \"5755bbe1-2d80-438b-9bc5-58b7abee53a1\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                            \"name\": \"Sanction flag\",'+
		'                            \"raw_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                            \"required\": false,'+
		'                            \"score\": 0.0'+
		'                        },'+
		'                        {'+
		'                            \"category\": {'+
		'                                \"type\": \"DATE_OF_INCORPORATION\"'+
		'                            },'+
		'                            \"category_id\": \"26381351-6c90-4a79-839f-a74fea2ababf\",'+
		'                            \"errors\": [],'+
		'                            \"input_value\": \"\",'+
		'                            \"name\": \"Date Of Incorporation\",'+
		'                            \"raw_value\": \"\",'+
		'                            \"required\": false'+
		'                        }'+
		'                    ],'+
		'                    \"missing_required_components\": []'+
		'                },'+
		'                \"expiry\": \"2024-05-10\",'+
		'                \"is_pending\": false,'+
		'                \"overall\": {'+
		'                    \"level\": \"MEDIUM\",'+
		'                    \"score\": 84.0'+
		'                },'+
		'                \"risk_model\": {'+
		'                    \"id\": \"2f1c14f9-8a1f-45a0-826a-599cda9ce530\",'+
		'                    \"version\": \"1970-01-01 00:00:00\"'+
		'                },'+
		'                \"thresholds\": {'+
		'                    \"low_medium\": 50.0,'+
		'                    \"medium_high\": 110.0'+
		'                }'+
		'            },'+
		'            \"status\": \"APPLIED\"'+
		'        }'+
		'    ],'+
		'    \"category\": \"APPLICANT\",'+
		'    \"checks\": [{' +
		'        \"check_type\": \"COMPANY_DATA\",' +
		'        \"output_data\": {' +
		'            \"metadata\": {' +
		'                \"metadata\": {' +
		'                    \"number\": \"123456\"' +
		'                }'+
		'            }'+
		'        }'+
		'    }],'+
		'    \"collected_data\": {'+
		'        \"entity_type\": \"COMPANY\",'+
		'        \"custom_fields_data\": {'+
		'            \"d_incorporation_date\": \"1990-10-10\",'+
		'            \"d_review_date\": \"2024-03-08\",'+
		'            \"m_countries_of_final_destinations_2\": ['+
		'                \"BMU\"'+
		'            ],'+
		'            \"m_currency_selection_credit\": ['+
		'                \"USD\"'+
		'            ],'+
		'            \"m_payment_months\": ['+
		'                \"January\",'+
		'                \"March\",'+
		'                \"May\"'+
		'            ],'+
		'            \"m_transaction_representation_country\": ['+
		'                \"AFG\",'+
		'                \"ALB\"'+
		'            ],'+
		'            \"n_estimated_number_of_insurance_policies_annually_australia_nz\": 44,'+
		'            \"n_estimated_number_of_students_payers_annually\": 199.0,'+
		'            \"n_how_far_in_advance_1\": 999,'+
		'            \"n_how_far_in_advance_3\": 6,'+
		'            \"n_maximum_payment_size_2\": 100,'+
		'            \"n_money_moved_annually_2\": 78,'+
		'            \"n_money_moved_annually_debit_cards\": 100,'+
		'            \"n_payment_collection_1\": 100,'+
		'            \"n_payment_collection_2\": 3,'+
		'            \"n_payment_collection_3\": 4,'+
		'            \"n_percentage_volume_1\": 100,'+
		'            \"n_percentage_volume_2\": 6,'+
		'            \"n_percentage_volume_other_1\": 100,'+
		'            \"n_percentage_volume_other_2\": 3,'+
		'            \"n_percentage_volume_other_3\": 4,'+
		'            \"n_project_value_of_payments_2\": 100,'+
		'            \"n_total_value_of_payments_2\": 100,'+
		'            \"n_typical_payment_size\": 5,'+
		'            \"n_typical_payment_size_1\": 200,'+
		'            \"s_1_d_trading_name_2\": \"New Trading name May 6\",'+
		'            \"s_1_n_tax_id_number\": \"Tx1112\",'+
		'            \"s_3_d_verified_bank_details\": \"Yes\",'+
		'            \"s_address_check\": \"yes\",'+
		'            \"s_address_check_select\": \"Yes\",'+
		'            \"s_advance_payment_types_1\": \"Tuition\",'+
		'            \"s_advance_payment_types_2\": \"Deposits\",'+
		'            \"s_advance_payment_types_2_1\": \"Tuition\",'+
		'            \"s_advance_payments\": \"Yes\",'+
		'            \"s_authorised_individual\": \"Yes\",'+
		'            \"s_bank_account_name\": \"assa\",'+
		'            \"s_bank_bic_swift_code\": \"fgf\",'+
		'            \"s_bank_iban\": \"dfd\",'+
		'            \"s_batch_tag\": \"334\",'+
		'            \"s_bo_at_25\": \"Yes\",'+
		'            \"s_company_id\": \"0015w000025htdJAAQ\",'+
		'            \"s_complex_structure\": \"More than 3 levels of ownership\",'+
		'            \"s_contact_email_address\": \"hello12@test.com\",'+
		'            \"s_country_accrediting_body_memberships\": \"USA\",'+
		'            \"s_credit_card_payments\": \"Yes\",'+
		'            \"s_currency_selection_payment_ss\": \"CHF\",'+
		'            \"s_declaration\": \"I agree\",'+
		'            \"s_entity_type\": \"Private\",'+
		'            \"s_evidence_url\": \"43.comc\",'+
		'            \"s_final_payments\": \"Student Fees/Supplies\",'+
		'            \"s_final_payments_3\": \"A/R Payments\",'+
		'            \"s_flywire_entity\": \"Flywire Payments Corporation\",'+
		'            \"s_further_information\": \"33333\",'+
		'            \"s_further_information_2\": \"333\",'+
		'            \"s_migration\": \"Yes\",'+
		'            \"s_mlro_delegate_high_risk\": \"May be\",'+
		'            \"s_mlro_delegate_pep\": \"ggg\",'+
		'            \"s_other_text_1\": \"5b\",'+
		'            \"s_other_text_2\": \"Tutions\",'+
		'            \"s_other_text_3\": \"Not sure\",'+
		'            \"s_other_text_final_2\": \"N\",'+
		'            \"s_other_text_final_3\": \"r\",'+
		'            \"s_phone_number\": \"1234561\",'+
		'            \"s_prohibited_ownership\": \"No\",'+
		'            \"s_prohibited_services\": \"No\",'+
		'            \"s_purpose_of_payments\": \"hu\",'+
		'            \"s_reduction\": \"No change\",'+
		'            \"s_sic_code\": \"6732 - Educational, religious, and charitable trusts\",'+
		'            \"s_tansaction_representation_country_1\": \"GBR\",'+
		'            \"s_tansaction_representation_country_2\": \"VNM\",'+
		'            \"s_tansaction_representation_country_3\": \"FRA\",'+
		'            \"s_tansaction_representation_country_4\": \"NAM\",'+
		'            \"s_tax_id_type\": \"VAT\",'+
		'            \"s_terms_and_conditions_url\": \"www.googl.ecom\",'+
		'            \"s_trading_name\": \"New awesome Flywire trading name\",'+
		'            \"s_transaction_1\": \"40\",'+
		'            \"s_transaction_1_1\": \"50\",'+
		'            \"s_transaction_3\": \"10\",'+
		'            \"s_transaction_4\": \"5\",'+
		'            \"s_transaction_5\": \"3\",'+
		'            \"s_transaction_representation_country_5\": \"ATA\",'+
		'            \"s_verify_open_loop\": \"Confirmed Open Loop\",'+
		'            \"s_vertical\": \"Education\",'+
		'            \"s_web_review\": \"Yes\",'+
		'            \"s_website\": \"xxx\",'+
		'            \"s_website_url\": \"1234.com\"'+
		'        },'+
		'        \"metadata\": {'+
		'            \"bvd_id\": \"US297747965L\",'+
		'            \"country_of_incorporation\": \"USA\",'+
		'            \"name\": \"Flywire LLC\",'+
		'            \"number\": \"297747965\",'+
		'            \"state_of_incorporation\": \"MA\"'+
		'        }'+
		'    },'+
		'    \"collection_steps\": [],'+
		'    \"creation_date\": \"2024-02-22 13:23:19\",'+
		'    \"display_name\": \"Flywire LLC\",'+
		'    \"document_images\": [],'+
		'    \"events\": [],'+
		'    \"has_associates\": true,'+
		'    \"has_collection_steps\": false,'+
		'    \"id\": \"ede087b2-c8de-406f-bce4-876af7922acd\",'+
		'    \"last_modified_date\": \"2024-05-06 14:34:34\",'+
		'    \"linked_to\": [],'+
		'    \"risk\": {'+
		'        \"components\": ['+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                \"name\": \"Adverse Media flag\",'+
		'                \"raw_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 0.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                \"name\": \"Associates (Authorized Persons/Beneficial Owners/Company Secretaries/Controlling Shareholders/Directors/Global Ultimate Owners/Others/Partners/Resigned Officers/Shareholders/Trustees) - Adverse Media flag\",'+
		'                \"raw_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 0.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                \"name\": \"Associates (Authorized Persons/Beneficial Owners/Company Secretaries/Controlling Shareholders/Directors/Global Ultimate Owners/Others/Partners/Resigned Officers/Shareholders/Trustees) - PEP flag\",'+
		'                \"raw_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 0.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"\",'+
		'                \"name\": \"Associates (Authorized Persons/Beneficial Owners/Company Secretaries/Controlling Shareholders/Directors/Global Ultimate Owners/Others/Partners/Resigned Officers/Shareholders/Trustees) - Pep Risk\",'+
		'                \"raw_value\": \"\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {}'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                \"name\": \"Associates (Authorized Persons/Beneficial Owners/Company Secretaries/Controlling Shareholders/Directors/Global Ultimate Owners/Others/Partners/Resigned Officers/Shareholders/Trustees) - Sanction flag\",'+
		'                \"raw_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 0.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"United States of America\",'+
		'                \"matched_rule_name\": \"Low Risk Country\",'+
		'                \"name\": \"Country Of Incorporation\",'+
		'                \"raw_value\": \"USA\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 10.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"[AFG, ALB]\",'+
		'                \"matched_rule_name\": \"High\",'+
		'                \"name\": \"Custom Field (m_transaction_representation_country)\",'+
		'                \"raw_value\": \"[AFG, ALB]\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 4.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"More than 3 levels of ownership\",'+
		'                \"matched_rule_name\": \"No score\",'+
		'                \"name\": \"Custom Field (s_complex_structure)\",'+
		'                \"raw_value\": \"More than 3 levels of ownership\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 4.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"\",'+
		'                \"name\": \"Custom Field (s_delivery_channel)\",'+
		'                \"raw_value\": \"\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {}'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"Private\",'+
		'                \"matched_rule_name\": \"\",'+
		'                \"name\": \"Custom Field (s_entity_type)\",'+
		'                \"raw_value\": \"Private\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 65.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"\",'+
		'                \"name\": \"Custom Field (s_pep_risk)\",'+
		'                \"raw_value\": \"\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {}'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"\",'+
		'                \"name\": \"Custom Field (s_product)\",'+
		'                \"raw_value\": \"\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {}'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"No\",'+
		'                \"matched_rule_name\": \"\",'+
		'                \"name\": \"Custom Field (s_prohibited_ownership)\",'+
		'                \"raw_value\": \"No\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 0.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"No\",'+
		'                \"matched_rule_name\": \"\",'+
		'                \"name\": \"Custom Field (s_prohibited_services)\",'+
		'                \"raw_value\": \"No\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 0.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"No change\",'+
		'                \"matched_rule_name\": \"\",'+
		'                \"name\": \"Custom Field (s_reduction)\",'+
		'                \"raw_value\": \"No change\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 0.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"\",'+
		'                \"name\": \"Custom Field (s_regulatory_status)\",'+
		'                \"raw_value\": \"\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {}'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"6732 - Educational, religious, and charitable trusts\",'+
		'                \"name\": \"Custom Field (s_sic_code)\",'+
		'                \"raw_value\": \"6732 - Educational, religious, and charitable trusts\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 0.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"GBR\",'+
		'                \"matched_rule_name\": \"Low\",'+
		'                \"name\": \"Custom Field (s_tansaction_representation_country_1)\",'+
		'                \"raw_value\": \"GBR\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 1.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"VNM\",'+
		'                \"matched_rule_name\": \"Medium\",'+
		'                \"name\": \"Custom Field (s_tansaction_representation_country_2)\",'+
		'                \"raw_value\": \"VNM\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 1.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"FRA\",'+
		'                \"matched_rule_name\": \"Low\",'+
		'                \"name\": \"Custom Field (s_tansaction_representation_country_3)\",'+
		'                \"raw_value\": \"FRA\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 1.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"NAM\",'+
		'                \"matched_rule_name\": \"High\",'+
		'                \"name\": \"Custom Field (s_tansaction_representation_country_4)\",'+
		'                \"raw_value\": \"NAM\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 4.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"ATA\",'+
		'                \"name\": \"Custom Field (s_transaction_representation_country_5)\",'+
		'                \"raw_value\": \"ATA\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {}'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"402\",'+
		'                \"matched_rule_name\": \"\",'+
		'                \"name\": \"Custom Field (d_incorporation_date)\",'+
		'                \"raw_value\": \"1990-10-10\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 1.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                \"name\": \"Events (REFER_FLAG)\",'+
		'                \"raw_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 0.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                \"name\": \"PEP flag\",'+
		'                \"raw_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 0.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                \"name\": \"Sanction flag\",'+
		'                \"raw_value\": \"0 mismatches, 0 matches, 0 possible matches\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {'+
		'                    \"score\": 0.0'+
		'                }'+
		'            },'+
		'            {'+
		'                \"errors\": [],'+
		'                \"input_value\": \"\",'+
		'                \"name\": \"Date Of Incorporation\",'+
		'                \"raw_value\": \"\",'+
		'                \"required\": false,'+
		'                \"risk_level\": {}'+
		'            }'+
		'        ],'+
		'        \"expiry_date\": \"2024-05-10\",'+
		'        \"is_pending\": false,'+
		'        \"missing_required_components\": [],'+
		'        \"overall_risk\": {'+
		'            \"category\": \"MEDIUM\",'+
		'            \"score\": 84.0'+
		'        }'+
		'    },'+
		'    \"role\": \"COMPANY_CUSTOMER\",'+
		'    \"root_id\": \"ede087b2-c8de-406f-bce4-876af7922acd\",'+
		'    \"status\": \"NORMAL\",'+
		'    \"tags\": ['+
		'        {'+
		'            \"id\": \"14d8d37a-a12a-479f-851e-afa7a9e967f8\",'+
		'            \"is_automatic\": false,'+
		'            \"name\": \"EMEA\"'+
		'        },'+
		'        {'+
		'            \"id\": \"796895ad-1ae7-46cb-999b-138ca801d736\",'+
		'            \"is_automatic\": false,'+
		'            \"name\": \"Test\"'+
		'        }'+
		'    ],'+
		'    \"task_progress\": {'+
		'        \"completed_count\": 2,'+
		'        \"total_count\": 9'+
		'    },'+
		'    \"task_types\": ['+
		'        \"COMPANY_MANUAL_TASK\",'+
		'        \"COMPANY_VERIFY_IDENTITY\",'+
		'        \"COMPANY_ASSESS_OWNERSHIP\",'+
		'        \"COMPANY_ASSESS_MEDIA_AND_SANCTIONS_EXPOSURE\",'+
		'        \"COMPANY_IDENTIFY_OFFICERS\",'+
		'        \"COMPANY_IDENTIFY_AUTHORIZED_PERSONS\"'+
		'    ],'+
		'    \"unresolved_event_types\": [],'+
		'    \"verified_data\": {'+
		'        \"entity_type\": \"COMPANY\",'+
		'        \"metadata\": {'+
		'            \"bvd_id\": \"US297747965L\",'+
		'            \"country_of_incorporation\": \"USA\",'+
		'            \"name\": \"Flywire LLC\",'+
		'            \"number\": \"297747965\",'+
		'            \"state_of_incorporation\": \"MA\",'+
		'            \"structured_company_type\": {'+
		'                \"is_limited\": true,'+
		'                \"is_public\": false,'+
		'                \"ownership_type\": \"COMPANY\"'+
		'            }'+
		'        }'+
		'    }'+
		'}';



}