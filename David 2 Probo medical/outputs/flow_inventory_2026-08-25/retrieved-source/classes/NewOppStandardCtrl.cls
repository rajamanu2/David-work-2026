public class NewOppStandardCtrl {

    String Stage, accountName, leadSrc, OppName, ShipType, closeDateString;
    Id accountid, recordTypeId, contactId, salesRecordTypeId;

    private transient Id srcRecId;

    public NewOppStandardCtrl(ApexPages.StandardController controller) {
        GH_Logger.debug('start single record NewOppStandardCtrl ctor');

        init(true);
    }

    public NewOppStandardCtrl(ApexPages.StandardSetController controller) {
        GH_Logger.debug('start list NewOppStandardCtrl Set ctor');

        init(false);
    }

    private void init(Boolean isStd){

        Stage = 'Proposal/Price Quote';
        OppName = 'Enter the name here';
        leadSrc = 'NEW';
        closeDateString = Date.today().month() + '/' + Date.today().day() + '/' + Date.today().year();

        srcRecId = ApexPages.currentPage().getParameters().get('id');

        // if we didn't ome from a list button, see if we came from a record (like the New button on the Opp list for Account)
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

        RecordType probeSalesOppRecType;
        RecordType SalesOppRecType;
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
        if(salesRecordTypeID == null){
            salesRecordTypeID = salesOppRecType.Id;
        }

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
                    Account acct = [SELECT Id, Name, Lead_Source__c FROM Account WHERE Id = :srcRecId LIMIT 1];
                    accountid = acct.Id;
                    accountName = acct.Name;
                    OppName = accountName;
                    leadSrc = acct.Lead_Source__c;
                } catch (Exception e) {
                    GH_Logger.debug('Page called with invalid Account ID');
                }

            } else if (srcRecId.getSobjectType() == Contact.getSobjectType()) {
                GH_Logger.debug('Page called from Contact ID: ' + srcRecId);

                try {
                    Contact cont = [SELECT Id, AccountId, Account.Name, Name, LeadSource FROM Contact WHERE Id = :srcRecId LIMIT 1];
                    accountid = cont.AccountId;
                    accountName = cont.Account.Name;
                    OppName = accountName;
                    contactId = cont.Id;
                    leadSrc = cont.LeadSource;
                } catch (Exception e) {
                    GH_Logger.debug('Page called with invalid Contact ID');
                }
            }
        }


    }

    public PageReference newStdOpp() {

        GH_Logger.debug('start newOpp');

        String pageURL = '/006/e?&retURL=%2F006%2Fo&RecordType=' + recordTypeId + '&ent=Opportunity'
                    + '&opp9=' + closeDateString + '&opp11=' + Stage + '&opp3=' + OppName + '&opp6=' + leadSrc;

        if (accountid != null){
            pageURL += '&opp4_lkid=' + accountid + '&opp4_lkold=' + accountName;
        }

        PageReference pr = new PageReference(pageURL);
        pr.getParameters().put('nooverride', '1');

        if (contactId != null) {
            pr.getParameters().put('00N0B0000066tC4', contactId);
        }

        if (ShipType != null) {
            pr.getParameters().put('00NU0000004je4r', ShipType);
        }

        GH_Logger.debug('end newOpp with URL: ' + pr.getUrl());

        return pr;

    }

    public PageReference newQuickOpp() {


        Opportunity quickopp = new Opportunity(RecordTypeId = salesRecordTypeID,
                AccountId = accountid,
                CloseDate = Date.today(), StageName = Stage,
                LeadSource = leadSrc, Name = 'TEST QUICK OPP');

        if (contactId != null) {
            quickopp.Primary_Contact_ID__c = contactId;
        }

        insert quickopp;

        return new PageReference('/apex/AddProductPage');

    }

}