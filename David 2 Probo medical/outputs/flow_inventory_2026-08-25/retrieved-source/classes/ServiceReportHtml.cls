/**
 * Builds the field-service / PM reports as HTML and renders them to PDF with
 * Blob.toPdf() -- synchronous, @AuraEnabled-safe, so it works directly from the
 * capture LWC. No Visualforce page request, no callout, no Named Credential.
 *
 * Data comes from FieldServiceReportController (constructed with a synthetic
 * StandardController so all parts/totals/appointments/maintenance logic stays in
 * one place). Signatures come from ServiceSignatureController via the
 * FileDownload servlet URL -- the source the capture LWC actually populates.
 *
 * Routing (WorkType.Name + Make/Model):
 *   Break Fix                              -> FSR
 *   PPM + Make/Model contains 'trophon'    -> Trophon PM
 *   PPM (any other Make/Model)             -> PM
 *
 * preliminary == true  -> the capture LWC skipped signatures and the required-field
 *                         gate; the PDF is filed with a leading "Prelim " (handled in
 *                         ServiceSignatureController.saveReportVersion). The report
 *                         renders normally; the signature blocks come out empty
 *                         because no Service_Signature__c records exist.
 */
public with sharing class ServiceReportHtml {

    @AuraEnabled
    public static Id generateReport(Id workOrderId, Boolean preliminary) {
        try {
            String html = build(workOrderId);
            Blob pdf = Test.isRunningTest() ? Blob.valueOf('TEST-PDF') : Blob.toPdf(html);
            return ServiceSignatureController.saveReportVersion(workOrderId, pdf, preliminary == true);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw err('Report generation failed: ' + e.getMessage());
        }
    }

    public static String build(Id woId) {
        WorkOrder w = [SELECT WorkType.Name, Make_Model__c FROM WorkOrder WHERE Id = :woId LIMIT 1];
        String wt = (w.WorkType != null) ? w.WorkType.Name : null;
        if (wt == 'PPM') {
            Boolean trophon = w.Make_Model__c != null && w.Make_Model__c.toLowerCase().contains('trophon');
            return trophon ? buildTrophon(woId) : buildPpm(woId);
        }
        return buildFsr(woId);   // Break Fix / default
    }

    // =====================================================================
    //  FSR (Break Fix)
    // =====================================================================
    private static String buildFsr(Id woId) {
        Context c = load(woId);
        WorkOrder wo = c.wo;

        String h = '<html><head><style type="text/css">'
            + '@page { size: letter landscape; margin: 0.45in 0.45in 0.55in 0.45in;'
            + ' @bottom-center { content: "5735 Benjamin Center Dr Tampa, FL 33634 | P: 1-866-513-8322 | www.ProboMedical.com";'
            + ' font-family: Arial, sans-serif; font-size: 10px; color: #333; } }'
            + baseCss()
            + '.title { font-size:26px; font-weight:bold; color:#0072bc; text-align:right; letter-spacing:1px; }'
            + '</style></head><body>'
            + '<table class="hdr-table"><tr>'
            + '<td style="width:45%"><img src="/resource/ProboMedicalInvoiceLogo" width="150"/></td>'
            + '<td style="width:55%; vertical-align:middle;"><div class="title">FIELD SERVICE REPORT</div>'
            + (String.isBlank(wo.Billing_Type__c) ? '' : '<div style="font-size:13px; text-align:right; font-weight:bold; color:#555; margin-top:3px;">' + esc(wo.Billing_Type__c) + '</div>')
            + '</td>'
            + '</tr></table>'
            + '<div style="height:8px;"></div>'   // small gap between the logo header and the info grid
            + infoGrid(wo, c.billAccount, true)    // FSR swaps Work Order / Product Detail
            + '<div class="divider"></div>';

        // Symptoms / verified -- Service Appointments and Reported Symptoms areas switched
        h += '<table class="grid">'
            + '<colgroup><col style="width:12%"/><col style="width:12%"/><col style="width:28%"/><col style="width:46%"/></colgroup>'
            + '<tr><td class="grp-hdr">Error Code</td><td class="grp-hdr">Symptom Code</td>'
            + '<td class="grp-hdr">Reported Symptoms</td><td class="grp-hdr">Verified Symptoms</td></tr>'
            + '<tr><td style="height:30px;">' + esc(wo.Error_Code__c) + '</td>'
            + '<td style="height:30px;">' + esc(wo.Symptom_Code__c) + '</td>'
            + '<td style="white-space:pre-wrap;">' + esc(wo.Reported_Symptoms__c) + '</td>'
            + '<td>' + esc(wo.Verified_Symptoms__c) + '</td></tr>'
            + '<tr><td colspan="2" class="grp-hdr">Service Appointments</td><td colspan="2" class="grp-hdr">Solutions/Remarks</td></tr>'
            + '<tr><td colspan="2" style="height:48px;">' + apptBlock(c.appts) + '</td>'
            + '<td colspan="2">' + esc(wo.Solution_Remarks__c) + '</td></tr>'
            + '</table><div class="divider"></div>';

        // Parts (prefiltered by FieldServiceReportController.displayParts (Labor, Travel, Shipping, DOA/Unused))
        h += '<table class="parts">'
            + '<colgroup><col style="width:11%"/><col style="width:25%"/><col style="width:15%"/><col style="width:19%"/>'
            + '<col style="width:6%"/><col style="width:14%"/><col style="width:10%"/></colgroup>'
            + '<tr><th class="grp-hdr">Part #</th><th class="grp-hdr">Description</th><th class="grp-hdr">Serial No</th>'
            + '<th class="grp-hdr">Status | Type</th><th class="grp-hdr">Qty</th><th class="grp-hdr">Unit Price</th>'
            + '<th class="grp-hdr">Total Price</th></tr>';
        for (WorkOrderLineItem p : c.data.displayParts) {
            h += '<tr><td>' + esc(p.Part_Number_D__c) + '</td><td>' + esc(p.Part_Name_D__c) + '</td>'
                + '<td>' + esc(p.Serial_No_D__c) + '</td><td>' + esc(p.Type_Intent__c) + '</td>'
                + '<td class="num">' + (p.Quantity == null ? '' : String.valueOf(p.Quantity)) + '</td>'
                + '<td class="num">' + money(p.UnitPrice) + '</td><td class="num">' + money(p.TotalPrice) + '</td></tr>';
        }
        for (Integer i = 0; i < c.data.blankRows.size(); i++) {
            h += '<tr><td style="height:16px;">&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>'
                + '<td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>';
        }
        h += '</table><div class="divider"></div>';

        // Signatures + totals
        h += '<table class="parts">'
            + '<colgroup><col style="width:9%"/><col style="width:40%"/><col style="width:6%"/><col style="width:14%"/>'
            + '<col style="width:1%"/><col style="width:6%"/><col style="width:14%"/><col style="width:10%"/></colgroup>'
            + '<tr><td colspan="4" class="grp-hdr">Signatures</td><td rowspan="5" style="background-color:#000;"></td>'
            + '<td colspan="2" class="grp-hdr">Total Parts</td><td class="num">' + money(c.data.totalParts) + '</td></tr>'
            + '<tr><td rowspan="2" class="lbl" style="vertical-align:middle;">Engineer</td>'
            + '<td rowspan="2" style="text-align:center; vertical-align:middle;">' + esc(sigName(c.eng)) + ' ' + sigImg(c.eng) + '</td>'
            + '<td rowspan="2" class="lbl" style="vertical-align:middle;">Date:</td>'
            + '<td rowspan="2" style="vertical-align:middle;">' + esc(sigDate(c.eng)) + '</td>'
            + '<td colspan="2" class="lbl">Shipping</td><td class="num">' + money(c.data.shippingTotal) + '</td></tr>'
            + '<tr><td class="lbl">Labor</td>'
            + '<td style="text-align:center;">' + num(c.data.laborHours) + ' Hrs @ ' + num(c.data.laborEffRate) + ' /Hr.</td>'
            + '<td class="num">' + money(c.data.laborTotal) + '</td></tr>'
            + '<tr><td rowspan="2" class="lbl" style="vertical-align:middle;">Customer</td>'
            + '<td rowspan="2" style="text-align:center; vertical-align:middle;">' + esc(sigName(c.cust)) + ' ' + sigImg(c.cust) + '</td>'
            + '<td rowspan="2" class="lbl" style="vertical-align:middle;">Date:</td>'
            + '<td rowspan="2" style="vertical-align:middle;">' + esc(sigDate(c.cust)) + '</td>'
            + '<td class="lbl">Travel</td>'
            + '<td style="text-align:center;">' + num(c.data.travelHours) + ' Hrs @ ' + num(c.data.travelEffRate) + ' /Hr.</td>'
            + '<td class="num">' + money(c.data.travelTotal) + '</td></tr>'
            + '<tr><td colspan="2" class="lbl">Total</td><td class="num">' + money(c.data.subtotal) + '</td></tr>'
            + '<tr><td colspan="5" style="border:none;">&nbsp;</td>'
            + '<td colspan="3" class="submsg" style="text-align:right; border:none;">Applicable tax will be added to your invoice.</td></tr>'
            + '</table></body></html>';
        return h;
    }

    // =====================================================================
    //  PM (non-Trophon)
    // =====================================================================
    private static String buildPpm(Id woId) {
        Context c = load(woId);
        WorkOrder wo = c.wo;
        Maintenance_Item__c pc = c.data.prelimChecks;
        Maintenance_Item__c et = c.data.electricTests;
        Maintenance_Item__c ca = c.data.correctiveAction;

        String h = pmHead('PREVENTATIVE MAINTENANCE REPORT', null, false)
            + infoGrid(wo, c.billAccount)
            + '<div class="divider"></div>';

        // PM checklist
        h += '<table class="parts">'
            + '<colgroup><col style="width:5%"/><col style="width:24%"/><col style="width:5%"/><col style="width:29%"/><col style="width:5%"/><col style="width:30%"/></colgroup>'
            + '<tr><td class="submsg" colspan="6" style="text-align:center">PM Checksheet Pass (P), Faily (F), Not Applicable (NA)</td></tr>'
            + '<tr><td class="grp-hdr" colspan="2" style="text-align:center">Preliminary</td><td class="grp-hdr" colspan="2" style="text-align:center">Inspection and Cleaning</td><td class="grp-hdr" colspan="2" style="text-align:center">Verification</td></tr>'
            + '<tr>' + chk(pc,'Discuss_Customer_Concerns__c','Discuss Customer Concerns') + chk(pc,'Clean_and_Inspect_System_Interior__c','Clean and inspect system interior') + chk(pc,'Check_Control_Panel_Keyboard__c','Check Control Panel / Keyboard') + '</tr>'
            + '<tr>' + chk(pc,'Verify_Power_Up__c','Verify Power Up') + chk(pc,'Check_Systems_Fans__c','Check system fans') + chk(pc,'Check_ECG_Cable_Signal__c','Check ECG Cable / Signal') + '</tr>'
            + '<tr>' + chk(pc,'Verify_Boot_Up_Process__c','Verify Boot Process') + chk(pc,'Clean_Systems_Filters__c','Clean system filters') + chk(pc,'Check_System_Battery__c','Check System Battery') + '</tr>'
            + '<tr>' + chk(pc,'Backup_Preset_Network_Settings__c','Backup Preset &amp; Network Settings') + chk(pc,'Clean_System_Monitor_Touch_Panel__c','Clean system monitor / touch panel') + chk(pc,'Check_Network_Functionality__c','Check Network functionality') + '</tr>'
            + '<tr>' + chk(pc,'Verify_Remote_Diagnostics_If_Applicable__c','Verify Remote Diagnostics if applicable') + chk(pc,'Clean_Trackball__c','Clean trackball') + chk(pc,'Check_2D_PW_Color_Incl_Angio_Power__c','Check 2D, PW, Color (Incl. Angio, Power Doppler)') + '</tr>'
            + '<tr>' + chk(pc,'Review_Error_Logs_If_Applicable__c','Review Error Logs if applicable') + chk(pc,'Hospital_Grade_Plug__c','Hospital grade plug') + chk(pc,'Check_CW_Doppler__c','Check CW Doppler') + '</tr>'
            + '<tr>' + chk(pc,'Run_System_Diagnostics_If_Applicable__c','Run System Diagnostics if available') + chk(pc,'Inspect_Acc_Periph_Security__c','Inspect accessories, peripherals for proper security') + chk(pc,'Check_3D_4D__c','Check 3D / 4D') + '</tr>'
            + '<tr>' + chk(pc,'Verify_Database__c','Verify Database') + chk(pc,'Wheels_Securely_Attached_Rotate_Proper__c','Wheels securely attached and rotate properly') + chk(pc,'Check_Optimize_Monitor__c','Check / optimize monitor') + '</tr>'
            + '<tr>' + chk(pc,'Perform_Hard_Drive_Maintenance__c','Perform hard drive maintenance') + chk(pc,'Wheel_Locks_Functional__c','Wheel locks functional') + chk(pc,'Checked_Basic_Measurements__c','Checked basic measurements') + '</tr>'
            + '<tr>' + chk(pc,'Transducers_Cleaned_After_Each_Use__c','Transducers cleaned after each use') + chk(pc,'All_Cords_and_Cables_Intact_No_Frays__c','All cords and cables intact (no frays)') + chk(pc,'Check_Calibrate_Power_Supplies__c','Check / calibrate power supplies') + '</tr>'
            + '<tr><td></td><td></td>' + chk(pc,'System_Articulations_Monitor_User_Inte__c','System articulations (monitor, UI, etc.)') + chk(pc,'Unit_Inspected_and_Tested_Per_OEM_Servic__c','Unit inspected and tested per OEM service manual') + '</tr>'
            + '</table><div class="divider"></div>';

        // Comments / flat-rate charge
        h += '<table class="parts"><colgroup><col style="width:30%"/><col style="width:50%"/><col style="width:20%"/></colgroup>'
            + '<tr><td class="grp-hdr" style="text-align:center">Service Appts</td><td class="grp-hdr" style="text-align:center">Preliminary comments and findings</td><td class="grp-hdr" style="text-align:right">Flat Rate PM Charge</td></tr>'
            + '<tr style="height:50px;"><td style="vertical-align:top;">' + apptBlock(c.appts) + '</td>'
            + '<td>' + v(pc,'Preliminary_Comments_and_Findings__c') + '</td>'
            + '<td class="num">' + money(c.data.subtotal) + '</td></tr>'
            + '<tr><td class="submsg" colspan="3" style="text-align:right; border-left:none; border-bottom:none; border-right:none; height:40px; vertical-align:top;">Applicable tax will be added to your invoice.</td></tr>'
            + '</table>';

        // Page 2: electrical safety tests
        String serial = String.isNotBlank(wo.System_Serial_Number__c) ? wo.System_Serial_Number__c : wo.Serial_Number__c;
        h += '<table class="grid" style="page-break-before: always;">'
            + '<colgroup><col style="width:13%"/><col style="width:7%"/><col style="width:13%"/><col style="width:6%"/><col style="width:18%"/>'
            + '<col style="width:1%"/><col style="width:1%"/><col style="width:10%"/><col style="width:11%"/><col style="width:7%"/><col style="width:12%"/></colgroup>'
            + '<tr><td class="grp-hdr" colspan="4">Electrical Safety Tests</td>'
            + '<td class="grp-hdr" colspan="3">ECG Leakage Tests <span style="font-size:9px;">(if applicable)</span></td>'
            + '<td class="grp-hdr" colspan="2">Work Order</td><td class="grp-hdr" colspan="2">Product Detail</td></tr>'
            + '<tr><td colspan="4" style="text-align:center; font-size:11px"><b>Line Voltage:</b> ' + v(et,'Line_Voltage_V__c')
            + '  <b>Device Current:</b> ' + v(et,'Device_Current_A__c') + '  <b>Power Cord Resistance:</b> ' + v(et,'Power_Cord_Resistance_m__c') + ' &#937;</td>'
            + '<td class="col-hdr">Test</td><td class="col-hdr">Value</td><td class="col-hdr">P/F</td>'
            + '<td class="lbl">Date</td><td>' + esc(Datetime.now().format('MM/dd/yyyy')) + '</td>'
            + '<td class="lbl">Make/Model</td><td>' + esc(wo.Make_Model__c) + '</td></tr>'
            + '<tr><td class="sub-hdr" colspan="2" style="border-bottom:none; text-align:center;">Normal Polarity Test</td>'
            + '<td class="sub-hdr" colspan="2" style="border-bottom:none; text-align:center;">Reverse Polarity Test</td>'
            + '<td style="border-bottom:none;">Lead Leakage</td>'
            + '<td class="val" rowspan="2">' + v(et,'Test_Lead_Leakage_Normal_Condition_A__c') + ' &micro;A</td>'
            + '<td class="val" rowspan="2">' + pf(et,'Test_Lead_Leakage_Normal_Condition_PF__c') + '</td>'
            + '<td class="lbl">WO#</td><td>' + esc(wo.WorkOrderNumber) + '</td>'
            + '<td class="lbl">Serial#</td><td>' + esc(serial) + '</td></tr>'
            + '<tr><td class="sub-hdr" colspan="2" style="border-top:none; text-align:center;">(Power ON)</td>'
            + '<td class="sub-hdr" colspan="2" style="border-top:none; text-align:center;">(Power ON)</td>'
            + '<td style="border-top:none;">(Normal Condition)</td>'
            + '<td class="lbl">Opp #</td><td>' + esc(wo.Opportunity_Number__c) + '</td>'
            + '<td class="lbl">Customer ID</td><td>' + esc(wo.Customer_Id__c) + '</td></tr>'
            + '<tr><td>Ground Open:</td><td class="val">' + v(et,'Norm_Polarity_Test_P_On_G_Open_A__c') + ' &micro;A</td>'
            + '<td>Ground Open:</td><td class="val">' + v(et,'Rev_Polarity_Test_P_On_G_Open_A__c') + ' &micro;A</td>'
            + '<td>Lead Isolation Test</td><td class="val">' + v(et,'Test_Lead_Isolation_A__c') + ' &micro;A</td>'
            + '<td class="val">' + pf(et,'Test_Lead_Isolation_P_F__c') + '</td>'
            + '<td class="lbl">Block SR#</td><td>' + esc(wo.Block_SR__c) + '</td>'
            + '<td class="lbl">Block EQ#</td><td>' + esc(wo.Block_EQ__c) + '</td></tr>'
            + '<tr><td>Ground Closed:</td><td class="val">' + v(et,'Norm_Polarity_Test_P_On_G_Close_A__c') + ' &micro;A</td>'
            + '<td>Ground Closed:</td><td class="val">' + v(et,'Rev_Polarity_Test_P_On_G_Close_A__c') + ' &micro;A</td>'
            + '<td colspan="7">&nbsp;</td></tr>'
            + '</table><div class="divider-sm"></div>';

        // Probe tests
        h += '<table class="parts"><colgroup><col style="width:15%"/><col style="width:10%"/><col style="width:8%"/><col style="width:15%"/>'
            + '<col style="width:15%"/><col style="width:15%"/><col style="width:10%"/><col style="width:6%"/><col style="width:6%"/></colgroup>'
            + '<tr><td class="grp-hdr" colspan="4" style="text-align:center;">SYSTEM SENSITIVITY (Max. Depth)'
            + '<div style="font-weight:normal; font-size:10px;">Turn off image enhancements. With system sensitivity set up for visualizing echogenicity as deeply as possible, select the maximum depth you can visualize the background echographic pattern.</div></td>'
            + '<td class="grp-hdr" colspan="5" style="text-align:center;">UNIFORMITY'
            + '<div style="font-weight:normal; font-size:10px;">Set up Main and TGC gain to obtain a uniform image, freeze the image and select the appropriate answer. 1) Agree 2) Disagree, slight non uniformities present 3) Disagree, major non uniformities present</div></td></tr>'
            + '<tr><td class="seg-hdr">Transducer Model</td><td class="seg-hdr">Transducer S/N</td><td class="seg-hdr">Max Depth (cm)</td>'
            + '<td class="seg-hdr">Average Brightness is same throughout image</td><td class="seg-hdr">No vertical or radial shadows cuased by dropout</td>'
            + '<td class="seg-hdr">No brightness transitions between focal zones</td><td class="seg-hdr">Intacts without cracks or delamination</td>'
            + '<td class="seg-hdr" style="font-size:8px;">Leakge Value GND Open (&micro;A)</td><td class="seg-hdr">P/F</td></tr>';
        for (Maintenance_Item__c t : c.data.transducers) {
            h += '<tr><td style="text-align:center;">' + v(t,'Transducer_Model__c') + '</td><td style="text-align:center;">' + v(t,'Transducer_S_N__c') + '</td>'
                + '<td style="text-align:center;">' + v(t,'Transducer_Max_Depth__c') + '</td><td style="text-align:center;">' + v(t,'AVG_Brightness_Across_Image__c') + '</td>'
                + '<td style="text-align:center;">' + v(t,'No_Shadows_Caused_by_Dropout__c') + '</td><td style="text-align:center;">' + v(t,'No_Brightness_Transitions__c') + '</td>'
                + '<td style="text-align:center;">' + v(t,'Without_Cracks_or_Delamination__c') + '</td><td style="text-align:center;">' + numComma(t,'Leak_Value_GND_Open_A__c') + '</td>'
                + '<td style="text-align:center;">' + v(t,'P_F__c') + '</td></tr>';
        }
        for (Integer i = 0; i < c.data.transducerBlankRows.size(); i++) {
            h += '<tr><td>&nbsp;</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>';
        }
        h += '</table><div class="divider-sm"></div>';

        // Peripherals + test equipment (capped at 2 lines each)
        h += '<table class="page2-layout"><tr>'
            + '<td style="width:36%; vertical-align:top; padding:0; border-right:2px solid #000;">'
            + '<table class="parts"><colgroup><col style="width:40%"/><col style="width:45%"/><col style="width:15%"/></colgroup>'
            + '<tr><td class="grp-hdr" style="text-align:center;">Peripheral</td><td class="grp-hdr" style="text-align:center;">Serial Number</td><td class="grp-hdr" style="text-align:center;">P/F</td></tr>';
        for (Maintenance_Item__c p : c.data.peripherals) {
            h += '<tr><td style="text-align:center;">' + v(p,'Peripheral_Name__c') + '</td><td style="text-align:center;">' + v(p,'Peripheral_Serial_Number__c') + '</td>'
                + '<td style="text-align:center;">' + v(p,'Peripheral_P_F__c') + '</td></tr>';
        }
        for (Integer i = 0; i < c.data.peripheralBlankRows.size() && (c.data.peripherals.size() + i) < 2; i++) h += '<tr><td>&nbsp;</td><td></td><td></td></tr>';
        h += '</table></td>'
            + '<td style="width:63%; vertical-align:top; padding:0;">'
            + '<table class="parts"><colgroup><col style="width:40%"/><col style="width:38%"/><col style="width:22%"/></colgroup>'
            + '<tr><td class="grp-hdr" style="text-align:center;">Test Equipment Model</td><td class="grp-hdr" style="text-align:center;">Test Equipment Serial Number</td><td class="grp-hdr" style="text-align:center;">Calibration Date</td></tr>';
        for (Maintenance_Item__c te2 : c.data.testEquipment) {
            h += '<tr><td style="text-align:center;">' + v(te2,'Test_Equipment_Model_Name__c') + '</td><td style="text-align:center;">' + v(te2,'Test_Equipment_Serial_Number__c') + '</td>'
                + '<td style="text-align:center;">' + vDate(te2,'Test_Equipment_Calibration_Date__c') + '</td></tr>';
        }
        for (Integer i = 0; i < c.data.testEquipBlankRows.size() && (c.data.testEquipment.size() + i) < 2; i++) h += '<tr><td>&nbsp;</td><td></td><td></td></tr>';
        h += '</table></td></tr></table><div class="divider-sm"></div>';

        // Corrective action
        h += '<table class="parts"><tr><td style="border-bottom:none;">Corrective Action Required?&nbsp;&nbsp;' + v(ca,'Corrective_Action_Required__c')
            + '&nbsp;&nbsp;&nbsp;&nbsp;If so, please describe:</td></tr>'
            + '<tr><td style="border-top:none; height:50px; vertical-align:top;">' + v(ca,'If_Yes_Please_Describe__c') + '</td></tr>'
            + '</table><div class="divider-sm"></div>';

        h += pmSignatures(c.eng, c.cust) + '</body></html>';
        return h;
    }

    // =====================================================================
    //  Trophon PM
    // =====================================================================
    private static String buildTrophon(Id woId) {
        Context c = load(woId);
        WorkOrder wo = c.wo;
        Maintenance_Item__c pt = c.data.prelimTrophon;
        Maintenance_Item__c fn = c.data.findings;
        Maintenance_Item__c ca = c.data.correctiveAction;

        String h = pmHead('PREVENTATIVE MAINTENANCE REPORT', 'TROPHON', true)
            + infoGrid(wo, c.billAccount)
            + '<div class="divider"></div>';

        // Trophon checklist
        h += '<table class="parts">'
            + '<colgroup><col style="width:4%"/><col style="width:24%"/><col style="width:5%"/><col style="width:35%"/><col style="width:5%"/><col style="width:27%"/></colgroup>'
            + '<tr><td class="grp-hdr" colspan="2" style="text-align:center;">Preliminary</td><td class="grp-hdr" colspan="2" style="text-align:center;">Inspection and Cleaning</td><td class="grp-hdr" colspan="2" style="text-align:center;">Verification</td></tr>'
            + '<tr><td style="font-weight:bold;">P/F</td><td style="font-weight:bold;">Item</td><td style="font-weight:bold;">P/F</td><td style="font-weight:bold;">Item</td><td style="font-weight:bold;">P/F</td><td style="font-weight:bold;">Item</td></tr>'
            + '<tr>' + chk(pt,'Operating_Environment__c','Operating environments meets specs') + chk(pt,'Check_Chemical_Leakage__c','Inspect for any internal or external chemical leakage') + chk(pt,'Run_disinfection_cycle__c','Run disinfection cycle and verify test indicator') + '</tr>'
            + '<tr>' + chk(pt,'Self_Test__c','Run self test') + chk(pt,'Inspect_Tubing__c','Inspect tubing for kinks, anchoring issues, and leakage') + chk(pt,'Verify_Printer_Functionality__c','Verify printer functionality') + '</tr>'
            + '<tr><td></td><td></td>' + chk(pt,'Inspect_Board_and_Cable__c','Inspect all board and cable connections') + chk(pt,'Reset_PM_Date__c','Reset PM date') + '</tr>'
            + '<tr><td></td><td></td>' + chk(pt,'Inspect_chamber_door_lock__c','Inspect chamber door locking mechanism') + '<td></td><td></td></tr>'
            + '<tr><td></td><td></td>' + chk(pt,'Verify_Door_and_Handles__c','Verify chamber door and handle functions properly') + '<td></td><td></td></tr>'
            + '<tr><td></td><td></td>' + chk(pt,'Clean_Waste_Tray_and_Panels__c','Clean the waste tray and exterior panels') + '<td></td><td></td></tr>'
            + '<tr><td></td><td></td>' + chk(pt,'Inspect_Chamber_seal_probe_clamp_etc__c','Inspect chamber seal, probe clamp, gland seal, loom sheath') + '<td></td><td></td></tr>'
            + '<tr><td></td><td></td>' + chk(pt,'Inspect_Chamber_Air_Path__c','Inspect and clean the chamber air path, if needed') + '<td></td><td></td></tr>'
            + '</table><div class="divider"></div>';

        // Comments / findings
        h += '<table class="parts"><colgroup><col style="width:30%"/><col style="width:30%"/><col style="width:15%"/><col style="width:5%"/><col style="width:15%"/><col style="width:5%"/></colgroup>'
            + '<tr><td class="grp-hdr">Service Appts</td><td class="grp-hdr">Comments</td><td class="grp-hdr" colspan="4">Findings</td></tr>'
            + '<tr><td rowspan="4" style="vertical-align:top;">' + apptBlock(c.appts) + '</td>'
            + '<td rowspan="4">' + v(fn,'Trophon_Comments__c') + '</td>'
            + '<td class="col-hdr">Cycle Count</td><td style="text-align:right;">' + numComma(fn,'Cycle_Count__c') + '</td>'
            + '<td class="col-hdr">Neb Fan Min</td><td style="text-align:right;">' + numComma(fn,'Neb_Fan_Min__c') + '</td></tr>'
            + '<tr><td class="col-hdr">Strength</td><td style="text-align:right;">' + numComma(fn,'Nebulizer_drive_strength__c') + '</td>'
            + '<td class="col-hdr">Neb Fan Max</td><td style="text-align:right;">' + numComma(fn,'Neb_Fan_Max__c') + '</td></tr>'
            + '<tr><td class="col-hdr">Dosage</td><td style="text-align:right;">' + numComma(fn,'Trophon_Dosage__c') + '</td>'
            + '<td class="col-hdr">Destruct Fan Min</td><td style="text-align:right;">' + numComma(fn,'Destruct_Fan_Min__c') + '</td></tr>'
            + '<tr><td></td><td></td><td class="col-hdr">Destruct Fan Max</td><td style="text-align:right;">' + numComma(fn,'Destruct_Fan_Max__c') + '</td></tr>'
            + '</table><div class="divider-sm"></div>';

        // Corrective action + flat-rate charge
        h += '<table class="parts"><tr><td style="border-bottom:none;">Corrective Action Required?&nbsp;&nbsp;' + v(ca,'Corrective_Action_Required__c')
            + '&nbsp;&nbsp;&nbsp;&nbsp;If so, please describe:</td><td class="grp-hdr">Flat Rate PM Charge</td></tr>'
            + '<tr><td style="border-top:none; height:30px; vertical-align:top;">' + v(ca,'If_Yes_Please_Describe__c') + '</td>'
            + '<td class="num">' + money(c.data.subtotal) + '</td></tr>'
            + '<tr><td class="submsg" colspan="3" style="text-align:right; border-left:none; border-bottom:none; border-right:none; height:20px; vertical-align:top;">Applicable tax will be added to your invoice.</td></tr>'
            + '</table>';

        h += pmSignatures(c.eng, c.cust) + '</body></html>';
        return h;
    }

    // =====================================================================
    //  Shared data load
    // =====================================================================
    private class Context {
        FieldServiceReportController data;
        WorkOrder wo;
        String billAccount;
        List<ServiceAppointment> appts;
        ServiceSignatureController.SignatureView eng;
        ServiceSignatureController.SignatureView cust;
    }

    private static Context load(Id woId) {
        Context c = new Context();
        c.data = new FieldServiceReportController(new ApexPages.StandardController(new WorkOrder(Id = woId)));
        c.wo = c.data.wo;
        c.appts = c.data.appointments;

        WorkOrder acct = [
            SELECT Account_Name__c, Account_Name_Free_Text__c, Billing_Account_Name__c, Account.Name
            FROM WorkOrder WHERE Id = :woId LIMIT 1
        ];
        c.billAccount = firstNonBlank(new List<String>{
            acct.Account_Name__c,
            acct.Account_Name_Free_Text__c,
            acct.Billing_Account_Name__c,
            (acct.Account != null ? acct.Account.Name : null)
        });

        ServiceSignatureController sc = new ServiceSignatureController(new ApexPages.StandardController(new WorkOrder(Id = woId)));
        c.eng  = sc.getEngineerSig();
        c.cust = sc.getCustomerSig();
        return c;
    }

    // =====================================================================
    //  Shared HTML fragments
    // =====================================================================
    // PM / Trophon: PO # prints "CONTRACT" when Billing_Type__c = Contract.
    private static String infoGrid(WorkOrder wo, String billAccount) {
        return infoGrid(wo, billAccount, true, true);
    }

    // FSR path: PO # printed literally (no CONTRACT substitution).
    private static String infoGrid(WorkOrder wo, String billAccount, Boolean swapWoPd) {
        return infoGrid(wo, billAccount, swapWoPd, false);
    }

    // swapWoPd   = true (FSR) renders Product Detail before Work Order, columns and all.
    // contractPo = true (PM/Trophon) prints "CONTRACT" for PO # when Billing_Type__c = Contract.
    private static String infoGrid(WorkOrder wo, String billAccount, Boolean swapWoPd, Boolean contractPo) {
        String serial = String.isNotBlank(wo.System_Serial_Number__c) ? wo.System_Serial_Number__c : wo.Serial_Number__c;
        String contactName  = (wo.Contact != null) ? wo.Contact.Name  : null;
        String contactEmail = (wo.Contact != null) ? wo.Contact.Email : null;
        String contactPhone = (wo.Contact != null) ? wo.Contact.Phone : null;
        String ownerName    = (wo.Owner   != null) ? wo.Owner.Name    : null;
        // FSE = owner, with Additional Engineers appended when present.
        String fse = ownerName;
        if (String.isNotBlank(wo.Additional_Engineers__c)) {
            fse = String.isBlank(fse) ? wo.Additional_Engineers__c : fse + ', ' + wo.Additional_Engineers__c;
        }
        String today        = Datetime.now().format('MM/dd/yyyy');

        // Site (Ship To) contact: prefer the related Contact, then fall back to WO fields.
        String shipName  = firstNonBlank(new List<String>{ contactName,  wo.Billing_Contact_Name__c });
        String shipPhone = firstNonBlank(new List<String>{ contactPhone, wo.Contact_Phone__c });
        String shipEmail = firstNonBlank(new List<String>{ contactEmail, wo.Contact_Email__c });

        // PO #: PM/Trophon show "CONTRACT" for contract work; everyone else shows the literal PO (Customer__PO from Opp or PO_number manually entered).
        String poValue = (contractPo && 'Contract'.equalsIgnoreCase(wo.Billing_Type__c))
            ? 'CONTRACT'
            : firstNonBlank(new List<String>{ wo.PO_Number__c , wo.Customer_PO__c});

        // Work Order vs Product Detail column widths -- the pair swaps with the sections.
        String colWo = '<col style="width:10%"/><col style="width:11%"/>';
        String colPd = '<col style="width:7%"/><col style="width:13%"/>';
        String rightCols = swapWoPd ? (colPd + colWo) : (colWo + colPd);

        String hdrWo = '<td class="sec-hdr" colspan="2">Work Order:</td>';
        String hdrPd = '<td class="sec-hdr" colspan="2">Product Detail:</td>';
        String rightHdr = swapWoPd ? (hdrPd + hdrWo) : (hdrWo + hdrPd);

        // Per-row Work Order / Product Detail segment pairs (ordered by seg()).
        String r1 = seg(swapWoPd, lbl('Date') + td(today),                         lbl('Make/Model') + td(wo.Make_Model__c));
        String r2 = seg(swapWoPd, lbl('WO#') + td(wo.WorkOrderNumber),             lbl('Serial#') + td(serial));
        String r3 = seg(swapWoPd, lbl('Opp #') + td(wo.Opportunity_Number__c),     lbl('Customer ID') + td(wo.Customer_Id__c));
        String r4 = seg(swapWoPd, lbl('PO #') + td(poValue),                       lbl('Customer SR#') + td(wo.Customer_SR__c));
        String r5 = seg(swapWoPd, lbl('FSE') + td(fse),                            lbl('Software') + td(wo.Software__c));
        String r6 = seg(swapWoPd, lbl('Block SR#') + td(wo.Block_SR__c),           lbl('Block EQ#') + td(wo.Block_EQ__c));

        // Block FL/SR/EQ line only appears for Block accounts.
        Boolean showBlock = billAccount != null && billAccount.toLowerCase().contains('block');
        String blockRow = showBlock
            ? '<tr><td class="lbl" colspan="2">&nbsp;</td>' + lbl('Block FL#') + td(wo.Block_FL__c) + r6 + '</tr>'
            : '';

        return '<table class="grid">'
            + '<colgroup><col style="width:8%"/><col style="width:22%"/><col style="width:7%"/><col style="width:22%"/>'
            + rightCols + '</colgroup>'
            + '<tr><td class="sec-hdr" colspan="2">Bill To:</td><td class="sec-hdr" colspan="2">Ship To:</td>'
            + rightHdr + '</tr>'
            + '<tr>' + lbl('Account') + td(billAccount) + lbl('Facility') + td(wo.Service_Site_Name__c) + r1 + '</tr>'
            + '<tr>' + lbl('Address') + td(wo.Billing_Street__c) + lbl('Address') + td(wo.Street) + r2 + '</tr>'
            + '<tr>' + lbl('City,State,Zip') + tdRaw(esc(wo.Billing_City__c) + ', ' + esc(stateCode(wo.Billing_State__c)) + ' ' + esc(wo.Billing_Zip_Postal_Code__c))
            + lbl('City,State,Zip') + tdRaw(esc(wo.City) + ', ' + esc(stateCode(wo.State)) + ' ' + esc(wo.PostalCode)) + r3 + '</tr>'
            + '<tr>' + lbl('Contact/Phone:') + '<td></td>' + lbl('Contact/Phone:') + tdRaw(esc(shipName) + ' ' + esc(shipPhone)) + r4 + '</tr>'
            + '<tr>' + lbl('Email') + td(wo.Billing_Email__c) + lbl('Email') + td(shipEmail) + r5 + '</tr>'
            + blockRow
            + '</table>';
    }

    // Orders a Work Order segment and a Product Detail segment for one info-grid row.
    private static String seg(Boolean swapWoPd, String woSeg, String pdSeg) {
        return swapWoPd ? (pdSeg + woSeg) : (woSeg + pdSeg);
    }

    private static String apptBlock(List<ServiceAppointment> appts) {
        String s = '';
        for (ServiceAppointment a : appts) {
            Datetime st = (a.ActualStartTime != null) ? a.ActualStartTime : a.SchedStartTime;
            Datetime en = (a.ActualEndTime   != null) ? a.ActualEndTime   : a.SchedEndTime;
            if (st != null) s += '<div>' + fmtDt(st) + ' - ' + fmtDt(en) + '</div>';
        }
        return s;
    }

    private static String pmHead(String titleLine, String subtitle, Boolean compact) {
        String pageMargin = compact ? '1.0in 0.5in 0.5in 0.5in' : '1.3in 0.5in 0.7in 0.5in';
        String compactCss = compact
            ? 'td, th { padding: 2px 4px; } .divider { height:5px; } .divider-sm { height:3px; }'
            : '';
        String headerRight = (subtitle == null)
            ? '<div class="page-count">Page <span class="pageNumber"></span> of <span class="pageCount"></span></div>'
            : '<div class="title" style="font-size:15px;color:#555;">' + esc(subtitle) + '</div>';
        return '<html><head><style type="text/css">'
            + '@page { size: letter landscape; margin: ' + pageMargin + ';'
            + ' @top-center { content: element(pageHeader); width: 10in; }'
            + ' @bottom-center { content: element(pageFooter); width: 10in; } }'
            + baseCss()
            + '.page-count { font-size:15px; text-align:right; margin-top:4px; font-weight:normal; }'
            + '.wo-type { font-size:13px; text-align:right; margin-top:3px; font-weight:bold; color:#555; }'
            + '.page-header { position: running(pageHeader); width:100%; }'
            + '.pageNumber:before { content: counter(page); }'
            + '.pageCount:before { content: counter(pages); }'
            + '.page-footer { position: running(pageFooter); font-family: Arial, sans-serif; font-size:10px; color:#333; text-align:center; line-height:1.3; }'
            + '.title { font-size:28px; font-weight:bold; color:#0072bc; text-align:right; letter-spacing:1px; }'
            + '.val { text-align:right; padding-right:10px; }'
            + '.col-hdr { font-weight:bold; text-align:center; }'
            + '.sub-hdr { font-weight:bold; text-align:center; }'
            + '.seg-hdr { text-align:center; font-weight:bold; }'
            + '.page2-layout { width:100%; border-collapse:collapse; }'
            + '.page2-layout > tbody > tr > td { border:none; }'
            + '.sig td { border:0.75px solid #000; }'
            + '.sig .hdr { font-size:14px; font-weight:bold; vertical-align:middle; text-align:center; background-color:#f9f9f9; }'
            + '.sig-img { text-align:center; }'
            + '.divider-sm { height:4px; background-color:#000; }'
            + compactCss
            + '</style></head><body>'
            + '<div class="page-header"><table class="hdr-table"><tr>'
            + '<td style="width:45%"><img src="/resource/ProboMedicalInvoiceLogo" width="150"/></td>'
            + '<td style="width:55%; vertical-align:middle;"><div class="title" style="font-size:20px;">' + esc(titleLine) + '</div>'
            + headerRight
            + '</td></tr></table></div>'
            + '<div class="page-footer">5735 Benjamin Center Dr Tampa, FL 33634 | P: 1-866-513-8322 | www.ProboMedical.com<br/>'
            + '&copy; 2026 Probo Medical, LLC. All rights reserved. &nbsp;|&nbsp; ProboMedPMR_Rev062026</div>';
    }

    private static String pmSignatures(ServiceSignatureController.SignatureView eng, ServiceSignatureController.SignatureView cust) {
        return '<table class="sig">'
            + '<colgroup><col style="width:10%"/><col style="width:20%"/><col style="width:6%"/><col style="width:14%"/>'
            + '<col style="width:10%"/><col style="width:20%"/><col style="width:6%"/><col style="width:14%"/></colgroup>'
            + '<tr><td colspan="8" class="hdr">Signatures</td></tr>'
            + '<tr>'
            + '<td class="lbl" style="vertical-align:middle;border-right:none;">Engineer</td>'
            + '<td class="sig-img" style="vertical-align:middle;border-left:none;border-right:none;">' + sigImg(eng) + '<br/>' + esc(sigName(eng)) + '</td>'
            + '<td class="lbl" style="vertical-align:middle;border-left:none;border-right:none;">Date:</td>'
            + '<td style="vertical-align:middle;border-left:none;">' + esc(sigDate(eng)) + '</td>'
            + '<td class="lbl" style="vertical-align:middle;border-right:none;">Customer</td>'
            + '<td class="sig-img" style="vertical-align:middle;border-right:none;border-left:none;">' + sigImg(cust) + '<br/>' + esc(sigName(cust)) + '</td>'
            + '<td class="lbl" style="vertical-align:middle;border-left:none;border-right:none;">Date:</td>'
            + '<td style="vertical-align:middle;border-left:none;">' + esc(sigDate(cust)) + '</td>'
            + '</tr></table>';
    }

    // =====================================================================
    //  Small helpers
    // =====================================================================
    private static String baseCss() {
        return '* { box-sizing: border-box; }'
            + 'body { font-family: Arial, Helvetica, sans-serif; font-size: 12px; color:#000; margin:0; padding:0; }'
            + 'table { border-collapse: collapse; width:100%; }'
            + 'td, th { vertical-align: top; padding: 3px 4px; }'
            + '.hdr-table td { border:none; padding:0; vertical-align:bottom; }'
            + '.grid td { border:0.75px solid #000; }'
            + '.lbl { font-weight:bold; white-space:nowrap; }'
            + '.sec-hdr { font-size:12px; font-weight:bold; text-align:center; background-color:#f9f9f9; border:0.75px solid #000; }'
            + '.parts th, .parts td { border:0.75px solid #000; text-align:left; }'
            + '.parts th { font-weight:bold; text-align:center; }'
            + '.grp-hdr { font-weight:bold; text-align:center; background-color:#f9f9f9; }'
            + '.submsg { font-size:11px; color:#333; }'
            + '.num { text-align:right; } .parts td.num, .parts th.num { text-align:right; }'
            + '.divider { height:8px; background-color:#000; }';
    }

    private static String chk(Maintenance_Item__c m, String field, String label) {
        return '<td style="text-align:center;">' + v(m, field) + '</td><td>' + esc(label) + '</td>';
    }
    private static String v(Maintenance_Item__c m, String f)     { return esc(m == null ? null : m.get(f)); }
    private static String vDate(Maintenance_Item__c m, String f) { return fmtDateVal(m == null ? null : m.get(f)); }

    // Like v(), but renders an empty cell when the picklist value is "No Selection".
    private static String pf(Maintenance_Item__c m, String f) {
        Object o = (m == null) ? null : m.get(f);
        if (o == null) return '';
        String norm = String.valueOf(o).toLowerCase().replaceAll('[^a-z]', '');
        return (norm == 'noselection') ? '' : esc(o);
    }

    private static String lbl(String text)  { return '<td class="lbl">' + esc(text) + '</td>'; }
    private static String td(Object value)  { return '<td>' + esc(value) + '</td>'; }
    private static String tdRaw(String html){ return '<td>' + html + '</td>'; }

    private static String sigImg(ServiceSignatureController.SignatureView vw) {
        return (vw != null && vw.attachmentId != null)
            ? '<img src="/servlet/servlet.FileDownload?file=' + vw.attachmentId + '" width="120" height="32"/>' : '';
    }
    private static String sigName(ServiceSignatureController.SignatureView vw) { return vw == null ? '' : vw.signerName; }
    private static String sigDate(ServiceSignatureController.SignatureView vw) { return vw == null ? '' : vw.signedAtText; }

    private static String esc(Object o) {
        if (o == null) return '';
        return String.valueOf(o).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;');
    }
    private static String money(Decimal d) {
        if (d == null) d = 0;
        return '$' + d.setScale(2, System.RoundingMode.HALF_UP).format();
    }
    private static String num(Decimal d) {
        if (d == null) d = 0;
        return d.setScale(2, System.RoundingMode.HALF_UP).format();
    }
    private static String fmtDt(Datetime d) { return d == null ? '' : d.format('MM/dd/yyyy hh:mm a'); }
    private static String fmtDateVal(Object o) {
        if (o == null) return '';
        if (o instanceof Datetime) return ((Datetime) o).format('MM/dd/yyyy');
        if (o instanceof Date) return ((Date) o).format();
        return String.valueOf(o);
    }

    // Comma-grouped, no decimals (e.g. 1,234) -- blank when null.
    private static String numComma(Maintenance_Item__c m, String f) {
        Object o = (m == null) ? null : m.get(f);
        if (o == null) return '';
        Decimal d;
        try { d = (o instanceof Decimal) ? (Decimal) o : Decimal.valueOf(String.valueOf(o)); }
        catch (Exception e) { return esc(o); }
        return d.setScale(0, System.RoundingMode.HALF_UP).format();
    }

    private static String firstNonBlank(List<String> vals) {
        for (String val : vals) { if (String.isNotBlank(val)) return val; }
        return '';
    }

    // Returns the 2-letter code. Passes through values already 2 chars; maps full
    // state names; returns the original if it can't resolve.
    private static String stateCode(String s) {
        if (String.isBlank(s)) return '';
        String t = s.trim();
        if (t.length() == 2) return t.toUpperCase();
        String code = US_STATES.get(t.toLowerCase());
        return (code != null) ? code : t;
    }

    private static final Map<String, String> US_STATES = new Map<String, String>{
        'alabama'=>'AL','alaska'=>'AK','arizona'=>'AZ','arkansas'=>'AR','california'=>'CA',
        'colorado'=>'CO','connecticut'=>'CT','delaware'=>'DE','district of columbia'=>'DC',
        'florida'=>'FL','georgia'=>'GA','hawaii'=>'HI','idaho'=>'ID','illinois'=>'IL',
        'indiana'=>'IN','iowa'=>'IA','kansas'=>'KS','kentucky'=>'KY','louisiana'=>'LA',
        'maine'=>'ME','maryland'=>'MD','massachusetts'=>'MA','michigan'=>'MI','minnesota'=>'MN',
        'mississippi'=>'MS','missouri'=>'MO','montana'=>'MT','nebraska'=>'NE','nevada'=>'NV',
        'new hampshire'=>'NH','new jersey'=>'NJ','new mexico'=>'NM','new york'=>'NY',
        'north carolina'=>'NC','north dakota'=>'ND','ohio'=>'OH','oklahoma'=>'OK','oregon'=>'OR',
        'pennsylvania'=>'PA','rhode island'=>'RI','south carolina'=>'SC','south dakota'=>'SD',
        'tennessee'=>'TN','texas'=>'TX','utah'=>'UT','vermont'=>'VT','virginia'=>'VA',
        'washington'=>'WA','west virginia'=>'WV','wisconsin'=>'WI','wyoming'=>'WY',
        'puerto rico'=>'PR'
    };

    private static AuraHandledException err(String msg) {
        AuraHandledException e = new AuraHandledException(msg);
        e.setMessage(msg);
        return e;
    }
}