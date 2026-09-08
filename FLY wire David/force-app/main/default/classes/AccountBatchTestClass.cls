@istest
public class AccountBatchTestClass {
    
    @istest 
    static void accountTest(){
        
        Test.startTest();
        Account a = new Account(Name='test1');
        insert a;
        Account b = new Account(Name='test1',ParentId=a.Id);
        insert b;
        Test.stopTest();
        
    }
}