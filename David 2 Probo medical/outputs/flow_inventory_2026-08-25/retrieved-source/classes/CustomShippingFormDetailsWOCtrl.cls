public with sharing class CustomShippingFormDetailsWOCtrl {

    public String theWOID {get;set;}

    private List<ShippingFormDetailsRow> tableData = new List<ShippingFormDetailsRow>();

    public CustomShippingFormDetailsWOCtrl() {
    }

    public List<ShippingFormDetailsRow> gettableData(){
        GH_Logger.debug('the WO ID: ' + theWOID);

        Map<Id, List<WorkOrderLineItem>> prodItemIDToWOLIs = new Map<Id, List<WorkOrderLineItem>>();

        for (WorkOrderLineItem woli : [
                SELECT Part_Used__r.Name, Part_Used__r.Product2_Name__c, Part_Used__r.Part_Number__c,
                        Part_Check_In_Type__c, TotalPrice,
                        Serial_No__c
                FROM WorkOrderLineItem
                WHERE WorkOrderId = :theWOID
                AND Part_Used__c != NULL
                AND (Part_Check_In_Type__c != 'Generic')
        ]) {

            if (!prodItemIDToWOLIs.containsKey(woli.Part_Used__c)) {
                prodItemIDToWOLIs.put(woli.Part_Used__c, new List<WorkOrderLineItem>());
            }
            prodItemIDToWOLIs.get(woli.Part_Used__c).add(woli);
        }

        GH_Logger.debug('this many ProductItem from WOLI to work with: ' + prodItemIDToWOLIs.size());

        Map<Id, RMA__c> prodItemIDToRMA = new Map<Id, RMA__c>();

        for (RMA__c r : [
                SELECT ProductItem__c, Name, Return_To_Account__r.Name, Return_To_Address__c, Vendor_RMA__c
                FROM RMA__c
                WHERE Work_Order__c = :theWOID
                AND ProductItem__c IN :prodItemIDToWOLIs.keySet()
        ]) {

            if (!prodItemIDToRMA.containsKey(r.ProductItem__c)) {
                prodItemIDToRMA.put(r.ProductItem__c, r);
            }
        }

        GH_Logger.debug('this many ProductItem from RMA to work with: ' + prodItemIDToRMA.size());

        // populate the output data for all the OLIs, adding in the RMAs as (or if) they are found
        for (Id pItemId : prodItemIDToWOLIs.keySet()) {

            GH_Logger.debug('Working with WOLIs for ProductItem__c: ' + pItemId);

            for (WorkOrderLineItem woli : prodItemIDToWOLIs.get(pItemId)) {
                GH_Logger.debug('Adding output row for WOLI: ' + woli);

                ShippingFormDetailsRow d = new ShippingFormDetailsRow();
                d.assetNum = woli.Part_Used__r.Name;
                d.productName = woli.Part_Used__r.Product2_Name__c;
                d.serialNum = woli.Serial_No__c;
                d.partNum = woli.Part_Used__r.Part_Number__c;
                d.totalPrice = '$' + String.valueOf(woli.TotalPrice);
               

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
        public String partNum {get;set;}
        public String totalPrice {get;set;}
       
        public String rmaNum {get;set;}
        public String vendorrmaNum {get;set;}
        public String retToAcct {get;set;}
        public String retToAddress {get;set;}
    }
}