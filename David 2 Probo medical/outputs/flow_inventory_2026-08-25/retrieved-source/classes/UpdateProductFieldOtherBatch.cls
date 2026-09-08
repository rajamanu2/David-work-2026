global class UpdateProductFieldOtherBatch implements Database.Batchable<SObject>, Schedulable, Database.AllowsCallouts {

    String Query;

    global Database.QueryLocator start(Database.BatchableContext bc) {

        Query = 'Select Id,Repair_Priority_Rating__c, Testing_Priority_Rating__c, Avg_Lost_Quote_Price_3_Months__c,Avg_Lost_Quote_Price_6_Months__c,Avg_Lost_Quote_Price_12_Months__c,Avg_Sale_Price_3_Months__c,Avg_Sale_Price_6_Months__c,Avg_Sale_Price_12_Months__c,No_of_Requests_Not_in_Stock_3_Months__c, No_of_Requests_Not_in_Stock_6_Months__c,No_of_Requests_Not_in_Stock_12_Months__c,Quantity_Sold_3_Months__c,Quantity_Sold_6_Months__c, Quantity_Sold_12_Months__c,Total_No_of_Requests_3_Months__c,Total_No_of_Requests_6_Months__c,Total_No_of_Requests_12_Months__c, Win_Rate_3_Months__c,Win_Rate_6_Months__c,Win_Rate_12_Months__c, Total_No_of_Requests_1_Month__c, No_of_Requests_Not_in_Stock_1_Month__c, Qty_Ready_to_Ship__c, Functionally_Good_Probes__c, Sug_Pr_Out__c, Family from Product2';
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
        for (RecordType r : ProboCommonUtils.getRecordTypes('Opportunity')) {
            if (r.DeveloperName == 'Sales_Opportunity'|| r.DeveloperName == 'Big_Iron_Sales_Opportunity' || r.DeveloperName == 'C_Arm_Sales_Opportunity'
                    || r.DeveloperName == 'Parts_Sales_Opportunity' || r.DeveloperName == 'Probe_Sales_Opportunity' || r.DeveloperName == 'Rental_Opportunity'
                     || r.DeveloperName == 'System_Sales_Opportunity'){
                SalesOppRecordList.add(r.Id);
                partSalesOppRecordList.add(r.Id);
                //oppSalesRecTypeId = r.Id;
                //break;
            }
            if(r.DeveloperName == 'Service_Sales_Opportunity'){
                partSalesOppRecordList.add(r.Id);
            }
        }

        /*--------------------- No Of Request ---------------------*/
        List<AggregateResult> soqlRes = [SELECT COUNT(Id) TotalNo,Product2Id
                FROM OpportunityLineItem
                WHERE Product2Id IN :prodIDs
                //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                AND ((Product_Family__c != 'Ultrasound Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                             (Product_Family__c = 'Ultrasound Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList))        
                AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                AND Close_Date__c = LAST_N_DAYS:365
                AND Opportunity.LeadSource != 'Ebay'
                AND (ProductItem__r.sold__c = FALSE OR (ProductItem__r.sold__c = TRUE AND TotalPrice != 0))
                GROUP BY Product2Id
        ];

        Map<String, Integer> prodNumLast12Mon = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
            prodNumLast12Mon.put((String) res.get('Product2Id'), (Integer) res.get('TotalNo'));
        }
        /*-----------------------------------------------------------------------------------------------------------*/

        /*--------------------- No Of Times Not In Stock ---------------------*/
        soqlRes = [SELECT COUNT(Id) NotInStock,Product2Id
                FROM OpportunityLineItem
                WHERE Product2Id IN :prodIDs
                //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                AND ((Product_Family__c != 'Ultrasound Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                             (Product_Family__c = 'Ultrasound Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList))
                AND Close_Date__c = LAST_N_DAYS:365
                AND ProductItem__r.Generic_Product__c = TRUE
                GROUP BY Product2Id
        ];

        Map<String, Integer> prodNumNotStockLast12Mon = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
            prodNumNotStockLast12Mon.put((String) res.get('Product2Id'), (Integer) res.get('NotInStock'));
        }
        /*-----------------------------------------------------------------------------------------------------------*/

        /*--------------------- Quantity Sold ---------------------*/
        soqlRes = [SELECT COUNT(Id) QuantitySold,Product2Id
                FROM OpportunityLineItem
                WHERE Product2Id IN :prodIDs
                //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                AND ((Product_Family__c != 'Ultrasound Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                             (Product_Family__c = 'Ultrasound Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList))
                AND Ship_Date__c = LAST_N_DAYS:365
                AND TotalPrice != 0
                AND Opportunity.StageName = 'Closed Won'
                AND Opportunity.LeadSource != 'Ebay - Auction'
                AND Opportunity.LeadSource != 'Ebay - Fixed Price'
                AND Opportunity.LeadSource != 'Ettin Group Auction'
                AND Opportunity.LeadSource != 'Hilditch Auction'
                AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                AND ProductItem__r.sold__c = TRUE
                GROUP BY Product2Id
        ];

        Map<String, Integer> prodNumSoldLast12Mon = new Map<String, Integer>();
        for (AggregateResult res : soqlRes) {
            prodNumSoldLast12Mon.put((String) res.get('Product2Id'), (Integer) res.get('QuantitySold'));
        }

        /*------------------------ Avg Lost Quote Price -------------------------*/
        soqlRes = [SELECT AVG(TotalPrice) AvgLostQuotePrice,Product2Id
                FROM OpportunityLineItem
                WHERE Product2Id IN :prodIDs
                //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                AND ((Product_Family__c != 'Ultrasound Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                             (Product_Family__c = 'Ultrasound Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList))
                AND Opportunity.StageName != 'Closed Won'
                AND Close_Date__c = LAST_N_DAYS:365
                AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                AND ProductItem__r.Generic_Product__c = FALSE
                GROUP BY Product2Id
        ];

        Map<String, Decimal> prodAvgLostPriceLast12Mon = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {
            prodAvgLostPriceLast12Mon.put((String) res.get('Product2Id'), (Decimal) res.get('AvgLostQuotePrice'));
        }
        /*-------------------------------------------------------------------------------------------------------------*/


        /*------------------------------ Avg Sale Price ----------------------------------*/
        soqlRes = [SELECT AVG(TotalPrice) AvgSalePrice,Product2Id
                FROM OpportunityLineItem
                WHERE Product2Id IN :prodIDs
                //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                AND ((Product_Family__c != 'Ultrasound Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                             (Product_Family__c = 'Ultrasound Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList))
                AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                AND Ship_Date__c = LAST_N_DAYS:365
                AND TotalPrice > 100
                AND Opportunity.StageName = 'Closed Won'
                AND Opportunity.LeadSource != 'Ebay - Auction'
                AND Opportunity.LeadSource != 'Ebay - Fixed Price'
                AND Opportunity.LeadSource != 'Ettin Group Auction'
                AND Opportunity.LeadSource != 'Hilditch Auction'
                AND ProductItem__r.Generic_Product__c = FALSE
                AND ProductItem__r.sold__c = TRUE
                GROUP BY Product2Id
        ];

        Map<String, Decimal> prodAvgSalePriceLast12Mon = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {
            prodAvgSalePriceLast12Mon.put((String) res.get('Product2Id'), (Decimal) res.get('AvgSalePrice'));
        }

        /*---------------------------------------------------------------------------------------------------------*/

        for (Product2 p : prodlist) {

            p.Total_No_of_Requests_12_Months__c = prodNumLast12Mon.containsKey(p.Id) ? prodNumLast12Mon.get(p.Id) : 0;
            Decimal halfTotNumRequests12Mons = prodNumLast12Mon.containsKey(p.Id) ? prodNumLast12Mon.get(p.Id) / 2 : 0;

            p.No_of_Requests_Not_in_Stock_12_Months__c = prodNumNotStockLast12Mon.containsKey(p.Id) ? prodNumNotStockLast12Mon.get(p.Id) : 0;

            Decimal result12mon;

            if (p.Total_No_of_Requests_12_Months__c != 0 && p.No_of_Requests_Not_in_Stock_12_Months__c != 0) {
                p.In_Stock_Rate_12_Months__c = (p.No_of_Requests_Not_in_Stock_12_Months__c / p.Total_No_of_Requests_12_Months__c) * 100;
                result12mon = p.Total_No_of_Requests_12_Months__c - p.No_of_Requests_Not_in_Stock_12_Months__c ;
            } else {
                p.In_Stock_Rate_12_Months__c = 100;
                result12mon = p.No_of_Requests_Not_in_Stock_12_Months__c == 0 ? p.Total_No_of_Requests_12_Months__c : 0;
            }

            p.Quantity_Sold_12_Months__c = prodNumSoldLast12Mon.containsKey(p.Id) ? prodNumSoldLast12Mon.get(p.Id) : 0;
            p.Avg_Lost_Quote_Price_12_Months__c = prodAvgLostPriceLast12Mon.containsKey(p.Id) ? prodAvgLostPriceLast12Mon.get(p.Id) : 0;
            p.Avg_Sale_Price_12_Months__c = prodAvgSalePriceLast12Mon.containsKey(p.Id) ? prodAvgSalePriceLast12Mon.get(p.Id) : 0;
            p.Win_Rate_12_Months__c = result12mon != 0 ? (p.Quantity_Sold_12_Months__c / result12mon) * 100 : 0;

            Decimal sugPrOut80Pct = p.Sug_Pr_Out__c != null ?  (p.Sug_Pr_Out__c / 80) : 0;
            Decimal qtyReadyToShipTimes10 = p.Qty_Ready_to_Ship__c != null ? (p.Qty_Ready_to_Ship__c * 10) : 0;
            Decimal funcGoodProbesTimes10 = p.Functionally_Good_Probes__c != null ? (p.Functionally_Good_Probes__c * 10) : 0;
            Decimal funcGoodPartsTimes10 = p.Total_Qty_Finished_Goods_Parts__c != null ? (p.Total_Qty_Finished_Goods_Parts__c * 10) : 0;

            if (sugPrOut80Pct != 0 && halfTotNumRequests12Mons != 0 && qtyReadyToShipTimes10 != 0) {
                p.Repair_Priority_Rating__c = sugPrOut80Pct - qtyReadyToShipTimes10 + halfTotNumRequests12Mons;
            } else if (sugPrOut80Pct == 0 && halfTotNumRequests12Mons != 0 && qtyReadyToShipTimes10 != 0) {
                p.Repair_Priority_Rating__c = Math.max(0, sugPrOut80Pct - qtyReadyToShipTimes10 + halfTotNumRequests12Mons);
            } else {
                p.Repair_Priority_Rating__c = sugPrOut80Pct - qtyReadyToShipTimes10 + halfTotNumRequests12Mons;
            }

            if (sugPrOut80Pct != 0 && halfTotNumRequests12Mons != 0 && funcGoodProbesTimes10 != 0) {
                p.Testing_Priority_Rating__c = sugPrOut80Pct - funcGoodProbesTimes10 + halfTotNumRequests12Mons;
            } else if (sugPrOut80Pct == 0 && halfTotNumRequests12Mons != 0 && funcGoodProbesTimes10 != 0 ) {
                p.Testing_Priority_Rating__c = Math.max(0, sugPrOut80Pct - funcGoodProbesTimes10 + halfTotNumRequests12Mons);
            } else {
                p.Testing_Priority_Rating__c = sugPrOut80Pct - funcGoodProbesTimes10 + halfTotNumRequests12Mons;
            }
            /* PARTS PRIORITY RATING SET TO FORMULA FIELD: if need to change, here is the code to set it.
            if (sugPrOut80Pct != 0 && halfTotNumRequests12Mons != 0 && funcGoodPartsTimes10 != 0) {
                p.Parts_Priority_Rating__c = sugPrOut80Pct - funcGoodPartsTimes10 + halfTotNumRequests12Mons;
            } else if (sugPrOut80Pct == 0 && halfTotNumRequests12Mons != 0 && funcGoodPartsTimes10 != 0 ) {
                p.Parts_Priority_Rating__c = Math.max(0, sugPrOut80Pct - funcGoodPartsTimes10 + halfTotNumRequests12Mons);
            } else {
                p.Parts_Priority_Rating__c = sugPrOut80Pct - funcGoodPartsTimes10 + halfTotNumRequests12Mons;
            }*/
        }

        update(prodlist);
        System.debug('Updated successfully');
    }

    global void execute(SchedulableContext sc) {
        UpdateProductFieldOtherBatch bc = new UpdateProductFieldOtherBatch();
        Database.executeBatch(bc, 5);
    }

    global void finish(Database.BatchableContext bc) {
    }
}