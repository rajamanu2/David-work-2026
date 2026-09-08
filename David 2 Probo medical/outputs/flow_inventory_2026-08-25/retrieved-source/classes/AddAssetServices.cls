public class AddAssetServices {
    public static final Integer maxRows = 200;
    public static id partRT;
    public static User userInfo; 
    
    @AuraEnabled
    public static List<Object> getProducts(Map<String, Object> queryParams) {
      List<ProductItem__c> listProductItems = new List<ProductItem__c>(); 
      List<Product2> listProducts = new List<Product2>(); 
      List<List<SObject>> searchList = new List<List<SObject>>();
      system.debug('#### queryParams: ' + queryParams);
       
      String strWhereClause;
      Boolean isPartsOnlySearch = false;
        
      for (String p: queryParams.keySet()) {
          switch on p {
              when 'partsOnly' {    
                  Object selectedPartsOnlyOption = (Object)queryParams.get('partsOnly'); 
                  system.debug('#### selected parts only option: ' + queryParams.get('partsOnly'));
                  
                  if (selectedPartsOnlyOption != null) {
                      isPartsOnlySearch = Boolean.valueOf(selectedPartsOnlyOption);
                      if (isPartsOnlySearch == true) {
                           strWhereClause = ' WHERE Family like \'%' + 'Part' + '%\'';
                      } 
                  }    
              }
              when 'queryString' {
                  // Add search string to match Product Names
                  system.debug('#### search string: ' + (String)queryParams.get('queryString'));
                  String searchStringValue = (String)queryParams.get('queryString');
                  if (isPartsOnlySearch == false) {
                      strWhereClause = ' WHERE (Name like \'%' + searchStringValue + '%\' OR ';
                      strWhereClause += ' Part_Number__c like \'%' + searchStringValue + '%\') AND IsActive = True';
                  } else {
                      strWhereClause += ' AND (Name like \'%' + searchStringValue + '%\' OR ';
                      strWhereClause += ' Part_Number__c like \'%' + searchStringValue + '%\') AND IsActive = True';
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
                          strWhereClause += ' AND Family IN(' ;
                          
                          for (String s: selectedFamiliesToQuery) {
                             strWhereClause += '\'' + s + '\',';
                          }
                          
                          strWhereClause = strWhereClause.removeEnd(',') + ')';
                      }  
                  }
              }
              when 'compatibleSystemOEM' {    
                  Object selectedCompatibleSystemOEM = (Object)queryParams.get('compatibleSystemOEM');
                  system.debug('#### compatible system OEM: ' + queryParams.get('compatibleSystemOEM'));
                  
                  if (selectedCompatibleSystemOEM != null) {
                      String compatibleOEM = String.valueOf(selectedCompatibleSystemOEM);
                      if (compatibleOEM != '') {
                          strWhereClause += ' AND Compatible_System_OEM__c = \'' + compatibleOEM + '\'';
                      }
                  }
              }
              when 'compatibleSystemFamily' {    
                  Object selectedCompatibleSystemFamily = (Object)queryParams.get('compatibleSystemFamily');
                  system.debug('#### compatible system Family: ' + queryParams.get('compatibleSystemFamily'));
                  
                  if (selectedCompatibleSystemFamily != null) {
                      String family = String.valueOf(selectedCompatibleSystemFamily);
                      if (family != '') {
                          strWhereClause += ' AND Compatible_System_Family__c = \'' + family + '\'';
                      }
                  }
              }
              when 'compatibleSystemModel' {    
                  Object selectedCompatibleSystemModel = (Object)queryParams.get('compatibleSystemModel');
                  system.debug('#### compatible system Model: ' + queryParams.get('compatibleSystemModel'));
                  
                  if (selectedCompatibleSystemModel != null) {
                      String model = String.valueOf(selectedCompatibleSystemModel);
                      if (model != '') {
                          strWhereClause += ' AND Compatible_System_Model__c = \'' + model + '\'';
                      }
                  }
              }
              when 'compatibleSystemSoftwareVersion' {    
                  Object selectedCompatibleSystemSoftwareVersion = (Object)queryParams.get('compatibleSystemSoftwareVersion');
                  system.debug('#### compatible system Software Version: ' + queryParams.get('compatibleSystemSoftwareVersion'));
                  
                  if (selectedCompatibleSystemSoftwareVersion != null) {
                      String version = String.valueOf(selectedCompatibleSystemSoftwareVersion);
                      if (version != '') {
                          strWhereClause += ' AND Compatible_System_Software_Version__c = \'' + version + '\'';
                      }
                  }
              }
              when 'compatibleSystemRevisionLevel' {    
                  Object selectedCompatibleSystemRevisionLevel = (Object)queryParams.get('compatibleSystemRevisionLevel');
                  system.debug('#### compatible system Revision Level: ' + queryParams.get('compatibleSystemRevisionLevel'));
                  
                  if (selectedCompatibleSystemRevisionLevel != null) {
                      String revision = String.valueOf(selectedCompatibleSystemRevisionLevel);
                      if (revision != '') {
                          strWhereClause += ' AND Compatible_System_BT_Revision_Level__c = \'' + revision + '\'';
                      }
                  }
              }
              when 'oem' {    
                  Object selectedOEM = (Object)queryParams.get('oem');
                  system.debug('#### OEM: ' + queryParams.get('oem'));
                  
                  if (selectedOEM != null) {
                      String oem = String.valueOf(selectedOEM);
                      if (oem != '') {
                          strWhereClause += ' AND OEM__c = \'' + oem + '\'';
                      }
                  }
              }

              when 'partType' {    
                  Object selectedPartType = (Object)queryParams.get('partType');
                  system.debug('#### part type: ' + queryParams.get('partType'));
                  
                  if (selectedPartType != null) {
                      String partType = String.valueOf(selectedPartType);
                      if (partType != '') {
                          strWhereClause += ' AND Part_Type__c = \'' + partType + '\'';
                      }
                  }
              }
              when 'modality' {    
                  Object selectedModality = (Object)queryParams.get('modality');
                  system.debug('#### modality: ' + queryParams.get('modality'));
                  
                  if (selectedModality != null) {
                      String modality = String.valueOf(selectedModality);
                      if (modality != '') {
                          strWhereClause += ' AND Modality__c = \'' + modality + '\'';
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
        
      for(Product2 p: Database.query(query)) {
        listProducts.add(p); 
      }
        
        System.debug('#### getProducts listProducts: ' + listProducts);
        return listProducts;
    }

    public static String getProductQuery() {
        String query = 'SELECT Id,Name,Part_Number__c,IsActive,Product_Analytics__c';
               query += ' FROM Product2';
        
        return query;
    }

    @AuraEnabled
    public static Object getHarvestWorkOrderInfo(String harvestWorkOrderId) {
        system.debug('#### getHarvestWorkOrderInfo.  Id: ' + harvestWorkOrderId);
       Harvest_Work_Order__c hw; 
        Map<String, String> harvestWorkOrderMap = new Map<String, String>();
        if (harvestWorkOrderId != null) {
          hw = [SELECT Id, Name, Status__c, System_Work_Order__c, HWO_Location__c, System_Functional_Rating__c FROM Harvest_Work_Order__c WHERE Id =:harvestWorkOrderId];
        }    
        
        harvestWorkOrderMap.put('status', hw.Status__c);
        harvestWorkOrderMap.put('systemWorkOrder', hw.System_Work_Order__c);
        harvestWorkOrderMap.put('location', hw.HWO_Location__c);
        string funcRating = '';
        if(hw.System_Functional_Rating__c != null){
            funcRating = hw.System_Functional_Rating__c;
            if(funcRating != null && funcRating != 'Good'){
                funcRating = 'Needs Testing';
            }
        }
        harvestWorkOrderMap.put('functionalRating', funcRating);
        
        return harvestWorkOrderMap;
    } 
    
    @AuraEnabled
    public static String createAssets(List<Map<String, Object>> selectedItems, String harvestWorkOrderId) {
        system.debug('#### calling createAssets method.');
        String statusMessage;
        List<ProductItem__c> pItemListToInsert = new List<ProductItem__c>();
        List<Product2> selectedProductsList = new List<Product2>();
        Set<String> setProductNames = new Set<String>();
        Map<Id, String> mapProductIdToProductName = new Map<Id, String>(); 
        Map<String, Id> mapProductToPriceBookEntryId = new Map<String, Id>();
        Map<String, Map<String, Object>> mapUpdatedProductItems = new Map<String, Map<String, Object>>();
        String recordIdList = '(';
        getRecordTypes();
        if (selectedItems != null && harvestWorkOrderId != null) {
            for (Map<String, Object> o : selectedItems) {
                system.debug('#### object map: ' + o);
                Map<String, Object>  mapProductItemValues = new Map<String, Object>();
                String recordId = String.valueOf(o.get('id'));
                system.debug('#### id: ' + recordId);
                recordIdList += '\'' + recordId + '\',';
                mapProductItemValues.put('quantity', o.get('quantity'));
                mapProductItemValues.put('partSubLocation', o.get('partSubLocation'));
                mapProductItemValues.put('serialNumber', o.get('serialNumber'));
                mapProductItemValues.put('cosmeticRating', o.get('cosmeticRating'));
                mapProductItemValues.put('functionalRating', o.get('functionalRating'));
                mapProductItemValues.put('reviewStatus', o.get('reviewStatus'));
                mapProductItemValues.put('dateOfManufacture', o.get('dateOfManufacture'));
                mapProductItemValues.put('tubeCount', o.get('tubeCount'));
                mapProductItemValues.put('tubeCountDate', o.get('tubeCountDate'));
                mapUpdatedProductItems.put(recordId, mapProductItemValues);
                system.debug('#### mapProductItemValues: ' + mapProductItemValues);
                system.debug('#### mapUpdatedProductItems: ' + mapUpdatedProductItems);
            }
            
            recordIdList = recordIdList.removeEnd(',') + ')';
            String whereClause = ' WHERE Id IN ' + recordIdList;
            System.debug('#### createAssets method whereClause: ' + whereClause);
            String query = getProductQuery();  
            query += whereClause;
            System.debug('#### createAssets method query: ' + query);
            
            for (Product2 p: Database.query(query)) {
                system.debug('#### product: ' + p);
                selectedProductsList.add(p);
                Map<String, Object>  mapProductItemValues = mapUpdatedProductItems.get(p.Id);
                String subLocation = (String) mapProductItemValues.get('partSubLocation');
                system.debug('#### sub location passed in: ' + subLocation);
                Integer quantity = Integer.valueOf(mapProductItemValues.get('quantity'));
                system.debug('#### number of assets to create for this product: ' + quantity);
                String serialNumber;
                if (mapProductItemValues.get('serialNumber') != null) {
                    serialNumber = (String) mapProductItemValues.get('serialNumber');
                    system.debug('#### serialNumber passed in: ' + serialNumber);
                }
                String cosmeticRating = (String) mapProductItemValues.get('cosmeticRating');
                String functionalRating = (String) mapProductItemValues.get('functionalRating');
                String reviewStatus = (String) mapProductItemValues.get('reviewStatus');
                String dateOfManufacture;
                if (mapProductItemValues.get('dateOfManufacture') != null){
                    dateOfManufacture = (String) mapProductItemValues.get('dateOfManufacture'); 
                } 
                String tubeCount;
                if (mapProductItemValues.get('tubeCount') != null){
                    tubeCount = (String) mapProductItemValues.get('tubeCount');
                } 
                Date tubeCountDate;
                if (mapProductItemValues.get('tubeCountDate') != null){
                    String tubeCountDateString = (String) mapProductItemValues.get('tubeCountDate');
                    tubeCountDate = Date.valueOf(tubeCountDateString);
                }
                

                setProductNames.add(p.Name);
                mapProductIdToProductName.put( p.Id, p.Name);
                Date receiveDate = Date.today();
                
                //determine location based on user location
                String currentUserLocation = 'Tampa';
                getCurrentUser();
                if(userInfo != null){
                    if(userInfo.Location__c != null){
                        currentUserLocation = userInfo.Location__c;
                        if(userInfo.Location__c.contains('UK')){
                            currentUserLocation = 'Gloucester, UK';
                        }
                    }
                    
                    
                }
                
                for (Integer i=0; i<quantity; i++) {
                    ProductItem__c pItem = new ProductItem__c(Product_Name__c=p.Id, Product_Analytics__c = p.Product_Analytics__c, Sub_Location__c=subLocation, Part_Status__c='WIP', Harvest_Work_Order__c=harvestWorkOrderId,
                                                              Serial_No__c=serialNumber, Check_In_Type__c='Harvested', Purchase_Harvest_Part__c='Harvest', 
                                                              Receive_date__c=receiveDate, Location__c= currentUserLocation, Cosmetic_Rating__c = cosmeticRating, Functional_Rating__c = functionalRating,
                                                              Review_Status__c = reviewStatus, Date_of_Manufacture__c = dateOfManufacture, Tube_Count__c = tubeCount, 
                                                              Tube_Count_Date__c = tubeCountDate, RecordTypeId = partRT, Asset_Model_No__c = p.Part_Number__c);
                    pItemListToInsert.add(pItem);
                }    
            }
        }
        
        if (!pItemListToInsert.isEmpty()) {
            try { 
                system.debug('#### About to insert this many assets: ' + pItemListToInsert.size());
              DatabaseService.insertList(pItemListToInsert);
                statusMessage = 'success';
            }  catch (Exception e) {
                statusMessage += 'error: ' + e.getMessage().unescapeHtml4();
            }
        }
        
        system.debug('createAssets status message returned:' + statusMessage);
        return statusMessage;
    }
   public static void getRecordTypes() {
        for (RecordType r : ProboCommonUtils.getRecordTypes('ProductItem__c')) {
            switch on r.DeveloperName {
                when 'Part' {
                    partRT = r.id;
                }
                
            }
        }
     }
    
    public static void getCurrentUser() {
        userInfo = ProboCommonUtils.getCurrentUser();
     }

}