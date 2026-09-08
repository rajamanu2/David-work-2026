public class NewOppLightningStandardCtrl {

    String Stage, accountName, shippingAccount, leadSrc, OppName, ShipType, closeDateString, UITheme, warrantyLength, fieldServiceEngineer, FSEEmail;
    Id accountid, recordTypeId, contactId, salesRecordTypeId;

    private transient Id srcRecId;
    
    

    public NewOppLightningStandardCtrl(ApexPages.StandardController controller) {
        GH_Logger.debug('start single record NewOppStandardCtrl ctor');

        init(true);
    }

    public NewOppLightningStandardCtrl(ApexPages.StandardSetController controller) {
        GH_Logger.debug('start list NewOppStandardCtrl Set ctor');

        init(false);
    }

    private void init(Boolean isStd){
		
        Stage = 'Proposal/Price Quote';
        OppName = 'Enter the name here';
        leadSrc = 'NEW';
        
        
        UITheme = URL.getCurrentRequestUrl().toExternalForm();
        if(UItheme.contains('lightning')){
            closeDateString = Date.today().year() + '-' + Date.today().month() + '-' + Date.today().day();
        }
        else{
            closeDateString = Date.today().month() + '/' + Date.today().day() + '/' + Date.today().year();
        }
		
        
        srcRecId = ApexPages.currentPage().getParameters().get('id');
        

        // if we didn't come from a list button, see if we came from a record (like the New button on the Opp list for Account)
        if (srcRecId == null){
            srcRecId = ApexPages.currentPage().getParameters().get('accid');
        }

        if (srcRecId == null){
            srcRecId = ApexPages.currentPage().getParameters().get('contid');
        }

        GH_Logger.debug('Source Record: ' + srcRecId);

        GH_Logger.debug('Deciding the Opp Rec Type to use');

        recordTypeId = ApexPages.currentPage().getParameters().get('RecordType');
        GH_Logger.debug('Selected Record Type: ' + recordTypeId);

        RecordType salesOppRecType;
        RecordType probeSalesOppRecType;
        RecordType purchasingOppRecType;
        RecordType materialTransferRecType;

        for (RecordType r : ProboCommonUtils.getRecordTypes('Opportunity')) {

            if (r.IsActive) {
                switch on r.DeveloperName {
                    when 'Sales_Opportunity' {
                        salesOppRecType = r;
                    }
                    when 'Probe_Sales_Opportunity' {
                        probeSalesOppRecType = r;
                    }
                    when 'Purchasing_Opportunity' {
                        purchasingOppRecType = r;
                    }
                    when 'Material_Transfer' {
                        materialTransferRecType = r;
                    }
                }
            }
        }

        if (recordTypeId == null) {
            recordTypeId = ProboCommonUtils.getCurrentUser().Profile.Name.containsIgnoreCase('Purchasing') ? purchasingOppRecType.Id : probeSalesOppRecType.Id;
            
        }
        if(salesRecordTypeId == null){
            salesRecordTypeId = salesOppRecType.id;
        }
		system.debug('THIS IS THE RECORD TYPE ID >>> ' + recordtypeID);
        if (recordTypeId == materialTransferRecType.Id) {

            OppName = 'Material Transfer';

            if(isStd){
                ShipType = 'Fedex Ground';
            }
        }

        // get some default values based on the record we were launched from
        if (srcRecId != null) {

            if (srcRecId.getSobjectType() == Account.getSobjectType()) {
                GH_Logger.debug('Page called from Account ID: ' + srcRecId);

                try {
                    Account acct = [SELECT Id, Name, Lead_Source__c, Shipping_Acct__c, Standard_Warranty_Length__c, Field_Service_Engineer__c 
                                    FROM Account WHERE Id = :srcRecId LIMIT 1];
                    accountid = acct.Id;
                    accountName = acct.Name;
                    OppName = accountName;
                    leadSrc = acct.Lead_Source__c;
                    warrantyLength = acct.Standard_Warranty_Length__c;
                    fieldServiceEngineer = acct.Field_Service_Engineer__c;
                    shippingAccount = acct.Shipping_Acct__c;
                    if(fieldServiceEngineer != null){
                        List<String> lstFSE = fieldServiceEngineer.split(' ');
                        String secondPart ='';
                        if(lstFSE.size () >= 2){
                            secondPart = lstFSE[1];
                        }   
                        FSEEmail =  fieldServiceEngineer.substring(0,1) + secondPart + '@probomedical.com';
                 
                    }
                    
                } catch (Exception e) {
                    GH_Logger.debug('Page called with invalid Account ID');
                }

            } else if (srcRecId.getSobjectType() == Contact.getSobjectType()) {
                GH_Logger.debug('Page called from Contact ID: ' + srcRecId);

                try {
                    Contact cont = [SELECT Id, AccountId, Account.Name, Name, LeadSource, Account.Standard_Warranty_Length__c, Account.Field_Service_Engineer__c, Account.Shipping_Acct__c FROM Contact WHERE Id = :srcRecId LIMIT 1];
                    accountid = cont.AccountId;
                    accountName = cont.Account.Name;
                    OppName = accountName;
                    contactId = cont.Id;
                    leadSrc = cont.LeadSource;
                    warrantyLength = cont.Account.Standard_Warranty_Length__c;
                    fieldServiceEngineer = cont.Account.Field_Service_Engineer__c;
                    shippingAccount = cont.Account.Shipping_Acct__c;
                    if(fieldServiceEngineer != null){
                        List<String> lstFSE = fieldServiceEngineer.split(' ');
                        String secondPart ='';
                        if(lstFSE.size () >= 2){
                            secondPart = lstFSE[1];
                        }   
                        FSEEmail =  fieldServiceEngineer.substring(0,1) + secondPart + '@probomedical.com';
                 
                    }

                } catch (Exception e) {
                    GH_Logger.debug('Page called with invalid Contact ID');
                }
            }
        }


    }

    public PageReference newStdOpp() {

        
        string pageURL='';
        if(oppname.contains(',')){
            oppname=oppname.replace(',','');
        }
        
        if(UITheme.contains('lightning')){
            pageURL = '/lightning/o/Opportunity/new?recordTypeId=' + recordTypeId + '&defaultFieldValues=Name=' + oppname + ',CloseDate=' + CloseDateString + ',StageName=' + Stage; 
        	if(accountId != null){
            	pageURL += ',AccountId=' + AccountId;
        	}
            if(contactID != null){
                pageURL += ',Contact_Lookup__c=' + contactID;
            }
        
            if(leadSrc != null){
                pageURL += ',Sales_Lead_Source__c=' + leadSrc;
            }
        
            if(warrantyLength != null){
                pageURL += ',Warranty_Length__c=' + warrantyLength;
            }
            
            if(fieldServiceEngineer != null){
                pageURL += ',Field_Service_Engineer__c=' + fieldServiceEngineer;
            }
            
            if(FSEEmail != null){
                pageURL += ',FSE_Email__c=' + FSEEmail;
            }
            
            
            if(ShipType != null){
                pageURL += ',Ship_Type__c=' + ShipType;
            }
            if(shippingAccount != null){
                pageURL += ',Shipping_Account_Number__c=' + shippingAccount;
            }
        
        }
        else{
            pageURL = '/006/e?&retURL=%2F006%2Fo&RecordType=' + recordTypeId + '&ent=Opportunity'
                    + '&opp9=' + closeDateString + '&opp11=' + Stage + '&opp3=' + OppName; //+ '&opp6=' + leadSrc;
       
                if (accountid != null){
                    pageURL += '&opp4_lkid=' + accountid + '&opp4_lkold=' + accountName;
                } 
            
		
        }

        PageReference pr = new PageReference(pageURL);
        pr.getParameters().put('nooverride', '1');
        if(!UItheme.contains('lightning')){
             if (contactId != null) {
                    pr.getParameters().put('00N0B0000066tC4', contactId);
                }
        
                if (ShipType != null) {
                    pr.getParameters().put('00NU0000004je4r', ShipType);
                }
            if(leadSrc != null){
                pr.getparameters().put('00N4O000006obJw', LeadSrc);
            }
            if(warrantyLength != null){
                //pr.getParameters().put('00N3K000000uUR8', warrantyLength); //SBPARTIAL
                pr.getParameters().put('00N5b00000DWsLD', warrantyLength); //PRODUCTION
            }
            if(fieldServiceEngineer != null){
                pr.getParameters().put('00N4O000006PSa8',fieldServiceEngineer);
            }
            
            if(FSEEmail != null){
               pr.getParameters().put('00N4O000006cUDE',FSEEmail);
            }
            if(shippingAccount != null){
                pr.getParameters().put('00N3K000000v0bM',shippingAccount);
            }
            
            
        }

        

        GH_Logger.debug('end newOpp with URL: ' + pr.getUrl());

        return pr;

    }

    public PageReference newQuickOpp() {


        Opportunity quickopp = new Opportunity(RecordTypeId = salesRecordTypeId,
                AccountId = accountid,
                CloseDate = Date.today(), StageName = Stage,
                LeadSource = leadSrc, Name = 'TEST QUICK OPP');

        if (contactId != null) {
            quickopp.Primary_Contact_ID__c = contactId;
        }

        insert quickopp;

        PageReference pr = new PageReference('/apex/AddProductLightning?');
        pr.getParameters().put('opportunityId', quickOpp.Id);
        pr.getParameters().put('action', 'add');
        
        return pr;

    }


}