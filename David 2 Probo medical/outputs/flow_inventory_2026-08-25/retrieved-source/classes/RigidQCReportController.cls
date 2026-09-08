public with sharing class RigidQCReportController {
    public String recordId { get; set; }
    public List<String> items { get; set; }
    public Map<String, String> inspectionResults { get; set; }
    public Map<String, String> actions { get; set; }
    public Map<String, Boolean> qcPassed { get; set; }

    public RigidQCReportController(ApexPages.StandardController controller) {
        recordId = controller.getId();

        items = new List<String>{
            'Objective Assembly', 'Distal Tip Window', 'Marker Plate', 'Tubing Condition', 'Light Fibers',
            'Rod Lenses', 'Tubing Laser Weld', 'Achromats', 'Video Coupler', 'Eyepiece',
            'Eyepiece Sleeve', 'Prism', 'Ocular', 'Tube Length (in MM)', 'Rod Lenses to Replace',
            'Achromats to Replace', 'Condenser Crystal', 'Image Bundle', 'Eyepiece Window'
        };

        inspectionResults = new Map<String, String>();
        actions = new Map<String, String>();
        qcPassed = new Map<String, Boolean>();

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
            'Tube Length (in MM)' => 'Tube_Length__c',
            'Rod Lenses to Replace' => 'Rod_Lenses_to_Replace__c',
            'Achromats to Replace' => 'Achromats_to_Replace__c',
            'Condenser Crystal' => 'Condenser_Crystal__c',
            'Image Bundle' => 'Image_Bundle__c',
            'Eyepiece Window' => 'Eyepiece_Window__c'
        };

        String soql = 'SELECT Id, Fluid_Damage__c, Adhesive_Damaged__c, Damage_by_Autoclave__c';
        for (String fieldApi : fieldMap.values()) {
            soql += ', ' + fieldApi;
        }
        soql += ' FROM ProductTest__c WHERE Id = :recordId LIMIT 1';
        ProductTest__c productTest = Database.query(soql);

        for (String item : items) {
        String fieldApi = fieldMap.get(item);
        if (fieldApi == null) {
            inspectionResults.put(item, '');
            actions.put(item, '');
            qcPassed.put(item, true);
            continue;
        }
    
        Object rawVal = productTest.get(fieldApi);
        String inspection = '';
        String action = '';

        if (rawVal instanceof String) {
            String rawValue = (String) rawVal;
            if (item == 'Tube Length (in MM)' || 
                item == 'Rod Lenses to Replace' || 
                item == 'Achromats to Replace') {
                inspection = rawValue;
            } else {
                List<String> selected = rawValue != null ? rawValue.split(';') : new List<String>();
                List<String> findings = new List<String>();
                for (String val : selected) {
                    val = val.trim();
                    if (val.equalsIgnoreCase('Repair') || val.equalsIgnoreCase('Replace')) {
                        action = val;
                    } else {
                        findings.add(val);
                    }
                }
                inspection = String.join(findings, ', ');
            }
        } else if (rawVal != null) {
            inspection = String.valueOf(rawVal);
        }
    
        inspectionResults.put(item, inspection);
        actions.put(item, action);
        qcPassed.put(item, true);
    }


        if (productTest.Fluid_Damage__c) {
            items.add('Fluid Damage');
            inspectionResults.put('Fluid Damage', '');
            actions.put('Fluid Damage', 'Check');
            qcPassed.put('Fluid Damage', true);
        }

        if (productTest.Adhesive_Damaged__c) {
            items.add('Adhesive Damaged');
            inspectionResults.put('Adhesive Damaged', '');
            actions.put('Adhesive Damaged', 'Check');
            qcPassed.put('Adhesive Damaged', true);
        }

        if (productTest.Damage_by_Autoclave__c) {
            items.add('Damage by Autoclave');
            inspectionResults.put('Damage by Autoclave', '');
            actions.put('Damage by Autoclave', 'Check');
            qcPassed.put('Damage by Autoclave', true);
        }
    }

    public List<String> getItems() {
        return items;
    }

    public Map<String, String> getInspectionResults() {
        return inspectionResults;
    }

    public Map<String, String> getActions() {
        return actions;
    }

    public Map<String, Boolean> getQcPassed() {
        return qcPassed;
    }
}