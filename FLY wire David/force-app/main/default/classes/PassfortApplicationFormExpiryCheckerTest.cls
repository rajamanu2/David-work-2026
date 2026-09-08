@IsTest
private class PassfortApplicationFormExpiryCheckerTest {

    @TestSetup
    static void makeData() {
        insert(new Account(
            Name = 'Test Account 1',
            Passfort_KYC_Form__c = 'www.test.account.1.com',
            Passfort_Profile_Id__c = UUID.randomUUID().toString()
        ));
    }

    @IsTest
    private static void shouldCheckFormExpiryTrue() {
        Account acct = [SELECT Id, Passfort_Profile_Id__c, Passfort_KYC_Form__c FROM Account LIMIT 1];
        String passfortProfileId = acct.Passfort_Profile_Id__c;

        HttpResponse response = new HttpResponse();
        String body =
        '[{' +
            '"action": "expired-form",' +
            '"filename": null,' +
            '"id": "' + UUID.randomUUID().toString() + '",' +
            '"message": null,' +
            '"profileID": "' + passfortProfileId + '",' +
            '"ref_data": {},' +
            '"signature": null,' +
            '"timestamp": ' + DateTime.now().getTime() + ',' +
            '"apikey": null,' +
            '"filehash": null' +
        '}]';

        response.setBody(body);
        response.setStatusCode(200);

        setMockHttpResponse(response);

        Test.startTest();
        Map<String,Boolean> areExpired = PassfortApplicationFormExpiryChecker.areExpired(new List<Account>{ acct });
        Test.stopTest();

        Assert.isTrue(areExpired.values()[0]);
    }

    @IsTest
    private static void shouldCheckFormExpiryFalse() {
        Account acct = [SELECT Id, Passfort_Profile_Id__c, Passfort_KYC_Form__c FROM Account LIMIT 1];
        String passfortProfileId = acct.Passfort_Profile_Id__c;

        HttpResponse response = new HttpResponse();
        String body =
        '[{' +
            '"action": "instantiated-form",' +
            '"filename": null,' +
            '"id": "' + UUID.randomUUID().toString() + '",' +
            '"message": null,' +
            '"profileID": "' + passfortProfileId + '",' +
            '"ref_data": {},' +
            '"signature": null,' +
            '"timestamp": ' + DateTime.now().getTime() + ',' +
            '"apikey": null,' +
            '"filehash": null' +
        '}]';

        response.setBody(body);
        response.setStatusCode(200);

        setMockHttpResponse(response);

        Test.startTest();
        Map<String,Boolean> areExpired = PassfortApplicationFormExpiryChecker.areExpired(new List<Account>{ acct });
        Test.stopTest();

        Assert.isFalse(areExpired.values()[0]);
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