public class NewRMA {
    String FSE, Attn, ShipStreet, ShipCity, ShipState, ShipPostal, BillStreet, BillCity, BillState, BillPostal, UITheme;
    Id ServiceContId, recordTypeId, OppId, WOId, acctID;

    private transient Id srcRecId;

    public NewRMA(ApexPages.StandardController controller) {
        GH_Logger.debug('start single record NewRMA ctor');

        init(true);
    }

    public NewRMA(ApexPages.StandardSetController controller) {
        GH_Logger.debug('start list NewRMA Set ctor');

        init(false);
    }

    private void init(Boolean isStd){
        
        UITheme = URL.getCurrentRequestUrl().toExternalForm();

		srcRecId = ApexPages.currentPage().getParameters().get('id');
        
        // if we didn't come from a list button, see if we came from a record (like the New button on the Work Order list for Service Contract)
        if (srcRecId == null){
            srcRecId = ApexPages.currentPage().getParameters().get('CF00N4O000006VvXO_lkid'); // Service Contract
        }

        if (srcRecId == null){
            srcRecId = ApexPages.currentPage().getParameters().get('CF00N5b00000DWmm2_lkid'); // Work Orders (standard)
        }
        
        if (srcRecId == null){
            srcRecId = ApexPages.currentPage().getParameters().get('CF00NU0000004lVwO_lkid'); // Opps
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
                    ServiceContId = SCRecord.Id;
                    OppId = SCRecord.Opportunity__c;
                    
                } catch (Exception e) {
                    GH_Logger.debug('Page called with invalid Service Contract ID');
                }

            } else if (srcRecId.getSobjectType() == WorkOrder.getSobjectType()) {
                GH_Logger.debug('Page called from Work Order ID: ' + srcRecId);

                try {
                    WorkOrder WORecord = [select ID, WorkOrderNumber, Opportunity__c, ServiceContractId FROM WorkOrder
                                       WHERE Id = :srcRecId LIMIT 1];
                    
                    ServiceContId = WORecord.ServiceContractId;
                    OppId = WORecord.Opportunity__c;
                    WOId = WORecord.Id;
                    

                } catch (Exception e) {
                    GH_Logger.debug('Page called with invalid Work Order ID');
                }
            }
            
           	 else if (srcRecId.getSobjectType() == Opportunity.getSobjectType()) {
                GH_Logger.debug('Page called from Opp ID: ' + srcRecId);

                try {
                    
                    Opportunity OppRecord = [SELECT Id, Name, AccountId, Field_Service_Engineer__c, Attention__c, ShippingStreet__c,
                                             ShippingCity__c, ShippingState__c, ShippingPostalCode__c, BillingStreet__c,
                                             BillingCity__c, BillingState__c, BillingPostalCode__c FROM Opportunity WHERE ID =: srcRecId LIMIT 1];
                    
                    OppId = OppRecord.Id;
                    
                } catch (Exception e) {
                    GH_Logger.debug('Page called with invalid Opp ID');
                }
            }
        }


    }

    public PageReference newStdRMA() {

        GH_Logger.debug('start newRMA');
        string pageURL='';
        
        if(UITheme.contains('lightning') || Test.isRunningTest()){
            pageURL = '/lightning/o/RMA__c/new?recordTypeId=' + recordTypeId + '&defaultFieldValues='; 
            if(OppId != null){
                pageURL += 'Opportunity__c=' + OppId;
            }
           
            if(ServiceContId != null){
                if(OppId != null){
                    pageURL += ',';
                }
            	pageURL += 'Service_Contract__c=' + ServiceContId;
        	}
            if(WOId != null){
                if(OppId != null || ServiceContId != null){
                    pageURL += ',';
                }
            	pageURL += 'Work_Order__c=' + WOId;
        	}
            
        
        }
        else{
            pageURL = '/a0m/e?&retURL=%2F0WO%2Fo&RecordType=' + recordTypeId + '&ent=RMA__c'; 
            
        }

        
        
        PageReference pr = new PageReference(pageURL);
        pr.getParameters().put('nooverride', '1');
        if(!UItheme.contains('lightning')){
            
            if(OppId != null){
            	pr.getParameters().put('00NU0000004lVwO', OppId);
        	}
            if(ServiceContId != null){
            	pr.getParameters().put('00N4O000006VvXO', ServiceContId);
        	}
            if(WOId != null){
            	pr.getParameters().put('00N5b00000DWmm2', WOId);
        	}
            
            
        }

        

        GH_Logger.debug('end newRMA with URL: ' + pr.getUrl());

        return pr;

    }

    
}