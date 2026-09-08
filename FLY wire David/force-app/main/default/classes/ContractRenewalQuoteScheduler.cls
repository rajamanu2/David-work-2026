public class ContractRenewalQuoteScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        ContractRenewalQuoteBatch batch1 = new ContractRenewalQuoteBatch();
			Database.executeBatch(batch1,1);
 
    }
}