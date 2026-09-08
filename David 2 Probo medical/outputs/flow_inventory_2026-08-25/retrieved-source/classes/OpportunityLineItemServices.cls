public class OpportunityLineItemServices {
    public static final Integer maxRows = 200;
    //public static Id salesRecordTypeId = RecordTypeUtility.getRecordTypeByName('Opportunity', 'Sales Opportunity');
    //public static Id purchasingRecordTypeId = RecordTypeUtility.getRecordTypeByName('Opportunity', 'Purchasing Opportunity');
    //public static Id repairRecordTypeId = RecordTypeUtility.getRecordTypeByName('Opportunity', 'External Repair / Testing');
  public static list<id> salesOppRecordList = new list<id>();
    public static list<id> purchasingOppRecordList = new list<id>();
   
    
    // This method is used on the lightning version of the Add Product page.
    // It returns Assets and related Product information based on the user's search.
    @AuraEnabled
    public static List<Object> getProducts(Map<String, Object> queryParams) {
      List<ProductItem__c> listProductItems = new List<ProductItem__c>();   
      List<List<SObject>> searchList = new List<List<SObject>>();
      system.debug('#### queryParams: ' + queryParams);
       
      String strWhereClause;
        
      for (String p: queryParams.keySet()) {
          switch on p {
              when 'queryString' {
                  // Add search string to match Product Names
                  system.debug('#### search string: ' + (String)queryParams.get('queryString'));
                  String searchStringValue = (String)queryParams.get('queryString');
                  strWhereClause = ' WHERE (Product_Name__r.Name like \'%' + searchStringValue + '%\' OR ';
                  strWhereClause += ' Name like \'%' + searchStringValue + '%\' OR Serial_No__c like \'%' + searchStringValue + '%\' OR';
                  strWhereClause += ' Part_Number__c like \'%' + searchStringValue + '%\' OR Compatible_System__c like \'%' + searchStringValue + '%\')';
                  strWhereClause += ' AND Sold__c = False';
              }  
              when 'family' {  
                  List<Object> selectedFamilies = (List<Object>)queryParams.get('family'); 
                  system.debug('#### selected families: ' + queryParams.get('family'));
                  List<String> selectedFamiliesToQuery = new List<String>();
                  
                  if (selectedFamilies != null) {
                      for (Object o: selectedFamilies) {
                          String productFamily = String.valueOf(o);
                          if (productFamily != '') {
                              selectedFamiliesToQuery.add(productFamily); 
                              system.debug('#### product family' + productFamily);
                          }
                      }
                      
                      if (!selectedFamiliesToQuery.isEmpty()) {
                          strWhereClause += ' AND Product_Name__r.Family IN(' ;
                          
                          for (String s: selectedFamiliesToQuery) {
                             strWhereClause += '\'' + s + '\',';
                          }
                          
                          strWhereClause = strWhereClause.removeEnd(',') + ')';
                      }  
                  }
              }
              when 'functionalRating' {    
                  List<Object> selectedFuntionalRating = (List<Object>)queryParams.get('functionalRating'); 
                  system.debug('#### selected functional rating: ' + queryParams.get('functionalRating'));
                  Set<String> selectedFuntionalRatingsToQuery = new Set<String>();
                  
                  if (selectedFuntionalRating != null) {
                      for (Object o: selectedFuntionalRating) {
                          String rating = String.valueOf(o);
                          if (rating != '') {
                              selectedFuntionalRatingsToQuery.add(rating); 
                              system.debug('#### functional rating' + rating);
                          }
                      }
                      
         if (!selectedFuntionalRatingsToQuery.isEmpty()) {
                          strWhereClause += ' AND (Functional_Rating__c like ' ;
              Boolean firstIteration = true;
                          
                          for (String s: selectedFuntionalRatingsToQuery) {
                  if (firstIteration) {
                strWhereClause += '\'%' + s + '%\'';
                } else {
                  strWhereClause += ' OR Functional_Rating__c like ' + '\'%' + s + '%\'';
                }
               
               firstIteration = false;
                          }
                          
                          strWhereClause += ')';
              
              if (selectedFuntionalRatingsToQuery.contains('Good') && !selectedFuntionalRatingsToQuery.contains('New')) {
              strWhereClause += ' AND (Functional_Rating__c != \'Good - New\' AND Functional_Rating__c !=null)';
              }
                      }   
                  }
              }
              when 'cosmeticRating' {    
                  List<Object> selectedCosmeticRating = (List<Object>)queryParams.get('cosmeticRating'); 
                  system.debug('#### selected cosmetic rating: ' + queryParams.get('cosmeticRating'));
                  List<String> selectedCosmeticRatingsToQuery = new List<String>();
                  
                  if (selectedCosmeticRating != null) {
                      for (Object o: selectedCosmeticRating) {
                          String rating = String.valueOf(o);
                          if (rating != '') {
                              selectedCosmeticRatingsToQuery.add(rating); 
                              system.debug('#### cosmetic rating' + rating);
                          }
                      }
                      
                      if (!selectedCosmeticRatingsToQuery.isEmpty()) {
                          strWhereClause += ' AND Cosmetic_Rating__c IN(' ;
                          
                          for (String s: selectedCosmeticRatingsToQuery) {
                             strWhereClause += '\'' + s + '\',';
                          }
                          
                          strWhereClause = strWhereClause.removeEnd(',') + ')';
                      }  
                  }
              }
              when 'checkInType' {    
                  List<Object> selectedCheckInType = (List<Object>)queryParams.get('checkInType'); 
                  system.debug('#### selected check in type: ' + queryParams.get('checkInType'));
                  List<String> selectedCheckInTypesToQuery = new List<String>();
                  
                  if (selectedCheckInType != null) {
                      for (Object o: selectedCheckInType) {
                          String rating = String.valueOf(o);
                          if (rating != '') {
                              selectedCheckInTypesToQuery.add(rating); 
                              system.debug('#### check In Type' + rating);
                          }
                      }
                      
                      if (!selectedCheckInTypesToQuery.isEmpty()) {
                          strWhereClause += ' AND Check_In_Type__c IN(' ;
                          
                          for (String s: selectedCheckInTypesToQuery) {
                             strWhereClause += '\'' + s + '\',';
                          }
                          
                          strWhereClause = strWhereClause.removeEnd(',') + ')';
                      }  
                  }
              }
              when 'reviewStatus' {    
                  List<Object> selectedFuntionalRating = (List<Object>)queryParams.get('reviewStatus'); 
                  system.debug('#### selected review status: ' + queryParams.get('reviewStatus'));
                  List<String> selectedFuntionalRatingsToQuery = new List<String>();
                  
                  if (selectedFuntionalRating != null) {
                      for (Object o: selectedFuntionalRating) {
                          String rating = String.valueOf(o);
                          if (rating != '') {
                              selectedFuntionalRatingsToQuery.add(rating); 
                              system.debug('#### review status' + rating);
                          }
                      }
                      
                      if (!selectedFuntionalRatingsToQuery.isEmpty()) {
                          strWhereClause += ' AND Review_Status__c IN(' ;
                          
                          for (String s: selectedFuntionalRatingsToQuery) {
                             strWhereClause += '\'' + s + '\',';
                          }
                          
                          strWhereClause = strWhereClause.removeEnd(',') + ')';
                      }  
                  }
              }
              when 'domestic' {    
                  Object selectedDomesticOption = (Object)queryParams.get('domestic'); 
                  system.debug('#### selected domestic option: ' + queryParams.get('domestic'));
                  
                  if (selectedDomesticOption != null) {
                      Boolean selectedDomesticOptionToQuery = Boolean.valueOf(selectedDomesticOption);
                      if (selectedDomesticOptionToQuery == true) {
                          // No additional filtering. All assets are visible.
                      } else {
                          strWhereClause += ' AND Domestic_Only__c = false';
                      }
                  }    
              }
              when 'locations' {
                //  Object selectedDomesticOption = (Object)queryParams.get('locations');
                  GH_Logger.debug('#### selected locations option: ' + queryParams.get('locations'));

                  if ((Object)queryParams.get('locations') != null) {
                      Boolean selectedDomesticOptionToQuery = Boolean.valueOf((Object)queryParams.get('locations'));
                      if (selectedDomesticOptionToQuery == true) {
                          // No additional filtering. All assets are visible.
                      } else {
                          strWhereClause += ' AND Location__c <> \'Customer Loan / Demo\'' +
                                  ' AND Location__c <> \'Rental\'' +
                                  ' AND Location__c <> \'External Repair / Testing\'' +
                                  ' AND Location__c <> \'Returned to Vendor/Cust\'';
                      }
                  }
              }
              /*when 'available' {
                  Object selectedAvailableOption = (Object)queryParams.get('available'); 
                  system.debug('#### selected available option: ' + queryParams.get('available'));
                  
                  if (selectedAvailableOption != null) {
                      Boolean selectedAvailableOptionToQuery = Boolean.valueOf(selectedAvailableOption);
                      if (selectedAvailableOptionToQuery == true) {
                          strWhereClause += ' AND Available_To_Sell__c = true';
                      } else {
                          strWhereClause += ' AND Available_To_Sell__c = false';
                      }
                  }    
              }*/
              
          }  
      } 
        
      System.debug('#### getProducts method where clause: ' + strWhereClause); 
      String query = getProductQuery();  
      query += strWhereClause;
      query += ' ORDER BY Name ASC LIMIT ' + maxRows;
      System.debug('#### getProducts method query: ' + query); 
        
      for(ProductItem__c p: Database.query(query)) {
        listProductItems.add(p); 
      }
        
        System.debug('#### getProducts listProductItems: ' + listProductItems);
        return listProductItems;
    }

    // This method is used on the lightning version of the Add Product page.
    // It is used to build the query for the getProducts method above.
    private static String getProductQuery() {
        String query = 'SELECT Id,Name,Product_Name__c,Product_Name__r.name,Createddate,Model__c,Part_Number__c,Serial_No__c,Compatible_System__c,Functional_Rating__c,';
               query += ' Functional_Notes__c,Price__c,Cosmetic_Rating__c,Cosmetic_Notes__c,Location__c,';
               query += ' Std_Cost_ex__c,Std_Cost_Out__c, Sug_Pr_Ex__c,Sug_Pr_Out__c,Cost__c,';
               query += ' Sug_Price_with_System__c, PO_Number__c,Other_Notes__c,Generic_Product__c,Image__c,Frequency_High__c,Frequency_Low__c,';
               query += ' Date_of_Manufacture__c,Product_Description__c,System_Software__c,Receive_date__c,Check_In_Type__c,Purchasing_Approved__c,';
               query += ' Repair_Activity__c,Repair_Priority_Rating__c,First_Call_Capability__c,System_Test_Bed__c,Repair_Summary__c,Review_Status__c, Review_Status_Notes__c,';
               query += ' Special_Offer_Pricing__c,Product_Name__r.Total_no_of_Requests__c,Product_Name__r.Total_Qty_in_stock__c, Domestic_Only__c,';
               query += ' Product_Name__r.Functionally_Good_Probes_Total__c, Product_Name__r.Total_Qty_of_New_Probes__c,';
               query += ' Product_Name__r.Functionally_Good_Probes__c,D_System_Test__c, Product_Name__r.Total_Qty_on_Purchasing_Verbal__c, Vendor__c,Vendor_Name__c,';
               query += ' Product_Name__r.New_Std_Cost_Out__c, Product_Name__r.New_Std_Cost_Ex__c, Product_Name__r.New_Sug_Pr_Out__c, Product_Name__r.New_Sug_Pr_Ex__c,';
               query += ' Product_Name__r.Proposed_STD_Wholesale_Price__c, Product_Name__r.Proposed_STD_w_Refurb_30_day__c, Product_Name__r.Proposed_STD_Retail__c,';
               query += ' Product_Name__r.Qty_Ready_to_Ship__c,Product_Name__r.Target_Quantity_in_Stock__c,Product_Name__r.Untested_Probes__c,Reserved__c, Posted_on_Ebay__c,';
               query += ' Avg_Sale_Price__c, Repair_Notes_Summary__c, Product_Name__r.Probe_Type__c, (select Probo_s_Offer__c,Supplier_s_Quote__c,Quantity from Opportunity_Product__r)';
               query += ' FROM ProductItem__c';
        
        return query;
    }
    
    // This method is used on the lightning Swap Product page.
    // It returns the existing line items on the opportunity and provides
    // the data to enable a user to select which items to swap.
    @AuraEnabled(cacheable=true)
    public static String getOpportunityLineItemsQuery(String opportunityId) {
        system.debug('#### calling getOpportunityLineItemsQuery method');
        String queryString = 'SELECT Id, Product_Name__c, Check_In_Type__c, OpportunityId, Asset_No__c, Exchange__c';
               queryString += ' FROM OpportunityLineItem WHERE OpportunityId =\'' +  opportunityId + '\' ORDER BY Product_Name__c';
 
        system.debug('#### existing Opportunity line items query returned:' + queryString);
        return queryString;
    } 
    
    // This method is used on the lightning version of the Add Product page.
    // It is called when the user saves the items they have selected.
    // It generates line items on the Opportunity.
    @AuraEnabled
    public static String createOpportunityLineItems(List<Map<String, Object>> selectedItems, List<Map<String, Object>> selectedPurchasingItems,  List<Object> swapItems, String opportunityId, Boolean exchangeValue) {
        // First get record types
        
        for (RecordType r : ProboCommonUtils.getRecordTypes('Opportunity')) {
            switch on r.DeveloperName{
                when 'Sales_Opportunity' {
                    salesOppRecordList.add(r.Id);
                }
                
                when 'Big_Iron_Sales_Opportunity'{
                    salesOppRecordList.add(r.Id);
                }
                
                when 'C_Arm_Sales_Opportunity'{
                    salesOppRecordList.add(r.Id);
                }
                
                when 'Parts_Sales_Opportunity' {
                    salesOppRecordList.add(r.Id);
                }
                
                when 'Probe_Sales_Opportunity'{
                    salesOppRecordList.add(r.Id);
                } 
                
                when 'Rental_Opportunity'{
                    salesOppRecordList.add(r.Id);
                }
                
               when 'Service_Sales_Opportunity'{
                    salesOppRecordList.add(r.Id);
                } 
                
                when 'System_Sales_Opportunity'{
                    salesOppRecordList.add(r.Id);
                }

                when 'Purchasing_Opportunity' {
                    purchasingOppRecordList.add(r.id);
                    
                }
                
                when 'Big_Iron_Purchasing_Opportunity'{
                    purchasingOppRecordList.add(r.id);
                }
            }
        }
        
        
        
        
        system.debug('#### calling createOpportunityLineItems method.');
        system.debug('#### item list: ' + selectedItems);
        system.debug('#### purchasing item list: ' + selectedPurchasingItems);
        system.debug('#### swap list: ' + swapItems);
        system.debug('#### Opportunity Id: ' + opportunityId);
        String statusMessage;
        //Pricebook2 pb;
        Id pbId;
        List<OpportunityLineItem> oliListToInsert = new List<OpportunityLineItem>();
        List<OpportunityLineItem> oliListToDelete = new List<OpportunityLineItem>();
        List<ProductItem__c> pItemList = new List<ProductItem__c>();
        List<ProductItem__c> updatedItemList = new List<ProductItem__c>();
        Map<Id, ProductItem__c> pItemMap = new Map<Id, ProductItem__c>();
        Map<Id, OpportunityLineItem> mapLineItem = new Map<Id, OpportunityLineItem>();
        Set<String> setProductNames = new Set<String>();
        Boolean isSwap = false;
        Boolean isOppUpdated = false;
        Opportunity currentOpp = new Opportunity();
        Map<String, String> mapOriginalIdToSelectedId = new Map<String, String>(); 
        Map<String, String> mapSelectedIdToOriginalId = new Map<String, String>();
        Set<Id> setSelectedItemsForSwap = new Set<Id>();
        Map<String, Id> mapProductToPriceBookEntryId = new Map<String, Id>();
        Map<String, Map<String, Object>> mapUpdatedProductItems = new Map<String, Map<String, Object>>();
        String recordIdList = '(';
        Opportunity opp = [SELECT Id, StageName, Ship_Date__c, CurrencyIsoCode, RecordTypeId FROM Opportunity WHERE Id =: opportunityId];
        system.debug('#### opp: ' + opp);
         
        if (purchasingOppRecordList.contains(opp.RecordTypeId)) {
            for (Map<String, Object> o : selectedPurchasingItems) {
                system.debug('#### object map: ' + o);
                Map<String, Object>  mapPurchasingProductItemValues = new Map<String, Object>();
                String recordId = String.valueOf(o.get('id'));
                system.debug('#### id: ' + recordId);
                recordIdList += '\'' + recordId + '\',';
                mapPurchasingProductItemValues.put('price', o.get('price'));
                mapPurchasingProductItemValues.put('cost', o.get('cost'));
                mapPurchasingProductItemValues.put('offer', o.get('offer'));
                mapPurchasingProductItemValues.put('quote', o.get('quote'));
                mapPurchasingProductItemValues.put('exchange', o.get('exchange'));
                mapUpdatedProductItems.put(recordId, mapPurchasingProductItemValues);
                system.debug('#### mapPurchasingProductItemValues: ' + mapPurchasingProductItemValues);
                system.debug('#### mapUpdatedProductItems: ' + mapUpdatedProductItems);
            }
        } else {
            for (Map<String, Object> o : selectedItems) {
                system.debug('#### object map: ' + o);
                Map<String, Object>  mapSalesProductItemValues = new Map<String, Object>();
                String recordId = String.valueOf(o.get('id'));
                system.debug('#### id: ' + recordId);
                recordIdList += '\'' + recordId + '\',';
                mapSalesProductItemValues.put('price', o.get('price'));
                mapSalesProductItemValues.put('cost', o.get('cost'));
                system.debug('EXCHANGE VALUE INSIDE CREATE OLI LOOP >> ' + exchangeValue);
                if(exchangeValue != true){
                    mapSalesProductItemValues.put('exchange', o.get('exchange'));
                }
                
                if(exchangeValue == true){
                    mapSalesProductItemValues.put('exchange', exchangeValue);
                }
                mapUpdatedProductItems.put(recordId, mapSalesProductItemValues);
                system.debug('#### mapSalesProductItemValues: ' + mapSalesProductItemValues);
                system.debug('#### mapUpdatedProductItems: ' + mapUpdatedProductItems);
            }
        }
        
        if (swapItems != null) {
            isSwap = true;
            
            for (Object o : swapItems) {
                system.debug('#### object : ' + o);
                String keyValue = String.valueOf(o);
                system.debug('#### key value : ' + keyValue);
                
                if (keyValue != null) {
                    String originalItemRecordId = keyValue.substringBefore('-');
                    system.debug('#### original id: ' + originalItemRecordId);
                    
                    String selectedItemRecordId =keyValue.substringAfter('-');
                    system.debug('#### selected id: ' + selectedItemRecordId);
                    if (!recordIdList.contains(selectedItemRecordId)){
                      recordIdList += '\'' + selectedItemRecordId + '\',';
                    }    
                    setSelectedItemsForSwap.add(selectedItemRecordId);
                
                  mapOriginalIdToSelectedId.put(originalItemRecordId, selectedItemRecordId);
                    mapSelectedIdToOriginalId.put(selectedItemRecordId, originalItemRecordId);
                }
                
                system.debug('#### mapOriginalIdToSelectedId : ' + mapOriginalIdToSelectedId);
                 mapLineItem = new Map<Id, OpportunityLineItem> ([SELECT Id, Check_In_Type__c, UnitPrice, Cost__c, Exchange__c FROM OpportunityLineItem WHERE OpportunityId =: opportunityId AND Id IN: mapOriginalIdToSelectedId.keySet() ]);
              system.debug('mapLineItem data: ' + mapLineItem.values());

          } 
        } 
        
        recordIdList = recordIdList.removeEnd(',') + ')';
        String whereClause = ' WHERE Id IN ' + recordIdList;
        System.debug('#### createOpportunityLineItems method whereClause: ' + whereClause);
        String query = getProductQuery();  
        query += whereClause;
        System.debug('#### createOpportunityLineItems method query: ' + query);
        
        for(ProductItem__c p: Database.query(query)) {
          pItemList.add(p);
            system.debug('#### item: ' + p);
            setProductNames.add(p.Product_Name__r.Name);
            pItemMap.put(p.Id, p);
        }
        
        if (test.isRunningTest()) {
            pbId = ProboCommonUtils.getStdPricebookId();
        } else {
            try {
                Pricebook2 pb = [select Id from PriceBook2 where isStandard = true and isActive = true limit 1];
                pbId = pb.Id;
            } catch (Exception e) {
                system.debug('#### Unable to find standard priceBook. Cannot continue.');
                statusMessage = 'Unable to find standard priceBook. Cannot continue.';
            } 
        }
        
        if (pbId != null && pItemList.size() != 0 && setProductNames.size() != 0) {
            system.debug('#### processing new line items');
            mapProductToPriceBookEntryId = createPriceBookEntries(pItemList, setProductNames, pbId, opp.CurrencyIsoCode);

            // Dedupe within THIS request only: never insert the same ProductItem twice in a single save.
            // Items already sitting on the opportunity from a previous save are intentionally left untouched.
            Set<Id> processedProductItemIds = new Set<Id>();

            for (ProductItem__c p: pItemList) {
                // Skip if we've already built an OLI for this ProductItem in this same call.
                // Swap-selected items are exempt so the swap flow is unaffected.
                if (processedProductItemIds.contains(p.Id) && !setSelectedItemsForSwap.contains(p.Id)) {
                    system.debug('#### skipping duplicate ProductItem within this request: ' + p.Id);
                    continue;
                }
                processedProductItemIds.add(p.Id);

                Id priceBookEntryId;
                OpportunityLineItem oli;
                ProductItem__c updatedProductItem;
                
                if (mapProductToPriceBookEntryId != null && mapProductToPriceBookEntryId.containsKey(p.Product_Name__r.Name)) {
                    priceBookEntryId = mapProductToPriceBookEntryId.get(p.Product_Name__r.Name);  
                }
                
                Map<String, Object>  mapProductItemValues = mapUpdatedProductItems.get(p.Id);
                oli = generateOpportunityLineItem(p, opp, priceBookEntryId, mapProductItemValues);
                if (isSwap && !mapSelectedIdToOriginalId.isEmpty() && !mapLineItem.isEmpty()) {
                    Id originalOliId = mapSelectedIdToOriginalId.get(p.Id);
                    OpportunityLineItem originalOli = mapLineItem.get(originalOliId);
                    oli = updateOpportunityLineItem(originalOli, oli);
                }
                oliListToInsert.add(oli);
                updatedProductItem = updateProductItem(p, opp, mapProductItemValues);
                if (updatedProductItem != null && updatedProductItem.Id != null) {
                    updatedItemList.add(updatedProductItem);
                }
            } 
            
            currentOpp = [SELECT Id, Name, CloseDate FROM Opportunity WHERE Id =: opportunityId];
            if (currentOpp.Name == 'TEST QUICK OPP') {
                String oppName = currentOpp.CloseDate.format() + ', ' + pItemList[0].Product_Name__r.Name;
                system.debug('updated opp name: ' + oppName);
                currentOpp.Name = oppName;
                isOppUpdated = true;
            }
            
        } 
        
        if(isSwap) {
            system.debug('#### processing line item swap');
            
            if (!mapLineItem.isEmpty() && !mapOriginalIdToSelectedId.isEmpty()) {
                for (String originalItemRecordId : mapOriginalIdToSelectedId.keySet()){
                    OpportunityLineItem existingLineItem = mapLineItem.get(originalItemRecordId);
                    system.debug('#### existing line item: ' + existingLineItem);
                    oliListToDelete.add(existingLineItem);
                }
            }
        }
         
        if (!oliListToInsert.isEmpty()) {
            try { 
                system.debug('THIS IS THE OLI LIST TO INSERT FROM OLI SERVICES >>> ' + oliListToInsert);
                
              DatabaseService.insertList(oliListToInsert);
                system.debug('THIS IS THE NUMBER OF QUERIES SO FAR (OLI) >>>' + Limits.getQueries());
                statusMessage = 'success';
            }  catch (Exception e) {
                statusMessage += 'error: ' + e.getMessage().unescapeHtml4();
            }
        }
        
        if (!updatedItemList.isEmpty()) {
            try { 
                system.debug('THIS IS THE ITEM LIST TO UPDATE FROM OLI SERVICES >>> ' + updatedItemList);
                
              DatabaseService.updateList(updatedItemList);
                system.debug('THIS IS THE NUMBER OF QUERIES SO FAR (ITEM) >>>' + Limits.getQueries());
                statusMessage = 'success';
            }  catch (Exception e) {
                if (statusMessage != null && statusMessage == 'success'){
                   statusMessage = 'error: '; 
                }
                statusMessage += e.getMessage().unescapeHtml4();
            }
        }
        
        if (!oliListToDelete.isEmpty()) {
           try { 
               system.debug('THIS IS THE OLI LIST TO DELETE FROM OLI SERVICES >>> ' + oliListToDelete);
              DatabaseService.deleteList(oliListToDelete);
               system.debug('THIS IS THE NUMBER OF QUERIES SO FAR >>>' + Limits.getQueries());
                statusMessage = 'success';
            }  catch (Exception e) {
                if (statusMessage != null && statusMessage == 'success'){
                   statusMessage = 'error: '; 
                }
                statusMessage += e.getMessage();
            } 
        }
        
        if (isOppUpdated) {
            try {
                system.debug('THIS IS THE OPP LIST TO UPDATE FROM OLI SERVICES >>> ' + currentOpp);
                update currentOpp;
                system.debug('THIS IS THE NUMBER OF QUERIES SO FAR >>>' + Limits.getQueries());
            }  catch (Exception e) {
                if (statusMessage != null && statusMessage == 'success'){
                   statusMessage = 'error: '; 
                }
                statusMessage += e.getMessage();
            }     
            
        }
        
        system.debug('createOpportunityLineItems status message returned:' + statusMessage);
        return statusMessage;
    }
    
    // This method is used on the lightning version of the Add Product page.
    // It checks whether the current user has acccess to see the Price__c field.
    @AuraEnabled(cacheable=true)
    public static String checkPriceFieldAccess() {
        String fieldAccess;
        
        if (Schema.sObjectType.ProductItem__c.fields.Price__c.isAccessible()) {
            fieldAccess = 'view';
        } else {
            fieldAccess = 'none';
        }
        
        return fieldAccess;
        
    }
    
    // This method is used on the lightning version of the Add Product page.
    // It returns the record type name and stage of the Opportunity selected by the user.
    // This is used to determine which fields to display on the page.
    @AuraEnabled(cacheable=true)
    public static Object getOpportunityInfo(String opportunityId) {
        system.debug('#### getOpportunityInfo method.  Id: ' + opportunityId);
       Opportunity opp; 
        Map<String, String> opportunityMap = new Map<String, String>();
        if (opportunityId != null) {
          opp = [SELECT Id, RecordType.DeveloperName, StageName,Deal_Type__c FROM Opportunity WHERE Id =:opportunityId];
        }    
        
        opportunityMap.put('recordTypeName', opp.RecordType.DeveloperName);
        opportunityMap.put('stageName', opp.StageName);
        opportunityMap.put('dealType', opp.Deal_Type__c);
        
        return opportunityMap;
    }    

    
    // This method is used on the lightning version of the Add Product page.
    // It creates price book entries as part of the line item creation process
    // and is called from the createOpportunityLineItems method.
    @AuraEnabled(cacheable=true)
    public static String getOpportunityRecordTypeName(String opportunityId) {
       String recordTypeName = ''; 
        if (opportunityId != null) {
          Opportunity opp = [SELECT Id, RecordType.DeveloperName FROM Opportunity WHERE Id =:opportunityId];
            recordTypeName = opp.RecordType.DeveloperName;
        }    
        
        return recordTypeName;
    }  

    private static Map<String, Id> createPriceBookEntries(List<ProductItem__c> productItems, Set<String> setProductNames, Id priceBookId, String oppCurrency) {
        Map<String, Id> mapProductNameToPriceBookEntryId = new Map <String, Id>();
        List<PriceBookEntry> listPriceBookEntries = new List <PriceBookEntry>();
        List<PricebookEntry> existingPriceBookEntries = new List<PricebookEntry>();

        for (PriceBookEntry pbe : [SELECT Id, Product2.Name, CurrencyIsoCode, IsActive FROM PricebookEntry WHERE Product2.Name IN:setProductNames and Pricebook2Id = :priceBookId and CurrencyIsoCode =: oppCurrency and IsActive = true]) {
            mapProductNameToPriceBookEntryId.put(pbe.Product2.Name, pbe.Id);
        }
        
        for (ProductItem__c p: productItems) { 
            if (!mapProductNameToPriceBookEntryId.containsKey(p.Product_Name__r.Name)) {
                PriceBookEntry pbe = new PricebookEntry (Pricebook2Id = priceBookId, Product2Id = p.Product_Name__c, IsActive = true, UnitPrice = p.price__c, CurrencyIsoCode = oppCurrency);
                system.debug('#### price book entry to create: ' + pbe);
                listPriceBookEntries.add(pbe);
            }
        }
        
        if (!listPriceBookEntries.isEmpty()) {
            DatabaseService.insertList(listPriceBookEntries);
        }
        
        for (PriceBookEntry pbe : listPriceBookEntries) {
            mapProductNameToPriceBookEntryId.put(pbe.Product2.Name, pbe.Id);
        }
        
       return mapProductNameToPriceBookEntryId;
    }
    
    // This method is used on the lightning version of the Add Product page.
    // It generates a line item record as part of the line item creation process
    // and is called from the createOpportunityLineItems method.
    private static OpportunityLineItem generateOpportunityLineItem(ProductItem__c p, Opportunity o, Id pbeId, Map<String, Object>  mapProductItemValues) {
       Double price = p.Price__c;
       Double offer = 0.0;
       Double quote = 0.0;
       Boolean exchange = false;
       Id salesProduct;
       Id purchasingProduct;
        
       if (purchasingOppRecordList.contains(o.RecordTypeId) && mapProductItemValues != null) {
           price = (Double)mapProductItemValues.get('price');
           offer = (Double)mapProductItemValues.get('offer');
           quote = (Double)mapProductItemValues.get('quote');
           
           if (mapProductItemValues.get('exchange') != null) {
               exchange = Boolean.valueOf(mapProductItemValues.get('exchange'));
           }
           
           purchasingProduct = p.Product_Name__c;
       } else if(mapProductItemValues != null) {
           price = (Double)mapProductItemValues.get('price');
           
           if (mapProductItemValues.get('exchange') != null) {
               exchange = Boolean.valueOf(mapProductItemValues.get('exchange'));
           }
           
           if(salesOppRecordList.contains(o.RecordTypeId) && p.Check_In_Type__c != 'Customer Repair' && o.StageName == 'Closed Won') {
               salesProduct = p.Product_Name__c;
           }    
       } 
       
      OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = o.Id, PricebookEntryId = pbeId, 
                                Serial_No__c = p.Serial_No__c, Model__c = p.Model__c , Part_Number__c = p.Part_Number__c,
                                TotalPrice = price, Compatible_System__c = p.Compatible_System__c, Functional_Rating__c = p.Functional_Rating__c,
                                Functional_Rating_Notes__c = p.Functional_Notes__c, ProductItem__c = p.Id,
                                Exchange__c = exchange, Asset_No__c = p.Name, Purchasing_Approved__c = p.Purchasing_Approved__c,
                                Probo_s_Offer__c = offer, Supplier_s_Quote__c = quote, Quantity = 1, Sales_Product__c = salesProduct,
                                Product__c = purchasingProduct);
        
       return oli; 
        
    }
    
    private static OpportunityLineItem updateOpportunityLineItem(OpportunityLineItem originalOli, OpportunityLineItem newOli) {
        
       if (originalOli != null && newOli != null && originalOli.Check_In_Type__c == 'Generic' && originalOli.UnitPrice != null) {
            newOli.TotalPrice = originalOli.UnitPrice;
       } 

       return newOli;
    } 
    
    // This method is used on the lightning version of the Add Product page.
    // It updates a product item as part of the line item creation process
    // and is called from the createOpportunityLineItems method.
    private static ProductItem__c updateProductItem(ProductItem__c p, Opportunity o, Map<String, Object>  mapProductItemValues) {
       ProductItem__c updatedProductItem = new ProductItem__c();
       Double cost = 0.0;
        
        if (p.Id != null) {
            updatedProductItem = p.clone(true, true, false, true);
            
            if (p.Generic_Product__c == false) {
                updatedProductItem.Added_To_Opportunity__c = true;
                
                if (o.StageName == 'Closed Won' && o.Ship_Date__c != null) {
                    updatedProductItem.Sold__c = true;
                }
               
                if (o.StageName == 'Verbal Acceptance' || o.StageName == 'PO Received' || o.StageName == 'Sold but not shipped' || o.StageName == 'External Repair/Testing' || 
                    o.StageName == 'Equipment Rental' || o.StageName == 'Probe Loan' || o.StageName == 'Sourcing' || o.StageName == 'Finalize Transaction' || 
                    (o.StageName == 'Closed Won' && o.Ship_Date__c == null)) {
                      updatedProductItem.Reserved__c = true;
                }
               
            }     
        
          if (mapProductItemValues != null && mapProductItemValues.containsKey('cost')) {
                cost = (Double)mapProductItemValues.get('cost');
                
                if (cost != null && cost != p.Cost__c) {
                    updatedProductItem.Cost__c = cost;
                }
            }
        }       
        
        return updatedProductItem;
    }
    
    @AuraEnabled
    public static String deleteOpportunityLineItem(String productItemId, String opportunityId) {
    String statusMessage;
        List<OpportunityLineItem> oliListToDelete = new List<OpportunityLineItem>();
        
        if (productItemId != null && opportunityId != null) {
          OpportunityLineItem oli = [SELECT Id, Product_Name__c, ProductItem__c, Check_In_Type__c, OpportunityId, Asset_No__c, Exchange__c 
                                       FROM OpportunityLineItem WHERE OpportunityId =: opportunityId AND ProductItem__c =: productItemId LIMIT 1];
            
            try { 
                oliListToDelete.add(oli);
              DatabaseService.deleteList(oliListToDelete);
                statusMessage = 'success';
            }  catch (Exception e) {
                statusMessage += 'error: ' + e.getMessage().unescapeHtml4();
            } 
        }
        
        return statusMessage;
    }   
    
    // This method is used on the lightning version of the Add Product page.
    // It checks whether the current user has acccess to see the Cost__c field.
    @AuraEnabled(cacheable=true)
    public static String checkCostFieldAccess() {
        String fieldAccess;
        Boolean costFieldPermissionSetAccess = UserHasAccess.hasPermissionSetAccess('AP_Page_Cost');
        
        if (costFieldPermissionSetAccess == true) {
            fieldAccess = 'view';
        } else {
            fieldAccess = 'none';
        }
        
        return fieldAccess;
        
    }
    
    
}