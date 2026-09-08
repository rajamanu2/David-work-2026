public class RMAList {
    Public List<RMA__c> rmaList{get;set;}
    ID accountID;
    String accountName;
    Account acc;
    public RMAList(ApexPages.StandardController controller) {
        accountID=ApexPages.currentPage().getParameters().get('Id');
        System.debug('-------------------------'+accountID);
        
        
        acc=[Select Name,id From Account where id=:accountID];
        
        if(acc != Null){
            accountName=acc.Name;
        }
        if(accountName !=null){
        rmaList=[Select Name,RMA_Type__c,Location__c,Amount__c,Account_Name__c,ProductItem__c,Probe_Model__c,CreatedDate,Date_RMA_Item_Received__c from RMA__c where Account_Name__c=:accountName ORDER BY CreatedDate DESC];
        }
    }

}