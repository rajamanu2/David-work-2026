public class SourcingRequest {

    // Hardcoded URLs fixed, DML in loop fixed, no SOQL issue

    id LineItemId, OppId;
    Integer ForNumber, QuantityNeeded;

    String OppName, ProductID, AssetNo, OppName2;
    Date ReadyDate;

    public SourcingRequest(ApexPages.StandardController controller) {
        LineItemId = ApexPages.currentPage().getParameters().get('id');
        system.debug('THIS IS THE LINE ITEM ID >>> ' + lineitemid);

        OpportunityLineItem lineitem = [
                select id, Quantity, OpportunityID, Opportunity_Name__c,
                        ProductItem__c, Asset_No__c
                from OpportunityLineItem
                where id = :lineitemid
                limit 1
        ];

        system.debug('THIS IS THE LINE ITEM >>> ' + lineitem);
        Opportunity opp = [select id, Name, Estimated_Ready_Date__c from Opportunity where id = :lineitem.OpportunityID];
        system.debug('THIS IS THE OPP >>> ' + opp);
        if (opp.Estimated_Ready_Date__c != null) {
            ReadyDate = opp.Estimated_Ready_Date__c;
        }
        QuantityNeeded = integer.valueof(lineitem.Quantity);
        OppName = opp.Name;
        OppName2 = '';
        ForNumber = OppName.indexOfIgnoreCase('#');
        if (ForNumber != null) {
            OppName2 = OppName.right(OppName.length() - ForNumber - 1);
            OppName = OppName.left(ForNumber) + '%23+';

        }

        OppId = opp.id;
        ProductID = lineitem.ProductItem__c;
        AssetNo = lineitem.Asset_No__c;
        system.debug('THIS IS THE PRODUCT ID >>> ' + ProductID);
        system.debug('THIS IS THE OPP NAME >>> ' + oppname);
        system.debug('THIS IS THE OPP NAME 2 >>> ' + oppname2);
    }

    public PageReference NewRequest() {
        List<Sourcing_Request_Item__c> sriToInsert = new List<Sourcing_Request_Item__c>();

        for (integer i = 0; i < QuantityNeeded; i++) {
            Sourcing_Request_Item__c newSRI = new Sourcing_Request_Item__c(Generic_Item__c = ProductID,
                    Requesting_Opportunity__c = OppId,
                    Need_By_Date__c = ReadyDate,
                    Condition_Requested__c = 'Used');

            sriToInsert.add(newSRI);
        }

        if (!sriToInsert.isEmpty()) {
            insert sriToInsert;
        }

        //PageReference pr = new PageReference('http://cs13.salesforce.com/'+OppId);
        //PageReference pr = new PageReference('http://na48.salesforce.com/'+OppId);
        PageReference pr = new PageReference('/' + OppId);

        return pr;

    }
}