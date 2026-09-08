/**
 * Created by jeff on 8/15/18.
 */

@IsTest
private class TemporaryTests {

    @isTest
    static void repEvalFrom(){

        try{
            Product2 pro = new Product2 (Name='Ultrasound Probe-Philips C5-1',probe_type__c='Linear',Max_Repair__c=100000,Sug_Pr_Ex__c=200,Qty_Ready_to_Ship__c=0,
                    Max_Non_Functional__c=200000,Cable_Advanced_Whitening__c=500,Cable_Jacket_Splice__c=500,Connector_Housing_Replacement__c=500,
                    Connector_Housing_Paint__c=500,Refurb__c=500,Lens_Refurb__c=500,Lens_Remove__c=500,Lens_Relens__c=500,Strain_Relief_Remove__c=500,
                    Strain_Relief_Replacement__c=500,Array_Replacement__c=800,Cable_Replacement__c=800,Cap_Replacement_with_Oil_Fill__c=800,
                    Connector_Repair__c=800,Electrical__c=800,Motor_Repair__c=800,Oil_Fill__c=800,Probe_Handle_Close__c=800,Probe_Handle_Open__c=800,
                    Probe_Handle_Replacement__c=800,Retermination__c=800,Bending_Rubber_Glue_Beads_Replacement__c=500,Control_Housing_Polish__c=500,
                    Grommet_Replacement__c=500,Knob_Replacement__c=500,Lens_Remove_Coating_RTV_Seal_Replacement__c=500,RTV_Seal_Replacement__c=500,
                    Tip_Polish__c=500,Array_Drive_Switch_or_Board_Replacement__c=800,Array_Drive_System_Replacement__c=800,Connector_Boards_Replacement__c=800,
                    Control_Housing_Overhaul__c=800,Insertion_Tube_Replacement__c=800,Steering_Cable_Adjustment__c=800, Steering_Cable_Replacement__c=800,
                    Tip_Overhaul__c=800,Cable_Prep__c=600,Flex_Bonding_Repair__c=600,Re_Lens__c=200,Strain_Relief__c=200,Mechanical__c=200,Re_Paint_Connector__c=200,
                    Replace_Housing__c=200,Replace_Knob__c=200,Pins__c=200,Replace_Handle__c=200,Advanced_Cable_Whitening__c=200,Reverse_Probe_Handle__c=200,
                    Re_Termination__c=200,Oil_Fill_and_Cap_Replacement__c=200,Replace_Bending_Rubber__c=200,Replace_Glue_Beads__c=200,Re_coat_Re_Label__c=200,
                    Adjust_Steering_Cable__c=200,Motor_Replacement__c=200,Connector_Overhaul__c=200,Switch_Replacement_TEE__c=200,Tip_Replacement__c=200,
                    Probe_Handle_Reverse__c=100, Tip_Lens_Film_Removal__c = 100, Full_Overhaul__c=200, Array_Carriage_Replacement__c = 900,
                    Cable_Jacket_Refurbishment__c = 900, Cap_Refurbishment__c = 900, Connector_Refurbishment__c = 900, Probe_Handle_Refurbishment__c = 900,
                    Strain_Relief_Refurbishment__c = 900, Ferrule_Assembly__c = 1, OEM__c = 'GE_Healthcare', Part_Type__c = 'Assembly', Modality__c = 'Ultrasound');
            insert pro;

            ProductItem__c prItem = new ProductItem__c (Product_Name__c=pro.Id,Model__c='Philips C5-1',Image__c='https://drive.google.com/drive/folders/0BzmqJILtsGQ8ME0tZ0pzeUtpbVk',
                    Serial_No__c='B0K81J',Functional_Rating__c='B',Functional_Notes__c='Good',
                    Cosmetic_Rating__c='C',Cosmetic_Notes__c='Yellow Cable',
                    Location__c='WIP',
                    PO_Number__c='2425',
                    Other_Notes__c='Cable needs cleaned',Added_To_Opportunity__c = false,Receive_date__c=Date.parse('01/08/2015'));
            insert prItem;

            ProductTest__c ptest = new ProductTest__c(Product_Item__c=prItem.id,Cos_evaluation__c='abc',Fun_evaluation__c='cxv',Cosmetic_Bending_rubber__c='no problem',Cosmetic_Cable_jacket__c='no problem',Cosmetic_Cap__c='no problem',Cosmetic_Connector__c='no problem',Cosmetic_Insertion_tube__c='no problem',Cosmetic_Lens__c='no problem',Cosmetic_Probe_Handle__c='no problem',
                    Cosmetic_Strain_Relief__c='no problem',Cosmetic_Tip__c='no problem',Functional_Airscan__c='no problem',Functional_Articulation__c='no problem',Functional_Color_artifacts__c='no problem',Functional_CW_artifacts__c='no problem',Functional_CW_Pulse__c='no problem',Functional_First_Call__c='no problem',Functional_If_motor__c='no problem',
                    Functional_Image__c='no problem',Functional_Leakage_current__c='no problem',Functional_Motor__c='no problem',Other_Notes_Cosmetic__c='abcd',Other_Notes_Functional__c='abcd');
            insert ptest;

            Account acc = new Account(name='abc',BillingStreet='vvv',BillingCity='iii',BillingCountry='zzz',BillingPostalCode='4582',BillingState='rrr');
            insert acc;

            opportunity opp = new opportunity(Name='newopp',AccountId=acc.Id,CloseDate=Date.parse('12/13/2014'),StageName='Prospecting');
            insert opp;

            RecordType rc = [select id from  RecordType where DeveloperName ='Customer_Repair_Evaluation'];
            RMA__c rma = new RMA__c(RecordTypeId=rc.id,ProductItem__c=prItem.id,Quality_Issue_Reported__c='report',Opportunity__c=opp.Id,Loaner_Asset_Number__c=prItem.id,Date_RMA_Item_Received__c=system.today());
            insert rma;
            String downloadURL;
            if(prItem.Image__c != null)
            {
                String temp = prItem.Image__c.reverse();
                String temp1=temp.substringBefore('/');
                downloadURL = temp1.reverse();
            }

        } catch(Exception e){

        }

    }

