@isTest
public class P_CaseTriggerHandlerTest {
    static testMethod void mytest() {

        Product2 pro = new Product2 (Name = 'Toshiba PVT-375BT', Probe_type__c = 'Convex', Max_Repair__c = 100000, Sug_Pr_Ex__c = 200, Qty_Ready_to_Ship__c = 0,
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
                Probe_Handle_Reverse__c = 100, Tip_Lens_Film_Removal__c = 100, Full_Overhaul__c = 200, OEM__c = 'GE_Healthcare', IsActive = true, Modality__c = 'Ultrasound');
        insert pro;
        ProductTestData__c ptest1 = new ProductTestData__c(Probe_Type__c = 'Convex', Field_API_Name__c = 'Image', Field_API_Value__c = 'Shadows',
                Outsource__c = false, rating__c = 'bad', repair_evaluation__c = 'Retermination', Repairable__c = 'Yes');
        insert ptest1;
        User u = TestDataFactory.createUser('Adam', 'Walter', true);
        Contact newContact = new Contact (FirstName = 'Natalie', LastName = 'Boger',Email = 'nboger@probomedical.com', HomePhone = '(866) 513-8322', MobilePhone = '(866) 513-8322');
        insert newContact;
        Case c = new Case (Repair_Eval_Probe_Type__c = 'Convex', Repair_Eval_Probe_Manufacturer__c = 'Toshiba', Repair_Eval_Probe_Model_Toshiba__c = 'PVT-375BT', Repair_Eval_Image__c = 'Shadows', OwnerId = u.id, Repair_Eval_Contact_Email__c = 'nboger@probomedical.com', Repair_Eval_Contact_Phone__c = '(866) 513-8322');
        insert c;

        }

}