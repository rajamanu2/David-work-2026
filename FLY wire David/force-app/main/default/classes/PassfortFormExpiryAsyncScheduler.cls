public with sharing class PassfortFormExpiryAsyncScheduler implements Schedulable {
    
    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new PassfortFormExpiryAsyncProcessor(), 20);
    }
}