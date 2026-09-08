public class P_TestDeleteHandler {
	// This prevents anyone from deleting a test that has the completed by field filled in.
    public void checkDeletes(Map<Id, ProductTest__c> oldRecs) {
        for (ProductTest__c checkTest : oldRecs.values()) {
            if (checkTest.Test_Completed_By__c != null) {
                checkTest.addError('You can not delete this test !');
            }
        }
    }
}