@isTest
public class SendInvoiceToLockstepTestClass {
	@isTest 
    public static void TestSendInvoiceToLockstepPDF(){
        
    //Opportunity Insert    
    Opportunity OppToInsert = new Opportunity();
        OppToInsert.Name = 'Test Opp';
        OppToInsert.OwnerId = '0054O00000AADz3QAH';
        OppToInsert.StageName = 'PO Received';
        OppToInsert.CloseDate = system.today() + 1;
        OppToInsert.Pricebook2Id = '01sU00000001dZOIAY';
    Insert OppToInsert;
    
    //Opportunity Line Items Insert    
    List<OpportunityLineItem> OppLineItems = new List<OpportunityLineItem>();
    OpportunityLineItem OppLineItemToInsert1 = new OpportunityLineItem();
        OppLineItemToInsert1.product2id = '01tU0000002WUUbIAO';
        OppLineitemToInsert1.OpportunityId = OppToInsert.Id;
        OppLineitemToInsert1.Quantity = 1;
        OppLineitemToInsert1.UnitPrice = 1.00;
        OppLineitemToInsert1.PricebookEntryId = '01uU000000CaUd9IAF';
        OppLineItems.add(OppLineItemToInsert1);
        
    OpportunityLineItem OppLineItemToInsert2 = new OpportunityLineItem();
        OppLineItemToInsert2.product2id = '01t0B000007cftJQAQ';
        OppLineitemToInsert2.OpportunityId = OppToInsert.Id;
        OppLineitemToInsert2.Quantity = 1;
        OppLineitemToInsert2.UnitPrice = 1.00;
        OppLineitemToInsert2.PricebookEntryId = '01u0B00000sgTEXQA2';
      	OppLineItems.add(OppLineItemToInsert2); 
        
    insert OppLineItems;
        
    //Invoice Insert
    Invoice__c InvoiceToInsert = new Invoice__c();
        InvoiceToInsert.RecordTypeId = '0124O000000tDwqQAE';
        InvoiceToInsert.OwnerId = '0054O00000AADz3QAH';
        InvoiceToInsert.Opportunity__c = OppToInsert.id;
    Insert InvoiceToInsert;
        
    //Credit Memo Insert
    Credit_Memo__c CreditMemoToInsert = new Credit_Memo__c();
        CreditMemoToInsert.OwnerId = '0054O00000AADz3QAH';
        CreditMemoToInsert.Opportunity__c = OppToInsert.id;
    Insert CreditMemoToInsert;
        
    //Invoice Update   
        InvoiceToInsert.Send_Invoice_To__c = '82270018-ce49-4d36-86b1-8985ee2f7602@my.anytimecollect.com;';
    Update InvoiceToInsert;
        
    //Add Invoice to List
    List<Id>InvoiceList = new List<Id>();
        InvoiceList.add(InvoiceToInsert.id);
    
    Test.startTest(); 
        //SendInvoicePDF Test
    	SendInvoiceToLockstep.SendInvoicePDFtoLockstep(InvoiceList);
        //InvoicePDFGenerator Test
        InvoicePdfGenerator.getInvoicePDF(InvoiceList);
        InvoicePdfGenerator.getInvoicePDF(InvoiceList);
        //InvoiceOppProducts Test        
		ApexPages.StandardController stdInvoice = new ApexPages.StandardController(InvoiceToInsert);
	   	InvoiceOppProducts objInvoiceOppProducts  = new InvoiceOppProducts(stdInvoice);
        //CreditMemoOppProducts Test
        ApexPages.StandardController stdCreditMemo = new ApexPages.StandardController(CreditMemoToInsert);
        CreditMemoOppProducts objCreditMemoProducts = new CreditMemoOppProducts(stdCreditMemo);
    Test.stopTest();
        
    }
}