public with sharing class FieldServiceReportController {

    public WorkOrder wo                          { get; private set; }
    public List<WorkOrderLineItem> parts         { get; private set; }
    // The subset the parts grid actually prints: no DOA/return/unused lines,
    // no Labor/Travel/Shipping (those live in the totals block).
    public List<WorkOrderLineItem> displayParts  { get; private set; }
    public List<ServiceAppointment> appointments { get; private set; }

    // Used by the VF page to pad the parts table to a fixed number of rows.
    public List<Integer> blankRows { get; private set; }

    public String   engineerSignature   { get; private set; }   // base64 PNG
    public String   customerSignature   { get; private set; }   // base64 PNG
    public Datetime engineerSignedDate   { get; private set; }
    public Datetime customerSignedDate   { get; private set; }

    // Calculated totals exposed to the page
    public Decimal totalParts    { get; private set; }
    public Decimal laborTotal    { get; private set; }
    public Decimal travelTotal   { get; private set; }
    public Decimal subtotal      { get; private set; }
    public Decimal shippingTotal { get; private set; }
    public Decimal grandTotal    { get; private set; }
    public Decimal laborHours    { get; private set; }
    public Decimal travelHours   { get; private set; }
    public Decimal laborEffRate  { get; private set; }
    public Decimal travelEffRate { get; private set; }

    // ----------------------------------------------------------------
    // Maintenance items, grouped by Type so the page can print one
    // section per type (Preliminary Trophon, Preliminary Checks, etc.).
    // ----------------------------------------------------------------
    public Map<String, List<Maintenance_Item__c>> maintItemsByType { get; private set; }
    public List<String> maintTypeOrder { get; private set; }

    // ---- Single-record types: one record per report, each field maps to
    //      a fixed cell in a detail table on the page. ----
    public Maintenance_Item__c prelimChecks     { get; private set; }
    public Maintenance_Item__c electricTests     { get; private set; }
    public Maintenance_Item__c prelimTrophon     { get; private set; }
    public Maintenance_Item__c findings          { get; private set; }
    public Maintenance_Item__c correctiveAction  { get; private set; }

    // ---- List types: multiple records, rendered as a grid like parts. ----
    public List<Maintenance_Item__c> transducers   { get; private set; }
    public List<Maintenance_Item__c> peripherals   { get; private set; }
    public List<Maintenance_Item__c> testEquipment { get; private set; }

    // Blank padding rows for each grid (mirrors the parts grid pattern).
    public List<Integer> transducerBlankRows { get; private set; }
    public List<Integer> peripheralBlankRows { get; private set; }
    public List<Integer> testEquipBlankRows  { get; private set; }

    // Number of total rows the parts grid should always show
    private static final Integer FIXED_PART_ROWS = 6;

    // Fixed heights for the maintenance grids. Tune per the page layout.
    private static final Integer FIXED_TRANSDUCER_ROWS  = 6;
    private static final Integer FIXED_PERIPHERAL_ROWS  = 2;
    private static final Integer FIXED_TEST_EQUIP_ROWS  = 2;

    // Canonical display order for the maintenance-item sections. Any
    // unexpected types found in the data get appended after these.
    private static final List<String> MAINT_TYPE_ORDER = new List<String>{
        'Preliminary  Trophon',
        'Preliminary Checks',
        'Electric Tests',
        'Transducer',
        'Peripheral',
        'Findings',
        'Corrective Action Note',
        'Test Equipment'
    };

    // Display abbreviations for the P/F picklist values.
    private static final Map<String, String> PF_ABBR = new Map<String, String>{
        'Pass'           => 'P',
        'Fail'           => 'F',
        'Not Applicable' => 'NA'
    };

    // Inventory bookkeeping, not work performed. Keys off Line_Intent__c and
    // drops DOA, unused, and cancelled lines from both the totals
    // and the printed parts grid.
    public static Boolean isExcludedIntent(WorkOrderLineItem p) {
        String intent = (p == null) ? null : p.Line_Intent__c;
        if (String.isBlank(intent)) return false;
        return intent.containsIgnoreCase('DOA')
            || intent.containsIgnoreCase('Unused')
            || intent.containsIgnoreCase('Cancel');
    }

    // Labor/Travel/Shipping belong in the totals block, not the parts grid.
    // Case-sensitive to match the legacy VF CONTAINS filter.
    public static Boolean isRateLine(WorkOrderLineItem p) {
        String lt = (p == null) ? null : p.Line_Type__c;
        return lt != null && (lt.contains('Labor') || lt.contains('Travel') || lt.contains('Shipping'));
    }
    public FieldServiceReportController(ApexPages.StandardController stdCtrl) {

        Id woId = stdCtrl.getId();

        // ----------------------------------------------------------------
        // 1) Load the Work Order with everything the page needs.
        // ----------------------------------------------------------------

        //Need to add block fields

        wo = [
            SELECT Id, WorkOrderNumber, Opportunity_Number__c, Customer_PO__c, Billing_Type__c, WorkType.Name,
                   OwnerId, Owner.Name, Additional_Engineers__c, PO_Number__c,
                   Service_Site_Name__c, Street, City, State, StateCode, PostalCode,
                   Billing_Account_Name__c, Billing_Address__c, Billing_Street__c, Billing_City__c, Billing_State__c, Billing_Zip_Postal_Code__c, Billing_Email__c, Billing_Contact_Name__c,
                   Contact.Name, Contact.Phone, Contact.Email, Contact_Phone_Number__c, contact_email__c, contact_phone__c, contact__c,
                   //Reporter_Contact_Info__c not working
                   Make_Model__c, System_Serial_Number__c, Serial_Number__c, Customer_Id__c, Customer_SR__c,Software__c,
                   Block_FL__c, Block_EQ__c, Block_SR__c,
                   Error_Code__c, Symptom_Code__c, Reported_Symptoms__c, Verified_Symptoms__c, Solution_Remarks__c

            FROM WorkOrder
            WHERE Id = :woId
            LIMIT 1
        ];

        // ----------------------------------------------------------------
        // 2) Load parts, labor, travel and shipping as standard Work Order Line Items.
        //    Line_Type__c drives the Labor/Travel/Shipping classification (sections
        //    5 & 6); Line_Type__c drives the DOA/return skip. Both must be selected.
        // ----------------------------------------------------------------
        parts = [
            SELECT Id, LineItemNumber, Type_Intent__c, Line_Intent__c, Line_Type__c, Description, Part_Number_D__c, Part_Name_D__c,
                   Serial_No__c, Serial_No_D__c, Quantity, UnitPrice, TotalPrice
            FROM WorkOrderLineItem
            WHERE WorkOrderId = :woId
            ORDER BY LineItemNumber
        ];

        // ----------------------------------------------------------------
        // 3) Pull Service Appointments
        // ----------------------------------------------------------------
        appointments = [
            SELECT Id, AppointmentNumber, Status,
                   SchedStartTime, SchedEndTime,      // scheduled window
                   ActualStartTime, ActualEndTime,    // actual on-site times
                   Duration
            FROM ServiceAppointment
            WHERE ParentRecordId = :woId
            ORDER BY ActualStartTime
        ];
       

        // ----------------------------------------------------------------
        // 4) Pull Signatures (defined as a method below; just call it here)
        // ----------------------------------------------------------------
        loadSignatures();

        // ----------------------------------------------------------------
        // 4b) Pull maintenance items tied to the appointment(s).
        //     Appointments must already be loaded (we key off their Ids).
        // ----------------------------------------------------------------
        loadMaintenanceItems();

        // ----------------------------------------------------------------
        // 5) Compute totals
        //    Skip logic keys off Type_Intent__c (DOA, returns, etc.).
        //    Labor / Travel / Shipping classification keys off Line_Type__c.
        // ----------------------------------------------------------------
        totalParts    = 0;
        laborTotal    = 0;
        travelTotal   = 0;
        shippingTotal = 0;
        laborHours    = 0;   // sum of Quantity on Labor lines
        travelHours   = 0;   // sum of Quantity on Travel lines

        for (WorkOrderLineItem p : parts) {
            if (isExcludedIntent(p)) continue;

            // Travel / Labor / Shipping classification now keys off Line_Type__c
            String lineType = p.Line_Type__c;

            Decimal lineAmt = (p.TotalPrice != null)
                ? p.TotalPrice
                : nz(p.Quantity) * nz(p.UnitPrice);

            if (lineType != null && lineType.containsIgnoreCase('Labor')) {
                laborTotal += lineAmt;
                laborHours += nz(p.Quantity);
            } else if (lineType != null && lineType.containsIgnoreCase('Travel')) {
                travelTotal += lineAmt;
                travelHours += nz(p.Quantity);
            } else if (lineType != null && lineType.containsIgnoreCase('Shipping')) {
                shippingTotal += lineAmt;
            } else {
                totalParts += lineAmt;   // everything else
            }
        }

        Decimal preTax = totalParts + laborTotal + travelTotal + shippingTotal;
        subtotal = preTax;

        // Effective (blended) rate = total / hours, guarded against divide-by-zero
        laborEffRate  = (laborHours  != null && laborHours  != 0) ? laborTotal  / laborHours  : 0;
        travelEffRate = (travelHours != null && travelHours != 0) ? travelTotal / travelHours : 0;

        // ----------------------------------------------------------------
        // 6) Build the printable parts list, then pad the grid to a fixed
        //     height. Both the rendered rows and the padding come from the
        //     same filtered list, so they can't drift apart. Excludes the
        //     DOA/unused/cancelled lines (Line_Intent__c) and the
        //     Labor / Travel / Shipping lines (Line_Type__c), which appear
        //     in the totals block rather than the parts grid.
        // ----------------------------------------------------------------
        displayParts = new List<WorkOrderLineItem>();
        for (WorkOrderLineItem li : parts) {
            if (isExcludedIntent(li) || isRateLine(li)) continue;
            displayParts.add(li);
        }

        blankRows = new List<Integer>();
        for (Integer i = 0; i < (FIXED_PART_ROWS - displayParts.size()); i++) {
            blankRows.add(i);
        }
    }   // ---- end constructor ----

    public class ApptRow {
    public String range { get; set; }
}

public List<ApptRow> getAppointmentRows() {
    List<ApptRow> rows = new List<ApptRow>();
    for (ServiceAppointment a : appointments) {   // reuses the existing appointments getter
        Datetime st = (a.ActualStartTime != null) ? a.ActualStartTime : a.SchedStartTime;
        Datetime en = (a.ActualEndTime   != null) ? a.ActualEndTime   : a.SchedEndTime;
        if (st == null) continue;                 // same skip rule as the old rendered= filter
        ApptRow r = new ApptRow();
        r.range = st.format('MM/dd/yyyy hh:mm a')
                + ' - '
                + (en == null ? '' : en.format('MM/dd/yyyy hh:mm a'));
        rows.add(r);
    }
    return rows;
}
    // --------------------------------------------------------------------
    // Maintenance items hang off the Service Appointment(s) for this work
    // order. Group them by Type, then expose:
    //   - single-record properties for the fixed checklist types
    //   - lists (+ blank padding) for the repeating grid types
    //
    // >>> REPLACE THE PLACEHOLDER API NAMES WITH YOUR ORG'S ACTUAL NAMES <<<
    //   - Maintenance_Item__c    : the maintenance-item object
    //   - Service_Appointment__c : the lookup back to ServiceAppointment
    //   - Type__c                : the picklist holding the type values
    //                              (if Record Types, swap mi.Type__c for
    //                              mi.RecordType.Name and query it explicitly)
    // --------------------------------------------------------------------
    private void loadMaintenanceItems() {
        maintItemsByType = new Map<String, List<Maintenance_Item__c>>();
        maintTypeOrder   = new List<String>();

        Set<Id> apptIds = new Set<Id>();
        for (ServiceAppointment appt : appointments) {
            apptIds.add(appt.Id);
        }

        // Default everything so the page never hits a null reference, even
        // when there are no appointments or no maintenance items.
        prelimChecks     = new Maintenance_Item__c();
        electricTests    = new Maintenance_Item__c();
        prelimTrophon    = new Maintenance_Item__c();
        findings         = new Maintenance_Item__c();
        correctiveAction = new Maintenance_Item__c();
        transducers      = new List<Maintenance_Item__c>();
        peripherals      = new List<Maintenance_Item__c>();
        testEquipment    = new List<Maintenance_Item__c>();
        transducerBlankRows = new List<Integer>();
        peripheralBlankRows = new List<Integer>();
        testEquipBlankRows  = new List<Integer>();

        if (apptIds.isEmpty()) return;

        // Build "all fields" list from the object's describe so every custom
        // field is available to the page without naming each one here.
        Map<String, Schema.SObjectField> fieldMap =
            Maintenance_Item__c.SObjectType.getDescribe().fields.getMap();
        String fieldList = String.join(new List<String>(fieldMap.keySet()), ', ');

        String soql = 'SELECT AVG_Brightness_Across_Image__c,'
+'Additional_Documentation_Reference__c,'
+'Air_Calibration__c,'
+'Alignment_and_Centring__c,'
+'Alignment_and_Positioning__c,'
+'All_Cords_and_Cables_Intact_No_Frays__c,'
+'Auxilary_Mountings_and_Fixings__c,'
+'BF_Outputs__c,'
+'BIOS_Battery_Reading__c,'
+'Backup_Corrections__c,'
+'Backup_Preset_Network_Settings__c,'
+'Bearings_and_Tracks__c,'
+'Brakes_and_Locks__c,'
+'COR_QA__c,'
+'Check_Calibrate_Power_Supplies__c,'
+'Check_Optimize_Monitor__c,'
+'Check_2D_PW_Color_Incl_Angio_Power__c,'
+'Check_3D_4D__c,'
+'Check_CW_Doppler__c,'
+'Check_Chemical_Leakage__c,'
+'Check_Control_Panel_Keyboard__c,'
+'Check_ECG_Cable_Signal__c,'
+'Check_Network_Functionality__c,'
+'Check_System_Battery__c,'
+'Check_Systems_Fans__c,'
+'Checked_Basic_Measurements__c,'
+'Clean_System_Monitor_Touch_Panel__c,'
+'Clean_Systems_Filters__c,'
+'Clean_Trackball__c,'
+'Clean_Waste_Tray_and_Panels__c,'
+'Clean_and_Inspect_System_Interior__c,'
+'Collimator_Carts__c,'
+'Collimator_Exchange_Mechanism__c,'
+'Collimator_Function_and_Alignment__c,'
+'Collision_Pads__c,'
+'Cooling_Systems_and_Heat_Exchangers__c,'
+'Corrective_Action_Required__c,'
+'Covers_Secured__c,'
+'Cycle_Count__c,'
+'DAP_Accuracy__c,'
+'Destruct_Fan_Max__c,'
+'Destruct_Fan_Min__c,'
+'Detector_2_Rotate__c,'
+'Detector_Fans__c,'
+'Detector_Latch_Bars__c,'
+'Detector_Motions__c,'
+'Detector_Peak__c,'
+'Detector_Uniformity__c,'
+'Detector_Voltages__c,'
+'Detectors_Checks_Comments__c,'
+'Detectors_Radius_and_Tangential_Drives__c,'
+'Device_Current_A__c,'
+'Discuss_Customer_Concerns__c,'
+'Display_Image_Quality_Assurance__c,'
+'Earth_Continuity__c,'
+'Electrical_Checks_Comments__c,'
+'Emergency_Stop_Switches_and_Isolators__c,'
+'End_to_End_DICOM__c,'
+'Error_Logs__c,'
+'Exchanged_Locking_Dock__c,'
+'Exchanger_Carts__c,'
+'Exposure_Checks_Comments__c,'
+'Exposure_Controls__c,'
+'Exposure_Index__c,'
+'Exposure_Indicators__c,'
+'FF_Outputs__c,'
+'Final_Functional_Checks__c,'
+'Final_Visual_Checks__c,'
+'Gantry_Covers_and_Cables__c,'
+'Gantry_Roll_Gear__c,'
+'Gantry_Rotation__c,'
+'General_Checks_Comments__c,'
+'Hospital_Grade_Plug__c,'
+'If_Yes_Please_Describe__c,'
+'Image_Artifacts__c,'
+'Image_Display_Quality__c,'
+'Imaging_Checks_Comments__c,'
+'Inspect_Acc_Periph_Security__c,'
+'Inspect_Board_and_Cable__c,'
+'Inspect_Chamber_Air_Path__c,'
+'Inspect_Chamber_seal_probe_clamp_etc__c,'
+'Inspect_Tubing__c,'
+'Inspect_chamber_door_lock__c,'
+'Laser_Lights__c,'
+'Leak_Value_GND_Open_A__c,'
+'Limit_Switches__c,'
+'Line_Voltage_V__c,'
+'Mechanical_Checks_Comments__c,'
+'Mechanical_Security__c,'
+'Mechanical_Visual_Inspection__c,'
+'Monitor_UI_Clean__c,'
+'Mylar_Window__c,'
+'Neb_Fan_Max__c,'
+'Neb_Fan_Min__c,'
+'Nebulizer_drive_strength__c,'
+'No_Brightness_Transitions__c,'
+'No_Shadows_Caused_by_Dropout__c,'
+'Norm_Polarity_Test_P_On_G_Close_A__c,'
+'Norm_Polarity_Test_P_On_G_Open_A__c,'
+'Nuclear_Mechanical_Checks_Comments__c,'
+'Operating_Environment__c,'
+'P_F__c,'
+'Patient_Positioning_Aids_and_Supports__c,'
+'Perform_Hard_Drive_Maintenance__c,'
+'Peripheral_Name__c,'
+'Peripheral_P_F__c,'
+'Peripheral_Serial_Number__c,'
+'Post_Processing_Functions__c,'
+'Power_Cord_Resistance_m__c,'
+'Preliminary_Comments_and_Findings__c,'
+'QA_Floods_Corrected__c,'
+'QA_Floods_Uncorrected__c,'
+'Reset_PM_Date__c,'
+'Rev_Polarity_Test_P_On_G_Close_A__c,'
+'Rev_Polarity_Test_P_On_G_Open_A__c,'
+'Review_Error_Logs_If_Applicable__c,'
+'Room_Warning_Lights__c,'
+'Run_System_Diagnostics_If_Applicable__c,'
+'Run_disinfection_cycle__c,'
+'Self_Test__c,'
+'Service_Appointment__c,'
+'Slip_Rings_and_Brushes__c,'
+'Switches_Pedals_and_Controls__c,'
+'System_Articulations_Monitor_User_Inte__c,'
+'System_Calibration__c,'
+'Table_Floor_Lock_Pins__c,'
+'Table_Motions__c,'
+'Table_Movements__c,'
+'Test_Equipment_Calibration_Date__c,'
+'Test_Equipment_Model_Name__c,'
+'Test_Equipment_Serial_Number__c,'
+'Test_Lead_Isolation_P_F__c,'
+'Test_Lead_Isolation_A__c,'
+'Test_Lead_Leakage_Normal_Condition_PF__c,'
+'Test_Lead_Leakage_Normal_Condition_A__c,'
+'Transducer_Max_Depth__c,'
+'Transducer_Model__c,'
+'Transducer_S_N__c,'
+'Transducers_Cleaned_After_Each_Use__c,'
+'Trophon_Comments__c,'
+'Trophon_Dosage__c,'
+'Tube_Adjustments_Performed__c,'
+'Type__c,'
+'UPS_Battery__c,'
+'Unit_Inspected_and_Tested_Per_OEM_Servic__c,'
+'Ventilation_Clean__c,'
+'Verify_Boot_Up_Process__c,'
+'Verify_Database__c,'
+'Verify_Door_and_Handles__c,'
+'Verify_Power_Up__c,'
+'Verify_Printer_Functionality__c,'
+'Verify_Remote_Diagnostics_If_Applicable__c,'
+'Virtual_Collimator_Alignment__c,'
+'Visual_Inspection__c,'
+'Voltages__c,'
+'Water_Calibration__c,'
+'Wheel_Locks_Functional__c,'
+'Wheels_Securely_Attached_Rotate_Proper__c,'
+'Without_Cracks_or_Delamination__c'
                    + ' FROM Maintenance_Item__c'
                    + ' WHERE Service_Appointment__c IN :apptIds'
                    + ' ORDER BY Name';

        List<Maintenance_Item__c> items = (List<Maintenance_Item__c>) Database.query(soql);
        abbreviatePF(items);

        for (Maintenance_Item__c mi : items) {
            String key = (mi.Type__c == null) ? 'Other' : mi.Type__c;
            if (!maintItemsByType.containsKey(key)) {
                maintItemsByType.put(key, new List<Maintenance_Item__c>());
            }
            maintItemsByType.get(key).add(mi);
        }

        // ---- Single-record types: first record of each, or an empty stub. ----
        prelimChecks     = firstOrNew('Preliminary Checks');
        electricTests    = firstOrNew('Electric Tests');
        prelimTrophon    = firstOrNew('Preliminary  Trophon');
        findings         = firstOrNew('Findings');
        correctiveAction = firstOrNew('Corrective Action Note');

        // ---- List types: the full list, then padded to a fixed height. ----
        transducers   = listOrEmpty('Transducer');
        peripherals   = listOrEmpty('Peripheral');
        testEquipment = listOrEmpty('Test Equipment');

        transducerBlankRows = padRows(FIXED_TRANSDUCER_ROWS, transducers.size());
        peripheralBlankRows = padRows(FIXED_PERIPHERAL_ROWS, peripherals.size());
        testEquipBlankRows  = padRows(FIXED_TEST_EQUIP_ROWS,  testEquipment.size());

        // render order: canonical types with rows first, then any extras
        for (String t : MAINT_TYPE_ORDER) {
            if (maintItemsByType.containsKey(t)) maintTypeOrder.add(t);
        }
        List<String> extras = new List<String>();
        for (String k : maintItemsByType.keySet()) {
            if (!MAINT_TYPE_ORDER.contains(k)) extras.add(k);
        }
        extras.sort();
        maintTypeOrder.addAll(extras);
    }

    // First record of a type, or an empty record so VF renders blank cells.
    private Maintenance_Item__c firstOrNew(String type) {
        List<Maintenance_Item__c> l = maintItemsByType.get(type);
        return (l != null && !l.isEmpty()) ? l[0] : new Maintenance_Item__c();
    }

    // All records of a type, or an empty list.
    private List<Maintenance_Item__c> listOrEmpty(String type) {
        List<Maintenance_Item__c> l = maintItemsByType.get(type);
        return (l != null) ? l : new List<Maintenance_Item__c>();
    }

    // Build (fixedCount - used) blank index rows for grid padding.
    private List<Integer> padRows(Integer fixedCount, Integer used) {
        List<Integer> blanks = new List<Integer>();
        for (Integer i = 0; i < (fixedCount - used); i++) {
            blanks.add(i);
        }
        return blanks;
    }

    // Rewrite Pass/Fail/Not Applicable to P/F/NA across every string field.
    private void abbreviatePF(List<Maintenance_Item__c> items) {
        for (Maintenance_Item__c mi : items) {
            Map<String, Object> populated = mi.getPopulatedFieldsAsMap();
            for (String f : populated.keySet()) {
                Object v = populated.get(f);
                if (v instanceof String && PF_ABBR.containsKey((String) v)) {
                    try {
                        mi.put(f, PF_ABBR.get((String) v));
                    } catch (Exception e) {
                        /* formula/non-writeable field — skip */
                    }
                }
            }
        }
    }

    // --------------------------------------------------------------------
    // Signatures: a DigitalSignature can parent to the WorkOrder OR one of
    // its appointments. The signature image lives in the "Document" field,
    // whose data type is File — and File fields are NOT queryable in SOQL.
    // The image is attached to the DigitalSignature record as a Salesforce
    // File, so it is resolved through ContentDocumentLink:
    //     DigitalSignature.Id  ->  ContentDocumentLink  ->  ContentDocumentId
    //                          ->  ContentVersion.VersionData  ->  base64
    // --------------------------------------------------------------------
    private void loadSignatures() {
        Set<Id> parentIds = new Set<Id>{ wo.Id };
        for (ServiceAppointment appt : appointments) {
            parentIds.add(appt.Id);
        }

        List<DigitalSignature> sigs = [
            SELECT Id, SignatureType, ParentId, CreatedDate
            FROM DigitalSignature
            WHERE ParentId IN :parentIds
            ORDER BY CreatedDate DESC
        ];
        if (sigs.isEmpty()) return;

        // signature Id -> ContentDocumentId, via the Files relationship.
        Set<Id> sigIds = new Map<Id, DigitalSignature>(sigs).keySet();

        Map<Id, Id> docBySig = new Map<Id, Id>();
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink cdl : [
                SELECT LinkedEntityId, ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :sigIds]) {
            // Assumes one signature file per record; first link wins.
            if (!docBySig.containsKey(cdl.LinkedEntityId)) {
                docBySig.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
                docIds.add(cdl.ContentDocumentId);
            }
        }
        if (docIds.isEmpty()) return;

        // Pull the image bytes once per document, base64-encode for the PDF.
        Map<Id, String> imgByDoc = new Map<Id, String>();
        for (ContentVersion cv : [
                SELECT ContentDocumentId, VersionData
                FROM ContentVersion
                WHERE ContentDocumentId IN :docIds AND IsLatest = true]) {
            imgByDoc.put(cv.ContentDocumentId, EncodingUtil.base64Encode(cv.VersionData));
        }

        // Route each signature to its slot. Adjust the string matches to
        // YOUR org's actual SignatureType picklist values.
        for (DigitalSignature s : sigs) {
            Id docId = docBySig.get(s.Id);
            String img = (docId == null) ? null : imgByDoc.get(docId);
            if (img == null) continue;

            String t = (s.SignatureType == null ? '' : s.SignatureType.toLowerCase());

            if (engineerSignature == null &&
                (t.contains('engineer') || t.contains('tech') || t.contains('fse'))) {
                engineerSignature  = img;
                engineerSignedDate = s.CreatedDate;
            } else if (customerSignature == null &&
                (t.contains('customer') || t.contains('client'))) {
                customerSignature  = img;
                customerSignedDate = s.CreatedDate;
            }
        }
    }

    // Null-safe decimal helper
    private Decimal nz(Decimal d) {
        return d == null ? 0 : d;
    }
}