    @isTest static void repEvalView(){

        try{

            Product2 pro = new Product2 (Name='Ultrasound Probe-Philips C5-1',probe_type__c='Linear',Max_Repair__c=100000,Sug_Pr_Ex__c=200,Qty_Ready_to_Ship__c=0,
                    Max_Non_Functional__c=200000,Cable_Advanced_Whitening__c=500,Cable_Jacket_Splice__c=500,Connector_Housing_Replacement__c=500,
                    Connector_Housing_Paint__c=500,Refurb__c=500,Lens_Refurb__c=500,Lens_Remove__c=500,Lens_Relens__c=500,Strain_Relief_Remove__c=500,
                    Strain_Relief_Replacement__c=500,Array_Replacement__c=800,Cable_Replacement__c=800,Cap_Replacement_with_Oil_Fill__c=800,
                    Connector_Repair__c=800,Electrical__c=800,Motor_Repair__c=800,Oil_Fill__c=800,Probe_Handle_Close__c=800,Probe_Handle_Open__c=800,
                    Probe_Handle_Replacement__c=800,Retermination__c=800,Bending_Rubber_Glue_Beads_Replacement__c=500,Control_Housing_Polish__c=500,
                    Grommet_Replacement__c=500,Knob_Replacement__c=500,Lens_Remove_Coating_RTV_Seal_Replacement__c=500,RTV_Seal_Replacement__c=500,
                    Tip_Polish__c=500,Array_Drive_Switch_or_Board_Replacement__c=800,Array_Drive_System_Replacement__c=800,Connector_Boards_Replacement__c=800,
                    Control_Housing_Overhaul__c=800,Insertion_Tube_Replacement__c=800,Steering_Cable_Adjustment__c=800, Steering_Cable_Replacement__c=800,
                    Tip_Overhaul__c=800,Cable_Prep__c=600,Flex_Bonding_Repair__c=600,Re_Lens__c=200,Strain_Relief__c=200,Mechanical__c=200,Re_Paint_Connector__c=200,
                    Replace_Housing__c=200,Replace_Knob__c=200,Pins__c=200,Replace_Handle__c=200,Advanced_Cable_Whitening__c=200,Reverse_Probe_Handle__c=200,
                    Re_Termination__c=200,Oil_Fill_and_Cap_Replacement__c=200,Replace_Bending_Rubber__c=200,Replace_Glue_Beads__c=200,Re_coat_Re_Label__c=200,
                    Adjust_Steering_Cable__c=200,Motor_Replacement__c=200,Connector_Overhaul__c=200,Switch_Replacement_TEE__c=200,Tip_Replacement__c=200,
                    Probe_Handle_Reverse__c=100, Tip_Lens_Film_Removal__c = 100, Full_Overhaul__c=200, Array_Carriage_Replacement__c = 900,
                    Cable_Jacket_Refurbishment__c = 900, Cap_Refurbishment__c = 900, Connector_Refurbishment__c = 900, Probe_Handle_Refurbishment__c = 900,
                    Strain_Relief_Refurbishment__c = 900, Ferrule_Assembly__c = 1, OEM__c = 'GE_Healthcare', Part_Type__c = 'Assembly', Modality__c = 'Ultrasound');
            insert pro;

            ProductItem__c prItem = new ProductItem__c (Product_Name__c=pro.Id,Model__c='Philips C5-1',Image__c='https://drive.google.com/drive/folders/0BzmqJILtsGQ8ME0tZ0pzeUtpbVk',
                    Serial_No__c='B0K81J',Functional_Rating__c='B',Functional_Notes__c='Good',
                    Cosmetic_Rating__c='C',Cosmetic_Notes__c='Yellow Cable',
                    Location__c='WIP',
                    PO_Number__c='2425',
                    Other_Notes__c='Cable needs cleaned',Added_To_Opportunity__c = false,Receive_date__c=Date.parse('01/08/2015'));
            insert prItem;

            ProductTest__c ptest = new ProductTest__c(Product_Item__c=prItem.id,Cos_evaluation__c='abc',Fun_evaluation__c='cxv',Cosmetic_Bending_rubber__c='no problem',Cosmetic_Cable_jacket__c='no problem',Cosmetic_Cap__c='no problem',Cosmetic_Connector__c='no problem',Cosmetic_Insertion_tube__c='no problem',Cosmetic_Lens__c='no problem',Cosmetic_Probe_Handle__c='no problem',
                    Cosmetic_Strain_Relief__c='no problem',Cosmetic_Tip__c='no problem',Functional_Airscan__c='no problem',Functional_Articulation__c='no problem',Functional_Color_artifacts__c='no problem',Functional_CW_artifacts__c='no problem',Functional_CW_Pulse__c='no problem',Functional_First_Call__c='no problem',Functional_If_motor__c='no problem',
                    Functional_Image__c='no problem',Functional_Leakage_current__c='no problem',Functional_Motor__c='no problem',Other_Notes_Cosmetic__c='abcd',Other_Notes_Functional__c='abcd');
            insert ptest;

            Account acc = new Account(name='abc',BillingStreet='vvv',BillingCity='iii',BillingCountry='zzz',BillingPostalCode='4582',BillingState='rrr');
            insert acc;

            opportunity opp = new opportunity(Name='newopp',AccountId=acc.Id,CloseDate=Date.parse('12/13/2014'),StageName='Prospecting');
            insert opp;

            RecordType rc = [select id from  RecordType where DeveloperName ='Customer_Repair_Evaluation'];
            RMA__c rma = new RMA__c(RecordTypeId=rc.id,ProductItem__c=prItem.id,Quality_Issue_Reported__c='report',Opportunity__c=opp.Id,Loaner_Asset_Number__c=prItem.id,Date_RMA_Item_Received__c=system.today());
            insert rma;
            String downloadURL;
            if(prItem.Image__c != null)
            {
                String temp = prItem.Image__c.reverse();
                String temp1=temp.substringBefore('/');
                downloadURL = temp1.reverse();
            }

        } catch(Exception e){

        }

    }

