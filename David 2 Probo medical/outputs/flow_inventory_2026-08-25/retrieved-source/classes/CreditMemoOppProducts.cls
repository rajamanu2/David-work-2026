public class CreditMemoOppProducts {
    public List<Credit_Memo_Line_Item__c> lineItems { get; set; }
    
    Public CreditMemoOppProducts( ApexPages.StandardController std )
	{
		if( std.getRecord().Id != null )
		{   
			Credit_Memo__c con = [ Select Id, Opportunity__c from Credit_Memo__c where Id =: std.getRecord().Id ];
			
			lineItems = [ Select Id,Credit_Memo_Line_Amount__c,Product_Name__c,Opportunity_Product__r.Product_Description__c,RMA__r.RMA_Item_Serial_Number__c from Credit_Memo_Line_Item__c where Credit_Memo__c =: std.getRecord().Id ];
		}
		else
		{
			lineItems = new List<Credit_Memo_Line_Item__c>();
		}
    }         
}