@isTest
public class RecordUnlockerTest {

    @testSetup
    static void setupTestRecords() {
        // Create records once for all test methods
        Account acc1 = new Account(Name='Locked Account');
        Account acc2 = new Account(Name='Unlocked Account');

        List<Account> accts = new List<Account>{acc1, acc2};
        insert accts;        
    } 

    @isTest
    static void testRecordUnlocker() {
        // Retrieve test records
        Account lockedAcc = [SELECT Id FROM Account WHERE Name = 'Locked Account' LIMIT 1];
        Account unlockedAcc = [SELECT Id FROM Account WHERE Name = 'Unlocked Account' LIMIT 1];

        // Lock one of the records so we can test unlocking it
        Approval.lock(lockedAcc.Id);

        Test.startTest();
        
        // 1. Test unlocking a locked record
        List<String> successResult = RecordUnlocker.unlockRecord(new List<Id>{lockedAcc.Id});
        System.assertEquals('Success', successResult[0], 'The result should be Success.');
        System.assertEquals(false, Approval.isLocked(lockedAcc.Id), 'The record should no longer be locked.');

        // 2. Test attempting to unlock an already unlocked record
        List<String> alreadyUnlockedResult = RecordUnlocker.unlockRecord(new List<Id>{unlockedAcc.Id});
        System.assertEquals('Success: Record is already unlocked.', alreadyUnlockedResult[0], 'It should return the already unlocked message.');

        // 3. Test passing a null list
        List<String> nullListResult = RecordUnlocker.unlockRecord(null);
        System.assertEquals('Error: No Record ID was provided.', nullListResult[0], 'It should catch the null list.');

        // 4. Test passing an empty list
        List<String> emptyListResult = RecordUnlocker.unlockRecord(new List<Id>());
        System.assertEquals('Error: No Record ID was provided.', emptyListResult[0], 'It should catch the empty list.');

        // 5. Test passing a list with a null ID
        List<String> nullIdResult = RecordUnlocker.unlockRecord(new List<Id>{null});
        System.assertEquals('Error: No Record ID was provided.', nullIdResult[0], 'It should catch the null ID inside the list.');

        Test.stopTest();
    }
    
    @isTest
    static void testCheckLockStatus() {
        // Retrieve the test records created in @testSetup
        Account lockedAcc = [SELECT Id FROM Account WHERE Name = 'Locked Account' LIMIT 1];
        Account unlockedAcc = [SELECT Id FROM Account WHERE Name = 'Unlocked Account' LIMIT 1];

        // Lock one of the records natively
        Approval.lock(lockedAcc.Id);

        Test.startTest();
        
        // 1. Test a locked record
        List<Boolean> lockedResult = RecordLockStatusChecker.checkLockStatus(new List<Id>{lockedAcc.Id});
        System.assertEquals(true, lockedResult[0], 'The locked account should return true.');

        // 2. Test an unlocked record
        List<Boolean> unlockedResult = RecordLockStatusChecker.checkLockStatus(new List<Id>{unlockedAcc.Id});
        System.assertEquals(false, unlockedResult[0], 'The unlocked account should return false.');

        // 3. Test passing a null ID (to cover your null check logic)
        List<Boolean> nullResult = RecordLockStatusChecker.checkLockStatus(new List<Id>{null});
        System.assertEquals(false, nullResult[0], 'A null ID should safely return false to prevent Flow crashes.');

        Test.stopTest();
    }
    
    @isTest
	static void testUnlockErrorHandling() {
        // 1. Create a Standard User
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User restrictedUser = new User(
            Alias = 'standt', 
            Email='standarduser@flywire.com', 
            EmailEncodingKey='UTF-8', 
            LastName='Testing', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', 
            ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='restricteduser' + DateTime.now().getTime() + '@testorg.com'
        );
        insert restrictedUser;
    
        // 2. Create and lock an Account as the System Admin
        Account lockedAcc = new Account(Name='Admin Locked Account');
        insert lockedAcc;
        Approval.lock(lockedAcc.Id);
    
        Test.startTest();
    
        // 3. Attempt to unlock the record as the restricted user
        System.runAs(restrictedUser) {
            try {
                // This will throw an exception if it fails
                List<String> result = RecordUnlocker.unlockRecord(new List<Id>{lockedAcc.Id});
            } catch (Exception e) {
                // Catch the exception and pass the message to the Flow
            }
        }
    
        Test.stopTest();
    }

}