    @isTest(seeAllData=true) static void mytest(){

        User theUser;
        try{
            theUser = [select id from User where alias = 'dtrog' and isActive = true LIMIT 1];
        } catch(Exception e){
            system.assert(false, 'Unable to find a user to RunAs.  Looking for Alias of dtrog');
        }


        System.runAs(theUser) {

            Account acc = new Account(name = 'abc');
            insert acc;

            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
            pro.Name = 'Ultrasound Probe-Philips C5-1';
            insert pro;

            ProductItem__c prItem1 = new ProductItem__c(Product_Name__c = pro.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '12345', Receive_date__c = Date.parse('01/08/2015'), Cost__c = 1000.00, Location__c = 'WIP', Purchasing_Approved__c = true);
            insert prItem1;


            opportunity opp = new opportunity(Name = 'newopp', AccountId = acc.Id, CloseDate = Date.parse('12/13/2014'), StageName = 'Qualification', Shipping_From_Location__c = 'Fishers, IN', Confirmation_number__c = '12345');
            insert opp;
            opp.StageName = 'Closed Won';
            opp.Customer_PO__C = '1234';
            update opp;

            pricebook2 pb = [select id from Pricebook2 where isStandard = true];

            PricebookEntry pbe = new PricebookEntry (Pricebook2Id = pb.id, Product2Id = pro.Id, IsActive = true, UnitPrice = 100.00);
            insert pbe;

            OpportunityLineItem oppli = new OpportunityLineItem(opportunityId = opp.Id, PricebookEntryId = pbe.Id, ProductItem__c = prItem1.Id, Quantity = 1, TotalPrice = 100.00, Purchasing_Approved__c = true);
            insert oppli;
            //update oppli;
            delete oppli;

        }
    }


