/**
 * Created by JR on 9/20/2018.
 */
@isTest
public class TestDataFactoryTest {

    @testSetup
    static void setup() {
        // TODO: JMAY: The TestDataFactory causes Too Many SOQL errors so we need to refactor how these methods work together
        Account a = TestDataFactory.createAccount(true);
        Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, true);
        Product2 p = TestDataFactory.createProduct('Non Inventory Item', true);
        ProductItem__c pi = TestDataFactory.createProductItem(p.Id, true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(p.Id, true);
        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(o.id, pbe.id, pi.Id, true);

        List<RMA__c> rmasToInsert = new List<RMA__c>();
        rmasToInsert.add(TestDataFactory.createRMA('Core Exchange', false));
        rmasToInsert.add(TestDataFactory.createRMA('Warranty Claim', false));
        insert rmasToInsert;


        List<Opportunity> oppList = TestDataFactory.createOpportunities(2, 'Probe Sales Opportunity', a.Id, false);
        List<PricebookEntry> pbes = TestDataFactory.createPricebookEntries(5, p.Id, true);
    }

    static testmethod void test1() {

        // JMAY: rem'd since this doesn't actually test anything
		Test.startTest();
        Account a = [SELECT Id FROM account];
        Opportunity o = [SELECT Id FROM opportunity];
        Product2 p = [SELECT Id FROM product2];
        ProductItem__c pi = [SELECT Id FROM ProductItem__c LIMIT 1];
        List<PricebookEntry> pbes = [SELECT Id FROM PricebookEntry];
        OpportunityLineItem oli = [SELECT Id, OpportunityId, ProductItem__c, PricebookEntryId  FROM OpportunityLineItem WHERE OpportunityId = :o.Id];
        List<RMA__c> rma = [SELECT Id FROM RMA__c];
        User u = TestDataFactory.createUser('First', 'Last', true);
        List<Account> accts = TestDataFactory.createAccountsWithContacts(2, 2);
        accts = TestDataFactory.createAccounts(2, true);
        List<Product2> prods = TestDataFactory.createProducts(2, 'Non Inventory Item', true);
        List<Work_Order__c> wos = TestDataFactory.createWorkOrders(2, 'Repair Work Order', pi.Id, true);
        List<ProductItem__c> pis = TestDataFactory.createProductItems(2, p.Id, true);
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(2, o.id, pbes[0].id, pi.Id, true);

        RMA__c rmaEvalNat = TestDataFactory.createRMA('Customer Repair Evaluation', false);
        rmaEvalNat.ProductItem__c = pi.Id;
        rmaEvalNat.Opportunity__c = o.Id;

        insert rmaEvalNat;
        
        Evaluation_Natalie__c en = TestDataFactory.createEvaluationNatalie(rmaEvalNat.Id, false);

        Test.stopTest();

    }
    
   	static testmethod void test2() {
        ProductItem__c pi = [SELECT Id FROM ProductItem__c LIMIT 1];		
        Product_Repair__c pr = TestDataFactory.createProductRepair('Cosmetic Repair', 'Repair Activity', pi.Id, true);
        ProductTest__c pt = TestDataFactory.createProductTest(pi.Id, true);
        ProductTestData__c ptd = TestDataFactory.createProductTestData('Orientation', 'Reversed', true);
        
        Test.startTest();
        
        Product_Repair__c pr2 = [SELECT Id, RecordTypeId, Product_Item__c, Repair_Activity__c, Repair_date__c FROM Product_Repair__c];
        ProductTest__c pt2 = [SELECT Id FROM ProductTest__c];
        ProductTestData__c ptd2 = [SELECT Id, Field_API_Value__c, Field_API_Name__c, Probe_Type__c, Rating__c FROM ProductTestData__c];
        
       	Test.stopTest();
    }
    
    static testmethod void test3() {
        ProductItem__c pi = [SELECT Id FROM ProductItem__c LIMIT 1];		
        
        Work_Order__c wo = TestDataFactory.createWorkOrder('Repair Work Order', pi.Id, true);
        
        Test.startTest();
        
		Work_Order__c wo2 = [SELECT Id, RecordTypeId, Asset__c, Person_Requesting_WO__c, Estimated_Ready_Date__c FROM Work_Order__c];
        
       	Test.stopTest();
    }
}