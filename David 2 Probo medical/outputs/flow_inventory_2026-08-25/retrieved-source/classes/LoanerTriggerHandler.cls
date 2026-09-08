public class LoanerTriggerHandler {
  set<RMA__c> rmasToUpsert = new set<RMA__c>();
    set<RMA__c> LoanerRMAsToInsert = new set<RMA__c>();
    set<Move_Location__c> MoveLocationsToInsert = new set<Move_Location__c>();
    set<Opportunity> OpportunitiesToUpsert = new set<Opportunity>();
    //List<OpportunityLineItem> OppLineItemsToInsert = new list<OpportunityLineItem>();
    
    List<ProductItem__c> AssetList = new List<ProductItem__c>();
    List<RMA__c> RMAList = new List<RMA__c>();
   
    
    private static RecordType LOANrt;
    private static RecordType EVALrt;
    private static RecordType OPPrt;
    private static RecordType WARRANTYrt;
    
    public void doTriggerInsertWork(List<Loaner__c> newRecs){
        for(Loaner__c l:newRecs){
        
            if(l.Repair_Opportunity__c != null){
                Opportunity RepairOpp = [select id, Attention__c, Ship_to_Account__c, ShippingCity__c, ShippingCountry__c, ShippingPostalCode__c, ShippingState__c, ShippingStreet__c from Opportunity where id=:l.Repair_Opportunity__c];
               	l.Attn__c = RepairOpp.Attention__c;
                l.Ship_to_Account__c = RepairOpp.Ship_To_Account__c;
                l.Shipping_City__c = RepairOpp.ShippingCity__c;
                l.Shipping_Country__c = RepairOpp.ShippingCountry__c;
                l.Shipping_Postal_Code__c = RepairOpp.ShippingPostalCode__c;
                l.Shipping_State__c = RepairOpp.ShippingState__c;
                l.Shipping_Street__c = RepairOpp.ShippingStreet__c;
                
                // This will be updated when ship date is entered anyways.
                //RepairOpp.Loaner__c = l.id; 
                    
            }
            
        }
        
    } // END INSERT WORK
    
    public void doTriggerUpdateWork(List<Loaner__c> newRecs, Map<Id, Loaner__c> newRecMap, Map<Id, Loaner__c> oldRecs) {
        User theCurrentUser = ProboCommonUtils.getCurrentUser();
        
        system.debug('OUTSIDE LOANER TRIGGER >>>> ' + newrecs);
        for (RecordType r : ProboCommonUtils.getRecordTypes('RMA__c')) {
            switch on r.Name {
                when 'Loaner Return' {
                    LOANrt = r;
                }
                when 'Customer Repair Evaluation' {
                    EVALrt = r;
                }
                when 'Warranty Claim'{
                    WARRANTYrt = r;
                }
            }
        }
        
        for (RecordType r : ProboCommonUtils.getRecordTypes('Opportunity')) {
            switch on r.DeveloperName {
                when 'Probe_Sales_Opportunity' {
                    OPPrt = r;
                }
                
            }
        }
        
      if (Trigger.isUpdate) {
            system.debug('INSIDE LOANER TRIGGER >>>> ' + newrecs);
            
            for(Loaner__c l:newRecs){
                Loaner__c OldLoaner;
                OldLoaner= oldRecs.get(l.Id);
                if(l.Loaner_Asset__c!= null){
                    list<string> LoanerAssets = l.Loaner_Asset__c.split(',');
                    AssetList = [select ID, name, Serial_No__c, Location__c, Sub_Location__c, Product2_Name__c from ProductItem__c where name IN :LoanerAssets];
                  system.debug('THIS IS THE ASSET LIST >>> ' + assetlist);
          Opportunity RepairOpp = [select id, AccountId, Sales_Lead_Source__c from Opportunity where id=:l.Repair_Opportunity__c];
                    
                if(l.Ship_Date_New__c != null && OldLoaner.Ship_Date_New__c == null){
                    String usr_name = theCurrentUser.FirstName + ' ' + theCurrentUser.LastName;
                    for(ProductItem__c Asset:AssetList){
                      Move_Location__c newMove = new Move_Location__c(Old_Location__c = Asset.Location__c, Note__c = 'Loaner shipped on ' + l.Ship_Date_New__c, Related_Opportunity__c = l.Repair_Opportunity__c,
                                                                    /*External_Location__c = l.Ship_to_Account__c,*/ New_Location__c = 'Customer Loan / Demo', Geographic_Location__c = 'Customer Loan / Demo', Completed_By__c = usr_name,
                                                                    ProductItem__c = Asset.Id);
                      MoveLocationsToInsert.add(newMove);
                      RMA__c LoanerRMA = new RMA__c(RecordTypeId = LOANrt.Id, Opportunity__c = l.Repair_Opportunity__c, ProductItem__c = Asset.id,
                                                    RMA_Item_Serial_Number__c = Asset.Serial_No__c, Loaner_Object__c = l.id, Date_loaner_shipped__c = l.Ship_Date_New__c);
                      system.debug('THIS IS THE LOANER RMA >>> ' + LoanerRMA);
                      loanerRMAsToInsert.add(loanerRMA);
                        
                    
                    }
                    
                    if (!loanerRMAsToInsert.isEmpty()) {
                        list<RMA__c> LoanerList = new List<RMA__c>(loanerRMAstoInsert);
                        system.debug('THIS IS THE LOANER LIST >>> ' + LoanerList);
                    	DatabaseService.insertList(loanerList);
                        system.debug('THIS IS THE LOANER RMA >>> ' + loanerList[0].id);
                       l.RMA__c = loanerList[0].id;
              		} 
          RMAList = [select id, Product_Name__c, RecordTypeId, Opportunity__c from RMA__c where Opportunity__c =:RepairOpp.id];
                     system.debug('THIS IS THE RMA LIST FOR LOANER TRIGGER >>> ' + RMAList);               
                    for(ProductItem__c Asset:AssetList){
                        id LoanerID;
                        RMA__c CurrentRepairRMA;
                        for(RMA__c CurrentRMA:RMAList){
                            system.debug('THIS IS RMA PRODUCT >>> ' + CurrentRMA.Product_Name__c + ' && THIS IS ASSET PRODUCT >>> ' + Asset.Product2_Name__c + ' && THIS IS THE RECORD TYPE >>> ' + CurrentRMA.RecordTypeId);
                            system.debug('THIS IS THE LOAN RT >> ' + loanRT.id + ' && THIS IS THE EVAL RT >> ' + EVALRT.id);
                            if(CurrentRMA.Product_Name__c == Asset.Product2_Name__c && CurrentRMA.RecordTypeId == loanRT.id){
                                loanerID = CurrentRMA.id;
                            }
                            if((CurrentRMA.Product_Name__c == Asset.Product2_Name__c || CurrentRMA.Product_Name__c == null) && (CurrentRMA.RecordTypeId == EVALRT.id || CurrentRMA.RecordTypeID == WarrantyRT.id)){
                                CurrentRepairRMA = CurrentRMA;
                            }
                            
                        }
                        system.debug('THIS IS THE CURRENT REPAIR RMA >>> ' + CurrentRepairRMA);
                        if(CurrentRepairRMA != null){
                            CurrentRepairRMA.Loaner_RMA__c = loanerid;
                            CurrentRepairRMA.Loaner_Asset_Number__c = Asset.id;
                            CurrentRepairRMA.Date_Loaner_Shipped__c = l.Ship_Date_New__c; 
                            if(CurrentRepairRMA.RecordTypeID == evalRT.id){
                                RepairOpp.Customer_Repair_Evaluation_RMA__c = CurrentRepairRMA.id;
                             
                            }
                           
                            rmasToUpsert.add(CurrentRepairRMA);
                        }
                            
                      RepairOpp.Loaner__c = l.id;
                      OpportunitiestoUpsert.add(RepairOpp);
                  }
                    
                             
                }
                    if(l.Ship_Date_New__c != null && OldLoaner.Ship_Date_New__c != null && OldLoaner.Ship_Date_New__c != l.Ship_Date_New__c){
                        RMAList = [select id, Product_Name__c, RecordTypeId, Opportunity__c from RMA__c where Opportunity__c =:RepairOpp.id];
                                        
                        for(ProductItem__c Asset:AssetList){
                           
                            RMA__c CurrentRepairRMA;
                            RMA__c CurrentLoanerRMA;
                            for(RMA__c CurrentRMA:RMAList){
                                if(CurrentRMA.Product_Name__c == Asset.Product2_Name__c && CurrentRMA.RecordTypeId == loanRT.id){
                                    CurrentLoanerRMA = CurrentRMA;
                                }
                                if(CurrentRMA.Product_Name__c == Asset.Product2_Name__c && (CurrentRMA.RecordTypeId == EVALRT.id || CurrentRMA.RecordTypeID == WarrantyRT.id)){
                                    CurrentRepairRMA = CurrentRMA;
                                }
                                
                            }
                            
                            if(CurrentRepairRMA != null){
                                
                                CurrentRepairRMA.Date_Loaner_Shipped__c = l.Ship_Date_New__c; 
                              
                                rmasToUpsert.add(CurrentRepairRMA);
                            }
                            
                            if(CurrentLoanerRMA != null){
                                
                                CurrentLoanerRMA.Date_Loaner_Shipped__c = l.Ship_Date_New__c; 
                              
                                rmasToUpsert.add(CurrentLoanerRMA);
                            }
                            
                        }
                        
                    }
                    
               /*     if(l.Loaner_Turned_to_Sale__c == true && oldLoaner.Loaner_Turned_to_Sale__c == false){
                        String oppname = 'Loaner for ' + l.Repair_Opportunity_Number__c;
                        Opportunity RepairOpp = [select id, AccountId, Sales_Lead_Source__c, Shipping_from_location__c from Opportunity where id=:l.Repair_Opportunity__c];
                        
                        Opportunity LoanerOpp = new Opportunity(RecordTypeId = OPPrt.Id, Shipping_from_location__c = RepairOpp.Shipping_from_location__c, StageName = 'Closed Won', Name = OppName, CloseDate = Date.today(), AccountId = RepairOpp.AccountId, Sales_lead_source__c = RepairOpp.Sales_Lead_Source__c);
                      insert LoanerOpp;
                        RepairOpp.Related_Opportunity__c = LoanerOpp.id;
                       // OpportunityLineItem OppLineItem = new OpportunityLineItem(OpportunityId = LoanerOpp.id, Quantity = 1, ProductItem__c = Asset.id, Purchasing_Approved__c = true);
                       // system.debug('THIS IS THE OPP LINE ITEM >>> ' + opplineitem);
                        OpportunitiestoUpsert.add(RepairOpp);
                       // OppLineItemstoInsert.add(OppLineItem);
                    }*/
                }
            }
        }
        if (!MoveLocationsToInsert.isEmpty()) {
            list<Move_Location__c> MoveLocationList = new list<Move_Location__c>(MoveLocationsToInsert);
            DatabaseService.insertList(MoveLocationList);
        }
        
        if (!rmasToUpsert.isEmpty()) {
            list<RMA__c> RMAList = new list<RMA__c>(rmasToUpsert);
            DatabaseService.upsertList(RMAList);
        }
        
        if (!OpportunitiestoUpsert.isEmpty()){
            list<Opportunity> OppList = new List<Opportunity>(OpportunitiesToUpsert);
            DatabaseService.upsertList(OppList);
        }
        
       /* if (!OppLineItemstoInsert.isEmpty()){
            DatabaseService.insertList(OppLineItemstoInsert);
        } */
        
        
    } // END UPDATE
    
    
}