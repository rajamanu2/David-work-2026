@IsTest
private class P_ClassicNoteTriggerTest {

    @TestSetup
    static void init(){
        Account a = new Account(Name = 'Test Co');
        insert a;

        Opportunity o = new Opportunity(Name = 'Test Opp', AccountId = a.Id, CloseDate = Date.today(),
                            StageName = 'Prospecting');
        insert o;
    }

    @IsTest
    static void simpleNoteNotOnOpp() {

        Account a = [SELECT Id FROM Account LIMIT 1];
        Note n = new Note(ParentId = a.Id, Title = 'Test Note', Body = 'Document Hello There was signed by Simon Toumes.');
        Test.startTest();
        insert n;
        Test.stopTest();

        System.assertEquals(true, true, 'If we got here the Note processing ran OK by doing nothing wrong');
    }

    @IsTest
    static void simpleNoteOnOpp() {

        Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
        Note n = new Note(ParentId = o.Id, Title = 'Test Note', Body = 'Random Note not part of PandaDoc. ');
        Test.startTest();
        insert n;
        Test.stopTest();

        Opportunity theOpp = [SELECT Id, Customer_Signed_By__c, Customer_Signed_Date__c, Signature_Type__c
                                FROM Opportunity WHERE Id = :o.Id LIMIT 1];

        System.assertEquals(null, theOpp.Customer_Signed_By__c, 'Customer_Signed_By__c was set when it should not have been.');
        System.assertEquals(null, theOpp.Customer_Signed_Date__c, 'Customer_Signed_Date__c was set when it should not have been.');
        System.assertEquals(null, theOpp.Signature_Type__c, 'Signature_Type__c was set when it should not have been.');
    }

    @IsTest
    static void pandaSignedNoteOnOpp() {

        Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
        Note n = new Note(ParentId = o.Id, Title = 'Test Note', Body = 'Document Hello There was signed by Simon Toumes. ');
        Test.startTest();
        insert n;
        Test.stopTest();

        Opportunity theOpp = [SELECT Id, Customer_Signed_By__c, Customer_Signed_Date__c, Signature_Type__c
        FROM Opportunity WHERE Id = :o.Id LIMIT 1];

        System.assertEquals('Simon Toumes', theOpp.Customer_Signed_By__c, 'Customer_Signed_By__c was not set correctly on a Signed Note.');
        System.assertEquals(null, theOpp.Customer_Signed_Date__c, 'Customer_Signed_Date__c was not set correctly on a Signed Note.');
        System.assertEquals(null, theOpp.Signature_Type__c, 'Signature_Type__c was not set correctly on a Signed Note.');
    }

    @IsTest
    static void pandaCompleteNoteOnOpp() {

        Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
        Note n = new Note(ParentId = o.Id, Title = 'Test Note', Body = 'Document Hello There has been completed. ');
        Test.startTest();
        insert n;
        Test.stopTest();

        Opportunity theOpp = [SELECT Id, Customer_Signed_By__c, Customer_Signed_Date__c, Signature_Type__c
        FROM Opportunity WHERE Id = :o.Id LIMIT 1];

        System.assertEquals(null, theOpp.Customer_Signed_By__c, 'Customer_Signed_By__c was not set correctly on a Completed Note.');
        System.assertEquals(Date.today(), theOpp.Customer_Signed_Date__c, 'Customer_Signed_Date__c was not set correctly on a Completed Note.');
        System.assertEquals(PandaDocService.SIGNEDTYPE, theOpp.Signature_Type__c, 'Signature_Type__c was not set correctly on a Completed Note.');
    }

}