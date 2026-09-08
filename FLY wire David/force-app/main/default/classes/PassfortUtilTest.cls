@IsTest
public class PassfortUtilTest {
    
    private static String passfortprofileId = 'ede087b2-c8de-406f-bce4-876af7922acd';
    
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
    @isTest
    static void testUpdateAccountWithValidProfileId() {
        // Setup
        PassfortProfile mockProfile = new PassfortProfile();
        mockProfile.id = passfortprofileId;
        mockProfile.risk = new PassfortProfile.ProfileRiskClass();
        mockProfile.risk.overall_risk = new PassfortProfile.OverallRiskClass();
        mockProfile.risk.overall_risk.category = 'Low';
        mockProfile.risk.overall_risk.score = 10;
        mockProfile.collected_data = new PassfortProfile.CollectedDataClass();
        mockProfile.collected_data.custom_fields_data = new PassfortProfile.CustomFieldsDataClass();
        mockProfile.collected_data.custom_fields_data.s_company_id = 'testCompanyId';
        
        //PassfortProfile.ApplicationsClass[] applications = new list<PassfortProfile.ApplicationsClass>();
        //PassfortProfile.ApplicationsClass application = new PassfortProfile.ApplicationsClass();
        //application.id = 'appid-random3475y734845734';
        
        //map<string,string> componentMap = new map<string,string>();
        //componentMap.put('','');
        
        //PassfortProfile.ComponentsClass[] components = new list<PassfortProfile.ComponentsClass>();
        //application.risk.breakdown.components = components;
        //applications.add(application);
        //mockProfile.applications = applications;
        
        // Mock HTTP callout
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody(JSON.serialize(mockProfile));
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new PassfortMockHttpResponseGenerator(mockResponse));

        // Mock Account
        //Account account = new Account(Name = 'Test Account', Passfort_Profile_Id__c = profileId);
        //insert account;

        // Test
        Test.startTest();
        Passfort_Webhook_Log__c log = new Passfort_Webhook_Log__c();
        PassfortUtil.PassfortProfileProcessingWrapper wrapper = PassfortUtil.updateAccout(passfortprofileId, log);
        Test.stopTest();

