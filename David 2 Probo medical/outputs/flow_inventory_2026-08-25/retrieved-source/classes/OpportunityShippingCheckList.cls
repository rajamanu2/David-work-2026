public class OpportunityShippingCheckList {
    Public String oppid {get;set;}
    Public String Notes {get;set;}
    Public String customerPO {get;set;}
    public list<OpportunityLineItem> OppProducts {get;set;}
    public list<string> HeaderInfo {get;set;}

    public OpportunityShippingCheckList(ApexPages.StandardController controller){
        OppId = ApexPages.currentPage().getParameters().get('id');
        system.debug('THIS IS THE OPP ID >>>> ' + oppid);
        OppProducts = [select id, Opportunity_Number__c, Opportunity_Name__c, Opportunity_Record_Type__c, Check_In_Type__c,
                Opportunity_Owner__c, Account_Name__c, White_Glove_Service__c, Asset_No__c,
                ProductItem__c, Product_Name__c, Location__c, Ship_Date__c, Estimated_Ready_Date__c,
                ProductItem__r.Serial_No__c, ProductItem__r.Part_number__c,  Opportunity.Customer_PO__c 
        from OpportunityLineItem where OpportunityID =:oppid];
		
        HeaderInfo = new List<String>();
        if (!OppProducts.isEmpty()){
            customerPO = '';
            if(OppProducts[0].Opportunity.Customer_PO__c != null){
                customerPO = OppProducts[0].Opportunity.Customer_PO__c;
            }
			HeaderInfo.add('Customer PO');
            HeaderInfo.add(customerPO);
            system.debug('THIS IS THE OPP PRODUCTS >>> ' + OppProducts[0].Opportunity_Number__c);
            HeaderInfo.add('Opportunity No');
            HeaderInfo.add(OppProducts[0].Opportunity_Number__c);
            system.debug('THIS IS THE OPP NO >>> ' + HeaderInfo);
            HeaderInfo.add('Opportunity Name');
            HeaderInfo.add(OppProducts[0].Opportunity_Name__c);
            system.debug('THIS IS THE OPP NAME >>> ' + HeaderInfo);
            HeaderInfo.add('Opportunity Type');
            HeaderInfo.add(OppProducts[0].Opportunity_Record_Type__c);
            system.debug('THIS IS THE OPP TYPE >>> ' + HeaderInfo);
            HeaderInfo.add('Opportunity Owner');
            HeaderInfo.add(OppProducts[0].Opportunity_Owner__c);
            system.debug('THIS IS THE OPP OWNER >>> ' + HeaderInfo);
            HeaderInfo.add('Customer Name');
            HeaderInfo.add(OppProducts[0].Account_Name__c);
            system.debug('THIS IS THE ACCOUNT >>> ' + HeaderInfo);
            HeaderInfo.add('White Glove Service?');
            if(OppProducts[0].White_Glove_Service__c == true){
                HeaderInfo.add('YES');
            } else {
                HeaderInfo.add('NO');
            }
            system.debug('THIS IS THE WGS >>> ' + HeaderInfo);
            HeaderInfo.add('Ship Date');
            if(OppProducts[0].Ship_Date__c != null){
                HeaderInfo.add(String.valueof(OppProducts[0].Ship_Date__c));
            } else {
                HeaderInfo.add('No ship date provided');
            }
            system.debug('THIS IS THE SHIP DATE >>> ' + HeaderInfo);
            HeaderInfo.add('Estimated Ready Date');
            if(OppProducts[0].Estimated_Ready_Date__c != null){
                HeaderInfo.add(String.valueof(OppProducts[0].Estimated_Ready_Date__c));
            } else {
                HeaderInfo.add('No estimated ready date provided');
            }
        }
        system.debug('THIS IS THE ESTIMATED READY DATE >>> ' + HeaderInfo);

    }
}