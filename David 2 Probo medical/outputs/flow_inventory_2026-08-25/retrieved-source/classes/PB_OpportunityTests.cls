/**
* @author Delagate
* @date 4/26/2021
*
* @description Tests for testing PB Opportunity
*/

@isTest
public with sharing class PB_OpportunityTests {
    @isTest
    public static void InsertOpportunity() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        acct.Tax_Exempt_States__c = 'Colorado';
        acct.Tax_Exemption_Form_Attached__c = true;
        try {
            insert acct;
        } catch(Exception ex) {
            acct.Tax_Exempt_States__c = 'CO';
            insert acct;
        }
        System.debug('T:' + acct);
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, false);
        opp.Account = acct;
        insert opp;
        test.stopTest();
    }
    @isTest
    public static void SetTaxTests() {
        test.startTest();
        List<Account> accts = TestDataFactory.createAccounts(1, true); 
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', accts[0].Id, true);
        opp.Amount = 100;
        update opp;
        test.stopTest();
    }
    @isTest
    public static void TestSetTax() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        acct.Tax_Exempt_States__c = 'Colorado';
        acct.Tax_Exemption_Form_Attached__c = true;
        try {
            insert acct;
        } catch(Exception ex) {
            acct.Tax_Exempt_States__c = 'CO';
            insert acct;
        }
        System.debug('T:' + acct);
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, false);
        opp.Account = acct;
        insert opp;
        System.debug('T2:' + opp.Account);
        opp.ShippingState__c = 'CO';
        opp.AVA_SFCLOUD__Sales_Tax__c = 600;
        update opp;
        test.stopTest();
    }
    @isTest
    public static void TestStageTimeStamp() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        insert acct;
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
        opp.StageName = 'Closed Lost';
        opp.Reason_Lost__c = 'Credit Memo';
        update opp;
        test.stopTest();
    }
    @isTest
    public static void TestSetWebLeadSource() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        insert acct;
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
        opp.LeadSource = 'httP://www.google.com';
        update opp;
        test.stopTest();
    }
    @isTest
    public static void TestRenameInterCompany() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        insert acct;
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
        opp.Name = 'Material Transfer';
        update opp;
        test.stopTest();
    }
    @isTest
    public static void TestSetCountry() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        insert acct;
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
        opp.ShippingState__c = 'CO';
        opp.ShippingCountry__c = null;
        update opp;
        test.stopTest();
    }
    @isTest
    public static void TestSignature() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        insert acct;
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
        opp.Signature_Type__c = 'eSignature';
        update opp;
        test.stopTest();
    }
    /*@isTest
    public static void TestSystemDeal() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        insert acct;
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
        opp.Products__c = Ultrasound_Systems__c + Ultrasound_Probes__c;
        opp.StageName = 'Sold but not Shipped';
        opp.Ship_Date__c = System.today();
        update opp;
        test.stopTest();
    }*/
    @isTest
    public static void TestShipType() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        insert acct;
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
        opp.Ship_Type__c = 'Vendor Shipped';
        update opp;
        test.stopTest();
    }
    @isTest
    public static void TestPurchaseOppName() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        insert acct;
        Opportunity opp = TestDataFactory.createOpportunity('Purchasing Opportunity', acct.Id, true);
        opp.PO__c = 'PX1234';
        update opp;
        test.stopTest();
    }
    @isTest
    public static void TestFinaizeTrans() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        insert acct;
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
        opp.StageName = 'Verbal Acceptance';
        opp.Confirmation_number__c = 'Test';
        update opp;
        test.stopTest();
    }
    @isTest
    public static void TestPendingApproval() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        insert acct;
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
        opp.Date_Repair_Evaluation_Sent_to_Customer__c = System.today();
        update opp;
        test.stopTest();
    }
    @isTest
    public static void TestEvaluationComplete() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        insert acct;
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
        opp.Date_Repair_Evaluation_Sent__c = System.today();
        update opp;
        test.stopTest();
    }
    @isTest
    public static void TestRepairApproved() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        insert acct;
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
        opp.Date_Repair_Approved__c = System.today();
        update opp;
        test.stopTest();
    }
    @isTest
    public static void TestSync() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        acct.Accounting_Contact_E_mail__c = 'Test@Test.com';
        insert acct;
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
        opp.StageName = 'Closed Won';
        opp.Ship_Date__c = System.today();
        opp.Account = acct;
        opp.Intacct_Shipper_Sync_Status__c = 'Warning';
        opp.Confirmation_Number__c = 'TEST';
        update opp;
        test.stopTest();
    }
    @isTest
    public static void TestHaveWorkOrders() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        acct.Accounting_Contact_E_mail__c = 'Test@Test.com';
        insert acct;
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
        update opp;
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', 'Test Product', 'Ultrasound Probe', true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        insert pi;
        Work_Order__c orders = new Work_Order__c();
        orders.Opportunity__c = opp.Id;
        orders.Asset__c = pi.Id;
        insert orders;
        Sourcing_Request_Item__c item = new Sourcing_Request_Item__c();
        item.Requesting_Opportunity__c = opp.Id;
        insert item;
        List<RMA__c> rmas = new List<RMA__c>();
        RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', false);
        rma.Opportunity__c = opp.Id;
        rmas.add(rma);
        rma = TestDataFactory.createRMA('Loaner Return', false);
        rma.Opportunity__c = opp.Id;
        rmas.add(rma);
        rma = TestDataFactory.createRMA('Core Exchange', false);
        rma.Opportunity__c = opp.Id;
        rmas.add(rma);        
        rma = TestDataFactory.createRMA('External Repair / Testing', false);
        rma.Opportunity__c = opp.Id;
        rmas.add(rma);
        rma = TestDataFactory.createRMA('Rental Return', false);
        rma.Opportunity__c = opp.Id;
        rmas.add(rma);
        insert rmas;    
        update opp;
        test.stopTest();
    }
    /*@isTest
    public static void PurchaseClosedWon() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        acct.Accounting_Contact_E_mail__c = 'Test@Test.com';
        insert acct;
        Opportunity opp = TestDataFactory.createOpportunity('Purchasing Opportunity', acct.Id, true);
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', 'Test Product', 'Ultrasound Probe', true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Sold__c = true;
        insert pi;
        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, false);
        oli.Opportunity = opp;
        insert oli;
        opp.StageName = 'Closed Won';
        opp.Confirmation_Number__c = 'TEST';
        update opp;
        test.stopTest();
    }*/
    @isTest
    public static void RepairEvaluation() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        acct.Accounting_Contact_E_mail__c = 'Test@Test.com';
        insert acct;
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
        //update opp;
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', 'Test Product', 'Ultrasound Probe', true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Sold__c = true;
        insert pi;
        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, false);
        oli.Opportunity = opp;
        insert oli;
        opp.Confirmation_Number__c = 'TEST';
        opp.StageName = 'Repair Evaluation';
        update opp;
        test.stopTest();
    }
    @isTest
    public static void ExternalRepairTesting() {
        test.startTest();
        Account acct = TestDataFactory.createAccount(false); 
        acct.Accounting_Contact_E_mail__c = 'Test@Test.com';
        insert acct;
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
        //update opp;
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', 'Test Product', 'Ultrasound Probe', true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Sold__c = true;
        insert pi;
        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, false);
        oli.Opportunity = opp;
        insert oli;
        opp.Confirmation_Number__c = 'TEST';
        opp.StageName = 'External Repair / Testing';
        update opp;
        test.stopTest();
    }
    
}