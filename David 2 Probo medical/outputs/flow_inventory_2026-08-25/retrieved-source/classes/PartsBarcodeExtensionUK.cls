public class PartsBarcodeExtensionUK {
    public List<ProductItem__c> partItems;
    
    public PartsBarcodeExtensionUK(ApexPages.StandardSetController controller) {
        List<ProductItem__c> itemsToGet = (List<ProductItem__c>)controller.getSelected();
        //system.debug('#### Product item list in set controller: ' +  itemsToGet);
        partItems = [SELECT Id, Harvest_Work_Order__c FROM ProductItem__c WHERE Id IN : itemsToGet];
        //system.debug('#### partItems: ' +  partItems);
         
    }
    
    public PageReference redir() {
        PageReference p;
        
        if (partItems != null && partItems.size() > 0) {
            ProductItem__c pItem = partItems[0];
            
            if (pItem.Harvest_Work_Order__c != null) {
                p = new PageReference('/apex/BarcodeGeneratorUK?id=' + pItem.Id + '&returnId=' + pItem.Harvest_Work_Order__c);
            } else {
        		p = new PageReference('/apex/BarcodeGeneratorUK?id=' + pItem.Id);
            }
            p.setRedirect(true);
        }    
        
        return p;
    }    

}