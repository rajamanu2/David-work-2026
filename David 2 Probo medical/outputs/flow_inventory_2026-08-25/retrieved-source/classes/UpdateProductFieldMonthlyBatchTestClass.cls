@isTest//(seeAllData=true)

public class UpdateProductFieldMonthlyBatchTestClass {

    static testmethod void TestUpdateProductFieldMonthlyBatchTest1() {
        //TODO - query the picklist values for the Work_Order__c.Person_Requesting_WO__c field and grab one of the fields from the picklist values for this user
        User u = TestDataFactory.createUser('Casey', 'Trogden', true);

        system.runas(u) {
            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
            pro.Functionally_Good_Probes__c = 190;
            insert pro;
            ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
            pi.Sold__c = true;
            pi.Purchasing_Approved__c = true;
            insert pi;
            Opportunity opp = TestDataFactory.createOpportunity('Sales Opportunity', null, false);
            opp.StageName = 'Closed Won';
            opp.Customer_PO__c = '1234';
            opp.Shipping_FROM_Location__c = 'Fishers, IN';
            opp.Confirmation_number__c = '12345';
            insert opp;
            PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
            OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, false);
            oli.Quantity = 1;
            oli.TotalPrice = 100;
            oli.Purchasing_Approved__c = true;
            insert oli;
        }

        Test.startTest();

        UpdateProductFieldMonthlyBatch upfb = new UpdateProductFieldMonthlyBatch();
        Database.executeBatch(upfb, 1);

        Test.stopTest();
    }
    
    static testmethod void TestUpdateProductFieldMonthlyBatchTest2() {
        //TODO - query the picklist values for the Work_Order__c.Person_Requesting_WO__c field and grab one of the fields from the picklist values for this user
        User u = TestDataFactory.createUser('Casey', 'Trogden', true);

        system.runas(u) {
            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
            pro.Functionally_Good_Probes__c = 190;
            insert pro;
            ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
            pi.Sold__c = true;
            pi.Purchasing_Approved__c = true;
            insert pi;
            Opportunity opp = TestDataFactory.createOpportunity('Sales Opportunity', null, false);
            opp.StageName = 'Closed Won';
            opp.Customer_PO__c = '1234';
            opp.Shipping_FROM_Location__c = 'Fishers, IN';
            opp.Confirmation_number__c = '12345';
            opp.CloseDate = Date.today().addDays(-29);
            opp.Ship_date__c = Date.today();
            insert opp;
            PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
            OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, false);
            oli.Quantity = 1;
            oli.TotalPrice = 100;
            oli.Purchasing_Approved__c = true;
            insert oli;
        }

        Test.startTest();

        UpdateProductFieldMonthlyBatch upfb = new UpdateProductFieldMonthlyBatch();
        Database.executeBatch(upfb, 1);

        Test.stopTest();
    }
/*
static testmethod void test1() {

        User theUser;
        try{
            theUser = [select id from User where alias = 'dtrog' and isActive = true LIMIT 1];
        } catch(Exception e){
            system.assert(false, 'Unable to find a user to RunAs.  Looking for Alias of dtrog');
        }

		
        System.runAs(theUser){

        Account acc = new Account(name='abcdgh');
        insert acc;
    
        Product2 pro = new Product2 (Name='Ultrasound Probe-Acuson 4V1C', Functionally_Good_Probes__c = 10, Qty_Ready_to_Ship__c = 5);
        insert pro;
        
        ProductItem__c prItem1 = new ProductItem__c(Product_Name__c=pro.Id,Check_In_Type__c='Purchase',  Serial_No__c='10613003',Receive_date__c=Date.parse('01/08/2015'),Cost__c=15000.00,Location__c='Finished Goods',
                                                   Functional_Rating__c = 'Good', Cosmetic_Rating__c = 'Good', Purchasing_Approved__c = true);
        insert prItem1;
         
        RecordType RC = [select id from  RecordType where SobjectType='Opportunity' AND DeveloperName='Sales_Opportunity'];      
        opportunity opp = new opportunity(Name='newopp',AccountId=acc.Id,CloseDate=Date.parse('12/13/2014'),StageName='Closed Won',RecordTypeId = RC.id, Customer_PO__c = '1234');
        insert opp;
        
        Id pbId = test.getStandardPricebookId(); //[select id from Pricebook2 where isStandard=true];
         
        PricebookEntry pbe = new PricebookEntry (Pricebook2Id=pbId , Product2Id=pro.Id, IsActive=true, UnitPrice=1000.00);
        insert pbe;
        
        OpportunityLineItem oppli = new OpportunityLineItem(opportunityId=opp.Id,PricebookEntryId=pbe.Id,ProductItem__c=prItem1.Id,Quantity=1, TotalPrice=1000.00, Purchasing_Approved__c = true);
        insert oppli;
    
    Product_Repair__c repair = new Product_Repair__c(Product_Item__C = prItem1.id, repair_date__c = date.parse('01/02/2018'), Repair_Activity__C = 'Lens Relens');
    insert repair;

        UpdateAssetBatch upfb = new UpdateAssetBatch();
        Database.executeBatch(upfb,1); 
         System.schedule('Scheduled Job 7', '0 0 * * * ?', new UpdateAssetBatch()); 
          

    }
    }*/

}