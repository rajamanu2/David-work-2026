public class NewRentalOpp {
	private static Opportunity OriginalOpp {get; set;}
    private static String OppId {get; set;}
    private static String Oppname {get; set;}
    private static String rentalOppRecordType {get; set;}
    private static String AssetNo {get; set;}
    private static String Model {get; set;}
    private static String rentalReturnRMARecordType {get; set;}
    private static List<OpportunityLineItem> Assets {get; set;}

    public NewRentalOpp(ApexPages.StandardController controller){
        OppId = ApexPages.currentPage().getParameters().get('id');
        System.debug('THIS IS THE OPP ID >>> ' + Oppid);
        
        rentalOppRecordType = RecordTypeUtility.getRecordTypeByDeveloperName('Opportunity', 'Rental_Opportunity');

        OriginalOpp = [select id, name, AccountId, LeadSource, Primary_Contact_ID__c,
                 Account.name, Account.ShippingStreet, Account.ShippingCity, Account.ShippingState,
                 Account.ShippingPostalCode, Account.ShippingCountry
         from Opportunity where id=:Oppid];

        Assets = [select Id, ProductItem__c, ProductItem__r.Product2_Name__c, ProductItem__r.Serial_No__c
                                            from OpportunityLineItem
                                            where OpportunityID =: OppId
                                            AND Check_In_Type__c != 'Generic'];

        System.debug('Found this many OLIs on the source Opp: ' + Assets.size());
        if(Assets.size() == 1){
            AssetNo = Assets[0].ProductItem__c;
            if (Assets[0].ProductItem__c != null){
                Model = Assets[0].ProductItem__r.Product2_Name__c;
            }
        }

        if(Model != null){
            OppName = Model + ' RENTAL SN #';
        } else {
            OppName = OriginalOpp.Account.Name + ' RENTAL SN #';
        }

    }
      
    public PageReference newRental(){

        Opportunity RentalOpp = new Opportunity(AccountId = OriginalOpp.AccountId, Name = Oppname,
                CloseDate = Date.Today(),
                StageName = 'Proposal/Price Quote',
                RecordTypeId = rentalOppRecordType,
                ShippingStreet__c = OriginalOpp.Account.ShippingStreet,
                ShippingCity__c = OriginalOpp.Account.ShippingCity,
                ShippingState__c = OriginalOpp.Account.ShippingState,
                ShippingPostalCode__c = OriginalOpp.Account.ShippingPostalCode,
                ShippingCountry__c = OriginalOpp.Account.ShippingCountry,
                Related_Opportunity__c = OppID,
                LeadSource = OriginalOpp.LeadSource,
                Primary_Contact_ID__c = OriginalOpp.Primary_Contact_ID__c);

        if(AssetNo != null){
            RentalOpp.Related_Asset__c = AssetNo;
        }
        insert RentalOpp;

        OriginalOpp.Related_Opportunity__c = RentalOpp.Id;
        OriginalOpp.Related_Asset__c = AssetNo;

        update OriginalOpp;
        
        PageReference pr = new PageReference('/'+ RentalOpp.Id);

        return pr;
    }
}