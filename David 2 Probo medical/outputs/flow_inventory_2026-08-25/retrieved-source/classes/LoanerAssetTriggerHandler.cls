public class LoanerAssetTriggerHandler extends GH_TriggerHandlerBase {
	
    protected override void beforeInsert() {
       setUniqueId(newList);
    }

    protected override void beforeUpdate(){
      setUniqueId(newList);
    }
    
    protected override void beforeDelete(){}
    protected override void afterInsert(){
        displayCount(newList);
    }
    protected override void afterUpdate(){
        displayCount(newList);
    }
    protected override void afterDelete(){}
    protected override void afterUndelete(){}
    
    private void setUniqueId(List<Loaner_Asset__c> lstTriggerNew) {
        
         for (Loaner_Asset__c la : lstTriggerNew) {
             if (la.Loaner__c != null && la.ProductItem__c != null) {
                 String uniqueId = String.valueOf(la.Loaner__c) + String.valueOf(la.ProductItem__c);
                 la.Unique_Id__c = uniqueId;
             }
        }    
             
    }   
    
    private void displayCount(List<Loaner_Asset__c> lstTriggerNew) {
         system.debug('record count:' + lstTriggerNew.size()); 
    }  
    
    
}