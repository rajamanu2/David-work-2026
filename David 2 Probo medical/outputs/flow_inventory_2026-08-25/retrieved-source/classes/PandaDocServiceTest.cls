@IsTest
private class PandaDocServiceTest {

    @TestSetup
    static void init(){
        Account a = new Account(Name = 'Test Co');
        insert a;

        Opportunity o = new Opportunity(Name = 'Test Opp', AccountId = a.Id, CloseDate = Date.today(),
                StageName = 'Prospecting');
        insert o;
    }

    @IsTest
    static void parseSignedByText() {

        String signerName = 'Simon Toumes';
        Test.startTest();
        Map<PandaDocService.PandaDocSigningInfo, Object> info = PandaDocService.parseNoteBody('Document Hello There was signed by ' + signerName + ' . ');
        Test.stopTest();

        System.assertEquals(1, info.size(), 'Parsing a SignedBy Note returned the wrong information');
        System.assertEquals(signerName, String.valueOf(info.get(PandaDocService.PandaDocSigningInfo.SignerName)), 'SignedBy was not properly returned.');
    }

    @IsTest
    static void parseCompletedText() {

        Test.startTest();
        Map<PandaDocService.PandaDocSigningInfo, Object> info = PandaDocService.parseNoteBody('Document Hello There has been completed, really it has.');
        Test.stopTest();

        System.assertEquals(2, info.size(), 'Parsing a Completed Note returned the wrong information');
        System.assertEquals(Date.today(), Date.valueOf(info.get(PandaDocService.PandaDocSigningInfo.SignedDate)), 'SignedDate was not properly returned.');
        System.assertEquals(PandaDocService.SIGNEDTYPE, String.valueOf(info.get(PandaDocService.PandaDocSigningInfo.SignedType)), 'SignedType was not properly returned.');
    }


}