public class P_ProductTestTriggerHandler extends GH_TriggerHandlerBase{

    protected override void beforeInsert(){
        System.debug('Not implemented yet');
    }
    protected override void beforeUpdate(){
        System.debug('Not implemented yet');
    }
    protected override void beforeDelete(){
        System.debug('Not implemented yet');
    }
    protected override void afterInsert(){
        System.debug('Not implemented yet');
    }
    protected override void afterUpdate(){
        System.debug('Not implemented yet');
    }
    protected override void afterDelete(){
        System.debug('Not implemented yet');
    }
    protected override void afterUndelete(){
        System.debug('Not implemented yet');
    }


    // these are here so they can be referenced in all methods
    private List<ProductTestData__c> prodTestDataList = new List<ProductTestData__c>();
    private Map<String, Decimal> RMap = new Map<String, Decimal>();
    private Map <String, Integer> rating = new Map<String, Integer>();
    private Map <Integer, String> rating_reverse = new Map<Integer, String>();
    private ProductItem__c thePItem;
    
    static Map<String, List<ProductTestData__c>> probeTypeToProdTestData;
    
    private Map<Id, Work_Order__c> getWorkOrderMap(List<Id> assetIds) {
        List<String> excludedStatuses = new List<String>{'Completed', 'Work order cancelled'};
        List<Work_Order__c> workOrderList = [SELECT Possible_Repairs__c,Id, Asset__c, CreatedDate 
                                                FROM Work_Order__c 
                                                WHERE Asset__c in :assetIds 
                                                AND RecordType.Name = 'Repair Work Order'
                                                AND Status__c NOT in :excludedStatuses 
                                                ORDER BY CreatedDate DESC];
        Map<Id, Work_Order__c> workOrderMap = new Map<Id, Work_Order__c>();
        for(Work_Order__c w : workOrderList) {
            workOrderMap.put(w.Asset__c, w);
        }
        return workOrderMap;
    }


    private Map<String, Decimal> GetValues(Product2 r) {
        Map<String, Decimal> thisInfo = new Map<String, Decimal>{
            // This is the pricing map that links the price for each repair from the product page to the repair.
			'Cable Advanced Whitening' => r.Cable_Advanced_Whitening__c,
			'Cable Jacket Splice' => r.Cable_Jacket_Splice__c,
			'Connector Housing Replacement' => r.Connector_Housing_Replacement__c,
			'Connector Housing Paint' => r.Connector_Housing_Paint__c,
			'Lens Refurbishment' => r.Lens_Refurb__c,
			'Lens Relens' => r.Lens_Relens__c,
			'Strain Relief Replacement' => r.Strain_Relief_Replacement__c,
			'Array Replacement' => r.Array_Replacement__c,
			'Cable Replacement' => r.Cable_Replacement__c,
			'Motor Repair' => r.Motor_Repair__c,
			'Cap Replacement with Oil Fill' => r.Cap_Replacement_with_Oil_Fill__c,
			'Connector Repair' => r.Connector_Repair__c,
			'Electrical' => r.Electrical__c,
			'Oil Fill' => r.Oil_Fill__c,
			'Probe Handle Replacement' => r.Probe_Handle_Replacement__c,
			'Retermination' => r.Retermination__c,
			'Bending Rubber/Glue Beads Replacement' => r.Bending_Rubber_Glue_Beads_Replacement__c,
			'Control Housing Polish' => r.Control_Housing_Polish__c,
			'Grommet Replacement' => r.Grommet_Replacement__c,
			'Knob Replacement' => r.Knob_Replacement__c,
			'Tip Polish' => r.Tip_Polish__c,
			'Lens Remove Coating/RTV Seal Replacement' => r.Lens_Remove_Coating_RTV_Seal_Replacement__c,
			'RTV Seal Replacement' => r.RTV_Seal_Replacement__c,
			'Array Drive Switch or Board Replacement' => r.Array_Drive_Switch_or_Board_Replacement__c,
			'Control Housing Overhaul' => r.Control_Housing_Overhaul__c,
			'Array Drive System Replacement' => r.Array_Drive_System_Replacement__c,
			'Steering Cable Adjustment' => r.Steering_Cable_Adjustment__c,
			'Connector Boards Replacement' => r.Connector_Boards_Replacement__c,
			'Insertion Tube Replacement' => r.Insertion_Tube_Replacement__c,
			'Steering Cable Replacement' => r.Steering_Cable_Replacement__c,
			'Tip Overhaul' => r.Tip_Overhaul__c,
			'Recoat/Relabel' => r.Recoat_Relabel__c,   
			'Probe Handle Reverse' => r.Probe_Handle_Reverse__c,
			'Cable Jacket Refurbishment' => r.Cable_Jacket_Refurbishment__c,
			'Connector Refurbishment' => r.Connector_Refurbishment__c,
			'Probe Handle Refurbishment' => r.Probe_Handle_Refurbishment__c,
			'Cap Refurbishment' => r.Cap_Refurbishment__c,
			'Connector Overhaul' => r.Connector_Overhaul__c,
			'Strain Relief Refurbishment' => r.Strain_Relief_Refurbishment__c,
			'Array Carriage Replacement' => r.Array_Carriage_Replacement__c,
			'Ferrule Assembly' => 1,
			'Electrical - miscellaneous' => r.Electrical__c,
			'Carriage Drive Cable Replacement' => r.Carriage_Drive_Cable_Replacement__c,
			'Oil Bladder Replacement' => r.Oil_Bladder_Replacement__c,
			'Wire splice' => r.Wire_splice__c,
			'New part price' => r.OEM_List_Price__c, 
			'Used part price' => r.REFURB_Exchange_Price__c,
            
            'A/W Channel Repair' => r.A_W_Channel_Repair__c,
			'A/W Channel Replacement' => r.A_W_Channel_Replacement__c,
			'A/W Nozzle Repair' => r.A_W_Nozzle_Repair__c,
			'A/W Nozzle Replacement' => r.A_W_Nozzle_Replacement__c,
			'A/W O-Rings Repair' => r.A_W_O_Rings_Repair__c,
			'A/W O-Rings Replacement' => r.A_W_O_Rings_Replacement__c,
			'A/W Separator Repair' => r.A_W_Separator_Repair__c,
			'A/W Separator Replacement' => r.A_W_Separator_Replacement__c,
			'Achromats Repair' => r.Achromats_Repair__c,
            'Achromats Replacement' => r.Achromats_Replacement__c,
           // 'Adhesive Repair' => r.Adhesive_Repair__c,
            'Adhesive Replacement' => r.Adhesive_Replacement__c,
            'Alignment of Image Repair' => r.Alignment_of_Image_Repair__c,
            'Alignment of Image Replacement' => r.Alignment_of_Image_Replacement__c,
            'Angulation Adjust Repair' => r.Angulation_Adjust_Repair__c,
            'Angulation Adjust Replacement' => r.Angulation_Adjust_Replacement__c,
            'Angulation System Repair' => r.Angulation_System_Repair__c,
            'Angulation System Replacement' => r.Angulation_System_Replacement__c,
            'Auto-Bright Repair' => r.Auto_Bright_Repair__c,
            'Auto-Bright Replacement' => r.Auto_Bright_Replacement__c,
            'Auxiliary Channel Repair' => r.Auxiliary_Channel_Repair__c,
            'Auxiliary Channel Replacement' => r.Auxiliary_Channel_Replacement__c,
            'Auxiliary Port Repair' => r.Auxiliary_Port_Repair__c,
            'Auxiliary Port Replacement' => r.Auxiliary_Port_Replacement__c,
            'Bending Section Repair' => r.Bending_Section_Repair__c,
            'Bending Section Replacement' => r.Bending_Section_Replacement__c,
            'Bending Sheath Repair' => r.Bending_Sheath_Repair__c,
            'Bending Sheath Replacement' => r.Bending_Sheath_Replacement__c,
            'Biopsy Channel Repair' => r.Biopsy_Channel_Repair__c,
            'Biopsy Channel Replacement' => r.Biopsy_Channel_Replacement__c,
            'CCD Chip Video Image Repair' => r.CCD_Chip_Video_Image_Repair__c,
            'CCD Chip Video Image Replacement' => r.CCD_Chip_Video_Image_Replacement__c,
            'Condenser Crystal Repair' => r.Condenser_Crystal_Repair__c,
            'Condenser Crystal Replacement' => r.Condenser_Crystal_Replacement__c,
            'Contamination Removal' => r.Contamination_Removal__c,
            'Control Body Repair' => r.Control_Body_Repair__c,
            'Control Body Replacement' => r.Control_Body_Replacement__c,
            'Control Cable Down Repair' => r.Control_Cable_Down_Repair__c,
            'Control Cable Down Replacement' => r.Control_Cable_Down_Replacement__c,
            'Control Cable Left Repair' => r.Control_Cable_Left_Repair__c,
            'Control Cable Left Replacement' => r.Control_Cable_Left_Replacement__c,
            'Control Cable Right Repair' => r.Control_Cable_Right_Repair__c,
            'Control Cable Right Replacement' => r.Control_Cable_Right_Replacement__c,
            'Control Cable Up Repair' => r.Control_Cable_Up_Repair__c,
            'Control Cable Up Replacement' => r.Control_Cable_Up_Replacement__c,
            'Control Knob Assembly Repair' => r.Control_Knob_Assy__c,
            'Control Knob Assembly Replacement' => r.Control_Knob_Assy_Replacement__c,
            'Distal End Cap Repair' => r.Distal_End_Cap_Repair__c,
            'Distal End Cap Replacement' => r.Distal_End_Cap_Replacement__c,
            'Distal Tip Window Repair' => r.Distal_Tip_Window_Repair__c,
            'Distal Tip Window Replacement' => r.Distal_Tip_Window_Replacement__c,
            'Electrical Contacts Repair' => r.Electrical_Contacts_Repair__c,
            'Electrical Contacts Replacement' => r.Electrical_Contacts_Replacement__c,
            'Elevator Cable Repair' => r.Elevator_Cable_Repair__c,
            'Elevator Cable Replacement' => r.Elevator_Cable_Replacement__c,
            'Elevator Channel Repair' => r.Elevator_Channel_Repair__c,
            'Elevator Channel Replacement' => r.Elevator_Channel_Replacement__c,
            'Elevator Lever Repair' => r.Elevator_Lever_Repair__c,
            'Elevator Lever Replacement' => r.Elevator_Lever_Replacement__c,
            'ETO Valve Repair' => r.ETO_Valve_Repair__c,
            'ETO Valve Replacement' => r.ETO_Valve_Replacement__c,
            'Eyepiece Repair' => r.Eyepiece_Repair__c,
            'Eyepiece Replacement' => r.Eyepiece_Replacement__c,
            'Eyepiece Sleeve Repair' => r.Eyepiece_Sleeve_Repair__c,
            'Eyepiece Sleeve Replacement' => r.Eyepiece_Sleeve_Replacement__c,
            'Eyepiece Window Repair' => r.Eyepiece_Window_Repair__c,
            'Eyepiece Window Replacement' => r.Eyepiece_Window_Replacement__c,
            'F/O Image Bundle Repair' => r.F_O_Image_Bundle_Repair__c,
            'F/O Image Bundle Replacement' => r.F_O_Image_Bundle_Replacement__c,
            'F/O Light Bundle Repair' => r.F_O_Light_Bundle_Repair__c,
            'F/O Light Bundle Replacement' => r.F_O_Light_Bundle_Replacement__c,
            'Flexibility Adjustment Mechanism Repair' => r.Flexibility_Adj_Mechanism_Repair__c,
            'Flexibility Adjustment Mechanism Replacement' => r.Flexibility_Adj_Mechanism_Replacement__c,
            'Fluid Removal' => r.Fluid_Removal__c,
            'Image Bundle Repair' => r.Image_Bundle_Repair__c,
            'Image Bundle Replacement' => r.Image_Bundle_Replacement__c,
            'Insertion Tube Repair' => r.Insertion_Tube_Repair__c,
            'Insertion Tube Replacement Endoscope' => r.Insertion_Tube_Replacement_Endoscope__c,
            'Internal Components Repair' => r.Internal_Components_Repair__c,
            'Internal Components Replacement' => r.Internal_Components_Replacement__c,
            'L/R Brake Assembly Repair' => r.L_R_Brake_Assy_Repair__c,
            'L/R Brake Assembly Replacement' => r.L_R_Brake_Assy_Replacement__c,
            'L/R Control Knob Repair' => r.L_R_Control_Knob_Repair__c,
            'L/R Control Knob Replacement' => r.L_R_Control_Knob_Replacement__c,
            'Light Fibers Repair' => r.Light_Fibers_Repair__c,
            'Light Fibers Replacement' => r.Light_Fibers_Replacement__c,
            'Light Guide Connector Repair' => r.Light_Guide_Connector_Repair__c,
            'Light Guide Connector Replacement' => r.Light_Guide_Connector_Replacement__c,
            'Light Guide Lens Repair' => r.Light_Guide_Lens_Repair__c,
            'Light Guide Lens Replacement' => r.Light_Guide_Lens_Replacement__c,
            'Light Guide Post Cap Repair' => r.Light_Guide_Post_Cap_Repair__c,
            'Light Guide Post Cap Replacement' => r.Light_Guide_Post_Cap_Replacement__c,
            'Marker Plate Repair' => r.Marker_Plate_Repair__c,
            'Marker Plate Replacement' => r.Marker_Plate_Replacement__c,
            'Objective Assembly Repair' => r.Objective_Assembly_Repair__c,
            'Objective Assembly Replacement' => r.Objective_Assembly_Replacement__c,
            'Objective Lens Repair' => r.Objective_Lens_Repair__c,
            'Objective Lens Replacement' => r.Objective_Lens_Replacement__c,
            'Ocular Repair' => r.Ocular_Repair__c,
            'Ocular Replacement' => r.Ocular_Replacement__c,
            'Prism Repair' => r.Prism_Repair__c,
            'Prism Replacement' => r.Prism_Replacement__c,
            'Rod Lens Repair' => r.Rod_Lens_Repair__c,
            'Rod Lens Replacement' => r.Rod_Lens_Replacement__c,
            'Stress Relief Boot Repair' => r.Stress_Relief_Boot_Repair__c,
            'Stress Relief Boot Replacement' => r.Stress_Relief_Boot_Replacement__c,
            'Suction Channel Repair' => r.Suction_Channel_Repair__c,
            'Suction Channel Replacement' => r.Suction_Channel_Replacement__c,
            'Suction Cylinder Repair' => r.Suction_Cylinder_Repair__c,
            'Suction Cylinder Replacement' => r.Suction_Cylinder_Replacement__c,
            'Switch #1 Repair' => r.Switch_1_Repair__c,
            'Switch #1 Replacement' => r.Switch_1_Replacement__c,
            'Tubing Laser Weld Repair' => r.Tubing_Laser_Weld_Repair__c,
            'Tubing Laser Weld Replacement' => r.Tubing_Laser_Weld_Replacement__c,
            'Tubing Repair' => r.Tubing_Repair__c,
            'Tubing Replacement' => r.Tubing_Replacement__c,
            'U/D Brake Assembly Repair' => r.U_D_Brake_Assy_Repair__c,
            'U/D Brake Assembly Replacement' => r.U_D_Brake_Assy_Replacement__c,
            'U/D Control Knob Repair' => r.U_D_Control_Knob__c,
            'U/D Control Knob Replacement' => r.U_D_Control_Knob_Replacement__c,
            'Universal Cord Repair' => r.Universal_Cord_Repair__c,
            'Universal Cord Replacement' => r.Universal_Cord_Replacement__c,
            'Video Connector Repair' => r.Video_Connector_Repair__c,
            'Video Connector Replacement' => r.Video_Connector_Replacement__c,
            'Video Coupler Repair' => r.Video_Coupler_Repair__c,
            'Video Coupler Replacement' => r.Video_Coupler_Replacement__c,
            'Video Switch Assembly Repair' => r.Video_Switch_Assy_Repair__c,
            'Video Switch Assembly Replacement' => r.Video_Switch_Assy_Replacement__c,
            'Wire Mesh Repair' => r.Wire_Mesh_Repair__c,
            'Wire Mesh Replacement' => r.Wire_Mesh_Replacement__c
            
		};
		return thisInfo;
    }

    
    
    
    public static string review_status;

