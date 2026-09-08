@IsTest
private class P_ProductRepairTriggerHandlerTest {


    @IsTest
    static void test() {

        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'test';
        p.Probe_Type__c = 'Sector';
        p.Family = 'Ultrasound Part';
        insert p;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'Cage', Receive_date__c = system.today());
        insert pi;

        ProductItem__c pi2 = new ProductItem__c(Product_Name__c =p.id, Check_In_Type__c = 'Purchase', Serial_No__c = '1234', 
                                                Cost__c = 200, Location__c = 'Cage', Receive_date__c = system.today(), 
                                                Purchasing_approved__c =true, Cosmetic_Rating__c = 'Good', Functional_Rating__c = 'Good');
        
        insert pi2;
        ProductTest__c pt = new ProductTest__c(Test_Completed_By__c = 'Andres Carvajal', Last_4_Characters_of_SN__c = '1234', Name = String.valueOf(System.today()), Product_Item__c = pi.id);
        insert pt;

        //Needed for Natalie's code
        RecordType rt = [select id,Name from RecordType where sObjectType = 'Product_Repair__c' AND Name = 'Cosmetic Repair' limit 1];

        datetime myDate = datetime.newInstance(2016, 1, 1, 12, 30, 0);

        Product_Repair__c pr = new Product_Repair__c(Repair_Technician__c = 'Bill Grider', RecordTypeId = rt.id, Product_Item__c = pi.id, Repair_date__c = datetime.now(), Asset_used_during_repair__c =pi2.id);
        insert pr;
        
