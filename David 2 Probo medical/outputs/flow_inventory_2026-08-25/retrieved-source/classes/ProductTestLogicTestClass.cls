@isTest
public class ProductTestLogicTestClass {

    static testMethod void mytest() {

        Product2 pro = new Product2 (Name = 'Ultrasound Probe-Philips X7-2t', Probe_type__c = 'Transesophageal', Max_Repair__c = 100000, Sug_Pr_Ex__c = 200, Qty_Ready_to_Ship__c = 0,
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
                Probe_Handle_Reverse__c = 100, Tip_Lens_Film_Removal__c = 100, Full_Overhaul__c = 200, OEM__c = 'GE_Healthcare', Part_Type__c = 'Assembly', Modality__c = 'Ultrasound',
                                    Family = 'Ultrasound Probe');
        insert pro;
        
        Product2 newPro = [SELECT Id, Name, Family from Product2 WHERE Id=: pro.Id];
        
        System.debug('THIS IS PRODUCT DATA >> ' + newPro + ' >> ' + newPro.Family);

        ProductItem__c pitem = new ProductItem__c(Product_Name__c = pro.Id, Serial_No__c = 'B0K81J', Check_In_Type__c = 'Purchase', Receive_date__c = Date.parse('01/08/2015'),
                Cosmetic_Rating__c = 'Good', Cosmetically_Repairable__c = 'Yes', Functional_Rating__c = 'Bad', Functionally_Repairable__c = 'No',
                Repair_Evaluation__c = 'refurb', Outsource__c = false);
        
        insert pitem;
        pitem.Product_Name__c = pro.Id; 
        update pitem;
        
        //========================================================================================
        /*  List<Product_Repair__c> productRepairlist = new List<Product_Repair__c>();
          ProductItem__c pi = new ProductItem__c(Product_Name__c=pro.Id,Check_In_Type__c='Purchase', Serial_No__c='64603208', Cost__c=259.57, Location__c='Repair Area', Receive_date__c=system.today());
          insert pi;

          ProductTest__c pt = new ProductTest__c(Name='2015-11-21', Product_Item__c=pi.id);
          insert pt;

          Date myDate = Date.newInstance(2015, 11, 25);
          Product_Repair__c pr = new Product_Repair__c(Product_Item__c=pi.id, Repair_date__c= myDate, Previous_Test__c=pt.id, Post_Test__c=pt.id, Repair_Activity__c = 'Cable Advanced Whitening');
          productRepairlist.add(pr);
          insert productRepairlist;*/
        //========================================================================================
        list<ProductTestData__c> ptestdata = new list<ProductTestData__c>();
        ProductTestData__c ptest1 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Airscan', Field_API_Value__c = 'noticeably irregular',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Tip Overhaul', Repairable__c = 'Yes');
        ptestdata.add(ptest1);
        ProductTestData__c ptest2 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Articulation', Field_API_Value__c = 'Major Slack in Left/Right',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Steering Cable Adjustment', Repairable__c = 'Yes');
        ptestdata.add(ptest2);
        ProductTestData__c ptest3 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Bending Rubber', Field_API_Value__c = 'Heavy Discoloration',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Bending Rubber/Glue Beads Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest3);
        ProductTestData__c ptest4 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Cable Jacket', Field_API_Value__c = 'Heavy Ink Stains',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Cable Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest4);

        ProductTestData__c ptest5 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Color Artifacts', Field_API_Value__c = 'Minor noise at bending section',
                Outsource__c = false, rating__c = 'fair', repair_evaluation__c = 'Cable Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest5);

        ProductTestData__c ptest6 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Connector', Field_API_Value__c = 'Broken Locking Knob',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Knob Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest6);

        ProductTestData__c ptest7 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Control Housing', Field_API_Value__c = 'Major Discoloration',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Control Housing Overhaul', Repairable__c = 'Yes');
        ptestdata.add(ptest7);

        ProductTestData__c ptest8 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'CW Artifacts', Field_API_Value__c = 'Minor noise at bending section',
                Outsource__c = false, rating__c = 'fair', repair_evaluation__c = 'Cable Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest8);

        ProductTestData__c ptest9 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'First Call', Field_API_Value__c = '4+ Dead element',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Array Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest9);

        ProductTestData__c ptest10 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Motor', Field_API_Value__c = 'Motor Sounds Labored',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Array Drive System Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest10);

        ProductTestData__c ptest11 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Image', Field_API_Value__c = 'Dark shadow(s)',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Tip Overhaul', Repairable__c = 'Yes');
        ptestdata.add(ptest11);

        ProductTestData__c ptest12 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Insertion Tube', Field_API_Value__c = 'bite marks-minor',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Insertion Tube Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest12);

        ProductTestData__c ptest13 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Interior', Field_API_Value__c = 'Fluid Intrusion Inside Tip',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Tip Overhaul', Repairable__c = 'Yes');
        ptestdata.add(ptest13);

        ProductTestData__c ptest14 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Leakage Current', Field_API_Value__c = 'Above Upper Limit at Tip',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Tip Overhaul', Repairable__c = 'Yes');
        ptestdata.add(ptest14);

        ProductTestData__c ptest15 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Orientation', Field_API_Value__c = 'Reversed',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Connector Boards Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest15);

        ProductTestData__c ptest16 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Probe Handle', Field_API_Value__c = 'minor scratches',
                Outsource__c = false, rating__c = 'fair', repair_evaluation__c = 'Probe Handle Refurbishment', Repairable__c = 'Yes');
        ptestdata.add(ptest16);

        ProductTestData__c ptest17 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Strain Relief', Field_API_Value__c = 'heavy discoloration',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Cable Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest17);

        ProductTestData__c ptest18 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Tip', Field_API_Value__c = 'Tip Case Cracked',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Tip Overhaul', Repairable__c = 'Yes');
        ptestdata.add(ptest18);

        ProductTestData__c ptest19 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Cap', Field_API_Value__c = 'Not Functioning',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Tip Overhaul', Repairable__c = 'Yes');
        ptestdata.add(ptest19);

        ProductTestData__c ptest20 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Lens', Field_API_Value__c = 'Not Functioning',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Tip Overhaul', Repairable__c = 'Yes');
        ptestdata.add(ptest20);

        ProductTestData__c ptest21 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'CW Pulse', Field_API_Value__c = 'Not Functioning',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Tip Overhaul', Repairable__c = 'Yes');
        ptestdata.add(ptest21);
        ProductTestData__c ptest22 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Strain Relief at Connector', Field_API_Value__c = 'Broken',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Strain Relief Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest22);

        ProductTestData__c ptest23 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Strain Relief at Probe Handle', Field_API_Value__c = 'Broken',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Strain Relief Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest23);

        ProductTestData__c ptest24 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Color Artifacts - High Stress', Field_API_Value__c = 'Exists: minor at SR',
                Outsource__c = false, rating__c = 'fair', repair_evaluation__c = 'Cable Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest24);

        ProductTestData__c ptest25 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'Color Artifacts - Low Stress', Field_API_Value__c = 'Exists: minor at SR',
                Outsource__c = false, rating__c = 'fair', repair_evaluation__c = 'Cable Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest25);

        ProductTestData__c ptest26 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'CW Artifacts - High Stress', Field_API_Value__c = 'Exists: minor at SR',
                Outsource__c = false, rating__c = 'fair', repair_evaluation__c = 'Cable Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest26);

        ProductTestData__c ptest27 = new ProductTestData__c(Probe_Type__c = 'Transesophageal', Field_API_Name__c = 'CW Artifacts - Low Stress', Field_API_Value__c = 'Exists: minor at SR',
                Outsource__c = false, rating__c = 'fair', repair_evaluation__c = 'Cable Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest27);

        insert ptestdata;

        ProductTest__c ptest = new ProductTest__c(Product_Item__c = pitem.id, Cos_evaluation__c = 'abc', Fun_evaluation__c = 'cxv', Cosmetic_Bending_rubber__c = 'Heavy Discoloration',
                Cosmetic_Cable_jacket__c = 'Heavy Ink Stains', Cosmetic_Cap__c = 'Not Functioning', Cosmetic_Connector__c = 'Broken Locking Knob',
                Cosmetic_Insertion_tube__c = 'bite marks-minor', Cosmetic_Lens__c = 'Not Functioning', Cosmetic_Probe_Handle__c = 'minor scratches',
                Cosmetic_Strain_Relief__c = 'heavy discoloration', Cosmetic_Control_Housing__c = 'Major Discoloration', Cosmetic_Tip__c = 'Tip Case Cracked',
                Functional_Airscan__c = 'noticeably irregular', Functional_Articulation__c = 'Major Slack in Left/Right',
                Functional_Color_artifacts__c = 'Minor noise at bending section', Functional_CW_artifacts__c = 'Minor noise at bending section',
                Functional_CW_Pulse__c = 'Not Functioning', Functional_First_Call__c = '4+ Dead element', Functional_Image__c = 'Dark shadow(s)',
                Functional_Leakage_current__c = 'Above Upper Limit at Tip', Functional_Motor__c = 'Motor Sounds Labored', Other_Notes_Cosmetic__c = 'abcd',
                Other_Notes_Functional__c = 'abcd', Functional_Interior__c = 'Fluid Intrusion Inside Tip', Functional_Orientation__c = 'Reversed',
                Cosmetic_Strain_Relief_at_Connector__c = 'Broken', Cosmetic_Strain_Relief_at_Probe_Handle__c = 'Broken', Last_4_Characters_of_SN__c = '1234',
                Test_Completed_By__c = 'Andres Carvajal');
        insert ptest;


    }
    static testMethod void mytest2() {

        Product2 pro = new Product2 (Name = 'Ultrasound Probe-Philips X7-2t', Probe_type__c = 'Phased Array', Max_Repair__c = 100000, Sug_Pr_Ex__c = 200, Qty_Ready_to_Ship__c = 0,
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
                Probe_Handle_Reverse__c = 100, Tip_Lens_Film_Removal__c = 100, Full_Overhaul__c = 200, OEM__c = 'GE_Healthcare', Part_Type__c = 'Assembly', Modality__c = 'Ultrasound');
        insert pro;

        ProductItem__c pitem = new ProductItem__c(Product_Name__c = pro.Id, Serial_No__c = 'B0K81J', Check_In_Type__c = 'Purchase', Receive_date__c = Date.parse('01/08/2015'),
                Cosmetic_Rating__c = 'Good', Cosmetically_Repairable__c = 'Yes', Functional_Rating__c = 'Bad', Functionally_Repairable__c = 'No',
                Repair_Evaluation__c = 'refurb', Outsource__c = false);
        insert pitem;
        pitem.Product_Name__c = pro.Id; 
        update pitem;

        //========================================================================================
        /*  List<Product_Repair__c> productRepairlist = new List<Product_Repair__c>();
          ProductItem__c pi = new ProductItem__c(Product_Name__c=pro.Id,Check_In_Type__c='Purchase', Serial_No__c='64603208', Cost__c=259.57, Location__c='Repair Area', Receive_date__c=system.today());
          insert pi;

          ProductTest__c pt = new ProductTest__c(Name='2015-11-21', Product_Item__c=pi.id);
          insert pt;

          Date myDate = Date.newInstance(2015, 11, 25);
          Product_Repair__c pr = new Product_Repair__c(Product_Item__c=pi.id, Repair_date__c= myDate, Previous_Test__c=pt.id, Post_Test__c=pt.id, Repair_Activity__c = 'Cable Advanced Whitening');
          productRepairlist.add(pr);
          insert productRepairlist;*/
        //========================================================================================
        list<ProductTestData__c> ptestdata = new list<ProductTestData__c>();
        ProductTestData__c ptest1 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Airscan', Field_API_Value__c = 'noticeably irregular',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Tip Overhaul', Repairable__c = 'Yes');
        ptestdata.add(ptest1);
        ProductTestData__c ptest2 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Articulation', Field_API_Value__c = 'Major Slack in Left/Right',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Steering Cable Adjustment', Repairable__c = 'Yes');
        ptestdata.add(ptest2);
        ProductTestData__c ptest3 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Bending Rubber', Field_API_Value__c = 'Heavy Discoloration',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Bending Rubber/Glue Beads Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest3);
        ProductTestData__c ptest4 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Cable Jacket', Field_API_Value__c = 'Heavy Ink Stains',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Cable Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest4);

        ProductTestData__c ptest5 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Color Artifacts', Field_API_Value__c = 'Minor noise at bending section',
                Outsource__c = false, rating__c = 'fair', repair_evaluation__c = 'Cable Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest5);

        ProductTestData__c ptest6 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Connector', Field_API_Value__c = 'Broken Locking Knob',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Knob Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest6);

        ProductTestData__c ptest7 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Control Housing', Field_API_Value__c = 'Major Discoloration',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Control Housing Overhaul', Repairable__c = 'Yes');
        ptestdata.add(ptest7);

        ProductTestData__c ptest8 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'CW Artifacts', Field_API_Value__c = 'Minor noise at bending section',
                Outsource__c = false, rating__c = 'fair', repair_evaluation__c = 'Cable Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest8);

        ProductTestData__c ptest9 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'First Call', Field_API_Value__c = '4+ Dead element',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Array Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest9);

        ProductTestData__c ptest10 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Motor', Field_API_Value__c = 'Motor Sounds Labored',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Array Drive System Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest10);

        ProductTestData__c ptest11 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Image', Field_API_Value__c = 'Dark shadow(s)',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Tip Overhaul', Repairable__c = 'Yes');
        ptestdata.add(ptest11);

        ProductTestData__c ptest12 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Insertion Tube', Field_API_Value__c = 'bite marks-minor',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Insertion Tube Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest12);

        ProductTestData__c ptest13 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Interior', Field_API_Value__c = 'Fluid Intrusion Inside Tip',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Tip Overhaul', Repairable__c = 'Yes');
        ptestdata.add(ptest13);

        ProductTestData__c ptest14 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Leakage Current', Field_API_Value__c = 'Above Upper Limit at Tip',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Tip Overhaul', Repairable__c = 'Yes');
        ptestdata.add(ptest14);

        ProductTestData__c ptest15 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Orientation', Field_API_Value__c = 'Reversed',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Connector Boards Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest15);

        ProductTestData__c ptest16 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Probe Handle', Field_API_Value__c = 'minor scratches',
                Outsource__c = false, rating__c = 'fair', repair_evaluation__c = 'Probe Handle Refurbishment', Repairable__c = 'Yes');
        ptestdata.add(ptest16);

        ProductTestData__c ptest17 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Strain Relief', Field_API_Value__c = 'heavy discoloration',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Cable Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest17);

        ProductTestData__c ptest18 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Tip', Field_API_Value__c = 'Tip Case Cracked',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Tip Overhaul', Repairable__c = 'Yes');
        ptestdata.add(ptest18);

        ProductTestData__c ptest19 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Cap', Field_API_Value__c = 'Not Functioning',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Tip Overhaul', Repairable__c = 'Yes');
        ptestdata.add(ptest19);

        ProductTestData__c ptest20 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Lens', Field_API_Value__c = 'Not Functioning',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Tip Overhaul', Repairable__c = 'Yes');
        ptestdata.add(ptest20);

        ProductTestData__c ptest21 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'CW Pulse', Field_API_Value__c = 'Not Functioning',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Tip Overhaul', Repairable__c = 'Yes');
        ptestdata.add(ptest21);
        ProductTestData__c ptest22 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Strain Relief at Connector', Field_API_Value__c = 'Broken',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Strain Relief Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest22);

        ProductTestData__c ptest23 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Strain Relief at Probe Handle', Field_API_Value__c = 'Broken',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Strain Relief Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest23);

        ProductTestData__c ptest24 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Color Artifacts - High Stress', Field_API_Value__c = 'Exists: minor at SR',
                Outsource__c = false, rating__c = 'fair', repair_evaluation__c = 'Cable Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest24);

        ProductTestData__c ptest25 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'Color Artifacts - Low Stress', Field_API_Value__c = 'Exists: minor at SR',
                Outsource__c = false, rating__c = 'fair', repair_evaluation__c = 'Cable Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest25);

        ProductTestData__c ptest26 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'CW Artifacts - High Stress', Field_API_Value__c = 'Exists: minor at SR',
                Outsource__c = false, rating__c = 'fair', repair_evaluation__c = 'Cable Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest26);

        ProductTestData__c ptest27 = new ProductTestData__c(Probe_Type__c = 'Phased Array', Field_API_Name__c = 'CW Artifacts - Low Stress', Field_API_Value__c = 'Exists: minor at SR',
                Outsource__c = false, rating__c = 'fair', repair_evaluation__c = 'Cable Replacement', Repairable__c = 'Yes');
        ptestdata.add(ptest27);

        insert ptestdata;

        ProductTest__c ptest = new ProductTest__c(Product_Item__c = pitem.id, Cos_evaluation__c = 'abc', Fun_evaluation__c = 'cxv', Cosmetic_Bending_rubber__c = 'Heavy Discoloration',
                Cosmetic_Cable_jacket__c = 'Heavy Ink Stains', Cosmetic_Cap__c = 'Not Functioning', Cosmetic_Connector__c = 'Broken Locking Knob',
                Cosmetic_Insertion_tube__c = 'bite marks-minor', Cosmetic_Lens__c = 'Not Functioning', Cosmetic_Probe_Handle__c = 'minor scratches',
                Cosmetic_Strain_Relief__c = 'heavy discoloration', Cosmetic_Control_Housing__c = 'Major Discoloration', Cosmetic_Tip__c = 'Tip Case Cracked',
                Functional_Airscan__c = 'noticeably irregular', Functional_Articulation__c = 'Major Slack in Left/Right',
                Functional_Color_artifacts__c = 'Minor noise at bending section', Functional_CW_artifacts__c = 'Minor noise at bending section',
                Functional_Color_artifacts_High_Stress__c = 'Exists: minor at SR', Functional_CW_artifacts_High_Stress__c = 'Exists: minor at SR',
                Functional_Color_artifacts_Low_Stress__c = 'Exists: minor at SR', Functional_CW_artifacts_Low_Stress__c = 'Exists: minor at SR',
                Functional_CW_Pulse__c = 'Not Functioning', Functional_First_Call__c = '4+ Dead element', Functional_Image__c = 'Dark shadow(s)',
                Functional_Leakage_current__c = 'Above Upper Limit at Tip', Functional_Motor__c = 'Motor Sounds Labored', Other_Notes_Cosmetic__c = 'abcd',
                Other_Notes_Functional__c = 'abcd', Functional_Interior__c = 'Fluid Intrusion Inside Tip', Functional_Orientation__c = 'Reversed',
                Cosmetic_Strain_Relief_at_Connector__c = 'Broken', Cosmetic_Strain_Relief_at_Probe_Handle__c = 'Broken', Last_4_Characters_of_SN__c = '1234',
                Test_Completed_By__c = 'Andres Carvajal');
        insert ptest;


    }
    
    @IsTest
    static void testSystems(){

        List<Product2> pToInsert = new List<Product2>();

        Product2 p = new Product2(Name = 'test', Family = 'Ultrasound System');
        pToInsert.add(p);

        
        insert pToInsert;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'Fishers, IN', Receive_date__c = Date.today());
        insert pi;
        pi.Product_Name__c = p.Id;
        update pi;

        ProductTest__c pt = new ProductTest__c(Name = String.valueOf(Date.today()), Product_Item__c = pi.Id, Last_4_Characters_of_SN__c = '1234', 
                                               Test_Completed_By__c = 'Andres Carvajal', Move_Test__c = 'Pass', DOA_Result__c = 'Yes', Monitor_Arm__c = 'Pass', 
                                               Breaks_Locks__c = 'Pass', Alignment__c = 'Pass', Depot_Standard_System_Test__c = 'Standard System');

        Test.startTest();

        System.debug('TEST - start of test');
        insert pt;

        Test.stopTest();

    }
    
    @IsTest
    static void testDepotSystems(){

        List<Product2> pToInsert = new List<Product2>();

        Product2 p = new Product2(Name = 'test', Family = 'Ultrasound System');
        pToInsert.add(p);

        
        insert pToInsert;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'Fishers, IN', Receive_date__c = Date.today());
        insert pi;
        pi.Product_Name__c = p.Id;
        update pi;

        ProductTest__c pt = new ProductTest__c(Name = String.valueOf(Date.today()), Product_Item__c = pi.Id, Last_4_Characters_of_SN__c = '1234', 
                                               Test_Completed_By__c = 'Andres Carvajal', Move_Test__c = 'Pass', DOA_Result__c = 'Yes', Monitor_Arm__c = 'Pass', 
                                               Breaks_Locks__c = 'Pass', Alignment__c = 'Pass', Depot_Standard_System_Test__c = 'Depot System');

        Test.startTest();

        System.debug('TEST - start of test');
        insert pt;

        Test.stopTest();

    }
    
     @IsTest
    static void testPart(){

       
        Product2 p = new Product2(Name = 'test', Family = 'Ultrasound Part', Modality__c = 'Ultrasound');
        
        insert p;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'Fishers, IN', Receive_date__c = Date.today());
        insert pi;
        pi.Product_Name__c = p.Id;
        update pi;

        ProductTest__c pt = new ProductTest__c(Name = String.valueOf(Date.today()), Product_Item__c = pi.Id, Last_4_Characters_of_SN__c = '1234', 
                                               Test_Completed_By__c = 'Andres Carvajal', Cosmetic_Repair_Capability__c = 'Internal', Cosmetic_Status__c = 'External part - broken/damaged',
                                              Functional_Repair_Capability__c = 'Internal', Functional_Status__c = 'Printed circuit board - failure', Core_Needed__c = true);
        Test.startTest();

        System.debug('TEST - start of test');
        insert pt;

        Test.stopTest();

    }
    
    @IsTest
    static void testCoil(){

       
        Product2 p = new Product2(Name = 'test', Family = 'Coil', Modality__c = 'MRI');
        
        insert p;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'Fishers, IN', Receive_date__c = Date.today());
        insert pi;
        pi.Product_Name__c = p.Id;
        update pi;

        ProductTest__c pt = new ProductTest__c(Name = String.valueOf(Date.today()), Product_Item__c = pi.Id, Last_4_Characters_of_SN__c = '1234', 
                                               Test_Completed_By__c = 'Andres Carvajal', Coil_Cosmetic_Evaluation__c = 'Parts Missing', Need_Refoamed__c = true,
                                               Fixture_Test__c = 'Fail', Network_Analyzer_Test__c = 'Fail', Decoupling_Test__c = 'Fail', 
                                               Coil_Functional_Evaluation__c = 'Cable Repair; Board Repair;', Preamp_Current_Draw__c = 'Fail');
        Test.startTest();

        System.debug('TEST - start of test');
        insert pt;

        Test.stopTest();

    }
    
    @IsTest
    static void testEndoscopy(){

       
        Product2 p = new Product2(Name = 'test GIF Flexible', Family = 'Endoscopy', Modality__c = 'Endoscopy', Probe_Type__c = 'Endoscopy - Flexible');
        
        insert p;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'Fishers, IN', Receive_date__c = Date.today());
        insert pi;
        pi.Product_Name__c = p.Id;
        update pi;
        //list<ProductTestData__c> ptestdata = new list<ProductTestData__c>();
        ProductTestData__c ptest1 = new ProductTestData__c(Probe_Type__c = 'Endoscopy - Flexible', Field_API_Name__c = 'Endoscopy_Insertion_Tube__c', Field_API_Value__c = 'Replace',
                Outsource__c = false, rating__c = 'fair', repair_evaluation__c = 'Insertion Tube Replacement', Repairable__c = 'Yes');
        insert ptest1;

        ProductTest__c pt = new ProductTest__c(Name = String.valueOf(Date.today()), Product_Item__c = pi.Id, Last_4_Characters_of_SN__c = '1234', 
                                               Test_Completed_By__c = 'Yasmina Rodriguez', Endoscopy_Insertion_Tube__c = 'Damaged;Replace');
        Test.startTest();

        System.debug('TEST - start of test');
        insert pt;

        Test.stopTest();

    }


}