    public void processRecords(List<ProductTest__c> newRecs,  Map<Id, ProductTest__c> newRecMap, Map<Id, ProductTest__c> oldRecs) {

        if (Trigger.isExecuting) {

            if (Trigger.isBefore) {

                Set<Id> pItemIds = new Set<Id>();
                Boolean HighCap = false;
				Set<Id> prodIDs = new Set<Id>();

                for (ProductTest__c p : newRecs) {
                    if (p.Product_Item__c != null) {
                        pItemIds.add(p.Product_Item__c);
                    }
                    
                    if(p.Depot_Repair_Required_Part_1__c != null){
                        prodIDs.add(p.Depot_Repair_Required_Part_1__c);
                    }
                    
                    if(p.Depot_Repair_Required_Part_2__c != null){
                        prodIDs.add(p.Depot_Repair_Required_Part_2__c);
                    }
                    
                    if(p.Depot_Repair_Required_Part_3__c != null){
                        prodIDs.add(p.Depot_Repair_Required_Part_3__c);
                    }
                    
                    if(p.Depot_Repair_Required_Part_4__c != null){
                        prodIDs.add(p.Depot_Repair_Required_Part_4__c);
                    }
                    
                    if(p.Depot_Repair_Cosmetic_Part_1__c != null){
                        prodIDs.add(p.Depot_Repair_Cosmetic_Part_1__c);
                    }
                    
                    if(p.Depot_Repair_Cosmetic_Part_2__c != null){
                        prodIDs.add(p.Depot_Repair_Cosmetic_Part_2__c);
                    }
                    
                    if(p.Depot_Repair_Cosmetic_Part_3__c != null){
                        prodIDs.add(p.Depot_Repair_Cosmetic_Part_3__c);
                    }
                    
                    if(p.Depot_Repair_Cosmetic_Part_4__c != null){
                        prodIDs.add(p.Depot_Repair_Cosmetic_Part_4__c);
                    }

                    // moved from WFR FU
                    if (p.Verified_Asset_and_Serial_Numbers_Match__c) {
                        p.Asset_Serial_Match_Verified_By__c = UserInfo.getName();
                        p.Timestamp_Verified_Asset_Serial_Match__c = Datetime.now();
                    }
                    
                    if(p.Final_QC_Test_Results__c == 'Passed'){
                        p.Final_QC_Functional_Rating__c = 'Good';
                        p.Final_QC_Cosmetic_Rating__c = 'Good';
                    }
                    if(p.Final_QC_Test_Results__c == 'Failed'){
                        p.Final_QC_Functional_Rating__c = 'Bad';
                        p.Final_QC_Cosmetic_Rating__c = 'Bad';
                    }
                }

                Map<Id, ProductItem__c> pItemIdToPItem = new Map<Id, ProductItem__c>([
                        SELECT Probe_Type__c, Id, Cosmetic_Rating__c, Cosmetically_Repairable__c, Functional_Rating__c,
                                Always_Save_for_Parts__c, Product_Name__r.Name, Product_Family__c,
                                Testing_Priority_Rating__c, Review_Status__c, Review_status_priority_rating_threshold__c,
                                Functionally_Repairable__c, Repair_Evaluation__c, Outsource__c, Product_Name__c, Check_In_Type__c,
                                Estimated_Lead_Time__c, Estimated_Repair_Time__c, Added_to_Work_Order__c
                        FROM ProductItem__c
                        WHERE Id IN:pItemIds
                ]);

                
                Set<String> probTypes = new Set<String>();

                for (ProductItem__c r : pItemIdToPItem.values()) {

                    if (r.Product_Name__c != null) {
                        prodIDs.add(r.Product_Name__c);
                    }

                    if (r.Probe_Type__c != null) {
                        probTypes.add(r.Probe_Type__c);
                    }
                }


                Map<Id, Product2> prodIDToProducts = new Map<Id, Product2>([
                        SELECT Id,Name,Cable_Advanced_Whitening__c,Cable_Jacket_Splice__c,Connector_Housing_Replacement__c,Connector_Housing_Paint__c,
                    Refurb__c,Lens_Refurb__c,Lens_Remove__c,Lens_Relens__c,Strain_Relief_Remove__c,Strain_Relief_Replacement__c,Array_Replacement__c,
                    Cable_Replacement__c,Cap_Replacement_with_Oil_Fill__c,Connector_Repair__c,Electrical__c,Motor_Repair__c,Oil_Fill__c,Probe_Handle_Close__c,
                    Probe_Handle_Open__c,Probe_Handle_Replacement__c,Retermination__c,Bending_Rubber_Glue_Beads_Replacement__c,Control_Housing_Polish__c,
                    Grommet_Replacement__c,Knob_Replacement__c,Lens_Remove_Coating_RTV_Seal_Replacement__c,RTV_Seal_Replacement__c,Tip_Polish__c,
                    Array_Drive_Switch_or_Board_Replacement__c,Array_Drive_System_Replacement__c,Connector_Boards_Replacement__c,Control_Housing_Overhaul__c,
                    Insertion_Tube_Replacement__c,Steering_Cable_Adjustment__c,Steering_Cable_Replacement__c,Tip_Overhaul__c,Probe_Handle_Reverse__c,Cap_Refurbishment__c,
                    Cable_Jacket_Refurbishment__c,Connector_Refurbishment__c,Probe_Handle_Refurbishment__c,Strain_Relief_Refurbishment__c,Wire_splice__c,
                    Oil_Bladder_Replacement__c,Carriage_Drive_Cable_Replacement__c,Array_Carriage_Replacement__c,Recoat_Relabel__c,Connector_Overhaul__c,
                    Max_Repair__c,Max_Non_Functional__c,New_Sug_Pr_Out__c,Sug_Pr_Out__c,REFURB_Exchange_Price__c,OEM_List_Price__c,A_W_Nozzle_Repair__c,A_W_Nozzle_Replacement__c,A_W_Channel_Repair__c,A_W_Channel_Replacement__c,A_W_Separator_Repair__c,A_W_Separator_Replacement__c,
                    A_W_O_Rings_Repair__c,A_W_O_Rings_Replacement__c,Alignment_of_Image_Repair__c,Angulation_System_Repair__c,Angulation_System_Replacement__c,
                    Auto_Bright_Repair__c,Auto_Bright_Replacement__c,Auxiliary_Channel_Repair__c,Auxiliary_Channel_Replacement__c,Bending_Section_Repair__c,
                    Bending_Section_Replacement__c,Bending_Sheath_Repair__c,Bending_Sheath_Replacement__c,Biopsy_Channel_Repair__c,Biopsy_Channel_Replacement__c,
                    CCD_Chip_Video_Image_Repair__c,CCD_Chip_Video_Image_Replacement__c,Control_Body_Repair__c,Control_Body_Replacement__c,Control_Cable_Down_Repair__c,
                    Control_Cable_Down_Replacement__c,Control_Cable_Left_Repair__c,Control_Cable_Left_Replacement__c,Control_Cable_Right_Repair__c,Control_Cable_Right_Replacement__c,
                    Control_Cable_Up_Repair__c,Control_Cable_Up_Replacement__c,Control_Knob_Assy__c,Control_Knob_Assy_Replacement__c,Distal_End_Cap_Repair__c,Distal_End_Cap_Replacement__c,
                    Electrical_Contacts_Repair__c,Electrical_Contacts_Replacement__c,Elevator_Cable_Repair__c,Elevator_Cable_Replacement__c,Elevator_Channel_Repair__c,
                    Elevator_Channel_Replacement__c,Elevator_Lever_Repair__c,Elevator_Lever_Replacement__c,ETO_Valve_Replacement__c,ETO_Valve_Repair__c,F_O_Image_Bundle_Repair__c,
                    F_O_Image_Bundle_Replacement__c,F_O_Light_Bundle_Repair__c,F_O_Light_Bundle_Replacement__c,Flexibility_Adj_Mechanism_Repair__c,Flexibility_Adj_Mechanism_Replacement__c,
                    Internal_Components_Repair__c,Internal_Components_Replacement__c,L_R_Brake_Assy_Repair__c,L_R_Brake_Assy_Replacement__c,L_R_Control_Knob_Repair__c,
                    L_R_Control_Knob_Replacement__c,Light_Guide_Connector_Repair__c,Light_Guide_Connector_Replacement__c,Light_Guide_Lens_Repair__c,Light_Guide_Lens_Replacement__c,
                    Light_Guide_Post_Cap_Repair__c,Light_Guide_Post_Cap_Replacement__c,Objective_Lens_Repair__c,Objective_Lens_Replacement__c,Ocular_Repair__c,Ocular_Replacement__c,
                    Suction_Channel_Repair__c,Suction_Channel_Replacement__c,Suction_Cylinder_Repair__c,Suction_Cylinder_Replacement__c,Switch_1_Repair__c,Switch_1_Replacement__c,
                    U_D_Brake_Assy_Repair__c,U_D_Brake_Assy_Replacement__c,U_D_Control_Knob__c,U_D_Control_Knob_Replacement__c,Universal_Cord_Repair__c,Universal_Cord_Replacement__c,
                    Video_Connector_Repair__c,Video_Connector_Replacement__c,Video_Switch_Assy_Repair__c,Video_Switch_Assy_Replacement__c,Wire_Mesh_Repair__c,Wire_Mesh_Replacement__c,
                    Achromats_Repair__c,Achromats_Replacement__c,Adhesive_Repair__c,Adhesive_Replacement__c,Condenser_Crystal_Repair__c,Condenser_Crystal_Replacement__c,Distal_Tip_Window_Repair__c,
                    Distal_Tip_Window_Replacement__c,Eyepiece_Repair__c,Eyepiece_Replacement__c,Eyepiece_Sleeve_Repair__c,Eyepiece_Sleeve_Replacement__c,Eyepiece_Window_Repair__c,Eyepiece_Window_Replacement__c,
                    Image_Bundle_Repair__c,Image_Bundle_Replacement__c,Light_Fibers_Repair__c,Light_Fibers_Replacement__c,Marker_Plate_Repair__c,Marker_Plate_Replacement__c,Objective_Assembly_Repair__c,
                    Objective_Assembly_Replacement__c,Prism_Repair__c,Prism_Replacement__c,Rod_Lens_Repair__c,Rod_Lens_Replacement__c,Tubing_Laser_Weld_Repair__c, Alignment_of_Image_Replacement__c,
                    Tubing_Laser_Weld_Replacement__c,Tubing_Repair__c,Tubing_Replacement__c,Video_Coupler_Repair__c,Video_Coupler_Replacement__c, Insertion_Tube_Repair__c,
                    Contamination_Removal__c, Fluid_Removal__c, Stress_Relief_Boot_Repair__c, Stress_Relief_Boot_Replacement__c, Insertion_Tube_Replacement_Endoscope__c,
                    Angulation_Adjust_Repair__c, Angulation_Adjust_Replacement__c, Auxiliary_Port_Repair__c, Auxiliary_Port_Replacement__c

                        FROM Product2
                        WHERE Id IN :prodIDs
                ]);

// we need a map of Maps for each ProductID
                Map<Id, Map<String, Decimal>> prodIDtoRMaps = new Map<Id, Map<String, Decimal>>();

                for (Product2 r : prodIDToProducts.values()) {

                    Map<String, Decimal> thisInfo = GetValues(r);

                    prodIDtoRMaps.put(r.Id, thisInfo);

                }

// Product test data is a custom object that's a matrix that indicates the proper repair activity, repairability, and rating based on the symptom from the test.
                //Map<String, List<ProductTestData__c>> probeTypeToProdTestData = new Map<String, List<ProductTestData__c>>();
                if(probeTypeToProdTestData == null) {
                    System.debug('CC...SELECT ProductTestData__c');
                    probeTypeToProdTestData = new Map<String, List<ProductTestData__c>>();

                for (ProductTestData__c r : [
                        SELECT Id, Field_API_Name__c, Field_API_Value__c, Outsource__c, Probe_Type__c, rating__c,
                                repair_evaluation__c, Repairable__c, Ratings_to_Update__c
                        FROM ProductTestData__c
                        WHERE Probe_Type__c IN :probTypes
                ]) {

                    if (!probeTypeToProdTestData.containsKey(r.Probe_Type__c)) {
                        probeTypeToProdTestData.put(r.Probe_Type__c, new List<ProductTestData__c>());
                    }
                    probeTypeToProdTestData.get(r.Probe_Type__c).add(r);
                }
                }

                GH_Logger.debug('Found ProductTestData records for this many Probe_Types: ' + probeTypeToProdTestData.size());
				    
                Map<Id, ProductTest__c> pItemIdtoPTest = new Map<Id, ProductTest__c>();

                for (ProductTest__c r : [SELECT Id, Product_Item__c, Cosmetic_Rating__c, CreatedDate FROM ProductTest__c WHERE Product_Item__c = :pItemIds ORDER BY CreatedDate DESC]) {

                    if (!pItemIdtoPTest.containsKey(r.Product_Item__c)) {
                        pItemIdtoPTest.put(r.Product_Item__c, r);
                    }
                }

// [select Id, Product_Item__c, Cosmetic_Rating__c from ProductTest__c where Product_Item__c = :p.Product_Item__c AND Id != :p.Id ORDER BY CreatedDate DESC limit 1];

// Rating maps that link numbers to the actual rating names. This allows the code to convert the ratings into numbers, find the worst (highest) rating,
// then convert back to the rating name for the final rating result.
                rating.put('Good', 1); rating.put('good', 1); rating.put('Fair', 2); rating.put('fair', 2); rating.put('Bad', 3); rating.put('bad', 3); rating.put('N/A', 0);

                rating_reverse.put(1, 'Good'); rating_reverse.put(2, 'Fair'); rating_reverse.put(3, 'Bad'); rating_reverse.put(0, 'N/A');


// The safe variables are turned to false if any symptoms make the probe unsafe. This is later used to help determine review status.https://probomedical--nataliedev.sandbox.my.salesforce.com/_ui/common/apex/debug/ApexCSIPage#
				
                for (ProductTest__c p : newRecs) {

                    System.debug('Looking at ProductTest__c: ' + p.Id + ' and probe type: ' + p.Probe_Type__c);
					// This is in before trigger and probe type and product family are formula fields so they are null. Need to pull from linked product item.
					if (p.Product_Item__c != null && pItemIdToPItem.containsKey(p.Product_Item__c)) {
                        thePItem = pItemIdToPItem.get(p.Product_Item__c);
                        system.debug('PRODUCT TEST CONTINUE >> ' + p.Product_Item__c + ' AND FINAL >> ' + thePItem);
                        System.debug('PRODUCT TEST CONTINUE CHECK PROBE TYPE >> ' + thePItem.Probe_Type__c + ' AND PRODUCT FAMILY >> ' + thePItem.Product_Family__c);
                        if (thePItem.Probe_Type__c == null && !thePItem.Product_Family__c.contains('Part') && !thePItem.Product_Family__c.contains('System') && !thePItem.Product_Family__c.contains('Coil') && !thePItem.Product_Family__c.contains('Endoscopy')) {
                            System.debug('No Probe_Type__c and not a part/system - skipping');
                            continue;
                        }
                    }
                    

// find the PItem and Product for this ProductTest
                    Product2 theProduct;

                    if (p.Product_Item__c != null && pItemIdToPItem.containsKey(p.Product_Item__c)) {
                        thePItem = pItemIdToPItem.get(p.Product_Item__c);
                        theProduct = prodIDToProducts.get(thePItem.Product_Name__c);
                    }

                    if (thePItem != null && prodIDtoRMaps.containsKey(thePItem.Product_Name__c)) {
                        RMap = prodIDtoRMaps.get(thePItem.Product_Name__c);
                    }


                    if (Trigger.isInsert) {
                        if (p.CreatedDate != null) {
                            Date testname = Date.newInstance(p.CreatedDate.year(), p.CreatedDate.month(), p.CreatedDate.day());
                            p.Name = String.valueOf(testname);
                        }

                        if (thePItem != null && pItemIdtoPTest.containsKey(thePItem.Id)) {
                            p.Previous_Test__c = pItemIdtoPTest.get(thePItem.Id).Id;
                        }
                    }

// everything else from here down applies to both Insert and Update

// find the ProductTestData__c for the ProbeType on the PItem related to this ProductTest
                    if (thePItem != null && probeTypeToProdTestData.containsKey(thePItem.Probe_Type__c)) {
                        prodTestDataList = probeTypeToProdTestData.get(thePItem.Probe_Type__c);
                    }
					system.debug('THIS IS THE PROD TEST DATA LIST >> ' + prodTestDataList);
                    // create the ProdTestWrapper for this ProdTest record
                    ProdTestInfoWrapper thisPTestInfo = new ProdTestInfoWrapper();

                    String last4 = '';

// Last 4 serial numbers must be entered and match the last 4 on the asset page to ensure the correct asset is being tested
                    if (p.Serial_No__c != null) {
                        last4 = p.Serial_No__c.right(4);
                    }
                    if(!p.Product_Family__c.contains('Part') && !p.Product_Family__c.contains('Coil')){
                     
                        p.Verified_Asset_and_Serial_Numbers_Match__c = (p.Last_4_Characters_of_SN__c == last4);
                        if(p.Verified_Asset_and_Serial_Numbers_Match__c){
                            p.Asset_Serial_Match_Verified_By__c = UserInfo.getName();
                            p.Timestamp_Verified_Asset_Serial_Match__c = Datetime.now();
                        }
                    }

// The following code goes through each mini test within the product test and compares against the product test
// data matrix, then runs the data collected from the matrix through the ComplexStringWrapper code above. In each section of code
// for each mini test, notes are stored with any issues found, any repairs needed, and if the asset is repairable or not.
// Currently, this is only built out for probes, but eventually systems will be added as well.
//
			
              if(p.Product_Family__c.contains('Probe') || p.Product_Family__c.contains('Endoscopy')){
                  // for all endoscopy fields
                 
                  if(p.Product_Family__c.contains('Endoscopy')){
                      List<String> EndoscopyTestFields = p.All_Endoscopy_Field_Names__c.split(';');
                      string currentField = '';
                      string notePrefix = '';
                    
                    for(string fieldName:EndoscopyTestFields){
                        String fieldValue = String.valueof(p.get(fieldName));
  						if(fieldValue !=null) {
                   
                          currentField = 'p.' + fieldName;
                          system.debug('THIS IS THE CURRENT FIELD >> ' + currentField);
                          notePrefix = fieldName.replaceAll('_','');
                          system.debug('THIS IS THE NOTE PREFIX >> ' + notePrefix);
                          notePrefix = notePrefix.left(notePrefix.length()-1);
                          system.debug('THIS IS THE NOTE PREFIX 2 >> ' + notePrefix);
                            if(notePrefix == 'Achromats'){
                                if(p.Achromats_to_Replace__c != null){
                                    fieldValue += '; ' + p.Achromats_to_Replace__c + ' Achromats';
                                }
                            }
                            if(notePrefix == 'RodLenses'){
                                if(p.Rod_Lenses_to_Replace__c != null){
                                    fieldValue += '; ' + p.Rod_Lenses_to_Replace__c + ' Rods';
                                }
                            }
                          thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'f', fieldValue, notePrefix, fieldName, null, null, null));
                    	  System.debug('Adding FLIST for Endoscopy '+ fieldName);
                          }
                      }
                      if(p.Adhesive_Damaged__c == true){
                          Integer ratenum = 3; String rep_ev = 'Adhesive Replacement'; Boolean repair = true; Integer repair_na = 0; Boolean out = false; String notes = 'Adhesive Damaged'; String repairs = 'Adhesive Replacement';
                          if (thePItem != null) {
                            ComplexStringWrapper w = new ComplexStringWrapper('f', rating_reverse.get(ratenum), repair, repair_na, rep_ev, out, notes, repairs, thePItem.Probe_Type__c);
                            System.debug('FUNCTIONAL ITERATION>' + w);
                            thisPTestInfo.FinalList.add(w);
                        }
                      }
                      
                      if(p.Fluid_Damage__c == true){
                          Integer ratenum = 3; String rep_ev = 'Fluid Removal'; Boolean repair = true; Integer repair_na = 0; Boolean out = false; String notes = 'Fluid Damage'; String repairs = 'Fluid Removal';
                          if (thePItem != null) {
                            ComplexStringWrapper w = new ComplexStringWrapper('f', rating_reverse.get(ratenum), repair, repair_na, rep_ev, out, notes, repairs, thePItem.Probe_Type__c);
                            System.debug('FUNCTIONAL ITERATION>' + w);
                            thisPTestInfo.FinalList.add(w);
                        }
                      }
                      /*
                      if(p.Damage_by_Autoclave__c == true){
                          Integer ratenum = 3; String rep_ev = 'Fluid Removal'; Boolean repair = true; Integer repair_na = 0; Boolean out = false; String notes = 'Fluid Damage'; String repairs = 'Fluid Removal';
                          if (thePItem != null) {
                            ComplexStringWrapper w = new ComplexStringWrapper('f', rating_reverse.get(ratenum), repair, repair_na, rep_ev, out, notes, repairs, thePItem.Probe_Type__c);
                            System.debug('FUNCTIONAL ITERATION>' + w);
                            thisPTestInfo.FinalList.add(w);
                        }
                      }*/
                        
                  }
                  	
                  // for standard ultrasound probe fields
                    if (p.Cosmetic_Bending_rubber__c != null) {
                        System.debug('Adding CLIST for Cosmetic_Bending_rubber__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'c', p.Cosmetic_Bending_rubber__c, 'BR', 'Bending Rubber', null, null, null));
                    }

                    if (p.Cosmetic_Cable_jacket__c != null) {
                        System.debug('Adding CLIST for Cosmetic_Cable_jacket__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'c', p.Cosmetic_Cable_jacket__c, 'CJ', 'Cable Jacket', null, null, null));
                    }

                    if (p.Cosmetic_Cap__c != null) {
                        System.debug('Adding CLIST for Cosmetic_Cap__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'c', p.Cosmetic_Cap__c, 'C', 'Cap', null, null, null));
                    }

                    if (p.Cosmetic_Connector__c != null) {
                        System.debug('Adding CLIST for Cosmetic_Connector__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'c', p.Cosmetic_Connector__c, 'CO', 'Connector', new List<String>{
                                'cracked', 'missing', 'broken pins', 'locking knob is broken'
                        }, null, null));
                    }

                    if (p.Cosmetic_Control_Housing__c != null) {
                        System.debug('Adding CLIST for Cosmetic_Control_Housing__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'c', p.Cosmetic_Control_Housing__c, 'CH', 'Control Housing', new List<String>{
                                'cracked'
                        }, null, null));
                    }

                    if (p.Cosmetic_Insertion_tube__c != null) {
                        System.debug('Adding CLIST for Cosmetic_Insertion_tube__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'c', p.Cosmetic_Insertion_tube__c, 'IT', 'Insertion Tube', null, null, null));
                    }

                    if (p.Cosmetic_Lens__c != null) {
                        System.debug('Adding CLIST for Cosmetic_Lens__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'c', p.Cosmetic_Lens__c, 'L', 'Lens', new List<String>{
                                'No lens'
                        }, new List<String>{
                                'hole', 'missing', 'cut'
                        }, null));
                    }

                    if (p.Cosmetic_Probe_Handle__c != null) {
                        System.debug('Adding CLIST for Cosmetic_Probe_Handle__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'c', p.Cosmetic_Probe_Handle__c, 'PH', 'Probe Handle', new List<String>{
                                'cracked'
                        }, null, null));
                    }

