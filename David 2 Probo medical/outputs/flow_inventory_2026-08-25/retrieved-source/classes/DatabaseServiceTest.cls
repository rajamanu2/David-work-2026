/**
 * Created by jeff on 11/19/18.
 */

@IsTest
private class DatabaseServiceTest {

    @IsTest static void insertListTest() {

        List<Account> aList = new List<Account>();
        aList.add(new Account(Name = 'test'));

        Test.startTest();
        DatabaseService.insertList(aList);
        Test.stopTest();

        List<Account> acctsToCheck = new List<Account>([SELECT Id, Name FROM Account]);
        system.assertEquals(1, acctsToCheck.size(), 'Insert was not successful');

    }

    @IsTest static void updateListTest() {
        List<Account> aList = new List<Account>();
        aList.add(new Account(Name = 'test'));
        insert aList;
        aList[0].Name = 'Updated Test';

        Test.startTest();
        DatabaseService.updateList(aList);
        Test.stopTest();

        List<Account> acctsToCheck = new List<Account>([SELECT Id, Name FROM Account]);

        system.assertEquals('Updated Test', acctsToCheck[0].Name, 'Update was not successful');
    }

    @IsTest static void upsertListTest() {
        List<Account> aList = new List<Account>();
        aList.add(new Account(Name = 'Upsert Account'));
        insert aList;
        aList[0].Name = 'Updated Test';
        aList.add(new Account(Name = 'test'));

        Test.startTest();
        DatabaseService.upsertList(aList);
        Test.stopTest();

        List<Account> acctsToCheck = new List<Account>([SELECT Id, Name FROM Account]);

        boolean foundinsert;
        boolean foundupdate;
        for(Account a : acctsToCheck){

            switch on a.Name {
                when 'Updated Test'{
                    foundupdate = true;
                }

                when 'test'{
                    foundinsert = true;
                }
            }
        }

        system.assertEquals(true, foundinsert, 'Upsert did not properly do an insert');
        system.assertEquals(true, foundupdate, 'Upsert did not properly do an update');
        system.assertEquals(2, acctsToCheck.size(), 'Upsert did not result in 2 Accounts');
    }


    @IsTest static void deleteListTest() {
        List<Account> aList = new List<Account>();
        aList.add(new Account(Name = 'test'));
        insert aList;

        Test.startTest();
        DatabaseService.deleteList(aList);
        Test.stopTest();

        List<Account> acctsToCheck = new List<Account>([SELECT Id, Name FROM Account]);

        system.assertEquals(0, acctsToCheck.size(), 'Delete was not successful');

    }

    @IsTest static void insertRecordTest() {

        Account a = new Account(Name = 'test');

        Test.startTest();
        DatabaseService.insertRecord(a);
        Test.stopTest();

        List<Account> acctsToCheck = new List<Account>([SELECT Id, Name FROM Account]);
        system.assertEquals(1, acctsToCheck.size(), 'Insert was not successful');

    }

    @IsTest static void updateRecordTest() {
        Account a = new Account(Name = 'test');
        insert a;
        a.Name = 'Updated Test';

        Test.startTest();
        DatabaseService.updateRecord(a);
        Test.stopTest();

        List<Account> acctsToCheck = new List<Account>([SELECT Id, Name FROM Account]);

        system.assertEquals('Updated Test', acctsToCheck[0].Name, 'Update was not successful');
    }


    @IsTest static void deleteRecordTest() {
        Account a = new Account(Name = 'test');
        insert a;

        Test.startTest();
        DatabaseService.deleteRecord(a);
        Test.stopTest();

        List<Account> acctsToCheck = new List<Account>([SELECT Id, Name FROM Account]);

        system.assertEquals(0, acctsToCheck.size(), 'Delete was not successful');

    }

}