        try{
           delete pr;
        }catch(DMLexception e){
            
system.assert(e.getmessage().contains('You can not delete a repair once it has been completed !'), 'You can not delete a repair once it has been completed !'
             );}
    }

    @IsTest
    static void test1() {

        Product2 p = new Product2 (Name = 'Ultrasound Probe-Philips C5-1', probe_type__c = 'Linear', Max_Repair__c = 100000, Sug_Pr_Ex__c = 200, Qty_Ready_to_Ship__c = 0,
                Max_Non_Functional__c = 200000, Cable_Advanced_Whitening__c = 500, Cable_Jacket_Splice__c = 500, Connector_Housing_Replacement__c = 500,
                Connector_Housing_Paint__c = 500, Refurb__c = 500, Lens_Refurb__c = 500, Lens_Remove__c = 500, Lens_Relens__c = 500, Strain_Relief_Remove__c = 500,
                Strain_Relief_Replacement__c = 500, Array_Replacement__c = 800, Cable_Replacement__c = 800, Cap_Replacement_with_Oil_Fill__c = 800,
                Connector_Repair__c = 800, Electrical__c = 800, Motor_Repair__c = 800, Oil_Fill__c = 800, Probe_Handle_Close__c = 800, Probe_Handle_Open__c = 800,
                Probe_Handle_Replacement__c = 800, Retermination__c = 800, Bending_Rubber_Glue_Beads_Replacement__c = 500, Control_Housing_Polish__c = 500,
                Grommet_Replacement__c = 500, Knob_Replacement__c = 500, Lens_Remove_Coating_RTV_Seal_Replacement__c = 500, RTV_Seal_Replacement__c = 500,
                Tip_Polish__c = 500, Array_Drive_Switch_or_Board_Replacement__c = 800, Array_Drive_System_Replacement__c = 800, Connector_Boards_Replacement__c = 800,
                Control_Housing_Overhaul__c = 800, Insertion_Tube_Replacement__c = 800, Steering_Cable_Adjustment__c = 800, Steering_Cable_Replacement__c = 800,
                Tip_Overhaul__c = 800, Cable_Prep__c = 600, Flex_Bonding_Repair__c = 600, Re_Lens__c = 200, Strain_Relief__c = 200, Mechanical__c = 200, Re_Paint_Connector__c = 200,
                Replace_Housing__c = 200, Replace_Knob__c = 200, Pins__c = 200, Replace_Handle__c = 200, Advanced_Cable_Whitening__c = 200, Reverse_Probe_Handle__c = 200,
                Re_Termination__c = 200, Oil_Fill_and_Cap_Replacement__c = 200, Replace_Bending_Rubber__c = 200, Replace_Glue_Beads__c = 200, Re_coat_Re_Label__c = 200,
                Adjust_Steering_Cable__c = 200, Motor_Replacement__c = 200, Connector_Overhaul__c = 200, Switch_Replacement_TEE__c = 200, Tip_Replacement__c = 200,
                Probe_Handle_Reverse__c = 100, Tip_Lens_Film_Removal__c = 100, Full_Overhaul__c = 200, Array_Carriage_Replacement__c = 900,
                Cable_Jacket_Refurbishment__c = 900, Cap_Refurbishment__c = 900, Connector_Refurbishment__c = 900, Probe_Handle_Refurbishment__c = 900,
                Strain_Relief_Refurbishment__c = 900, Ferrule_Assembly__c = 1, OEM__c = 'GE_Healthcare', Part_Type__c = 'Assembly', Modality__c = 'Ultrasound');
        insert p;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Customer Repair', Serial_No__c = '64603209',
                Cost__c = 259.57, Location__c = 'Cage', Receive_date__c = system.today());
        insert pi;

        RecordType rt = [select id, name from RecordType where Sobjecttype = 'RMA__c' and name = 'Customer Repair Evaluation'];
        RMA__c newRMA = new RMA__c(RecordTypeId = rt.id, Approved_Repairs__c = 'All Repairs Approved',
                Date_Last_Test_Completed__c = system.today(), Bending_Rubber__c = 'No problem', Cable_Jacket__c = 'No problem',
                Cap__c = 'No problem', Connector__c = 'No problem', Control_Housing__c = 'No problem', Insertion_Tube__c = 'No problem',
                Lens__c = 'No problem', Probe_Handle__c = 'No problem', Strain_Relief__c = 'No problem', Tip__c = 'No problem',
                Airscan__c = 'No problem', Articulation__c = 'No problem', Color_Artifacts__c = 'No problem',
                CW_Artifacts__c = 'No problem', CW_Pulse__c = 'No problem', First_Call__c = 'No problem', Image__c = 'No problem',
                Interior__c = 'No problem', Leakage_Current__c = 'No problem', Motor__c = 'No problem', Orientation__c = 'No problem',
                ProductItem__c = pi.id, Quality_Issue_Notes__c = 'TEST');
        insert newRMA;
        ProductTest__c pt = new ProductTest__c(Test_Completed_By__c = 'Andres Carvajal', Last_4_Characters_of_SN__c = '1234', Name = String.valueOf(System.today()), Product_Item__c = pi.id);
        insert pt;
		Work_Order__c wo = new Work_Order__c(Asset__c = pi.id);
        insert wo;
        //needed for Natalie's code
        RecordType rt2 = [select id,Name from RecordType where sObjectType = 'Product_Repair__c' AND Name = 'Functional Repair' limit 1];

        datetime myDate = datetime.newInstance(2016, 1, 1, 12, 30, 0);

        Product_Repair__c pr = new Product_Repair__c(Added_to_Work_Order__c = true, Work_Order__c = wo.id, Repair_Technician__c = 'Bill Grider', RecordTypeId = rt2.id, Product_Item__c = pi.id, Repair_date__c = date.today(), Repair_activity__c = 'Cable Replacement');
        insert pr;

    //   ProductTest__c p1 =new ProductTest__c(Name=String.valueOf(System.today()), Product_Item__c=pi.id);
      //  insert p1;
    }

    @IsTest
    static void test2() {

        List<Product2> prodsToInsert = new List<Product2>();

        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'test';
        p.Probe_Type__c = 'Linear';
        prodsToInsert.add(p);

        Product2 p2 = TestDataFactory.createProduct('Ultrasound Probe', false);
        p2.Name = 'Array - test';
        p2.Probe_Type__c = 'Linear';
        p2.Family = 'Ultrasound Part';
        p2.Parent_Product__c = p.Id;
        prodsToInsert.add(p2);

        insert prodsToInsert;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'Cage', Receive_date__c = system.today());
        insert pi;

        ProductTest__c pt = new ProductTest__c(Test_Completed_By__c = 'Andres Carvajal', Last_4_Characters_of_SN__c = '1234', Name = String.valueOf(System.today()), Product_Item__c = pi.id);
        insert pt;

        //Needed for Natalie's code
        RecordType rt = [select id,Name from RecordType where sObjectType = 'Product_Repair__c' AND Name = 'Harvest' limit 1];

        datetime myDate = datetime.newInstance(2016, 1, 1, 12, 30, 0);

        List<Product_Repair__c> prsToInsert = new List<Product_Repair__c>();
        Product_Repair__c pr = new Product_Repair__c(Repair_Technician__c = 'Bill Grider', RecordTypeId = rt.id, Product_Item__c = pi.id, Repair_date__c = myDate, Previous_Test__c = pt.id, Post_Test__c = pt.id, Part_to_Harvest__c = 'Array');
        prsToInsert.add(pr);

        Product_Repair__c pr2 = new Product_Repair__c(Repair_Technician__c = 'Bill Grider', RecordTypeId = rt.id, Product_Item__c = pi.id, Repair_date__c = myDate, Previous_Test__c = pt.id, Post_Test__c = pt.id, Part_to_Harvest__c = 'Array Carriage');
        prsToInsert.add(pr2);

        Product_Repair__c pr3 = new Product_Repair__c(Repair_Technician__c = 'Bill Grider', RecordTypeId = rt.id, Product_Item__c = pi.id, Repair_date__c = myDate, Previous_Test__c = pt.id, Post_Test__c = pt.id, Part_to_Harvest__c = 'Cable');
        prsToInsert.add(pr3);

        Product_Repair__c pr4 = new Product_Repair__c(Repair_Technician__c = 'Bill Grider', RecordTypeId = rt.id, Product_Item__c = pi.id, Repair_date__c = myDate, Previous_Test__c = pt.id, Post_Test__c = pt.id, Part_to_Harvest__c = 'Cap');
        prsToInsert.add(pr4);

        Product_Repair__c pr5 = new Product_Repair__c(Repair_Technician__c = 'Bill Grider', RecordTypeId = rt.id, Product_Item__c = pi.id, Repair_date__c = myDate, Previous_Test__c = pt.id, Post_Test__c = pt.id, Part_to_Harvest__c = 'Connector Board');
        prsToInsert.add(pr5);

        Product_Repair__c pr6 = new Product_Repair__c(Repair_Technician__c = 'Bill Grider', RecordTypeId = rt.id, Product_Item__c = pi.id, Repair_date__c = myDate, Previous_Test__c = pt.id, Post_Test__c = pt.id, Part_to_Harvest__c = 'Connector Housing');
        prsToInsert.add(pr6);

        Product_Repair__c pr7 = new Product_Repair__c(Repair_Technician__c = 'Bill Grider', RecordTypeId = rt.id, Product_Item__c = pi.id, Repair_date__c = myDate, Previous_Test__c = pt.id, Post_Test__c = pt.id, Part_to_Harvest__c = 'Motor');
        prsToInsert.add(pr7);

        Product_Repair__c pr8 = new Product_Repair__c(Repair_Technician__c = 'Bill Grider', RecordTypeId = rt.id, Product_Item__c = pi.id, Repair_date__c = myDate, Previous_Test__c = pt.id, Post_Test__c = pt.id, Part_to_Harvest__c = 'Oil Bladder');
        prsToInsert.add(pr8);

        Product_Repair__c pr9 = new Product_Repair__c(Repair_Technician__c = 'Bill Grider', RecordTypeId = rt.id, Product_Item__c = pi.id, Previous_Test__c = pt.id, Post_Test__c = pt.id, Part_to_Harvest__c = 'Probe Handle');
        prsToInsert.add(pr9);

        insert prsToInsert;

        Test.startTest();
        pr9.Repair_date__c = myDate;
        update pr9;
        Test.stopTest();
    }

    @IsTest
    static void test3() {

        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'test';
        p.Probe_Type__c = 'Linear';
        insert p;

        Product2 p2 = TestDataFactory.createProduct('Ultrasound Probe', false);
        p2.Name = 'Array - test';
        p2.Probe_Type__c = 'Linear';
        p2.Family = 'Ultrasound Part';
        p2.Parent_Product__c = p.Id;
        insert p2;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'Cage', Receive_date__c = system.today());
        insert pi;
        
        

        ProductTest__c pt = new ProductTest__c(Test_Completed_By__c = 'Andres Carvajal', Last_4_Characters_of_SN__c = '1234', Name = String.valueOf(System.today()), Product_Item__c = pi.id);
        insert pt;

        //Needed for Natalie's code
        RecordType rt = [select id,Name from RecordType where sObjectType = 'Product_Repair__c' AND Name = 'Harvest' limit 1];

        datetime myDate = datetime.newInstance(2016, 1, 1, 12, 30, 0);


        Product_Repair__c pr9 = new Product_Repair__c(Repair_Technician__c = 'Bill Grider', RecordTypeId = rt.id, Product_Item__c = pi.id, Previous_Test__c = pt.id, Post_Test__c = pt.id, Part_to_Harvest__c = 'Probe Handle');
        insert pr9;

        pr9.Repair_date__c = myDate;
        update pr9;
    }

    @IsTest
    static void test4() {

        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'test';
        p.Probe_Type__c = 'Linear';
        insert p;

        Product2 p2 = TestDataFactory.createProduct('Ultrasound Probe', false);
        p2.Name = 'Array - test';
        p2.Probe_Type__c = 'Linear';
        p2.Family = 'Ultrasound Part';
        p2.Parent_Product__c = p.Id;
        insert p2;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'Cage', Receive_date__c = system.today());
        insert pi;

        ProductTest__c pt = new ProductTest__c(Test_Completed_By__c = 'Andres Carvajal', Last_4_Characters_of_SN__c = '1234', Name = String.valueOf(System.today()), Product_Item__c = pi.id);
        insert pt;

        //Needed for Natalie's code
        RecordType rt = [select id,Name from RecordType where sObjectType = 'Product_Repair__c' AND Name = 'Harvest' limit 1];

        datetime myDate = datetime.newInstance(2016, 1, 1, 12, 30, 0);

        Product_Repair__c pr2 = new Product_Repair__c(Repair_Technician__c = 'Bill Grider', RecordTypeId = rt.id, Product_Item__c = pi.id, Repair_date__c = myDate, Previous_Test__c = pt.id, Post_Test__c = pt.id, Part_to_Harvest__c = 'Array Carriage');
        insert pr2;

    }

    /*@IsTest
    static void repairTechNameUpdate() {

        List<Product2> pToInsert = new List<Product2>();

        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'test';
        p.Probe_Type__c = 'Linear';
        pToInsert.add(p);

        Product2 p2 = TestDataFactory.createProduct('Ultrasound Probe', false);
        p2.Name = 'Array - test';
        p2.Probe_Type__c = 'Linear';
        p2.Family = 'Ultrasound Part';
        p2.Parent_Product__c = p.Id;
        pToInsert.add(p2);

        insert pToInsert;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'Cage', Receive_date__c = Date.today());
        insert pi;

        ProductTest__c pt = new ProductTest__c(Test_Completed_By__c = 'Andres Carvajal', Last_4_Characters_of_SN__c = '1234', Name = String.valueOf(Date.today()), Product_Item__c = pi.Id);
        insert pt;

        //Needed for Natalie's code
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SobjectType = 'Product_Repair__c' AND Name = 'Harvest' LIMIT 1];

        Datetime myDate = Datetime.newInstance(2016, 1, 1, 12, 30, 0);

        Product_Repair__c pr2 = new Product_Repair__c(RecordTypeId = rt.Id, Product_Item__c = pi.Id,
                Repair_date__c = myDate, Previous_Test__c = pt.Id, Repair_Technician__c = 'Bill Grider', 
                Post_Test__c = pt.Id, Part_to_Harvest__c = 'Array Carriage');
        insert pr2;

        // create a user who is in the picklist choices for Repair_Technician__c
        User u = TestDataFactory.createUser('Tampa', 'Tech', true);

        Test.startTest();

        System.debug('TEST - start of test');
        pr2.Repair_Technician__c = u.FirstName + ' ' + u.LastName;
        update pr2;
        Test.stopTest();

        Product_Repair__c prToCheck = [SELECT Id, OwnerId FROM Product_Repair__c WHERE Id = :pr2.Id LIMIT 1];

        System.assertEquals(u.Id, prToCheck.OwnerId, 'Product_Repair__c owner is not set when Repair_Technician__c is changed.');

    }*/

    @IsTest
    static void testLastRepairDate(){

        List<Product2> pToInsert = new List<Product2>();

        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'test';
        p.Probe_Type__c = 'Linear';
        pToInsert.add(p);

        Product2 p2 = TestDataFactory.createProduct('Ultrasound Probe', false);
        p2.Name = 'Array - test';
        p2.Probe_Type__c = 'Linear';
        p2.Family = 'Ultrasound Part';
        p2.Parent_Product__c = p.Id;
        pToInsert.add(p2);

        insert pToInsert;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'Cage', Receive_date__c = Date.today());
        insert pi;

        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SobjectType = 'Product_Repair__c' AND Name = 'Harvest' LIMIT 1];

        Datetime myDate = Datetime.newInstance(2016, 1, 1, 12, 30, 0);

        Product_Repair__c pr2 = new Product_Repair__c(RecordTypeId = rt.Id, Product_Item__c = pi.Id, Repair_Technician__c = 'Bill Grider', 
                Repair_date__c = myDate, Part_to_Harvest__c = 'Array Carriage');


        Test.startTest();

        System.debug('TEST - start of test');
        insert pr2;

        Test.stopTest();

        ProductItem__c piToCheck = [SELECT Id, Last_Repair__c FROM ProductItem__c WHERE Id = :pi.Id LIMIT 1];

        System.assertEquals(myDate, piToCheck.Last_Repair__c, 'Product_Repair__c did not set parent ProductItem__c Last_Repair__c date correctly');
    }

    @IsTest
    static void testPItemCRatingCleared() {

        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'test';
        p.Probe_Type__c = 'Sector';
        p.Family = 'Ultrasound Part';
        insert p;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'Cage', Receive_date__c = System.today(), Cosmetic_Rating__c = 'Good');
        insert pi;

        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SobjectType = 'Product_Repair__c' AND Name = 'Cosmetic Repair' LIMIT 1];

        Datetime myDate = Datetime.newInstance(2016, 1, 1, 12, 30, 0);

        Product_Repair__c pr = new Product_Repair__c(RecordTypeId = rt.Id, Product_Item__c = pi.Id);
        insert pr;

        Test.startTest();

        System.debug('TEST: starting here');
        ProductItem__c pItemCheck = [SELECT Id, Cosmetic_Rating__c FROM ProductItem__c WHERE Id = :pi.Id LIMIT 1];
        System.assertEquals('Good', pItemCheck.Cosmetic_Rating__c, 'PItem Cosmetic_Rating not correct after Product_Repair Insert');
        pr.Repair_Technician__c = 'Bill Grider';
        pr.Repair_date__c = myDate;
        update pr;
        Test.stopTest();

        ProductItem__c pItemCheckAgain = [SELECT Id, Cosmetic_Rating__c FROM ProductItem__c WHERE Id = :pi.Id LIMIT 1];
        System.assertEquals(null, pItemCheckAgain.Cosmetic_Rating__c, 'PItem Cosmetic_Rating not correct after Product_Repair has Repair_Date__c set');

    }

    @IsTest
    static void testPItemFRatingCleared() {

        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'test';
        p.Probe_Type__c = 'Sector';
        p.Family = 'Ultrasound Part';
        insert p;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'Cage', Receive_date__c = System.today(), Functional_Rating__c = 'Good');
        insert pi;

        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SobjectType = 'Product_Repair__c' AND Name = 'Functional Repair' LIMIT 1];

        Datetime myDate = Datetime.newInstance(2016, 1, 1, 12, 30, 0);

        Product_Repair__c pr = new Product_Repair__c(RecordTypeId = rt.Id, Product_Item__c = pi.Id);
        insert pr;

        Test.startTest();
        System.debug('TEST: starting here');

        ProductItem__c pItemCheck = [SELECT Id, Functional_Rating__c FROM ProductItem__c WHERE Id = :pi.Id LIMIT 1];
        System.assertEquals('Good', pItemCheck.Functional_Rating__c, 'PItem Functional_Rating__c not correct after Product_Repair Insert');
        pr.Repair_Technician__c = 'Bill Grider';
        pr.Repair_date__c = myDate;
        update pr;
        Test.stopTest();

        ProductItem__c pItemCheckAgain = [SELECT Id, Functional_Rating__c FROM ProductItem__c WHERE Id = :pi.Id LIMIT 1];
        System.assertEquals(null, pItemCheckAgain.Functional_Rating__c, 'PItem Functional_Rating__c not correct after Product_Repair has Repair_Date__c set');

    }

}