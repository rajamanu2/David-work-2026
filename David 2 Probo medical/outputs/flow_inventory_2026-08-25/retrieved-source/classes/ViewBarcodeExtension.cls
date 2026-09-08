public class ViewBarcodeExtension {
    public List<ProductItem__c> pItems;
    
    public ViewBarcodeExtension(ApexPages.StandardSetController controller) {
        List<ProductItem__c> itemsToGet = (List<ProductItem__c>)controller.getSelected();
        //system.debug('#### Product item list in set controller: ' +  itemsToGet);
        pItems = [SELECT Id, Harvest_Work_Order__c FROM ProductItem__c WHERE Id IN : itemsToGet];
        //system.debug('#### partItems: ' +  partItems);
         
    }
    
    public PageReference redir() {
        PageReference p;
        
        if (pItems != null && pItems.size() > 0) {
            ProductItem__c pItem = pItems[0];
            
            if (pItem.Harvest_Work_Order__c != null) {
                p = new PageReference('/apex/ViewBarcodeUK?id=' + pItem.Id + '&returnId=' + pItem.Harvest_Work_Order__c);
            } else {
        		p = new PageReference('/apex/ViewBarcodeUK?id=' + pItem.Id);
            }
            p.setRedirect(true);
        }    
        
        return p;
    }    

}