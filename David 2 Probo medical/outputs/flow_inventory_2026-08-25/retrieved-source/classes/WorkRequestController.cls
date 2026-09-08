public with sharing class WorkRequestController {
    public String recordId { get; set; }
    public Boolean endoscopyStandard { get; set; }
    public Boolean endoscopyOther { get; set; }
    public List<Map<String, String>> filteredRows { get; set; }
    
    private List<Product_Test_Line_Item__c> getTestItems(Id productTestId) {
        List<Product_Test_Line_Item__c> productTestItems = [SELECT Id, Quantity__c, Item_Description__c, ProductTest__c, Complaint__c, Repair_Technician__c, Repairs_Needed__c, Repair_Price__c
                                                           FROM Product_Test_Line_Item__c WHERE ProductTest__c = :productTestId ORDER BY CreatedDate ASC];
        
        return productTestItems;
    }

    public WorkRequestController(ApexPages.StandardController controller) {
        recordId = controller.getId();
        system.debug('THIS IS THE RECORD ID >> ' + recordId);
        endoscopyStandard = false;
        endoscopyOther = true;
        filteredRows = new List<Map<String, String>>();

        // Define inspection area to field API mapping
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
            
        Map<String, String> rigidFieldMap = new Map<String, String>{
            'Objective Assembly' => 'Objective_Assembly__c',
            'Distal Tip Window' => 'Distal_Tip_Window__c',
            'Marker Plate' => 'Marker_Plate__c',
            'Tubing Condition' => 'Tubing_Condition__c',
            'Light Fibers' => 'Light_Fibers__c',
            'Rod Lenses' => 'Rod_Lenses__c',
            'Tubing Laser Weld' => 'Tubing_Laser_Weld__c',
            'Achromats' => 'Achromats__c',
            'Video Coupler' => 'Video_Coupler__c',
            'Eyepiece' => 'Eyepiece__c',
            'Eyepiece Sleeve' => 'Eyepiece_Sleeve__c',
            'Prism' => 'Prism__c',
            'Ocular' => 'Ocular__c',
            'Condenser Crystal' => 'Condenser_Crystal__c',
            'Image Bundle' => 'Image_Bundle__c',
            'Eyepiece Window' => 'Eyepiece_Window__c',
            'Tube Length (in MM)' => 'Tube_Length__c',
            'Rod Lenses to Replace' => 'Rod_Lenses_to_Replace__c',
            'Achromats to Replace' => 'Achromats_to_Replace__c'
        };

        // Add checkbox fields manually if checked
        List<String> checkboxAreas = new List<String>();
        // for misc endoscopy parts -not flex or rigid scopes
        List<Product_Test_Line_Item__c> testItems = new List<Product_Test_Line_Item__c>();
        String query = 'SELECT Id, Automated_Repairs_Added__c, Final_QC_Test_Results__c, Fiber_Optic_Before_Image__c, Fluid_Damage__c, Adhesive_Damaged__c, Damage_by_Autoclave__c, RecordType.DeveloperName, Functional_Rating__c, Cosmetic_Rating__c';
        // prevents duplicate fields from being added if both rigid and flexible have same field
        Set<String> endoscopyFields = new Set<String>(flexFieldMap.values());
        endoscopyFields.addAll(rigidFieldMap.values());
        for (String field : endoscopyFields) {
            query += ', ' + field;
        }
        
        query += ' FROM ProductTest__c WHERE Id = :recordId LIMIT 1';
        ProductTest__c product = Database.query(query);
        if (product.Fluid_Damage__c) checkboxAreas.add('Fluid Damage');
        if (product.Adhesive_Damaged__c) checkboxAreas.add('Adhesive Damaged');
        if (product.Damage_by_Autoclave__c) checkboxAreas.add('Damage by Autoclave');
       // if (product.Fiber_Optic_Before_Image__c) checkboxAreas.add('Fiber Optic Before Image');

        // Process fields
        // for flexible endoscope
        if(product.RecordType.DeveloperName.contains('Flexible')){
            getFilteredRows(flexFieldMap, checkboxAreas, product, testItems);
            endoscopyStandard = true;
            endoscopyOther = false;
        }
        
        // for rigid endoscope
        else if(product.RecordType.DeveloperName.contains('Rigid')){
            getFilteredRows(rigidFieldMap, checkboxAreas, product, testItems);
            endoscopyStandard = true;
            endoscopyOther = false;
        }
        
        //for "other" endoscopy items
        else{
            testItems = getTestItems(recordId);
            getFilteredRows(rigidFieldMap, checkboxAreas, product, testItems);
            
        }
        

    }
    
    
	
    public List<Map<String, String>> getFilteredRows(Map<String, String> fieldMap, List<String> checkboxAreas, ProductTest__c product, List<Product_Test_Line_Item__c> testItems) {
        String qcPassed = '';
        Set<String> addedRepairs = new Set<String>();
        Set<String> addedRepairsAreas = new Set<String>();
        if(product.Automated_Repairs_Added__c != null){
            String area = '';
            for(string repair:product.Automated_Repairs_Added__c.split(';')){
                addedRepairs.add(repair);
                if(repair.contains('Repair')){
                    area = repair.substringBefore('Repair');
                    area = area.trim();
                    addedRepairsAreas.add(area);
                }
                if(repair.contains('Replacement')){
                    area = repair.substringBefore('Replacement');
                    area = area.trim();
                    addedRepairsAreas.add(area);
                }
            }
            
        }
        if(product.Functional_Rating__c != null && product.Functional_Rating__c.contains('Good') && product.Cosmetic_Rating__c != null && product.Cosmetic_Rating__c.contains('Good')){
            qcPassed = 'Yes';
        }
        if(product.Final_QC_Test_Results__c == 'Passed'){
            qcPassed = 'Yes';
        }
        if(product.Final_QC_Test_Results__c == 'Failed'){
            qcPassed = 'No';
        }
        
        if(fieldMap.size() != 0 && testItems.size() == 0){
        for (String area : fieldMap.keySet()) {
            
            String fieldName = fieldMap.get(area);
            Object rawVal = product.get(fieldName);

            String result = '';
            String action = '';
            

            if (area == 'Tube Length (in MM)' ||
                area == 'Rod Lenses to Replace' ||
                area == 'Achromats to Replace') {
                result = rawVal != null ? String.valueOf(rawVal).trim() : '';
                    if(area.contains('Replace')){
                        action = 'Replace';
                    }
                if (String.isNotBlank(result)) {
                    Map<String, String> row = new Map<String, String>{
                        'area' => area,
                        'action' => action,
                        'result' => result,
                        'qc' => qcPassed  
                    };
                    filteredRows.add(row);
                }
                continue;
            }

	
            if (rawVal != null && rawVal instanceof String) {
                
                String value = (String) rawVal;
                
                if (String.isNotBlank(value)) {
                    
                    List<String> selections = value.split(';');
                    for (String entry : selections) {
                        entry = entry.trim();
                        if (entry.equalsIgnoreCase('Repair') || entry.equalsIgnoreCase('Replace')) {
                            action = entry;
                        } else {
                            result = result == '' ? entry : result + ', ' + entry;
                        }
                        
                    }
                    if(addedRepairsAreas.contains(area)){
                        if(value.contains('Repair') && addedRepairs.contains(area + ' Replacement')){
                            action = 'Replace';
                            if(result == null || result == ''){
                                result = 'Automatically changed from repair to replace';
                            }
                            else{
                                result += '; automatically changed from repair to replace';
                            }
                            addedRepairs.remove(area + ' Replacement');
                            
                        }
                        if(value.contains('Replace') && addedRepairs.contains(area + ' Repair')){
                            addedRepairs.remove(area + ' Repair');
                        }
                	}
                    if(area.contains('Contamination') && !value.contains('No Problem')){
                		action = 'Remove';
            		}	
					Map<String, String> row = new Map<String, String>{
                            'area' => area,
                            'action' => action,
                            'result' => result,
                            'qc' => qcPassed
                    };
                    filteredRows.add(row);
                    
                }
            }
        }
        }
        if(addedRepairs != null){
            String area = '';
            String action = '';
            for(string repair:addedRepairs){
                if(repair.contains('Repair')){
                    area = repair.substringBefore('Repair');
                    area = area.trim();
                    action = 'Repair';
                }
                if(repair.contains('Replacement')){
                    area = repair.substringBefore('Replacement');
                    area = area.trim();
                    action = 'Replace';
                }
                Map<String, String> row = new Map<String, String>{
                    'area' => area,
                    'action' => action,
                    'result' => 'automatically added',
                    'qc' => qcPassed
                        
                };
                
                filteredRows.add(row);
            }
        }
        if(checkboxAreas.size() != 0){
            for (String checkboxArea : checkboxAreas) {
                String action = 'Check';
                if(checkboxArea.contains('Fluid')){
                    action = 'Remove';
                }
                if(checkboxArea.contains('Adhesive')){
                    action = 'Replace';
                }
                Map<String, String> row = new Map<String, String>{
                    'area' => checkboxArea,
                    'action' => action,
                    'result' => 'Damaged',
                    'qc' => qcPassed
                        
                };
                filteredRows.add(row);
            }   
        }
        if(testItems.size() != 0){
           
            for (Product_Test_Line_Item__c lineItem: testItems) {
                String complaint = 'Complaint not listed';
                String result = '';
            	String action = '';
                if(lineItem.Repairs_Needed__c != null){
                    complaint = 'Repair as needed';
                }
                
                Map<String, String> row = new Map<String, String>{
                    'qty' => (lineItem.Quantity__c == null) ? ' ' : String.valueof(lineItem.Quantity__c),
                    'area' => lineItem.Item_Description__c ?? ' ',
                    'action' => lineItem.Complaint__c ?? complaint,
                    'result' => lineItem.Repairs_Needed__c ?? ' ',
                    'qc' => 'Yes' // eventually use QCPassed once system set up to automate
                        
                };
                filteredRows.add(row);
            }
            
        }
        
        return filteredRows;
    }
}