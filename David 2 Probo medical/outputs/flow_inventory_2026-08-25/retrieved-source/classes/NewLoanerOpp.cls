public class NewLoanerOpp {

    Opportunity Repairopp;
    String OppId;
    String Oppname;
    String rt;
    String AssetNo;
    String Model;


    public NewLoanerOpp(ApexPages.StandardController controller) {
        OppId = ApexPages.currentPage().getParameters().get('id');
        System.debug('THIS IS THE OPP ID >>> ' + OppId);

        for (RecordType r : ProboCommonUtils.getRecordTypes('Opportunity')){
            if (r.Name == 'Probe Sales Opportunity'){
                rt = r.Id;
                break;
            }
        }

        Repairopp = [select Id, Name, AccountId, LeadSource, Primary_Contact_ID__c, Related_Opportunity__c,
                Account.Name, Account.ShippingStreet, Account.ShippingCity, Account.ShippingState,
                Account.ShippingPostalCode, Account.ShippingCountry
        from Opportunity where Id = :OppId];

        List<OpportunityLineItem> Assets = [select Id, ProductItem__c, OpportunityId, ProductItem__r.Product2_Name__c
        from OpportunityLineItem where OpportunityId = :OppId];


        system.debug('NewLoanerOpp ctor found this many OLIs for the RepairOpp: ' + Assets.size());
        if (Assets.size() == 1) {
            system.debug('The first OLIs has a ProductItem__c ID: ' + Assets[0].ProductItem__c);
            AssetNo = Assets[0].ProductItem__c;
            if (Assets[0].ProductItem__c != null){
                Model = Assets[0].ProductItem__r.Product2_Name__c;
            }
        }

        if (Model != null) {
            Oppname = Model + ' LOANER SN #';
        } else {
            Oppname = Repairopp.Account.Name + ' LOANER SN #';
        }

    }

    public PageReference newLoaner() {

        Opportunity LoanerOpp = new Opportunity(AccountId = Repairopp.AccountId, Name = Oppname,
                CloseDate = Date.today(),
                StageName = 'Proposal/Price Quote',
                RecordTypeId = rt,
                ShippingStreet__c = Repairopp.Account.ShippingStreet,
                ShippingCity__c = Repairopp.Account.ShippingCity,
                ShippingState__c = Repairopp.Account.ShippingState,
                ShippingPostalCode__c = Repairopp.Account.ShippingPostalCode,
                ShippingCountry__c = Repairopp.Account.ShippingCountry,
                Related_Opportunity__c = OppId,
                LeadSource = Repairopp.LeadSource,
                Primary_Contact_ID__c = Repairopp.Primary_Contact_ID__c,
                SubType__c = 'Loaner');

        system.debug('NewLoanerOpp.newLoaner() is working with this AssetNo: ' + AssetNo);
        if (AssetNo != null) {
            LoanerOpp.Related_Asset__c = AssetNo;
        }

        insert LoanerOpp;

        if (Repairopp.Related_Opportunity__c == null){
            System.debug('Setting Repair Opp related Opportunity to Loaner Opp ID');
            Repairopp.Related_Opportunity__c = LoanerOpp.Id;
            update Repairopp;
        }

        PageReference pr = new PageReference('/' + LoanerOpp.Id);

        return pr;
    }
}