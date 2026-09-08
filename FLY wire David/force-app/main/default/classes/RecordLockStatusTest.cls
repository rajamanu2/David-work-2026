@isTest
public class RecordLockStatusTest {

    @isTest
    static void testRecordLockStatus() {
        Account acc1 = new Account(Name='Test1');
        
        Account acc2 = new Account(Name='Test2');

        List<Account> accts = new List<Account>();
        accts.add(acc1);
        accts.add(acc2);
        insert accts;        

        Test.startTest();
        // Lock one of the records
        Approval.LockResult lockResult = Approval.lock(acc1.Id);
        Test.stopTest();

        // Verify lock status after locking
        List<Boolean> lockStatusAfter = RecordLockStatus.checkRecordLockStatus(new List<String>{acc1.Id, acc2.Id});
        System.assertEquals(true, lockStatusAfter[0]);
        System.assertEquals(false, lockStatusAfter[1]);

    }
}