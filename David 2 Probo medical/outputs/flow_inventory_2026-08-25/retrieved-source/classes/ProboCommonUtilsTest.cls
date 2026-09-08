@IsTest
private class ProboCommonUtilsTest {

    @isTest private static void testRecTypes(){
        List<RecordType> theTypes = ProboCommonUtils.getRecordTypes('Opportunity');
        system.assertNotEquals(0, theTypes.size(), 'Did not properly return Record Type list');
    }

    @isTest private static void testGettingStdPriceBookId() {

        Id theID = ProboCommonUtils.getStdPricebookId();
        system.assertNotEquals(null, theID, 'Did not properly retrieve the Standard PriceBook ID');
    }

    @isTest private static void testGettingCurrentUserInfo() {

        User theUser = ProboCommonUtils.getCurrentUser();
        system.assertNotEquals(null, theUser, 'Did not properly retrieve the current User Info');
    }

    @isTest private static void fullObjectSelect() {

        String allFields = ProboCommonUtils.fullObjectSelect('Account');
        system.assertNotEquals(null, allFields, 'fullObjectSelect did not return any fields');
    }

}