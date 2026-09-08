@istest
class SchedulableEmailSendOnTaskDueDateTest{
    static testmethod void mytest1() {
        Task t = new Task();
        t.ActivityDate = System.today();
        t.Subject='Call customer';
        insert t;
        
        SchedulableEmailSendOnTaskDueDate m = new SchedulableEmailSendOnTaskDueDate();
        String sch = '0 0 * * * ?';
        String jobID = system.schedule('EmailSendJob', sch, m);
    }
}