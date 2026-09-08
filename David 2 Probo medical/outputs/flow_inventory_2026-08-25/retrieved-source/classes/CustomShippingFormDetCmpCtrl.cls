public with sharing class CustomShippingFormDetCmpCtrl {

    public String theOppID {get;set;}

    private List<ShippingFormDetailsRow> tableData = new List<ShippingFormDetailsRow>();

    public CustomShippingFormDetCmpCtrl() {
    }

    public List<ShippingFormDetailsRow> gettableData(){
        GH_Logger.debug('the Opp ID: ' + theOppID);

        Map<Id, List<OpportunityLineItem>> prodItemIDToOLIs = new Map<Id, List<OpportunityLineItem>>();

        for (OpportunityLineItem oli : [
                SELECT ProductItem__c, ProductItem__r.Name, ProductItem__r.Asset_Model_No__c,
                        Check_In_Type__c, Exchange__c, Product_Name__c, TotalPrice,
                        Serial_No__c, ProductItem__r.Model_Number__c
                FROM OpportunityLineItem
                WHERE OpportunityId = :theOppID
                AND ProductItem__c != NULL
        ]) {

            if (!prodItemIDToOLIs.containsKey(oli.ProductItem__c)) {
                prodItemIDToOLIs.put(oli.ProductItem__c, new List<OpportunityLineItem>());
            }
            prodItemIDToOLIs.get(oli.ProductItem__c).add(oli);
        }

        GH_Logger.debug('this many ProductItem from OLI to work with: ' + prodItemIDToOLIs.size());

        Map<Id, RMA__c> prodItemIDToRMA = new Map<Id, RMA__c>();

        for (RMA__c r : [
                SELECT ProductItem__c, Name, Return_To_Account__r.Name, Return_To_Address__c, Vendor_RMA__c
                FROM RMA__c
                WHERE Opportunity__c = :theOppID
                AND ProductItem__c IN :prodItemIDToOLIs.keySet()
        ]) {

            if (!prodItemIDToRMA.containsKey(r.ProductItem__c)) {
                prodItemIDToRMA.put(r.ProductItem__c, r);
            }
        }

        GH_Logger.debug('this many ProductItem from RMA to work with: ' + prodItemIDToRMA.size());

        // populate the output data for all the OLIs, adding in the RMAs as (or if) they are found
        for (Id pItemId : prodItemIDToOLIs.keySet()) {

            GH_Logger.debug('Working with OLIs for ProductItem__c: ' + pItemId);

            for (OpportunityLineItem oli : prodItemIDToOLIs.get(pItemId)) {
                GH_Logger.debug('Adding output row for OLI: ' + oli);

                ShippingFormDetailsRow d = new ShippingFormDetailsRow();
                d.assetNum = oli.ProductItem__r.Name;
                d.productName = oli.Product_Name__c;
                d.serialNum = oli.Serial_No__c;
                d.assetModelNum = oli.ProductItem__r.Asset_Model_No__c;
          //      d.assetPrice = '$' + String.valueOf(oli.ProductItem__r.Price__c);
                d.totalPrice = '$' + String.valueOf(oli.TotalPrice);
                d.modelNum = oli.ProductItem__r.Model_Number__c;
                d.exchange = String.valueOf(oli.Exchange__c);

                if (prodItemIDToRMA.containsKey(pItemId)) {
                    GH_Logger.debug('Found an RMA : ' + prodItemIDToRMA.get(pItemId).Name);
                    d.rmaNum = prodItemIDToRMA.get(pItemId).Name;
                    d.retToAcct = prodItemIDToRMA.get(pItemId).Return_To_Account__r.Name;
                    d.retToAddress = prodItemIDToRMA.get(pItemId).Return_To_Address__c;
                    d.vendorrmaNum = prodItemIDToRMA.get(pItemId).Vendor_RMA__c;
                }
                tableData.add(d);
            }
        }

        return tableData;
    }

    public class ShippingFormDetailsRow {

        public String assetNum {get;set;}
        public String productName {get;set;}
        public String serialNum {get;set;}
        public String assetModelNum {get;set;}
   //     public String assetPrice {get;set;}
        public String totalPrice {get;set;}
        public String modelNum {get;set;}
        public String exchange {get;set;}
        public String rmaNum {get;set;}
        public String vendorrmaNum {get;set;}
        public String retToAcct {get;set;}
        public String retToAddress {get;set;}
    }
}