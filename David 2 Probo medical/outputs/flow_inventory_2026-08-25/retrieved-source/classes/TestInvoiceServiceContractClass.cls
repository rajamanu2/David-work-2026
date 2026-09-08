@isTest
public class TestInvoiceServiceContractClass {
	@isTest static void testAccountOpportunity(){
       Account Acc = TestDataFactory.createAccount(FALSE);
       insert Acc;
       ServiceContract ServCon = new ServiceContract(Name='Test Contract',AccountId=Acc.id,RecordTypeId='0124O000000obTmQAI',Contract_Billing__c='Monthly',Pricebook2Id='01sU00000001dZOIAY');
       insert ServCon;
       ContractLineItem CLI = new ContractLineItem(PricebookEntryId='01u0B00000sgysRQAQ',UnitPrice=5,Quantity=1,ServiceContractId=ServCon.id);
       insert CLI;
       Opportunity opp = new Opportunity();
            opp.Pricebook2Id = '01sU00000001dZOIAY';
            opp.AccountId = Acc.id;
            opp.Name = 'Test Opportunity';
            opp.StageName = 'Prospecting';
            opp.CloseDate = system.today() + 21;
            opp.Amount = 50;
            opp.TotalOpportunityQuantity = 7;
            opp.Shipping_FROM_Location__c = 'Fishers, IN';
            opp.LeadSource = 'Other';
            opp.BillingStreet__c = '1234 Main';
            opp.BillingCity__c = 'Denver';
            opp.BillingState__c = 'CO';
            opp.BillingPostalCode__c = '12345';
            opp.BillingCountry__c = 'US';
            opp.ShippingStreet__c = '1234 Main';
            opp.ShippingCity__c = 'Denver';
            opp.ShippingState__c = 'CO';
            opp.ShippingPostalCode__c = '12345';
            opp.ShippingCountry__c = 'US';
            opp.Shipping_Cost__c = 20;
       		opp.Service_Contract__c = ServCon.id;
       insert opp;
       Invoice__c ac = new Invoice__c();
       ac.Opportunity__c = opp.id;
       insert ac;       
      //AccountNew is the Visualforce page created
       PageReference testPage = Page.Service_Contract_Invoice_PDF; 
       Test.setCurrentPage(testPage);
       testPage.getParameters().put('Id', String.valueOf(ac.Id));
       
       ApexPages.StandardController sc = new  ApexPages.StandardController(ac);     
       ServiceContractInvoiceLineItems ext = new ServiceContractInvoiceLineItems(sc);         
   } 
}