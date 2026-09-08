@isTest
public class SendInvoicePDFTestClass {
    @isTest 
    public static void TestSendInvoicePDF(){
        
    //Opportunity Insert    
    Opportunity OppToInsert = new Opportunity();
        OppToInsert.Name = 'Test Opp';
        OppToInsert.OwnerId = '0054O00000AADz3QAH';
        OppToInsert.StageName = 'PO Received';
        OppToInsert.CloseDate = system.today() + 1;
        OppToInsert.Pricebook2Id = '01sU00000001dZOIAY';
        OppToInsert.CurrencyISOCode = 'USD';
        //OppToInsert.Sales_Lead_Source_Detail__c = 'Inbound Call';
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

    List<Id> CreditMemoIdList = new List<Id>();
    CreditMemoIdList.add(CreditMemoToInsert.id);
    
    //Invoice Update   
        InvoiceToInsert.Send_Invoice_To__c = 'brandon@delegate.team;brandonweaver95@gmail.com';
    Update InvoiceToInsert;
        
        // Create Invoice Line Items
        List<Invoice_Line_Item__c> InvoiceLineItems = new List<Invoice_Line_Item__c>();
        Invoice_Line_Item__c InvoiceLineItem = new Invoice_Line_Item__c (
            Invoice__c=InvoiceToInsert.Id,
            Product__c=OppLineItems[0].Product2Id,
            Opportunity_Product__c=OppLineItems[0].Id,
            Unit_Price__c=OppLineItems[0].UnitPrice,
            Quantity__c=OppLineItems[0].Quantity
        );
        
        InvoiceLineItems.add(InvoiceLineItem);
        
        insert InvoiceLineItems;
        
    //Add Invoice to List
    List<Id>InvoiceList = new List<Id>();
        InvoiceList.add(InvoiceToInsert.id);
    
    Test.startTest(); 
        //SendInvoicePDF Test
        SendInvoicePDF.flowInput input = new SendInvoicePDF.flowInput();
        input.currentRecordId = invoiceList[0];
        List<String> emailStringList = new List<String>{'noreply@probomedical.com'}; 
        input.emailList = emailStringList;
        input.oppRecordId = OppToInsert.id;
        input.invoiceName = 'Test';
        input.sendFSRAttachment = false;
        List<SendInvoicePDF.flowInput> inputs = new List<SendInvoicePDF.flowInput>();
        inputs.add(input);
        List<SendInvoicePDF.flowOutput> results = SendInvoicePDF.processRecords(inputs);
        //InvoicePDFGenerator Test
        InvoicePdfGenerator.getInvoicePDF(InvoiceList);
        InvoicePdfGenerator.getInvoicePDF(InvoiceList);
        //InvoiceLineItems Test        
        ApexPages.StandardController InvoiceWithInvoiceLineItems = new ApexPages.StandardController(InvoiceToInsert);
        InvoiceLineItems objInvoiceLineItems = new InvoiceLineItems(InvoiceWithInvoiceLineItems);
        //InvoiceOppProducts Test        
        ApexPages.StandardController stdInvoice = new ApexPages.StandardController(InvoiceToInsert);
        InvoiceOppProducts objInvoiceOppProducts  = new InvoiceOppProducts(stdInvoice);
        //CreditMemoOppProducts Test
        ApexPages.StandardController stdCreditMemo = new ApexPages.StandardController(CreditMemoToInsert);
        CreditMemoOppProducts objCreditMemoProducts = new CreditMemoOppProducts(stdCreditMemo);
        //RunCreditMemoPdfGenerator
        CreditMemoPdfGenerator.getCreditMemoPDF(CreditMemoIdList);
        CreditMemoPdfGenerator.getCreditMemoPDF(CreditMemoIdList);
    Test.stopTest();
        
    }
}