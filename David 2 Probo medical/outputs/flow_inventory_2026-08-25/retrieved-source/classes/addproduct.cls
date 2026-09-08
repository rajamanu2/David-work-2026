public class addproduct {

    public String searchString { get; set; }

    public list<wrapperProduct> wlist { get; set; }
    public list<ProductItem__c> pItem;
    public String Searchresult { get; set; }
    public Boolean renderd { get; set; }
    public static string opprecordType { get; set; }
    public Integer total_size;
    public Integer list_size = 1000;
    public string opptype { get; set; }
    public boolean InterCompany { get; set; }

    public Opportunity opp;

    public string querystring, oppname;
    public string newname { get; set; }

    public Boolean isSalesOpp { get; Set; }
    public Boolean isPurchaseOpp { get; set; }

    private RecordType oppRType;

    public addproduct(ApexPages.StandardController controller) {

        renderd = false;
        id oppid = ApexPages.currentPage().getParameters().get('id');
        id UserID = UserInfo.getUserId();

        system.debug('THIS IS THE OPP ID >>> ' + oppid);

        // TODO: Why is the page being loaded from anywhere EXCEPT an Opportunity?
        if (oppid == null) {
            Opportunity findopp = [select id, name, CreatedByID, LastModifiedDate from Opportunity where CreatedByID = :userid ORDER BY LastModifiedDate DESC limit 1];
            oppid = findopp.id;

        }

        opp = [Select id, StageName, RecordTypeId, Name, Account_Name__c from Opportunity where Id = :oppid];
        InterCompany = false;

        // TODO: What is this doing?
        if (opp.Name == 'TEST QUICK OPP') {
            oppname = 'TEST';
        }
        // Two different codes run based on if purchasing or sales - this first part of the code indicates which code to run
        if (opp.RecordTypeId != null) {
            oppRType = [select DeveloperName from RecordType where id = :opp.RecordTypeId];

            if (oppRType.DeveloperName == 'Purchasing_Opportunity') {
                OppType = 'Purchasing';
                renderd = true;
                isPurchaseOpp = true;
                isSalesOpp = false;
            } else {
                OppType = 'Sales';
                renderd = false;
                isSalesOpp = true;
                isPurchaseOpp = false;
                if (oppRType.DeveloperName == 'Inter_Company_Material_Transfer') {
                    InterCompany = true;
                }
            }
        }

        wlist = new list<wrapperProduct> ();


    }
    // Custom search options; exact name helps to limit search if many assets listed under similar names;
    // available probes are only probes in certain locations and review statuses;
    // asset number just looks at the asset number; all components brings in all parts too;
    // add to inter company opp allows a sold probe to be added to the opp, but only if on an inter-company opp
    // May need to get rid of option 3 - if no search option selected, looks for similar product name, serial number, asset number or part number
    public list<SelectOption> getSearch() {
        list<SelectOption> options = new list<SelectOption>();
        options.add(new SelectOption('1', 'Search By EXACT Name'));
        options.add(new SelectOption('2', 'Search For Available Probes'));
        options.add(new SelectOption('3', 'Search By Asset Number'));
        options.add(new SelectOption('4', 'Search All Components'));
        options.add(new SelectOption('5', 'Add to Inter-Company Opp'));
        return options;
    }

    public PageReference searchProdut() {
        // TODO: The product family code is old - may need to be updated
        //used to store  5 new prodcut families as requested by Zach
        Set<String> ProductFamily = new set<String>{
                'Ultrasound System', 'Ultrasound Probe', 'Ultrasound Part', 'Non Inventory Item', 'Other Medical Equipment',
                'Credit Card Fee','Equipment Rental Income','Exchange Fee Income','Loaner Damage Charges Income',
                'Referral Fee','Restocking Fee Charges','Sales Tax','Shipping and Delivery Income','Training Income',
                'Ultrasound Labor','Ultrasound Maintenance Plan','Ultrasound Preventative Maintenance','Ultrasound Probe Repair'
        };

        wlist.clear();
        if (searchString == '') {
            return null;
        }
        system.debug('#### addproduct.searchProdut() searchResult: ' + searchResult);
        // Pulling in all assets that meet search criteria for purchasing opps, then sales opps (inter company option only available on sales opp)
        if (opp.RecordTypeId != null && oppRType != null) {

            if (oppRType.DeveloperName == 'Purchasing_Opportunity') {

                if (Searchresult == '1') {
                    querystring = '%' + searchString + '%';
                    total_size = [
                            SELECT count()
                            FROM ProductItem__c
                            WHERE Product_Name__r.Name = :searchString and sold__c = false AND
                            Generic_Product__c = true AND Product_Name__r.Family in :ProductFamily
                    ];
                    System.debug('Total Size: ' + total_size);

                    pItem = [
                            Select ID,Name,Product_Name__r.name,Createddate,Model__c,Part_Number__c,Serial_No__c,Compatible_System__c,
                                    Functional_Rating__c,Functional_Notes__c,Price__c,Cosmetic_Rating__c,Cosmetic_Notes__c, Sug_Price_with_System__c,
                                    Location__c,
                                    Std_Cost_ex__c,Std_Cost_Out__c,Sug_Pr_Ex__c,Sug_Pr_Out__c,
                                    PO_Number__c,Other_Notes__c,
                                    Generic_Product__c,Image__c,Frequency_High__c,Frequency_Low__c,Date_of_Manufacture__c,Product_Description__c,
                                    System_Software__c,Receive_date__c,Check_In_Type__c,Purchasing_Approved__c,Repair_Activity__c, Domestic_Only__c,
                                    Repair_Priority_Rating__c,First_Call_Capability__c,System_Test_Bed__c, Repair_Summary__c,Review_Status__c,
                                    Review_Status_Notes__c,Special_Offer_Pricing__c,Product_Name__r.Total_no_of_Requests__c,Product_Name__r.Total_Qty_in_stock__c,
                                    Product_Name__r.Functionally_Good_Probes_Total__c, Product_Name__r.Total_Qty_of_New_Probes__c,
                                    Product_Name__r.Functionally_Good_Probes__c, Product_Name__r.Qty_Ready_to_Ship__c,Product_Name__r.Target_Quantity_in_Stock__c,
                                    Product_Name__r.Untested_Probes__c,Reserved__c,Repair_Notes_Summary__c, Avg_Sale_Price__c, Posted_on_Ebay__c,
                                    Product_Name__r.Probe_Type__c, D_System_Test__c, Product_Name__r.Total_Qty_on_Purchasing_Verbal__c, Vendor__c, Vendor_Name__c,
                                    Product_Name__r.New_Std_Cost_Out__c, Product_Name__r.New_Std_Cost_Ex__c, Product_Name__r.New_Sug_Pr_Out__c, Product_Name__r.New_Sug_Pr_Ex__c,
                                    Product_Name__r.Proposed_STD_Wholesale_Price__c, Product_Name__r.Proposed_STD_w_Refurb_30_day__c, Product_Name__r.Proposed_STD_Retail__c,

                            (select Probo_s_Offer__c,Supplier_s_Quote__c,Quantity from Opportunity_Product__r)
                            from ProductItem__c
                            where
                            Product_Name__r.Name = :searchstring and sold__c = false AND Generic_Product__c = true AND
                            Product_Name__r.Family in :ProductFamily
                            ORDER BY Name ASC
                            LIMIT :list_size/*or Serial_No__c like:querystring*/
                    ];
                } else if (Searchresult == '2') {
                    querystring = '%' + searchString + '%';
                    total_size = [
                            SELECT count()
                            FROM ProductItem__c
                            WHERE Product_Name__r.Name like:querystring AND Purchasing_Approved__c = true AND sold__c = false AND
                            (Location__c = 'Cage' OR Location__c = 'Generic' OR Location__c = 'QA-Testing' OR Location__c = 'Repair Area - Cosmetic') AND
                            (Review_Status__c = 'Cosmetic Repair Queue' OR Review_Status__c = 'Finished Goods' OR Review_Status__c = 'Special Offer') AND
                            Check_In_Type__c != 'Customer Repair' AND Check_In_Type__c != 'Harvested' AND Product_Name__r.Family in :ProductFamily
                    ];

                    pItem = [
                            Select ID,Name,Product_Name__r.name,Createddate,Model__c,Part_Number__c,Serial_No__c,Compatible_System__c,
                                    Functional_Rating__c,Functional_Notes__c,Price__c,Cosmetic_Rating__c,Cosmetic_Notes__c,Location__c, Sug_Price_with_System__c,
                                    Std_Cost_ex__c,Std_Cost_Out__c,Sug_Pr_Ex__c,Sug_Pr_Out__c,
                                    PO_Number__c,Other_Notes__c,Generic_Product__c,Image__c,
                                    Frequency_High__c,Frequency_Low__c,Date_of_Manufacture__c,Product_Description__c,System_Software__c,Receive_date__c,
                                    Check_In_Type__c,Purchasing_Approved__c,Repair_Activity__c,Repair_Priority_Rating__c,First_Call_Capability__c, Domestic_Only__c,
                                    System_Test_Bed__c,Repair_Summary__c,Review_Status__c,Review_Status_Notes__c,Special_Offer_Pricing__c,Product_Name__r.Total_no_of_Requests__c,
                                    Product_Name__r.Total_Qty_in_stock__c,Product_Name__r.Functionally_Good_Probes__c,Product_Name__r.Qty_Ready_to_Ship__c,
                                    Product_Name__r.Functionally_Good_Probes_Total__c, Product_Name__r.Total_Qty_of_New_Probes__c,
                                    Product_Name__r.Target_Quantity_in_Stock__c,Product_Name__r.Untested_Probes__c,Reserved__c,Vendor__c,Vendor_Name__c,
                                    Repair_Notes_Summary__c, Avg_Sale_Price__c, D_System_Test__c, Product_Name__r.Total_Qty_on_Purchasing_Verbal__c,
                                    Product_Name__r.New_Std_Cost_Out__c, Product_Name__r.New_Std_Cost_Ex__c, Product_Name__r.New_Sug_Pr_Out__c, Product_Name__r.New_Sug_Pr_Ex__c,
                                    Product_Name__r.Proposed_STD_Wholesale_Price__c, Product_Name__r.Proposed_STD_w_Refurb_30_day__c, Product_Name__r.Proposed_STD_Retail__c,
                                    Posted_on_Ebay__c, Product_Name__r.Probe_Type__c, (select Probo_s_Offer__c,Supplier_s_Quote__c,Quantity from Opportunity_Product__r)

                            from ProductItem__c
                            where Product_Name__r.Name like:querystring AND Purchasing_Approved__c = true AND sold__c = false AND
                            (Location__c = 'Cage' OR Location__c = 'Generic' OR Location__c = 'QA-Testing' OR Location__c = 'Repair Area - Cosmetic') AND
                            (Review_Status__c = 'Cosmetic Repair Queue' OR Review_Status__c = 'Finished Goods' OR Review_Status__c = 'Special Offer') AND
                            Check_In_Type__c != 'Customer Repair' AND Check_In_Type__c != 'Harvested' AND Product_Name__r.Family in :ProductFamily
                            ORDER BY Name ASC
                            LIMIT :list_size
                    ];
                } else if (Searchresult == '3') {
                    querystring = '%' + searchString + '%';
                    total_size = [
                            SELECT count()
                            FROM ProductItem__c
                            WHERE /*Product_Name__r.Name like:querystring or */Name like:querystring and
                            sold__c = false AND Generic_Product__c = true AND Product_Name__r.Family in :ProductFamily
                    ];

                    pItem = [
                            Select ID,Name,Product_Name__r.name,Createddate,Model__c,Part_Number__c,Serial_No__c,Compatible_System__c,
                                    Functional_Rating__c,Functional_Notes__c,Price__c,Cosmetic_Rating__c,Cosmetic_Notes__c,Location__c, Sug_Price_with_System__c,
                                    Std_Cost_ex__c,Std_Cost_Out__c,Sug_Pr_Ex__c,Sug_Pr_Out__c,
                                    PO_Number__c,Other_Notes__c,Generic_Product__c,Image__c,
                                    Frequency_High__c,Frequency_Low__c,Date_of_Manufacture__c,Product_Description__c,System_Software__c,Receive_date__c,
                                    Check_In_Type__c,Purchasing_Approved__c,Repair_Activity__c,Repair_Priority_Rating__c,First_Call_Capability__c, Domestic_Only__c,
                                    System_Test_Bed__c,Repair_Summary__c,Review_Status__c,Review_Status_Notes__c,Special_Offer_Pricing__c,
                                    Product_Name__r.Functionally_Good_Probes_Total__c, Product_Name__r.Total_Qty_of_New_Probes__c,
                                    Product_Name__r.Total_no_of_Requests__c,D_System_Test__c, Product_Name__r.Total_Qty_on_Purchasing_Verbal__c, Vendor__c,Vendor_Name__c,
                                    Product_Name__r.New_Std_Cost_Out__c, Product_Name__r.New_Std_Cost_Ex__c, Product_Name__r.New_Sug_Pr_Out__c, Product_Name__r.New_Sug_Pr_Ex__c,
                                    Product_Name__r.Proposed_STD_Wholesale_Price__c, Product_Name__r.Proposed_STD_w_Refurb_30_day__c, Product_Name__r.Proposed_STD_Retail__c,
                                    Product_Name__r.Total_Qty_in_stock__c,Product_Name__r.Functionally_Good_Probes__c,Product_Name__r.Qty_Ready_to_Ship__c,
                                    Product_Name__r.Target_Quantity_in_Stock__c,Product_Name__r.Untested_Probes__c,Reserved__c,Repair_Notes_Summary__c, Avg_Sale_Price__c,
                                    Posted_on_Ebay__c, Product_Name__r.Probe_Type__c, (select Probo_s_Offer__c,Supplier_s_Quote__c,Quantity from Opportunity_Product__r)
                            from ProductItem__c
                            where
                                    /*Product_Name__r.Name like:querystring or */Name like:querystring and sold__c = false AND Generic_Product__c = true AND
                            Product_Name__r.Family in :ProductFamily
                            ORDER BY Name ASC
                            LIMIT :list_size
                    ];

                } else if (Searchresult == '4') {
                    querystring = '%' + searchString + '%';
                    total_size = [
                            SELECT count()
                            FROM ProductItem__c
                            WHERE (Product_Name__r.Name like:querystring or Serial_No__c like:querystring OR Name like:querystring OR Part_Number__c like:querystring) and
                            sold__c = false AND Generic_Product__c = true
                    ];

                    pItem = [
                            Select ID,Name,Product_Name__r.name,Createddate,Model__c,Part_Number__c,Serial_No__c,Compatible_System__c,
                                    Functional_Rating__c,Functional_Notes__c,Price__c,Cosmetic_Rating__c,Cosmetic_Notes__c,Location__c, Sug_Price_with_System__c,
                                    Std_Cost_ex__c,Std_Cost_Out__c,Sug_Pr_Ex__c,Sug_Pr_Out__c,
                                    PO_Number__c,Other_Notes__c,Generic_Product__c,Image__c,
                                    Frequency_High__c,Frequency_Low__c,Date_of_Manufacture__c,Product_Description__c,System_Software__c,Receive_date__c,
                                    Check_In_Type__c,Purchasing_Approved__c,Repair_Activity__c,Repair_Priority_Rating__c,First_Call_Capability__c, Domestic_Only__c,
                                    System_Test_Bed__c,Repair_Summary__c,Review_Status__c,Review_Status_Notes__c,Special_Offer_Pricing__c,
                                    Product_Name__r.Functionally_Good_Probes_Total__c, Product_Name__r.Total_Qty_of_New_Probes__c,
                                    Product_Name__r.Total_no_of_Requests__c,D_System_Test__c, Product_Name__r.Total_Qty_on_Purchasing_Verbal__c, Vendor__c,Vendor_Name__c,
                                    Product_Name__r.New_Std_Cost_Out__c, Product_Name__r.New_Std_Cost_Ex__c, Product_Name__r.New_Sug_Pr_Out__c, Product_Name__r.New_Sug_Pr_Ex__c,
                                    Product_Name__r.Proposed_STD_Wholesale_Price__c, Product_Name__r.Proposed_STD_w_Refurb_30_day__c, Product_Name__r.Proposed_STD_Retail__c,
                                    Product_Name__r.Total_Qty_in_stock__c,Product_Name__r.Functionally_Good_Probes__c,Product_Name__r.Qty_Ready_to_Ship__c,
                                    Product_Name__r.Target_Quantity_in_Stock__c,Product_Name__r.Untested_Probes__c,Reserved__c,Repair_Notes_Summary__c, Avg_Sale_Price__c,
                                    Posted_on_Ebay__c, Product_Name__r.Probe_Type__c, (select Probo_s_Offer__c,Supplier_s_Quote__c,Quantity from Opportunity_Product__r)
                            from ProductItem__c
                            where
                            (Product_Name__r.Name like:querystring or Serial_No__c like:querystring OR Name like:querystring OR Part_Number__c like:querystring) and sold__c = false AND
                            Generic_Product__c = true
                            ORDER BY Name ASC
                            LIMIT :list_size
                    ];


                } else {
                    querystring = '%' + searchString + '%';
                    total_size = [
                            SELECT count()
                            FROM ProductItem__c
                            WHERE (Product_Name__r.Name like:querystring OR Serial_No__c like:querystring OR
                            Name like:querystring OR Part_Number__c like:querystring) AND sold__c = false AND
                            Generic_Product__c = true AND Product_Name__r.Family in :ProductFamily
                    ];

                    pItem = [
                            Select ID,Name,Product_Name__r.name,Createddate,Model__c,Part_Number__c,Serial_No__c,Compatible_System__c,
                                    Functional_Rating__c,Functional_Notes__c, Price__c,Cosmetic_Rating__c,Cosmetic_Notes__c,Location__c, Sug_Price_with_System__c,
                                    Std_Cost_ex__c,Std_Cost_Out__c,Sug_Pr_Ex__c,Sug_Pr_Out__c,
                                    PO_Number__c,Other_Notes__c,Generic_Product__c,Image__c,
                                    Frequency_High__c,Frequency_Low__c,Date_of_Manufacture__c,Product_Description__c,System_Software__c,Receive_date__c, Domestic_Only__c,
                                    Check_In_Type__c,Purchasing_Approved__c,Repair_Activity__c,Repair_Priority_Rating__c,First_Call_Capability__c,
                                    System_Test_Bed__c,Repair_Summary__c,Review_Status__c,Review_Status_Notes__c,Special_Offer_Pricing__c,Product_Name__r.Total_no_of_Requests__c,
                                    Product_Name__r.Functionally_Good_Probes_Total__c, Product_Name__r.Total_Qty_of_New_Probes__c,
                                    Product_Name__r.Total_Qty_in_stock__c,Product_Name__r.Functionally_Good_Probes__c,D_System_Test__c,
                                    Product_Name__r.Qty_Ready_to_Ship__c, Product_Name__r.Total_Qty_on_Purchasing_Verbal__c, Vendor__c,Vendor_Name__c,
                                    Product_Name__r.New_Std_Cost_Out__c, Product_Name__r.New_Std_Cost_Ex__c, Product_Name__r.New_Sug_Pr_Out__c, Product_Name__r.New_Sug_Pr_Ex__c,
                                    Product_Name__r.Proposed_STD_Wholesale_Price__c, Product_Name__r.Proposed_STD_w_Refurb_30_day__c, Product_Name__r.Proposed_STD_Retail__c,
                                    Product_Name__r.Target_Quantity_in_Stock__c,Product_Name__r.Untested_Probes__c,Reserved__c,Repair_Notes_Summary__c, Avg_Sale_Price__c,
                                    Posted_on_Ebay__c, Product_Name__r.Probe_Type__c, (select Probo_s_Offer__c,Supplier_s_Quote__c,Quantity from Opportunity_Product__r)
                            from ProductItem__c
                            where
                            (Product_Name__r.Name like:querystring or Serial_No__c like:querystring OR Name like:querystring OR Part_Number__c like:querystring) and
                            sold__c = false AND Generic_Product__c = true AND Product_Name__r.Family in :ProductFamily
                            ORDER BY Name ASC
                            LIMIT :list_size
                    ];
                }

            } else { // Record Type is NOT Purchasing Opportunity

                if (Searchresult == '1') {
                    querystring = '%' + searchString + '%';
                    total_size = [
                            SELECT count()
                            FROM ProductItem__c
                            WHERE Product_Name__r.Name = :searchString and sold__c = false AND
                            Product_Name__r.Family in :ProductFamily
                    ];

                    pItem = [
                            Select ID,Name,Product_Name__r.name,Createddate,Model__c,Part_Number__c,Serial_No__c,Compatible_System__c,
                                    Functional_Rating__c,Functional_Notes__c,Price__c,Cosmetic_Rating__c,Cosmetic_Notes__c,Location__c, Sug_Price_with_System__c,
                                    Std_Cost_ex__c,Std_Cost_Out__c,Sug_Pr_Ex__c,Sug_Pr_Out__c,
                                    PO_Number__c,Other_Notes__c,Generic_Product__c,Image__c,
                                    Frequency_High__c,Frequency_Low__c,Date_of_Manufacture__c,Product_Description__c,System_Software__c,Receive_date__c,
                                    Check_In_Type__c,Purchasing_Approved__c,Repair_Activity__c,Repair_Priority_Rating__c,First_Call_Capability__c,
                                    System_Test_Bed__c,Repair_Summary__c,Review_Status__c,Review_Status_Notes__c,Special_Offer_Pricing__c, Domestic_Only__c,
                                    D_System_Test__c, Product_Name__r.Total_no_of_Requests__c, Product_Name__r.Total_Qty_on_Purchasing_Verbal__c, Vendor__c,Vendor_Name__c,
                                    Product_Name__r.Functionally_Good_Probes_Total__c, Product_Name__r.Total_Qty_of_New_Probes__c,
                                    Product_Name__r.New_Std_Cost_Out__c, Product_Name__r.New_Std_Cost_Ex__c, Product_Name__r.New_Sug_Pr_Out__c, Product_Name__r.New_Sug_Pr_Ex__c,
                                    Product_Name__r.Proposed_STD_Wholesale_Price__c, Product_Name__r.Proposed_STD_w_Refurb_30_day__c, Product_Name__r.Proposed_STD_Retail__c,
                                    Product_Name__r.Total_Qty_in_stock__c,Product_Name__r.Functionally_Good_Probes__c,Product_Name__r.Qty_Ready_to_Ship__c,
                                    Product_Name__r.Target_Quantity_in_Stock__c,Product_Name__r.Untested_Probes__c,Reserved__c,Repair_Notes_Summary__c, Posted_on_Ebay__c,
                                    Product_Name__r.Probe_Type__c, Avg_Sale_Price__c, (select Probo_s_Offer__c,Supplier_s_Quote__c,Quantity from Opportunity_Product__r)
                            from ProductItem__c
                            where Product_Name__r.Name = :searchstring and sold__c = false AND Product_Name__r.Family in :ProductFamily
                            ORDER BY
                                    Name ASC
                            LIMIT :list_size/*or Serial_No__c like:querystring*/
                    ];
                } else if (Searchresult == '2') {
                    querystring = '%' + searchString + '%';
                    total_size = [
                            SELECT count()
                            FROM ProductItem__c
                            WHERE Product_Name__r.Name like:querystring AND Purchasing_Approved__c = true AND sold__c = false AND
                            (Location__c = 'Cage' OR Location__c = 'Generic' OR Location__c = 'QA-Testing' OR Location__c = 'Repair Area - Cosmetic') AND
                            (Review_Status__c = 'Cosmetic Repair Queue' OR Review_Status__c = 'Finished Goods' OR Review_Status__c = 'Special Offer') AND
                            Check_In_Type__c != 'Customer Repair' AND Check_In_Type__c != 'Harvested' AND Product_Name__r.Family in :ProductFamily
                    ];

                    pItem = [
                            Select ID,Name,Product_Name__r.name,Createddate,Model__c,Part_Number__c,Serial_No__c,Compatible_System__c,
                                    Functional_Rating__c,Functional_Notes__c,Price__c,Cosmetic_Rating__c,Cosmetic_Notes__c,Location__c, Sug_Price_with_System__c,
                                    Std_Cost_ex__c,Std_Cost_Out__c,Sug_Pr_Ex__c,Sug_Pr_Out__c,
                                    PO_Number__c,Other_Notes__c,Generic_Product__c,Image__c,
                                    Frequency_High__c,Frequency_Low__c,Date_of_Manufacture__c,Product_Description__c,System_Software__c,Receive_date__c,
                                    Check_In_Type__c,Purchasing_Approved__c,Repair_Activity__c,Repair_Priority_Rating__c,First_Call_Capability__c,
                                    System_Test_Bed__c,Repair_Summary__c,Review_Status__c,Review_Status_Notes__c,Special_Offer_Pricing__c, Domestic_Only__c,
                                    Product_Name__r.Functionally_Good_Probes_Total__c, Product_Name__r.Total_Qty_of_New_Probes__c,
                                    Product_Name__r.Total_no_of_Requests__c,D_System_Test__c, Product_Name__r.Total_Qty_on_Purchasing_Verbal__c, Vendor__c,Vendor_Name__c,
                                    Product_Name__r.New_Std_Cost_Out__c, Product_Name__r.New_Std_Cost_Ex__c, Product_Name__r.New_Sug_Pr_Out__c, Product_Name__r.New_Sug_Pr_Ex__c,
                                    Product_Name__r.Proposed_STD_Wholesale_Price__c, Product_Name__r.Proposed_STD_w_Refurb_30_day__c, Product_Name__r.Proposed_STD_Retail__c,
                                    Product_Name__r.Total_Qty_in_stock__c,Product_Name__r.Functionally_Good_Probes__c,Product_Name__r.Qty_Ready_to_Ship__c,
                                    Product_Name__r.Target_Quantity_in_Stock__c,Product_Name__r.Untested_Probes__c,Reserved__c,Repair_Notes_Summary__c, Posted_on_Ebay__c,
                                    Avg_Sale_Price__c, Product_Name__r.Probe_Type__c, (select Probo_s_Offer__c,Supplier_s_Quote__c,Quantity from Opportunity_Product__r)
                            from ProductItem__c
                            where Product_Name__r.Name like:querystring AND Purchasing_Approved__c = true AND sold__c = false AND
                            (Location__c = 'Cage' OR Location__c = 'Generic' OR Location__c = 'QA-Testing' OR Location__c = 'Repair Area - Cosmetic') AND
                            (Review_Status__c = 'Cosmetic Repair Queue' OR Review_Status__c = 'Finished Goods' OR Review_Status__c = 'Special Offer') AND
                            Check_In_Type__c != 'Customer Repair' AND Check_In_Type__c != 'Harvested' AND Product_Name__r.Family in :ProductFamily
                            ORDER BY Name ASC
                            LIMIT :list_size
                    ];
                } else if (Searchresult == '3') {
                    querystring = '%' + searchString + '%';
                    total_size = [
                            SELECT count()
                            FROM ProductItem__c
                            WHERE /*Product_Name__r.Name like:querystring or */
                            Name like:querystring and sold__c = false AND Product_Name__r.Family in :ProductFamily
                    ];

                    pItem = [
                            Select ID,Name,Product_Name__r.name,Createddate,Model__c,Part_Number__c,Serial_No__c,Compatible_System__c,
                                    Functional_Rating__c,Functional_Notes__c,Price__c,Cosmetic_Rating__c,Cosmetic_Notes__c,Location__c, Sug_Price_with_System__c,
                                    Std_Cost_ex__c,Std_Cost_Out__c,Sug_Pr_Ex__c,Sug_Pr_Out__c,
                                    PO_Number__c,Other_Notes__c,Generic_Product__c,Image__c,
                                    Frequency_High__c,Frequency_Low__c,Date_of_Manufacture__c,Product_Description__c,System_Software__c,Receive_date__c,
                                    Check_In_Type__c,Purchasing_Approved__c,Repair_Activity__c,Repair_Priority_Rating__c,First_Call_Capability__c,
                                    System_Test_Bed__c,Repair_Summary__c,Review_Status__c,Review_Status_Notes__c,Special_Offer_Pricing__c, Domestic_Only__c,
                                    Product_Name__r.Functionally_Good_Probes_Total__c, Product_Name__r.Total_Qty_of_New_Probes__c,
                                    Product_Name__r.Total_no_of_Requests__c,D_System_Test__c, Product_Name__r.Total_Qty_on_Purchasing_Verbal__c, Vendor__c,Vendor_Name__c,
                                    Product_Name__r.New_Std_Cost_Out__c, Product_Name__r.New_Std_Cost_Ex__c, Product_Name__r.New_Sug_Pr_Out__c, Product_Name__r.New_Sug_Pr_Ex__c,
                                    Product_Name__r.Proposed_STD_Wholesale_Price__c, Product_Name__r.Proposed_STD_w_Refurb_30_day__c, Product_Name__r.Proposed_STD_Retail__c,
                                    Product_Name__r.Total_Qty_in_stock__c,Product_Name__r.Functionally_Good_Probes__c,Product_Name__r.Qty_Ready_to_Ship__c,
                                    Product_Name__r.Target_Quantity_in_Stock__c,Product_Name__r.Untested_Probes__c,Reserved__c,Repair_Notes_Summary__c, Posted_on_Ebay__c,
                                    Avg_Sale_Price__c, Product_Name__r.Probe_Type__c, (select Probo_s_Offer__c,Supplier_s_Quote__c,Quantity from Opportunity_Product__r)
                            from ProductItem__c
                            where
                                    /*Product_Name__r.Name like:querystring or */Name like:querystring and sold__c = false AND
                            Product_Name__r.Family in :ProductFamily
                            ORDER BY Name ASC
                            LIMIT :list_size
                    ];


                } else if (Searchresult == '4') {
                    querystring = '%' + searchString + '%';
                    total_size = [
                            SELECT count()
                            FROM ProductItem__c
                            WHERE (Product_Name__r.Name like:querystring or Serial_No__c like:querystring or Name like:querystring OR Part_Number__c like:querystring) and
                            sold__c = false
                    ];

                    pItem = [
                            Select ID,Name,Product_Name__r.name,Createddate,Model__c,Part_Number__c,Serial_No__c,Compatible_System__c,
                                    Functional_Rating__c,Functional_Notes__c,Price__c,Cosmetic_Rating__c,Cosmetic_Notes__c,Location__c, Sug_Price_with_System__c,
                                    Std_Cost_ex__c,Std_Cost_Out__c,Sug_Pr_Ex__c,Sug_Pr_Out__c,
                                    PO_Number__c,Other_Notes__c,Generic_Product__c,Image__c,
                                    Frequency_High__c,Frequency_Low__c,Date_of_Manufacture__c,Product_Description__c,System_Software__c,Receive_date__c,
                                    Check_In_Type__c,Purchasing_Approved__c,Repair_Activity__c,Repair_Priority_Rating__c,First_Call_Capability__c,
                                    System_Test_Bed__c,Repair_Summary__c,Review_Status__c,Review_Status_Notes__c,Special_Offer_Pricing__c, Domestic_Only__c,
                                    Product_Name__r.Functionally_Good_Probes_Total__c, Product_Name__r.Total_Qty_of_New_Probes__c,
                                    Product_Name__r.Total_no_of_Requests__c,D_System_Test__c,Product_Name__r.Total_Qty_on_Purchasing_Verbal__c, Vendor__c,Vendor_Name__c,
                                    Product_Name__r.New_Std_Cost_Out__c, Product_Name__r.New_Std_Cost_Ex__c, Product_Name__r.New_Sug_Pr_Out__c, Product_Name__r.New_Sug_Pr_Ex__c,
                                    Product_Name__r.Proposed_STD_Wholesale_Price__c, Product_Name__r.Proposed_STD_w_Refurb_30_day__c, Product_Name__r.Proposed_STD_Retail__c,
                                    Product_Name__r.Total_Qty_in_stock__c,Product_Name__r.Functionally_Good_Probes__c,Product_Name__r.Qty_Ready_to_Ship__c,
                                    Product_Name__r.Target_Quantity_in_Stock__c,Product_Name__r.Untested_Probes__c,Reserved__c,Repair_Notes_Summary__c, Avg_Sale_Price__c,
                                    Posted_on_Ebay__c, Product_Name__r.Probe_Type__c, (select Probo_s_Offer__c,Supplier_s_Quote__c,Quantity from Opportunity_Product__r)
                            from ProductItem__c
                            where
                            (Product_Name__r.Name like:querystring or Serial_No__c like:querystring or Name like:querystring OR Part_Number__c like:querystring) and sold__c = false
                            ORDER BY Name ASC
                            LIMIT :list_size
                    ];


                } else if (Searchresult == '5' && InterCompany == true) {
                    querystring = '%' + searchString + '%';
                    total_size = [
                            SELECT count()
                            FROM ProductItem__c
                            WHERE (Product_Name__r.Name like:querystring or Serial_No__c like:querystring or
                            Name like:querystring OR Part_Number__c like:querystring) and sold__c = false AND
                            Product_Name__r.Family in :ProductFamily
                    ];

                    pItem = [
                            Select ID,Name,Product_Name__r.name,Createddate,Model__c,Part_Number__c,Serial_No__c,Compatible_System__c,Functional_Rating__c,
                                    Functional_Notes__c,Price__c,Cosmetic_Rating__c,Cosmetic_Notes__c,Location__c,
                                    Std_Cost_ex__c,Std_Cost_Out__c, Sug_Pr_Ex__c,Sug_Pr_Out__c,
                                    Sug_Price_with_System__c, PO_Number__c,Other_Notes__c,Generic_Product__c,Image__c,Frequency_High__c,Frequency_Low__c,
                                    Date_of_Manufacture__c,Product_Description__c,System_Software__c,Receive_date__c,Check_In_Type__c,Purchasing_Approved__c,
                                    Repair_Activity__c,Repair_Priority_Rating__c,First_Call_Capability__c,System_Test_Bed__c,Repair_Summary__c,Review_Status__c, Review_Status_Notes__c,
                                    Special_Offer_Pricing__c,Product_Name__r.Total_no_of_Requests__c,Product_Name__r.Total_Qty_in_stock__c, Domestic_Only__c,
                                    Product_Name__r.Functionally_Good_Probes_Total__c, Product_Name__r.Total_Qty_of_New_Probes__c,
                                    Product_Name__r.Functionally_Good_Probes__c,D_System_Test__c, Product_Name__r.Total_Qty_on_Purchasing_Verbal__c, Vendor__c,Vendor_Name__c,
                                    Product_Name__r.New_Std_Cost_Out__c, Product_Name__r.New_Std_Cost_Ex__c, Product_Name__r.New_Sug_Pr_Out__c, Product_Name__r.New_Sug_Pr_Ex__c,
                                    Product_Name__r.Proposed_STD_Wholesale_Price__c, Product_Name__r.Proposed_STD_w_Refurb_30_day__c, Product_Name__r.Proposed_STD_Retail__c,
                                    Product_Name__r.Qty_Ready_to_Ship__c,Product_Name__r.Target_Quantity_in_Stock__c,Product_Name__r.Untested_Probes__c,Reserved__c, Posted_on_Ebay__c,
                                    Avg_Sale_Price__c, Repair_Notes_Summary__c, Product_Name__r.Probe_Type__c, (select Probo_s_Offer__c,Supplier_s_Quote__c,Quantity from Opportunity_Product__r)
                            from ProductItem__c
                            where
                            (Product_Name__r.Name like:querystring or Serial_No__c like:querystring or Name like:querystring OR Part_Number__c like:querystring) and
                            Product_Name__r.Family in :ProductFamily
                            ORDER BY Name ASC
                            LIMIT :list_size
                    ];

                } else {
                    querystring = '%' + searchString + '%';
                    total_size = [
                            SELECT count()
                            FROM ProductItem__c
                            WHERE (Product_Name__r.Name like:querystring or Serial_No__c like:querystring or
                            Name like:querystring OR Part_Number__c like:querystring) and sold__c = false AND
                            Product_Name__r.Family in :ProductFamily
                    ];

                    pItem = [
                            Select ID,Name,Product_Name__r.name,Createddate,Model__c,Part_Number__c,Serial_No__c,Compatible_System__c,Functional_Rating__c,
                                    Functional_Notes__c,Price__c,Cosmetic_Rating__c,Cosmetic_Notes__c,Location__c,
                                    Std_Cost_ex__c,Std_Cost_Out__c, Sug_Pr_Ex__c,Sug_Pr_Out__c,
                                    Sug_Price_with_System__c, PO_Number__c,Other_Notes__c,Generic_Product__c,Image__c,Frequency_High__c,Frequency_Low__c,
                                    Date_of_Manufacture__c,Product_Description__c,System_Software__c,Receive_date__c,Check_In_Type__c,Purchasing_Approved__c,
                                    Repair_Activity__c,Repair_Priority_Rating__c,First_Call_Capability__c,System_Test_Bed__c,Repair_Summary__c,Review_Status__c, Review_Status_Notes__c,
                                    Special_Offer_Pricing__c,Product_Name__r.Total_no_of_Requests__c,Product_Name__r.Total_Qty_in_stock__c, Domestic_Only__c,
                                    Product_Name__r.Functionally_Good_Probes_Total__c, Product_Name__r.Total_Qty_of_New_Probes__c,
                                    Product_Name__r.Functionally_Good_Probes__c,D_System_Test__c, Product_Name__r.Total_Qty_on_Purchasing_Verbal__c, Vendor__c,Vendor_Name__c,
                                    Product_Name__r.New_Std_Cost_Out__c, Product_Name__r.New_Std_Cost_Ex__c, Product_Name__r.New_Sug_Pr_Out__c, Product_Name__r.New_Sug_Pr_Ex__c,
                                    Product_Name__r.Proposed_STD_Wholesale_Price__c, Product_Name__r.Proposed_STD_w_Refurb_30_day__c, Product_Name__r.Proposed_STD_Retail__c,
                                    Product_Name__r.Qty_Ready_to_Ship__c,Product_Name__r.Target_Quantity_in_Stock__c,Product_Name__r.Untested_Probes__c,Reserved__c, Posted_on_Ebay__c,
                                    Avg_Sale_Price__c, Repair_Notes_Summary__c, Product_Name__r.Probe_Type__c, (select Probo_s_Offer__c,Supplier_s_Quote__c,Quantity from Opportunity_Product__r)
                            from ProductItem__c
                            where
                            (Product_Name__r.Name like:querystring or Serial_No__c like:querystring or Name like:querystring OR Part_Number__c like:querystring) and
                            sold__c = false AND Product_Name__r.Family in :ProductFamily
                            ORDER BY Name ASC
                            LIMIT :list_size
                    ];
                }
            }

            system.debug('SIZE ' + pItem.size() + querystring);
            Set<Id>pItemID = new Set<Id>();
            for (ProductItem__c pItem1 : pItem) {
                pItemID.add(pItem1.ID);
            }
            List<OpportunityLineItem> opplineItem = [select ProductItem__c,Probo_s_Offer__c,Supplier_s_Quote__c,Quantity from OpportunityLineItem where ProductItem__c in:pItemID];

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
            // Wrapper pulls in information for product selected
            for (ProductItem__c pItem1 : pItem) {
                wrapperProduct wp = new wrapperProduct(pItem1, oppLineItemMap);
                wlist.add(wp);
            }

            system.debug('product ' + pItem);

            system.debug('SIZE ' + wlist.size() + querystring);
        }

        return null;
    }

    public PageReference addProdut() {

        Pricebook2 pb;
        try {
            pb = [select Id from PriceBook2 where isStandard = true and isActive = true limit 1];
        } catch (Exception e) {
            system.debug('Unable to find standard priceBook. Cannot continue.');
            // Redirects to opp page after products are added
            PageReference pr = new PageReference('/' + opp.id);

            pr.setRedirect(true);
            return pr;
        }

        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        list<ProductItem__c> pItemUpdateList = new list<ProductItem__c>();

        for (Integer i = 0; i < wlist.size(); i++) {
            WrapperProduct wp = wlist[i];

            // update asset for sold/reserved boxes
            system.debug('into wrapperlist for');
            if (wp.check == true) {
                newname = wp.prItem.Product_Name__r.name;

                system.debug('THIS IS THE NEW NAME >>> ' + newname);
                if (wp.prItem.Generic_Product__c == false) {

                    wp.prItem.Added_To_Opportunity__c = true;

                    if (opp.StageName == 'Closed Won') {
                        wp.prItem.Sold__c = true;
                    }
                    if (opp.StageName == 'Verbal Acceptance') {
                        wp.prItem.Reserved__c = true;
                    }

                    pItemUpdateList.add(wp.prItem);
                }

                // TODO: SOQL must move out of the for loop
                list<PricebookEntry> pbenamelist = [select id, Product2.Name from PricebookEntry where Product2.Name = :wp.name and Pricebook2Id = :pb.Id];
                system.debug('THIS IS THE PRICE BOOK ENTRY >>>> ' + pbenamelist);
                // Creates opportunity line item for all add products selected and inserts them
                if (pbenamelist.size() == 0) {

                    system.debug('into true insert condition');
                    PricebookEntry pbe = new PricebookEntry (Pricebook2Id = pb.id, Product2Id = wp.prItem.Product_Name__c, IsActive = true, UnitPrice = Decimal.valueof(wp.price));

                    insert pbe;

                    OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbe.Id, Model__c = wp.Model, Part_Number__c = wp.PartNumber,
                            Serial_No__c = wp.SerialNo,/*Actual_Price__c=Decimal.valueof(wp.price),*//*Discount=Decimal.valueOf(wp.Discount),*/
                            TotalPrice = Decimal.valueof(wp.price), Compatible_System__c = wp.CompatibleSystem,
                            Functional_Rating__c = wp.FunctionalRating, Functional_Rating_Notes__c = wp.FunctionalRatingNotes, ProductItem__c = wp.prItem.Id,
                            Exchange__c = wp.Exchange, Asset_No__c = wp.Assetno, Purchasing_Approved__c = wp.PurchasingApproved_b,
                            Probo_s_Offer__c = Decimal.valueOf(wp.ProboOffer), Supplier_s_Quote__c = Decimal.valueOf(wp.SupplierQuote),
                            Quantity = wp.qty);
                    // The following two creates a list on the product page of all items on purchasing opps and all on sales opps by linking them

                    if (OppType == 'Purchasing') {
                        oli.Product__c = wp.pritem.Product_Name__c;
                    }
                    if (OppType == 'Sales' && wp.pritem.Check_In_Type__c != 'Customer Repair' && opp.StageName == 'Closed Won') {
                        oli.Sales_Product__c = wp.pritem.Product_Name__c;
                    }

                    oliList.add(oli);

                } else {

                    system.debug('into false insert condition');

                    OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbenamelist[0].Id, Model__c = wp.Model, Part_Number__c = wp.PartNumber,
                            Serial_No__c = wp.SerialNo, Quantity = wp.qty, Actual_Price__c = Decimal.valueof(wp.price),/*Discount=Decimal.valueOf(wp.Discount),*/
                            TotalPrice = Decimal.valueof(wp.price), Compatible_System__c = wp.CompatibleSystem,
                            Functional_Rating__c = wp.FunctionalRating, Functional_Rating_Notes__c = wp.FunctionalRatingNotes, ProductItem__c = wp.prItem.Id,
                            Exchange__c = wp.Exchange, Asset_No__c = wp.Assetno, Purchasing_Approved__c = wp.PurchasingApproved_b,
                            Probo_s_Offer__c = Decimal.valueOf(wp.ProboOffer), Supplier_s_Quote__c = Decimal.valueOf(wp.SupplierQuote));
                    // The following two creates a list on the product page of all items on purchasing opps and all on sales opps by linking them
                    if (OppType == 'Purchasing') {
                        oli.Product__c = wp.pritem.Product_Name__c;
                    }
                    if (OppType == 'Sales' && wp.pritem.Check_In_Type__c != 'Customer Repair' && opp.StageName == 'Closed Won') {
                        oli.Sales_Product__c = wp.pritem.Product_Name__c;
                    }

                    oliList.add(oli);

                }
            }
            system.debug('oilist size======================' + olilist.size());


        }

        insert olilist;

        // TODO: Remove this next block and fix the tests if the pItems need to be updated
        // This line has been in code forever - not sure if it actually serves a purpose
        if (!Test.isRunningTest()) {
            update pItemUpdateList;
        }

        if (oppname == 'TEST') {
            oppname = newname;
        }
        if (oppname == null) {
            oppname = '';
        }
        date newdate = date.today();
        // When quick opp is created, the name is automatically set to "TEST QUICK OPP" - this changes the name to the date plus the product name of one of the add products
        if (opp.Name == 'TEST QUICK OPP') {
            opp.Name = newdate.month() + '/' + newdate.day() + '/' + newdate.year() + ', ' + oppname;
            system.debug('THIS SHOULD BE THE OPP NAME >>> ' + date.today() + ' ' + oppname);
            update opp;
        }
        // Redirects to opp page after products are added
        PageReference pr = new PageReference('/' + opp.id);

        pr.setRedirect(true);
        return pr;
    }


    // ----------------------------------------------------------Modified by Koushik----------------------

    // Pulls in data from product item added and displays them on the add product page
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
        public Boolean Domestic { get; set; }


        Public String GenericProduct { get; set; }
        public String CosmeticRating { get; set; }
        public String CosmeticRatingNote { get; set; }
        public String Location { get; set; }
        public String StdCostex { get; set; }
        public String StdCostOut { get; set; }
        public String SugPrEx { get; set; }
        public String SugPrOut { get; set; }
        public String NewStdCostex { get; set; }
        public String NewStdCostOut { get; set; }
        public String NewSugPrEx { get; set; }
        public String NewSugPrOut { get; set; }
        public String PropSTDWholesale { get; set; }
        public String PropSTDRefurb30 { get; set; }
        public String PropSTDRetail { get; set; }

        public String SugPrSystem { get; set; }
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

        public Boolean PurchasingApproved_b { get; set; }
        public String FirstCallCapability { get; set; }
        public String SystemTestBed { get; set; }
        public Decimal SpecialOfferPricing { get; set; }
        public String ReviewStatus { get; set; }
        public String ReviewStatusNotes { get; set; }
        public Decimal qty { get; set; }
        public Decimal TotalNoOfRequests { get; set; }
        public Decimal TotalQtyInStock { get; set; }
        public Decimal FunctionallyGoodProbes { get; set; }
        public Decimal FunctionallyGoodProbesNew { get; set; }
        public Decimal FunctionallyGoodProbesTotal { get; set; }
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
        public Decimal Verbal { get; set; }
        public string Vendor { get; set; }
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

            SugPrSystem = String.valueOf(p.Sug_Price_with_System__c);

            NewStdCostex = String.valueOf(p.Product_Name__r.New_Std_Cost_ex__c);
            NewStdCostOut = String.valueOf(p.Product_Name__r.New_Std_Cost_Out__c);
            NewSugPrEx = String.valueOf(p.Product_Name__r.New_Sug_Pr_Ex__c);
            NewSugPrOut = String.valueOf(p.Product_Name__r.New_Sug_Pr_Out__c);

            PropSTDWholesale = String.valueOf(p.Product_Name__r.Proposed_STD_Wholesale_Price__c);
            PropSTDRefurb30 = String.valueOf(p.Product_Name__r.Proposed_STD_w_Refurb_30_day__c);
            PropSTDRetail = String.valueOf(p.Product_Name__r.Proposed_STD_Retail__c);

            check = false;
            Exchange = false;
            ReceivedDate = String.valueOf(p.Receive_date__c);
            PONumber = p.PO_Number__c;
            OtherNotes = p.Other_Notes__c;
            DSystem = p.D_System_Test__c;

            Image = p.Image__c;

            if (Image != null && !Image.startswith('https://')) {
                Image = 'http://' + Image;
            }

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
            System.debug('THIS IS THE PROBOFFVAL >>>> ' + proboffVal);
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
            SpecialOfferPricing = p.Special_Offer_Pricing__c;
            TotalNoOfRequests = p.Product_Name__r.Total_no_of_Requests__c;
            TotalQtyInStock = p.Product_Name__r.Total_Qty_in_stock__c;
            FunctionallyGoodProbes = p.Product_Name__r.Functionally_Good_Probes__c;
            FunctionallyGoodProbesNew = p.Product_Name__r.Total_Qty_of_New_Probes__c;
            FunctionallyGoodProbesTotal = p.Product_Name__r.Functionally_Good_Probes_Total__c;
            QtyReadyToShip = p.Product_Name__r.Qty_Ready_to_Ship__c;
            TargetQuantityInStock = p.Product_Name__r.Target_Quantity_in_Stock__c;
            UntestedProbes = p.Product_Name__r.Untested_Probes__c;
            Reserved = p.Reserved__c;
            RepairNotesSummary = p.Repair_Notes_Summary__c;
            AvgSalesPrice = String.valueof(p.Avg_Sale_Price__c);
            PostedonEbay = p.Posted_on_Ebay__c;
            Verbal = p.Product_Name__r.Total_Qty_on_Purchasing_Verbal__c;
            Vendor = p.Vendor_Name__c;
            Domestic = p.Domestic_Only__c;

        }
    }

}