// TEST CLASS
@IsTest(seeAllData=true)
private class SaveCreditMemoPdfFileActionTest {

    @IsTest
    static void testSaveUsingExistingCreditMemo() {
        // Try to find a Credit Memo with an Invoice (so the UK/US logic can run cleanly)
        Credit_Memo__c cm = [
            SELECT Id, Name, Invoice__c, Invoice_Entity_Location__c
            FROM Credit_Memo__c
            WHERE Invoice__c != null
            LIMIT 1
        ];

        System.assertNotEquals(null, cm, 'At least one Credit_Memo__c with an Invoice__c must exist to run this test.');

        Test.startTest();
        SaveCreditMemoPdfFileAction.Request req = new SaveCreditMemoPdfFileAction.Request();
        req.recordId = cm.Id;
        req.fileTitle = 'Test_Credit_Memo_PDF';

        List<SaveCreditMemoPdfFileAction.Result> results =
            SaveCreditMemoPdfFileAction.save(new List<SaveCreditMemoPdfFileAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'One result expected.');
        SaveCreditMemoPdfFileAction.Result res = results[0];

        System.assertEquals(true, res.success, 'The PDF generation and save should succeed.');
        System.assertNotEquals(null, res.contentDocumentId, 'A ContentDocumentId should be returned.');
        System.assertNotEquals(null, res.contentVersionId, 'A ContentVersionId should be returned.');
        System.assert(res.fileName != null && res.fileName.endsWith('.pdf'), 'Filename should end with .pdf');

        // Validate the VF page selection logic (best-effort based on the record found)
        String loc = cm.Invoice__c != null ? cm.Invoice_Entity_Location__c : null;
        Boolean expectedUk = (loc != null) && (loc.trim().startsWith('1400') || loc.trim().startsWith('1500'));
        System.assertEquals(expectedUk, res.isUk, 'UK detection should match the invoice location prefix rule.');
        System.assertEquals(expectedUk ? 'Credit_Memo_UK_PDF' : 'Credit_Memo_PDF', res.vfPageName, 'VF page name should match region.');
    }
}