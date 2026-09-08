public with sharing class GenarateBarcode {

    // DML, hardcoded OK, SOQL OK

     public String barcode{get;set;}
     private final ProductItem__c pro;

    public GenarateBarcode(ApexPages.StandardController controller) {
    
        //id urlid=apexpages.currentpage().getparameters().get('id');
        
        this.pro = (ProductItem__c)Controller.getRecord();
        String proId = pro.Id; 
        //system.debug('ID====================='+ proId );

        try{
            ProductItem__c proList = [select Barcode_No__c from ProductItem__c where Id=:proId limit 1];
            barcode = proList.Barcode_No__c;
        } catch(Exception e){
            system.debug('Unable to find a ProductItem__c for this ID: ' + proId);
        }
    }
    

}