    static testmethod void test() {

        User theUser;
        try{
            theUser = [select id from User where alias = 'dtrog' and isActive = true LIMIT 1];
        } catch(Exception e){
            system.assert(false, 'Unable to find a user to RunAs.  Looking for Alias of dtrog');
        }


        System.runAs(theUser) {

            Account acc = new Account(name = 'abc');
            insert acc;

            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
            pro.Name = 'Ultrasound Probe-Philips C5-1';
            insert pro;

            ProductItem__c prItem1 = new ProductItem__c(Product_Name__c = pro.Id, Check_In_Type__c = 'Purchase', Sold__c = true, Serial_No__c = '12345', Receive_date__c = Date.parse('01/08/2015'), Cost__c = 1000.00, Location__c = 'WIP', Purchasing_Approved__c = true);
            insert prItem1;

            RecordType RC = [select id from RecordType where SobjectType = 'Opportunity' AND DeveloperName = 'Sales_Opportunity'];
            opportunity opp = new opportunity(Name = 'newopp', AccountId = acc.Id, CloseDate = Date.parse('12/13/2014'), StageName = 'Closed Won', RecordTypeId = RC.id, Customer_PO__C = '1234', Shipping_From_Location__c = 'Fishers, IN', Confirmation_number__c = '12345');
            insert opp;

            Id pbId = test.getStandardPricebookId(); //[select id from Pricebook2 where isStandard=true];

            PricebookEntry pbe = new PricebookEntry (Pricebook2Id = pbId, Product2Id = pro.Id, IsActive = true, UnitPrice = 100.00);
            insert pbe;

            OpportunityLineItem oppli = new OpportunityLineItem(opportunityId = opp.Id, PricebookEntryId = pbe.Id, ProductItem__c = prItem1.Id, Quantity = 1, TotalPrice = 100.00, Purchasing_Approved__c = true);
            insert oppli;

            //Test.startTest();
            UpdateProductFieldBatch upfb = new UpdateProductFieldBatch();
            Database.executeBatch(upfb, 1);
            //Test.stopTest();

        }

    }


