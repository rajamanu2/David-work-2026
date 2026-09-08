public class AccountParentCountBatch implements Database.Batchable<sobject>,Schedulable {
    public set<Id> accountIds;
    
    public AccountParentCountBatch(set<Id> accIds){
        accountIds = accIds;
    }
    public Database.QueryLocator start(Database.BatchableContext info) { 
        if(!accountIds.isEmpty()){
            return Database.getQueryLocator('SELECT Id,parent.Parent_Accounts__c,Parent_Accounts__c,Signed_Parent_Accounts__c,Parent.Signed_Parent_Accounts__c,Active_Parent_Accounts__c,Parent.Active_Parent_Accounts__c,Parent.Account_Status__c,ParentId from Account WHERE Id in:accountIds');
        }
        return Database.getQueryLocator('SELECT Id,parent.Parent_Accounts__c,Parent_Accounts__c,Signed_Parent_Accounts__c,Parent.Signed_Parent_Accounts__c,Active_Parent_Accounts__c,Parent.Active_Parent_Accounts__c,Parent.Account_Status__c,ParentId from Account WHERE Parent_Counted__c = FALSE');
    }
    
    public void execute(Database.BatchableContext info, List<Account> accounts) { 
        
        for(Account acc : accounts){
            acc.Signed_Parent_Accounts__c = 0;
            acc.Active_Parent_Accounts__c = 0;
            acc.Parent_Accounts__c = 0;
            acc.Parent_Counted__c = true;
            if(acc.ParentId!=NULL){
                acc.Parent_Accounts__c = 1;
                if(acc.parent.Parent_Accounts__c!=NULL){
                    acc.Parent_Accounts__c = acc.parent.Parent_Accounts__c+1;
                }
                
                if(acc.parent.Signed_Parent_Accounts__c!=NULL){
                    acc.Signed_Parent_Accounts__c = acc.parent.Signed_Parent_Accounts__c;
                }
                if(acc.parent.Account_Status__c == 'Client Signed'){
                    acc.Signed_Parent_Accounts__c++;
                }
                
                if(acc.parent.Active_Parent_Accounts__c!=NULL){
                    acc.Active_Parent_Accounts__c = acc.parent.Active_Parent_Accounts__c;
                }
                if(acc.parent.Account_Status__c == 'Active (Product Live)'){
                    acc.Active_Parent_Accounts__c++;
                }
            }            
        }
        update accounts;
    }
    
    public void finish(Database.BatchableContext info) {     
    } 
    
    public void execute(SchedulableContext sc){
        database.executeBatch(new AccountParentCountBatch(accountIds));
        System.abortJob(sc.getTriggerId());
    }
}