public class AddProductPortal {

    public String searchString { get; set; }
    public list<wrapperProduct> wlist { get; set; }
    public list<ProductItem__c> pItemList;

    public Boolean renderd { get; set; }
    public static string opprecordType { get; set; }
    public Integer total_size;
    public Integer list_size = 1000;


    public Opportunity opp;
    public string querystring;
    public Boolean isSalesOpp { get; Set; }
    public AddProductPortal() {

        renderd = false;
        isSalesOpp = true;

        wlist = new list<wrapperProduct> ();


    }


    public PageReference searchProduct() {
        Set<String> ProductFamily = new set<String>{
                'Ultrasound System', 'Ultrasound Probe'
        };    //used to store  5 new prodcut families as requested by Zach

        wlist.clear();

        if (searchString == '') {
            return null;
        }

        querystring = '%' + searchString + '%';

        pItemList = new List<ProductItem__c>();

        pItemList = [
                SELECT ID,Name,Product_Name__r.name,Createddate,Model__c,Part_Number__c,Serial_No__c,
                        Compatible_System__c,Functional_Rating__c, Functional_Notes__c,Price__c,
                        Cosmetic_Rating__c,Cosmetic_Notes__c, Location__c,Std_Cost_ex__c,Std_Cost_Out__c,
                        Sug_Pr_Ex__c,Sug_Pr_Out__c,PO_Number__c,Other_Notes__c,Generic_Product__c,
                        Image__c,Frequency_High__c,Frequency_Low__c, Date_of_Manufacture__c,Product_Description__c,
                        System_Software__c,Receive_date__c, Check_In_Type__c,Purchasing_Approved__c,
                        Repair_Activity__c,Repair_Priority_Rating__c,First_Call_Capability__c,System_Test_Bed__c,
                        Repair_Summary__c,Review_Status__c, Review_Status_Notes__c, Special_Offer_Pricing__c,
                        Product_Name__r.Total_no_of_Requests__c, Product_Name__r.Total_Qty_in_stock__c,
                        Product_Name__r.Functionally_Good_Probes__c, D_System_Test__c,
                        Image_Link_for_Customer_Portal__c, Product_Name__r.Qty_Ready_to_Ship__c,
                        Product_Name__r.Target_Quantity_in_Stock__c,Product_Name__r.Untested_Probes__c,
                        Reserved__c, Posted_on_Ebay__c, Avg_Sale_Price__c, Repair_Notes_Summary__c,
                        Product_Name__r.Probe_Type__c, (SELECT Probo_s_Offer__c,Supplier_s_Quote__c,Quantity from Opportunity_Product__r)
                FROM ProductItem__c
                WHERE
                (Product_Name__r.Name LIKE :querystring OR Serial_No__c LIKE :querystring OR Name LIKE :querystring OR Part_Number__c LIKE :querystring
                )
                AND sold__c = false
                AND Product_Name__r.Family IN :ProductFamily
                AND Check_In_Type__c != 'Customer Repair'
                AND Check_In_Type__c != 'Harvested'
                AND Check_In_Type__c != 'Generic'
                AND Purchasing_Approved__c = true
                AND Generic_Product__c = false
                AND Location__c != 'Customer Loan / Demo'
                AND Location__c != 'MAS'
                AND Location__c != 'External Repair / Testing'
                AND Location__c != 'Scrap'
                AND Location__c != 'Out of Flow'
                AND Location__c != 'Generic'
                AND Location__c != 'Returned to Vendor/Cust'
                AND Review_Status__c != 'Liquidate'
                ORDER BY Name ASC
        ];


        system.debug('Matching Products for ' + querystring + ': ' + pItemList.size());

        List<OpportunityLineItem> opplineItem = [
                SELECT ProductItem__c,Probo_s_Offer__c,Supplier_s_Quote__c,Quantity
                FROM OpportunityLineItem
                WHERE ProductItem__c IN :pItemList
        ];

        Map<ID, List<OpportunityLineItem>> oppLineItemMap = new Map<ID, List<OpportunityLineItem>>();

        for (OpportunityLineItem opl : opplineItem) {

            List<OpportunityLineItem> oplList = oppLineItemMap.get(opl.ProductItem__c);
            if (oplList == null) {
                List<OpportunityLineItem> tempList = new List<OpportunityLineItem>();
                tempList.add(opl);
                oppLineItemMap.put(opl.ProductItem__c, tempList);
            } else {
                oplList.add(opl);
                oppLineItemMap.put(opl.ProductItem__c, oplList);

            }
        }

        for (ProductItem__c pItem1 : pItemList) {
            wrapperProduct wp = new wrapperProduct(pItem1, oppLineItemMap);
            wlist.add(wp);
        }

        system.debug('product list: ' + pItemList);

        system.debug('SIZE=====================' + wlist.size() + querystring);

        return null;
    }


