@isTest
public class ItemReceiptTriggerTest {
    @isTest
    Public Static Void ItemReceiptTest1(){
        
        Account acc = TestDataFactory.createAccount(false); 
        acc.Accounting_Contact_E_mail__c = 'Test@Test.com';
        insert acc;
        
        Contact cont = new Contact(FirstName='Brandon',LastName='Weaver',email='brandon@delegate.team');
        insert cont;

        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acc.Id, false);
        opp.Repair_Evaluation_Serial_Number__c = '1234';
        opp.StageName = 'Proposal/Price Quote';
        opp.Primary_Contact_ID__c = cont.id;
        opp.Customer_Probe__c = true;
        opp.White_Glove_Service__c = true;
        opp.Opportunity_Notes__c = 'Test Stuff';
        insert opp;
        
        Item_Receipt__c ItemReceiptToInsert = new Item_Receipt__c(Opportunity__c = opp.id);
        Insert ItemReceiptToInsert;
        
        ItemReceiptToInsert.Intacct_Receipt_Sync_Status__c = 'Sync';
        Update ItemReceiptToInsert;               
    }

}