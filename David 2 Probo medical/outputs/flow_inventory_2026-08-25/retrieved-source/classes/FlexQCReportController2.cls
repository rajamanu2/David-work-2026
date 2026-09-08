public with sharing class FlexQCReportController2 {
    public String recordId { get; set; }
    public List<String> items { get; set; }
    public Map<String, String> inspectionResults { get; set; }
    public Map<String, String> actions { get; set; }
    public Map<String, Boolean> qcPassed { get; set; }

    public FlexQCReportController2(ApexPages.StandardController controller) {
        recordId = controller.getId();

        items = new List<String>{
            'A/W Nozzle', 'A/W Channel', 'A/W Separator', 'A/W O-rings', 'Aux. Valve',
            'Angulation Adjust Up, Down, Left and Right', 'Control Cables Up', 'Control Cables Down',
            'Control Cables Left', 'Control Cables Right', 'Bending Sheath', 'Bending Section',
            'Wire Mesh', 'Biopsy Channel', 'CCD Video Chip', 'Flex. Adjustment', 'Distal Cap',
            'Control Body', 'Control Knob Assy.', 'U/D Brake', 'L/R Brake', 'U/D Knob', 'L/R Knob',
            'Elevator Cable', 'Elevator Channel', 'Elevator Lever', 'ETO Valve',
            'F.O. Light Bundle', 'Alignment', 'Auto Bright', 'Insertion Tube', 'Light Guide Connector',
            'Light Guide Post Cap', 'Electrical Contacts', 'Light Guide Lens', 'Objective Lens',
            'Stress Relief Boot', 'Suction Channel', 'Suction Cylinder',
            'Universal Cord', 'Switch #1', 'Video Switch Assy.', 'Video Connector',
            'Contamination Bending Sec./Distal', 'Angulation System', 'Internal Components'
        };

        inspectionResults = new Map<String, String>();
        actions = new Map<String, String>();
        qcPassed = new Map<String, Boolean>();

        Map<String, String> fieldMap = new Map<String, String>{
            'A/W Nozzle' => 'A_W_Nozzle__c',
            'A/W Channel' => 'A_W_Channel__c',
            'A/W Separator' => 'A_W_Separator__c',
            'A/W O-rings' => 'A_W_O_Rings__c',
            'Aux. Valve' => 'Auxiliary_Channel__c',
            'Angulation Adjust Up, Down, Left and Right' => 'Angulation_Adjust__c',
            'Control Cables Up' => 'Control_Cable_Up__c',
            'Control Cables Down' => 'Control_Cable_Down__c',
            'Control Cables Left' => 'Control_Cable_Left__c',
            'Control Cables Right' => 'Control_Cable_Right__c',
            'Bending Sheath' => 'Bending_Sheath__c',
            'Bending Section' => 'Bending_Section__c',
            'Wire Mesh' => 'Wire_Mesh__c',
            'Biopsy Channel' => 'Biopsy_Channel__c',
            'CCD Video Chip' => 'CCD_Chip_Video_Image__c',
            'Flex. Adjustment' => 'Flexibility_Adjustment_Mechanism__c',
            'Distal Cap' => 'Distal_End_Cap__c',
            'Control Body' => 'Control_Body__c',
            'Control Knob Assy.' => 'Control_Knob_Assembly__c',
            'U/D Brake' => 'U_D_Brake_Assembly__c',
            'L/R Brake' => 'L_R_Brake_Assembly__c',
            'U/D Knob' => 'U_D_Control_Knob__c',
            'L/R Knob' => 'L_R_Control_Knob__c',
            'Elevator Cable' => 'Elevator_Cable__c',
            'Elevator Channel' => 'Elevator_Channel__c',
            'Elevator Lever' => 'Elevator_Lever__c',
            'ETO Valve' => 'ETO_Valve__c',
            'F.O. Light Bundle' => 'F_O_Light_Bundle__c',
            'Alignment' => 'Alignment_of_Image__c',
            'Auto Bright' => 'Auto_Bright__c',
            'Insertion Tube' => 'Endoscopy_Insertion_Tube__c',
            'Light Guide Connector' => 'Light_Guide_Connector__c',
            'Light Guide Post Cap' => 'Light_Guide_Post_Cap__c',
            'Electrical Contacts' => 'Electrical_Contacts__c',
            'Light Guide Lens' => 'Light_Guide_Lens__c',
            'Objective Lens' => 'Objective_Lens__c',
            'Stress Relief Boot' => 'Stress_Relief_Boot__c',
            'Suction Channel' => 'Suction_Channel__c',
            'Suction Cylinder' => 'Suction_Cylinder__c',
            'Universal Cord' => 'Universal_Cord__c',
            'Switch #1' => 'Switch_1__c',
            'Video Switch Assy.' => 'Video_Switch_Assembly__c',
            'Video Connector' => 'Video_Connector__c',
            'Contamination Bending Sec./Distal' => 'Contamination__c',
            'Angulation System' => 'Angulation_System__c',
            'Internal Components' => 'Internal_Components__c'
        };

        String soql = 'SELECT Id, Install_Boot_Extender__c';
        for (String fieldApi : fieldMap.values()) {
            soql += ', ' + fieldApi;
        }
        soql += ' FROM ProductTest__c WHERE Id = :recordId LIMIT 1';
        ProductTest__c productTest = Database.query(soql);

        for (String item : items) {
            String fieldApi = fieldMap.get(item);
            if (String.isBlank(fieldApi)) {
                inspectionResults.put(item, '');
                actions.put(item, '');
                qcPassed.put(item, true);
                continue;
            }

            String rawValue = (String)productTest.get(fieldApi);
            List<String> selected = rawValue != null ? rawValue.split(';') : new List<String>();
            List<String> findings = new List<String>();
            String action = '';

            for (String val : selected) {
                val = val.trim();
                if (val.equalsIgnoreCase('Repair') || val.equalsIgnoreCase('Replace')) {
                    action = val;
                } else {
                    findings.add(val);
                }
            }

            inspectionResults.put(item, String.join(findings, ', '));
            actions.put(item, action);
            qcPassed.put(item, true); // Always "Yes"
        }

        // Boot Extender logic
        if (productTest.Install_Boot_Extender__c) {
            items.add('Boot Extender');
            inspectionResults.put('Boot Extender', '');
            actions.put('Boot Extender', 'Install');
            qcPassed.put('Boot Extender', true);
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

    public PageReference saveAsPDF() {
        try {
            PageReference pdfPage = Page.FlexQCReportPDF;
            pdfPage.getParameters().put('id', recordId);
            Blob pdfBlob = pdfPage.getContentAsPDF();

            Datetime easternNow = System.now().addSeconds(TimeZone.getTimeZone('America/New_York').getOffset(System.now()) / 1000);
            String formattedDate = easternNow.format('MM/dd/yyyy');

            ContentVersion content = new ContentVersion();
            content.Title = 'Flex QC Report - ' + formattedDate;
            content.PathOnClient = 'FlexQCReport.pdf';
            content.VersionData = pdfBlob;
            content.IsMajorVersion = true;
            insert content;

            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id].ContentDocumentId;
            link.LinkedEntityId = recordId;
            link.ShareType = 'V';
            link.Visibility = 'AllUsers';
            insert link;

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'PDF successfully saved under the Product Test record.'));
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error generating PDF: ' + e.getMessage()));
        }

        return null;
    }
}