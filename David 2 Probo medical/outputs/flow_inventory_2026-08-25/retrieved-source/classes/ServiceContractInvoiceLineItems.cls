public class ServiceContractInvoiceLineItems {
	public List<ContractLineItem> ContractLineItems { get; set; }
	public List<OpportunityLineItem> SortedlineItems { get; set; }
    
    Public ServiceContractInvoiceLineItems( ApexPages.StandardController std )
	{
		if( std.getRecord().Id != null )
		{
			Invoice__c con = [ Select Id, Opportunity__c from Invoice__c where Id =: std.getRecord().Id ];
			
			List<OpportunityLineItem> lineItems = [Select Id,Serial_No__c,Quantity,TotalPrice,Product2Id,Product_Name__c,Product_Description__c,UnitPrice from OpportunityLineItem where Opportunityid =: con.Opportunity__c AND Invoice2__c =: con.id];
            Opportunity Opp = [select Id, Service_Contract__c from Opportunity where Id=: con.Opportunity__c];
            ContractLineItems = [Select System_Serial_Number__c, System_Type__c, Transducers__c, Transducer_Serial__c, StartDate, EndDate from ContractLineItem where ServiceContractId =: Opp.Service_Contract__c];
            SortedLineItems = new List<OpportunityLineItem>();
            OpportunityLineItem shippingline = new OpportunityLineItem();
            for(OpportunityLineItem lineItem : lineItems){
                if(lineItem.product2Id != '01tU0000002WUUbIAO'){
                    SortedLineItems.add(lineItem);
                }
                else{
                    shippingline = lineItem;
                }
            }
            if(shippingline != NULL){
                SortedLineItems.add(shippingline);
            }
                                     
		}
		else
		{
			SortedLineItems = new List<OpportunityLineItem>();
		}
    }         
}