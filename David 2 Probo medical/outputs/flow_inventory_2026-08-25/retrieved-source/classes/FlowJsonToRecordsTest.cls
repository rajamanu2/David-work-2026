@IsTest
private class FlowJsonToRecordsTest {

    @IsTest
    static void testValidJson() {
        // Arrange
        Account a1 = new Account(Name = 'Test Account 1');
        Account a2 = new Account(Name = 'Test Account 2');
        insert new List<Account>{ a1, a2 };

        String json = JSON.serialize(new List<Account>{ a1, a2 });

        FlowJsonToRecords.Request req = new FlowJsonToRecords.Request();
        req.json = json;
        req.sObjectApiName = 'Account';

        // Act
        Test.startTest();
        List<FlowJsonToRecords.Response> responses = FlowJsonToRecords.run(
            new List<FlowJsonToRecords.Request>{ req }
        );
        Test.stopTest();

        // Assert
        Assert.areEqual(1, responses.size(), 'Should return one response');
        Assert.areEqual(2, responses[0].records.size(), 'Should return 2 records');
        Assert.areEqual(a1.Id, responses[0].records[0].Id, 'First record Id should match');
        Assert.areEqual(a2.Id, responses[0].records[1].Id, 'Second record Id should match');
    }

    @IsTest
    static void testSingleRecord() {
        // Arrange
        Account a = new Account(Name = 'Single Account');
        insert a;

        String json = JSON.serialize(new List<Account>{ a });

        FlowJsonToRecords.Request req = new FlowJsonToRecords.Request();
        req.json = json;
        req.sObjectApiName = 'Account';

        // Act
        Test.startTest();
        List<FlowJsonToRecords.Response> responses = FlowJsonToRecords.run(
            new List<FlowJsonToRecords.Request>{ req }
        );
        Test.stopTest();

        // Assert
        Assert.areEqual(1, responses[0].records.size(), 'Should return 1 record');
        Assert.areEqual(a.Id, responses[0].records[0].Id, 'Record Id should match');
    }

    @IsTest
    static void testEmptyJson() {
        // Arrange
        FlowJsonToRecords.Request req = new FlowJsonToRecords.Request();
        req.json = '[]';
        req.sObjectApiName = 'Account';

        // Act
        Test.startTest();
        List<FlowJsonToRecords.Response> responses = FlowJsonToRecords.run(
            new List<FlowJsonToRecords.Request>{ req }
        );
        Test.stopTest();

        // Assert
        Assert.areEqual(1, responses.size(), 'Should return one response');
        Assert.areEqual(0, responses[0].records.size(), 'Should return 0 records for empty JSON');
    }

    @IsTest
    static void testInvalidSObjectName() {
        // Arrange
        FlowJsonToRecords.Request req = new FlowJsonToRecords.Request();
        req.json = '[{"Name":"Test"}]';
        req.sObjectApiName = 'InvalidObject__xyz';

        // Act
        Test.startTest();
        List<FlowJsonToRecords.Response> responses = FlowJsonToRecords.run(
            new List<FlowJsonToRecords.Request>{ req }
        );
        Test.stopTest();

        // Assert — class returns null when sObject name is invalid
        Assert.isNull(responses, 'Should return null for invalid sObject name');
    }

    @IsTest
    static void testMultipleRequests() {
        // Arrange — put multiple records of different types in one request
        Account a = new Account(Name = 'Bulk Account');
        insert a;

        Account a2 = new Account(Name = 'Bulk Account 2');
        insert a2;

        String json = JSON.serialize(new List<Account>{ a, a2 });

        FlowJsonToRecords.Request req = new FlowJsonToRecords.Request();
        req.json = json;
        req.sObjectApiName = 'Account';

        // Act
        Test.startTest();
        List<FlowJsonToRecords.Response> responses = FlowJsonToRecords.run(
            new List<FlowJsonToRecords.Request>{ req }
        );
        Test.stopTest();

        // Assert — one response containing both records
        Assert.areEqual(1, responses.size(), 'Should return one response');
        Assert.areEqual(2, responses[0].records.size(), 'Response should contain 2 records');
        Assert.areEqual(a.Id,  responses[0].records[0].Id, 'First Account Id should match');
        Assert.areEqual(a2.Id, responses[0].records[1].Id, 'Second Account Id should match');
    }

    @IsTest
    static void testFieldValuesPreserved() {
        // Arrange
        Account a = new Account(
            Name        = 'Field Test Account',
            Phone       = '555-1234',
            BillingCity = 'Portland'
        );
        insert a;

        String json = JSON.serialize(new List<Account>{ a });

        FlowJsonToRecords.Request req = new FlowJsonToRecords.Request();
        req.json = json;
        req.sObjectApiName = 'Account';

        // Act
        Test.startTest();
        List<FlowJsonToRecords.Response> responses = FlowJsonToRecords.run(
            new List<FlowJsonToRecords.Request>{ req }
        );
        Test.stopTest();

        // Assert
        Account result = (Account) responses[0].records[0];
        Assert.areEqual('Field Test Account', result.Name,        'Name should be preserved');
        Assert.areEqual('555-1234',           result.Phone,       'Phone should be preserved');
        Assert.areEqual('Portland',           result.BillingCity, 'BillingCity should be preserved');
    }
}