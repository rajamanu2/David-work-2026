@IsTest
private class P_OpportunityTriggerHandlerTest {
    
    @isTest static void repairRMACreate1() {

        ProboCommonUtils.getStdPricebookId();

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

        Product2 pro = TestDataFactory.createProduct('Ultrasound System', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        System.debug('CC...ProductItem__c' + pi.Id);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);

        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, false);
        insert oli;
        System.debug('CC...OpportunityLineItem' + oli.ProductItem__c);

        Test.startTest();

        opp.StageName = 'Repair Evaluation';
        update opp;

        // check that the opportunity was updated as expected
        List<RMA__c> theRMAs = [SELECT Id FROM RMA__c WHERE Opportunity__c = :opp.Id];

        //System.assertEquals(1, theRMAs.size(), 'Incorrect number of RMAs after setting Stage to Repair Evaluation');

        opp.StageName = 'Proposal/Price Quote';
        //update opp;

        opp.StageName = 'Verbal Acceptance';
        update opp;
        
        opp.StageName = 'Repair Evaluation';
        opp.Ship_Date__c = system.today();
        update opp;
        
        //oli.Stage__c = 'Verbal Acceptance';
        update oli;

        opp.StageName = 'Closed Won';
        opp.Confirmation_Number__c = '1234';
        update opp;

        oli.UnitPrice = 666;

        update oli;


        delete oli;

        // check that the opportunity was updated as expected
        theRMAs = [SELECT Id FROM RMA__c WHERE Opportunity__c = :opp.Id];

        //System.assertEquals(1, theRMAs.size(), 'Incorrect number of RMAs after setting Stage back to Repair Evaluation again');

        Test.stopTest();

    }
    @isTest static void repairRMACreate() {

        ProboCommonUtils.getStdPricebookId();

        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acc.Id, false);
        opp.Repair_Evaluation_Serial_Number__c = '1234';
        opp.StageName = 'Proposal/Price Quote';
        insert opp;

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);

        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, true);

        Test.startTest();

        opp.StageName = 'Repair Evaluation';
        update opp;

        // check that the opportunity was updated as expected
        List<RMA__c> theRMAs = [SELECT Id FROM RMA__c WHERE Opportunity__c = :opp.Id];

        System.assertEquals(1, theRMAs.size(), 'Incorrect number of RMAs after setting Stage to Repair Evaluation');

        opp.StageName = 'Proposal/Price Quote';
        update opp;

        opp.StageName = 'Repair Evaluation';
        update opp;

        // check that the opportunity was updated as expected
        theRMAs = [SELECT Id FROM RMA__c WHERE Opportunity__c = :opp.Id];

        System.assertEquals(1, theRMAs.size(), 'Incorrect number of RMAs after setting Stage back to Repair Evaluation again');

        Test.stopTest();

    }
    
     @isTest static void EstimatedReadyDateChange() {

        ProboCommonUtils.getStdPricebookId();

        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity('Probe Sales Opportunity', acc.Id, false);
        opp.Repair_Evaluation_Serial_Number__c = '1234';
        opp.StageName = 'Proposal/Price Quote';
        insert opp;

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);

        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, true);

        Test.startTest();

        opp.StageName = 'Repair Evaluation';
        update opp;

        
        opp.Estimated_Ready_Date__c = date.today();
        update opp;

        Test.stopTest();

    }

    @isTest static void externalRepairRMACreate() {

        ProboCommonUtils.getStdPricebookId();

        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity('External Repair / Testing', acc.Id, false);
        opp.Repair_Evaluation_Serial_Number__c = '1234';
        opp.StageName = 'Proposal/Price Quote';
        insert opp;

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);

        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, true);

        Test.startTest();

        opp.StageName = 'External Repair / Testing';
        update opp;

        // check that the opportunity was updated as expected
        List<RMA__c> theRMAs = [SELECT Id FROM RMA__c WHERE Opportunity__c = :opp.Id];

        System.assertEquals(1, theRMAs.size(), 'Incorrect number of RMAs after setting Stage to External Repair / Testing');

        opp.StageName = 'Proposal/Price Quote';
        update opp;

        opp.StageName = 'External Repair / Testing';
        update opp;

        // check that the opportunity was updated as expected
        theRMAs = [SELECT Id FROM RMA__c WHERE Opportunity__c = :opp.Id];

        System.assertEquals(1, theRMAs.size(), 'Incorrect number of RMAs after setting Stage back to External Repair / Testing again');

        Test.stopTest();

    }
