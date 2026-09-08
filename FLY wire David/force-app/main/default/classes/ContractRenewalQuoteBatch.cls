public class ContractRenewalQuoteBatch implements Database.Batchable<SObject> {

    // Start method to collect contract records for processing
     public Database.QueryLocator start(Database.BatchableContext bc){
        Date contractEndDate60Days = Date.today().addDays(60); 
        Date contractEndDate1Day = Date.today().addDays(1); 

        // Query for Auto Renewal and Manual Renewal contracts for which Renewal Quote to be created
        String query = 'SELECT Id, Auto_Renewal__c, SBQQ__RenewalForecast__c, EndDate, Price_Book_Name__c, AccountId ' +
                       'FROM Contract ' +
                       'WHERE SBQQ__RenewalForecast__c = true AND Account.RecordType.DeveloperName != \'Strategic_Partner\'' + 
                       'AND Price_Book_Name__c = \'CPQ\' ' +
            		   'AND SBQQ__RenewalQuoted__c = false ' +
                       'AND ((Auto_Renewal__c = \'No\' AND EndDate <= :contractEndDate60Days) ' +  
                       'OR (Auto_Renewal__c = \'Yes\' AND EndDate <= :contractEndDate1Day))';  
        // Execute query
        //List<Contract> contractsToProcess = Database.query(query);
        //return contractsToProcess;
        return Database.getQueryLocator(query);
    }

    // Execute method to process each batch of contracts
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Contract> contractsToUpdate = new List<Contract>();

        // Loop through the batch of contracts and update Renewal_Quoted__c to true
        for (SObject sObj : scope) {
            Contract c = (Contract) sObj;
                c.SBQQ__RenewalQuoted__c = true;
                contractsToUpdate.add(c);
            }

        // Perform DML operation to update contracts in the database
        if (!contractsToUpdate.isEmpty()) {
            try {
                update contractsToUpdate; // Update the contracts with the new Renewal Quoted value
            } catch (DmlException e) {
                System.debug('Error updating contracts: ' + e.getMessage());
            }
        }
    }

    // Finish method to perform any post-processing tasks
    public void finish(Database.BatchableContext bc) {
      
    }
}