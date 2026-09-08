@IsTest
private class PassfortAuditReportTest {

    @IsTest
    private static void shouldParseAuditReport() {
        
        String auditReport =
        '[{' +
            '"action": "created-profile",' +
            '"filename": null,' +
            '"id": "' + UUID.randomUUID().toString() + '",' +
            '"message": null,' +
            '"profileID": "' + UUID.randomUUID().toString() + '",' +
            '"ref_data": {},' +
            '"signature": null,' +
            '"timestamp": 1234567891234,' +
            '"user": {' +
                '"id": "' + UUID.randomUUID().toString() + '",' +
                '"name": "John Doe",' +
                '"email": "john.doe@flywire.com"' +
            '},' +
            '"apikey": null,' +
            '"filehash": null,' +
            '"auditee": {' +
                '"id": "' + UUID.randomUUID().toString() + '",' +
                '"name": "John Doe",' +
                '"user": {' +
                    '"id": "' + UUID.randomUUID().toString() + '",' +
                    '"email": "john.doe@flywire.com"' +
                '}' +
            '},' +
            '"ref_auditID": null' +
        '}]';

        Test.startTest();
        List<PassfortAuditReport> audits = PassfortAuditReport.parseMultiple(auditReport);
        Test.stopTest();

        Assert.isInstanceOfType(audits[0], PassfortAuditReport.class);
        Assert.areEqual('created-profile', audits[0].action);
    }
}