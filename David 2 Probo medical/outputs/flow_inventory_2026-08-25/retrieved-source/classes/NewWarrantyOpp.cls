public class NewWarrantyOpp {
    Opportunity OriginalOpp;
    String OppId;
    String Oppname;
    String rt;
    String AssetNo;
    String Model;

    public NewWarrantyOpp(ApexPages.StandardController controller){
        OppId = ApexPages.currentPage().getParameters().get('id');
         System.debug('THIS IS THE OPP ID >>> ' + Oppid);

        for (RecordType r : ProboCommonUtils.getRecordTypes('Opportunity')){
            if (r.Name == 'Sales Opportunity'){
                RT = r.Id;
                break;
            }
        }

        OriginalOpp = [select id, name, AccountId, LeadSource, Primary_Contact_ID__c,
                 Account.name, Account.ShippingStreet, Account.ShippingCity, Account.ShippingState,
                 Account.ShippingPostalCode, Account.ShippingCountry
         from Opportunity where id=:Oppid];

        List<OpportunityLineItem> Assets = [select Id, ProductItem__c, ProductItem__r.Product2_Name__c
                                            from OpportunityLineItem
                                            where OpportunityID =: OppId
                                            AND Check_In_Type__c != 'Generic'];

        System.debug('Found this many OLIs on the source Opp: ' + Assets.size());
        if(Assets.size()==1){
            AssetNo = Assets[0].ProductItem__c;
            if (Assets[0].ProductItem__c != null){
                Model = Assets[0].ProductItem__r.Product2_Name__c;
            }
        }

        if(Model != null){
            OppName = Model + ' WARRANTY SN #';
        } else {
            OppName = OriginalOpp.Account.Name + ' WARRANTY SN #';
        }

    }
      
    public PageReference newWarranty(){

        Opportunity WarrantyOpp = new Opportunity(AccountId = OriginalOpp.AccountId, Name = Oppname,
                CloseDate = Date.Today(),
                StageName = 'Proposal/Price Quote',
                RecordTypeId = RT,
                ShippingStreet__c = OriginalOpp.Account.ShippingStreet,
                ShippingCity__c = OriginalOpp.Account.ShippingCity,
                ShippingState__c = OriginalOpp.Account.ShippingState,
                SubType__c = 'Warranty',
                ShippingPostalCode__c = OriginalOpp.Account.ShippingPostalCode,
                ShippingCountry__c = OriginalOpp.Account.ShippingCountry,
                Related_Opportunity__c = OppID,
                LeadSource = OriginalOpp.LeadSource,
                Primary_Contact_ID__c = OriginalOpp.Primary_Contact_ID__c);

        if(AssetNo != null){
            WarrantyOpp.Related_Asset__c = AssetNo;
        }
        insert WarrantyOpp;

        OriginalOpp.Related_Opportunity__c = WarrantyOpp.Id;
        OriginalOpp.Related_Asset__c = AssetNo;

        update OriginalOpp;

        PageReference pr = new PageReference('/'+WarrantyOpp.Id);

        return pr;
    }
}