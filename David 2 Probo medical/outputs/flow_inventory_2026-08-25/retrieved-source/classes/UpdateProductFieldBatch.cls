global class UpdateProductFieldBatch implements Database.Batchable<SObject>, Schedulable, Database.AllowsCallouts, Database.Stateful {

    String Query;
    
    global Integer recordsProcessed = 0;
    
    
    global Database.QueryLocator start(Database.BatchableContext bc) {

        Query = 'Select Id,Avg_Lost_Quote_Price__c,Avg_Sale_Price__c,Compatible_System__c,Frequency_High__c,Frequency_Low__c,In_Stock_Rate__c,No_of_Requests_Not_in_Stock__c,Part_Number__c,Probe_Type__c,Qty_Cosmetically_Repairable__c,Qty_Functionally_Repairable__c,Qty_no_Repair_Eval__c,Qty_Ready_to_Ship__c,Quantity_Sold__c,Repair_Priority_Rating__c,Std_Cost_ex__c,Std_Cost_Out__c,Sug_Pr_Ex__c,Sug_Pr_Out__c,Total_no_of_Requests__c,Untested_Probes__c,Win_Rate__c,Total_no_of_purchasing_opps__c,Average_Probo_offer__c,Average_sourcing_quote__c,Average_supplier_s_quote__c, Calculated_Avg_Sensitivity__c, Calculated_Avg_Capacitance__c, Family, Compatible_Part_Numbers__c, Total_Qty_FG_With_Compatible_Parts__c, Total_Qty_Finished_Goods_Parts__c from Product2';
		return Database.getQueryLocator(Query);
    }

    global void execute(Database.BatchableContext bc, List<Product2> prodlist) {
		Set<Id> prodIDs = new Set<Id>(); 
    
        for (Product2 p : prodlist) {
            prodIDs.add(p.Id);
        }
		
        //Id oppSalesRecTypeId;
        list<id> SalesOppRecordList = new list<id>();
        list<id> partSalesOppRecordList = new list<id>();
        list<id> purchasingOppRecordList = new list<id>(); 
        
        for (RecordType r : ProboCommonUtils.getRecordTypes('Opportunity')) {
            switch on r.DeveloperName{
                when 'Sales_Opportunity' {
                    //oppSalesRecTypeId = r.Id;
                    SalesOppRecordList.add(r.Id);
                    partSalesOppRecordList.add(r.Id);
                }
                
                when 'Big_Iron_Sales_Opportunity'{
                    SalesOppRecordList.add(r.Id);
                    partSalesOppRecordList.add(r.Id);
                }
                
                when 'C_Arm_Sales_Opportunity'{
                    SalesOppRecordList.add(r.Id);
                    partSalesOppRecordList.add(r.Id);
                }
                
                when 'Parts_Sales_Opportunity' {
                    SalesOppRecordList.add(r.Id);
                    partSalesOppRecordList.add(r.Id);
                }
                
                when 'Probe_Sales_Opportunity'{
                    SalesOppRecordList.add(r.Id);
                    partSalesOppRecordList.add(r.Id);
                } 
                
                when 'Rental_Opportunity'{
                    SalesOppRecordList.add(r.Id);
                    partSalesOppRecordList.add(r.Id);
                }
                
               // service opps were excluded but we need this for part request numbers
                when 'Service_Sales_Opportunity'{
                    //SalesOppRecordList.add(r.Id);
                    partSalesOppRecordList.add(r.Id);
                } 
                
                when 'System_Sales_Opportunity'{
                    SalesOppRecordList.add(r.Id);
                    partSalesOppRecordList.add(r.Id);
                }

                when 'Purchasing_Opportunity' {
                    purchasingOppRecordList.add(r.Id);
                    
                }
                when 'Big_Iron_Purchasing_Opportunity' {
                    purchasingOppRecordList.add(r.Id);
                    
                }
            }
        }

        /*--------------------- No Of Request ---------------------*/
        List<AggregateResult> soqlRes = [SELECT COUNT(Id) TotalNo, Product2Id
                                    FROM OpportunityLineItem
                                    WHERE Product2Id IN :prodIDs
                                    //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                                    AND ((Product_Family__c != 'Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                                         (Product_Family__c = 'Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList))
                                    AND Opportunity.LeadSource != 'Ebay'
                                    AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                                    AND ProductItem__r.Check_In_Type__c != 'Warranty Repair'
                                    AND (ProductItem__r.sold__c = FALSE OR (ProductItem__r.sold__c = TRUE AND TotalPrice != 0))
                                    GROUP BY Product2Id
                            ];

        Map<String, Integer> prodCount = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
            prodCount.put((String) res.get('Product2Id'), (Integer) res.get('TotalNo'));
        }
        /*------------------------------------------------------------------------------------------------------*/

        /*--------------------- No Of Times Not In Stock ---------------------*/
        soqlRes = [SELECT COUNT(Id) NotInStock, Product2Id
                    FROM OpportunityLineItem
                    WHERE Product2Id IN :prodIDs
                    //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                    //AND Opportunity.RecordTypeID IN :SalesOppRecordList
                    AND ((Product_Family__c != 'Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                                         (Product_Family__c = 'Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList))
                    AND ProductItem__r.Generic_Product__c = TRUE
                    GROUP BY Product2Id
                ];

        Map<String, Integer> prodNotInStockCount = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
            prodNotInStockCount.put((String) res.get('Product2Id'), (Integer) res.get('NotInStock'));
        }
        /*-----------------------------------------------------------------------------------------------------------*/

        /*--------------------- Quantity Sold ---------------------*/
        soqlRes = [SELECT COUNT(Id) QuantitySold, Product2Id
                FROM OpportunityLineItem
                WHERE Product2Id IN :prodIDs
                //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                AND ((Product_Family__c != 'Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                                         (Product_Family__c = 'Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList))
                AND UnitPrice != 0
                AND TotalPrice != 0
                AND Opportunity.StageName = 'Closed Won'
                AND Opportunity.LeadSource != 'Ebay - Auction'
                AND Opportunity.LeadSource != 'Ebay - Fixed Price'
                AND Opportunity.LeadSource != 'Ettin Group Auction'
                AND Opportunity.LeadSource != 'Hilditch Auction'
                AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                AND ProductItem__r.Check_In_Type__c != 'Warranty Repair'
                AND ProductItem__r.sold__c = TRUE
                GROUP BY Product2Id
        ];

        Map<String, Integer> prodQtySold = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
            prodQtySold.put((String) res.get('Product2Id'), (Integer) res.get('QuantitySold'));
        }
        /*-------------------------------------------------------------------------------------------------------------*/

        /*------------------------------ Avg Sale Price ----------------------------------*/
        soqlRes = [SELECT AVG(TotalPrice) AvgSalePrice,Product2Id
                FROM OpportunityLineItem
                WHERE Product2Id IN :prodIDs
                //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                AND Opportunity.RecordTypeID IN :SalesOppRecordList                         
                AND UnitPrice != 0
                AND TotalPrice > 100
                AND Opportunity.StageName = 'Closed Won'
                AND Opportunity.LeadSource != 'Ebay - Auction'
                AND Opportunity.LeadSource != 'Ebay - Fixed Price'
                AND Opportunity.LeadSource != 'Ettin Group Auction'
                AND Opportunity.LeadSource != 'Hilditch Auction'
                AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                AND ProductItem__r.Check_In_Type__c != 'Warranty Repair'
                AND ProductItem__r.Generic_Product__c = FALSE
                AND ProductItem__r.sold__c = TRUE
                AND ProductItem__r.Original_Condition_New__c != TRUE
                GROUP BY Product2Id
        ];

        Map<String, Decimal> prodAvgSalesPrice = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {
            prodAvgSalesPrice.put((String) res.get('Product2Id'), (Decimal) res.get('AvgSalePrice'));
        }
        /*---------------------------------------------------------------------------------------------------------*/

        /*------------------------ Avg Lost Quote Price -------------------------*/
        soqlRes = [SELECT AVG(TotalPrice) AvgLostQuotePrice,Product2Id
                FROM OpportunityLineItem
                WHERE Product2Id IN:prodIDs
                //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                AND Opportunity.RecordTypeID IN :SalesOppRecordList
                AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                AND ProductItem__r.Check_In_Type__c != 'Warranty Repair'
                AND ProductItem__r.Generic_Product__c = FALSE
                AND Opportunity.StageName != 'Closed Won'
                GROUP BY Product2Id
        ];
        Map<String, Decimal> prodAvgLostQuotePrice = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {
            prodAvgLostQuotePrice.put((String) res.get('Product2Id'), (Decimal) res.get('AvgLostQuotePrice'));
        }
        /*---------------------------------------------------------------------------------------------------------*/

        /*-------------------------------------- Qty Ready to Ship -----------------------------------------------------*/
        soqlRes = [SELECT COUNT(Id) QtyReadytoShip,Product_Name__c productId
                FROM ProductItem__c
                WHERE Product_Name__c IN :prodIDs
                AND Location__c != 'External Repair / Testing'
                AND Location__c != 'Customer Loan / Demo'
                AND Location__c != 'Out of Flow'
                AND Location__c != 'On Rental'
                AND Check_In_Type__c != 'Generic'
                AND Check_In_Type__c != 'Customer Repair'
                AND Check_In_Type__c != 'Warranty Repair'
                AND sold__c != TRUE
                AND Generic_Product__c != TRUE
                AND Reserved__c != TRUE
                AND
                (
                        ((Functional_Rating__c = 'Good' OR Functional_Rating__c = 'Good - Leakage Test Not Available') AND Cosmetic_Rating__c = 'Good')
                        OR ((Functional_Rating__c = 'Good' OR Functional_Rating__c = 'Good - Leakage Test Not Available'
                        OR Functional_Rating__c = 'Fair' OR Functional_Rating__c = 'Fair - Leakage Test Not Available') AND Review_Status__c = 'Finished Goods')
                )
                GROUP BY Product_Name__c
        ];

        Map<String, Integer> prodQtyReadyToShip = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
            prodQtyReadyToShip.put((String) res.get('productId'), (Integer) res.get('QtyReadytoShip'));
        }
        /*--------------------------------------------------------------------------------------------------------------------*/

        /*--------------------- Qty Cosmetically Repairable ---------------------*/
        soqlRes = [
                SELECT COUNT(Id) QtyCosmeticallyRepairable,Product_Name__c productId
                FROM ProductItem__c
                WHERE
                Product_Name__c IN :prodIDs
                AND sold__c = FALSE
                AND Generic_Product__c = FALSE
                AND Functionally_Repairable__c != 'Yes'
                AND Cosmetically_Repairable__c = 'Yes'
                AND (Check_In_Type__c = 'Purchase' OR Check_In_Type__c = 'Core Exchange')
                GROUP BY Product_Name__c
        ];
        Map<String, Integer> prodQtyCosmeticallyRepairable = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
            prodQtyCosmeticallyRepairable.put((String) res.get('productId'), (Integer) res.get('QtyCosmeticallyRepairable'));
        }
        /*------------------------------------------------------------------------------------------------------*/

        /*--------------------- Qty Functionally Repairable ---------------------*/
        soqlRes = [SELECT COUNT(Id) QtyFunctionallyRepairable,Product_Name__c productId
                FROM ProductItem__c
                WHERE Product_Name__c IN :prodIDs
                AND sold__c = FALSE
                AND Generic_Product__c = FALSE
                AND Functionally_Repairable__c = 'Yes'
                AND Review_Status__c != 'Finished Goods'
                AND (Check_In_Type__c = 'Purchase' OR Check_In_Type__c = 'Core Exchange')
                GROUP BY Product_Name__c
        ];
        Map<String, Integer> prodQtyFunctionallyRepairable = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
            prodQtyFunctionallyRepairable.put((String) res.get('productId'), (Integer) res.get('QtyFunctionallyRepairable'));
        }
        /*------------------------------------------------------------------------------------------------------*/

        /*--------------------- Qty no Repair Eval ---------------------*/
        soqlRes = [
                SELECT COUNT(Id) QtynoRepairEval,Product_Name__c productId
                FROM ProductItem__c
                WHERE Product_Name__c IN :prodIDs
                AND Functionally_Repairable__c != 'Yes'
                AND Cosmetically_Repairable__c != 'Yes'
                AND Review_Status__c != 'Finished Goods'
                AND sold__c != TRUE
                AND Generic_Product__c != TRUE
                AND (Check_In_Type__c = 'Purchase' OR Check_In_Type__c = 'Core Exchange')
                GROUP BY Product_Name__c
        ];
        Map<String, Integer> prodQtyNoRepairEval = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
            prodQtyNoRepairEval.put((String) res.get('productId'), (Integer) res.get('QtynoRepairEval'));
        }
        /*------------------------------------------------------------------------------------------------------*/


        /*------------------------------------ Untested Probes ----------------------------------------------------*/
        soqlRes = [SELECT COUNT(Id) UntestedProbes,Product_Name__c productId
                FROM ProductItem__c
                WHERE Product_Name__c IN :prodIDs
                AND sold__c != TRUE
                AND Generic_Product__c != TRUE
                AND (Functional_Rating__c = 'N/A: No System & First Call'
                        OR Functional_Rating__c = 'N/A: No System & First Call - Leakage Test Not Available'
                        OR Functional_Rating__c = NULL)
                AND (Check_In_Type__c = 'Purchase' OR Check_In_Type__c = 'Core Exchange')
                GROUP BY Product_Name__c
        ];
        Map<String, Integer> prodQtyUntestedProbes = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
            prodQtyUntestedProbes.put((String) res.get('productId'), (Integer) res.get('UntestedProbes'));
        }
        /*---------------------------------------------------------------------------------------------------------*/


        /*--------------------- Total Qty in stock - Used  --------------*/

        soqlRes = [SELECT COUNT(Id) TotalQtyinstock,Product_Name__c productId
                FROM ProductItem__c
                WHERE Product_Name__c IN :prodIDs
                AND sold__c = FALSE
                AND Generic_Product__c = FALSE
                AND Location__c != 'External Repair / Testing'
                AND Location__c != 'Customer Loan / Demo'
                AND Location__c != 'Out of Flow'
                AND Functional_Rating__c != 'Good - New'
                AND (Check_In_Type__c = 'Purchase' OR Check_In_Type__c = 'Core Exchange' OR Check_In_Type__c = 'Harvested')
                GROUP BY Product_Name__c
        ];
        Map<String, Integer> prodQtyInStockUsed = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
            prodQtyInStockUsed.put((String) res.get('productId'), (Integer) res.get('TotalQtyinstock'));
        }
        /*------------------------------------------------------------------------------------------------------*/


        /*--------------------- Total Qty of Functionally Good Probes Used  --------------*/
        soqlRes = [SELECT COUNT(Id) TotalFunGoodPro,Product_Name__c productId
                FROM ProductItem__c
                WHERE Product_Name__c IN :prodIDs
                AND sold__c = FALSE
                AND Location__c != 'On Rental'
                AND Location__c != 'Customer Loan / Demo'
                AND (Functional_Rating__c = 'Good' OR Functional_Rating__c = 'Good - Leakage Test Not Available')
                AND (Check_In_Type__c = 'Purchase' OR Check_In_Type__c = 'Core Exchange' OR Check_In_Type__c = 'Harvested')
                GROUP BY Product_Name__c
        ];

        Map<String, Integer> prodQtyFuncGoodProbesUsed = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
            prodQtyFuncGoodProbesUsed.put((String) res.get('productId'), (Integer) res.get('TotalFunGoodPro'));
        }
        /*------------------------------------------------------------------------------------------------------*/

        /*--------------------- Total Qty of Functionally Good Loaners ----------------------*/
        soqlRes = [SELECT COUNT(Id) TotalFunGoodLoaners,Product_Name__c productId
                FROM ProductItem__c
                WHERE Product_Name__c IN :prodIDs
                AND sold__c = FALSE
                AND (Functional_Rating__c = 'Good' OR Functional_Rating__c = 'Good - Leakage Test Not Available' OR Functional_Rating__c = 'Good - New')
                AND (Check_In_Type__c = 'Purchase' OR Check_In_Type__c = 'Core Exchange')
                AND (Location__c = 'Customer Loan / Demo' OR Location__c = 'On Rental')
                GROUP BY Product_Name__c
        ];

        Map<String, Integer> prodQtyFuncGoodLoaners = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
            prodQtyFuncGoodLoaners.put((String) res.get('productId'), (Integer) res.get('TotalFunGoodLoaners'));
        }
        /*---------------------------------------------------------------------------------------------------------*/

        /*--------------------- Total Qty of Functionally Good Probes Purchasing Approved---------------------*/
        soqlRes = [SELECT COUNT(Id) TotalFunGoodProApproved,Product_Name__c productId
                FROM ProductItem__c
                WHERE Product_Name__c IN :prodIDs
                AND sold__c = FALSE
                AND Purchasing_Approved__c = TRUE
                AND (Functional_Rating__c = 'Good' OR Functional_Rating__c = 'Good - Leakage Test Not Available' OR Functional_Rating__c = 'Good - New')
                AND (Check_In_Type__c = 'Purchase' OR Check_In_Type__c = 'Core Exchange' OR Check_In_Type__c = 'Harvested')
                GROUP BY Product_Name__c
        ];
        Map<String, Integer> prodQtyFuncGoodProbesPurchApp = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
            prodQtyFuncGoodProbesPurchApp.put((String) res.get('productId'), (Integer) res.get('TotalFunGoodProApproved'));
        }
        /*------------------------------------------------------------------------------------------------------*/

        /*--------------------- Total Qty of Finished Good Parts---------------------*/
        soqlRes = [SELECT COUNT(Id) TotalFinishedGoodsParts,Product_Name__c productId
                FROM ProductItem__c
                WHERE Product_Name__c IN :prodIDs
                AND sold__c = FALSE
                AND Review_Status__c = 'Finished Goods' 
                AND Product_Family__c = 'Part'
                GROUP BY Product_Name__c
        ];
        Map<String, Integer> prodQtyFinishedGoodsParts = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
           
            prodQtyFinishedGoodsParts.put((String) res.get('productId'), (Integer) res.get('TotalFinishedGoodsParts'));
             
        }
        system.debug('THIS IS THE FINISHED GOODS PARTS >> ' + prodQtyFinishedGoodsParts);
        /*
        Map<String, Integer> prodQtyFinishedGoodsPartsWithCompatible = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
            Id newproductID = (String) res.get('productID');
            List<String> compatiblePartList = new List<String>();
            system.debug('THIS IS THE NEW PRODUCT ID >>> ' + newproductID);
            system.debug('THIS IS THE COMPATIBLE PART SEARCH >>> ' + compatiblePartsMap.get(newProductID));
            if(compatiblePartsMap.get(newProductID) != null){
                compatiblePartList = compatiblePartsMap.get(newproductID).split(';');
            }
            
            Integer compatibleAddition = 0;
            if(compatiblePartList.size() != 0){
                for(String compatible: compatiblePartList){
                	Id compatibleID = partNumberMap.get(compatible);
                    if(compatibleID != null && prodQtyFinishedGoodsParts.get(compatibleID) != null){
                        compatibleAddition += prodQtyFinishedGoodsParts.get(compatibleID);
                    }
            	}
            }
            if(prodQtyFinishedGoodsParts.get(newProductID) != null){
                compatibleAddition += prodQtyFinishedGoodsParts.get(newproductID);
            }
            
            prodQtyFinishedGoodsPartsWithCompatible.put((String) res.get('productId'), compatibleAddition);
        }*/
        
        /*------------------------------------------------------------------------------------------------------*/

        
        /*--------------------- Avg Sensitivity --------------ADD PRODIDS TO WHERE -------*/
        soqlRes = [SELECT AVG(Avg_sensitivity_latest_test__c) AvgSensitivity,
                AVG(Avg_capacitance_latest_test__c) AvgCapacitance, Product_Name__c productId
                FROM ProductItem__c
                WHERE Product_Name__c IN :prodIDs
                AND (Functional_Rating__c = 'Good' OR Functional_Rating__c = 'Good - Leakage Test Not Available' OR Functional_Rating__c = 'Good - New')
                GROUP BY Product_Name__c
        ];
        Map<String, Decimal> prodAvgSensitivity = new Map<String, Decimal>();
        Map<String, Decimal> prodAvgCapacitance = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {
            prodAvgSensitivity.put((String) res.get('productId'), (Decimal) res.get('AvgSensitivity'));
            prodAvgCapacitance.put((String) res.get('productId'), (Decimal) res.get('AvgCapacitance'));
        }
        /*------------------------------------------------------------------------------------------------------*/

        /*------------------------ Avg Cost - Functionally Good -------------------------*/
        soqlRes = [SELECT AVG(Cost__c) AvgCostFun,Product_Name__c productId
                FROM ProductItem__c
                WHERE Product_Name__c IN :prodIDs
                AND Check_In_Type__c != 'Generic'
                AND Check_In_Type__c != 'Customer Repair'
                AND Check_In_Type__c != 'Warranty Repair'
                AND Generic_Product__c = FALSE
                AND sold__c = FALSE
                AND Cost__c != NULL
                AND (Functional_Rating__c = 'Good' OR Functional_Rating__c = 'Good - Leakage Test Not Available')
                GROUP BY Product_Name__c
        ];
        Map<String, Decimal> prodAvgCostFuncGood = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {
            prodAvgCostFuncGood.put((String) res.get('productId'), (Decimal) res.get('AvgCostFun'));
        }
        /*---------------------------------------------------------------------------------------------------------*/

        /*------------------------ Avg Cost - Ready to Ship -------------------------*/
        soqlRes = [SELECT AVG(Cost__c) AvgCostShip,Product_Name__c productId
                FROM ProductItem__c
                WHERE Product_Name__c IN :prodIDs
                AND Location__c != 'External Repair / Testing'
                AND Location__c != 'Customer Loan / Demo'
                AND Location__c != 'Out of Flow'
                AND Location__c != 'On Rental'
                AND Check_In_Type__c != 'Generic'
                AND Check_In_Type__c != 'Customer Repair'
                AND Check_In_Type__c != 'Warranty Repair'
                AND sold__c = FALSE
                AND Generic_Product__c != TRUE
                AND Cost__c != NULL
                AND (
                        ((Functional_Rating__c = 'Good' OR Functional_Rating__c = 'Good - Leakage Test Not Available') AND Cosmetic_Rating__c = 'Good')
                        OR ((Functional_Rating__c = 'Good' OR Functional_Rating__c = 'Good - Leakage Test Not Available'
                        OR Functional_Rating__c = 'Fair' OR Functional_Rating__c = 'Fair - Leakage Test Not Available') AND Review_Status__c = 'Finished Goods')
                )
                GROUP BY Product_Name__c
        ];

        Map<String, Decimal> prodAvgCostReadyToShip = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {
            prodAvgCostReadyToShip.put((String) res.get('productId'), (Decimal) res.get('AvgCostShip'));
        }
        /*---------------------------------------------------------------------------------------------------------*/

        /*--------------------- Total Qty in stock NEW -----------------------------------*/
        soqlRes = [SELECT COUNT(Id) TotalQtyinstockNEW,Product_Name__c productId
                FROM ProductItem__c
                WHERE Product_Name__c IN :prodIDs
                AND sold__c = FALSE
                AND Generic_Product__c = FALSE
                AND Functional_Rating__c = 'Good - New'
                AND Location__c != 'External Repair / Testing'
                AND Location__c != 'Customer Loan / Demo'
                AND Location__c != 'Out of Flow'
                AND Location__c != 'On Rental'
                AND (Check_In_Type__c = 'Purchase' OR Check_In_Type__c = 'Core Exchange' OR Check_In_Type__c = 'Harvested' OR Check_In_Type__c = 'Vet – Purchase')
                GROUP BY Product_Name__c
        ];

        Map<String, Integer> prodQtyInstockNew = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
            prodQtyInstockNew.put((String) res.get('productId'), (Integer) res.get('TotalQtyinstockNEW'));
        }
        /*------------------------------------------------------------------------------------------------------*/

        /*------------------------ Avg Cost - NEW -------------------------*/
        soqlRes = [SELECT AVG(Cost__c) AvgCostNEW,Product_Name__c productId
                FROM ProductItem__c
                WHERE Product_Name__c IN:prodIDs
                AND Check_In_Type__c != 'Generic'
                AND Check_In_Type__c != 'Customer Repair'
                AND Check_In_Type__c != 'Warranty Repair'
                AND Generic_Product__c = FALSE
                AND Functional_Rating__c = 'Good - New'
                AND sold__c = FALSE
                AND Cost__c != NULL
                GROUP BY Product_Name__c
        ];
        Map<String, Decimal> prodAvgCostNew = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {
            prodAvgCostNew.put((String) res.get('productId'), (Decimal) res.get('AvgCostNEW'));
        }
        /*---------------------------------------------------------------------------------------------------------*/

        /*--------------------- Quantity in Special Offer -----------------------------------*/
        soqlRes = [SELECT COUNT(Id) TotalQtySpecial,Product_Name__c productId
                FROM ProductItem__c
                WHERE Product_Name__c IN :prodIDs
                AND sold__c = FALSE
                AND Reserved__c = FALSE
                AND Generic_Product__c = FALSE
                AND Review_Status__c = 'Special Offer'
                AND Location__c != 'External Repair / Testing'
                AND Location__c != 'Customer Loan / Demo'
                AND Location__c != 'Out of Flow'
                AND (Check_In_Type__c = 'Purchase' OR Check_In_Type__c = 'Core Exchange' OR Check_In_Type__c = 'Harvested')
                GROUP BY Product_Name__c
        ];
        Map<String, Integer> prodQtyInSpecialOffer = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
            prodQtyInSpecialOffer.put((String) res.get('productId'), (Integer) res.get('TotalQtySpecial'));
        }
        /*------------------------------------------------------------------------------------------------------*/

        /*------------------------ Avg Price - Special Offer -------------------------*/
        soqlRes = [SELECT AVG(Special_Offer_Pricing__c) AvgPriceSpecial,Product_Name__c productId
                FROM ProductItem__c
                WHERE Product_Name__c IN :prodIDs
                AND sold__c = FALSE
                AND Reserved__c = FALSE
                AND Generic_Product__c = FALSE
                AND Review_Status__c = 'Special Offer'
                AND Location__c != 'External Repair / Testing'
                AND Location__c != 'Customer Loan / Demo'
                AND Location__c != 'Out of Flow'
                AND Special_Offer_Pricing__c != NULL
                AND (Check_In_Type__c = 'Purchase' OR Check_In_Type__c = 'Core Exchange' OR Check_In_Type__c = 'Harvested')
                GROUP BY Product_Name__c
        ];
        Map<String, Decimal> prodAvgPriceSpecialOffer = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {
            prodAvgPriceSpecialOffer.put((String) res.get('productId'), (Decimal) res.get('AvgPriceSpecial'));
        }
        /*---------------------------------------------------------------------------------------------------------*/

        /*--------------------- Quantity on Sales Verbal Acceptance AND THIS WEEK ---------------------*/

        Map<String, Integer> prodQtyOnSalesVerbalAccept = new Map<String, Integer>();
        Map<String, Integer> prodQtyOnSalesVerbalAcceptThisWeek = new Map<String, Integer>();

        for (OpportunityLineItem oli : [SELECT Id, Time_Stamp_of_Opportunity_Stage_Change__c, Product2Id
        FROM OpportunityLineItem
        WHERE Product2Id IN :prodIDs
        //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                AND ((Product_Family__c != 'Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                                         (Product_Family__c = 'Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList))
        AND Opportunity.StageName = 'Verbal Acceptance']) {

            if (!prodQtyOnSalesVerbalAccept.containsKey(oli.Product2Id)){
                prodQtyOnSalesVerbalAccept.put(oli.Product2Id, 0);
            }
            prodQtyOnSalesVerbalAccept.put(oli.Product2Id, prodQtyOnSalesVerbalAccept.get(oli.Product2Id) + 1);

            if (oli.Time_Stamp_of_Opportunity_Stage_Change__c != null &&
                    oli.Time_Stamp_of_Opportunity_Stage_Change__c.date().toStartOfWeek() == Date.today().toStartOfWeek()){
                if (!prodQtyOnSalesVerbalAcceptThisWeek.containsKey(oli.Product2Id)){
                    prodQtyOnSalesVerbalAcceptThisWeek.put(oli.Product2Id, 0);
                }
                prodQtyOnSalesVerbalAcceptThisWeek.put(oli.Product2Id, prodQtyOnSalesVerbalAcceptThisWeek.get(oli.Product2Id) + 1);
            }
        }
        /*-------------------------------------------------------------------------------------------------------------*/

        /*--------------------- Total Qty Sales Closed Won AND THIS WEEK ---------------------*/

        Map<String, Integer> prodQtyOnSalesClosedWon = new Map<String, Integer>();
        Map<String, Integer> prodQtyOnSalesClosedWonThisWeek = new Map<String, Integer>();

        for (OpportunityLineItem oli : [SELECT Id, Time_Stamp_of_Opportunity_Stage_Change__c, Product2Id
        FROM OpportunityLineItem
        WHERE Product2Id IN :prodIDs
       //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
        AND ((Product_Family__c != 'Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                                         (Product_Family__c = 'Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList))
        AND Opportunity.StageName = 'Closed Won']) {

            if (!prodQtyOnSalesClosedWon.containsKey(oli.Product2Id)){
                prodQtyOnSalesClosedWon.put(oli.Product2Id, 0);
            }
            prodQtyOnSalesClosedWon.put(oli.Product2Id, prodQtyOnSalesClosedWon.get(oli.Product2Id) + 1);

            if (oli.Time_Stamp_of_Opportunity_Stage_Change__c != null &&
                    oli.Time_Stamp_of_Opportunity_Stage_Change__c.date().toStartOfWeek() == Date.today().toStartOfWeek()){
                if (!prodQtyOnSalesClosedWonThisWeek.containsKey(oli.Product2Id)){
                    prodQtyOnSalesClosedWonThisWeek.put(oli.Product2Id, 0);
                }
                prodQtyOnSalesClosedWonThisWeek.put(oli.Product2Id, prodQtyOnSalesClosedWonThisWeek.get(oli.Product2Id) + 1);
            }
        }

        /*-------------------------------------------------------------------------------------------------------------*/

        /*------------------------------ average supplier’s quote ----------------------------------*/
        soqlRes = [SELECT AVG(Supplier_s_Quote__c) AvgSupplierQuote,Product2Id
                FROM OpportunityLineItem
                WHERE Product2Id IN :prodIDs
                //AND Opportunity.RecordTypeId = :oppPurchRecTypeId
                AND Opportunity.RecordTypeID IN :purchasingOppRecordList
                AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                AND ProductItem__r.Check_In_Type__c != 'Warranty Repair'
                AND Supplier_s_Quote__c != 0
                GROUP BY Product2Id
        ];
        Map<String, Decimal> prodAvgSupplierQuote = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {
            prodAvgSupplierQuote.put((String) res.get('Product2Id'), (Decimal) res.get('AvgSupplierQuote'));
        }
        /*---------------------------------------------------------------------------------------------------------*/

        /*------------------------------ average Probo offer ----------------------------------*/
        soqlRes = [SELECT AVG(Probo_s_Offer__c) AvgProboOffer,Product2Id
                FROM OpportunityLineItem
                WHERE Product2Id IN :prodIDs
                //AND Opportunity.RecordTypeId = :oppPurchRecTypeId
                AND Opportunity.RecordTypeID IN :purchasingOppRecordList
                AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                AND ProductItem__r.Check_In_Type__c != 'Warranty Repair'
                AND Probo_s_Offer__c != 0
                GROUP BY Product2Id
        ];
        Map<String, Decimal> prodAvgProboOffer = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {
            prodAvgProboOffer.put((String) res.get('Product2Id'), (Decimal) res.get('AvgProboOffer'));
        }
        /*---------------------------------------------------------------------------------------------------------*/

        /*------------------------------ average sourcing quote ----------------------------------*/
        soqlRes = [SELECT AVG(Supplier_s_Quote__c) AvgSourcingQuote, Product2Id
                FROM OpportunityLineItem
                WHERE Product2Id IN :prodIDs
                //AND Opportunity.RecordTypeId = :oppPurchRecTypeId
                AND Opportunity.RecordTypeID IN :purchasingOppRecordList
                AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                AND ProductItem__r.Check_In_Type__c != 'Warranty Repair'
                AND Supplier_s_Quote__c != 0
                AND Opportunity.Purchasing_Opportunity_Type__c = 'Sourcing'
                GROUP BY Product2Id
        ];
        Map<String, Decimal> prodAvgSourcingQuote = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {
            prodAvgSourcingQuote.put((String) res.get('Product2Id'), (Decimal) res.get('AvgSourcingQuote'));
        }
        /*---------------------------------------------------------------------------------------------------------*/

        /*------------------------------ total no of purchasing opps ----------------------------------*/
        soqlRes = [SELECT COUNT(Id) TotalPurOppLines, Product2Id
                    FROM OpportunityLineItem
                    WHERE Product2Id IN :prodIDs
                    //AND Opportunity.RecordTypeId = :oppPurchRecTypeId
                   AND Opportunity.RecordTypeID IN :purchasingOppRecordList 
                   GROUP BY Product2Id];

        Map<String, Decimal> prodNumPurchasingOppLines = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {
            prodNumPurchasingOppLines.put((String) res.get('Product2Id'), (Decimal) res.get('TotalPurOppLines'));
        }
        /*---------------------------------------------------------------------------------------------------------*/

        /*--------------------- Quantity on Purchasing Verbal Acceptance AND THIS WEEK ---------------------*/

        Map<String, Integer> prodNumOnPurchVerbalAccept = new Map<String, Integer>();
        Map<String, Integer> prodNumOnPurchVerbalAcceptThisWeek = new Map<String, Integer>();

        for (OpportunityLineItem oli : [SELECT Id, Time_Stamp_of_Opportunity_Stage_Change__c, Product2Id
                                        FROM OpportunityLineItem
                                        WHERE Product2Id IN :prodIDs
                                        //AND Opportunity.RecordTypeId = :oppPurchRecTypeId
                                        AND Opportunity.RecordTypeID IN :purchasingOppRecordList
                                        AND Opportunity.StageName = 'Verbal Acceptance']) {

            if (!prodNumOnPurchVerbalAccept.containsKey(oli.Product2Id)){
                prodNumOnPurchVerbalAccept.put(oli.Product2Id, 0);
            }
            prodNumOnPurchVerbalAccept.put(oli.Product2Id, prodNumOnPurchVerbalAccept.get(oli.Product2Id) + 1);

            if (oli.Time_Stamp_of_Opportunity_Stage_Change__c != null &&
                    oli.Time_Stamp_of_Opportunity_Stage_Change__c.date().toStartOfWeek() == Date.today().toStartOfWeek()){
                if (!prodNumOnPurchVerbalAcceptThisWeek.containsKey(oli.Product2Id)){
                    prodNumOnPurchVerbalAcceptThisWeek.put(oli.Product2Id, 0);
                }
                prodNumOnPurchVerbalAcceptThisWeek.put(oli.Product2Id, prodNumOnPurchVerbalAcceptThisWeek.get(oli.Product2Id) + 1);
            }
        }

        /*-------------------------------------------------------------------------------------------------------------*/


        /*--------------------- Total Qty Purchasing Closed Won AND THIS WEEK ---------------------*/
        Map<String, Integer> prodNumPurchClosedWon = new Map<String, Integer>();
        Map<String, Integer> prodNumPurchClosedWonThisWeek = new Map<String, Integer>();

        for (OpportunityLineItem oli : [SELECT Id, Time_Stamp_of_Opportunity_Stage_Change__c, Product2Id
                                        FROM OpportunityLineItem
                                        WHERE Product2Id IN :prodIDs
                                        //AND Opportunity.RecordTypeId = :oppPurchRecTypeId
                                        AND Opportunity.RecordTypeID IN :purchasingOppRecordList
                                        AND Opportunity.StageName = 'Closed Won']) {

            if (!prodNumPurchClosedWon.containsKey(oli.Product2Id)){
                prodNumPurchClosedWon.put(oli.Product2Id, 0);
            }
            prodNumPurchClosedWon.put(oli.Product2Id, prodNumPurchClosedWon.get(oli.Product2Id) + 1);

            if (oli.Time_Stamp_of_Opportunity_Stage_Change__c != null &&
                    oli.Time_Stamp_of_Opportunity_Stage_Change__c.date().toStartOfWeek() == Date.today().toStartOfWeek()){
                if (!prodNumPurchClosedWonThisWeek.containsKey(oli.Product2Id)){
                    prodNumPurchClosedWonThisWeek.put(oli.Product2Id, 0);
                }
                prodNumPurchClosedWonThisWeek.put(oli.Product2Id, prodNumPurchClosedWonThisWeek.get(oli.Product2Id) + 1);
            }
        }
        /*-------------------------------------------------------------------------------------------------------------*/

        for (Product2 p : prodlist) {

            recordsProcessed ++;

            p.Total_no_of_Requests__c = prodCount.containsKey(p.Id) ? prodCount.get(p.Id) : 0;
            p.No_of_Requests_Not_in_Stock__c = prodNotInStockCount.containsKey(p.Id) ? prodNotInStockCount.get(p.Id) : 0;
            p.Quantity_Sold__c = prodQtySold.containsKey(p.Id) ? prodQtySold.get(p.Id) : 0;
            p.Avg_Sale_Price__c = prodAvgSalesPrice.containsKey(p.Id) ? prodAvgSalesPrice.get(p.Id) : 0;
            p.Avg_Lost_Quote_Price__c = prodAvgLostQuotePrice.containsKey(p.Id) ? prodAvgLostQuotePrice.get(p.Id) : 0;
            p.Qty_Ready_to_Ship__c = prodQtyReadyToShip.containsKey(p.Id) ? prodQtyReadyToShip.get(p.Id) : 0;
            p.Qty_Cosmetically_Repairable__c = prodQtyCosmeticallyRepairable.containsKey(p.Id) ? prodQtyCosmeticallyRepairable.get(p.Id) : 0;
            p.Qty_Functionally_Repairable__c = prodQtyFunctionallyRepairable.containsKey(p.Id) ? prodQtyFunctionallyRepairable.get(p.Id) : 0;
            p.Qty_no_Repair_Eval__c = prodQtyNoRepairEval.containsKey(p.Id) ? prodQtyNoRepairEval.get(p.Id) : 0;
            p.Untested_Probes__c = prodQtyUntestedProbes.containsKey(p.Id) ? prodQtyUntestedProbes.get(p.Id) : 0;
            p.Total_Qty_in_stock__c = prodQtyInStockUsed.containsKey(p.Id) ? prodQtyInStockUsed.get(p.Id) : 0;

            Decimal result;

            if (p.Total_no_of_Requests__c != 0 && p.No_of_Requests_Not_in_Stock__c != 0) {
                p.In_Stock_Rate__c = (1 - (p.No_of_Requests_Not_in_Stock__c / p.Total_no_of_Requests__c)) * 100;
                System.debug('InStockRate: ' + p.In_Stock_Rate__c);
                result = p.Total_no_of_Requests__c - p.No_of_Requests_Not_in_Stock__c;
                System.debug('Subtraction Result: ' + result);

            } else if (p.No_of_Requests_Not_in_Stock__c == 0) {
                p.In_Stock_Rate__c = 100;
                System.debug('InStockRate default with values: ' + p.In_Stock_Rate__c);
                result = p.Total_no_of_Requests__c;

            } else {
                p.In_Stock_Rate__c = 100;
                System.debug('InStockRate default: ' + p.In_Stock_Rate__c);
                result = 0;
            }

            p.Win_Rate__c = result != 0 ? (p.Quantity_Sold__c / result) * 100 : 0;
            p.Functionally_Good_Probes__c = prodQtyFuncGoodProbesUsed.containsKey(p.Id) ? prodQtyFuncGoodProbesUsed.get(p.Id) : 0;
            p.Functionally_Good_Probes_Out_on_Loan__c = prodQtyFuncGoodLoaners.containsKey(p.Id) ? prodQtyFuncGoodLoaners.get(p.Id) : 0;
            p.Functionally_Good_Probes_Approved__c = prodQtyFuncGoodProbesPurchApp.containsKey(p.Id) ? prodQtyFuncGoodProbesPurchApp.get(p.Id) : 0;
            p.Total_Qty_Finished_Goods_Parts__c = prodQtyFinishedGoodsParts.containsKey(p.Id) ? prodQtyFinishedGoodsParts.get(p.Id) : 0;
            //p.Total_Qty_FG_With_Compatible_Parts__c = prodQtyFinishedGoodsPartsWithCompatible.containsKey(p.Id) ? prodQtyFinishedGoodsPartsWithCompatible.get(p.Id) : 0;
            p.Calculated_Avg_Sensitivity__c = prodAvgSensitivity.containsKey(p.Id) ? prodAvgSensitivity.get(p.Id) : 0.00;
            p.Calculated_Avg_Capacitance__c = prodAvgCapacitance.containsKey(p.Id) ? prodAvgCapacitance.get(p.Id) : 0;
            p.Avg_Cost_Functionally_Good__c = prodAvgCostFuncGood.containsKey(p.Id) ? prodAvgCostFuncGood.get(p.Id) : 0;
            p.Avg_Cost_Ready_to_Ship__c = prodAvgCostReadyToShip.containsKey(p.Id) ? prodAvgCostReadyToShip.get(p.Id) : 0;
            p.Total_Qty_of_New_Probes__c = prodQtyInstockNew.containsKey(p.Id) ? prodQtyInstockNew.get(p.Id) : 0;
            p.Avg_Cost_New_Probes__c = prodAvgCostNew.containsKey(p.Id) ? prodAvgCostNew.get(p.Id) : 0;
            p.Total_Qty_of_Special_Offer_Probes__c = prodQtyInSpecialOffer.containsKey(p.Id) ? prodQtyInSpecialOffer.get(p.Id) : 0;
            p.Avg_Price_Special_Offer_Probes__c = prodAvgPriceSpecialOffer.containsKey(p.Id) ? prodAvgPriceSpecialOffer.get(p.Id) : 0;
            p.Total_no_of_purchasing_opps__c = prodNumPurchasingOppLines.containsKey(p.Id) ? prodNumPurchasingOppLines.get(p.Id) : 0;
            p.Average_supplier_s_quote__c = prodAvgSupplierQuote.containsKey(p.Id) ? prodAvgSupplierQuote.get(p.Id) : 0;
            p.Average_Probo_offer__c = prodAvgProboOffer.containsKey(p.Id) ? prodAvgProboOffer.get(p.Id) : 0;
            p.Average_sourcing_quote__c = prodAvgSourcingQuote.containsKey(p.Id) ? prodAvgSourcingQuote.get(p.Id) : 0;
            p.Total_Qty_on_Purchasing_Verbal__c = prodNumOnPurchVerbalAccept.containsKey(p.Id) ? prodNumOnPurchVerbalAccept.get(p.Id) : 0;
            p.Qty_on_Purchasing_Verbal_This_Week__c = prodNumOnPurchVerbalAcceptThisWeek.containsKey(p.Id) ? prodNumOnPurchVerbalAcceptThisWeek.get(p.Id) : 0;
            p.Total_Qty_on_Purchasing_Closed_Won__c = prodNumPurchClosedWon.containsKey(p.Id) ? prodNumPurchClosedWon.get(p.Id) : 0;
            p.Qty_on_Purchasing_Closed_Won_This_Week__c = prodNumPurchClosedWonThisWeek.containsKey(p.Id) ? prodNumPurchClosedWonThisWeek.get(p.Id) : 0;
            p.Total_Qty_on_Sales_Verbal__c = prodQtyOnSalesVerbalAccept.containsKey(p.Id) ? prodQtyOnSalesVerbalAccept.get(p.Id) : 0;
            p.Qty_on_Sales_Verbal_This_Week__c = prodQtyOnSalesVerbalAcceptThisWeek.containsKey(p.Id) ? prodQtyOnSalesVerbalAcceptThisWeek.get(p.Id) : 0;
            p.Total_Qty_on_Sales_Closed_Won__c = prodQtyOnSalesClosedWon.containsKey(p.Id) ? prodQtyOnSalesClosedWon.get(p.Id) : 0;
            p.Qty_on_Sales_Closed_Won_This_Week__c = prodQtyOnSalesClosedWonThisWeek.containsKey(p.Id) ? prodQtyOnSalesClosedWonThisWeek.get(p.Id) : 0;
        }

        update(prodlist);
        System.debug('Updated Successfully');
    }

    global void execute(SchedulableContext sc) {
        UpdateProductFieldBatch bc = new UpdateProductFieldBatch();
        // at size of 75, hit error for number of query rows; changed to 50 12.29.24; changed to 25 on 7.9.25 NB; changed to 5 on 2.17.26 NB
        Database.executeBatch(bc, 5);
        
    }

    global void finish(Database.BatchableContext bc) {
        List<Product2> productsToUpdate = [SELECT Id, Part_Number__c, Compatible_Part_Numbers__c, Total_Qty_FG_With_Compatible_Parts__c, Total_Qty_Finished_Goods_Parts__c from Product2];
        List<Product2> finalProductsToUpdate = new List<Product2>();
        Map<String, ID> partNumberMap = new Map<String, ID>();
    	Map<ID, String> compatiblePartsMap = new Map<ID, String>();
        Map<String, Decimal> finalProdQtyFinishedGoodsParts = new Map<String, Decimal>();
    
        for (Product2 p : productsToUpdate) {
            partNumberMap.put(p.Part_Number__c, p.Id);
            compatiblePartsMap.put(p.Id, p.Compatible_Part_Numbers__c);
            finalProdQtyFinishedGoodsParts.put(p.Id, p.Total_Qty_Finished_Goods_Parts__c);
        }
        	for (Product2 p : productsToUpdate) {
                // calculate total qty finished goods parts on all compatible parts
                List<String> compatiblePartList = new List<String>();
                system.debug('THIS IS THE COMPATIBLE PART SEARCH >>> ' + compatiblePartsMap.get(p.Id));
                if(compatiblePartsMap.get(p.Id) != null){
                    compatiblePartList = compatiblePartsMap.get(p.Id).split(';');
                }
                
                Decimal compatibleAddition = 0;
                if(compatiblePartList.size() != 0){
                    for(String compatible: compatiblePartList){
                        Id compatibleID = partNumberMap.get(compatible);
                        if(compatibleID != null && finalProdQtyFinishedGoodsParts.get(compatibleID) != null){
                            compatibleAddition += finalProdQtyFinishedGoodsParts.get(compatibleID);
                        }
                    }
                }
                // include total qty finished goods for current product as well
                if(finalProdQtyFinishedGoodsParts.get(p.Id) != null){
                    compatibleAddition += finalProdQtyFinishedGoodsParts.get(p.Id);
                }
                if(p.Total_Qty_FG_With_Compatible_Parts__c != compatibleAddition){
                    p.Total_Qty_FG_With_Compatible_Parts__c = compatibleAddition;
                    finalProductsToUpdate.add(p);
                }
                
    	}
        
		update(finalProductsToUpdate);
        System.debug('Updated Compatible Parts fields Successfully >>> ' + finalProductsToUpdate); 
        
        
        
        
		 // Send an email with the number of records processed
         Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
         email.setToAddresses(new String[] {'brandon@delegate.team'});
         email.setSubject('UpdateProductFieldBatch Results');
         email.setPlainTextBody('The batch job updated ' + recordsProcessed + ' records.');
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
         
    }
}