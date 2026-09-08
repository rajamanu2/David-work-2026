@isTest(seeAllData=true)
private class QCRigidCertificatePDFGenerator_Test {

    @isTest
    static void test_generateAndSavePDF() {
        List<ProductTest__c> recent = [
            SELECT Id 
            FROM ProductTest__c 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];

        if (!recent.isEmpty()) {
            Test.startTest();
            QCRigidCertificatePDFGenerator.generateAndSavePDF(new List<Id>{ recent[0].Id });
            Test.stopTest();
        }
    }
}