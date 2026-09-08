@isTest
private class P_ProductItemTriggerHandlerTest {

    @IsTest
    static void testMeetsQMSStandardsRepairAndEarlierTest(){
        List<Product2> pToInsert = new List<Product2>();

        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'test';
        p.Probe_Type__c = 'Linear';
        p.Family = 'Ultrasound Probe';
        pToInsert.add(p);

        Product2 p2 = TestDataFactory.createProduct('Ultrasound Probe', false);
        p2.Name = 'Array - test';
        p2.Probe_Type__c = 'Linear';
        p2.Family = 'Ultrasound Part';
        p2.Parent_Product__c = p.Id;
        pToInsert.add(p2);

        insert pToInsert;
		Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity('Purchasing Opportunity', acc.id, true);
        
        
        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'Repair Area - Cosmetic', Receive_date__c = Date.today(), Purchasing_opportunity__c = opp.id, Vendor_Warranty_Length__c = '90 days', Decontamination_Complete__c = true);
        insert pi;
        pi.Product_Name__c = p.Id;
        update pi;
        
        ProductTest__c pt = new ProductTest__c(Name = String.valueOf(Date.today()), Product_Item__c = pi.Id, Test_Completed_By__c = 'Test', Last_4_Characters_of_SN__c = '1234');
        insert pt;

        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SobjectType = 'Product_Repair__c' AND Name = 'Harvest' LIMIT 1];

        Datetime myDate = Datetime.now();

        Product_Repair__c pr2 = new Product_Repair__c(RecordTypeId = rt.Id, Product_Item__c = pi.Id,
                Repair_date__c = myDate, Part_to_Harvest__c = 'Array Carriage',Repair_Technician__c = 'Ana Howard');

        Test.startTest();

        System.debug('TEST - start of test');
        insert pr2;

        Test.stopTest();

        ProductItem__c piToCheck = [SELECT Id, Meets_QMS_Standards__c FROM ProductItem__c WHERE Id = :pi.Id LIMIT 1];

        System.assertEquals('Does Not Meet Standards', piToCheck.Meets_QMS_Standards__c, 'ProductItem__c Meets QMS Standards is wrong for Product_Repair and an earlier ProductTest');
    }

    @IsTest
    static void testMeetsQMSStandardsRepairAndLaterTest(){


        List<Product2> pToInsert = new List<Product2>();

        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'test';
        p.Probe_Type__c = 'Linear';
        p.Family = 'Ultrasound Probe';
        pToInsert.add(p);

        Product2 p2 = TestDataFactory.createProduct('Ultrasound Probe', false);
        p2.Name = 'Array - test';
        p2.Probe_Type__c = 'Linear';
        p2.Family = 'Ultrasound Part';
        p2.Parent_Product__c = p.Id;
        pToInsert.add(p2);

        insert pToInsert;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'Repair Area - Cosmetic', Receive_date__c = Date.today());
        insert pi;
		Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity('Purchasing Opportunity', acc.id, true);
        //insert opp;
        pi.Product_Name__c = p.Id;
        pi.Purchasing_Opportunity__c = opp.id;
        pi.Repair_Due_Date__c = date.today();
        pi.Image__c = 'https://drive.google.com/open?id=test12323872937192837192831827391823';
        update pi;

        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SobjectType = 'Product_Repair__c' AND Name = 'Harvest' LIMIT 1];

        Datetime myDate = Datetime.now().addMinutes(-1);

        Product_Repair__c pr2 = new Product_Repair__c(RecordTypeId = rt.Id, Product_Item__c = pi.Id,
                Repair_date__c = myDate, Part_to_Harvest__c = 'Array Carriage',Repair_Technician__c = 'Ana Howard');
        insert pr2;

        Test.startTest();

        System.debug('TEST - start of test');
        ProductTest__c pt = new ProductTest__c(Name = String.valueOf(Date.today()), Product_Item__c = pi.Id, Test_Completed_By__c = 'Test', Last_4_Characters_of_SN__c = '1234');
        insert pt;

        Test.stopTest();

        ProductTest__c ptestToCheck = [SELECT Id, CreatedDate FROM ProductTest__c WHERE Id = :pt.Id LIMIT 1];
        ProductItem__c piToCheck = [SELECT Id, Meets_QMS_Standards__c, Last_Repair__c, Last_Test__c FROM ProductItem__c WHERE Id = :pi.Id LIMIT 1];

        System.assertEquals(pr2.Repair_date__c, piToCheck.Last_Repair__c, 'PR Repair_date__c is not set on ProductItem');
        System.assertEquals(ptestToCheck.CreatedDate, piToCheck.Last_Test__c, 'PTest CreatedDate is not rolled up to ProductItem');
        System.assertEquals('Meets Standards', piToCheck.Meets_QMS_Standards__c, 'ProductItem__c Meets QMS Standards is wrong for Product_Repair and a later ProductTest');
    }

    @IsTest
    static void testMeetsQMSStandardsRepairAndNoTest(){

        List<Product2> pToInsert = new List<Product2>();

        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'test';
        p.Probe_Type__c = 'Linear';
        p.Family = 'Ultrasound Probe';
        pToInsert.add(p);

        Product2 p2 = TestDataFactory.createProduct('Ultrasound Probe', false);
        p2.Name = 'Array - test';
        p2.Probe_Type__c = 'Linear';
        p2.Family = 'Ultrasound Part';
        p2.Parent_Product__c = p.Id;
        pToInsert.add(p2);

        insert pToInsert;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Core Exchange', Serial_No__c = '64603208', Decontamination_Complete__c = true,
                Cost__c = 259.57, Location__c = 'Repair Area - Cosmetic', Receive_date__c = Date.today(), Reserved__c = true, Added_to_work_order__c = true);
        insert pi;
        pi.Product_Name__c = p.Id;
        update pi;
        


        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SobjectType = 'Product_Repair__c' AND Name = 'Harvest' LIMIT 1];

        Datetime myDate = Datetime.now();

        Product_Repair__c pr2 = new Product_Repair__c(RecordTypeId = rt.Id, Product_Item__c = pi.Id,
                Repair_date__c = myDate, Part_to_Harvest__c = 'Array Carriage',Repair_Technician__c = 'Ana Howard');

        Test.startTest();

        System.debug('TEST - start of test');
        insert pr2;

        Test.stopTest();

        ProductItem__c piToCheck = [SELECT Id, Meets_QMS_Standards__c FROM ProductItem__c WHERE Id = :pi.Id LIMIT 1];

        System.assertEquals('Does Not Meet Standards', piToCheck.Meets_QMS_Standards__c, 'ProductItem__c Meets QMS Standards is wrong for Product_Repair and no ProductTest');
    }

    @IsTest
    static void testMeetsQMSStandardsNoRepairAndATest(){

        List<Product2> pToInsert = new List<Product2>();

        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'test';
        p.Probe_Type__c = 'Linear';
        p.Family = 'Ultrasound Probe';
        pToInsert.add(p);

        Product2 p2 = TestDataFactory.createProduct('Part', false);
        p2.Name = 'Array - test';
        p2.Family = 'Ultrasound Part';
        p2.Parent_Product__c = p.Id;
        pToInsert.add(p2);

        insert pToInsert;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'Scrap', Receive_date__c = Date.today(), Posted_on_Ebay__c = true);
        insert pi;
        pi.Product_Name__c = p.Id;
        update pi;


        Test.startTest();

        System.debug('TEST - start of test >> ' + pi.Product_Name__c + ' >> ' + pi.Product_Family__c);
		
        ProductTest__c pt = new ProductTest__c(Name = String.valueOf(Date.today()), Product_Item__c = pi.Id, Test_Completed_By__c = 'Test', Last_4_Characters_of_SN__c = '1234');
        insert pt;

        Test.stopTest();

        ProductItem__c piToCheck = [SELECT Id, Meets_QMS_Standards__c FROM ProductItem__c WHERE Id = :pi.Id LIMIT 1];

        System.assertEquals(null, piToCheck.Meets_QMS_Standards__c, 'ProductItem__c Meets QMS Standards is wrong for no Product_Repair and a ProductTest');
    }

    @IsTest
    static void testMeetsQMSStandardsNoRepairAndNoTest(){

        List<Product2> pToInsert = new List<Product2>();

        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'test';
        p.Probe_Type__c = 'Linear';
        p.Family = 'Ultrasound Probe';
        pToInsert.add(p);

        Product2 p2 = TestDataFactory.createProduct('Ultrasound Probe', false);
        p2.Name = 'Array - test';
        p2.Probe_Type__c = 'Linear';
        p2.Family = 'Ultrasound Part';
        p2.Parent_Product__c = p.Id;
        pToInsert.add(p2);

        insert pToInsert;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'Repair Area - Cosmetic', Receive_date__c = Date.today(), Original_Condition_New__c = true);
        insert pi;
        pi.Product_Name__c = p.Id;
        update pi;

        ProductItem__c piToCheck = [SELECT Id, Meets_QMS_Standards__c FROM ProductItem__c WHERE Id = :pi.Id LIMIT 1];

        System.assertEquals(null, piToCheck.Meets_QMS_Standards__c, 'ProductItem__c Meets QMS Standards is wrong for no Product_Repair and no ProductTest');
    }
    
     @IsTest
    static void testDeleteAsset(){

        List<Product2> pToInsert = new List<Product2>();

        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'test';
        p.Probe_Type__c = 'Linear';
        p.Family = 'Ultrasound Probe';
        insert p;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'QA-Testing', Receive_date__c = Date.today(), Posted_on_Ebay__c = true);
        insert pi;


        Test.startTest();

         try{
            delete pi;
        }Catch (DMLException e){
            System.assert(e.getMessage().contains('You can not delete an asset.'), 'You can not delete an asset.');
        }
        Test.stopTest();

    }

    // ── OLI Purchasing_Approved sync ─────────────────────────────────────────
    // Covers the pItemIDsForLineItems path in the OLI SOQL query and the
    // after-trigger DML that mirrors Purchasing_Approved__c from ProductItem to OLI.
    @IsTest
    static void testOLIPurchasingApprovedSyncedWhenProductItemApproved() {
        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'Sync Test Product';
        p.Family = 'Ultrasound Probe';
        insert p;

        PricebookEntry pbe = TestDataFactory.createPricebookEntry(p.Id, true);
        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity('Purchasing Opportunity', acc.Id, true);

        ProductItem__c pi = new ProductItem__c(
            Product_Name__c = p.Id,
            Check_In_Type__c = 'Purchase',
            Serial_No__c = 'SYNC0001',
            Location__c = 'Repair Area - Cosmetic',
            Receive_date__c = Date.today(),
            Added_To_Opportunity__c = true,
            Purchasing_Approved__c = false
        );
        insert pi;

        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, true);

        Test.startTest();
        Validator_Class.assetBeforeUpdate = 0;
        Validator_Class.assetAfterUpdate = 0;
        pi.Purchasing_Approved__c = true;
        update pi;
        Test.stopTest();

        OpportunityLineItem oliResult = [SELECT Id, Purchasing_Approved__c FROM OpportunityLineItem WHERE Id = :oli.Id];
        System.assertEquals(true, oliResult.Purchasing_Approved__c,
            'OLI Purchasing_Approved__c should be synced from ProductItem when Purchasing_Approved__c changes to true');
    }

    // ── PricingMap pre-computation ────────────────────────────────────────────
    // Covers the new pricingMapByKey pre-computation and Probo_s_Offer__c
    // assignment when Purchasing_Opportunity__c is assigned for the first time.
    @IsTest
    static void testPricingOfferAssignedOnFirstOppAssignment() {
        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'Pricing Test Product';
        insert p;

        PricebookEntry pbe = TestDataFactory.createPricebookEntry(p.Id, true);
        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity('Purchasing Opportunity', acc.Id, true);

        // Generic item linked to the OLI — drives the Check_In_Type formula on OLI
        ProductItem__c piGeneric = new ProductItem__c(
            Product_Name__c = p.Id,
            Check_In_Type__c = 'Generic',
            Serial_No__c = 'PRICE001',
            Location__c = 'Repair Area - Cosmetic',
            Receive_date__c = Date.today(),
            Purchasing_Opportunity__c = opp.Id,
            Initial_Functional_Rating__c = 'Fair',
            Initial_Cosmetic_Rating__c = 'Fair'
        );
        insert piGeneric;
        piGeneric.Product_Name__c = p.Id;
        update piGeneric;

        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, piGeneric.Id, false);
        oli.Probo_s_Offer__c = 150.00;
        insert oli;
        
        System.debug('THIS IS THE OLI PRODUCT BEFORE PRICING MAP >> ' + oli.Product_Name__c + ' AND PRODUCT ITEM >> ' + oli.ProductItem__c + ' AND WOLI >> ' + oli.Work_Order_Line_Item__c);
		
        // Higher-rated item — no opp yet; will be assigned the opp in the test
        ProductItem__c piTrigger = new ProductItem__c(
            Product_Name__c = p.Id,
            Check_In_Type__c = 'Purchase',
            Serial_No__c = 'PRICE002',
            Location__c = 'Repair Area - Cosmetic',
            Receive_date__c = Date.today(),
            Initial_Functional_Rating__c = 'Good',
            Initial_Cosmetic_Rating__c = 'Good'
        );
        Validator_Class.assetBeforeInsert = 0;
        Validator_Class.assetAfterInsert = 0;
        insert piTrigger;

        Test.startTest();
        Validator_Class.assetBeforeUpdate = 0;
        Validator_Class.assetAfterUpdate = 0;
        piTrigger.Purchasing_Opportunity__c = opp.Id;
        update piTrigger;
        Test.stopTest();

        ProductItem__c result = [SELECT Id, Probo_s_Offer__c FROM ProductItem__c WHERE Id = :piTrigger.Id];
        System.assertEquals(150.00, result.Probo_s_Offer__c,
            'Probo_s_Offer__c should be assigned from OLI pricing when Purchasing_Opportunity__c is first set');
    }

    // ── Before-update timestamps ──────────────────────────────────────────────
    // Covers the Sold__c, Decontamination_Complete__c, Posted_on_Ebay__c, and
    // Reserved__c timestamp/by-field paths in the before-update loop.
    @IsTest
    static void testTimestampsSetOnUpdate() {
        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'Timestamp Test Product';
        insert p;

        ProductItem__c pi = new ProductItem__c(
            Product_Name__c = p.Id,
            Check_In_Type__c = 'Purchase',
            Serial_No__c = 'TIME0001',
            Location__c = 'Repair Area - Cosmetic',
            Receive_date__c = Date.today(),
            Sold__c = false,
            Decontamination_Complete__c = false,
            Posted_on_Ebay__c = false,
            Reserved__c = false
        );
        insert pi;

        Test.startTest();
        pi.Sold__c = true;
        pi.Decontamination_Complete__c = true;
        pi.Posted_on_Ebay__c = true;
        pi.Reserved__c = true;
        update pi;
        Test.stopTest();

        ProductItem__c result = [SELECT Id,
                                        Time_Stamp_Sold__c, Sold_Box_Changed_By__c,
                                        Time_Decontamination_Completed__c,
                                        Posted_on_Ebay_Timestamp__c, Posted_on_Ebay_By__c,
                                        Reserved_Time_Stamp__c, Reserved_By__c
                                 FROM ProductItem__c WHERE Id = :pi.Id];

        System.assertNotEquals(null, result.Time_Stamp_Sold__c,
            'Time_Stamp_Sold__c should be set when Sold__c becomes true');
        System.assertNotEquals(null, result.Sold_Box_Changed_By__c,
            'Sold_Box_Changed_By__c should be set when Sold__c becomes true');
        System.assertNotEquals(null, result.Time_Decontamination_Completed__c,
            'Time_Decontamination_Completed__c should be set when Decontamination_Complete__c becomes true');
        System.assertNotEquals(null, result.Posted_on_Ebay_Timestamp__c,
            'Posted_on_Ebay_Timestamp__c should be set when Posted_on_Ebay__c becomes true');
        System.assertNotEquals(null, result.Posted_on_Ebay_By__c,
            'Posted_on_Ebay_By__c should be set when Posted_on_Ebay__c becomes true');
        System.assertNotEquals(null, result.Reserved_Time_Stamp__c,
            'Reserved_Time_Stamp__c should be set when Reserved__c becomes true');
        System.assertNotEquals(null, result.Reserved_By__c,
            'Reserved_By__c should be set when Reserved__c becomes true');
    }

}