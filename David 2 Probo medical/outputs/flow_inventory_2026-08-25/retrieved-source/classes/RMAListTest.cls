@isTest
private class RMAListTest{

    static testmethod void TestRMAListTest1() {

        User theUser;
        try{
            theUser = [SELECT Id FROM User WHERE alias = 'dtrog' AND isActive = TRUE LIMIT 1];
        } catch(Exception e){
            System.assert(false, 'Unable to find a user to RunAs.  Looking for Alias of dtrog');
        }

        System.runAs(theUser) {

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Probe_Type__c = 'Sector';
        pro.Family = 'Ultrasound Part';
        insert pro;
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity('Sales Opportunity', acc.Id, false);
        opp.Name = 'oppname2';
        opp.Amount = null;
        opp.StageName = 'Closed Won';
        opp.Shipping_FROM_Location__c = 'Fishers, IN';
        opp.CloseDate = system.today();
        insert opp;

        Test.startTest();

            RMA__c rma = TestDataFactory.createRMA('Warranty Claim', false);
            rma.ProductItem__c = pi.Id;
            rma.Opportunity__c = opp.Id;
            rma.Customer_Expectation__c = 'Customer wants Equipment Back';
            rma.Date_RMA_Item_Received__c = system.today() - 2;
            rma.Quality_Issue_Notes__c = 'Bad image';

            System.debug('TEST: start of test');
            insert rma;
            Test.setCurrentPageReference(new PageReference('Page.RMAList'));
            System.currentPageReference().getParameters().put('id', acc.id);
            ApexPages.StandardController sc = new ApexPages.standardController(acc);
            RMAList rm = new RMAList(sc);

            Test.stopTest();
        }

        System.debug('TEST: end of test');
    }
}