    static testmethod void test1() {

        User theUser;
        try{
            theUser = [select id from User where alias = 'dtrog' and isActive = true LIMIT 1];
        } catch(Exception e){
            system.assert(false, 'Unable to find a user to RunAs.  Looking for Alias of dtrog');
        }


        System.runAs(theUser) {

            Account acc = new Account(name = 'abcd');
            insert acc;

            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
            pro.Name = 'Ultrasound Probe-Acuson 4V1C';
            insert pro;

            ProductItem__c prItem1 = new ProductItem__c(Product_Name__c = pro.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '10613003',
                    Cosmetically_Repairable__c = 'Yes', Functionally_Repairable__c = 'Yes', Functional_Rating__c = 'Good',
                    Cosmetic_Rating__c = 'Good', Receive_date__c = Date.parse('01/08/2015'),
                    Cost__c = 15000.00, Purchasing_Approved__c = true);
            insert prItem1;

            RecordType RC = [select id from RecordType where SobjectType = 'Opportunity' AND DeveloperName = 'Sales_Opportunity'];
            opportunity opp = new opportunity(Name = 'newopp', AccountId = acc.Id, CloseDate = Date.parse('12/13/2014'), StageName = 'Qualification', RecordTypeId = RC.id, Shipping_From_Location__c = 'Fishers, IN');
            insert opp;

            Id pbId = test.getStandardPricebookId(); //[select id from Pricebook2 where isStandard=true];

            PricebookEntry pbe = new PricebookEntry (Pricebook2Id = pbId, Product2Id = pro.Id, IsActive = true, UnitPrice = 1000.00);
            insert pbe;

            OpportunityLineItem oppli = new OpportunityLineItem(opportunityId = opp.Id, PricebookEntryId = pbe.Id, ProductItem__c = prItem1.Id, Quantity = 1, TotalPrice = 1000.00, Purchasing_Approved__c = true);
            insert oppli;

            UpdateProductFieldBatch upfb = new UpdateProductFieldBatch();
            Database.executeBatch(upfb, 1);

        }
    }

    static testmethod void test2() {

        User theUser;
        try{
            theUser = [select id from User where alias = 'dtrog' and isActive = true LIMIT 1];
        } catch(Exception e){
            system.assert(false, 'Unable to find a user to RunAs.  Looking for Alias of dtrog');
        }


        System.runAs(theUser) {

            Account acc = new Account(name = 'abcdgh');
            insert acc;

            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
            pro.Name = 'Ultrasound Probe-Acuson 4V1C';
            insert pro;

            ProductItem__c prItem1 = new ProductItem__c(Product_Name__c = pro.Id, Check_In_Type__c = 'Purchase', Generic_Product__c = true, Serial_No__c = '10613003', Receive_date__c = Date.parse('01/08/2015'), Cost__c = 15000.00, Location__c = 'Finished Goods', Purchasing_Approved__c = true);
            insert prItem1;

            RecordType RC = [select id from RecordType where SobjectType = 'Opportunity' AND DeveloperName = 'Sales_Opportunity'];
            opportunity opp = new opportunity(Name = 'newopp', AccountId = acc.Id, CloseDate = Date.parse('12/13/2014'), StageName = 'Closed Won', RecordTypeId = RC.id, Customer_PO__c = '1234', Shipping_From_Location__c = 'Fishers, IN', Confirmation_number__c = '12345');
            insert opp;

            Id pbId = test.getStandardPricebookId(); //[select id from Pricebook2 where isStandard=true];

            PricebookEntry pbe = new PricebookEntry (Pricebook2Id = pbId, Product2Id = pro.Id, IsActive = true, UnitPrice = 1000.00);
            insert pbe;

            OpportunityLineItem oppli = new OpportunityLineItem(opportunityId = opp.Id, PricebookEntryId = pbe.Id, ProductItem__c = prItem1.Id, Quantity = 1, TotalPrice = 1000.00, Purchasing_Approved__c = true);
            insert oppli;

            UpdateProductFieldBatch upfb = new UpdateProductFieldBatch();
            Database.executeBatch(upfb, 1);
            System.schedule('Scheduled Job 7', '0 0 * * * ?', new UpdateProductFieldBatch());

        }
    }

