@isTest
private class NewOppLightningStandardCtrlTest {
    @testSetup
    static void setup() {
        Account acc = TestDataFactory.createAccount(false);
        acc.Field_Service_Engineer__c = 'Hobie Sears';
        acc.Standard_Warranty_Length__c = '6 Months';
        acc.Lead_Source__c = 'Referral';
        acc.Name = 'Probo Medical, Inc';
        insert acc;
        Contact con = new Contact(LastName='Doe', FirstName='John', AccountId=acc.Id);
        insert con;
        Opportunity opp = TestDataFactory.createOpportunity('Inter-Company / Material Transfer', acc.Id, false);
        opp.StageName = 'Qualification';
        opp.Shipping_TO_Location__c = 'Fishers, IN';
        opp.Shipping_FROM_Location__c = 'Tampa, FL';
        insert opp;
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Functionally_Good_Probes__c = 190;
        insert pro;
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, true);
    }
    
    static testmethod void TestNewOppLightningTestWithOpportunity() {
        Opportunity o = [SELECT Id, Shipping_To_Location__c, Shipping_From_Location__c FROM Opportunity LIMIT 1];

        Test.startTest();
		
        ApexPages.StandardController sc = new ApexPages.StandardController(o);
        ApexPages.currentPage().getParameters().put('id', o.id);
        NewOppLightningStandardCtrl tester = new NewOppLightningStandardCtrl(sc);
        tester.newStdOpp();
        tester.newQuickOpp();
         
        Test.stopTest();
        
    }

    static testmethod void TestNewOppLightningTestWithAccount() {
        Account a = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
	    
        ApexPages.StandardController sc = new ApexPages.StandardController(a);
        ApexPages.currentPage().getParameters().put('id', a.id);
        NewOppLightningStandardCtrl tester = new NewOppLightningStandardCtrl(sc);
        tester.newStdOpp();

        Test.stopTest();
    }

    static testmethod void TestNewOppLightningTestWithContact() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
		
        ApexPages.StandardController sc = new ApexPages.StandardController(c);
        ApexPages.currentPage().getParameters().put('id', c.id);
        NewOppLightningStandardCtrl tester = new NewOppLightningStandardCtrl(sc);
        tester.newStdOpp();

        Test.stopTest();
    }
    
    
}