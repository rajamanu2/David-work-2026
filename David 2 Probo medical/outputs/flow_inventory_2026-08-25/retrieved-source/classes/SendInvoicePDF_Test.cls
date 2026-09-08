@IsTest(SeeAllData=true)
public class SendInvoicePDF_Test {

    @IsTest
    static void testProcessRecords_WithFSR_AndHIPAA() {

        // ----- Test data setup -----
        Account acc = new Account(Name = 'Test Invoice Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        // Create an FSR ContentVersion
        ContentVersion fsr = new ContentVersion(
            Title = 'FSR_Test_Document',
            PathOnClient = 'FSR_Test_Document.pdf',
            VersionData = Blob.valueOf('FSR DATA')
        );
        insert fsr;

        // Link FSR to Opportunity
        fsr = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :fsr.Id
        ];

        ContentDocumentLink fsrLink = new ContentDocumentLink(
            ContentDocumentId = fsr.ContentDocumentId,
            LinkedEntityId = opp.Id,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        insert fsrLink;

        // ----- Build Flow Input -----
        SendInvoicePDF.flowInput input = new SendInvoicePDF.flowInput();
        input.currentRecordId = acc.Id;
        input.oppRecordId = opp.Id;
        input.eMailList = new List<String>{ 'test1@example.com', 'test2@example.com' };
        input.invoiceName = 'INV-1001';
        input.sendFSRAttachment = true;
        input.includeHIPAAWarning = true;

        List<SendInvoicePDF.flowInput> inputs = new List<SendInvoicePDF.flowInput>{ input };

        // ----- Execute -----
        Test.startTest();
        List<SendInvoicePDF.flowOutput> results =
            SendInvoicePDF.processRecords(inputs);
        Test.stopTest();

        // ----- Assertions -----
        System.assertEquals(1, results.size());
        System.assertEquals(acc.Id, results[0].currentRecordId);
        System.assertEquals(null, results[0].errorMessage);
    }

    @IsTest
    static void testSendEmail_NoFSR_NoHIPAA() {

        // ----- Test data setup -----
        Account acc = new Account(Name = 'No FSR Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'No FSR Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15),
            AccountId = acc.Id
        );
        insert opp;

        // ----- Execute SendEmail directly -----
        Test.startTest();
        SendInvoicePDF.SendEmail(
            acc.Id,
            'nofsr@example.com',
            opp.Id,
            'INV-2002',
            false,   // sendFSR
            false    // includeHIPAA
        );
        Test.stopTest();

        // ----- Validate content was created -----
        List<ContentDocumentLink> links = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :acc.Id
        ];
        System.assert(links.size() > 0, 'Invoice PDF should be linked to the record');
    }
}