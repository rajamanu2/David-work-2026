public class BarcodeGeneratorExtension {
 	public String barcode {get;set;}
    public String returnId {get;set;}
 	public ProductItem__c pro {get;set;} 

    public BarcodeGeneratorExtension(ApexPages.StandardController controller) {
    
        returnId = apexpages.currentpage().getparameters().get('returnId');
        //system.debug('#### return Id: '+ returnId);
        ProductItem__c p = (ProductItem__c)Controller.getRecord();
        String proId = p.Id; 
        //system.debug('ID====================='+ proId );

        try{
            pro = [select Barcode_No__c, Part_Number__c, Product_Description__c, Product_Name__r.Name, Harvest_Work_Order__c, Label_Printed__c from ProductItem__c where Id=:proId limit 1];
            barcode = pro.Barcode_No__c;
        } catch(Exception e){
            system.debug('Unable to find a ProductItem__c for this ID: ' + proId);
        }
    }
    
    public PageReference close() {
        if (pro.Label_Printed__c == false) {
            pro.Label_Printed__c = true;
            update pro;
        }
        
        String url;
        
        if (returnId != null) {
            url = '/' + returnId;
        } else {
            url = '/' + pro.Id;
        }
        
        PageReference nextPage = new PageReference(url);
        nextPage.setRedirect(true);
        
        return nextPage;
    }    
}