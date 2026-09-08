public class InvoiceLineItems {
    public List<Invoice_Line_Item__c> lineItems { get; set; }
    
    Public InvoiceLineItems( ApexPages.StandardController std )
	{
        lineItems = new List<Invoice_Line_Item__c>();
        
		if( std.getRecord().Id != null )
		{   
			Invoice__c con = [ Select Id, Opportunity__c from Invoice__c where Id =: std.getRecord().Id ];
			
			lineItems = [ Select Id, Product__c, Product_Name__c, Serial_No__c, Quantity__c, Unit_Price__c, Total_Price__c from Invoice_Line_Item__c where Invoice__c =: std.getRecord().Id ];
		}
    }         
}