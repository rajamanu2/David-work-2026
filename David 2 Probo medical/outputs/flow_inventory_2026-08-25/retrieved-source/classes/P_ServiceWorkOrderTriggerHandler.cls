public class P_ServiceWorkOrderTriggerHandler {
    private static Id serviceRT;
    private static Id maintenanceRT;
    private static Id loanerRT;
    private static Id loanerRmaRT;
    
    
    
    private Map<Id, List<ContractLineItem>> getContractLineItems(List<ServiceContract> SCList) {
        List<ContractLineItem> contractLineItemList = [SELECT Id, System_Serial_Number__c, Serial_No__c, ServiceContractId  
                                                FROM ContractLineItem 
                                                WHERE ServiceContractId in :SCList 
                                                ];
        Map<Id, List<ContractLineItem>> contractLineItemMap = new Map<Id, List<ContractLineItem>>();
        for(ServiceContract sc:SCList) {
            List<ContractLineItem> lineItemList = new List<ContractLineItem>();
            for(ContractLineItem cli:contractLineItemList){
                if(cli.ServiceContractId == sc.Id){
                    lineItemList.add(cli);
                }
            }
            ContractLineItemMap.put(sc.id, lineItemList);
        }
        return ContractLineItemMap;
    }
    
    private List<ProductItem__c> getAssetList(list<ID> WOList) {
            
            List<WorkOrderLineItem> WOLineItemList = [SELECT ID, Part_Used__c, WorkOrderId, Part_Used__r.Check_In_Type__c 
                                                    FROM WorkOrderLineItem 
                                                    WHERE WorkOrderId in: WOList AND Part_Used__r.Check_In_Type__c != 'Generic'];
            List<ID> assetIDList = new list<ID> ();
            for(WorkOrderLineItem w : WOLineItemList) {
                assetIDList.add(w.Part_Used__c);
            }
            List<ProductItem__c> assetList = [select ID, Reserved__c, Sold__c, Sales_Price__c, Check_In_Type__c, Location__c, Purchasing_Approved__c, Serial_No__c, Product_Family__c from ProductItem__c WHERE id in: assetIDList];
            
            return assetList;
    }
        
    private Map<ID, decimal> getAssetMap(list<ID> WOList) {
        
        List<WorkOrderLineItem> WOLineItemList = [SELECT ID, Part_Used__c, WorkOrderId, Fair_Market_Price__c, Part_Used__r.Check_In_Type__c 
                                                  FROM WorkOrderLineItem 
                                                  WHERE WorkOrderId in: WOList AND Part_Used__r.Check_In_Type__c != 'Generic'];
        
        Map<ID, Decimal> assetMap = new Map<ID, Decimal>();
        for(WorkOrderLineItem w : WOLineItemList) {
            assetMap.put(w.Part_Used__c, w.Fair_Market_Price__c);
        }
        return assetMap;
    }
    
    private Map<ID, Account> getAccountMap(list<WorkOrder> WOList){
        list<ID> accountIDList = new list<ID>();
        for(WorkOrder wo:WOList){
            accountIDList.add(wo.AccountID);
        }
        
        list<Account> newAccountList = [select ID, BillingStreet, BillingCity, BillingState, BillingPostalCode from
                                       Account where id=: accountIDList];
        
        Map<ID, Account> accountMap = new Map<ID, Account>();
        for(Account a:newAccountList){
            accountMap.put(a.id, a);
        }
        
        return accountMap;
    }
    private Map<ID, Opportunity> getOppMap(list<WorkOrder> WOList){
        list<ID> oppIDList = new list<ID>();
        for(WorkOrder wo:WOList){
            oppIDList.add(wo.Opportunity__c);
        }
        
        list<Opportunity> newOppList = [select ID, Owner.Email from
                                       Opportunity where id=: oppIDList];
        
        Map<ID, Opportunity> oppMap = new Map<ID, Opportunity>();
        for(Opportunity o:newOppList){
            oppMap.put(o.id, o);
        }
        
        return oppMap;
    }
    
    public void doTriggerInsertWork(List<WorkOrder> newRecs){
        getRecordTypes();
        list<ID> workOrderIDList = new list<ID>();
        Map<Id,Account> newAccountMap = getAccountMap(newRecs);
        Map<Id,Opportunity> newOppMap = getOppMap(newRecs);
        for(WorkOrder newWO: newRecs){
            if(newWO.Field_Service_Engineer__c != null){
                list<String> FSEList = newWO.Field_Service_Engineer__c.split(';');
                
                List<String> engineer = FSEList[0].split(' ');String secondPart ='';if(engineer.size () >= 2){secondPart = engineer[1];
                }   
                newWO.FSE_Email__c =  FSEList[0].substring(0,1) + secondPart + '@probomedical.com';
            }
            if(newWO.Opportunity__c != null){
                Opportunity o = newOppMap.get(newWO.Opportunity__c);
                newWO.Opportunity_Owner_Email__c = o.Owner.Email;
            }
            if(newWO.RecordTypeId == serviceRT && newWO.Work_Order_PDF_Type__c == null){
                newWO.Work_Order_PDF_Type__c = 'Field Service Report';
            }
            if(newWO.RecordTypeId == maintenanceRT && newWO.Work_Order_PDF_Type__c == null){
                newWO.Work_Order_PDF_Type__c = 'Preventative Maintenance Report';
            }
            
            
            
            if(newWO.AccountId != null && newWO.Billing_Street__c == null){
                Account a = newAccountMap.get(newWO.AccountId);
                if(a != null){
                    newWO.Billing_Street__c = a.BillingStreet;
                	newWO.Billing_City__c = a.BillingCity;
                	newWO.Billing_State__c = a.BillingState;
                	newWO.Billing_Zip_Postal_Code__c = a.BillingPostalCode;
                }
                
                
            }
            
            // Search for service contract to link if coming from Service Fusion
            if(/*newWO.Owner.Name == 'Delegate' &&*/ newWO.ServiceContractId == null){
                List<ServiceContract> SCList = [SELECT Id, Coverage_Type__c, AccountId, StartDate, EndDate from ServiceContract WHERE 
                                                ((StartDate < TODAY AND EndDate > TODAY) OR (Warranty_Start_Date__c < TODAY AND Warranty_End_Date__c > TODAY)) 
                                                AND AccountId =:newWO.AccountId];
                system.debug('THIS IS THE SC LIST >>> ' + SCList);
                if(SCList.size() > 0){
                    Map<Id,List<ContractLineItem>> contractLineItems = getContractLineItems(SCList);
                   
                    for(ServiceContract sc:SCList){
                        if(SC.Coverage_Type__c != null){
                            if(sc.Coverage_Type__c.contains('PM') && newWO.RecordTypeId == maintenanceRT){
                            	newWO.ServiceContractId = sc.Id;
                                newWO.Description = newWO.Description + '; Updated Service Contract through Apex';
                        	}
                            if(sc.Coverage_Type__c.contains('Full Service') && (newWO.RecordTypeId == serviceRT || newWO.RecordTypeId == maintenanceRT)){
                                newWO.ServiceContractId = sc.Id;
                                newWO.Description = newWO.Description + '; Updated Service Contract through Apex';
                            }
                        }
                        
                        
                    }
                    if(newWO.Serial_Number__c != null){
                        system.debug('INSIDE SERIAL NUMBER IF STATEMENT >>> ' + newWO.Serial_Number__c);
                        for(ServiceContract sc:SCList){
                            
                            List<ContractLineItem> CLIList = contractLineItems.get(sc.id);
                            for(ContractLineItem cli:CLIList){
                                system.debug('THIS IS THE CLI INSIDE FOR LOOP >>> ' + cli);
                                if(newWO.Serial_Number__c == cli.System_Serial_Number__c || newWo.Serial_Number__c == cli.Serial_No__c){
                                    newWO.ServiceContractId = sc.Id;
                                    newWO.Description = newWO.Description + '; Updated Service Contract through Apex';
                                }
                            }
                               
                        
                        }
                    }
                    
                }
                
            }
            // Removed WO Line Item section from Insert Section - no WO line items on WO creation. 09/10/24 NB
            
            
        
        }
            
            // END of WO line item UPDATES
          
    }
    
   	public void doTriggerBeforeUpdateWork(List<WorkOrder> newRecs,Map<Id, WorkOrder> oldRecs){
        getRecordTypes();
        Map<Id,Account> newAccountMap = getAccountMap(newRecs);
        Map<Id,Opportunity> newOppMap = getOppMap(newRecs);
        for(WorkOrder newWO:newRecs){
            if(newWO.Field_Service_Engineer__c != null && oldRecs.get(newWO.Id).Field_Service_Engineer__c != newWO.Field_Service_Engineer__c){
                list<String> FSEList = newWO.Field_Service_Engineer__c.split(';');
                
                List<String> engineer = FSEList[0].split(' ');String secondPart ='';if(engineer.size () >= 2){secondPart = engineer[1];
                }   
                newWO.FSE_Email__c =  FSEList[0].substring(0,1) + secondPart + '@probomedical.com';
                
            
            }
            if(newWO.Opportunity__c != null){
                Opportunity o = newOppMap.get(newWO.Opportunity__c);
                if(newWO.Opportunity_Owner_Email__c != o.Owner.Email){
                    newWO.Opportunity_Owner_Email__c = o.Owner.Email;
                }
                
            }
            if(newWO.RecordTypeId == serviceRT && newWO.Work_Order_PDF_Type__c == null){
                newWO.Work_Order_PDF_Type__c = 'Field Service Report';
            }
            if(newWO.RecordTypeId == maintenanceRT && newWO.Work_Order_PDF_Type__c == null){
                newWO.Work_Order_PDF_Type__c = 'Preventative Maintenance Report';
            }
            if(newWO.AccountId != null && newWO.Billing_Street__c == null){
                Account a = newAccountMap.get(newWO.AccountId);
                if(a != null){
                    newWO.Billing_Street__c = a.BillingStreet;
                	newWO.Billing_City__c = a.BillingCity;
                	newWO.Billing_State__c = a.BillingState;
                	newWO.Billing_Zip_Postal_Code__c = a.BillingPostalCode;
                }
                
                
            }
            
        }
    
    }
    
    public void doTriggerAfterUpdateWork(List<WorkOrder> newRecs,Map<Id, WorkOrder> oldRecs){
        // Mark WO line items as sold and set sales price, so cost can be back filled on asset page
        User theCurrentUser = ProboCommonUtils.getCurrentUser();
        List<Move_Location__c> MoveLocationsToInsert = new List<Move_Location__c>();  
        List<RMA__c> LoanerRMAsToInsert = new List<RMA__c>();
        List<ProductItem__c> WOAssetList = new List<ProductItem__c>();
        Map <ID, Decimal> finalAssetMap = new Map<ID, Decimal>();
        list<ID> workOrderIDList = new list<ID>();
        for(WorkOrder newWO:newRecs){
            
            if(newWO.Ship_Date__c != null && newWO.Tracking_Number__c != null && (oldRecs.get(newWO.Id).Ship_Date__c == null || oldRecs.get(newWO.Id).Tracking_Number__c == null)){
                workOrderIDList.add(newWO.ID);
            }       
        
            if(workOrderIDList.size() > 0){
                WOAssetList = getAssetList(workOrderIDList);
                finalAssetMap = getAssetMap(workOrderIDList);
            }
            // Mark WO line items as sold and set sales price, so cost can be back filled on asset page
        	
            for(ProductItem__c p: WOAssetList){
                system.debug('THIS IS THE PRODUCT ITEM >> ' + p);
                if (p.Purchasing_Approved__c == false && p.Check_In_Type__c != 'Generic' && p.Check_In_Type__c != 'Customer Repair' 
                    						&& p.Check_In_Type__c != 'Vet – Customer Repair'
                                            && p.Check_In_Type__c != 'Vet – Warranty Repair'
                                            && p.Check_In_Type__c != 'Warranty Repair') {
                    system.debug('Not possible because product is not purchasing approved');
                    newWO.addError('Not possible because product is not purchasing approved');
                }
                
                String usr_name = theCurrentUser.FirstName + ' ' + theCurrentUser.LastName;
                if(newWO.RecordTypeId != loanerRT){
                    p.Sold__c = true;
                    if(p.Location__c != 'Shipping' && p.Location__c != 'Customer Loan / Demo'){
                        Move_Location__c newMove = new Move_Location__c(Old_Location__c = p.Location__c, Note__c = 'Shipped on ' + newWO.Ship_Date__c, Related_Opportunity__c = newWO.Opportunity__c,
                                                                        New_Location__c = 'Shipping', Geographic_Location__c = 'Shipping', Completed_By__c = usr_name,
                                                                        ProductItem__c = p.Id);
                        MoveLocationsToInsert.add(newMove);
                    }
                    if(finalAssetMap.get(p.id) != null){
                        p.Sales_Price__c = finalAssetMap.get(p.id);
                    }
                }
                
                if(newWO.recordTypeId == loanerRT){
                    
                    Move_Location__c newMove = new Move_Location__c(Old_Location__c = p.Location__c, Note__c = 'Loaner shipped on ' + newWO.Ship_Date__c, Related_Opportunity__c = newWO.Opportunity__c,
                                                                    New_Location__c = 'Customer Loan / Demo', Geographic_Location__c = 'Customer Loan / Demo', Completed_By__c = usr_name,
                                                                    ProductItem__c = p.Id);
                    if(p.Product_Family__c.contains('Part')){
                        // all parts on loan are going to FSEs - need to document which FSE has each one
                        newMove.New_Location__c = 'Field Service Engineer';
                        newMove.Geographic_Location__c = 'Field Service Engineer';
                        newMove.Field_Service_Engineer__c = newWO.Field_Service_Engineer__c;
                    }
                    MoveLocationsToInsert.add(newMove);
                     RMA__c LoanerRMA = new RMA__c(RecordTypeId = loanerRmaRT, Opportunity__c = newWO.Opportunity__c, ProductItem__c = p.id,
                                                    RMA_Item_Serial_Number__c = p.Serial_No__c, Work_Order__c = newWO.id, Date_loaner_shipped__c = newWO.Ship_Date__c);
                      system.debug('THIS IS THE LOANER RMA >>> ' + LoanerRMA);
                      loanerRMAsToInsert.add(loanerRMA);
               }
            }
        }
        // END of WO line item UPDATES
        
        
        //UPDATE SERVICE CONTRACTS
        decimal TotalBillable = 0;
        decimal TotalCost = 0;
        list<ServiceContract> ContractList = new list<ServiceContract>();
        list<ServiceContract> ContractsToUpdate = new list<ServiceContract>();
        list<ID> ContractIDs = new list<ID>();
        
        for(WorkOrder newWO:newRecs){
            ContractIDs.add(newWO.ServiceContractId);   
        }
        
        ContractList = [select ID, Billable_Work_Order_Total__c, Total_Cost__c from ServiceContract where ID=:ContractIDs];
        list<Schema.WorkOrder> CompleteWOList = [select ID, Billable_Work_Order__c, Work_Order_Cost__c, ServiceContractID from WorkOrder where ServiceContractID =:ContractIDs];
        for(ServiceContract SC:ContractList){
            TotalBillable = 0;
            TotalCost = 0;
            for(Schema.WorkOrder WOs:CompleteWOList){
                if(WOs.ServiceContractID == SC.ID){
                    if(WOs.Billable_Work_Order__c != null){
                        TotalBillable += WOs.Billable_Work_Order__c;
                    }
                    if(WOs.Work_Order_Cost__c != null){
                        TotalCost += WOs.Work_Order_Cost__c;
                    }
                    
                }
            }
            if (SC.Billable_Work_Order_Total__c != TotalBillable){
                SC.Billable_Work_Order_Total__c = TotalBillable;
                ContractsToUpdate.add(SC);
            }
            if (SC.Total_Cost__c != TotalCost){
                SC.Total_Cost__c = TotalCost;
                if(!ContractsToUpdate.contains(SC)){
                    ContractsToUpdate.add(SC);
                }
                
            }
            
        }
        // END OF SERVICE CONTRACT UPDATES 
        
        if(ContractsToUpdate.size() > 0){
            update ContractsToUpdate;
        }
        if(WOAssetList.size() > 0){
            update WOAssetList;
        }
        
        System.debug('Inserting this many Move Locations in P_ServiceWorkorderTrigger: ' + MoveLocationsToInsert.size());
        if (!MoveLocationsToInsert.isEmpty()) {
            DatabaseService.insertList(MoveLocationsToInsert);
        }
        
        System.debug('Inserting this many Loaner RMAs in P_ServiceWorkorderTrigger: ' + LoanerRMAsToInsert.size());
        if (!LoanerRMAsToInsert.isEmpty()) {
            DatabaseService.insertList(LoanerRMAsToInsert);
        }
        
        
    }
 
    
     public static void getRecordTypes() {
        for (RecordType r : ProboCommonUtils.getRecordTypes('WorkOrder')) {
            switch on r.Name {
                when 'Service Call' {
                    serviceRT = r.id;
                }
                when 'Preventative Maintenance' {
                    maintenanceRT = r.id;
                }
                when 'Loaner WO'{
                    loanerRT = r.id;
                }
            }
     }
         for (RecordType r : ProboCommonUtils.getRecordTypes('RMA__c')) {
            switch on r.Name {
                when 'Loaner Return' {
                    loanerRmaRT = r.id;
                }
            }
         }
     }

}