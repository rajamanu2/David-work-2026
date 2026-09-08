public with sharing class RigidWorkRequestController {
    public String recordId { get; set; }
    public List<Map<String, String>> filteredRows { get; set; }

    public RigidWorkRequestController(ApexPages.StandardController controller) {
        recordId = controller.getId();
        filteredRows = new List<Map<String, String>>();

        Map<String, String> fieldMap = new Map<String, String>{
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
        String query = 'SELECT Id, Fluid_Damage__c, Adhesive_Damaged__c, Damage_by_Autoclave__c';
        for (String field : fieldMap.values()) {
            query += ', ' + field;
        }
        query += ' FROM ProductTest__c WHERE Id = :recordId LIMIT 1';
        ProductTest__c product = Database.query(query);

        if (product.Fluid_Damage__c) checkboxAreas.add('Fluid Damage');
        if (product.Adhesive_Damaged__c) checkboxAreas.add('Adhesive Damaged');
        if (product.Damage_by_Autoclave__c) checkboxAreas.add('Damage by Autoclave');

        for (String area : fieldMap.keySet()) {
            String fieldName = fieldMap.get(area);
            Object rawVal = product.get(fieldName);

            String result = '';
            String action = '';

            if (area == 'Tube Length (in MM)' ||
                area == 'Rod Lenses to Replace' ||
                area == 'Achromats to Replace') {
                result = rawVal != null ? String.valueOf(rawVal).trim() : '';
                if (String.isNotBlank(result)) {
                    Map<String, String> row = new Map<String, String>{
                        'area' => area,
                        'action' => '',
                        'result' => result
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

                    if (String.isNotBlank(action)) {
                        Map<String, String> row = new Map<String, String>{
                            'area' => area,
                            'action' => action,
                            'result' => result
                        };
                        filteredRows.add(row);
                    }
                }
            }
        }

        // Add checkbox-based rows
        for (String checkboxArea : checkboxAreas) {
            Map<String, String> row = new Map<String, String>{
                'area' => checkboxArea,
                'action' => 'Check',
                'result' => ''
            };
            filteredRows.add(row);
        }
    }

    public List<Map<String, String>> getFilteredRows() {
        return filteredRows;
    }
}