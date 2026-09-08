public class NewStandardWorkOrder {
    String FSE, Attn, ShiptoAccount, ShipStreet, ShipCity, ShipState, ShipPostal, BillStreet, BillCity, BillState, BillPostal, UITheme;
    Id servicecontid, recordTypeId, oppId, RMAid, acctID, parentWOID;

    private transient Id srcRecId;

    public NewStandardWorkOrder(ApexPages.StandardController controller) {
        GH_Logger.debug('start single record NewStandardWorkOrder ctor');

        init(true);
    }

    public NewStandardWorkOrder(ApexPages.StandardSetController controller) {
        GH_Logger.debug('start list NewStandardWorkOrder Set ctor');

        init(false);
    }

    private void init(Boolean isStd){
        
        UITheme = URL.getCurrentRequestUrl().toExternalForm();

		srcRecId = ApexPages.currentPage().getParameters().get('id');
        
        // if we didn't come from a list button, see if we came from a record (like the New button on the Work Order list for Service Contract)
        if (srcRecId == null){
            srcRecId = ApexPages.currentPage().getParameters().get('ServiceContract_lkid');
        }

        if (srcRecId == null){
            srcRecId = ApexPages.currentPage().getParameters().get('CF00N4O000006N5I6_lkid'); // RMAs
        }
        
        if (srcRecId == null){
            srcRecId = ApexPages.currentPage().getParameters().get('CF00N4O000006N7ho_lkid'); // Opps
        }
        
        if (srcRecId == null){
            srcRecId = ApexPages.currentPage().getParameters().get('ParentWorkOrder_lkid'); // parent WO
        }

        GH_Logger.debug('Source Record: ' + srcRecId);


        recordTypeId = ApexPages.currentPage().getParameters().get('RecordType');
        GH_Logger.debug('Selected Record Type: ' + recordTypeId);

  
        // get some default values based on the record we were launched from
        if (srcRecId != null) {

            if (srcRecId.getSobjectType() == ServiceContract.getSobjectType()) {
                GH_Logger.debug('Page called from Service Contract ID: ' + srcRecId);

                try {
                    ServiceContract SCRecord = [SELECT Id, Name, Opportunity__c, AccountID  
                                    FROM ServiceContract WHERE Id = :srcRecId LIMIT 1];
                    servicecontid = SCRecord.id;
                    OppID = SCRecord.Opportunity__c;
                    acctID = SCRecord.AccountID;
                    
                    if(OppID != null){
                        Opportunity OppRecord = [SELECT Id, Name, Ship_to_Account__c, Field_Service_Engineer__c, Attention__c, ShippingStreet__c,
                                            ShippingCity__c, ShippingState__c, ShippingPostalCode__c, BillingStreet__c,
                                            BillingCity__c, BillingState__c, BillingPostalCode__c FROM Opportunity WHERE ID =: oppID LIMIT 1];
                    
                    	FSE = OppRecord.Field_Service_Engineer__c;
                        Attn = OppRecord.Attention__c;
                        ShipStreet = OppRecord.ShippingStreet__c;
                        ShipCity = OppRecord.ShippingCity__c;
                        ShipState = OppRecord.ShippingState__c;
                        ShipPostal = OppRecord.ShippingPostalCode__c;
                        BillStreet = OppRecord.BillingStreet__c;
                        BillCity = OppRecord.BillingCity__c;
                        BillState = OppRecord.BillingState__c;
                        BillPostal = OppRecord.BillingPostalCode__c;
                        ShipToAccount = OppRecord.Ship_to_Account__c;
                        
                    }
                    
                    
                } catch (Exception e) {
                    GH_Logger.debug('Page called with invalid Service Contract ID');
                }

            } else if (srcRecId.getSobjectType() == RMA__c.getSobjectType()) {
                GH_Logger.debug('Page called from RMA ID: ' + srcRecId);

                try {
                    RMA__c RMARecord = [select ID, Name, Opportunity__c, Service_Contract__c FROM RMA__c
                                       WHERE Id = :srcRecId LIMIT 1];
                    RMAid = RMARecord.id;
                    servicecontid = RMARecord.Service_Contract__c;
                    OppID = RMARecord.Opportunity__c;
                    system.debug('THIS IS THE OPP ID FOR RMA >>> ' + OppID);
                    if(OppID != null){
                        Opportunity OppRecord = [SELECT Id, Name, Ship_to_Account__c, AccountId, Field_Service_Engineer__c, Attention__c, ShippingStreet__c,
                                            ShippingCity__c, ShippingState__c, ShippingPostalCode__c, BillingStreet__c,
                                            BillingCity__c, BillingState__c, BillingPostalCode__c FROM Opportunity WHERE ID =: oppID LIMIT 1];
                    
                    	acctID = OppRecord.AccountID;
                        FSE = OppRecord.Field_Service_Engineer__c;
                        Attn = OppRecord.Attention__c;
                        ShipStreet = OppRecord.ShippingStreet__c;
                        ShipCity = OppRecord.ShippingCity__c;
                        ShipState = OppRecord.ShippingState__c;
                        ShipPostal = OppRecord.ShippingPostalCode__c;
                        BillStreet = OppRecord.BillingStreet__c;
                        BillCity = OppRecord.BillingCity__c;
                        BillState = OppRecord.BillingState__c;
                        BillPostal = OppRecord.BillingPostalCode__c;
                        ShiptoAccount = OppRecord.Ship_To_Account__c;
                        
                    }

                } catch (Exception e) {
                    GH_Logger.debug('Page called with invalid RMA ID');
                }
            }
            
           	 else if (srcRecId.getSobjectType() == Opportunity.getSobjectType()) {
                GH_Logger.debug('Page called from Opp ID: ' + srcRecId);

                try {
                    
                    Opportunity OppRecord = [SELECT Id, Name, Ship_to_Account__c, AccountId, Field_Service_Engineer__c, Attention__c, ShippingStreet__c,
                                             ShippingCity__c, ShippingState__c, ShippingPostalCode__c, BillingStreet__c,
                                             BillingCity__c, BillingState__c, BillingPostalCode__c FROM Opportunity WHERE ID =: srcRecId LIMIT 1];
                    
                    OppID = OppRecord.Id;
                    acctID = OppRecord.AccountID;
                    FSE = OppRecord.Field_Service_Engineer__c;
                    Attn = OppRecord.Attention__c;
                    ShipStreet = OppRecord.ShippingStreet__c;
                    ShipCity = OppRecord.ShippingCity__c;
                    ShipState = OppRecord.ShippingState__c;
                    ShipPostal = OppRecord.ShippingPostalCode__c;
                    BillStreet = OppRecord.BillingStreet__c;
                    BillCity = OppRecord.BillingCity__c;
                    BillState = OppRecord.BillingState__c;
                    BillPostal = OppRecord.BillingPostalCode__c;
                    ShiptoAccount = OppRecord.Ship_To_Account__c;
                    

                } catch (Exception e) {
                    GH_Logger.debug('Page called with invalid Opp ID');
                }
            }
            
            else if (srcRecId.getSobjectType() == WorkOrder.getSobjectType()) {
                GH_Logger.debug('Page called from WO ID: ' + srcRecId);

                try {
                    WorkOrder parentWORecord = [select ID, AccountId, Opportunity__c, ServiceContractId FROM WorkOrder
                                       WHERE Id = :srcRecId LIMIT 1];
                    parentWOid = parentWORecord.id;
                    servicecontid = parentWORecord.ServiceContractId;
                    OppID = parentWORecord.Opportunity__c;
                    acctID = parentWORecord.AccountId;
                    system.debug('THIS IS THE OPP ID FOR RMA >>> ' + OppID);
                    if(OppID != null){
                        Opportunity OppRecord = [SELECT Id, Name, Ship_to_Account__c, AccountId, Field_Service_Engineer__c, Attention__c, ShippingStreet__c,
                                            ShippingCity__c, ShippingState__c, ShippingPostalCode__c, BillingStreet__c,
                                            BillingCity__c, BillingState__c, BillingPostalCode__c FROM Opportunity WHERE ID =: oppID LIMIT 1];
                    
                        FSE = OppRecord.Field_Service_Engineer__c;
                        Attn = OppRecord.Attention__c;
                        ShipStreet = OppRecord.ShippingStreet__c;
                        ShipCity = OppRecord.ShippingCity__c;
                        ShipState = OppRecord.ShippingState__c;
                        ShipPostal = OppRecord.ShippingPostalCode__c;
                        BillStreet = OppRecord.BillingStreet__c;
                        BillCity = OppRecord.BillingCity__c;
                        BillState = OppRecord.BillingState__c;
                        BillPostal = OppRecord.BillingPostalCode__c;
                        ShipToAccount = OppRecord.Ship_To_Account__c;
                        
                    }

                } catch (Exception e) {
                    GH_Logger.debug('Page called with invalid WO ID');
                }
            }
        }


    }

    public PageReference newStdWorkOrder() {

        GH_Logger.debug('start newWorkOrder');
        string pageURL='';
        
        if(UITheme.contains('lightning') || Test.isRunningTest()){
            pageURL = '/lightning/o/WorkOrder/new?recordTypeId=' + recordTypeId + '&defaultFieldValues=Status=NEW,Priority=Low,Ship_Type__c=FedEx Standard Overnight'; 
        	
            if(ServiceContID != null){
            	pageURL += ',ServiceContractId=' + ServiceContId;
        	}
            if(OppID != null){
            	pageURL += ',Opportunity__c=' + OppId;
        	}
            if(AcctID != null){
            	pageURL += ',AccountId=' + AcctId;
        	}
            if(parentWOID != null){
                pageURL += ',ParentWorkOrderId=' + parentWOId;
            }
            if(RMAid != null){
                pageURL += ',RMA__c=' + RMAid;
            }
            if(FSE != null){
                pageURL += ',Field_Service_Engineer__c=' + FSE;
            }
            if(Attn != null){
                pageURL += ',Attn__c=' + Attn;
            }
            if(ShipStreet != null){
            	pageURL += ',Shipping_Street__c=' + ShipStreet;
            }
            if(ShipCity != null){
            	pageURL += ',Shipping_City__c=' + ShipCity;
            }
            if(ShipState != null){
            	pageURL += ',Shipping_State__c=' + ShipState;
            }
            if(ShipPostal != null){
            	pageURL += ',Shipping_Postal_Code__c=' + ShipPostal;
            }
            if(BillStreet != null){
            	pageURL += ',Billing_Street__c=' + BillStreet;
            }
            if(BillCity != null){
            	pageURL += ',Billing_City__c=' + BillCity;
            }
            if(BillState != null){
            	pageURL += ',Billing_State__c=' + BillState;
            }
            if(BillPostal != null){
            	pageURL += ',Billing_Zip_Postal_Code__c=' + BillPostal;
            }
            if(ShipToAccount != null){
            	pageURL += ',Ship_to_Account__c=' + ShipToAccount;
            }
        
        }
        else{
            pageURL = '/0WO/e?&retURL=%2F0WO%2Fo&RecordType=' + recordTypeId + '&ent=WorkOrder'
                    + '&Status=NEW&Priority=Low&Ship_Type__c=' + 'FedEx Standard Overnight'; 
            if (acctid != null){
                    pageURL += '&AccountId=' + acctid;
           } 
            if(ServiceContID != null){
                pageURL += '&ServiceContractId=' + serviceContID;
            }
            if(parentWOID != null){
                pageURL += '&ParentWorkOrderId=' + parentWOID;
            }
       
        }

        
        
        PageReference pr = new PageReference(pageURL);
        pr.getParameters().put('nooverride', '1');
        if(!UItheme.contains('lightning')){
            
            if(OppID != null){
            	pr.getParameters().put('00N4O000006N7ho', OppId);
        	}
            if(RMAid != null){
                pr.getParameters().put('00N4O000006N5I6', RMAid);
            }
            if(FSE != null){
                pr.getParameters().put('00N4O000006N7vQ', FSE);
            }
            if(Attn != null){
                pr.getParameters().put('00N5b00000DWjV3', Attn);
            }
            if(ShipStreet != null){
            	pr.getParameters().put('00N5b00000DWfmG', ShipStreet);
            }
            if(ShipCity != null){
            	pr.getParameters().put('00N5b00000DWfmB', ShipCity);
            }
            if(ShipState != null){
            	pr.getParameters().put('00N5b00000DWfmF', ShipState);
            }
            if(ShipPostal != null){
            	pr.getParameters().put('00N5b00000DWfmE', ShipPostal);
            }
            if(BillStreet != null){
            	pr.getParameters().put('00N4O000006N7gR', BillStreet);
            }
            if(BillCity != null){
            	pr.getParameters().put('00N4O000006N7gO', BillCity);
            }
            if(BillState != null){
            	pr.getParameters().put('00N4O000006N7gP', BillCity);
            }
            if(BillPostal != null){
            	pr.getParameters().put('00N4O000006N7gS', BillPostal);
            }
            if(ShipToAccount != null){
            	pr.getParameters().put('00N5b00000DWtST', ShipToAccount);
            }
            
        }

        

        GH_Logger.debug('end newWO with URL: ' + pr.getUrl());

        return pr;

    }

    
}