    static testmethod void test3() {

        User theUser;
        try{
            theUser = [select id from User where alias = 'dtrog' and isActive = true LIMIT 1];
        } catch(Exception e){
            system.assert(false, 'Unable to find a user to RunAs.  Looking for Alias of dtrog');
        }


        System.runAs(theUser) {

            Account acc = new Account(name = 'abcd');
            insert acc;

            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
            pro.Name = 'Ultrasound Probe-Acuson 4V1C';
            insert pro;

            ProductItem__c prItem1 = new ProductItem__c(Product_Name__c = pro.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '10613003', Receive_date__c = Date.parse('01/08/2015'), Cost__c = 15000.00, Location__c = 'Customer Loan / Demo',
                    Functional_Rating__c = 'Good', Purchasing_Approved__c = true);
            insert prItem1;

            RecordType RC = [select id from RecordType where SobjectType = 'Opportunity' AND DeveloperName = 'Sales_Opportunity'];
            opportunity opp = new opportunity(Name = 'newopp', AccountId = acc.Id, CloseDate = Date.parse('12/13/2014'), StageName = 'Qualification', RecordTypeId = RC.id, Shipping_From_Location__c = 'Fishers, IN');
            insert opp;

            Id pbId = test.getStandardPricebookId(); //[select id from Pricebook2 where isStandard=true];

            PricebookEntry pbe = new PricebookEntry (Pricebook2Id = pbId, Product2Id = pro.Id, IsActive = true, UnitPrice = 1000.00);
            insert pbe;

            OpportunityLineItem oppli = new OpportunityLineItem(opportunityId = opp.Id, PricebookEntryId = pbe.Id, ProductItem__c = prItem1.Id, Quantity = 1, TotalPrice = 1000.00, Purchasing_Approved__c = true);
            insert oppli;

            UpdateProductFieldBatch upfb = new UpdateProductFieldBatch();
            Database.executeBatch(upfb, 1);

        }
    }

    static testMethod void mytestXX(){
        Product2 pro = new Product2 (Name='Ultrasound Probe-Philips C5-1', Sug_Pr_Out__c = 1000, Sug_Pr_Ex__c = 1000,
                Std_Cost_Out__c = 1000, Std_Cost_Ex__c = 1000, OEM__c = 'GE_Healthcare', Part_Type__c = 'Assembly', Modality__c = 'Ultrasound' );
        insert pro;
        pro.Sug_Pr_Ex__c = 2000;
        pro.Sug_Pr_Out__c = 2000;
        pro.Std_Cost_ex__c = 2000;
        pro.Std_Cost_Out__c = 2000;
        update pro;
    }

    static testMethod void mytest2() {

        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'test';
        p.Probe_Type__c = 'Sector';
        p.Family = 'Ultrasound Part';
        insert p;

        ProductItem__c newPitem = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = 'S00', Cost__c = 100.20, Location__c = 'Cage', Receive_date__c = System.today());
        insert newPitem;

        ProductTest__c newPTest= new ProductTest__c(Product_Item__c=newPitem.Id,Cosmetic_Bending_rubber__c='light discoloration');
        insert newPTest;

