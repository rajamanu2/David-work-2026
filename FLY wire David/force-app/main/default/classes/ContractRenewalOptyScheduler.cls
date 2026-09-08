public class ContractRenewalOptyScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        ContractRenewalOppBatch batch = new ContractRenewalOppBatch();
        Database.executeBatch(batch, 1); 
    }
}