// Standard strain relief field is for TEE probes; specific SR fields (at connector and at probe handle) are used for non-TEE probes
                    if (p.Cosmetic_Strain_Relief__c != null) {
                        System.debug('Adding CLIST for Cosmetic_Strain_Relief__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'c', p.Cosmetic_Strain_Relief__c, 'SR', 'Strain Relief', new List<String>{
                                'broken', 'torn'
                        }, null, null));
                    }

                    if (p.Cosmetic_Strain_Relief_at_Connector__c != null) {
                        System.debug('Adding CLIST for Cosmetic_Strain_Relief_at_Connector__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'c', p.Cosmetic_Strain_Relief_at_Connector__c, 'SR', 'Strain Relief at Connector', new List<String>{
                                'broken', 'torn'
                        }, null, ' (at connector)'));
                    }

                    if (p.Cosmetic_Strain_Relief_at_Probe_Handle__c != null) {
                        System.debug('Adding CLIST for Cosmetic_Strain_Relief_at_Probe_Handle__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'c', p.Cosmetic_Strain_Relief_at_Probe_Handle__c, 'SR', 'Strain Relief at Probe Handle', new List<String>{
                                'broken', 'torn'
                        }, null, ' (at probe handle)'));
                    }

                    if (p.Cosmetic_Tip__c != null) {
                        System.debug('Adding CLIST for Cosmetic_Tip__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'c', p.Cosmetic_Tip__c, 'T', 'Tip', null, null, null));
                    }


                    if (p.Functional_Airscan__c != null) {
                        System.debug('Adding FLIST for Functional_Airscan__c');
                        System.debug('Calling complexListSplitter for Functional_Airscan__c value of ' + p.Functional_Airscan__c);
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'f', p.Functional_Airscan__c, 'A', 'Airscan', null, null, null));
                    }

                    if (p.Functional_Articulation__c != null) {
                        System.debug('Adding FLIST for Functional_Articulation__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'f', p.Functional_Articulation__c, 'AR', 'Articulation', null, null, null));
                    }




// Standard color/CW artifacts field is for TEE probes; specific color/CW fields (high stress and low stress) are used for non-TEE probes

                    if (p.Functional_Color_artifacts__c != null) {
                        System.debug('Adding FLIST for Functional_Color_artifacts__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'f', p.Functional_Color_artifacts__c, 'CA', 'Color Artifacts', null, null, null));
                    }

                    if (p.Functional_Color_Artifacts_High_Stress__c != null) {
                        System.debug('Adding FLIST for Functional_Color_Artifacts_High_Stress__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'f', p.Functional_Color_Artifacts_High_Stress__c, 'CA', 'Color Artifacts - High Stress', null, null, ' (under high stress)'));
                    }

                    if (p.Functional_Color_Artifacts_Low_Stress__c != null) {
                        System.debug('Adding FLIST for Functional_Color_Artifacts_Low_Stress__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'f', p.Functional_Color_Artifacts_Low_Stress__c, 'CA', 'Color Artifacts - Low Stress', null, null, ' (under low stress)'));
                    }

                    if (p.Functional_CW_artifacts__c != null) {
                        System.debug('Adding FLIST for Functional_CW_artifacts__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'f', p.Functional_CW_artifacts__c, 'CWA', 'CW Artifacts', null, null, null));
                    }

                    if (p.Functional_CW_Artifacts_High_Stress__c != null) {
                        System.debug('Adding FLIST for Functional_CW_Artifacts_High_Stress__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'f', p.Functional_CW_Artifacts_High_Stress__c, 'CWA', 'CW Artifacts - High Stress', null, null, ' (under high stress)'));
                    }

                    if (p.Functional_CW_Artifacts_Low_Stress__c != null) {
                        System.debug('Adding FLIST for Functional_CW_Artifacts_Low_Stress__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'f', p.Functional_CW_Artifacts_Low_Stress__c, 'CWA', 'CW Artifacts - Low Stress', null, null, ' (under low stress)'));
                    }

                    if (p.Functional_CW_Pulse__c != null) {
                        System.debug('Adding FLIST for Functional_CW_Pulse__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'f', p.Functional_CW_Pulse__c, 'CWP', 'CW Pulse', null, null, null));
                    }

// FIRST CALL: there are two first call fields; the sensitivity field is not used for TEE probes.
                    if (p.Functional_First_Call__c != null || p.Functional_First_Call_Sensitivity__c != null) {
                        System.debug('Processing Functional_First_Call__c ' + p.Functional_First_Call__c + ' OR Functional_First_Call_Sensitivity__c ' + p.Functional_First_Call_Sensitivity__c);
                        List<String> ftest = new List<String>();

                        String notes = '';
                        if (p.Functional_First_Call__c != null) {
                            List<String> ftest1 = p.Functional_First_Call__c.split(';');

                            if (ftest1.size() > 1 || (ftest1.size() == 1 && ftest1[0] != 'no problem')) {

                                for (String f : ftest1) {
                                    ftest.add(f);
                                    if (thePItem != null && thePItem.Probe_Type__c != 'Transesophageal' && (f.containsIgnoreCase('not available') || f.containsIgnoreCase('sensitivity') || f.containsIgnoreCase('high capacitance') || f.containsIgnoreCase('no problem'))) {
                                        notes = notes + 'FC:' + f + '; ';
                                    }
                                    if (thePItem != null && thePItem.Probe_Type__c == 'Transesophageal') {
                                        notes = notes + 'FC:' + f + '; ';
                                    }
                                    if (f.containsIgnoreCase('high capacitance')) {
                                        HighCap = true;
                                    }
                                }
                            }
                        }

                        if (p.Functional_First_Call_Sensitivity__c != null) {
                            List<String> ftest2 = p.Functional_First_Call_Sensitivity__c.split(';');
                            for (String f : ftest2) {
                                ftest.add(f);
                                if (!f.containsIgnoreCase('No problem')) {
                                    notes = notes + 'FC:' + f + '; ';
                                }
                            }
                        }
                        Integer ratenum = 0; String rep_ev = ''; Boolean repair = true; Integer repair_na = 0; Boolean out = false; String repairs = '';
                        for (String s : ftest) {

                            GH_Logger.debug('Checking ftest: ' + s);
                            for (ProductTestData__c ptdtemp : prodTestDataList) {
                                GH_Logger.debug('Against this ProductTestData: ' + ptdtemp);
                                if (s.equalsIgnoreCase(ptdtemp.Field_API_Value__c) && ptdtemp.Field_API_Name__c == 'First Call') {
                                    if (ratenum < rating.get(ptdtemp.rating__c)) {
                                        ratenum = rating.get(ptdtemp.rating__c);
                                    }
                                    system.debug('THIS IS THE First Call Loop RATING >>> ' + ratenum + ' and THIS IS THE PTDTEMP >>> ' + ptdtemp);
                                    if (ptdtemp.repair_evaluation__c != null) {
                                        rep_ev = rep_ev + ptdtemp.repair_evaluation__c.trim() + ';';
                                        if (RMap.get(ptdtemp.repair_evaluation__c.trim()) > 0) {
                                            repairs = repairs + ptdtemp.repair_evaluation__c.trim() + ';';
                                        }
                                        if (RMap.get(ptdtemp.repair_evaluation__c.trim()) <= 0 || RMap.get(ptdtemp.repair_evaluation__c.trim()) == null) {
                                            repair = false;
                                        }
                                    }
                                    if (ptdtemp.repair_evaluation__c == null && ptdtemp.Repairable__c == 'No') {
                                        repair = false;
                                    }
                                    if (!ptdtemp.Repairable__c.containsIgnoreCase('N/A')) {
                                        repair_na = repair_na + 1;
                                    }
                                    if (ptdtemp.Outsource__c == true) {
                                        out = true;
                                    }
                                }
                            }
                        }
                        System.debug('THIS IS THE FC RATING >>> ' + ratenum);
                        if (thePItem != null) {
                            ComplexStringWrapper w = new ComplexStringWrapper('f', rating_reverse.get(ratenum), repair, repair_na, rep_ev, out, notes, repairs, thePItem.Probe_Type__c);
                            System.debug('FUNCTIONAL ITERATION ================>' + w);
                            thisPTestInfo.FinalList.add(w);
                        }
                    }

                    if (p.Functional_Image__c != null) {
                        System.debug('Adding FLIST for Functional_Image__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'f', p.Functional_Image__c, 'I', 'Image', new List<String>{
                                'dark shadow(s) - middle 80%'
                        }, null, null));
                    }

                    if (p.Functional_Interior__c != null) {
                        System.debug('Adding FLIST for Functional_Interior__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'f', p.Functional_Interior__c, 'IN', 'Interior', null, null, null));
                    }

                    if (p.Functional_Leakage_current__c != null) {
                        System.debug('Processing Functional_Leakage_current__c: ' + p.Functional_Leakage_current__c);
                        List<String> ftest = p.Functional_Leakage_current__c.split(';');
                        Integer ratenum = 0; String rep_ev = ''; Boolean repair = true; Integer repair_na = 0; Boolean out = false; String notes = ''; String repairs = '';
                        for (String s : ftest) {
                            if (!s.containsIgnoreCase('No problem') && !s.contains('Below 50mA')) {
                                notes = notes + 'LC:' + s + '; ';
                            }


                            for (ProductTestData__c ptdtemp : prodTestDataList) {
                                if (s.equalsIgnoreCase(ptdtemp.Field_API_Value__c) && ptdtemp.Field_API_Name__c == 'Leakage Current') {
                                    if (ratenum < rating.get(ptdtemp.rating__c)) {
                                        ratenum = rating.get(ptdtemp.rating__c);
                                    }
                                    if (ptdtemp.repair_evaluation__c != null) {
                                        rep_ev = rep_ev + ptdtemp.repair_evaluation__c.trim() + ';';
                                        if (RMap.get(ptdtemp.repair_evaluation__c.trim()) > 0) {
                                            repairs = repairs + ptdtemp.repair_evaluation__c.trim() + (';');
                                        }
                                        if (RMap.get(ptdtemp.repair_evaluation__c.trim()) <= 0 || RMap.get(ptdtemp.repair_evaluation__c.trim()) == null) {
                                            repair = false;
                                        }
                                    }
                                    if (ptdtemp.repair_evaluation__c == null && ptdtemp.Repairable__c == 'No') {
                                        repair = false;
                                    }
                                    if (!ptdtemp.Repairable__c.containsIgnoreCase('N/A')) {
                                        repair_na = repair_na + 1;
                                    }
                                    if (ptdtemp.Outsource__c == true) {
                                        out = true;
                                    }
                                }
                            }
                        }
                        if (thePItem != null) {
                            ComplexStringWrapper w = new ComplexStringWrapper('f', rating_reverse.get(ratenum), repair, repair_na, rep_ev, out, notes, repairs, thePItem.Probe_Type__c);
                            System.debug('FUNCTIONAL ITERATION>' + w);
                            thisPTestInfo.FinalList.add(w);
                        }
                    }

                    if (p.Functional_Motor__c != null) {
                        System.debug('Adding FLIST for Functional_Motor__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'f', p.Functional_Motor__c, 'M', 'Motor', null, null, null));
                    }

                    if (p.Functional_Orientation__c != null) {
                        System.debug('Adding FLIST for Functional_Orientation__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, 'f', p.Functional_Orientation__c, 'O', 'Orientation', null, null, null));
                    }

                    System.debug('End of the field-level checking and processing.');
                    Integer cnum = 0;
                    Boolean crepair = true;
                    Integer crepair_na = 0;
                    String c_notes = '';
                    Integer some_c = 0;
                    String rep_ev = '';
                    String pos_repairs = '';

                    Integer fnum = 0;
                    Boolean frepair = true;
                    Integer frepair_na = 0;
                    String f_notes = '';
                    Integer some_f = 0;

                    Boolean finalout = false;
                    Integer inum = 0;
                    Integer fcnum = 0;

                    for (ComplexStringWrapper finaltest : thisPTestInfo.FinalList) {
                        System.debug('Working with Final Cosmetic: ' + finaltest);
                        if (cnum < rating.get(finaltest.c_rating)) {
                            cnum = rating.get(finaltest.c_rating);
                        }
                        if (fnum < rating.get(finaltest.f_rating)) {
                            fnum = rating.get(finaltest.f_rating);
                        }
                        if (inum < rating.get(finaltest.image_rating)) {
                            inum = rating.get(finaltest.image_rating);
                        }
                        if (fcnum < rating.get(finaltest.FC_rating)) {
                            fcnum = rating.get(finaltest.FC_rating);
                        }
                        if (!rep_ev.contains(finaltest.repair_eval)) {
                            rep_ev = rep_ev + finaltest.repair_eval;
                        }
                        if (!pos_repairs.contains(finaltest.repairs)) {
                            pos_repairs = pos_repairs + finaltest.repairs;
                        }
                        if (finaltest.c_repairable == false) {
                            crepair = false;
                            some_c += 1;
                        }
                        if (finaltest.c_repairable_na != 0 && finaltest.c_repairable_na != null) {
                            crepair_na = crepair_na + 1;
                        }
                        if (finaltest.f_repairable == false) {
                            frepair = false;
                            some_f += 1;
                        }
                        if (finaltest.f_repairable_na != 0 && finaltest.f_repairable_na != null) {
                            frepair_na = frepair_na + 1;
                        }


                        if (finaltest.outsource == true) {
                            finalout = true;
                        }
                        if(finaltest.c_notes != null){
                            c_notes = c_notes + finaltest.c_notes;
                        }
                        if(finaltest.f_notes != null){
                            f_notes = f_notes + finaltest.f_notes;
                        }

                    }

                    System.debug('FINAL COSMETIC ======> cnum ' + cnum + ' final_rep_ev ' + rep_ev + ' crepair ' + crepair + ' crepair_na ' + crepair_na + ' finalout ' + finalout + ' notes' + c_notes + ' possible repairs' + pos_repairs);


                    if (p.Cable_Length__c != null) {
                        f_notes = f_notes + 'CL: ' + p.Cable_Length__c + ' (inches)';
                    }

                    System.debug('FINAL FUNCTIONAL: fnum ' + fnum + ' final_rep_ev ' + rep_ev + ' frepair ' + frepair + ' frepair_na ' + frepair_na + ' finalout ' + finalout + ' notes' + f_notes + ' possible repairs' + pos_repairs);

                    String func_rating = '';
                    String cos_rating = '';

                    func_rating = rating_reverse.get(fnum);
                    cos_rating = rating_reverse.get(cnum);

                    System.debug('THIS IS THE FUNCTIONAL IMAGE: ' + p.Functional_Image__c);
                    if (HighCap == true && (p.Product_Name__c.containsIgnoreCase('Sonosite') ||
                            p.Product_Name__c.containsIgnoreCase('M12L') ||
                            p.Product_Name__c.containsIgnoreCase('L12-5'))) {
                        func_rating = 'Bad';
                    }

                    System.debug('THIS IS THE FUNCTIONAL FC >>>> ' + p.Functional_First_Call__c);
                    if (p.Functional_Image__c != null && p.Functional_First_Call__c != null) {
                        if (p.Functional_Image__c.containsIgnoreCase('not available')) {
                            if (p.Functional_First_Call__c.containsIgnoreCase('not available')) {
                                func_rating = 'N/A: No System & First Call';
                            } else {
                                func_rating = rating_reverse.get(fcnum);
                            }
                        }
                    }

                    if (p.Functional_Motor__c != null) {
                        if (!p.Functional_Motor__c.equalsIgnoreCase('No problem')) {
                            func_rating = 'Bad';
                        }
                    }

                    if (p.Functional_Leakage_current__c != null) {
                        if (!p.Functional_Leakage_current__c.containsIgnoreCase('No problem') && !p.Functional_Leakage_current__c.contains('Below 50mA') &&
                                !p.Functional_Leakage_current__c.containsIgnoreCase('Not available')) {
                            func_rating = 'Bad - Failed Leakage';
                            thisPTestInfo.safe = false;

                        }
                        if (p.Functional_Leakage_current__c.containsIgnoreCase('Not available')) {
                            func_rating += ' - Leakage Test Not Available';
                            if (thisPTestInfo.lenssafe == false) {
                                thisPTestInfo.safe = false;
                            }
                        }
                    }
                    
                    if(f_notes.containsignorecase('Too damaged to test')){
                        func_rating = 'Bad';
                        cos_rating = 'Bad';
                    }

                    String c_repairable = 'No';
                    String f_repairable = 'No';

                    if (crepair == true) {
                        c_repairable = 'Yes';
                    }

                    if (crepair_na == 0) {
                        c_repairable = 'N/A';
                    }

                    if (frepair == true) {
                        f_repairable = 'Yes';
                    }

                    if (frepair_na == 0) {
                        f_repairable = 'N/A';
                    }

                    String cos_rep_ev = '';
                    String fun_rep_ev = '';
                    String cos_repairs = '';
                    String fun_repairs = '';

                    List<String> REtemp2 = rep_ev.split(';');
                    Set<String> REtemp = new Set<String>();
                    REtemp.addAll(REtemp2);

                    List<String> POStemp2 = pos_repairs.split(';');
                    Set<String> POStemp = new Set<String>();
                    POStemp.addAll(POStemp2);

                    Set<String> cannot = new Set<String>();
                    Set<String> currentRepairs = new Set<String>();
                   
                    for (String r : REtemp) {
                        // TEMPORARY - allow all repairs, regardless of price field to be populated as possible repairs for endoscopy tests
                        system.debug('THIS IS INITIAL RETEMP LINE BY LINE >> ' + r);
                        currentRepairs.add(r);
                        if (!POStemp.contains(r) && !p.Product_Family__c.contains('Endoscopy')) {
                            cannot.add(r);
                        }
                    }

                    System.debug('THESE REPAIRS CANNOT BE DONE >>>>>>>>>>>>> ' + cannot);

					// Sometimes techs will opt out of the insertion tube replacement, but it will be added automatically as a
					// repair with certain symptoms. This checkbox allows the tech to choose to keep it from being added as a repair.
                    for (String r : REtemp) {
                        if (p.Opt_Out_of_Insertion_Tube_Replacement__c == true && r == 'Insertion Tube Replacement') {
                            REtemp.remove(r);
                        }
                    }

                    for (String pr : POStemp) {
                        if (p.Opt_Out_of_Insertion_Tube_Replacement__c == true && pr == 'Insertion Tube Replacement') {
                            POStemp.remove(pr);
                        }
                    }

                    // Certain repairs for certain models also require other repairs. Additionally, if a more complex repair is
                    // needed, the simpler repairs will be removed. If a SR needs to be replaced, it no longer needs to be
                    // refurbished. So the code will filter out unnecessary repairs.
                    if (REtemp.contains('Insertion Tube Replacement') && (p.Product_Name__c == 'Philips 21369A-68000 T6210' ||
                            p.Product_Name__c == 'Philips 21369A T6210' ||
                            p.Product_Name__c == 'Philips 21378A T6H' ||
                            p.Product_Name__c == 'Philips 21778A S7-2t')) {
                        REtemp.add('Tip Overhaul');
                    }
                  
                    if (REtemp.contains('Retermination') && (p.Product_Name__c.containsIgnoreCase('PVT-375BT') ||
                            p.Product_Name__c.containsIgnoreCase('PLT-805AT'))) {
                        REtemp.remove('Retermination');
                        REtemp.add('Array Replacement');
                        REtemp.add('Probe Handle Replacement');
                        REtemp.add('Strain Relief Replacement');
                    }

                    if (REtemp.contains('Connector Housing Paint') && (p.Product_Name__c.containsIgnoreCase('Toshiba') ||
                            p.Product_Name__c.containsIgnoreCase('Acuson') ||
                            p.Product_Name__c.containsIgnoreCase('Cartridge'))) {
                        REtemp.remove('Connector Housing Paint');
                        REtemp.add('Connector Refurbishment');
                    }

                    if (REtemp.contains('Retermination')) {
                        REtemp.add('Strain Relief Replacement');
                    }
                    if (REtemp.contains('Ferrule Assembly')) {
                        REtemp.add('Strain Relief Replacement');
                    }
                  // endoscopy
                  if(p.Product_Name__c.containsIgnoreCase('Flexible')){
                      if(p.Product_Name__c.contains('GIF') || p.Product_Name__c.contains('CF') || p.Product_Name__c.contains('PCF') || p.Product_Name__c.contains('TJF') || p.Product_Name__c.contains('SIF')){
                          if(REtemp.contains('Universal Cord Replacement')){
                              REtemp.add('Suction Channel Replacement');
                              REtemp.add('Video Connector Replacement');
                          }
                          if(REtemp.contains('Insertion Tube Replacement')){
                              REtemp.add('Alignment of Image Replacement');
                              REtemp.add('Angulation Adjust Replacement');
                              REtemp.add('A/W Channel Replacement');
                              REtemp.add('Bending Sheath Replacement');
                              REtemp.add('Biopsy Channel Replacement');
                              REtemp.add('Control Cable Down Replacement');
                              REtemp.add('Control Cable Up Replacement');
                              REtemp.add('Control Cable Left Replacement');
                              REtemp.add('Control Cable Right Replacement');
                              REtemp.add('Coil Pipe Assembly Replacement');
                              REtemp.add('Distal End Cap Replacement');
                              REtemp.add('F/O Light Bundle Replacement');
                              REtemp.add('Wire Mesh Replacement');
                          }
                          if(REtemp.contains('Angulation System Replacement')){
                              REtemp.add('Alignment of Image Replacement');
                              REtemp.add('Angulation Adjust Replacement');
                              REtemp.add('Bending Sheath Replacement');
                              REtemp.add('Biopsy Channel Replacement');
                              REtemp.add('Control Cable Down Replacement');
                              REtemp.add('Control Cable Up Replacement');
                              REtemp.add('Control Cable Left Replacement');
                              REtemp.add('Control Cable Right Replacement');
                              REtemp.add('Coil Pipe Assembly Replacement');
                              REtemp.add('Wire Mesh Replacement');
                          }
                          if(REtemp.contains('Biopsy Channel Replacement') || REtemp.contains('A/W Channel Replacement')){
                              REtemp.add('Alignment of Image Replacement');
                              REtemp.add('Angulation Adjust Replacement');
                              REtemp.add('Bending Sheath Replacement');
                          }
                          if(REtemp.contains('CCD Chip Video Image Repair') || REtemp.contains('CCD Chip Video Image Replacement')){
                              REtemp.add('Alignment of Image Replacement');
                              REtemp.add('Angulation Adjust Replacement');
                              REtemp.add('Bending Sheath Replacement');
                              REtemp.add('Biopsy Channel Replacement');
                              REtemp.add('Video Connector Replacement');
                          }
                          if(REtemp.contains('Bending Section Replacement')){
                              REtemp.add('Alignment of Image Replacement');
                              REtemp.add('Angulation Adjust Replacement');
                              REtemp.add('Bending Sheath Replacement');
                              REtemp.add('Biopsy Channel Replacement');
                              REtemp.add('Control Cable Down Replacement');
                              REtemp.add('Control Cable Up Replacement');
                              REtemp.add('Control Cable Left Replacement');
                              REtemp.add('Control Cable Right Replacement');
                              REtemp.add('Wire Mesh Replacement');
                          }
                          if(REtemp.contains('F/O Light Bundle Replacement')){
                              REtemp.add('Alignment of Image Replacement');
                              REtemp.add('Angulation Adjust Replacement');
                              REtemp.add('Bending Sheath Replacement');
                              REtemp.add('Biopsy Channel Replacement');
                          }
        
                      }
                  }
                   if (REtemp.contains('Retermination') && (p.Product_Name__c.containsIgnoreCase('PVT-375BT') ||
                            p.Product_Name__c.containsIgnoreCase('PLT-805AT'))) {
                        REtemp.remove('Retermination');
                        REtemp.add('Array Replacement');
                        REtemp.add('Probe Handle Replacement');
                        REtemp.add('Strain Relief Replacement');
                    }

                    for (String r : REtemp) {

                        if (REtemp.contains('Array Replacement') && (r == 'Lens Relens' || r == 'Lens Refurbishment')) {
                            REtemp.remove(r);
                        }
                        if (REtemp.contains('Cable Replacement')
                                && (r == 'Cable Jacket Splice' || r == 'Cable Advanced Whitening' || r == 'Cable Jacket Refurbishment'
                                || r == 'Retermination' || r == 'Strain Relief Replacement' || r == 'Strain Relief Refurbishment'
                                || r == 'Ferrule Assembly')) {
                            REtemp.remove(r);
                        }
                        if (REtemp.contains('Cap Replacement with Oil Fill') && (r == 'Oil Fill' || r == 'Cap Refurbishment')) {
                            REtemp.remove(r);
                        }
                        if (REtemp.contains('Connector Housing Replacement')
                                && (r == 'Connector Housing Paint' || r == 'Connector Refurbishment')) {
                            REtemp.remove(r);
                        }
                        if (REtemp.contains('Connector Overhaul') && (r == 'Connector Repair')) {
                            REtemp.remove(r);
                        }
                        if (REtemp.contains('Control Housing Replacement') && (r == 'Control Housing Polish')) {
                            REtemp.remove(r);
                        }
                        if (REtemp.contains('Control Housing Overhaul') && (r == 'Control Housing Polish')) {
                            REtemp.remove(r);
                        }
                        if (REtemp.contains('Insertion Tube Replacement') && (r == 'Steering Cable Adjustment')) {
                            REtemp.remove(r);
                        }
                        if (REtemp.contains('Lens Relens') && (r == 'Lens Refurbishment')) {
                            REtemp.remove(r);
                        }
                        if (REtemp.contains('Lens Remove Coating/RTV Seal Replacement') && (r == 'RTV Seal Replacement')) {
                            REtemp.remove(r);
                        }
                        if (REtemp.contains('Probe Handle Replacement') && (r == 'Probe Handle Refurbishment')) {
                            REtemp.remove(r);
                        }
                        if (REtemp.contains('Retermination') && (r == 'Ferrule Assembly')) {
                            REtemp.remove(r);
                        }
                        if (REtemp.contains('Strain Relief Replacement') && (r == 'Strain Relief Refurbishment')) {
                            REtemp.remove(r);
                        }
                        if (REtemp.contains('Steering Cable Replacement') && (r == 'Steering Cable Adjustment')) {
                            REtemp.remove(r);
                        }
                        if (REtemp.contains('Tip Overhaul') && (r == 'Tip Polish')) {
                            REtemp.remove(r);
                        }
                    }

                    System.debug('THIS IS THE RETEMP >>>>>>> ' + REtemp);
                  List<String> finalAddedRepairsList = new List<String>();
                  
                  for(string repair: REtemp){
                      system.debug('THIS IS THE REPAIR INSIDE LOOP FOR RETEMP >> ' + repair + ' AND CURRENT REPAIRS CONTAINS >> ' + currentRepairs.contains(repair));
                      if(!currentRepairs.contains(repair)){
                          String addedRepair = '';
                          if(repair.contains('Replacement')){
                              addedRepair = repair.left(repair.length() - 4);
                          }
                          else{
                              addedRepair = repair;
                          }
                          finalAddedRepairsList.add(addedRepair);
                      }
                  }
					system.debug('THIS IS THE FINAL ADDED REPAIRS LIST >> ' + finalAddedRepairsList);
                    if (POStemp.contains('Insertion Tube Replacement') && (p.Product_Name__c == 'Philips 21369A-68000 T6210' ||
                            p.Product_Name__c == 'Philips 21369A T6210' ||
                            p.Product_Name__c == 'Philips 21378A T6H' ||
                            p.Product_Name__c == 'Philips 21778A S7-2t')) {

                        POStemp.add('Tip Overhaul');

                    }
                  
                    if (POStemp.contains('Retermination') && (p.Product_Name__c.containsIgnoreCase('PVT-375BT') ||
                            p.Product_Name__c.containsIgnoreCase('PLT-805AT'))) {
                        POStemp.remove('Retermination');
                        POStemp.add('Array Replacement');
                        POStemp.add('Probe Handle Replacement');
                        POStemp.add('Strain Relief Replacement');
                    }

                    if (POStemp.contains('Connector Housing Paint') && (p.Product_Name__c.containsIgnoreCase('Toshiba') ||
                            p.Product_Name__c.containsIgnoreCase('Acuson') ||
                            p.Product_Name__c.containsIgnoreCase('Cartridge'))) {
                        POStemp.remove('Connector Housing Paint');
                        POStemp.add('Connector Refurbishment');
                    }

                    if (POStemp.contains('Ferrule Assembly')) {
                        POStemp.add('Strain Relief Replacement');
                    }

                    if (POStemp.contains('Retermination')) {
                        POStemp.add('Strain Relief Replacement');
                    }
                  
                  // endoscopy
                  system.debug('THIS IS THE PRODUCT NAME >> ' + p.Product_Name__c + ' AND POStemp >> ' + POStemp);
                  if(p.Product_Name__c.containsIgnoreCase('Flexible')){
                      if(p.Product_Name__c.contains('GIF') || p.Product_Name__c.contains('CF') || p.Product_Name__c.contains('PCF') || p.Product_Name__c.contains('TJF') || p.Product_Name__c.contains('SIF')){
                          if(POStemp.contains('Universal Cord Replacement')){
                              POStemp.add('Suction Channel Replacement');
                              POStemp.add('Video Connector Replacement');
                          }
                          if(POStemp.contains('Insertion Tube Replacement')){
                              POStemp.add('Alignment of Image Replacement');
                              POStemp.add('Angulation Adjust Replacement');
                              POStemp.add('A/W Channel Replacement');
                              POStemp.add('Bending Sheath Replacement');
                              POStemp.add('Biopsy Channel Replacement');
                              POStemp.add('Control Cable Down Replacement');
                              POStemp.add('Control Cable Up Replacement');
                              POStemp.add('Control Cable Left Replacement');
                              POStemp.add('Control Cable Right Replacement');
                              POStemp.add('Coil Pipe Assembly Replacement');
                              POStemp.add('Distal End Cap Replacement');
                              POStemp.add('F/O Light Bundle Replacement');
                              POStemp.add('Wire Mesh Replacement');
                          }
                          if(POStemp.contains('Angulation System Replacement')){
                              POStemp.add('Alignment of Image Replacement');
                              POStemp.add('Angulation Adjust Replacement');
                              POStemp.add('Bending Sheath Replacement');
                              POStemp.add('Biopsy Channel Replacement');
                              POStemp.add('Control Cable Down Replacement');
                              POStemp.add('Control Cable Up Replacement');
                              POStemp.add('Control Cable Left Replacement');
                              POStemp.add('Control Cable Right Replacement');
                              POStemp.add('Coil Pipe Assembly Replacement');
                              POStemp.add('Wire Mesh Replacement');
                          }
                          if(POStemp.contains('Biopsy Channel Replacement') || POStemp.contains('A/W Channel Replacement')){
                              POStemp.add('Alignment of Image Replacement');
                              POStemp.add('Angulation Adjust Replacement');
                              POStemp.add('Bending Sheath Replacement');
                          }
                          if(POStemp.contains('CCD Chip Video Image Repair') || POStemp.contains('CCD Chip Video Image Replacement')){
                              POStemp.add('Alignment of Image Replacement');
                              POStemp.add('Angulation Adjust Replacement');
                              POStemp.add('Bending Sheath Replacement');
                              POStemp.add('Biopsy Channel Replacement');
                              POStemp.add('Video Connector Replacement');
                          }
                          if(POStemp.contains('Bending Section Replacement')){
                              POStemp.add('Alignment of Image Replacement');
                              POStemp.add('Angulation Adjust Replacement');
                              POStemp.add('Bending Sheath Replacement');
                              POStemp.add('Biopsy Channel Replacement');
                              POStemp.add('Control Cable Down Replacement');
                              POStemp.add('Control Cable Up Replacement');
                              POStemp.add('Control Cable Left Replacement');
                              POStemp.add('Control Cable Right Replacement');
                              POStemp.add('Wire Mesh Replacement');
                          }
                          if(POStemp.contains('F/O Light Bundle Replacement')){
                              POStemp.add('Alignment of Image Replacement');
                              POStemp.add('Angulation Adjust Replacement');
                              POStemp.add('Bending Sheath Replacement');
                              POStemp.add('Biopsy Channel Replacement');
                          }
        
                      }
                  }

                    for (String pr : POStemp) {

                        if (POStemp.contains('Array Replacement') && (pr == 'Lens Relens' || pr == 'Lens Refurbishment')) {
                            POStemp.remove(pr);
                        }
                        if (POStemp.contains('Cable Replacement')
                                && (pr == 'Cable Jacket Splice' || pr == 'Cable Advanced Whitening' || pr == 'Cable Jacket Refurbishment'
                                || pr == 'Retermination' || pr == 'Strain Relief Replacement' || pr == 'Strain Relief Refurbishment'
                                || pr == 'Ferrule Assembly')) {
                            POStemp.remove(pr);
                        }
                        if (POStemp.contains('Cap Replacement with Oil Fill') && (pr == 'Oil Fill' || pr == 'Cap Refurbishment')) {
                            POStemp.remove(pr);
                        }
                        if (POStemp.contains('Connector Housing Replacement') && (pr == 'Connector Housing Paint' || pr == 'Connector Refurbishment')) {
                            POStemp.remove(pr);
                        }
                        if (POStemp.contains('Connector Overhaul') && (pr == 'Connector Repair')) {
                            POStemp.remove(pr);
                        }
                        if (POStemp.contains('Control Housing Replacement') && (pr == 'Control Housing Polish')) {
                            POStemp.remove(pr);
                        }
                        if (POStemp.contains('Control Housing Overhaul') && (pr == 'Control Housing Polish')) {
                            POStemp.remove(pr);
                        }
                        if (POStemp.contains('Insertion Tube Replacement') && (pr == 'Steering Cable Adjustment')) {
                            POStemp.remove(pr);
                        }
                        if (POStemp.contains('Lens Relens') && (pr == 'Lens Refurbishment')) {
                            POStemp.remove(pr);
                        }
                        if (POStemp.contains('Lens Remove Coating/RTV Seal Replacement') && (pr == 'RTV Seal Replacement')) {
                            POStemp.remove(pr);
                        }
                        if (POStemp.contains('Probe Handle Replacement') && (pr == 'Probe Handle Refurbishment')) {
                            POStemp.remove(pr);
                        }
                        if (POStemp.contains('Retermination') && (pr == 'Ferrule Assembly')) {
                            POStemp.remove(pr);
                        }
                        if (POStemp.contains('Strain Relief Replacement') && (pr == 'Strain Relief Refurbishment')) {
                            POStemp.remove(pr);
                        }
                        if (POStemp.contains('Steering Cable Replacement') && (pr == 'Steering Cable Adjustment')) {
                            POStemp.remove(pr);
                        }

                        if (POStemp.contains('Tip Overhaul') && (pr == 'Tip Polish')) {
                            POStemp.remove(pr);
                        }
                    }

					// This compiles all the data from the ComplexStringWrapper and all the repairs/notes from all of the test symptoms.
                    System.debug('THIS IS THE POSTEMP >>>>>>> ' + POStemp);
                    List<String> c_repair_evaluation = new List<String>();
                    List<String> f_repair_evaluation = new List<String>();
                    List<String> c_repairs = new List<String>();
                    List<String> f_repairs = new List<String>();
                    List<Integer> reverseorder = new List<Integer>();
                    String order = '';

                    for (String r : REtemp) {
                        System.debug('checking REtemp value of ' + r);
                        if (ProboConstants.cosmetic_repair_list.contains(r)) {
                            System.debug('found it in cosmetic_repair_list');
                            c_repair_evaluation.add(r);
                            cos_rep_ev += r + ';';
                        }
                        if (ProboConstants.functional_repair_list.contains(r)) {
                            System.debug('found it in functional_repair_list');
                            f_repair_evaluation.add(r);
                            fun_rep_ev += r + ';';
                        }
                    }

					// There are a few repairs for TEE and Endoscope that are in a different order than non-TEE. This corrects for that.
                    for (String pos : POStemp) {
                        System.debug('checking POStemp value of ' + pos);
                        if (ProboConstants.cosmetic_repair_list.contains(pos)) {
                            System.debug('found it in cosmetic_repair_list');
                            c_repairs.add(pos);
                            cos_repairs += pos + ';';
                            if (thePItem != null && thePItem.Probe_Type__c == 'Transesophageal') {
                                if (pos == 'Strain Relief Replacement') {
                                    reverseorder.add(5);
                                }
                                if (pos == 'Connector Housing Replacement') {
                                    reverseorder.add(28);
                                }
                                if (pos == 'Connector Housing Paint') {
                                    reverseorder.add(29);
                                }
                                if (pos != 'Strain Relief Replacement' && pos != 'Connector Housing Replacement' && pos != 'Connector Housing Paint') {
                                    reverseorder.add(ProboConstants.OrderRepairs.get(pos));
                                }
                            }
                            if (thePItem != null && thePItem.Probe_Type__c != 'Transesophageal') {
                                reverseorder.add(ProboConstants.OrderRepairs.get(pos));
                            }
                        }

                        if (ProboConstants.functional_repair_list.contains(pos)) {
                            System.debug('found it in functional_repair_list');
                            f_repairs.add(pos);
                            fun_repairs += pos + ';';
                            if (thePItem != null && thePItem.Product_Family__c == 'Endoscopy') {
                                if(pos == 'Insertion Tube Replacement'){
                                    reverseorder.add(127);
                                }
                                if (pos != 'Insertion Tube Replacement') {
                                    reverseorder.add(ProboConstants.OrderRepairs.get(pos));
                                }
                            }
                            if (thePItem != null && thePItem.Probe_Type__c == 'Transesophageal') {
                                if (pos == 'Array Replacement') {
                                    reverseorder.add(2);
                                }
                                if (pos == 'Cable Replacement') {
                                    reverseorder.add(4);
                                }
                                if (pos != 'Array Replacement' && pos != 'Cable Replacement') {
                                    reverseorder.add(ProboConstants.OrderRepairs.get(pos));
                                }
                            }
                            if (thePItem != null && thePItem.Probe_Type__c != 'Transesophageal' && thePItem.Product_Family__c != 'Endoscopy') {
                                reverseorder.add(ProboConstants.OrderRepairs.get(pos));
                                
                            }
                        }
                    }

                    System.debug('THIS IS BEFORE THE REPAIR SORT >>>> ' + reverseorder);
                    reverseorder.sort();
                    System.debug('THIS IS AFTER THE REPAIR SORT >>>>>> ' + reverseorder);

                    for (Integer i : reverseorder) {
                        order += ProboConstants.ReverseOrderRepairs.get(i) + '; ';
                    }

                    p.Order_of_Repairs__c = order;
                    System.debug('THIS IS THE REORDERING FINAL >>>>>> ' + order);

                    String final_rep_ev = cos_rep_ev + fun_rep_ev;
                    String final_repairs = cos_repairs + fun_repairs;
                    List<String> repair_evaluation = final_rep_ev.split(';');
                    List<String> repairs = final_repairs.split(';');
                    Set<String> set_c_repair = new Set<String>();
                    Set<String> set_c_re = new Set<String>();
                    set_c_re.addAll(c_repair_evaluation);
                    set_c_repair.addAll(c_repairs);

                    System.debug('c_repairable: ' + c_repairable);
                    System.debug('set_c_re: ' + set_c_re);
                    System.debug('set_c_repair: ' + set_c_repair);
                    System.debug('some_c: ' + some_c);

                    // Determines if some of the cosmetic repairs are possible or not. For functional, if any repair is
                    // not possible, then the asset is set to be unrepairable.
                    if (c_repairable == 'No' && set_c_re.size() == set_c_repair.size() && some_c > 0) {
                        c_repairable = 'Partial - see notes';
                    }

                    if (set_c_re.size() != set_c_repair.size() && set_c_repair.size() != 0) {
                        c_repairable = 'Partial - see notes';
                    }

                    Set<String> set_f_repair = new Set<String>();
                    Set<String> set_f_re = new Set<String>();
                    set_f_re.addAll(f_repair_evaluation);
                    set_f_repair.addAll(f_repairs);

                    if (f_repairable == 'No' && set_f_re.size() == set_f_repair.size() && some_f > 0) {
                        f_repairable = 'No'; //used to be partial - see notes
                    }
                    if (set_f_re.size() != set_f_repair.size() && set_f_repair.size() != 0) {
                        f_repairable = 'No'; //used to be partial - see notes
                    }

    // Functionally repairable field set to needs troubleshooting if one of the repairs listed is
    // "Electrical". No longer use this, but may need it again in the future.
    /*
    if(set_f_repair.contains('Electrical')){
        f_repairable = 'Needs troubleshooting';
    } */
                    Set<String> set_re = new Set<String>();
                    set_re.addAll(repair_evaluation);


                    System.debug('FINAL REPAIR EVALUATION SET> ' + set_re);
                    String final_re = '';
                    String final_crepair = '';
                    String final_frepair = '';
                    for (String re : set_re) {
                        final_re += re + '\n';
                    }

                    for (String rp : set_c_repair) {
                        final_crepair += rp + '\n';
                    }

                    if (final_crepair.length() < 3) {
                        final_crepair = '';
                    }

                    for (String rp : set_f_repair) {
                        final_frepair += rp + '\n';
                    }

                    if (final_frepair.length() < 3) {
                        final_frepair = '';
                    }

                    System.debug('FINAL REPAIR EVALUATION> ' + final_re);

                    String cannot_repairs = '';
                    for (String c : cannot) {
                        cannot_repairs += c + '\n';
                        if (c == 'Array Replacement') {
                            f_repairable = 'No';

                        }
                    }

					// Change the fields based on the information collected.
                    p.Cosmetic_Rating__c = cos_rating;
                    if(p.Product_Family__c.contains('Endoscopy') || p.Product_Family__c.contains('Instrument Tray')){
                        p.Cosmetic_Rating__c = 'Good';
                        if(f_notes != ''){
                            p.Cosmetic_Rating__c = 'Bad';
                        }
                        if(p.Endoscopy_Repair_Notes__c != null && p.Endoscopy_Repair_Notes__c.containsIgnoreCase('not repairable')){
                            p.Cosmetic_Rating__c = 'Bad';
                            p.Functional_Rating__c = 'Bad';
                        }
                        // if Functional Rating manually filled in, automatically make Cosmetic Rating the same for Endoscopy only
                        if(p.Functional_Rating__c != null){
                            p.Cosmetic_Rating__c = p.Functional_Rating__c;
                        }
                    }
                  
					// This is used for the pre ship test.
                    if (p.Cosmetics_are_the_same_as_previous_test__c == true) {
                        p.Cosmetic_Rating__c = pItemIdtoPTest.get(p.Product_Item__c).Cosmetic_Rating__c;
                    // JMAY: OLD CODE before using the shared PItemMap SOQL. Note that the SOQL below Id != p.Id is irrelevant since p.ID is a ProductTest.ID not a ProductItem.Id
                    //ProductTest__c PreviousTest = [ select Id, Product_Item__c, Cosmetic_Rating__c from ProductTest__c where Product_Item__c = :p.Product_Item__c AND Id != :p.Id ORDER BY CreatedDate DESC limit 1];
                    // p.Cosmetic_Rating__c = PreviousTest.Cosmetic_Rating__c;
                    }
                  Boolean keepFunctionalRating = false;
                  // for endoscopy tests, if the functional rating is manually changed and no automatic functional rating spits out from the repair matrix, then keep the rating that was chosen manually in the field.
                 // add instrument tray?? and mimic for cosmetic??
                  if(p.Product_Family__c.contains('Endoscopy') && func_rating != null && func_rating == 'N/A' && p.Functional_Rating__c != null){
                      keepFunctionalRating = true;
                  }
                  if(!keepFunctionalRating){
                      p.Functional_Rating__c = func_rating;
                  }

                    p.Cosmetically_Repairable__c = c_repairable;
                    p.Functionally_Repairable__c = f_repairable;
                    p.Cosmetic_Evaluation__c = c_notes;
                    p.Functional_Evaluation__c = f_notes;
                    p.New_Repair_Evaluation__c = final_re;
                    p.Outsource__c = finalout;
                    p.Possible_Cosmetic_Repairs__c = final_crepair;
                    p.Possible_Functional_Repairs__c = final_frepair;
                    p.These_Repairs_Cannot_Be_Done__c = cannot_repairs;
                    p.Image_Rating__c = rating.get(func_rating);
                    p.First_Call_Rating__c = fcnum;
                  system.debug('THIS IS THE STRING JOIN FOR FINAL ADDED REPAIRS LIST >> ' + String.join(finalAddedRepairsList, ';'));
                    p.Automated_Repairs_Added__c = String.join(finalAddedRepairsList, ';');
					// This is later used for setting the review status.
                    if (thisPTestInfo.safe == true) {
                        p.Probe_distribution__c = 'Okay for distribution';
                    }
                    if (thisPTestInfo.safe == false) {
                        p.Probe_distribution__c = 'Not okay for distribution';
                    }


                    System.debug('THIS IS THE SAFE CHECKBOX >>> ' + thisPTestInfo.safe);


					// Set repairs, required and full costs for evals
                    List<String> crepairfinal = final_crepair.split('\n');
                    List<String> frepairfinal = final_frepair.split('\n');
                    String finalc = '';
                    String finalf = '';
                    Decimal requiredcost = 0;
                    Decimal fullcost = 0;
                    if (final_crepair != '') {
                        for (String c : crepairfinal) {
                            if (c != null && RMap.get(c) != null) {
                                System.debug('SETTING UP COST >>>> ' + crepairfinal);
                                if (c == 'Lens Relens') {
                                    requiredcost += RMap.get(c);
                                    fullcost += RMap.get(c);
                                    finalf += c + ';';
                                } else {
                                    fullcost += RMap.get(c);
                                    finalc += c + '; ';
                                }
                            }
                        }
                    }
                    if (final_frepair != '') {
                        for (String f : frepairfinal) {
                            // TEMPORARY - allow all repairs to be added for endoscopy, regardless of price on product page
                            if (f != null && (RMap.get(f) != null || p.Product_Family__c.contains('Endoscopy'))) {
                                System.debug('THIS IS THE FREPAIRFINAL LOOP >>>>>> ' + f + ' AND THIS IS THE REQUIRED COST >> ' + requiredcost);
                                if(p.Product_Family__c.contains('Endoscopy') && f == 'Insertion Tube Replacement'){
                                    f = 'Insertion Tube Replacement Endoscope';
                                }
                                if(RMap.get(f) != null){
                                    requiredcost += RMap.get(f);
                                	fullcost += RMap.get(f);
                                }
                                if(p.Product_Family__c.contains('Endoscopy') && f == 'Insertion Tube Replacement Endoscope'){
                                    f = 'Insertion Tube Replacement';
                                }
                                finalf += f + '; ';
                            }
                        }
                    }

                    if (requiredcost > theProduct.Max_Repair__c) {
                        requiredcost = theProduct.Max_Repair__c;
                    }

                    Decimal recommended = fullcost - requiredcost;
                    if (recommended > theProduct.Max_Non_Functional__c) {
                        recommended = theProduct.Max_Non_Functional__c;
                    }

                    fullcost = requiredcost + recommended;
                    if (fullcost > theProduct.Max_Repair__c) {
                        fullcost = theProduct.Max_Repair__c;
                    }

                    p.Required_Repairs__c = finalf;
                    p.Recommended_Repairs__c = finalc;
                    p.Required_Cost__c = requiredcost;
                    p.Full_Cost__c = fullcost;
              } // end of Ultrasound Probe test components
                    string stepdown = '';
                    string cosmetic_rating = '';
                    string functional_rating = '';
                    string cosmetic_repairs = '';
                    string functional_repairs = '';
                    
                    system.debug('THIS IS THE PRODUCT FAMILY BEFORE PART >> ' + p.Product_Family__c);
                    if(p.Product_Family__c.contains('Part')){
                        if(p.Functional_Status__c != null && p.Cosmetic_Status__c != null){
                           if(p.Functional_Status__c == 'No problem' && p.Cosmetic_Status__c == 'No problem'){
                                stepdown = 'Pass - Move to Finished Goods';
                                Cosmetic_rating = 'Good';
                                Functional_rating = 'Good';
                            }
                        
                        if(p.Cosmetic_Status__c != 'No problem'){
                            cosmetic_rating = 'Bad';
                            if(p.Functional_Status__c == 'No problem'){
                                Functional_rating = 'Good';
                            }
                            functional_rating = 'Good';
                            if(p.Cosmetic_Repair_Capability__c == 'Internal'){
                                stepdown = 'Failed - Move to Cosmetic Repair';
                            }
                            else if(p.Cosmetic_Repair_Capability__c == 'External'){
                                stepdown = 'Failed - Move to External Repair';
                            }
                            else{
                                if(p.Core_Needed__c){
                                    stepdown = 'Failed - Move to Non Conforming';
                                }
                                else{
                                    stepdown = 'Failed - Scrap';
                                }
                                
                            }
                            system.debug('THIS IS THE COSMETIC STATUS >>> ' + p.Cosmetic_Status__c);
                            
                            if(p.Cosmetic_Status__c.contains('External part - broken/damaged') || p.Cosmetic_Status__c.contains('External part - scratched')){
                                cosmetic_repairs += 'Plastic Repair/Paint'+ '\n';
                            }
                            if(p.Cosmetic_Status__c.contains('External part - discolored')){
                                cosmetic_repairs += 'Additional Cleaning'+ '\n';
                            }
                            if(p.Cosmetic_Status__c.contains('External part - missing component')){
                                cosmetic_repairs += 'Component Replacement' + '\n';
                            }  
                            
                            system.debug('THIS IS THE COSMETIC REPAIRS FOR PARTS >>> ' + cosmetic_repairs);
                        }
                       if(p.Functional_Status__c != 'No problem'){
                           Functional_Rating = 'Bad';
                           if(p.Cosmetic_Status__c == 'No problem'){
                               Cosmetic_rating = 'Good';
                           }
                            if(p.Functional_Repair_Capability__c == 'Internal'){
                                stepdown = 'Failed - Move to Functional Repair';
                            }
                            else if(p.Functional_Repair_Capability__c == 'External'){
                                stepdown = 'Failed - Move to External Repair';
                            }
                            else{
                                if(p.Core_Needed__c){
                                    stepdown = 'Failed - Move to Non Conforming';
                                }
                                else{
                                    stepdown = 'Failed - Scrap';
                                }
                                
                            }
                           
                           if(p.Functional_Status__c.contains('Internal parts - failure')){
                               functional_repairs += 'Internal Parts' + '\n';
                           }
                           if(p.Functional_Status__c.contains('Printed circuit board - failure')){
                               functional_repairs += 'Printed Circuit Board' + '\n';
                           }
                           if(p.Functional_Status__c.contains('Touch glass - failure')){
                               functional_repairs += 'Touch Glass' + '\n';
                           }
                           if(p.Functional_Status__c.contains('Monitor - failure')){
                               functional_repairs += 'Monitor';
                           }
                           
                            
                           system.debug('THIS IS THE FUNCTIONAL REPAIRS FOR PARTS >>> ' + functional_repairs);
                       }
                        
                        switch on stepdown{
                            when 'Failed - Scrap'{
                                cosmetic_rating = 'Scrap';
                                functional_rating = 'Scrap';
                                review_status = 'Scrap';
                            }
                            when 'Pass - Move to Finished Goods'{
                                
                                review_status = 'Finished Goods';
                            }
                            when 'Failed - Move to Non Conforming'{
                                
                                review_status = 'Non Conforming'; // double check this review status name
                            }
                            when 'Failed - Move to Functional Repair'{
                                
                                review_status = 'Work in Progress - Functional';
                            }
                            when 'Failed - Move to Cosmetic Repair'{
                                review_status = 'Work in Progress - Cosmetic';
                            }
                            when 'Failed - Move to External Repair'{
                                review_status = 'Work in Progress - External Repair';
                            }
                            
                        }
                       p.Cosmetic_Rating__c = cosmetic_rating;
                       p.Functional_Rating__c = functional_rating;
                       p.Step_down_decision__c = stepdown;
                       p.Possible_Cosmetic_Repairs__c = cosmetic_repairs;
                       p.Possible_Functional_Repairs__c = functional_repairs;
                       
                       // Part Test Priority Rating
                       p.Part_Priority_Rating_at_Test__c = p.Product_Item__r.Product_Name__r.Parts_Priority_Rating__c;
                       
                        }// only does above if cosmetic and functional status fields are filled in
                        system.debug('IS REVIEW STATUS SET??? >>> ' + review_status);
                    } // end of Part section
                    // This section is for the coil product test.
                    system.debug('THIS IS THE PRODUCT FAMILY BEFORE COIL >> ' + p.Product_Family__c);
                    if(p.Product_Family__c.contains('Coil')){
                        string cosmetic_notes = '';
                        string functional_notes = '';
                        cosmetic_rating = 'Good';
                        functional_rating = 'Good';
                        if(p.Coil_Cosmetic_Evaluation__c.contains('Scrapes, Scuffs, or Marks')){
                            cosmetic_rating = 'Bad';
                            cosmetic_repairs += 'Plastic Repair/Paint; ';
					        cosmetic_notes += 'C: Scrapes, Scuffs, or Marks; ';                    
                        }
                        if(p.Coil_Cosmetic_Evaluation__c.contains('Parts Missing')){
                            cosmetic_rating = 'Bad';
					        cosmetic_notes += 'C: Parts Missing; ';                    
                        }
                        if(p.Coil_Cosmetic_Evaluation__c.contains('Foam Ripped')){
                            cosmetic_rating = 'Bad';
                            cosmetic_repairs += 'Refoam; ';
					        cosmetic_notes += 'C: Foam Ripped; ';                    
                        }
                        if(p.Need_Refoamed__c == true && !p.Coil_Cosmetic_Evaluation__c.contains('Foam Ripped')){
                            cosmetic_rating = 'Bad';
                            cosmetic_repairs += 'Refoam; ';
					        cosmetic_notes += 'C: Needs Refoamed; ';
                        }
                        if(p.Bent_Pins_on_Connectors__c == true){
                            functional_rating = 'Bad';
                            functional_notes += 'BP: Fail; ';
                        }
                        if(p.Network_Analyzer_Test__c == 'Fail'){
                            functional_rating = 'Bad';
                            functional_notes += 'NAT: Fail; ';
                        }
                        if(p.Decoupling_Test__c == 'Fail'){
                            functional_rating = 'Bad';
                            functional_notes += 'DT: Fail; ';
                        }
                        if(p.Preamp_Current_Draw__c == 'Fail'){
                            functional_rating = 'Bad';
                            functional_notes += 'PCD: Fail; ';
                        }
                        if(p.Coil_Functional_Evaluation__c != null){
                            if(p.Coil_Functional_Evaluation__c.contains('Cable Repair')){
                                functional_rating = 'Bad';
                                functional_notes += 'Cable: Fail; ';
                                functional_repairs += 'Cable Repair; ';
                        	}
                            if(p.Coil_Functional_Evaluation__c.contains('Board Repair')){
                                functional_rating = 'Bad';
                                functional_notes += 'Board: Fail; ';
                                functional_repairs += 'Board Repair; ';
                            }
                        }
                        
                        
                        
                        
                        
                        
                        p.Cosmetic_Rating__c = cosmetic_rating;
                        p.Functional_Rating__c = functional_rating;
                        p.Possible_Cosmetic_Repairs__c = cosmetic_repairs;
                        p.Possible_Functional_Repairs__c = functional_repairs;
                        p.Cosmetic_Evaluation__c = cosmetic_notes;
                        p.Functional_Evaluation__c = functional_notes;
                        
                    } //end of Coil section
                    
                    system.debug('THIS IS THE PRODUCT FAMILY BEFORE SYSTEM >> ' + p.Product_Family__c);
                    if(p.Product_Family__c.contains('System')){
                        system.debug('INSIDE SYSTEM TEST LOOP >> ' + p.Depot_Standard_System_Test__c);
                        if(p.Depot_Standard_System_Test__c == 'Depot System'){
                            Decimal requiredcost = 0;
                            Decimal recommendedcost = 0;
                            Decimal fullcost = 0;
                            String finalf = '';
                            String finalc = '';
                            List<ID> partsList = new List<ID>();
       
                            if (p.Depot_Repair_Required_Part_1__c != null && prodIDtoRMaps.containsKey(p.Depot_Repair_Required_Part_1__c)) {
                                RMap = prodIDtoRMaps.get(p.Depot_Repair_Required_Part_1__c);
                                finalf += prodIDToProducts.get(p.Depot_Repair_Required_Part_1__c).Name + ' Replacement; ';
                                if(p.Depot_Required_Part_1_New_Used__c == 'New' && RMap.get('New part price') != null){
                                    requiredcost += (p.Depot_Required_Part_1_QTY__c * RMap.get('New part price'));
                                }
                                if(p.Depot_Required_Part_1_New_Used__c == 'Used' && RMap.get('Used part price') != null){
                                    requiredcost += (p.Depot_Required_Part_1_QTY__c * RMap.get('Used part price'));
                                }
                            }
                            
                            if (p.Depot_Repair_Required_Part_2__c != null && prodIDtoRMaps.containsKey(p.Depot_Repair_Required_Part_2__c)) {
                                RMap = prodIDtoRMaps.get(p.Depot_Repair_Required_Part_2__c);
                                finalf += prodIDToProducts.get(p.Depot_Repair_Required_Part_2__c).Name + ' Replacement; ';
                                if(p.Depot_Required_Part_2_New_Used__c == 'New' && RMap.get('New part price') != null){
                                    requiredcost += (p.Depot_Required_Part_2_QTY__c * RMap.get('New part price'));
                                }
                                if(p.Depot_Required_Part_2_New_Used__c == 'Used' && RMap.get('Used part price') != null){
                                    requiredcost += (p.Depot_Required_Part_2_QTY__c * RMap.get('Used part price'));
                                }
                            }
                            
                            if (p.Depot_Repair_Required_Part_3__c != null && prodIDtoRMaps.containsKey(p.Depot_Repair_Required_Part_3__c)) {
                                RMap = prodIDtoRMaps.get(p.Depot_Repair_Required_Part_3__c);
                                finalf += prodIDToProducts.get(p.Depot_Repair_Required_Part_3__c).Name + ' Replacement; ';
                                if(p.Depot_Required_Part_3_New_Used__c == 'New' && RMap.get('New part price') != null){
                                    requiredcost += (p.Depot_Required_Part_3_QTY__c * RMap.get('New part price'));
                                }
                                if(p.Depot_Required_Part_3_New_Used__c == 'Used' && RMap.get('Used part price') != null){
                                    requiredcost += (p.Depot_Required_Part_3_QTY__c * RMap.get('Used part price'));
                                }
                            }
                            
                            if (p.Depot_Repair_Required_Part_4__c != null && prodIDtoRMaps.containsKey(p.Depot_Repair_Required_Part_4__c)) {
                                RMap = prodIDtoRMaps.get(p.Depot_Repair_Required_Part_4__c);
                                finalf += prodIDToProducts.get(p.Depot_Repair_Required_Part_4__c).Name + ' Replacement; ';
                                if(p.Depot_Required_Part_4_New_Used__c == 'New' && RMap.get('New part price') != null){
                                    requiredcost += (p.Depot_Required_Part_4_QTY__c * RMap.get('New part price'));
                                }
                                if(p.Depot_Required_Part_4_New_Used__c == 'Used' && RMap.get('Used part price') != null){
                                    requiredcost += (p.Depot_Required_Part_4_QTY__c * RMap.get('Used part price'));
                                }
                            }
                            
                            if (p.Depot_Repair_Cosmetic_Part_1__c != null && prodIDtoRMaps.containsKey(p.Depot_Repair_Cosmetic_Part_1__c)) {
                                RMap = prodIDtoRMaps.get(p.Depot_Repair_Cosmetic_Part_1__c);
                                finalc += prodIDToProducts.get(p.Depot_Repair_Cosmetic_Part_1__c).Name + ' Replacement; ';
                                if(p.Depot_Cosmetic_Part_1_New_Used__c == 'New' && RMap.get('New part price') != null){
                                    recommendedcost += (p.Depot_Cosmetic_Part_1_QTY__c * RMap.get('New part price'));
                                }
                                if(p.Depot_Cosmetic_Part_1_New_Used__c == 'Used' && RMap.get('Used part price') != null){
                                    recommendedcost += (p.Depot_Cosmetic_Part_1_QTY__c * RMap.get('Used part price'));
                                }
                            }
                            
                            if (p.Depot_Repair_Cosmetic_Part_2__c != null && prodIDtoRMaps.containsKey(p.Depot_Repair_Cosmetic_Part_2__c)) {
                                RMap = prodIDtoRMaps.get(p.Depot_Repair_Cosmetic_Part_2__c);
                                finalc += prodIDToProducts.get(p.Depot_Repair_Cosmetic_Part_2__c).Name + ' Replacement; ';
                                if(p.Depot_Cosmetic_Part_2_New_Used__c == 'New' && RMap.get('New part price') != null){
                                    recommendedcost += (p.Depot_Cosmetic_Part_2_QTY__c * RMap.get('New part price'));
                                }
                                if(p.Depot_Cosmetic_Part_2_New_Used__c == 'Used' && RMap.get('Used part price') != null){
                                    recommendedcost += (p.Depot_Cosmetic_Part_2_QTY__c * RMap.get('Used part price'));
                                }
                            }
                            
                            if (p.Depot_Repair_Cosmetic_Part_3__c != null && prodIDtoRMaps.containsKey(p.Depot_Repair_Cosmetic_Part_3__c)) {
                                RMap = prodIDtoRMaps.get(p.Depot_Repair_Cosmetic_Part_3__c);
                                finalc += prodIDToProducts.get(p.Depot_Repair_Cosmetic_Part_3__c).Name + ' Replacement; ';
                                if(p.Depot_Cosmetic_Part_3_New_Used__c == 'New' && RMap.get('New part price') != null){
                                    recommendedcost += (p.Depot_Cosmetic_Part_3_QTY__c * RMap.get('New part price'));
                                }
                                if(p.Depot_Cosmetic_Part_3_New_Used__c == 'Used' && RMap.get('Used part price') != null){
                                    recommendedcost += (p.Depot_Cosmetic_Part_3_QTY__c * RMap.get('Used part price'));
                                }
                            }
                            
                            if (p.Depot_Repair_Cosmetic_Part_4__c != null && prodIDtoRMaps.containsKey(p.Depot_Repair_Cosmetic_Part_4__c)) {
                                RMap = prodIDtoRMaps.get(p.Depot_Repair_Cosmetic_Part_4__c);
                                finalc += prodIDToProducts.get(p.Depot_Repair_Cosmetic_Part_4__c).Name + ' Replacement; ';
                                if(p.Depot_Cosmetic_Part_4_New_Used__c == 'New' && RMap.get('New part price') != null){
                                    recommendedcost += (p.Depot_Cosmetic_Part_4_QTY__c * RMap.get('New part price'));
                                }
                                if(p.Depot_Cosmetic_Part_4_New_Used__c == 'Used' && RMap.get('Used part price') != null){
                                    recommendedcost += (p.Depot_Cosmetic_Part_4_QTY__c * RMap.get('Used part price'));
                                }
                            }
                            
                            if (requiredcost > theProduct.Max_Repair__c) {
                                requiredcost = theProduct.Max_Repair__c;
                            }
        
                            if (recommendedcost > theProduct.Max_Non_Functional__c) {
                                recommendedcost = theProduct.Max_Non_Functional__c;
                            }
        
                            fullcost = requiredcost + recommendedcost;
                            if (fullcost > theProduct.Max_Repair__c) {
                                fullcost = theProduct.Max_Repair__c;
                            }
                            
                            if(p.Labor_Estimated_Time_Hours__c != null){
                                requiredcost += (p.Labor_Estimated_Time_Hours__c * p.Labor_Price_Hr__c);
                                fullcost += (p.Labor_Estimated_Time_Hours__c * p.Labor_Price_Hr__c);
                            }
                            
                            p.Required_Repairs__c = finalf;
                            p.Possible_Functional_Repairs__c = finalf;
                            p.Recommended_Repairs__c = finalc;
                            p.Possible_Cosmetic_Repairs__c = finalc;
                            p.Required_Cost__c = requiredcost;
                            p.Full_Cost__c = fullcost;
                            system.debug('THIS IS DEPOT TEST >> ' + finalf + ' & ' + finalc);
                        }
                        
                        if(p.Depot_Standard_System_Test__c == 'Standard System'){
                            String systemCosmeticRating = 'Good';
                            String systemFunctionalRating = 'Good';
                            String systemCosmeticNotes = '';
                            String systemFunctionalNotes = '';
                            
                            if(p.Panels_Casters_Cosmetic__c != 'No problem'){
                                systemCosmeticRating = 'Fair';
                                systemCosmeticNotes += 'PC: ' + p.Panels_Casters_Cosmetic__c + '; ';
                            }
                            if(p.User_Interface_Control_Panel_Cosmetic__c != 'No problem' || p.Monitor_Touchscreen_Cosmetic__c != 'No problem'){
                                systemCosmeticRating = 'Bad';
                                if(p.User_Interface_Control_Panel_Cosmetic__c != 'No problem'){
                                    systemCosmeticNotes += 'UI/CP: ' + p.User_Interface_Control_Panel_Cosmetic__c + '; ';
                                }
                                if(p.Monitor_Touchscreen_Cosmetic__c != 'No problem'){
                                    systemCosmeticNotes += 'M: ' + p.Monitor_Touchscreen_Cosmetic__c;
                                }
                                
                            }
                            
                            String luminescenceResult = '';
                            if(p.Luminescence_Test_Value__c != null){
                                if(p.Luminescence_Test_Value__c > p.Luminescence_Test_Lower_Value__c && p.Luminescence_Test_Value__c < p.Luminescence_Test_Upper_Value__c){
                                    luminescenceResult = 'Pass';
                                }
                                else{
                                    luminescenceResult = 'Fail';
                                }
                            }
                            
                            if(p.TGC__c == 'Fail' || p.Rotary_Knob_Potentiometer__c == 'Fail' || p.Alpha_Numeric__c == 'Fail' || p.Trackball__c == 'Fail' || 
                               p.Button_Pressure__c == 'Fail' || p.Move_Test__c == 'Fail' || p.Monitor_Arm__c == 'Fail' || p.Breaks_Locks__c == 'Fail' || p.Alignment__c == 'Fail'){
                                 systemFunctionalRating = 'Fair';
                            }
                            
                            if(p.DOA_Result__c == 'Yes' || p.Diagnostic_Test_Result__c == 'Fail' || p.Move_Test__c == 'Fail' || luminescenceResult == 'Fail' ){
                                systemFunctionalRating = 'Bad';
                            }
                            
                            if(p.DOA_Result__c == 'Yes'){
                                systemFunctionalNotes += 'DOA; ';
                            }
                            
                            if(p.Diagnostic_Test_Result__c == 'Fail'){
                                systemFunctionalNotes += 'Diagnostic Test Fail; ';
                            }
                            
                            if(p.TGC__c == 'Fail'){
                                systemFunctionalNotes += 'TGC Fail; ';
                            }
                            if(p.Rotary_Knob_Potentiometer__c == 'Fail'){
                                systemFunctionalNotes += 'Rotary Knob/Potentiometer Fail; ';
                            }
                            if(p.Alpha_Numeric__c == 'Fail'){
                                systemFunctionalNotes += 'Alpha Numeric Fail; ';
                            }
                            if(p.Trackball__c == 'Fail'){
                                systemFunctionalNotes += 'Trackball Fail; ';
                            }
                            if(p.Button_Pressure__c == 'Fail'){
                                systemFunctionalNotes += 'Button Pressure Fail; ';
                            }
                            if(p.Move_Test__c == 'Fail'){
                                systemFunctionalNotes += 'Move Test Fail; ';
                            }
                            if(luminescenceResult == 'Fail'){
                                systemFunctionalNotes += 'Luminescence Fail; ';
                            }
                            if(p.Monitor_Arm__c == 'Fail'){
                                systemFunctionalNotes += 'Monitor Arm Fail; ';
                            }
                            if(p.Breaks_Locks__c == 'Fail'){
                                systemFunctionalNotes += 'Breaks/Locks Fail; ';
                            }
                            if(p.Alignment__c == 'Fail'){
                                systemFunctionalNotes += 'Alignment Fail; ';
                            }
                            
                            p.Cosmetic_Rating__c = systemCosmeticRating;
                            p.Functional_Rating__c = systemFunctionalRating;
                            p.Cosmetic_Evaluation__c = systemCosmeticNotes;
                            p.Functional_Evaluation__c = systemFunctionalNotes;
                            system.debug('THIS IS STANDARD SYSTEM TEST >> ' + systemFunctionalNotes + ' & ' + systemCosmeticNotes);
                            
                        }
                        
                        
                        
                        
                        
                    }
                } // end of trigger loop

// end of Before
            } else if (Trigger.isAfter) {
				system.debug('IS REVIEW STATUS STILL SET??? >>> ' + review_status);
                System.debug('THIS IS THE START OF TestNameTrigger');

                RecordType preShipRecordType;
                RecordType functionalRecordType;
                RecordType functionalTEERecordType;
                RecordType cosmeticRecordType;
                RecordType cosmeticTEERecordType;
                RecordType partsRecordType;
                RecordType endoscopyFlexibleRecordType;
                RecordType endoscopyRigidRecordType;
                RecordType RMACoreExchangeRT;
                RecordType RMAExtRepairRT;

                for (RecordType rt : ProboCommonUtils.getRecordTypes('ProductTest__c')) {
                    if (rt.DeveloperName == 'Pre_Shipping_Test') {
                        preShipRecordType = rt;
                        break;
                    }
                }
                
                for (RecordType rt : ProboCommonUtils.getRecordTypes('RMA__c')) {
                    switch on rt.DeveloperName {

                        when 'Core_Exchange' {
                            RMACoreExchangeRT = rt;
                        }
                        when 'External_Repair_Testing' {
                            RMAExtRepairRT = rt;
                        }
                        
                    }
                    
                }

                for (RecordType rt : ProboCommonUtils.getRecordTypes('Product_Repair__c')) {
                    switch on rt.Name {

                        when 'Functional Repair' {
                            functionalRecordType = rt;
                        }
                        when 'Functional TEE Repair' {
                            functionalTEERecordType = rt;
                        }
                        when 'Cosmetic Repair' {
                            cosmeticRecordType = rt;
                        }
                        when 'Cosmetic TEE Repair' {
                            cosmeticTEERecordType = rt;
                        }
                        when 'Part Repair'{
                            PartsRecordType = rt;
                        }
                        when 'Endoscopy - Flexible Repair'{
                            endoscopyFlexibleRecordType = rt;
                        }
                        when 'Endoscopy - Rigid Repair'{
                            endoscopyRigidRecordType = rt;
                        }
                            
                    }
                }
                
                
                
                Set<Id> pItemIdsNeeded = new Set<Id>();

                for (ProductTest__c p : newRecs) {
                    if (p.Product_Item__c != null) {
                        pItemIdsNeeded.add(p.Product_Item__c);
                    }
                }

                Map<Id, ProductItem__c> pItemIdToPItem = new Map<Id, ProductItem__c>(
                [
                        SELECT Id, Added_to_Work_Order__c, Product_Name__c, Date_Last_Test_Completed__c,
                                Check_In_Type__c, Required_Repairs__c, Recommended_Repairs__c, Required_Cost__c, Full_Cost__c,
                                Latest_Test_Verified_Numbers_Match__c, Always_Save_for_Parts__c, 
                                Testing_Priority_Rating__c, Product_Family__c, Cosmetically_unable_to_Improve__c,
                                Functionally_unable_to_improve__c, Review_status_priority_rating_threshold__c,
                                Review_Status__c, Probe_Type__c, Functional_Notes__c, Cosmetic_Notes__c
                        FROM ProductItem__c
                        WHERE Id IN :pItemIdsNeeded
                ]);

                Set<Id> prodIdsNeeded = new Set<Id>();

                for (ProductItem__c p : pItemIdToPItem.values()) {
                    if (p.Product_Name__c != null) {
                        prodIdsNeeded.add(p.Product_Name__c);
                    }
                }

                Map<Id, List<ProductTest__c>> pItemIDToProductTestList = new Map<Id, List<ProductTest__c>>();

                for (ProductTest__c r : [
                        SELECT Id, Functional_Rating__c, Cosmetic_Rating__c, CreatedDate, Product_Item__c
                        FROM ProductTest__c
                        WHERE Product_Item__c = :pItemIdsNeeded
                        ORDER BY CreatedDate ASC
                ]) {

                    if (!pItemIDToProductTestList.containsKey(r.Product_Item__c)) {
                        pItemIDToProductTestList.put(r.Product_Item__c, new List<ProductTest__c>());
                    }
                    pItemIDToProductTestList.get(r.Product_Item__c).add(r);
                }

                Map<Id, List<Product_Repair__c>> pItemIDToProductRepairList = new Map<Id, List<Product_Repair__c>>();

                for (Product_Repair__c r : [
                        SELECT Id, Repair_Activity__c, Post_Test__c, Repair_date__c, Product_Item__c,
                                Date_Last_Test_Completed__c, Estimated_Repair_Time__c,
                                Repair_Activity_Lead_Time__c, No_longer_needed__c, Reason_for_why_no_longer_needed__c
                        FROM Product_Repair__c
                        WHERE Product_Item__c = :pItemIdsNeeded
                        ORDER BY Repair_date__c DESC
                ]) {

                    if (!pItemIDToProductRepairList.containsKey(r.Product_Item__c)) {
                        pItemIDToProductRepairList.put(r.Product_Item__c, new List<Product_Repair__c>());
                    }
                    pItemIDToProductRepairList.get(r.Product_Item__c).add(r);
                }


                Map<Id, List<RMA__c>> pItemIDToRMAList = new Map<Id, List<RMA__c>>();

                for (RMA__c r : [
                        SELECT Name, Id, Approved_Repairs__c,Date_Last_Test_Completed__c, Bending_Rubber__c, Cable_Jacket__c,
                                Cap__c, Connector__c, Control_Housing__c, Insertion_Tube__c, Lens__c, ProductItem__c,
                                Probe_Handle__c, Strain_Relief__c, Tip__c, Airscan__c, Articulation__c,
                                Color_Artifacts__c, CW_Artifacts__c, CW_Pulse__c, First_Call__c, Image__c,
                                Interior__c, Leakage_Current__c, Motor__c, Orientation__c, Possible_Repairs__c
                        FROM RMA__c
                        WHERE ProductItem__c = :pItemIdsNeeded AND RecordTypeId != :RMACoreExchangeRT.Id AND RecordTypeId != :RMAExtRepairRT.Id
                        ORDER BY LastModifiedDate DESC
                ]) {

                    if (!pItemIDToRMAList.containsKey(r.ProductItem__c)) {
                        pItemIDToRMAList.put(r.ProductItem__c, new List<RMA__c>());
                    }
                    pItemIDToRMAList.get(r.ProductItem__c).add(r);
                }

                Map<Id, Work_Order__c> pItemIdToWO = new Map<Id, Work_Order__c>();

                if (Trigger.isInsert) {
                    for (Work_Order__c w : [
                            SELECT Id, Status__c, Asset__c
                            FROM Work_Order__c
                            WHERE Asset__c IN :pItemIdsNeeded
                            ORDER BY CreatedDate DESC
                    ]) {

                        if (!pItemIdToWO.containsKey(w.Asset__c)) {
                            pItemIdToWO.put(w.Asset__c, w);
                        }
                    }
                }

                

// END OF TRIGGER SETUP

                List<Work_Order__c> woToUpdate = new List<Work_Order__c>();
                List<ProductItem__c> pItemsToUpdate = new List<ProductItem__c>();
                List<Product_Repair__c> repairsToUpsert = new List<Product_Repair__c>();
                List<RMA__c> RMAsToUpdate = new List<RMA__c>();

                for (ProductTest__c p : newRecs) {

                    Boolean WOcheck = false;

                    ProductItem__c item = pItemIdToPItem.get(p.Product_Item__c);

					// Checks to see if work order already created; test is last step of repair and testing work orders - this closes out the work order; marks it as completed and unchecks the box on the asset page
                    if (Trigger.isInsert && item.Added_to_Work_Order__c == true) {
                        GH_Logger.debug('ProductTest was Added_to_Work_Order on Insert so we will not make Product_Repairs__c');
                        Work_Order__c wo = pItemIdToWO.get(item.Id);
                        wo.Status__c = 'Completed';
                        woToUpdate.add(wo);
                        item.Added_to_Work_Order__c = false;
                        WOcheck = true;
                    }

                    List<Product_Repair__c> repairlist = new List<Product_Repair__c>();
                    if (pItemIDToProductRepairList.containsKey(p.Product_Item__c)) {
                        repairlist = pItemIDToProductRepairList.get(p.Product_Item__c);
                    }

                    List<ProductTest__c> testlist = new List<ProductTest__c>();
                    if (pItemIDToProductTestList.containsKey(p.Product_Item__c)) {
                        testlist = pItemIDToProductTestList.get(p.Product_Item__c);
                    }

                    String finalrepairlist = '';
                    Integer leadtime = 0;
                    Decimal repairtime = 0;
					
// Update post test in repairs done since last test
                    for (Product_Repair__c pr : repairlist) {
                        Boolean changed = false;

                        if (pr.Date_Last_Test_Completed__c != p.CreatedDate) {
                            pr.Date_Last_Test_Completed__c = p.CreatedDate;
                            changed = true;
                        }
                        
                        if(p.Final_QC_Test_Date__c != null){
                            if(pr.Date_Last_Test_Completed__c != p.Final_QC_Test_Date__c){
                                pr.Date_Last_Test_Completed__c = p.Final_QC_Test_Date__c;
                                changed = true;
                            }
                        }

                        if ((pr.Repair_date__c <= p.CreatedDate) && (pr.Repair_date__c != null) && (pr.Post_Test__c == null)) {
                            finalrepairlist += pr.Repair_Activity__c;
                            pr.Post_Test__c = p.Id;
                            changed = true;
                        }

                        if (pr.Repair_date__c == null && pr.No_longer_needed__c == false) {
                            leadtime += Integer.valueOf(pr.Repair_Activity_Lead_Time__c);
                            repairtime += pr.Estimated_Repair_Time__c;
                        }

                        if (changed) {
                            repairsToUpsert.add(pr);
                        }
                    }


                    // Determine Review Status based on complex if then statements; the order matters - some technically
                    // fall under more than one review status; the order goes from best to worst, and then harvest at the end;
                    // lastly no functional test available
                    String ReviewStatus = 'Unknown';
                    String FunctionalRating = '';
                    String FunctionalNotes = '';
                    String CosmeticNotes = '';
                    String FunctionallyRepairable = '';

                    if (p.Functional_Rating__c != null) {
                        FunctionalRating = p.Functional_Rating__c;
                    }

                    if (p.Cosmetic_Evaluation__c != null) {
                        CosmeticNotes = p.Cosmetic_Evaluation__c;
                    }

                    if (p.Functional_Evaluation__c != null) {
                        FunctionalNotes = p.Functional_Evaluation__c;
                    }

                    if (p.Functionally_Repairable__c != null) {
                        FunctionallyRepairable = p.Functionally_Repairable__c;
                    }

                    // TODO: ran into issues with systems since the fields used to determine review status are not updated currently with systems;
                    // TODO: may want to add systems in later, will just need to adjust code to use more variables for missing fields (see functionally repairable above)
                    if (item.Product_Family__c.contains('Probe')) {
                        if ((FunctionalRating.containsIgnoreCase('Good') && p.Cosmetic_Rating__c == 'Good') || (FunctionalRating.containsIgnoreCase('Good') &&
                                p.Cosmetic_Rating__c == 'Fair' && item.Cosmetically_unable_to_Improve__c == true)) {
                            ReviewStatus = 'Finished Goods';
                        }

                        System.debug('REVIEW STATUS AFTER FG: ' + ReviewStatus);
                        System.debug('THE RATING >>> ' + FunctionalRating + ' AND THE REPAIRABLE >>> ' + FunctionallyRepairable);

                        if (((FunctionalRating.containsIgnoreCase('Fair') && FunctionallyRepairable.equalsIgnoreCase('Yes')) ||
                                (FunctionalRating.containsIgnoreCase('Bad') && FunctionallyRepairable.equalsIgnoreCase('Yes')) ||
                                (FunctionalRating.containsIgnoreCase('Bad') && FunctionalNotes.containsIgnoreCase('Does not register'))) && item.Functionally_unable_to_improve__c == false) {
                            ReviewStatus = 'Repair Queue';
                        }

                        System.debug('REVIEW STATUS AFTER RQ: ' + ReviewStatus);

                        if (item.Cosmetically_unable_to_Improve__c == false
                                && ((FunctionalRating.containsIgnoreCase('Good') && p.Cosmetic_Rating__c == 'Fair')
                                || (FunctionalRating.containsIgnoreCase('Good') && p.Cosmetic_Rating__c == 'Bad')
                                || (item.Always_Save_for_Parts__c == false
                                && (!FunctionallyRepairable.equalsIgnoreCase('Yes') || item.Testing_Priority_Rating__c < item.Review_status_priority_rating_threshold__c)
                                && ((FunctionalRating.containsIgnoreCase('Fair') && p.Cosmetic_Rating__c == 'Fair')
                                || (FunctionalRating.containsIgnoreCase('Fair') && p.Cosmetic_Rating__c == 'Bad'))))) {
                            ReviewStatus = 'Cosmetic Repair Queue';
                        }
                        System.debug('REVIEW STATUS AFTER CRQ: ' + ReviewStatus);

                        if ((!FunctionallyRepairable.equalsIgnoreCase('Yes') || item.Testing_Priority_Rating__c < item.Review_status_priority_rating_threshold__c)
                                && item.Always_Save_for_Parts__c == false
                                && p.Probe_distribution__c != null
                                && p.Probe_distribution__c.equalsIgnoreCase('Okay for distribution')

                                && ((FunctionalRating.containsIgnoreCase('Fair') && p.Cosmetic_Rating__c == 'Bad'
                                && item.Cosmetically_unable_to_Improve__c == true)

                                || (FunctionalRating.containsIgnoreCase('Bad') && (p.Cosmetic_Rating__c == 'Good' || p.Cosmetic_Rating__c == 'Fair'))

                                || (FunctionalRating.containsIgnoreCase('Bad')
                                && (FunctionalNotes.containsIgnoreCase('Exists:major at SR (under low stress)')
                                || FunctionalNotes.containsIgnoreCase('Exists:major at 6"+ below SR (under low stress)')
                                || FunctionalNotes.containsIgnoreCase('I:Light shadow(s) - middle 80%')
                                || FunctionalNotes.containsIgnoreCase('I:Moderate shadow(s)'))))) {
                            ReviewStatus = 'eBay';
                        }

                        System.debug('REVIEW STATUS AFTER E: ' + ReviewStatus);

                        if ((!FunctionallyRepairable.equalsIgnoreCase('Yes') || item.Testing_Priority_Rating__c < item.Review_status_priority_rating_threshold__c)
                                && item.Always_Save_for_Parts__c == false
                                && p.Probe_distribution__c != null
                                && p.Probe_distribution__c.equalsIgnoreCase('Okay for distribution')
                                && FunctionalRating.containsIgnoreCase('Bad')
                                && ((FunctionalNotes.containsIgnoreCase('A:Dark shadow(s) - middle 80%') || FunctionalNotes.containsIgnoreCase('I:Dark shadow(s) - outer edge'))
                                || (p.Cosmetic_Rating__c == 'Bad')
                                || (FunctionalNotes.containsIgnoreCase('Automatic')))) {
                            ReviewStatus = 'Auction';
                        }

                        if ((FunctionalRating.containsIgnoreCase('Bad') && FunctionalNotes.containsIgnoreCase('Does not register'))) {
                            ReviewStatus = 'Repair Queue';
                        }
                        System.debug('REVIEW STATUS AFTER A: ' + ReviewStatus);
                        if (item.Always_Save_for_Parts__c == false
                                && ((FunctionalRating.containsIgnoreCase('Fair') && p.Cosmetic_Rating__c == 'Good' && (!FunctionallyRepairable.equalsIgnoreCase('Yes') ||
                                item.Testing_Priority_Rating__c < item.Review_status_priority_rating_threshold__c))
                                || (FunctionalRating.containsIgnoreCase('Fair') && p.Cosmetic_Rating__c == 'Fair' && (!FunctionallyRepairable.equalsIgnoreCase('Yes') ||
                                item.Testing_Priority_Rating__c < item.Review_status_priority_rating_threshold__c) && item.Cosmetically_unable_to_Improve__c == true)
                                || (FunctionalRating.containsIgnoreCase('Good') && p.Cosmetic_Rating__c == 'Bad' && item.Cosmetically_unable_to_Improve__c == true
                                && p.Probe_distribution__c != null && p.Probe_distribution__c.equalsIgnoreCase('Okay for distribution'))
                                || (FunctionalRating.containsIgnoreCase('Bad') && (!FunctionallyRepairable.equalsIgnoreCase('Yes') ||
                                item.Testing_Priority_Rating__c < item.Review_status_priority_rating_threshold__c) && CosmeticNotes.containsIgnoreCase('L:bubble') && p.Probe_distribution__c != null && p.Probe_distribution__c.equalsIgnoreCase('Okay for distribution'))
                                || (FunctionalRating.containsIgnoreCase('Bad') && (!FunctionallyRepairable.equalsIgnoreCase('Yes') ||
                                item.Testing_Priority_Rating__c < item.Review_status_priority_rating_threshold__c) && FunctionalNotes.containsIgnoreCase('I:Light shadow(s) - outer edge') && p.Probe_distribution__c != null && p.Probe_distribution__c.equalsIgnoreCase('Okay for distribution')))) {
                            ReviewStatus = 'Special Offer';
                        }
                        System.debug('REVIEW STATUS AFTER SO: ' + ReviewStatus);
                        if (item.Always_Save_for_Parts__c == false
                                && ((FunctionalRating.containsIgnoreCase('Good') && p.Cosmetic_Rating__c == 'Bad' && item.Cosmetically_unable_to_Improve__c == true
                                && p.Probe_distribution__c != null && p.Probe_distribution__c.equalsIgnoreCase('Not okay for distribution'))
                                || (FunctionalRating.containsIgnoreCase('Fair') && p.Cosmetic_Rating__c == 'Bad' && (!FunctionallyRepairable.equalsIgnoreCase('Yes') ||
                                item.Testing_Priority_Rating__c < item.Review_status_priority_rating_threshold__c) && item.Cosmetically_unable_to_Improve__c == true
                                && p.Probe_distribution__c != null && p.Probe_distribution__c.equalsIgnoreCase('Not okay for distribution'))
                                || (FunctionalRating.containsIgnoreCase('Bad') && p.Cosmetic_Rating__c == 'Bad' && (!FunctionallyRepairable.equalsIgnoreCase('Yes') ||
                                item.Testing_Priority_Rating__c < item.Review_status_priority_rating_threshold__c) && p.Probe_distribution__c != null && p.Probe_distribution__c.equalsIgnoreCase('Not okay for distribution'))
                                || (FunctionalRating.containsIgnoreCase('Bad') && (!FunctionallyRepairable.equalsIgnoreCase('Yes') ||
                                item.Testing_Priority_Rating__c < item.Review_status_priority_rating_threshold__c) && (FunctionalNotes.containsIgnoreCase('I:Dark shadow(s) - middle 80%') ||
                                FunctionalNotes.containsIgnoreCase('I:poor penetration') || FunctionalNotes.containsIgnoreCase('I:double image') ||
                                FunctionalNotes.containsIgnoreCase('I:fuzzy')))
                                || (FunctionalRating.containsIgnoreCase('Bad') && (!FunctionallyRepairable.equalsIgnoreCase('Yes') || item.Testing_Priority_Rating__c <
                                item.Review_status_priority_rating_threshold__c) && p.Probe_distribution__c != null && p.Probe_distribution__c.equalsIgnoreCase('Not okay for distribution') &&
                                (FunctionalNotes.containsIgnoreCase('Exists:major at SR (under low stress)') ||
                                        FunctionalNotes.containsIgnoreCase('Exists:major at 6"+ below SR (under low stress)') || FunctionalNotes.containsIgnoreCase('Automatic'))))) {
                            ReviewStatus = 'Liquidate';
                        }
                        // This was used as a catch all but ended up putting too many assets in the liquidate review status; may still need it, just modified
                        /*if(ReviewStatus != 'Repair Queue' && ReviewStatus != 'Cosmetic Repair Queue' && p.Probe_distribution__c.equalsignorecase('Not okay for distribution')){
                            ReviewStatus = 'Liquidate';
                        }*/
                        System.debug('REVIEW STATUS AFTER L: ' + ReviewStatus);
                        if (item.Always_Save_for_Parts__c == true
                                && ((FunctionalRating.containsIgnoreCase('Good') && p.Cosmetic_Rating__c == 'Bad' && item.Cosmetically_unable_to_Improve__c == true)
                                || ((!FunctionallyRepairable.equalsIgnoreCase('Yes') || item.Testing_Priority_Rating__c < item.Review_status_priority_rating_threshold__c)
                                && (FunctionalRating.containsIgnoreCase('Fair') || FunctionalRating.containsIgnoreCase('Bad'))))) {
                            ReviewStatus = 'Harvest';
                        }
                        
                         if(FunctionalNotes.containsIgnoreCase('Too damaged to test')){
                            ReviewStatus = 'Repair Queue';
                        }

                        if ((FunctionalNotes.containsIgnoreCase('A:System not available') || FunctionalNotes.containsIgnoreCase('I:System not available')) && FunctionalNotes.containsIgnoreCase('FC:First Call not available')) {
                            ReviewStatus = 'No Functional Test Available';
                        }
                        if (item.Probe_Type__c == 'Pencil' && FunctionalNotes.containsIgnoreCase('CWA:System not available')) {
                            ReviewStatus = 'No Functional Test Available';
                        }
                    }
                    if(item.Product_Family__c.contains('Probe') || item.Product_Family__c.contains('Part')){
                        System.debug('THIS IS THE REVIEW STATUS AFTER H: ' + ReviewStatus);
                        if(item.Product_Family__c.contains('Part')){
                            ReviewStatus = review_status;
                            System.debug('THIS IS THE REVIEW STATUS FOR PARTS: ' + ReviewStatus);
                        }
                        String OldReview = item.Review_Status__c;
                        System.debug('THIS IS THE OLD REVIEW >>> ' + OldReview + ' AND THIS IS THE NEW >>>> ' + ReviewStatus);
                        String username = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();

						// only update review status for non-TEE probes that aren't customer/warranty repairs; also only if review status is different from current review status
                        if (item.Review_Status__c != ReviewStatus && p.RecordTypeId != preShipRecordType.Id
                                && item.Check_In_Type__c != 'Customer Repair' && item.Check_In_Type__c != 'Generic' && item.Check_In_Type__c != 'Warranty Repair'
                                && item.Probe_Type__c != 'Transesophageal' && (item.Product_Family__c.contains('Probe') || item.Product_Family__c.contains('Part'))) {


                            Review_Status__c RS = new Review_Status__c(ProductItem__c = item.Id, Old_Review_Status__c = OldReview, New_Review_Status__c = ReviewStatus,
                                    Completed_By__c = username, Notes__c = 'Changed automatically through Product Test Evaluation');
                            Validator_Class.SetByPassReviewTrigger(true);
                            DatabaseService.insertRecord(RS);
                            item.Review_Status__c = ReviewStatus;
                            item.Last_Review_Status_Update__c = Date.today();
                            item.date_review_status_completed__c = Date.today();
                            item.Review_Status_Notes__c = RS.Notes__c + ' ' + String.valueOf(Date.today()) + '; ';
                            item.Most_Recent_Review_Status_Notes__c = RS.Notes__c;
                            Validator_Class.SetByPassReviewTrigger(false);

                        }
                    } // end if Ultrasound

					// insert new repairs if not customer repair based on what repairs are needed (and possible) from the product test
                    if (Trigger.isInsert) {

                        item.Latest_Test_Verified_Numbers_Match__c = p.Verified_Asset_and_Serial_Numbers_Match__c;

                        if (item.Check_In_Type__c != 'Generic' && item.Check_In_Type__c != 'Customer Repair') {

                            String newlocation = '';

							// New location currently not being used; may be used in the future to help sort; currently use work orders
                            if (p.Possible_Cosmetic_Repairs__c != null && !p.Product_Family__c.contains('Part')) {
                                newlocation = 'Repair Area - Cosmetic';
                            }

                            if (p.Possible_Functional_Repairs__c != null && !p.Product_Family__c.contains('Part')) {
                                newlocation = 'Repair Area - Electrical';
                            }


                            // JMAY: added this check since if WOCheck is TRUE, we don't insert the Product_Repairs
                            // so no sense doing all the work
                            if (!WOcheck) {

                                List<Product_Repair__c> repairsToInsert = new List<Product_Repair__c>();

                                List<String> lstOfOrders = new List<String>();

                                if (p.Order_of_Repairs__c != null) {
                                    lstOfOrders = p.Order_of_Repairs__c.split(';');
                                }
                                if(p.Product_Family__c.contains('Part')){
                                    if(p.Possible_Functional_Repairs__c != null){
                                        lstofOrders.addall(p.Possible_Functional_Repairs__c.split('\n'));
                                    }
                                    
                                    if(p.Possible_Cosmetic_Repairs__c != null){
                                        lstofOrders.addall(p.Possible_Cosmetic_Repairs__c.split('\n'));
                                    }
                                }

                                System.debug('THIS IS THE ORDER >>>> ' + lstOfOrders);

                                for (String o : lstOfOrders) {
                                    System.debug('THIS IS THE O IN THE ORDER >>> ' + o);

                                    if (p.Possible_Cosmetic_Repairs__c != null) {
                                        List<String> cnewrepair1 = p.Possible_Cosmetic_Repairs__c.split('\n');
                                        Set<String> cnewrepair = new Set<String>();
                                        cnewrepair.addAll(cnewrepair1);

                                        System.debug('THIS IS THE FINAL CNEWREPAIR >>> ' + cnewrepair);

                                        if (o != '' && o != ' ' && cnewrepair.contains(o.trim())) {
                                            System.debug('THIS IS INSIDE CONTAINS O FOR COSMETIC >>> ' + o);

                                            Product_Repair__c pr = new Product_Repair__c();
                                            if (item.Probe_Type__c != 'Transesophageal') {
                                                pr.RecordTypeId = cosmeticRecordType.Id;
                                            } else {
                                                pr.RecordTypeId = cosmeticTEERecordType.Id;
                                            }
                                            if(item.Product_Family__c.contains('Part')){
                                                pr.RecordTypeId = PartsRecordType.id;
                                                pr.Type_of_repair__c = 'Cosmetic';
                                            }
                                            pr.Product_Item__c = p.Product_Item__c;
                                            pr.Date_Assigned__c = System.today();
                                            pr.Product_Repair_Name__c = o.trim();
                                            pr.Repair_Activity__c = o.trim();

                                            System.debug('THIS IS THE REVIEW STATUS INSIDE THE COSMETIC LOOP >>> ' + ReviewStatus);

                                            if (ReviewStatus != 'Finished Goods' && ReviewStatus != 'Special Offer' && item.Product_Family__c.contains('Probe')) {
                                                System.debug('THIS IS INSIDE FG AND SO');

                                                if ((ReviewStatus.equalsIgnoreCase('eBay') || ReviewStatus == 'Auction')
                                                        && (o == 'Cable Advanced Whitening' || o.contains('Refurbishment') || o.contains('Paint') || o.contains('Polish'))) {

                                                    repairsToInsert.add(pr);
                                                    System.debug('THIS IS INSIDE EBAY');

                                                } else if (ReviewStatus == 'Cosmetic Repair Queue' || ReviewStatus == 'Repair Queue') {
                                                    System.debug('THIS IS INSIDE CRQ');
                                                    repairsToInsert.add(pr);
                                                }
                                            }
                                           // Parts team didn't want repairs to be automated. Removed 08.14.22. NB
                                            /* if(item.Product_Family__c.contains('Part') && p.Cosmetic_Repair_Capability__c!= 'External'){
                                                repairstoInsert.add(pr);
                                            }*/
                                        }
                                    }

                                    if (p.Possible_Functional_Repairs__c != null) {

                                        List<String> fnewrepair1 = p.Possible_Functional_Repairs__c.split('\n');
                                        Set<String> fnewrepair = new Set<String>();
                                        fnewrepair.addAll(fnewrepair1);

                                        System.debug('THIS IS THE F NEW REPAIR IN TEST NAME TRIGGER >>> ' + fnewrepair);
										System.debug('This is the o inside functional >> ' + o + ' and this is o.trim >>> ' + o.trim() + ' AND this is logic >>> ' + fnewrepair.contains(o.trim()));
                                        if (o != '' && o != ' ' && fnewrepair.contains(o.trim())) {

                                            System.debug('THIS IS INSIDE CONTAINS O FOR FUNCTIONAL >>> ' + o);
                                            System.debug('Functional_Rating: ' + p.Functional_Rating__c);
                                            System.debug('Functionally_Repairable: ' + p.Functionally_Repairable__c);
                                            System.debug('ReviewStatus: ' + ReviewStatus);
											
                                            // Parts team didn't want repairs to be automated. Removed 08.14.22. NB
                                            if ((p.Functional_Rating__c != 'Good'
                                                    && p.Functionally_Repairable__c == 'Yes'
                                                    && ReviewStatus == 'Repair Queue' && item.Product_Family__c.contains('Probe')) || (item.Product_Family__c.contains('Endoscopy')) /*|| (item.Product_Family__c.contains('Part') && p.Functional_Repair_Capability__c != 'External')*/) {

                                                System.debug('THIS IS INSIDE RQ');

                                                Product_Repair__c pr = new Product_Repair__c();

                                                System.debug('THIS IS THE PROBE TYPE >>> ' + item.Probe_Type__c);

                                                if (item.Probe_Type__c == 'Transesophageal') {
                                                    pr.RecordTypeId = functionalTEERecordType.Id;
                                                 } else if (item.Probe_Type__c == 'Endoscopy - Flexible') {
                                                   pr.RecordTypeId = endoscopyFlexibleRecordType.Id;                                           
                                                 } else if (item.Probe_Type__c == 'Endoscopy - Rigid') {
                                                   pr.RecordTypeId = endoscopyRigidRecordType.Id;                                           
                                                 } else{
                                                                                                       
                                                    pr.RecordTypeId = functionalRecordType.Id;
                                                    
                                                }
                                               /*
												if(item.Product_Family__c.contains('Part')){
                                                	pr.RecordTypeId = PartsRecordType.id;
                                                	pr.Type_of_repair__c = 'Functional';
                                            	}*/
                                                pr.Product_Item__c = p.Product_Item__c;
                                                pr.Date_Assigned__c = System.today();
                                                pr.Product_Repair_Name__c = o.trim();
                                                pr.Repair_Activity__c = o.trim();
                                                System.debug('THIS IS SUPPOSED TO BE THE REVIEW STATUS >>>> ' + ReviewStatus);
												
                                                repairsToInsert.add(pr);
                                            }
                                        }
                                    }
                                }

                                System.debug('Have this many ProductRepairs to Insert >>>> ' + repairsToInsert.size());

                                if (!repairsToInsert.isEmpty()) {
                                    repairsToUpsert.addAll(repairsToInsert);
                                    item.Repair_Status__c = 'Unassigned';
                                }

                            } else {
                                System.debug('Skipping Order processing and ProductRepair Insert since WOCheck is TRUE');
                            }


                            item.Needs_to_be_moved_to_this_location__c = newlocation;
                        }
                    }

					// Updates asset page from information on product test page
                    item.Estimated_Lead_Time__c = leadtime;
                    item.Estimated_Repair_Time__c = repairtime;
                    item.Date_Last_Test_Completed__c = p.CreatedDate;
                    if(p.Final_QC_Test_Date__c != null){
                        item.Date_Last_Test_Completed__c = p.Final_QC_Test_Date__c;
                    }
                    item.Cosmetic_Rating__c = p.Cosmetic_Rating__c;
                    if(p.Final_QC_Cosmetic_Rating__c != null){
                        item.Cosmetic_Rating__c = p.Final_QC_Cosmetic_Rating__c;
                    }
                    item.Functional_Rating__c = p.Functional_Rating__c;
                    if(p.Final_QC_Functional_Rating__c != null){
                        item.Functional_Rating__c = p.Final_QC_Functional_Rating__c;
                    }
                    item.Cosmetically_Repairable__c = p.Cosmetically_Repairable__c;
                    item.Functionally_Repairable__c = p.Functionally_Repairable__c;
					item.System_Options__c = p.System_Options_Calculations__c;
                    item.System_Software__c = p.System_Software__c;
                    item.D_System_Test__c = p.D_System_Test__c;
                    item.Required_Repairs__c = p.Required_Repairs__c;
                    item.Recommended_Repairs__c = p.Recommended_Repairs__c;
                    item.Required_Cost__c = p.Required_Cost__c;
                    item.Full_Cost__c = p.Full_Cost__c;
                    item.Avg_sensitivity_latest_test__c = p.First_Call_Avg_Sensitivity__c;
                    item.Avg_capacitance_latest_test__c = p.First_Call_Avg_Capacitance__c;

                    switch on (Integer) p.First_Call_Rating__c {

                        when 3 {
                            item.First_Call_Rating__c = 'Bad';
                        }

                        when 2 {
                            item.First_Call_Rating__c = 'Fair';
                        }

                        when 1 {
                            item.First_Call_Rating__c = 'Good';
                        }

                        when 0 {
                            item.First_Call_Rating__c = 'N/A';
                        }
                    }

                    item.Cosmetic_Notes__c = p.Cosmetic_Evaluation__c != null ? p.Cosmetic_Evaluation__c : '';

                    item.Functional_Notes__c = p.Functional_Evaluation__c != null ? p.Functional_Evaluation__c : '';

					// Other notes combines issues with cosmetic test and other cosmetic notes field
                    if (p.Other_Notes_Cosmetic__c != null) {
                        item.Cosmetic_Notes__c = (p.Cosmetic_Evaluation__c != null ? p.Cosmetic_Evaluation__c : '') + 'Other Notes: ' + p.Other_Notes_Cosmetic__c;
                    }

					// Other notes combines issues with functional test and other functional notes field
                    if (p.Other_Notes_Functional__c != null) {
                        item.Functional_Notes__c = (p.Functional_Evaluation__c != null ? p.Functional_Evaluation__c : '') + 'Other Notes: ' + p.Other_Notes_Functional__c;
                    }
                    
                    if(p.Endoscopy_Repair_Notes__c != null){
                        item.Functional_Notes__c = (p.Functional_Evaluation__c != null ? p.Functional_Evaluation__c : '') + 'Repair Notes: ' + p.Endoscopy_Repair_Notes__c;
                    }
                    item.New_Repair_Evaluation__c = p.New_Repair_Evaluation__c;
                    item.Outsource__c = p.Outsource__c;
                    item.Possible_Cosmetic_Repairs__c = p.Possible_Cosmetic_Repairs__c;
                    item.Possible_Functional_Repairs__c = p.Possible_Functional_Repairs__c;
                    item.These_Repairs_Cannot_Be_Done__c = p.These_Repairs_Cannot_Be_Done__c;
                    item.Cable_Length__c = p.Cable_Length__c;
                    item.Latest_Test_Verified_Numbers_Match__c = p.Verified_Asset_and_Serial_Numbers_Match__c;
                    item.Probe_distribution__c = p.Probe_distribution__c;

                    if (testlist.size() == 1) {
                        item.Initial_Cosmetic_Rating__c = p.Cosmetic_Rating__c;
                        item.Initial_Functional_Rating__c = p.Functional_Rating__c;
                        item.Initial_Date_Tested__c = p.CreatedDate;
                    }

                    pItemsToUpdate.add(item);


					// Update RMA with test information to be used for the eval
                    List<RMA__c> allAssociatedRMAs = new List<RMA__c>();

                    if (pItemIDToRMAList.containsKey(item.Id)) {
                        allAssociatedRMAs = pItemIDToRMAList.get(item.Id);
                    }

                    if (!allAssociatedRMAs.isEmpty()) {

                        RMA__c AssociatedRMA = allAssociatedRMAs[0];
                        System.debug('Only using the most recently modified RMA: ' + AssociatedRMA);
                        AssociatedRMA.Date_Last_Test_Completed__c = p.CreatedDate;
                        if(p.Final_QC_Test_Date__c != null){
                            AssociatedRMA.Date_Last_Test_Completed__c = p.Final_QC_Test_Date__c;
                        }
                        AssociatedRMA.Airscan__c = p.Functional_Airscan__c;
                        AssociatedRMA.Articulation__c = p.Functional_Articulation__c;
                        AssociatedRMA.Bending_Rubber__c = p.Cosmetic_Bending_rubber__c;
                        AssociatedRMA.Cable_Jacket__c = p.Cosmetic_Cable_jacket__c;
                        AssociatedRMA.Cap__c = p.Cosmetic_Cap__c;
                        AssociatedRMA.Cause_of_Damage__c = p.Cause_of_Damage__c; // added by Jay H 4/30/24

                        String compString = '';
                        if (p.Functional_Color_artifacts__c != null) {
                            compString += p.Functional_Color_artifacts__c;
                        }

                        if (p.Functional_Color_artifacts__c != p.Functional_Color_Artifacts_High_Stress__c && p.Functional_Color_Artifacts_High_Stress__c != null) {
                            compString += ';' + p.Functional_Color_Artifacts_High_Stress__c + ' (under high stress)';
                            if(compString.contains('no problem')){
                            	compString = compString.remove('no problem');
                        	}
                        }

                        if (p.Functional_Color_artifacts__c != p.Functional_Color_Artifacts_Low_Stress__c && p.Functional_Color_Artifacts_Low_Stress__c != null) {
                            compString += ';' + p.Functional_Color_Artifacts_Low_Stress__c + ' (under low stress)';
                            if(compString.contains('no problem')){
                            	compString = compString.remove('no problem');
                        	}
                        }

                        compString = compString.removeStart(';');
                        
                        AssociatedRMA.Color_Artifacts__c = compString;

                        AssociatedRMA.Connector__c = p.Cosmetic_Connector__c;
                        AssociatedRMA.Control_Housing__c = p.Cosmetic_Control_Housing__c;

                        compString = '';
                        if (p.Functional_CW_artifacts__c != null) {
                            compString += p.Functional_CW_artifacts__c;
                        }

                        if (p.Functional_CW_artifacts__c != p.Functional_CW_Artifacts_High_Stress__c && p.Functional_CW_Artifacts_High_Stress__c != null) {
                            compString += ';' + p.Functional_CW_Artifacts_High_Stress__c + ' (under high stress)';
                            if(compString.contains('no problem')){
                            	compString = compString.remove('no problem');
                        	}
                        }

                        if (p.Functional_CW_artifacts__c != p.Functional_CW_Artifacts_Low_Stress__c && p.Functional_CW_Artifacts_Low_Stress__c != null) {
                            compString += ';' + p.Functional_CW_Artifacts_Low_Stress__c + ' (under low stress)';
                            if(compString.contains('no problem')){
                            	compString = compString.remove('no problem');
                        	}
                        }

                        compString = compString.removeStart(';');
                        
                        AssociatedRMA.CW_Artifacts__c = compString;

                        AssociatedRMA.CW_Pulse__c = p.Functional_CW_Pulse__c;
                        AssociatedRMA.First_Call__c = p.Functional_First_Call__c;

                        if (p.Functional_First_Call__c != p.Functional_First_Call_Sensitivity__c && p.Functional_First_Call_Sensitivity__c != null) {
                            String FirstCall = p.Functional_First_Call__c + ';' + p.Functional_First_Call_Sensitivity__c;
                            FirstCall = FirstCall.removeStart(';');
                            AssociatedRMA.First_Call__c = FirstCall.left(255);
                        }

                        AssociatedRMA.Image__c = p.Functional_Image__c;

                        AssociatedRMA.Insertion_Tube__c = p.Cosmetic_Insertion_tube__c;

                        AssociatedRMA.Interior__c = p.Functional_Interior__c;
                        AssociatedRMA.Leakage_Current__c = p.Functional_Leakage_current__c;
                        AssociatedRMA.Lens__c = p.Cosmetic_Lens__c;
                        AssociatedRMA.Motor__c = p.Functional_Motor__c;
                        AssociatedRMA.Orientation__c = p.Functional_Orientation__c;
                        AssociatedRMA.Probe_Handle__c = p.Cosmetic_Probe_Handle__c;

                        compString = '';
                        if (p.Cosmetic_Strain_Relief__c != null) {
                            compString += p.Cosmetic_Strain_Relief__c;
                        }

                        if (p.Cosmetic_Strain_Relief_at_Connector__c == 'no problem'
                                && p.Cosmetic_Strain_Relief_at_Probe_Handle__c == 'no problem') {
                            compString += ';no problem';
                        } else {

                            if (p.Cosmetic_Strain_Relief_at_Connector__c != null) {
                                compString += ';' + p.Cosmetic_Strain_Relief_at_Connector__c + ' (at connector)';
                            }

                            if (p.Cosmetic_Strain_Relief_at_Probe_Handle__c != null) {
                                compString += ';' + p.Cosmetic_Strain_Relief_at_Probe_Handle__c + ' (at probe handle)';
                            }
                        }


                        compString = compString.removeStart(';');
                        AssociatedRMA.Strain_Relief__c = compString;
                        AssociatedRMA.Tip__c = p.Cosmetic_Tip__c;

                        AssociatedRMA.Required_Repairs__c = item.Required_Repairs__c;
                        AssociatedRMA.Recommended_Repairs__c = item.Recommended_Repairs__c;
                        AssociatedRMA.Required__c = item.Required_Cost__c;
                        AssociatedRMA.Full__c = item.Full_Cost__c;
                        AssociatedRMA.Diagnostics_Test__c = p.Diagnostics_Test__c;
                        AssociatedRMA.Diagnostics_Test_Notes__c = p.Diagnostics_Test_Notes__c;
                        if(p.Depot_Standard_System_Test__c == 'Depot System'){
                            AssociatedRMA.Depot_Repair__c = true;
                        }

                        compString = '';
                        if (p.Possible_Cosmetic_Repairs__c != null) {
                            compString += p.Possible_Cosmetic_Repairs__c + '\n';
                        }

                        if (p.Possible_Functional_Repairs__c != null) {
                            compString += p.Possible_Functional_Repairs__c;
                        }

                        AssociatedRMA.Possible_Repairs__c = compString;

                        AssociatedRMA.These_Repairs_Cannot_Be_Done__c = p.These_Repairs_Cannot_Be_Done__c;
                        AssociatedRMA.Other_Notes_Cosmetic__c = p.Other_Notes_Cosmetic__c;
                        AssociatedRMA.Other_Notes_Functional__c = p.Other_Notes_Functional__c;
                        if(p.Endoscopy_Repair_Notes__c != null){
                        	AssociatedRMA.Other_Notes_Functional__c = p.Endoscopy_Repair_Notes__c;
                    	}
                        if(p.Repair_Level__c != null){
                            AssociatedRMA.Repair_Level__c = p.Repair_Level__c;
                        }
                        if(p.Rod_Lenses_to_Replace__c != null){
                            AssociatedRMA.Rod_Lenses_to_Replace__c = p.Rod_Lenses_to_Replace__c;
                        }
                        
                        if(p.Product_Family__c.contains('Endoscopy') || p.Product_Family__c.contains('Instrument Tray')){
                            AssociatedRMA.Endoscopy_Evaluation_Results__c = p.Functional_Evaluation__c;
                            AssociatedRMA.Received_With__c = String.valueof(p.Received_With__c);
                            AssociatedRMA.Cause_of_Damage__c = p.Cause_of_Damage__c;
                        }
                        system.debug('THIS IS UNREPAIRABLE >> ' + p.Unrepairable__c);
                        if(p.Unrepairable__c == true){
                            AssociatedRMA.Probe_Deemed_Unrepairable__c = true;
                        }
                        if(p.No_Problems_Found__c == true){
                            AssociatedRMA.No_Problems_Found__c = true;
                        }
                         
                        RMAsToUpdate.add(AssociatedRMA);
                    }

                } // end trigger loop

                System.debug('About to update this many WOs: ' + woToUpdate.size());
                if (!woToUpdate.isEmpty()) {
                    DatabaseService.updateList(woToUpdate);
                }

                System.debug('About to upsert this many ProductRepairs: ' + repairsToUpsert.size());
                if (!repairsToUpsert.isEmpty()) {
                    DatabaseService.upsertList(repairsToUpsert);
                }

                System.debug('About to update this many ProductItems: ' + pItemsToUpdate.size());
                if (!pItemsToUpdate.isEmpty()) {
                    system.debug('pItemsToUpdate#=' +pItemsToUpdate);
                    DatabaseService.updateList(pItemsToUpdate);
                }

                System.debug('About to update this many RMAs: ' + RMAsToUpdate.size());
                if (!RMAsToUpdate.isEmpty()) {
                    DatabaseService.updateList(RMAsToUpdate);
                }

// end of After
            }
        }
    }

    private List<ComplexStringWrapper> complexListSplitter(ProdTestInfoWrapper theProdTestWrapper, String cOrf, String theField, String theNotePrefix,
            String theLabel, List<String> safetyTerms, List<String> lensSafetyTerms, String noteEnding) {

        List<ComplexStringWrapper> retList = new List<ComplexStringWrapper>();
        List<String> VTDList = new List<String>{'light discoloration', 'heavy discoloration', 'Minor Scratches', 'Major Scratches / Scrapes', 'numbers faded - minor', 'numbers faded - major', 'bite marks - minor'};
        // no sense doing work if we have no place to store it
        if (thePItem != null) {

            List<String> fieldValues = theField.split(';');
            Integer ratenum = 0;
            String rep_ev = '';
            Boolean repair = true;
            Integer repair_na = 0;
            Boolean out = false;
            String notes = '';
            String repairs = '';
            Boolean bothratings = false;

            for (String thisTest : fieldValues) {

                if (lensSafetyTerms != null) {
                    for (String sfty : lensSafetyTerms) {
                        if (thisTest.containsIgnoreCase(sfty)) {
                            theProdTestWrapper.lenssafe = false;
                            break;
                        }
                    }
                }

                if (safetyTerms != null) {
                    for (String sfty : safetyTerms) {
                        if (thisTest.containsIgnoreCase(sfty)) {
                            theProdTestWrapper.safe = false;
                            break;
                        }
                    }
                }

                if (!thisTest.containsIgnoreCase('No problem') && thisTest != 'Repair' && thisTest != 'Replace') {
                    notes = notes + theNotePrefix + ':' + thisTest + (noteEnding != null ? noteEnding : '') + '; ';
                }

                for (ProductTestData__c ptdtemp : prodTestDataList) {
                    if (thisTest.equalsIgnoreCase(ptdtemp.Field_API_Value__c) && ptdtemp.Field_API_Name__c == theLabel) {
                        system.debug('This is the ptdtemp >>>>> ' + ptdtemp);
                        if (ratenum < rating.get(ptdtemp.rating__c)) {
                            ratenum = rating.get(ptdtemp.rating__c);
                        }
                        if (ptdtemp.repair_evaluation__c != null) {
                            system.debug('THIS IS THE PRODUCT NAME >>> ' + thePItem.Product_Name__r.Name);
                            system.debug('AND THIS IS THE TEST ISSUE >>> ' + thisTest);
                            if(thePItem.Product_Name__r.Name == 'GE 6VT-D' && VTDList.contains(thisTest)){
                                rep_ev = rep_ev + 'Recoat/Relabel;';
                                system.debug('THIS IS THE RMAP FOR RECOAT/RELABEL >>> ' + RMap.get('Recoat/Relabel'));
                                if (RMap.get('Recoat/Relabel') > 0) {
                                	repairs = repairs + 'Recoat/Relabel' + (';');
                            	} else {
                                	repair = false;
                            	}
                            }
                            else
                            {
                                rep_ev = rep_ev + ptdtemp.repair_evaluation__c.trim() + ';';
                                // TEMPORARY - adding in the OR for all endoscopy items to mark all repairs as possible without needing a price on product page
                                if (RMap.get(ptdtemp.repair_evaluation__c.trim()) > 0 || thePItem.Product_Family__c.contains('Endoscopy')) {
                                    repairs = repairs + ptdtemp.repair_evaluation__c.trim() + (';');
                                } else {
                                    repair = false;
                                }
                            }
                            
                            
                        } else if (ptdtemp.Repairable__c == 'No') {
                            repair = false;
                        }
                        system.debug('This is the repairable ptdtemp field >>> ' + ptdtemp.Repairable__c);
                        if (!ptdtemp.Repairable__c.containsIgnoreCase('N/A')) {
                            repair_na = repair_na + 1;
                            system.debug('This is the repair_na inside the loop >>>> ' + repair_na);
                        }

                        if (ptdtemp.Outsource__c == true) {
                            out = true;
                        }
                        if(ptdtemp.Ratings_to_Update__c == 'Both'){
                            bothratings = true;
                        }
                        break;
                    }
                }
            }

            if(bothratings == true){
                ComplexStringWrapper w1 = new ComplexStringWrapper('f', rating_reverse.get(ratenum), repair, repair_na, rep_ev, out, notes, repairs, thePItem.Probe_Type__c);
                ComplexStringWrapper w2 = new ComplexStringWrapper('c', rating_reverse.get(ratenum), repair, repair_na, rep_ev, out, notes, repairs, thePItem.Probe_Type__c);
                System.debug('String ITERATION: ' + w1 + w2);
                retList.add(w1);
                retList.add(w2);
            }
            if(bothratings == false){
                ComplexStringWrapper w = new ComplexStringWrapper(cOrf, rating_reverse.get(ratenum), repair, repair_na, rep_ev, out, notes, repairs, thePItem.Probe_Type__c);
                System.debug('String ITERATION: ' + w);
                retList.add(w);
            }

        }

        return retList;
    }

    public class ProdTestInfoWrapper {


        public List<ComplexStringWrapper> FinalList;
        public Boolean safe;
        public Boolean lenssafe;

        public ProdTestInfoWrapper() {
            safe = true;
            lenssafe = true;

            FinalList = new List<ComplexStringWrapper>();
        }
    }

    public class ComplexStringWrapper {

        public String c_rating { get; set; }
        public String f_rating { get; set; }
        public Boolean c_repairable { get; set; }
        public Boolean f_repairable { get; set; }
        public String repair_eval { get; set; }
        public Boolean outsource { get; set; }
        public Integer c_repairable_na { get; set; }
        public Integer f_repairable_na { get; set; }
        public String c_notes { get; set; }
        public String f_notes { get; set; }
        public String repairs { get; set; }
        public String image_rating { get; set; }
        public String FC_rating { get; set; }

        public ComplexStringWrapper(String cOrF, String rating, Boolean repairable, Integer repairable_na, String repairEval, Boolean doOutsource, String notes, String theRepairs, String probe_Type) {
            if (cOrF == 'c') {
                c_rating = rating;
                c_repairable = repairable;
                c_repairable_na = repairable_na;
                repair_eval = repairEval;
                outsource = doOutsource;
                c_notes = notes;
                repairs = theRepairs;
            } else {
                f_rating = rating;
                f_repairable = repairable;
                f_repairable_na = repairable_na;
                repair_eval = repairEval;
                outsource = doOutsource;
                f_notes = notes;
                repairs = theRepairs;
            }

            // A separate functional rating, called the First Call rating was used at one point to compare if the image results
            // lined up with the FC results. Currently not being used very often, but may be used more in the future.
            if (notes.contains('FC:') && probe_Type != 'Transesophageal') {
                FC_rating = rating;
                f_rating = 'N/A';
                if (notes.containsIgnoreCase('FC:No problem')) {
                    f_rating = 'Good';
                    f_notes = '';
                }
            }
        }
    }

}