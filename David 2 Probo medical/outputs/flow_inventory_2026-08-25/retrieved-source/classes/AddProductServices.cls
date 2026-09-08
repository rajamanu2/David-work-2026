public class AddProductServices {
    public static final Integer maxRows = 200;
    //public static Id salesRecordTypeId = RecordTypeUtility.getRecordTypeByName('Opportunity', 'Sales Opportunity');
    //public static Id purchasingRecordTypeId = RecordTypeUtility.getRecordTypeByName('Opportunity', 'Purchasing Opportunity');
    //public static Id repairRecordTypeId = RecordTypeUtility.getRecordTypeByName('Opportunity', 'External Repair / Testing');

    // This method is used on the lightning version of the Add Product page.
    // It returns Assets and related Product information based on the user's search.
    @AuraEnabled
    public static List<Object> getProducts(Map<String, Object> queryParams) {
      List<ProductItem__c> listProductItems = new List<ProductItem__c>();   
      List<List<SObject>> searchList = new List<List<SObject>>();
      system.debug('#### queryParams: ' + queryParams);
       
      String strWhereClause;
      Boolean isPartsOnlySearch = false;
      Boolean isCompatiblePartsSearch = true;
      Boolean isExactSearch = false;
      Boolean isProbeOpp = false;
        
      for (String p: queryParams.keySet()) {
          switch on p {
              when 'partsOnly' {		
                  Object selectedPartsOnlyOption = (Object)queryParams.get('partsOnly'); 
                  system.debug('#### selected parts only option: ' + queryParams.get('partsOnly'));
                  
                  if (selectedPartsOnlyOption != null) {
                  		isPartsOnlySearch = Boolean.valueOf(selectedPartsOnlyOption);
                      if (isPartsOnlySearch == true) {
                           strWhereClause = ' WHERE Product_Name__r.Family like \'%' + 'Part' + '%\'';
                      } 
                  }    
              }
              when 'exactSearch' {		
                Object selectedExactSearchOption = (Object)queryParams.get('exactSearch'); 
                system.debug('#### selected exact search option: ' + queryParams.get('exactSearch'));
                
                if (selectedExactSearchOption != null) {
                        isExactSearch = Boolean.valueOf(selectedExactSearchOption);
                }    
              }
            
              when 'compatibleParts' {		
                Object selectedCompatiblePartsOption = (Object)queryParams.get('compatibleParts'); 
                system.debug('#### selected compatible parts option: ' + queryParams.get('compatibleParts'));
                
                if (selectedCompatiblePartsOption != null) {
                        isCompatiblePartsSearch = Boolean.valueOf(selectedCompatiblePartsOption);
                
                }    
            }
              when 'oppRecordType' {
                Object oppRTName = (Object)queryParams.get('oppRecordType');
                system.debug('#### opp record type name: ' + queryParams.get('oppRecordType'));
                
                if (oppRTName != null && oppRTName == 'Probe_Sales_Opportunity') {
                        isProbeOpp = true;
                        system.debug('#### probe opp set to TRUE');
                } 
              }
              when 'queryString' {
                  // Add search string to match Product Names
                  system.debug('#### search string: ' + (String)queryParams.get('queryString'));
                  
                  String searchStringValue = (String)queryParams.get('queryString');
                  Product2 searchProduct;
                  try{
                    searchProduct = [select id, Part_Number__c, Product_Status__c, Compatible_Part_Numbers__c FROM Product2 WHERE Part_Number__c = :searchStringValue AND Compatible_Part_Numbers__c != null AND Product_Status__c = 'Validated' LIMIT 1];
                } catch(Exception e){
                    system.debug('Unable to find a Product for this part number: ' + searchStringValue);
                }
                system.debug('THIS IS THE SEARCH PRODUCT >>> ' + searchProduct);
                  if (isPartsOnlySearch == false) {
                     if(isExactSearch == false){
                      strWhereClause = ' WHERE (Product_Name__r.Name like \'%' + searchStringValue + '%\' OR ';
                      strWhereClause += ' Name like \'%' + searchStringValue + '%\' OR Serial_No__c like \'%' + searchStringValue + '%\' OR';
                      strWhereClause += ' Part_Number__c like \'%' + searchStringValue + '%\' OR Compatible_System__c like \'%' + searchStringValue + '%\')';
                      strWhereClause += ' AND Sold__c = False AND Product_Name__r.IsActive = True';
                     }
                      if(isExactSearch == true){
                        strWhereClause = ' WHERE (Product_Name__r.Name like \'%' + ' ' +searchStringValue + '\' OR ';
                        strWhereClause += ' Product_Name__r.Name like \'%' +searchStringValue + '\' OR Name like \'%' + ' ' + searchStringValue + '\' OR '; 
                        strWhereClause += ' Name like \'%' + searchStringValue + '\' OR Serial_No__c like \'%' + searchStringValue + '\' OR';
                        strWhereClause += ' Part_Number__c like \'%' + searchStringValue + '\' OR Compatible_System__c like \'%' + searchStringValue + '\')';
                        strWhereClause += ' AND Sold__c = False AND Product_Name__r.IsActive = True';
                      }
                      system.debug('THIS IS THE ACTUAL PROBE OPP VALUE >>> ' + isProbeOpp);
                      if(isProbeOpp == true){
                        system.debug('Probe Opp = true');
                        strWhereClause += ' AND (Product_Name__r.Family = \'Ultrasound Probe\' OR Product_Name__r.RecordType.DeveloperName = \'Non_Inventory_Item\')';
                      }
                      system.debug('THIS IS THE QUERY STRING >>> ' + strWhereClause);
                  } else {
                      strWhereClause += ' AND (Product_Name__r.Name like \'%' + searchStringValue + '%\' OR ';
                      strWhereClause += ' Name like \'%' + searchStringValue + '%\' OR Serial_No__c like \'%' + searchStringValue + '%\' OR ';
                      if(isCompatiblePartsSearch && searchProduct != null){
                          if(searchProduct.Compatible_Part_Numbers__c != null){
                                list<String> compatiblePartsList = searchProduct.Compatible_Part_Numbers__c.split(';');
                                if(compatiblePartsList.size() != 0){
                                    for(string comp:compatiblePartsList){
                                        strWhereClause += 'Part_Number__c like \'%' + comp.trim() + '%\' OR ';
                                    }
                                }
                                /*strWhereClause += 'Product_Name__r.Compatible_Part_Numbers__c like \'%' + searchStringValue + '%\' OR';*/
                                system.debug('THIS IS LOOKING FOR COMPATIBLE PARTS >>> ' + strWhereClause);
                           }
                      }
                      strWhereClause += ' Part_Number__c like \'%' + searchStringValue + '%\' OR Compatible_System__c like \'%' + searchStringValue + '%\')';
                      strWhereClause += ' AND Sold__c = False AND Product_Name__r.IsActive = True';
                  }
              }	
              when 'family' {	
                  List<Object> selectedFamilies = (List<Object>)queryParams.get('family'); 
                  system.debug('#### selected families: ' + queryParams.get('family'));
                  List<String> selectedFamiliesToQuery = new List<String>();
                  
                  if (selectedFamilies != null && isPartsOnlySearch == false) {
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
              when 'availableOnly' {		
                Object selectedAvailableOption = (Object)queryParams.get('availableOnly'); 
                system.debug('#### selected available only option: ' + queryParams.get('availableOnly'));
                
                if (selectedAvailableOption != null && Boolean.valueOf(selectedAvailableOption) == true) {
                    system.debug('selected available only ACTUALLY true');
                    strWhereClause += ' AND Available_To_Sell__c = true AND (Review_Status__c = \'Finished Goods\' OR Review_Status__c = \'Cosmetic Repair Queue\')';
                   
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
              when 'compatibleSystemOEM' {		
                  Object selectedCompatibleSystemOEM = (Object)queryParams.get('compatibleSystemOEM');
                  system.debug('#### compatible system OEM: ' + queryParams.get('compatibleSystemOEM'));
                  
                  if (selectedCompatibleSystemOEM != null) {
                      String compatibleOEM = String.valueOf(selectedCompatibleSystemOEM);
                      if (compatibleOEM != '') {
                          strWhereClause += ' AND Product_Name__r.Compatible_System_OEM__c = \'' + compatibleOEM + '\'';
                      }
                  }
              }
              when 'compatibleSystemFamily' {		
                  Object selectedCompatibleSystemFamily = (Object)queryParams.get('compatibleSystemFamily');
                  system.debug('#### compatible system Family: ' + queryParams.get('compatibleSystemFamily'));
                  
                  if (selectedCompatibleSystemFamily != null) {
                      String family = String.valueOf(selectedCompatibleSystemFamily);
                      if (family != '') {
                          strWhereClause += ' AND Product_Name__r.Compatible_System_Family__c = \'' + family + '\'';
                      }
                  }
              }
              when 'compatibleSystemModel' {		
                  Object selectedCompatibleSystemModel = (Object)queryParams.get('compatibleSystemModel');
                  system.debug('#### compatible system Model: ' + queryParams.get('compatibleSystemModel'));
                  
                  if (selectedCompatibleSystemModel != null) {
                      String model = String.valueOf(selectedCompatibleSystemModel);
                      if (model != '') {
                          strWhereClause += ' AND Product_Name__r.Compatible_System_Model__c = \'' + model + '\'';
                      }
                  }
              }
              when 'compatibleSystemSoftwareVersion' {		
                  Object selectedCompatibleSystemSoftwareVersion = (Object)queryParams.get('compatibleSystemSoftwareVersion');
                  system.debug('#### compatible system Software Version: ' + queryParams.get('compatibleSystemSoftwareVersion'));
                  
                  if (selectedCompatibleSystemSoftwareVersion != null) {
                      String version = String.valueOf(selectedCompatibleSystemSoftwareVersion);
                      if (version != '') {
                          strWhereClause += ' AND Product_Name__r.Compatible_System_Software_Version__c = \'' + version + '\'';
                      }
                  }
              }
              when 'compatibleSystemRevisionLevel' {		
                  Object selectedCompatibleSystemRevisionLevel = (Object)queryParams.get('compatibleSystemRevisionLevel');
                  system.debug('#### compatible system Revision Level: ' + queryParams.get('compatibleSystemRevisionLevel'));
                  
                  if (selectedCompatibleSystemRevisionLevel != null) {
                      String revision = String.valueOf(selectedCompatibleSystemRevisionLevel);
                      if (revision != '') {
                          strWhereClause += ' AND Product_Name__r.Compatible_System_BT_Revision_Level__c = \'' + revision + '\'';
                      }
                  }
              }
              when 'oem' {		
                  Object selectedOEM = (Object)queryParams.get('oem');
                  system.debug('#### OEM: ' + queryParams.get('oem'));
                  
                  if (selectedOEM != null) {
                      String oem = String.valueOf(selectedOEM);
                      if (oem != '') {
                          strWhereClause += ' AND Product_Name__r.OEM__c = \'' + oem + '\'';
                      }
                  }
              }

              when 'partType' {		
                  Object selectedPartType = (Object)queryParams.get('partType');
                  system.debug('#### part type: ' + queryParams.get('partType'));
                  
                  if (selectedPartType != null) {
                      String partType = String.valueOf(selectedPartType);
                      if (partType != '') {
                          strWhereClause += ' AND Product_Name__r.Part_Type__c = \'' + partType + '\'';
                      }
                  }
              }
              when 'modality' {		
                  Object selectedModality = (Object)queryParams.get('modality');
                  system.debug('#### modality: ' + queryParams.get('modality'));
                  
                  if (selectedModality != null) {
                      String modality = String.valueOf(selectedModality);
                      if (modality != '') {
                          strWhereClause += ' AND Product_Name__r.Modality__c = \'' + modality + '\'';
                      }
                  }
              }
              
          }  
      } 
        
      System.debug('#### getProducts method where clause: ' + strWhereClause); 
      String query = getProductQuery();  
      query += strWhereClause;
      query += ' ORDER BY Name ASC LIMIT ' + maxRows;
      System.debug('#### getProducts method query: ' + query); 
        
      for(ProductItem__c p: Database.query(query)) {
        listProductItems.add(p); 
        system.debug('THIS IS THE ASSET >> ' + p.Name + ' AND THIS IS THE SUB LOCATION >>> '  + p.Sub_location__c + ' AND THIS IS THE DEALER >>> ' + p.Product_Name__r.Dealer__c + ' AND Available to Sell >>> ' + p.Available_To_Sell__c) ;
        
      }
        
        System.debug('#### getProducts listProductItems: ' + listProductItems);
        return listProductItems;
    }

    // This method is used on the lightning version of the Add Product page.
    // It is used to build the query for the getProducts method above.
    public static String getProductQuery() {
        String query = 'SELECT Id,Name,Product_Name__c,Product_Name__r.name, Product_Name__r.IsActive, Createddate,Model__c,Part_Number__c,Serial_No__c,Compatible_System__c,Functional_Rating__c,';
               query += ' Functional_Notes__c,Price__c,Cosmetic_Rating__c,Cosmetic_Notes__c,Location__c, Product_Name__r.Compatible_Part_Numbers__c, Available_To_Sell__c, Product_Name__r.Dealer_Pr_Out__c, Product_Name__r.Dealer_Pr_Ex__c,';
               query += ' Std_Cost_ex__c,Std_Cost_Out__c, Sug_Pr_Ex__c,Sug_Pr_Out__c,Cost__c, Sub_Location__c, Product_Name__r.Dealer__c, Product_Name__r.Outright_Only_Part__c, Designated_For__c,';
               query += ' Sug_Price_with_System__c, PO_Number__c,Other_Notes__c,Generic_Product__c,Image__c,Frequency_High__c,Frequency_Low__c, Ownership__c, Product_Name__r.Retail_Pr_Out__c, Product_Name__r.Retail_Pr_Ex__c,';
               query += ' Date_of_Manufacture__c,Product_Description__c,System_Software__c,Receive_date__c,Check_In_Type__c,Purchasing_Approved__c, Product_Name__r.Family, Product_Name__r.RecordType.DeveloperName,';
               query += ' Repair_Activity__c,Repair_Priority_Rating__c,First_Call_Capability__c,System_Test_Bed__c,Repair_Summary__c,Review_Status__c, Review_Status_Notes__c,';
               query += ' Special_Offer_Pricing__c,Product_Name__r.Total_no_of_Requests__c,Product_Name__r.Total_Qty_in_stock__c, Domestic_Only__c, Product_Name__r.NEW_Exchange_Price__c, Product_Name__r.REFURB_Exchange_Price__c,';
               query += ' Product_Name__r.Functionally_Good_Probes_Total__c, Product_Name__r.Total_Qty_of_New_Probes__c, Product_Name__r.End_User__c,Product_Name__r.Tier_1_REFURB_Ex__c, Product_Name__r.Tier_2_REFURB_Ex__c,';
               query += ' Product_Name__r.Functionally_Good_Probes__c,D_System_Test__c, Product_Name__r.Total_Qty_on_Purchasing_Verbal__c, Vendor__c,Vendor_Name__c, Product_Name__r.Tier_3_REFURB_Ex__c,';
               query += ' Product_Name__r.New_Std_Cost_Out__c, Product_Name__r.New_Std_Cost_Ex__c, Product_Name__r.New_Sug_Pr_Out__c, Product_Name__r.New_Sug_Pr_Ex__c,';
               query += ' Product_Name__r.Proposed_STD_Wholesale_Price__c, Product_Name__r.Proposed_STD_w_Refurb_30_day__c, Product_Name__r.Proposed_STD_Retail__c,';
               query += ' Product_Name__r.Qty_Ready_to_Ship__c,Product_Name__r.Target_Quantity_in_Stock__c,Product_Name__r.Untested_Probes__c,Reserved__c, Posted_on_Ebay__c,';
               query += ' Avg_Sale_Price__c, Repair_Notes_Summary__c, Product_Name__r.Probe_Type__c, (select Probo_s_Offer__c,Supplier_s_Quote__c,Quantity from Opportunity_Product__r)';
               query += ' FROM ProductItem__c';
        
        return query;
    }
    
    // This method is used on the lightning version of the Add Product page.
    // It returns the record type name and stage of the Opportunity selected by the user.
    // This is used to determine which fields to display on the page.

    @AuraEnabled
    public static Object getUserInfo(String userId) {
        system.debug('#### getUserInfo method.  Id: ' + userId);
     	User userInfo; 
        Map<String, String> userMap = new Map<String, String>();
        if (userId != null) {
        	userInfo = [SELECT Id, Location__c, Profile.Name, Entity__c FROM User WHERE Id =:userId];
        }    
        
        userMap.put('profileName', userInfo.Profile.Name);
        userMap.put('location', userInfo.Location__c);
        userMap.put('entityName', userInfo.Entity__c);
        
        system.debug('THIS IS THE USER FROM ADD PRODUCT SERVICES >>> ' + userMap);
        
        return userMap;
    } 




    @AuraEnabled
    public static Object getOpportunityInfo(String oppId) {
        system.debug('#### getOpportunityInfo method.  Id: ' + oppId);
     	Opportunity opp; 
        Map<String, String> opportunityMap = new Map<String, String>();
        if (oppId != null) {
        	opp = [SELECT Id, RecordType.DeveloperName, StageName,Deal_Type__c, Account.Sales_Purchasing_CSR_Account__c, Account.Type, Entity__c FROM Opportunity WHERE Id =:oppId];
        }    
        
        opportunityMap.put('recordTypeName', opp.RecordType.DeveloperName);
        opportunityMap.put('stageName', opp.StageName);
        opportunityMap.put('dealType', opp.Deal_Type__c);
        opportunityMap.put('accountType', opp.Account.Type);
        opportunityMap.put('accountTier', opp.Account.Sales_Purchasing_CSR_Account__c);
        opportunityMap.put('opportunityEntityName', opp.Entity__c);
        system.debug('THIS IS THE OPP FROM ADD PRODUCT SERVICES >>> ' + opportunityMap);
        
        return opportunityMap;
    }   
    
    @AuraEnabled
    public static Object getWorkOrderInfo(String workOrderId) {
        system.debug('#### getWorkOrderInfo method.  Id: ' + workOrderId);
        Map<String, String> workOrderMap = new Map<String, String>();
        Map<String, String> opportunityMap = new Map<String, String>();
        WorkOrder wo;
        Id oppId;
        if (workOrderId != null) {
             for(sObject s : [SELECT Id, WorkOrderNumber, ServiceContractId, ServiceContract.Opportunity__c, Opportunity__c FROM WorkOrder WHERE Id =: workOrderId]) {
                 system.debug('THIS IS THE WO OPP >> ' + String.valueOf(s.get('Opportunity__c')));
                 
                 if (s.get('ServiceContractId') != null) {
                     system.debug('#### service contract Id: ' + String.valueOf(s.get('ServiceContractId')));
                     workOrderMap.put('serviceContractId', String.valueOf(s.get('ServiceContractId')));
                 }
                 if (s.getSobject('ServiceContract') != null && s.getSobject('ServiceContract').get('Opportunity__c') != null) {
                     oppId = String.valueOf(s.getSobject('ServiceContract').get('Opportunity__c'));
                     system.debug('#### opp Id: ' + oppId);
                     workOrderMap.put('oppId', oppId); 
                 }
                 else if(s.get('Opportunity__c') != null){
                 	oppId = String.valueOf(s.get('Opportunity__c'));
                    workOrderMap.put('oppId', oppId);
             	 }
             }
             
             if (oppId != null) {
                 system.debug('#### getting Opportunity info');
                 opportunityMap = (Map<String, String>)getOpportunityInfo(oppId);
                 if (!opportunityMap.isEmpty()) {
                     system.debug('#### opp record type name: ' + opportunityMap.get('recordTypeName'));
                     workOrderMap.put('opportunityRecordTypeName' , opportunityMap.get('recordTypeName')); 
                     workOrderMap.put('opportunityStageName' , opportunityMap.get('stageName'));
                     workOrderMap.put('opportunityDealType' , opportunityMap.get('dealType'));
                     workOrderMap.put('opportunityAccountType', opportunityMap.get('accountType'));
        			 workOrderMap.put('opportunityAccountTier', opportunityMap.get('accountTier'));
        			 workOrderMap.put('opportunityEntityName', opportunityMap.get('opportunityEntityName'));
                 }
             }
             
         } 
         
        system.debug('#### workOrderMap returned: ' + workOrderMap);
        return workOrderMap;
    }  
    
    @AuraEnabled
    public static Object getLoanerInfo(String loanerId) {
        system.debug('#### getLoanerInfo method.  Id: ' + loanerId);
        Map<String, String> loanerMap = new Map<String, String>();
        Map<String, String> opportunityMap = new Map<String, String>();
        Loaner__c lo;
        Id oppId;
        
         if (loanerId != null) {
             lo = [SELECT Id, Name, Repair_Opportunity__c FROM Loaner__c WHERE Id =: loanerId];
             system.debug('#### loaner record: ' + lo);
             loanerMap.put('name', lo.Name);
             
             
             if (lo.Repair_Opportunity__c != null) {
                 system.debug('#### repair opportunity Id: ' + lo.Repair_Opportunity__c);
                 oppId = lo.Repair_Opportunity__c;
             }
             
             if (oppId != null) {
                 system.debug('#### getting Opportunity info');
                 loanerMap.put('oppId', oppId);
                 opportunityMap = (Map<String, String>)getOpportunityInfo(oppId);
                 if (!opportunityMap.isEmpty()) {
                     system.debug('#### opp record type name: ' + opportunityMap.get('recordTypeName'));
                     loanerMap.put('opportunityRecordTypeName' , opportunityMap.get('recordTypeName')); 
                     loanerMap.put('opportunityStageName' , opportunityMap.get('stageName'));
                     loanerMap.put('opportunityDealType' , opportunityMap.get('dealType'));
                     loanerMap.put('opportunityAccountType', opportunityMap.get('accountType'));
        			 loanerMap.put('opportunityAccountTier', opportunityMap.get('accountTier'));
                     loanerMap.put('opportunityEntityName' , opportunityMap.get('opportunityEntityName'));
                 }
             }
             
         }     
        
        system.debug('#### loanerMap returned: ' + loanerMap);
        return loanerMap;
    } 
    
    @AuraEnabled
    public static Object getRentalOrderInfo(String rentalOrderId) {
        system.debug('#### getRentalOrderInfo method.  Id: ' + rentalOrderId);
        Map<String, String> rentalOrderMap = new Map<String, String>();
        Map<String, String> opportunityMap = new Map<String, String>();
        Rental_Order__c ro;
        Id oppId;
        
         if (rentalOrderId != null) {
             ro = [SELECT Id, Name, Opportunity__c FROM Rental_Order__c WHERE Id =:rentalOrderId];
             system.debug('#### rental record: ' + ro);
             rentalOrderMap.put('name', ro.Name);
             
             if (ro.Opportunity__c != null) {
                 system.debug('#### opportunity Id: ' + ro.Opportunity__c);
                 oppId = ro.Opportunity__c;
             }
             
             if (oppId != null) {
                 system.debug('#### getting Opportunity info');
                 rentalOrderMap.put('oppId', oppId);
                 opportunityMap = (Map<String, String>)getOpportunityInfo(oppId);
                 if (!opportunityMap.isEmpty()) {
                     system.debug('#### opp record type name: ' + opportunityMap.get('recordTypeName'));
                     rentalOrderMap.put('opportunityRecordTypeName' , opportunityMap.get('recordTypeName')); 
                     rentalOrderMap.put('opportunityStageName' , opportunityMap.get('stageName'));
                     rentalOrderMap.put('opportunityDealType' , opportunityMap.get('dealType'));
                     rentalOrderMap.put('opportunityAccountType', opportunityMap.get('accountType'));
        			 rentalOrderMap.put('opportunityAccountTier', opportunityMap.get('accountTier'));
                     rentalOrderMap.put('opportunityEntityName' , opportunityMap.get('opportunityEntityName'));
                 }
             }
             
         }     
        
        system.debug('#### rentalOrderMap returned: ' + rentalOrderMap);
        return rentalOrderMap;
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
    
    public static Map<String, Id> createPriceBookEntries(List<ProductItem__c> productItems, Set<String> setProductNames, Id priceBookId, String oppCurrency) {
        Map<String, Id> mapProductNameToPriceBookEntryId = new Map <String, Id>();
        List<PriceBookEntry> listPriceBookEntries = new List <PriceBookEntry>();
        List<PricebookEntry> existingPriceBookEntries = new List<PricebookEntry>();

        for (PriceBookEntry pbe : [SELECT Id, Product2.Name, CurrencyIsoCode, IsActive  FROM PricebookEntry WHERE Product2.Name IN:setProductNames and Pricebook2Id = :priceBookId and CurrencyIsoCode =:oppCurrency and IsActive = true]) {
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

    // new for Creating Service Contract Assets from Opportunity Products
    @AuraEnabled
    public static Object getPickListOptions(){
        List<String> pickListValuesList= new List<String>();
        Map<String, List<String>> pickListOptionMap = new Map<String, List<String>>();
        
        Schema.DescribeFieldResult fieldResult = ProductItem__c.Warranty_Term__c.getDescribe();
        pickListValuesList = retrievePickListValues(fieldResult, false); 
        pickListOptionMap.put('Warranty_Term__c', pickListValuesList);
        GH_Logger.debug('calling getPickListOptions. return value: ' + pickListOptionMap);
        return pickListOptionMap;
    } 
    
    @TestVisible
    private static List<String> retrievePickListValues(Schema.DescribeFieldResult fieldResult, Boolean includeNoneOption) {
        List<String> pickListValuesList= new List<String>();
        
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        if (includeNoneOption) {
        	pickListValuesList.add('--None--');
        }  
        
        for(Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }  
        
        return pickListValuesList;
    }

      public class OrderInfoDTO {
        @AuraEnabled public Id orderId;
        @AuraEnabled public Id pricebook2Id;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String status;
        @AuraEnabled public String accountType;
        @AuraEnabled public String accountTier;
    }

    @AuraEnabled(cacheable=true)
    public static OrderInfoDTO getOrderInfo(Id orderId) {
        Order o = [
            SELECT Id, Pricebook2Id, AccountId, Status,
                   Account.Type, Account.Sales_Purchasing_CSR_Account__c
            FROM Order
            WHERE Id = :orderId
            LIMIT 1
        ];
        OrderInfoDTO dto = new OrderInfoDTO();
        dto.orderId = o.Id;
        dto.pricebook2Id = o.Pricebook2Id;
        dto.accountId = o.AccountId;
        dto.status = o.Status;
        dto.accountType = (o.Account != null ? o.Account.Type : null);
        dto.accountTier = (o.Account != null ? (String)o.Account.get('Tier__c') : null);
        return dto;
    }

}