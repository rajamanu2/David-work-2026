@isTest
private with sharing class PassfortFormExpiryAsyncProcessorTest {
    @TestSetup
    static void makeData() {
        // Tetsing for 20 accounts at the same time since the 
        // PassfortFormExpiryAsyncProcessor batch size is 20
        List<Account> testAccts = new List<Account>();
        for (Integer i = 0; i < 20; i++) {
            testAccts.add(new Account(
                Name = 'Test Account ' + i,
                Passfort_KYC_Form__c = 'www.test.account.' + i + '.com',
                Passfort_Profile_Id__c = UUID.randomUUID().toString()
            ));
        }

        insert testAccts;
    }

    @isTest
    private static void shouldClearAccountKycUrlFieldForExpiredApplications() {

        List<Account> acctBeforeCheck = [SELECT Id, Passfort_Profile_Id__c, Passfort_KYC_Form__c FROM Account];
        
        for (Account currentAcctBeforeCheck : acctBeforeCheck) {
            Assert.isNotNull(currentAcctBeforeCheck.Passfort_KYC_Form__c);
        }

        HttpResponse response = new HttpResponse();
        // Instatiated form date is previous to expired form date, therefore this form is expired
        String body =
        '[' +
            '{' +
            '"action": "instantiated-form",' +
            '"filename": null,' +
            '"id": "' + UUID.randomUUID().toString() + '",' +
            '"message": null,' +
            '"profileID": "' + acctBeforeCheck[0].Passfort_Profile_Id__c + '",' +
            '"ref_data": {},' +
            '"signature": null,' +
            '"timestamp": ' + DateTime.now().getTime() + ',' +
            '"apikey": null,' +
            '"filehash": null' +
        '},' +
        '{' +
            '"action": "expired-form",' +
            '"filename": null,' +
            '"id": "' + UUID.randomUUID().toString() + '",' +
            '"message": null,' +
            '"profileID": "' + acctBeforeCheck[0].Passfort_Profile_Id__c + '",' +
            '"ref_data": {},' +
            '"signature": null,' +
            '"timestamp": ' + (DateTime.now().getTime() + 1000) + ',' +
            '"apikey": null,' +
            '"filehash": null' +
        '}]';

        response.setBody(body);
        response.setStatusCode(200);

        setMockHttpResponse(response);

        Test.startTest();
        Database.executeBatch(new PassfortFormExpiryAsyncProcessor(), 20);
        Test.stopTest();

        List<Account> acctAfterCheck = [SELECT Id, Passfort_Profile_Id__c, Passfort_KYC_Form__c FROM Account];
        
        for (Account currentAcctAfterCheck : acctAfterCheck) {
            Assert.isNull(currentAcctAfterCheck.Passfort_KYC_Form__c);
        }
    }

    private static void setMockHttpResponse(HttpResponse response) {
        Test.setMock(HttpCalloutMock.class, new PassfortProfileAuditReportMock(response));
    }

    private class PassfortProfileAuditReportMock implements HttpCalloutMock {
        private HttpResponse response;
        
        public PassfortProfileAuditReportMock(HttpResponse response) {
            this.response = response;
        }
        
        public HttpResponse respond(HttpRequest req) {
            return response;
        }
    }
}