    public class WrapperProduct {

        public String Assetno { get; set; }
        public String Name { get; set; }
        public String Model { get; set; }
        public String PartNumber { get; set; }
        public String SerialNo { get; set; }
        public String CompatibleSystem { get; set; }
        public String FunctionalRating { get; set; }
        public String FunctionalRatingNotes { get; set; }
        public String Price { get; set; }
        public String Discount { get; set; }
        public Boolean check { get; set; }
        public Boolean Exchange { get; set; }


        Public String GenericProduct { get; set; }
        public String CosmeticRating { get; set; }
        public String CosmeticRatingNote { get; set; }
        public String Location { get; set; }
        public String StdCostex { get; set; }
        public String StdCostOut { get; set; }
        public String SugPrEx { get; set; }
        public String SugPrOut { get; set; }
        public String PONumber { get; set; }
        public String OtherNotes { get; set; }
        public String ReceivedDate { get; set; }
        public String Image { get; set; }
        public String FrequencyHigh { get; set; }
        public String FrequencyLow { get; set; }
        public String DateofManufacture { get; set; }
        public String ProductDescription { get; set; }
        public String SystemSoftware { get; set; }
        public String ProboOffer { get; set; }
        public Decimal RepairPriorityRating { get; set; }
        public String SupplierQuote { get; set; }
        public String RepairSummary { get; set; }
        public String RepairNotesSummary { get; set; }
        public String PurchasingApproved { get; set; }
        public String RepairActivity { get; set; }
        public String CheckInType { get; set; }
        //public String GenericProduct{get;set;}
        public Boolean PurchasingApproved_b { get; set; }
        public String FirstCallCapability { get; set; }
        public String SystemTestBed { get; set; }
        public String SpecialOfferPricing { get; set; }
        public String ReviewStatus { get; set; }
        public String ReviewStatusNotes { get; set; }
        public Decimal qty { get; set; }
        public Decimal TotalNoOfRequests { get; set; }
        public Decimal TotalQtyInStock { get; set; }
        public Decimal FunctionallyGoodProbes { get; set; }
        public Decimal QtyReadyToShip { get; set; }
        public Decimal TargetQuantityInStock { get; set; }
        public Decimal UntestedProbes { get; set; }
        public Boolean Reserved { get; set; }
        public String avgProboffOffer { get; set; }
        public String avgSuplyQuote { get; set; }
        public String avgSalesPrice { get; set; }
        public Boolean PostedonEbay { get; set; }
        public String ProbeType { get; set; }
        public String DSystem { get; set; }
        public ProductItem__c prItem;
        public List<OpportunityLineItem> oppGetFrMap = new List<OpportunityLineItem>();
        public WrapperProduct(ProductItem__c p, Map<ID, List<OpportunityLineItem>> oppLineItemMap) {

            Discount = '0.0';
            prItem = p;
            Assetno = p.Name;
            Name = p.Product_Name__r.name;
            Model = p.Model__c;
            PartNumber = p.Part_Number__c;
            SerialNo = p.Serial_No__c;
            ProbeType = p.Product_Name__r.Probe_Type__c;
            //ProboOffer=p.Probo_s_Offer__c;

            //------------------------------------------------Repair summary----------------------
            RepairSummary = p.Repair_Summary__c;
            CompatibleSystem = p.Compatible_System__c;
            FunctionalRating = p.Functional_Rating__c;
            FunctionalRatingNotes = p.Functional_Notes__c;
            if (p.Price__c != null)
                Price = String.valueOf(p.Price__c); else
                    Price = '00.00';
            CosmeticRating = p.Cosmetic_Rating__c;
            CosmeticRatingNote = p.Cosmetic_Notes__c;
            Location = p.Location__c;
            StdCostex = String.valueOf(p.Std_Cost_ex__c);
            StdCostOut = String.valueOf(p.Std_Cost_Out__c);
            SugPrEx = String.valueOf(p.Sug_Pr_Ex__c);
            SugPrOut = String.valueOf(p.Sug_Pr_Out__c);
            check = false;
            Exchange = false;
            ReceivedDate = String.valueOf(p.Receive_date__c);
            PONumber = p.PO_Number__c;
            OtherNotes = p.Other_Notes__c;
            DSystem = p.D_System_Test__c;
            // GenericProduct = p.Generic_Product__c;
            Image = p.Image_Link_for_Customer_Portal__c;

            //amit
            if (Image != null && !Image.startswith('https://')) {
                Image = 'http://' + Image;
            }

            //end

            /* opportunity product*/

            Double proboffVal = 0, suplyQuot = 0;
            Decimal avgProboffVal = 0, avgSuplyQuot = 0;
            Integer numberOfNotNullProbooffVal = 0, numberOffNotNullSuplyQuot = 0;
            oppGetFrMap = oppLineItemMap.get(p.ID);
            if (oppGetFrMap != Null) {
                for (OpportunityLineItem op : oppGetFrMap) {
                    if (op.Probo_s_Offer__c != null && op.Probo_s_Offer__c > 0) {
                        proboffVal += op.Probo_s_Offer__c;
                        numberOfNotNullProbooffVal = numberOfNotNullProbooffVal + 1;

                    }
                    if (op.Supplier_s_Quote__c != null && op.Supplier_s_Quote__c > 0) {
                        suplyQuot += op.Supplier_s_Quote__c;
                        numberOffNotNullSuplyQuot = numberOffNotNullSuplyQuot + 1;

                    }
                }
            }
            System.debug(proboffVal);
            System.debug(numberOfNotNullProbooffVal);
            if (proboffVal != 0) {
                avgProboffVal = (proboffVal / numberOfNotNullProbooffVal);
            }
            if (suplyQuot != 0) {
                avgSuplyQuot = (suplyQuot / numberOffNotNullSuplyQuot);
            }
            System.debug('Average of probo off' + avgProboffVal);
            System.debug('Average of suply Quote' + avgSuplyQuot);
            ProboOffer = String.valueOf(0.0);
            SupplierQuote = String.valueOf(0.0);
            avgProboffOffer = String.valueOf(avgProboffVal.SetScale(2));
            avgSuplyQuote = String.valueOf(avgSuplyQuot.SetScale(2));
            qty = 1;
            /*end  opportunity product**/

            FrequencyHigh = p.Frequency_High__c;
            FrequencyLow = p.Frequency_Low__c;
            DateofManufacture = p.Date_of_Manufacture__c;
            ProductDescription = p.Product_Description__c;
            SystemSoftware = p.System_Software__c;
            if (p.Generic_Product__c == true) {
                GenericProduct = 'Generic';
            } else {
                GenericProduct = 'Not Generic';
            }
            RepairPriorityRating = p.Repair_Priority_Rating__c;
            PurchasingApproved_b = p.Purchasing_Approved__c;
            if (p.Purchasing_Approved__c == true)
                PurchasingApproved = 'Yes'; else
                    PurchasingApproved = 'No';
            RepairActivity = p.Repair_Activity__c;
            CheckInType = p.Check_In_Type__c;
            if (p.First_Call_Capability__c == true)
                FirstCallCapability = 'Yes'; else
                    FirstCallCapability = 'No';

            SystemTestBed = p.System_Test_Bed__c;

            ReviewStatus = p.Review_Status__c;
            ReviewStatusNotes = p.Review_Status_Notes__c;
            //SpecialOfferPricing=p.Special_Offer_Pricing__c;
            TotalNoOfRequests = p.Product_Name__r.Total_no_of_Requests__c;
            TotalQtyInStock = p.Product_Name__r.Total_Qty_in_stock__c;
            FunctionallyGoodProbes = p.Product_Name__r.Functionally_Good_Probes__c;
            QtyReadyToShip = p.Product_Name__r.Qty_Ready_to_Ship__c;
            TargetQuantityInStock = p.Product_Name__r.Target_Quantity_in_Stock__c;
            UntestedProbes = p.Product_Name__r.Untested_Probes__c;
            Reserved = p.Reserved__c;
            RepairNotesSummary = p.Repair_Notes_Summary__c;
            AvgSalesPrice = String.valueof(p.Avg_Sale_Price__c);
            PostedonEbay = p.Posted_on_Ebay__c;

        }
    }

}