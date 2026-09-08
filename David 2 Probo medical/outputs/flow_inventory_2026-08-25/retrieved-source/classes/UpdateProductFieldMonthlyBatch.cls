global class UpdateProductFieldMonthlyBatch implements Database.Batchable<SObject>, Schedulable, Database.AllowsCallouts {

    String Query;

    global Database.QueryLocator start(Database.BatchableContext bc) {

        Query = 'Select Id,Repair_Priority_Rating__c, Testing_Priority_Rating__c, Avg_Lost_Quote_Price_3_Months__c,Avg_Lost_Quote_Price_6_Months__c,Avg_Lost_Quote_Price_12_Months__c,Avg_Sale_Price_3_Months__c,Avg_Sale_Price_6_Months__c,Avg_Sale_Price_12_Months__c,No_of_Requests_Not_in_Stock_3_Months__c, No_of_Requests_Not_in_Stock_6_Months__c,No_of_Requests_Not_in_Stock_12_Months__c,Quantity_Sold_3_Months__c,Quantity_Sold_6_Months__c, Quantity_Sold_12_Months__c,Total_No_of_Requests_3_Months__c,Total_No_of_Requests_6_Months__c,Total_No_of_Requests_12_Months__c, Win_Rate_3_Months__c,Win_Rate_6_Months__c,Win_Rate_12_Months__c, Total_No_of_Requests_1_Month__c, No_of_Requests_Not_in_Stock_1_Month__c, Qty_Ready_to_Ship__c, Functionally_Good_Probes__c, Sug_Pr_Out__c, Family from Product2';
        return Database.getQueryLocator(Query);
    }

    global void execute(Database.BatchableContext bc, List<Product2> prodlist) {

        Set<Id> pset = new Set<Id>();
        for (Product2 p : prodlist) {
            pset.add(p.Id);
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
        Map<Id, Integer> prodToNumLast30Days = new Map<Id, Integer>();
        Map<Id, Integer> prodToNumLast90Days = new Map<Id, Integer>();
        Map<Id, Integer> prodToNumLast180Days = new Map<Id, Integer>();

        for (OpportunityLineItem oli : [SELECT Id, Product2Id, Close_Date__c
                                        FROM OpportunityLineItem
                                        WHERE Product2Id IN :pset
                                        //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                                        AND ((Product_Family__c != 'Ultrasound Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                                         (Product_Family__c = 'Ultrasound Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList)) AND Close_Date__c = LAST_N_DAYS:180
                                        AND Opportunity.LeadSource != 'Ebay'
                                        
                                        AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                                        AND (ProductItem__r.sold__c = FALSE
                                        OR (ProductItem__r.sold__c = TRUE AND TotalPrice != 0))]){

            if (oli.Close_Date__c > Date.today().addDays(-30)){
                if (!prodToNumLast30Days.containsKey(oli.Product2Id)){
                    prodToNumLast30Days.put(oli.Product2Id, 0);
                }
                prodToNumLast30Days.put(oli.Product2Id, prodToNumLast30Days.get(oli.Product2Id) + 1);
            }

            if (oli.Close_Date__c > Date.today().addDays(-90)){
                if (!prodToNumLast90Days.containsKey(oli.Product2Id)){
                    prodToNumLast90Days.put(oli.Product2Id, 0);
                }
                prodToNumLast90Days.put(oli.Product2Id, prodToNumLast90Days.get(oli.Product2Id) + 1);
            }

            if (oli.Close_Date__c > Date.today().addDays(-180)){
                if (!prodToNumLast180Days.containsKey(oli.Product2Id)){
                    prodToNumLast180Days.put(oli.Product2Id, 0);
                }
                prodToNumLast180Days.put(oli.Product2Id, prodToNumLast180Days.get(oli.Product2Id) + 1);
            }
        }

        /*--------------------- No Of Times Not In Stock ---------------------*/
        Map<Id, Integer> prodToNumNotInStockLast30Days = new Map<Id, Integer>();
        Map<Id, Integer> prodToNumNotInStockLast90Days = new Map<Id, Integer>();
        Map<Id, Integer> prodToNumNotInStockLast180Days = new Map<Id, Integer>();

        for (OpportunityLineItem oli : [SELECT Id, Product2Id, Close_Date__c
                                        FROM OpportunityLineItem
                                        WHERE Product2Id IN :pset
                                        //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                                         AND ((Product_Family__c != 'Ultrasound Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                                         (Product_Family__c = 'Ultrasound Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList))
                                        AND Close_Date__c = LAST_N_DAYS:180
                                        AND ProductItem__r.Generic_Product__c = TRUE]){
                                            // change to check in type of Generic

            if (oli.Close_Date__c > Date.today().addDays(-30)){
                if (!prodToNumNotInStockLast30Days.containsKey(oli.Product2Id)){
                    prodToNumNotInStockLast30Days.put(oli.Product2Id, 0);
                }
                prodToNumNotInStockLast30Days.put(oli.Product2Id, prodToNumNotInStockLast30Days.get(oli.Product2Id) + 1);
            }

            if (oli.Close_Date__c > Date.today().addDays(-90)){
                if (!prodToNumNotInStockLast90Days.containsKey(oli.Product2Id)){
                    prodToNumNotInStockLast90Days.put(oli.Product2Id, 0);
                }
                prodToNumNotInStockLast90Days.put(oli.Product2Id, prodToNumNotInStockLast90Days.get(oli.Product2Id) + 1);
            }

            if (oli.Close_Date__c > Date.today().addDays(-180)){
                if (!prodToNumNotInStockLast180Days.containsKey(oli.Product2Id)){
                    prodToNumNotInStockLast180Days.put(oli.Product2Id, 0);
                }
                prodToNumNotInStockLast180Days.put(oli.Product2Id, prodToNumNotInStockLast180Days.get(oli.Product2Id) + 1);
            }
        }

        /*--------------------- Quantity Sold ---------------------*/
        Map<Id, Integer> prodToNumSoldLast30Days = new Map<Id, Integer>();
        Map<Id, Integer> prodToNumSoldLast90Days = new Map<Id, Integer>();
        Map<Id, Integer> prodToNumSoldLast180Days = new Map<Id, Integer>();

        for (OpportunityLineItem oli : [SELECT Id, Product2Id, Close_Date__c, Ship_Date__c
                                        FROM OpportunityLineItem
                                        WHERE Product2Id IN :pset
                                        //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                                         AND ((Product_Family__c != 'Ultrasound Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                                         (Product_Family__c = 'Ultrasound Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList))
                                        AND Ship_Date__c = LAST_N_DAYS:180
                                        AND Opportunity.StageName = 'Closed Won'
                                        AND Opportunity.LeadSource != 'Ebay - Auction'
                                        AND Opportunity.LeadSource != 'Ebay - Fixed Price'
                                        AND Opportunity.LeadSource != 'Ettin Group Auction'
                                        AND Opportunity.LeadSource != 'Hilditch Auction'
                                        AND TotalPrice != 0
                                        AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                                        AND ProductItem__r.sold__c = TRUE]){

            if (oli.Ship_Date__c > Date.today().addDays(-30)){
                if (!prodToNumSoldLast30Days.containsKey(oli.Product2Id)){
                    prodToNumSoldLast30Days.put(oli.Product2Id, 0);
                }
                prodToNumSoldLast30Days.put(oli.Product2Id, prodToNumSoldLast30Days.get(oli.Product2Id) + 1);
            }

            if (oli.Ship_Date__c > Date.today().addDays(-90)){
                if (!prodToNumSoldLast90Days.containsKey(oli.Product2Id)){
                    prodToNumSoldLast90Days.put(oli.Product2Id, 0);
                }
                prodToNumSoldLast90Days.put(oli.Product2Id, prodToNumSoldLast90Days.get(oli.Product2Id) + 1);
            }

            if (oli.Ship_Date__c > Date.today().addDays(-180)){
                if (!prodToNumSoldLast180Days.containsKey(oli.Product2Id)){
                    prodToNumSoldLast180Days.put(oli.Product2Id, 0);
                }
                prodToNumSoldLast180Days.put(oli.Product2Id, prodToNumSoldLast180Days.get(oli.Product2Id) + 1);
            }
        }

        /*------------------------ Avg Lost Quote Price -------------------------*/
        List<AggregateResult> soqlRes = [SELECT AVG(TotalPrice) AvgLostQuotePrice,Product2Id
                FROM OpportunityLineItem
                WHERE Product2Id IN :pset
               //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                 AND ((Product_Family__c != 'Ultrasound Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                                         (Product_Family__c = 'Ultrasound Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList))
                AND Close_Date__c = LAST_N_DAYS:30
                AND Opportunity.StageName != 'Closed Won'
                AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                AND ProductItem__r.Generic_Product__c = FALSE
                GROUP BY Product2Id
        ];

        Map<String, Decimal> prodAvgLostPrice30Days = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {
            prodAvgLostPrice30Days.put((String) res.get('Product2Id'), (Decimal) res.get('AvgLostQuotePrice'));
        }

        soqlRes = [SELECT AVG(TotalPrice) AvgLostQuotePrice,Product2Id
                FROM OpportunityLineItem
                WHERE Product2Id IN :pset
                //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                 AND ((Product_Family__c != 'Ultrasound Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                                         (Product_Family__c = 'Ultrasound Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList))
                AND Close_Date__c = LAST_N_DAYS:90
                AND Opportunity.StageName != 'Closed Won'
                AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                AND ProductItem__r.Generic_Product__c = FALSE
                GROUP BY Product2Id
        ];

        Map<String, Decimal> prodAvgLostPrice90Days = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {
            prodAvgLostPrice90Days.put((String) res.get('Product2Id'), (Decimal) res.get('AvgLostQuotePrice'));
        }

        soqlRes = [
                SELECT AVG(TotalPrice) AvgLostQuotePrice,Product2Id
                FROM OpportunityLineItem
                WHERE Product2Id IN:pset
                //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                 AND ((Product_Family__c != 'Ultrasound Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                                         (Product_Family__c = 'Ultrasound Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList))
                AND Close_Date__c = LAST_N_DAYS:180
                AND Opportunity.StageName != 'Closed Won'
                AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                AND ProductItem__r.Generic_Product__c = FALSE
                GROUP BY Product2Id
        ];

        Map<String, Decimal> prodAvgLostPrice180Days = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {

            prodAvgLostPrice180Days.put((String) res.get('Product2Id'), (Decimal) res.get('AvgLostQuotePrice'));

        }

        /*------------------------------ Avg Sale Price ----------------------------------*/
        soqlRes = [
                SELECT AVG(TotalPrice) AvgSalePrice,Product2Id
                FROM OpportunityLineItem
                WHERE Product2Id IN :pset
                //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                 AND ((Product_Family__c != 'Ultrasound Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                                         (Product_Family__c = 'Ultrasound Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList))
                AND Ship_Date__c = LAST_N_DAYS:30
                AND TotalPrice > 100
                AND Opportunity.StageName = 'Closed Won'
                AND Opportunity.LeadSource != 'Ebay - Auction'
                AND Opportunity.LeadSource != 'Ebay - Fixed Price'
                AND Opportunity.LeadSource != 'Ettin Group Auction'
                AND Opportunity.LeadSource != 'Hilditch Auction'
                AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                AND ProductItem__r.Generic_Product__c = FALSE
                AND ProductItem__r.sold__c = TRUE
                GROUP BY Product2Id
        ];

        Map<String, Decimal> prodAvgSalePrice30Days = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {
            prodAvgSalePrice30Days.put((String) res.get('Product2Id'), (Decimal) res.get('AvgSalePrice'));
        }

        soqlRes = [
                SELECT AVG(TotalPrice) AvgSalePrice,Product2Id
                FROM OpportunityLineItem
                WHERE Product2Id IN :pset
                //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                 AND ((Product_Family__c != 'Ultrasound Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                                         (Product_Family__c = 'Ultrasound Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList))
                AND Ship_Date__c = LAST_N_DAYS:90
                AND TotalPrice > 100
                AND Opportunity.StageName = 'Closed Won'
                AND Opportunity.LeadSource != 'Ebay - Auction'
                AND Opportunity.LeadSource != 'Ebay - Fixed Price'
                AND Opportunity.LeadSource != 'Ettin Group Auction'
                AND Opportunity.LeadSource != 'Hilditch Auction'
                AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                AND ProductItem__r.Generic_Product__c = FALSE
                AND ProductItem__r.sold__c = TRUE
                GROUP BY Product2Id
        ];

        Map<String, Decimal> prodAvgSalePrice90Days = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {
            prodAvgSalePrice90Days.put((String) res.get('Product2Id'), (Decimal) res.get('AvgSalePrice'));
        }

        soqlRes = [
                SELECT AVG(TotalPrice) AvgSalePrice,Product2Id
                FROM OpportunityLineItem
                WHERE Product2Id IN :pset
                //AND Opportunity.RecordTypeId = :oppSalesRecTypeId
                 AND ((Product_Family__c != 'Ultrasound Part' AND Opportunity.RecordTypeID IN :SalesOppRecordList) OR
                                         (Product_Family__c = 'Ultrasound Part' AND Opportunity.RecordTypeID IN :partSalesOppRecordList))
                AND Ship_Date__c = LAST_N_DAYS:180
                AND TotalPrice > 100
                AND Opportunity.StageName = 'Closed Won'
                AND Opportunity.LeadSource != 'Ebay - Auction'
                AND Opportunity.LeadSource != 'Ebay - Fixed Price'
                AND Opportunity.LeadSource != 'Ettin Group Auction'
                AND Opportunity.LeadSource != 'Hilditch Auction'
                AND ProductItem__r.Check_In_Type__c != 'Customer Repair'
                AND ProductItem__r.Generic_Product__c = FALSE
                AND ProductItem__r.sold__c = TRUE
                GROUP BY Product2Id
        ];

        Map<String, Decimal> prodAvgSalePrice180Days = new Map<String, Decimal>();
        for (AggregateResult res : soqlRes) {
            prodAvgSalePrice180Days.put((String) res.get('Product2Id'), (Decimal) res.get('AvgSalePrice'));
        }

        for (Product2 p : prodlist) {

            /*--------------------- No Of Request ---------------------*/
            p.Total_No_of_Requests_1_Month__c =  prodToNumLast30Days.containsKey(p.Id) ? prodToNumLast30Days.get(p.Id) : 0;
            p.Total_No_of_Requests_3_Months__c =  prodToNumLast90Days.containsKey(p.Id) ? prodToNumLast90Days.get(p.Id) : 0;
            p.Total_No_of_Requests_6_Months__c =  prodToNumLast180Days.containsKey(p.Id) ? prodToNumLast180Days.get(p.Id) : 0;

            /*--------------------- No Of Times Not In Stock ---------------------*/
            p.No_of_Requests_Not_in_Stock_1_Month__c =  prodToNumNotInStockLast30Days.containsKey(p.Id) ? prodToNumNotInStockLast30Days.get(p.Id) : 0;
            p.No_of_Requests_Not_in_Stock_3_Months__c =  prodToNumNotInStockLast90Days.containsKey(p.Id) ? prodToNumNotInStockLast90Days.get(p.Id) : 0;
            p.No_of_Requests_Not_in_Stock_6_Months__c =  prodToNumNotInStockLast180Days.containsKey(p.Id) ? prodToNumNotInStockLast180Days.get(p.Id) : 0;

            /*------------------------------------- In Stock Rate ---------------------------------------------------*/
            Decimal result1mon;

            if (p.Total_No_of_Requests_1_Month__c != 0 && p.No_of_Requests_Not_in_Stock_1_Month__c != 0) {
                p.In_Stock_Rate_1_Month__c = (1 - (p.No_of_Requests_Not_in_Stock_1_Month__c / p.Total_No_of_Requests_1_Month__c)) * 100;
                result1mon = p.Total_No_of_Requests_1_Month__c - p.No_of_Requests_Not_in_Stock_1_Month__c;
            } else  {
                p.In_Stock_Rate_1_Month__c = 100;
                result1mon = p.No_of_Requests_Not_in_Stock_1_Month__c == 0 ? p.Total_No_of_Requests_1_Month__c : 0;
            }

            Decimal result3mon;
            if (p.Total_No_of_Requests_3_Months__c != 0 && p.No_of_Requests_Not_in_Stock_3_Months__c != 0) {
                p.In_Stock_Rate_3_Months__c = (1 - (p.No_of_Requests_Not_in_Stock_3_Months__c / p.Total_No_of_Requests_3_Months__c)) * 100;
                result3mon = p.Total_No_of_Requests_3_Months__c - p.No_of_Requests_Not_in_Stock_3_Months__c;
            } else  {
                p.In_Stock_Rate_3_Months__c = 100;
                result3mon = p.No_of_Requests_Not_in_Stock_3_Months__c == 0 ? p.Total_No_of_Requests_3_Months__c : 0;
            }

            Decimal result6mon;
            if (p.Total_No_of_Requests_6_Months__c != 0 && p.No_of_Requests_Not_in_Stock_6_Months__c != 0) {
                p.In_Stock_Rate_6_Months__c = (1 - (p.No_of_Requests_Not_in_Stock_6_Months__c / p.Total_No_of_Requests_6_Months__c)) * 100;
                result6mon = p.Total_No_of_Requests_6_Months__c - p.No_of_Requests_Not_in_Stock_6_Months__c;
            } else  {
                p.In_Stock_Rate_6_Months__c = 100;
                result6mon = p.No_of_Requests_Not_in_Stock_6_Months__c == 0 ? p.Total_No_of_Requests_6_Months__c : 0;
            }

            /*--------------------- Quantity Sold ---------------------*/
            p.Quantity_Sold_1_Month__c = prodToNumSoldLast30Days.containsKey(p.Id) ? prodToNumSoldLast30Days.get(p.Id) : 0;
            p.Quantity_Sold_3_Months__c = prodToNumSoldLast90Days.containsKey(p.Id) ? prodToNumSoldLast90Days.get(p.Id) : 0;
            p.Quantity_Sold_6_Months__c = prodToNumSoldLast180Days.containsKey(p.Id) ? prodToNumSoldLast180Days.get(p.Id) : 0;

            /*------------------------ Avg Lost Quote Price -------------------------*/
            p.Avg_Lost_Quote_Price_1_Month__c = prodAvgLostPrice30Days.containsKey(p.Id) ? prodAvgLostPrice30Days.get(p.Id) : 0;
            p.Avg_Lost_Quote_Price_3_Months__c = prodAvgLostPrice90Days.containsKey(p.Id) ? prodAvgLostPrice90Days.get(p.Id) : 0;
            p.Avg_Lost_Quote_Price_6_Months__c = prodAvgLostPrice180Days.containsKey(p.Id) ? prodAvgLostPrice180Days.get(p.Id) : 0;

            /*------------------------------ Avg Sale Price ----------------------------------*/
            p.Avg_Sale_Price_1_Month__c = prodAvgSalePrice30Days.containsKey(p.Id) ? prodAvgSalePrice30Days.get(p.Id) : 0;
            p.Avg_Sale_Price_3_Months__c = prodAvgSalePrice90Days.containsKey(p.Id) ? prodAvgSalePrice90Days.get(p.Id) : 0;
            p.Avg_Sale_Price_6_Months__c = prodAvgSalePrice180Days.containsKey(p.Id) ? prodAvgSalePrice180Days.get(p.Id) : 0;

            /*----------------------------------------- WinRate ------------------------------------------*/
            p.Win_Rate_1_Month__c = result1mon != 0 ? (p.Quantity_Sold_1_Month__c / result1mon) * 100 : 0;
            p.Win_Rate_3_Months__c = result3mon != 0 ? (p.Quantity_Sold_3_Months__c / result3mon) * 100 : 0;
            p.Win_Rate_6_Months__c = result6mon != 0 ? (p.Quantity_Sold_6_Months__c / result6mon) * 100 : 0;
        }

        update(prodlist);
        System.debug('Updated successfully');
    }

    global void execute(SchedulableContext sc) {
        UpdateProductFieldMonthlyBatch bc = new UpdateProductFieldMonthlyBatch();

        Database.executeBatch(bc, 5);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('This method is required by the interface.');
    }
}