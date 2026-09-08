@isTest(seeAllData=true)
private class WorkRequestController_Test {

    @isTest
    static void test_ControllerAndGetter() {
        
        
        Map<String, String> flexFieldMap = new Map<String, String>{
            'A/W Nozzle' => 'A_W_Nozzle__c',
            'A/W Channel' => 'A_W_Channel__c',
            'A/W Separator' => 'A_W_Separator__c',
            'A/W O-Rings' => 'A_W_O_Rings__c',
            'Auxiliary Channel' => 'Auxiliary_Channel__c',
            'Auxiliary Port' => 'Auxiliary_Port__c',
            'Angulation Adjust' => 'Angulation_Adjust__c',
            'Control Cables Up' => 'Control_Cable_Up__c',
            'Control Cables Down' => 'Control_Cable_Down__c',
            'Control Cables Left' => 'Control_Cable_Left__c',
            'Control Cables Right' => 'Control_Cable_Right__c',
            'Bending Sheath' => 'Bending_Sheath__c',
            'Bending Section' => 'Bending_Section__c',
            'Wire Mesh' => 'Wire_Mesh__c',
            'Biopsy Channel' => 'Biopsy_Channel__c',
            'CCD Chip Video Image' => 'CCD_Chip_Video_Image__c',
            'Flexibility Adjustment Mechanism' => 'Flexibility_Adjustment_Mechanism__c',
            'Distal Cap' => 'Distal_End_Cap__c',
            'Control Body' => 'Control_Body__c',
            'Control Knob Assembly' => 'Control_Knob_Assembly__c',
            'U/D Brake Assembly' => 'U_D_Brake_Assembly__c',
            'L/R Brake Assembly' => 'L_R_Brake_Assembly__c',
            'U/D Control Knob' => 'U_D_Control_Knob__c',
            'L/R Control Knob' => 'L_R_Control_Knob__c',
            'Elevator Cable' => 'Elevator_Cable__c',
            'Elevator Channel' => 'Elevator_Channel__c',
            'Elevator Lever' => 'Elevator_Lever__c',
            'ETO Valve' => 'ETO_Valve__c',
            'F/O Light Bundle' => 'F_O_Light_Bundle__c',
            'F/O Image Bundle' => 'F_O_Image_Bundle__c',
            'Alignment of Image' => 'Alignment_of_Image__c',
            'Auto-Bright' => 'Auto_Bright__c',
            'Endoscopy Insertion Tube' => 'Endoscopy_Insertion_Tube__c',
            'Light Guide Connector' => 'Light_Guide_Connector__c',
            'Light Guide Post Cap' => 'Light_Guide_Post_Cap__c',
            'Electrical Contacts' => 'Electrical_Contacts__c',
            'Light Guide Lens' => 'Light_Guide_Lens__c',
            'Objective Lens' => 'Objective_Lens__c',
            'Ocular' => 'Ocular__c',
            'Stress Relief Boot' => 'Stress_Relief_Boot__c',
            'Suction Channel' => 'Suction_Channel__c',
            'Suction Cylinder' => 'Suction_Cylinder__c',
            'Universal Cord' => 'Universal_Cord__c',
            'Switch #1' => 'Switch_1__c',
            'Video Switch Assembly' => 'Video_Switch_Assembly__c',
            'Video Connector' => 'Video_Connector__c',
            'Contamination' => 'Contamination__c',
            'Angulation System' => 'Angulation_System__c',
            'Internal Components' => 'Internal_Components__c'
        };
		String query = 'SELECT Id, Fluid_Damage__c, Final_QC_Test_Results__c, Adhesive_Damaged__c, Damage_by_Autoclave__c, RecordType.DeveloperName, Functional_Rating__c, Cosmetic_Rating__c, Automated_Repairs_Added__c';
        for (String field : flexFieldMap.values()) {
            query += ', ' + field;
        }          
        // Grab the most recently modified ProductTest__c
        query += ' FROM ProductTest__c ORDER BY LastModifiedDate DESC LIMIT 1';
        ProductTest__c product = Database.query(query);
        product.Automated_Repairs_Added__c = 'Bending Sheath Replacement; Distal End Cap Repair;';
        product.Bending_Sheath__c = 'Leaking; Repair;';
        update product;
        List<String> checkboxAreas = new List<String>{'Fluid Damage'};
        List<Product_Test_Line_Item__c> testItems = new List<Product_Test_Line_Item__c>();

        if (product.Id != null) {
            ApexPages.StandardController stdController = new ApexPages.StandardController(product);
			WorkRequestController controller = new WorkRequestController(stdController);
            
            Test.startTest();
            controller.getFilteredRows(flexFieldMap, checkboxAreas, product, testItems);
            Test.stopTest();
        }
    }
}