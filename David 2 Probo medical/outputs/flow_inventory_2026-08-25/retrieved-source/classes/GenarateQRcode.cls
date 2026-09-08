public with sharing class GenarateQRcode {

    // SOQL  DML and hardcoded OK

    private final ProductItem__c pro;
    public  ProductItem__c pro1{get;set;}

    public GenarateQRcode(ApexPages.StandardController controller) {
    
        this.pro = (ProductItem__c)Controller.getRecord();
        String proId = pro.Id; 

        try{
            pro1 = [select QR_Code__c from ProductItem__c where Id=:proId limit 1];
        } catch(Exception e){
            system.debug('Unable to find ProductItem__c for ID: ' + proId);
        }
    }
}