        RecordType RC = [select id from  RecordType where SobjectType='Product_Repair__c' AND DeveloperName='Cosmetic_Repair'];
        Product_Repair__c newPrepair = new Product_Repair__c(Repair_Time__c = '1', Repair_date__c = System.now(), Repair_Activity__c = 'Refurb', Repair_Technician__c = 'Be Tran', Product_Item__c = newPitem.Id, RecordTypeId = RC.id,Repair_Notes__c='Test Note',The_Date_Last_Test_Completed__c=String.ValueOf(newPTest.CreatedDate));
        insert newPrepair;
    }

    static testMethod void mytest1() {

        Product2 p = new Product2 (Name='Ultrasound Probe-Philips C5-1',probe_type__c='Linear',Max_Repair__c=100000,Sug_Pr_Ex__c=200,Qty_Ready_to_Ship__c=0,
                Max_Non_Functional__c=200000,Cable_Advanced_Whitening__c=500,Cable_Jacket_Splice__c=500,Connector_Housing_Replacement__c=500,
                Connector_Housing_Paint__c=500,Refurb__c=500,Lens_Refurb__c=500,Lens_Remove__c=500,Lens_Relens__c=500,Strain_Relief_Remove__c=500,
                Strain_Relief_Replacement__c=500,Array_Replacement__c=800,Cable_Replacement__c=800,Cap_Replacement_with_Oil_Fill__c=800,
                Connector_Repair__c=800,Electrical__c=800,Motor_Repair__c=800,Oil_Fill__c=800,Probe_Handle_Close__c=800,Probe_Handle_Open__c=800,
                Probe_Handle_Replacement__c=800,Retermination__c=800,Bending_Rubber_Glue_Beads_Replacement__c=500,Control_Housing_Polish__c=500,
                Grommet_Replacement__c=500,Knob_Replacement__c=500,Lens_Remove_Coating_RTV_Seal_Replacement__c=500,RTV_Seal_Replacement__c=500,
                Tip_Polish__c=500,Array_Drive_Switch_or_Board_Replacement__c=800,Array_Drive_System_Replacement__c=800,Connector_Boards_Replacement__c=800,
                Control_Housing_Overhaul__c=800,Insertion_Tube_Replacement__c=800,Steering_Cable_Adjustment__c=800, Steering_Cable_Replacement__c=800,
                Tip_Overhaul__c=800,Cable_Prep__c=600,Flex_Bonding_Repair__c=600,Re_Lens__c=200,Strain_Relief__c=200,Mechanical__c=200,Re_Paint_Connector__c=200,
                Replace_Housing__c=200,Replace_Knob__c=200,Pins__c=200,Replace_Handle__c=200,Advanced_Cable_Whitening__c=200,Reverse_Probe_Handle__c=200,
                Re_Termination__c=200,Oil_Fill_and_Cap_Replacement__c=200,Replace_Bending_Rubber__c=200,Replace_Glue_Beads__c=200,Re_coat_Re_Label__c=200,
                Adjust_Steering_Cable__c=200,Motor_Replacement__c=200,Connector_Overhaul__c=200,Switch_Replacement_TEE__c=200,Tip_Replacement__c=200,
                Probe_Handle_Reverse__c=100, Tip_Lens_Film_Removal__c = 100, Full_Overhaul__c=200, OEM__c = 'GE_Healthcare', Part_Type__c = 'Assembly', Modality__c = 'Ultrasound');
        insert p;

        ProductItem__c newPitem = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = 'S00', Cost__c = 100.20, Location__c = 'Cage', Receive_date__c = System.today());
        insert newPitem;

        ProductTest__c newPTest= new ProductTest__c(Product_Item__c=newPitem.Id,Cosmetic_Bending_rubber__c='light discoloration');
        insert newPTest;

        RecordType RC = [select id from  RecordType where SobjectType='Product_Repair__c' AND DeveloperName='Cosmetic_Repair'];
        Product_Repair__c newPrepair = new Product_Repair__c(Repair_Time__c = '1', Repair_date__c = System.now(), Repair_Activity__c = 'Refurb', Repair_Technician__c = 'Be Tran', Product_Item__c = newPitem.Id, RecordTypeId = RC.id,Repair_Notes__c='Test Note',The_Date_Last_Test_Completed__c=String.ValueOf(newPTest.CreatedDate));
        insert newPrepair;
    }

    static testmethod void testXXX() {

        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'test';
        p.Probe_Type__c = 'Sector';
        p.Family = 'Ultrasound Part';
        insert p;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id,Check_In_Type__c='Purchase', Serial_No__c='64603208',
                Cost__c=259.57, Location__c='Repair Area', Receive_date__c=system.today(), Purchasing_Approved__c = true);
        insert pi;

        ProductTest__c pt = new ProductTest__c(Name=String.valueOf(System.today()), Product_Item__c=pi.id);
        insert pt;

        //Needed for Natalie's code
        RecordType rt =[select id,Name from RecordType where sObjectType = 'Product_Repair__c' AND Name='Cosmetic Repair' limit 1];

        datetime myDate = datetime.newInstance(2016, 1, 1, 12, 30, 0);

        Product_Repair__c pr = new Product_Repair__c(RecordTypeId = rt.id, Product_Item__c=pi.id, Repair_date__c= myDate, Previous_Test__c=pt.id, Post_Test__c=pt.id);
        insert pr;
        pr.Repair_Technician__c = 'Bill Grider';
        update pr;

    }
    static testmethod void test1x() {

        Product2 p = new Product2 (Name='Ultrasound Probe-Philips C5-1',probe_type__c='Linear',Max_Repair__c=100000,Sug_Pr_Ex__c=200,Qty_Ready_to_Ship__c=0,
                Max_Non_Functional__c=200000,Cable_Advanced_Whitening__c=500,Cable_Jacket_Splice__c=500,Connector_Housing_Replacement__c=500,
                Connector_Housing_Paint__c=500,Refurb__c=500,Lens_Refurb__c=500,Lens_Remove__c=500,Lens_Relens__c=500,Strain_Relief_Remove__c=500,
                Strain_Relief_Replacement__c=500,Array_Replacement__c=800,Cable_Replacement__c=800,Cap_Replacement_with_Oil_Fill__c=800,
                Connector_Repair__c=800,Electrical__c=800,Motor_Repair__c=800,Oil_Fill__c=800,Probe_Handle_Close__c=800,Probe_Handle_Open__c=800,
                Probe_Handle_Replacement__c=800,Retermination__c=800,Bending_Rubber_Glue_Beads_Replacement__c=500,Control_Housing_Polish__c=500,
                Grommet_Replacement__c=500,Knob_Replacement__c=500,Lens_Remove_Coating_RTV_Seal_Replacement__c=500,RTV_Seal_Replacement__c=500,
                Tip_Polish__c=500,Array_Drive_Switch_or_Board_Replacement__c=800,Array_Drive_System_Replacement__c=800,Connector_Boards_Replacement__c=800,
                Control_Housing_Overhaul__c=800,Insertion_Tube_Replacement__c=800,Steering_Cable_Adjustment__c=800, Steering_Cable_Replacement__c=800,
                Tip_Overhaul__c=800,Cable_Prep__c=600,Flex_Bonding_Repair__c=600,Re_Lens__c=200,Strain_Relief__c=200,Mechanical__c=200,Re_Paint_Connector__c=200,
                Replace_Housing__c=200,Replace_Knob__c=200,Pins__c=200,Replace_Handle__c=200,Advanced_Cable_Whitening__c=200,Reverse_Probe_Handle__c=200,
                Re_Termination__c=200,Oil_Fill_and_Cap_Replacement__c=200,Replace_Bending_Rubber__c=200,Replace_Glue_Beads__c=200,Re_coat_Re_Label__c=200,
                Adjust_Steering_Cable__c=200,Motor_Replacement__c=200,Connector_Overhaul__c=200,Switch_Replacement_TEE__c=200,Tip_Replacement__c=200,
                Probe_Handle_Reverse__c=100, Tip_Lens_Film_Removal__c = 100, Full_Overhaul__c=200, Array_Carriage_Replacement__c = 900,
                Cable_Jacket_Refurbishment__c = 900, Cap_Refurbishment__c = 900, Connector_Refurbishment__c = 900, Probe_Handle_Refurbishment__c = 900,
                Strain_Relief_Refurbishment__c = 900, OEM__c = 'GE_Healthcare', Part_Type__c = 'Assembly', Modality__c = 'Ultrasound');
        insert p;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id,Check_In_Type__c='Customer Repair', Serial_No__c='64603209',
                Cost__c=259.57, Location__c='Repair Area', Receive_date__c=system.today(), Purchasing_Approved__c = true);
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
        ProductTest__c pt = new ProductTest__c(Name=String.valueOf(System.today()), Product_Item__c=pi.id);
        insert pt;

        //needed for Natalie's code
        RecordType rt2 =[select id,Name from RecordType where sObjectType= 'Product_Repair__c' AND Name='Functional Repair' limit 1];

        datetime myDate = datetime.newInstance(2016, 1, 1, 12, 30, 0);

        Product_Repair__c pr = new Product_Repair__c(RecordTypeId = rt2.id, Product_Item__c=pi.id, Repair_date__c= myDate);
        insert pr;

        Test.startTest();
        ProductTest__c pt1 = new ProductTest__c(Name=String.valueOf(System.today()), Product_Item__c=pi.id);
        insert pt1;
        Test.stopTest();

    }

}