/*
 // No longer create loaner RMA off of opps. 07.20.21
    @isTest static void loanerRMACreate() {

        ProboCommonUtils.getStdPricebookId();

        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity('External Repair / Testing', acc.Id, false);
        opp.Repair_Evaluation_Serial_Number__c = '1234';
        opp.StageName = 'Proposal/Price Quote';
        insert opp;

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);

        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, true);

        Test.startTest();

        opp.StageName = 'External Repair / Testing';
        update opp;

        // check that the opportunity was updated as expected
        List<RMA__c> theRMAs = [SELECT Id FROM RMA__c WHERE Opportunity__c = :opp.Id];

        System.assertEquals(1, theRMAs.size(), 'Incorrect number of RMAs after setting Stage to External Repair / Testing');

        opp.StageName = 'Proposal/Price Quote';
        update opp;

        opp.StageName = 'External Repair / Testing';
        update opp;

        // check that the opportunity was updated as expected
        theRMAs = [SELECT Id FROM RMA__c WHERE Opportunity__c = :opp.Id];

        System.assertEquals(1, theRMAs.size(), 'Incorrect number of RMAs after setting Stage back to External Repair / Testing again');

        Test.stopTest();

    }
*/
    @isTest static void createRentalRetRMA() {

        ProboCommonUtils.getStdPricebookId();
        
        User u = [select Id from User where LastName = 'Walter' and FirstName = 'Adam' LIMIT 1];
        
        /*
        Tech_Ship_Location_Junction__c TSLJToInsert = new Tech_Ship_Location_Junction__c(
        Technician_Ship_Location__c = TechShipLocation.id,
        Technician__c = u.id
        );
        insert TSLJToInsert;
        */
        
        Schema.Location loc = new Schema.Location(Name = 'Adam Walter', LocationType = 'Field Service Engineer');
        insert loc;
        
        Schema.Address addr = new Schema.Address(ParentId = loc.Id, AddressType = 'FedEx', LocationType = 'Field Service Engineer');
        insert addr;
        

        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity('External Repair / Testing', acc.Id, false);
        opp.Repair_Evaluation_Serial_Number__c = '1234';
        opp.StageName = 'Proposal/Price Quote';
        opp.Field_Service_Engineer__c = 'Adam Walter';
        opp.Ship_To_Account__c = 'Test Account';
        opp.ShippingStreet__c = '52 Commons Drive';
        opp.ShippingCity__c = 'Pottstown';
        opp.ShippingState__c = 'PA';
        opp.ShippingPostalCode__c = '19076';
        opp.ShippingCountry__c = 'US';
        insert opp;
        
        // opp.Tech_Ship_Location__c = TSLJTOInsert.id;
        opp.Tech_Ship_Location_Address__c = addr.Id;
        update opp;

        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);

        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, true);

        Test.startTest();

        GH_Logger.debug('TEST: starting');
        // this causes the first RentalRet RMA to be created
        opp.StageName = 'Equipment Rental';
        opp.AVA_SFCLOUD__AvaTax_Message__c = 'Sales Tax Current';
        update opp;

        List<RMA__c> theRMAs = [SELECT Id FROM RMA__c WHERE Opportunity__c = :opp.Id];

        System.assertEquals(1, theRMAs.size(), 'Incorrect number of RMAs after setting Stage to Equipment Rental');

        // switching away then back to 'Equipment Rental' should not cause a duplicate RentalRet RMA to be created
        opp.StageName = 'Proposal/Price Quote';
        update opp;

        opp.StageName = 'Equipment Rental';
        update opp;

        GH_Logger.debug('TEST: ending');

        // check that the opportunity was updated as expected
        theRMAs = [SELECT Id FROM RMA__c WHERE Opportunity__c = :opp.Id];

        System.assertEquals(1, theRMAs.size(), 'Incorrect number of RMAs after setting Stage back to Equipment Rental again');

        Test.stopTest();

    }
    
    @isTest
    static void testUpdateSyncStatusAsAdamWalter() {
        // Retrieve Adam Walter user
        User adam = [SELECT Id FROM User WHERE FirstName = 'Adam' AND LastName = 'Walter' LIMIT 1];
    
        Test.startTest();
    
        System.runAs(adam) {
            ProboCommonUtils.getStdPricebookId();
    
            // Attempt to fetch an existing Schema.Address record
            Schema.Address existingAddr;
            try {
                existingAddr = [SELECT Id FROM Address LIMIT 1];
            } catch (QueryException qe) {
                // If none exist, create one
                Schema.Location loc = new Schema.Location(
                    Name = 'Adam Walter',
                    LocationType = 'Field Service Engineer'
                );
                insert loc;
    
                existingAddr = new Schema.Address(
                    ParentId = loc.Id,
                    AddressType = 'FedEx',
                    LocationType = 'Field Service Engineer'
                );
                insert existingAddr;
            }
    
            // Create test account and opportunity
            Account acc = TestDataFactory.createAccount(true);
            Opportunity opp = TestDataFactory.createOpportunity('External Repair / Testing', acc.Id, false);
            opp.Repair_Evaluation_Serial_Number__c = '1234';
            opp.StageName = 'Proposal/Price Quote';
            opp.Field_Service_Engineer__c = 'Adam Walter';
            opp.Ship_To_Account__c = 'Test Account';
            opp.ShippingStreet__c = '52 Commons Drive';
            opp.ShippingCity__c = 'Pottstown';
            opp.ShippingState__c = 'PA';
            opp.ShippingPostalCode__c = '19076';
            opp.ShippingCountry__c = 'US';
            opp.Intacct_Shipper_Sync_Status__c = 'Synced';
            opp.Tech_Ship_Location_Address__c = existingAddr.Id; // <-- assign fetched Address
            opp.FSR_Attached__c = false;
            insert opp;
            
            opp.AVA_SFCLOUD__AvaTax_Message__c = 'Sales Tax Current';
            update opp;

			opp.FSR_Attached__c = true;
            update opp;
    
            // Attempt update that should trigger addError
            Boolean errorThrown = false;
            try {
                opp.Intacct_Shipper_Sync_Status__c = 'Sync';
                update opp;
            } catch (DmlException e) {
                errorThrown = true;
                System.assert(
                    e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'),
                    'Expected FIELD_CUSTOM_VALIDATION_EXCEPTION, but got: ' + e.getMessage()
                );
            }
    
            System.assert(errorThrown, 'Expected error from addError(), but none was thrown.');
        }
    
        Test.stopTest();
    }

}