        // Verify
        Account updatedAccount = wrapper.acct;
        Assert.areEqual(passfortprofileId, updatedAccount.Passfort_Profile_Id__c);
        Assert.areEqual('Low', updatedAccount.KYC_Risk_Level__c);
        Assert.areEqual(10, updatedAccount.KYC_Risk_Score__c);
        Assert.isNotNull(wrapper.logMessage);
    }

    @isTest
    static void testUpdateAccountWithInvalidProfileId() {
        // Setup
        String profileId = 'invalidProfileId';

        // Mock HTTP callout
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"error":"Profile not found"}');
        mockResponse.setStatusCode(404);
        Test.setMock(HttpCalloutMock.class, new PassfortMockHttpResponseGenerator(mockResponse));

        // Test
        Test.startTest();
        try {
            Passfort_Webhook_Log__c log = new Passfort_Webhook_Log__c();
            PassfortUtil.updateAccout(profileId, log);
            System.assert(false, 'Expected exception to be thrown');
        } catch (PassfortWebhook.RequestBodyException e) {
            System.assert(e.getMessage().contains('profileRespone status code.404'));
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateAccountWithNoMatchingAccount() {
        // Setup
        String profileId = 'testProfileId';
        PassfortProfile mockProfile = new PassfortProfile();
        mockProfile.id = profileId;
        mockProfile.risk = new PassfortProfile.ProfileRiskClass();
        mockProfile.risk.overall_risk = new PassfortProfile.OverallRiskClass();
        mockProfile.risk.overall_risk.category = 'Low';
        mockProfile.risk.overall_risk.score = 10;
        mockProfile.collected_data = new PassfortProfile.CollectedDataClass();
        mockProfile.collected_data.custom_fields_data = new PassfortProfile.CustomFieldsDataClass();
        mockProfile.collected_data.custom_fields_data.s_company_id =  'badAccountId' ;
        
        // Mock HTTP callout
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody(JSON.serialize(mockProfile));
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new PassfortMockHttpResponseGenerator(mockResponse));

        // Test
        Test.startTest();
        Passfort_Webhook_Log__c log = new Passfort_Webhook_Log__c();
        PassfortUtil.PassfortProfileProcessingWrapper wrapper = PassfortUtil.updateAccout(profileId, log);
        Test.stopTest();

        // Verify
        System.assert(wrapper.logMessage.contains('does not exists in Salesforce'));
    }
    
	public class PassfortMockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse response;
    
        public PassfortMockHttpResponseGenerator(HttpResponse response) {
            this.response = response;
        }
    
        public HTTPResponse respond(HTTPRequest req) {
            return response;
        }
    }
    
    

    @isTest
    static void testUpdateAccount_SuccessfulUpdate() {
        // Insert a single account with the same Passfort_Profile_Id__c
        Account acc = new Account(Name = 'Test Account', Passfort_Profile_Id__c = 'profile1');
        insert acc;

        // Mock the response for Passfort.getProfileDetails
        String jsonResponse = '{ "id": "profile1", "applications": [{ "id": "app1", "status": "approved", "flag": "green", "product": { "name": "Product1" }, "risk": { "breakdown": { "components": [ {';
        jsonResponse = jsonResponse + ' "input_value": "Custom Field Value 1", "category": { "custom_field_name": "s_sic_code", "type": "CUSTOM_FIELD" ';
        jsonResponse = jsonResponse + ' } }, { "input_value": "Custom Field Value 2","category": { "custom_field_name": "s_complex_structure","type": "CUSTOM_FIELD" ';
        jsonResponse = jsonResponse + ' }},{ "input_value": "Custom Field Value 3", "category": { "custom_field_name": "s_tansaction_representation_country_1", ';
        jsonResponse = jsonResponse + '  "type": "CUSTOM_FIELD" } }, {"input_value": "USA","category": {"type": "COUNTRY_OF_INCORPORATION"} },';
        jsonResponse = jsonResponse + ' { "input_value": "Custom Field Value 1", "category": { "custom_field_name": "s_tansaction_representation_country_2",  "type": "CUSTOM_FIELD" }  },';    
        jsonResponse = jsonResponse + ' { "input_value": "Custom Field Value 1", "category": { "custom_field_name": "s_tansaction_representation_country_3",  "type": "CUSTOM_FIELD" }  },';    
        jsonResponse = jsonResponse + ' { "input_value": "Custom Field Value 1", "category": { "custom_field_name": "s_tansaction_representation_country_4",  "type": "CUSTOM_FIELD" }  },';    
        jsonResponse = jsonResponse + ' { "input_value": "Custom Field Value 1", "category": { "custom_field_name": "s_transaction_representation_country_5",  "type": "CUSTOM_FIELD" }  },';    
        jsonResponse = jsonResponse + ' { "input_value": "Custom Field Value 1", "category": { "custom_field_name": "s_regulatory_status",  "type": "CUSTOM_FIELD" }  },';    
        jsonResponse = jsonResponse + ' { "input_value": "Custom Field Value 1", "category": { "custom_field_name": "s_delivery_channel",  "type": "CUSTOM_FIELD" }  }';    
        
        jsonResponse = jsonResponse + '  ] } }, "assignments": [{ "assignee": { "name": "Assignee1" } }] }], "risk": { "overall_risk": { "category": "High", "score": 75 } }, "tags": [{ "name": "Tag1" }], "collected_data":';
        jsonResponse = jsonResponse + ' { "custom_fields_data": { "s_product":"Product1","s_company_id": null, "s_1_d_trading_name_2": "2 trad", "s_website_url": "2 trad","s_mlro_delegate_high_risk": "2 trad","s_contact_email_address": "1@g.com","s_entity_type": "2 trad","s_1_n_tax_id_number": "2 trad","s_web_review": "2 trad","s_verify_open_loop": "2 trad","s_bo_at_25": "2 trad",';
        jsonResponse = jsonResponse + ' "s_address_check_select": "2 trad", "s_currency_selection_payment_ss": "2", "n_maximum_payment_size_2": 2, "n_project_value_of_payments_2": 2, "n_total_value_of_payments_2": 2, "n_typical_payment_size_1": 2, "s_transaction_1_1": "1", "s_transaction_1": "2", "s_transaction_3": "2", "s_transaction_4": "2",';
        jsonResponse = jsonResponse + ' "s_transaction_5": "2", "s_bank_account_name": "2", "s_bank_bic_swift_code": "2", "s_bank_iban": "2", "n_money_moved_annually_2": "2", "s_advance_payment_types_1": "2", "n_money_moved_annually_debit_cards": "1", "s_other_text_1": "2", "n_percentage_volume_1": 2, "n_how_far_in_advance_1": 2, ';
        
        jsonResponse = jsonResponse + ' "metadata": { "number": 123456, "name": "test", "addresses":[{ "address": {"original_freeform_address": "1, Gran via, Madrid, MD", "country": "ESP" }, "type": "registered_address" }]},';
        
        jsonResponse = jsonResponse + '"s_trading_name": "Trading Name" } }, "checks": [] }';
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody(jsonResponse);
        mockResponse.setStatusCode(200);
        PassfortUtilTest.setMockHttpResponse(mockResponse);

        Test.startTest();
        Passfort_Webhook_Log__c log = new Passfort_Webhook_Log__c();
        PassfortUtil.PassfortProfileProcessingWrapper result = PassfortUtil.updateAccout('profile1', log);
        Test.stopTest();
        System.assert(result.logMessage.contains('Updated Account Id'), 'Expected log message for updated account');
        Account updatedAcc = result.acct;
        System.assertEquals('profile1', updatedAcc.Passfort_Profile_Id__c);
        System.assertEquals('High', updatedAcc.KYC_Risk_Level__c);
        System.assertEquals(75, updatedAcc.KYC_Risk_Score__c);
        System.assertEquals('Tag1,', updatedAcc.KYC_Tags__c);

        // Verify KYC application records
        KYC_Application__c kycApp = result.apps[0];
        System.assertEquals('app1', kycApp.Application_ID__c);
        System.assertEquals('approved', kycApp.Status__c);
        System.assertEquals('green', kycApp.Flag__c);
        System.assertEquals('Product1', kycApp.Product_Name__c);
        System.assertEquals('Assignee1', kycApp.KYC_Assignee__c);
    }

    private static void setMockHttpResponse(HttpResponse response) {
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl(response));
    }
    
    private class HttpCalloutMockImpl implements HttpCalloutMock {
        private HttpResponse response;
        
        public HttpCalloutMockImpl(HttpResponse response) {
            this.response = response;
        }
        
        public HttpResponse respond(HttpRequest req) {
            return response;
        }
    }
}