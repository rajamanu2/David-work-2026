public with sharing class MassBarcodeController {

    // This is a "wrapper" — a mini object that holds one Asset's
    
    public class AssetWrapper {
        public ProductItem__c asset { get; set; }
        public String imageUrl { get; set; }

        public AssetWrapper(ProductItem__c asset, String imageUrl) {
            this.asset = asset;
            this.imageUrl = imageUrl;
        }
    }

    // This is the list the Visualforce page will loop through
    public List<AssetWrapper> assetWrappers { get; set; }

    // Constructor — this runs when the page loads

    public MassBarcodeController() {

        assetWrappers = new List<AssetWrapper>();

        // The page will be called with a URL parameter called "ids"

        String idsParam = ApexPages.currentPage().getParameters().get('ids');

        if (idsParam == null || idsParam.trim() == '') {
            // Nothing passed in — nothing to show
            return;
        }


        List<String> idList = idsParam.split(',');


        List<ProductItem__c> assets = [
            SELECT Id, Name, Barcode_No__c, Serial_No__c,
                   Asset_Model_No__c, PO_Number__c, Label_Printed__c,
                   Product_Name__c, Product_Name__r.Name, Product2_Name__c
            FROM ProductItem__c
            WHERE Id IN :idList
        ];


        for (ProductItem__c asset : assets) {

            String imageUrl;

            // Same PI check as the original — narrower barcode for PI assets
            if (asset.Name != null && asset.Name.contains('PI')) {
                imageUrl = 'https://generator.barcodetools.com/barcode.png?gen=0&data='
                    + asset.Barcode_No__c
                    + '&bcolor=FFFFFF&fcolor=000000&tcolor=000000&fh=14&bred=0&w2n=2.5&xdim=1&w=&h=50&debug=1&btype=7&angle=0&quiet=0&balign=2&talign=2&guarg=1&text=0&tdown=1&stst=1&schk=0&cchk=1&ntxt=1&c128=0';
            } else {
                imageUrl = 'https://generator.barcodetools.com/barcode.png?gen=0&data='
                    + asset.Barcode_No__c
                    + '&bcolor=FFFFFF&fcolor=000000&tcolor=000000&fh=14&bred=0&w2n=2.5&xdim=2&w=&h=50&debug=1&btype=7&angle=0&quiet=0&balign=2&talign=2&guarg=1&text=0&tdown=1&stst=1&schk=0&cchk=1&ntxt=1&c128=0';
            }

            assetWrappers.add(new AssetWrapper(asset, imageUrl));
        }
    }
    
    public PageReference updatelabels() {
        List<ProductItem__c> toUpdate = new List<ProductItem__c>();
        for (AssetWrapper w : assetWrappers) {
        if (w.asset.Label_Printed__c != true) {
            w.asset.Label_Printed__c = true;
            toUpdate.add(w.asset);
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
        return null;
    }
    
}