public class AccountChildCountBatch implements Database.Batchable<sobject>,Schedulable {
    public set<Id> accountIds;
    
    public AccountChildCountBatch(set<Id> accIds){
        accountIds = accIds;
    }
    public Database.QueryLocator start(Database.BatchableContext info) { 
        if(!accountIds.isEmpty()){
            return Database.getQueryLocator('SELECT Id,Child_Counted__c,Child_Accounts__c,ParentId from Account WHERE Id in:accountIds');
        }
        
        return Database.getQueryLocator('SELECT Id,Child_Counted__c,Child_Accounts__c,ParentId from Account WHERE Child_Counted__c = FALSE');
        
    }
    
    public void execute(Database.BatchableContext info, List<Account> accounts) { 
        set<Id> tempAccountIds = new set<Id>();
        for(Account acc : accounts){
            tempAccountIds.add(acc.Id);      
        }
        List<Account> accChilds = new List<Account>([SELECT Id,ParentId,Child_Accounts__c,Active_Child_Accounts__c,Signed_Child_Accounts__c,Account_Status__c FROM Account WHERE ParentId IN: tempAccountIds]);
        for(Account ac: accounts){
            integer count =0;
            integer activeCount =0;
            integer signedCount =0;
            
            for(Account acChild: accChilds){
                if(acChild.ParentId == ac.Id){
                    
                    count = (acChild.Child_Accounts__c!=null?((Integer)acChild.Child_Accounts__c) : 0)+1 + count;
                    activeCount = (acChild.Active_Child_Accounts__c!=null?((Integer)acChild.Active_Child_Accounts__c) : 0)+ activeCount;
                    signedCount = (acChild.Signed_Child_Accounts__c!=null?((Integer)acChild.Signed_Child_Accounts__c) : 0)+ signedCount;
                    
                    if(acChild.Account_Status__c == 'Active (Product Live)'){
                        activeCount++;                       
                    }
                    
                    if(acChild.Account_Status__c == 'Client Signed'){
                        signedCount++;                       
                    }
                }             
            }
            ac.Child_Counted__c = true;
            ac.Child_Accounts__c = count;    
            ac.Active_Child_Accounts__c = activeCount;
            ac.Signed_Child_Accounts__c = signedCount;
        }
        update accounts;
    }
    
    public void finish(Database.BatchableContext info) {     
    } 
    
    public void execute(SchedulableContext sc){
        database.executeBatch(new AccountChildCountBatch(accountIds));
        System.abortJob(sc.getTriggerId());
        
    }
}