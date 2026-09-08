@IsTest
private class FlowRecordsToJsonTest {

    @IsTest
    static void testValidRecords() {
        // Arrange
        Account a1 = new Account(Name = 'Test Account 1');
        Account a2 = new Account(Name = 'Test Account 2');
        insert new List<Account>{ a1, a2 };

        FlowRecordsToJson.Request req = new FlowRecordsToJson.Request();
        req.records = new List<SObject>{ a1, a2 };

        // Act
        Test.startTest();
        List<FlowRecordsToJson.Response> responses = FlowRecordsToJson.run(
            new List<FlowRecordsToJson.Request>{ req }
        );
        Test.stopTest();

        // Assert
        Assert.areEqual(1, responses.size(), 'Should return one response');
        Assert.isNotNull(responses[0].json, 'JSON should not be null');

        List<Object> parsed = (List<Object>) JSON.deserializeUntyped(responses[0].json);
        Assert.areEqual(2, parsed.size(), 'Parsed JSON should contain 2 records');
    }

    @IsTest
    static void testSingleRecord() {
        // Arrange
        Account a = new Account(Name = 'Single Account');
        insert a;

        FlowRecordsToJson.Request req = new FlowRecordsToJson.Request();
        req.records = new List<SObject>{ a };

        // Act
        Test.startTest();
        List<FlowRecordsToJson.Response> responses = FlowRecordsToJson.run(
            new List<FlowRecordsToJson.Request>{ req }
        );
        Test.stopTest();

        // Assert
        List<Object> parsed = (List<Object>) JSON.deserializeUntyped(responses[0].json);
        Assert.areEqual(1, parsed.size(), 'Parsed JSON should contain 1 record');

        Map<String, Object> record = (Map<String, Object>) parsed[0];
        Assert.areEqual(a.Id, (String) record.get('Id'), 'Id should be serialized correctly');
        Assert.areEqual('Single Account', (String) record.get('Name'), 'Name should be serialized correctly');
    }

    @IsTest
    static void testEmptyList() {
        // Arrange
        FlowRecordsToJson.Request req = new FlowRecordsToJson.Request();
        req.records = new List<SObject>();

        // Act
        Test.startTest();
        List<FlowRecordsToJson.Response> responses = FlowRecordsToJson.run(
            new List<FlowRecordsToJson.Request>{ req }
        );
        Test.stopTest();

        // Assert
        Assert.isNotNull(responses[0].json, 'JSON should not be null');
        List<Object> parsed = (List<Object>) JSON.deserializeUntyped(responses[0].json);
        Assert.areEqual(0, parsed.size(), 'Parsed JSON should be an empty list');
    }

    @IsTest
    static void testMultipleRequests() {
        // Arrange
        Account a = new Account(Name = 'Bulk Account');
        Contact c = new Contact(LastName = 'Bulk Contact');
        insert new List<SObject>{ a, c };

        FlowRecordsToJson.Request req1 = new FlowRecordsToJson.Request();
        req1.records = new List<SObject>{ a };

        FlowRecordsToJson.Request req2 = new FlowRecordsToJson.Request();
        req2.records = new List<SObject>{ c };

        // Act
        Test.startTest();
        List<FlowRecordsToJson.Response> responses = FlowRecordsToJson.run(
            new List<FlowRecordsToJson.Request>{ req1, req2 }
        );
        Test.stopTest();

        // Assert
        Assert.areEqual(2, responses.size(), 'Should return two responses');

        List<Object> parsed1 = (List<Object>) JSON.deserializeUntyped(responses[0].json);
        List<Object> parsed2 = (List<Object>) JSON.deserializeUntyped(responses[1].json);

        Assert.areEqual(1, parsed1.size(), 'First response should contain 1 record');
        Assert.areEqual(1, parsed2.size(), 'Second response should contain 1 record');
    }

    @IsTest
    static void testFieldValuesPreserved() {
        // Arrange
        Account a = new Account(
            Name        = 'Field Test Account',
            Phone       = '555-9876',
            BillingCity = 'Seattle'
        );
        insert a;

        FlowRecordsToJson.Request req = new FlowRecordsToJson.Request();
        req.records = new List<SObject>{ a };

        // Act
        Test.startTest();
        List<FlowRecordsToJson.Response> responses = FlowRecordsToJson.run(
            new List<FlowRecordsToJson.Request>{ req }
        );
        Test.stopTest();

        // Assert
        List<Object> parsed = (List<Object>) JSON.deserializeUntyped(responses[0].json);
        Map<String, Object> record = (Map<String, Object>) parsed[0];

        Assert.areEqual('Field Test Account', (String) record.get('Name'),        'Name should be preserved');
        Assert.areEqual('555-9876',           (String) record.get('Phone'),       'Phone should be preserved');
        Assert.areEqual('Seattle',            (String) record.get('BillingCity'), 'BillingCity should be preserved');
    }

    @IsTest
    static void testJsonIsValidAndParseable() {
        // Arrange
        Account a = new Account(Name = 'Parse Test');
        insert a;

        FlowRecordsToJson.Request req = new FlowRecordsToJson.Request();
        req.records = new List<SObject>{ a };

        // Act
        Test.startTest();
        List<FlowRecordsToJson.Response> responses = FlowRecordsToJson.run(
            new List<FlowRecordsToJson.Request>{ req }
        );
        Test.stopTest();

        // Assert — confirm the output is valid JSON that can round-trip back
        String outputJson = responses[0].json;
        Boolean isValid = true;
        try {
            JSON.deserializeUntyped(outputJson);
        } catch (Exception ex) {
            isValid = false;
        }
        Assert.isTrue(isValid, 'Output should be valid parseable JSON');
    }
}