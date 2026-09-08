global class WorkOrderEntryMerge implements schedulable{
    global void execute(SchedulableContext ctx) {
        //get work orders to merge
        Set<String> woNumberSet = new Set<String>();
        
        List<WorkOrder> listWo = [SELECT AccountId, Address, All_chords_and_cables_intact_no_Frays__c, Asset2__c, AssetId, Backup_Preset_and_Network_Settings__c, 
                     Billable_Work_Order__c, Billing_City__c, Billing_State__c, Billing_Status__c, Billing_Street__c, Billing_Zip_Postal_Code__c, 
                     BusinessHoursId, CaseId, Check_2D_PW_Color_Incl_Angio_Power__c, Check_3D_4D__c, Check_CW_Doppler__c, Check_Calibrate_power_supplies__c,
                     Check_Control_Panel_Keyboard__c, Check_ECG_Cable_Signal__c, Check_System_Battery__c, Check_network_functionality__c, Check_optimize_monitor__c, 
                     Check_system_fans__c, Checked_Basic_measurements__c, City, Clean_and_inspect_system_interior__c, Clean_system_filters__c, Clean_system_monitor_touch_panel__c, 
                     Clean_trackball__c, ContactId, Contact_Phone__c, Core_Probe_Serial__c, Core_Probe__c, Core_System_Serial_2__c, Core_System__c, Country, CreatedById, CreatedDate, 
                     Customer_ID__c, //Customer_Signature__c, 
                     Description, Device_Current__c, Discount, Discuss_Customer_Concerns__c, Display_Characteristics_Completed__c, 
                     Duration, DurationInMinutes, DurationType, EndDate, //Engineer_Signature__c, 
                     EntitlementId, Entitlement_Type__c, Error_Code__c, 
                     Field_Service_Engineer__c, GeocodeAccuracy, GrandTotal, Hospital_grade_plug__c, Id, Inspect_accessories_peripherals_for_pro__c,  
                     Installed_Part_Number_1__c, Installed_Part_Number_2__c, Installed_Part_Number_3__c, Installed_Part_Number_4__c, Installed_Part_Number_5__c, Installed_Part_Number_6__c, 
                     Installed_Part_Rev_1__c, Installed_Part_Rev_2__c, Installed_Part_Rev_3__c, Installed_Part_Rev_4__c, Installed_Part_Rev_5__c, Installed_Part_Rev_6__c, Intact_without_cracks_1__c, 
                     Intact_without_cracks_2__c, Intact_without_cracks_3__c, Intact_without_cracks_4__c, Intact_without_cracks_5__c, Intact_without_cracks_6__c, Intact_without_cracks_7__c, 
                     Intact_without_cracks_8__c, IsClosed, IsDeleted, IsStopped, Labor_Date_Time_In__c, Labor_Date_Time_Out__c, Labor_Price__c, LastModifiedById, LastModifiedDate, LastReferencedDate, 
                     LastViewedDate, Latitude, Lead_Isolation_P_F__c, Lead_Isolation_Test_Value__c, Lead_Leakage_P_F__c, Lead_Leakage_Value__c, Leakage_Value_GND_Open_1__c, Leakage_Value_GND_Open_2__c, 
                     Leakage_Value_GND_Open_3__c, Leakage_Value_GND_Open_4__c, Leakage_Value_GND_Open_5__c, Leakage_Value_GND_Open_6__c, Leakage_Value_GND_Open_7__c, Leakage_Value_GND_Open_8__c, LineItemCount, 
                     Line_Voltage__c, LocationId, Longitude, Make_Model__c, MilestoneStatus, Needs_Paid__c, No_Brightness_Transitions_1__c, No_Brightness_Transitions_2__c, No_Brightness_Transitions_3__c, 
                     No_Brightness_Transitions_4__c, No_Brightness_Transitions_5__c, No_Brightness_Transitions_6__c, No_Brightness_Transitions_7__c, No_Brightness_Transitions_8__c, No_Vertical_or_Radical_Shadows_1__c, 
                     No_Vertical_or_Radical_Shadows_2__c, No_Vertical_or_Radical_Shadows_3__c, No_Vertical_or_Radical_Shadows_4__c, No_Vertical_or_Radical_Shadows_5__c, No_Vertical_or_Radical_Shadows_6__c, 
                     No_Vertical_or_Radical_Shadows_7__c, No_Vertical_or_Radical_Shadows_8__c, Normal_Polarity_Test_Ground_Closed__c, Normal_Polarity_Test_Ground_Open__c, Opportunity__c, OwnerId, 
                     PO_Number__c, ParentWorkOrderId, Part_Description_1__c, Part_Description_2__c, Part_Description_3__c, Part_Description_4__c, Part_Description_5__c, Part_Description_6__c, 
                     Part_Installed_Price_1__c, Part_Installed_Price_2__c, Part_Installed_Price_3__c, Part_Installed_Price_4__c, Part_Installed_Price_5__c, Part_Installed_Price_6__c, Part_Installed_Quantity_1__c, 
                     Part_Installed_Quantity_2__c, Part_Installed_Quantity_3__c, Part_Installed_Quantity_4__c, Part_Installed_Quantity_5__c, Part_Installed_Quantity_6__c, Part_Installed_Serial_Number_1__c, 
                     Part_Installed_Serial_Number_2__c, Part_Installed_Serial_Number_3__c, Part_Installed_Serial_Number_4__c, Part_Installed_Serial_Number_5__c, Part_Installed_Serial_Number_6__c,
                     Part_Removed_Quantity_1__c, Part_Removed_Quantity_2__c, Part_Removed_Quantity_3__c, Part_Removed_Quantity_4__c, Part_Removed_Quantity_5__c, Part_Removed_Quantity_6__c, Part_Removed_Serial_Number_1__c, 
                     Part_Removed_Serial_Number_2__c, Part_Removed_Serial_Number_3__c, Part_Removed_Serial_Number_4__c, Part_Removed_Serial_Number_5__c, Part_Removed_Serial_Number_6__c, Parts_Total__c, 
                     Perform_hard_drive_maintenance__c, Person_Requesting_WO_Email__c, Possible_Repairs__c, PostalCode, Power_Cord_Resistance__c, Preliminary_Comments_and_Findings__c, Pricebook2Id, Priority, RMA__c, 
                     RecordTypeId, Removed_Part_Number_1__c, Removed_Part_Number_2__c, Removed_Part_Number_3__c, Removed_Part_Number_4__c, Removed_Part_Number_5__c, Removed_Part_Number_6__c, Removed_Part_Rev_1__c, 
                     Removed_Part_Rev_2__c, Removed_Part_Rev_3__c, Removed_Part_Rev_4__c, Removed_Part_Rev_5__c, Removed_Part_Rev_6__c, Replacement_Probe_Serial__c, Replacement_Probe__c, Replacement_System_Serial__c, 
                     Replacement_System__c, Reported_Symptoms__c, Reverse_Polarity_Test_Ground_Closed__c, Reverse_Polarity_Test_Ground_Open__c, Review_Error_Logs_if_applicable__c, RootWorkOrderId, 
                     Run_System_Diagnostics_if_available__c, Serial_Number__c, ServiceAppointmentCount, ServiceContractId, Service_City__c, Service_Department__c, Service_Facility__c, Service_Report_Number__c, 
                     Service_State_Province__c, Service_Street__c, Service_Zip_Postal_Code__c, SlaExitDate, SlaStartDate, Software__c, Solution_Remarks__c, Special_Instructions__c, StartDate, State, Status, StatusCategory, 
                     StopStartDate, Street, Subject, Subtotal, Symptom_Code__c, SystemModstamp, System_Articulations_monitor_user_inte__c, Tax, Third_Party_Vendor_Cost__c, Third_Party_Vendor_Name__c, Third_Party_Vendor_PO__c, 
                     TotalPrice, Total_Labor__c, Total_Travel__c, Tranducer_Average_Brightness_Same_1__c, Tranducer_Average_Brightness_Same_2__c, Tranducer_Average_Brightness_Same_3__c, Tranducer_Average_Brightness_Same_4__c, 
                     Tranducer_Average_Brightness_Same_5__c, Tranducer_Average_Brightness_Same_6__c, Tranducer_Average_Brightness_Same_7__c, Tranducer_Average_Brightness_Same_8__c, Transducer_Max_Depth_1__c, 
                     Transducer_Max_Depth_2__c, Transducer_Max_Depth_3__c, Transducer_Max_Depth_4__c, Transducer_Max_Depth_5__c, Transducer_Max_Depth_6__c, Transducer_Max_Depth_7__c, Transducer_Max_Depth_8__c, Transducer_Model_1__c, 
                     Transducer_Model_2__c, Transducer_Model_3__c, Transducer_Model_4__c, Transducer_Model_5__c, Transducer_Model_6__c, Transducer_Model_7__c, Transducer_Model_8__c, Transducer_P_F_1__c, Transducer_P_F_2__c, 
                     Transducer_P_F_3__c, Transducer_P_F_4__c, Transducer_P_F_5__c, Transducer_P_F_6__c, Transducer_P_F_7__c, Service_Date__c, Transducer_P_F_8__c, Transducer_S_N_1__c, Transducer_S_N_2__c, Transducer_S_N_3__c, 
                     Transducer_S_N_4__c, Transducer_S_N_5__c, Transducer_S_N_6__c, Transducer_S_N_7__c, Transducer_S_N_8__c, Transducers_cleaned_after_each_use__c, Travel_Date_Time_In__c, Travel_Date_Time_Out__c, 
                     Travel_Price__c, Unit_Inspected_and_tested_per_OEM_servic__c, Verified_Symptoms__c, Verify_Boot_Process__c, Verify_Database__c, Verify_Power_Up__c, Verify_Remote_Diagnostics_if_applicable__c, 
                     Wheel_locks_functional__c, Wheels_securly_attached_and_rotate_prope__c, WorkOrderNumber, Work_Order_Cost__c, Work_Order_PDF_Type__c, Work_Order_Shipping__c, Work_Order_Tax__c, Work_Order_Total__c FROM WorkOrder WHERE Service_Report_Number__c != ''];
        
        system.debug('listwo: '+listwo);        
        for(WorkOrder individualwo:listWo){
            woNumberSet.add(individualwo.Service_Report_Number__c);
        }
        
        List<WorkOrder> mergingwolist = new List<WorkOrder>();
        
        mergingwolist = [Select AccountId, Address, All_chords_and_cables_intact_no_Frays__c, Asset2__c, AssetId, Backup_Preset_and_Network_Settings__c, 
                     Billable_Work_Order__c, Billing_City__c, Billing_State__c, Billing_Status__c, Billing_Street__c, Billing_Zip_Postal_Code__c, 
                     BusinessHoursId, CaseId, Check_2D_PW_Color_Incl_Angio_Power__c, Check_3D_4D__c, Check_CW_Doppler__c, Check_Calibrate_power_supplies__c,
                     Check_Control_Panel_Keyboard__c, Check_ECG_Cable_Signal__c, Check_System_Battery__c, Check_network_functionality__c, Check_optimize_monitor__c, 
                     Check_system_fans__c, Checked_Basic_measurements__c, City, Clean_and_inspect_system_interior__c, Clean_system_filters__c, Clean_system_monitor_touch_panel__c, 
                     Clean_trackball__c, ContactId, Contact_Phone__c, Core_Probe_Serial__c, Core_Probe__c, Core_System_Serial_2__c, Core_System__c, Country, CreatedById, CreatedDate, 
                     Customer_ID__c, //Customer_Signature__c, 
                     Description, Device_Current__c, Discount, Discuss_Customer_Concerns__c, Display_Characteristics_Completed__c, 
                     Duration, DurationInMinutes, DurationType, EndDate, //Engineer_Signature__c, 
                     EntitlementId, Entitlement_Type__c, Error_Code__c, 
                     Field_Service_Engineer__c, GeocodeAccuracy, GrandTotal, Hospital_grade_plug__c, Id, Inspect_accessories_peripherals_for_pro__c,  
                     Installed_Part_Number_1__c, Installed_Part_Number_2__c, Installed_Part_Number_3__c, Installed_Part_Number_4__c, Installed_Part_Number_5__c, Installed_Part_Number_6__c, 
                     Installed_Part_Rev_1__c, Installed_Part_Rev_2__c, Installed_Part_Rev_3__c, Installed_Part_Rev_4__c, Installed_Part_Rev_5__c, Installed_Part_Rev_6__c, Intact_without_cracks_1__c, 
                     Intact_without_cracks_2__c, Intact_without_cracks_3__c, Intact_without_cracks_4__c, Intact_without_cracks_5__c, Intact_without_cracks_6__c, Intact_without_cracks_7__c, 
                     Intact_without_cracks_8__c, IsClosed, IsDeleted, IsStopped, Labor_Date_Time_In__c, Labor_Date_Time_Out__c, Labor_Price__c, LastModifiedById, LastModifiedDate, LastReferencedDate, 
                     LastViewedDate, Latitude, Lead_Isolation_P_F__c, Lead_Isolation_Test_Value__c, Lead_Leakage_P_F__c, Lead_Leakage_Value__c, Leakage_Value_GND_Open_1__c, Leakage_Value_GND_Open_2__c, 
                     Leakage_Value_GND_Open_3__c, Leakage_Value_GND_Open_4__c, Leakage_Value_GND_Open_5__c, Leakage_Value_GND_Open_6__c, Leakage_Value_GND_Open_7__c, Leakage_Value_GND_Open_8__c, LineItemCount, 
                     Line_Voltage__c, LocationId, Longitude, Make_Model__c, MilestoneStatus, Needs_Paid__c, No_Brightness_Transitions_1__c, No_Brightness_Transitions_2__c, No_Brightness_Transitions_3__c, 
                     No_Brightness_Transitions_4__c, No_Brightness_Transitions_5__c, No_Brightness_Transitions_6__c, No_Brightness_Transitions_7__c, No_Brightness_Transitions_8__c, No_Vertical_or_Radical_Shadows_1__c, 
                     No_Vertical_or_Radical_Shadows_2__c, No_Vertical_or_Radical_Shadows_3__c, No_Vertical_or_Radical_Shadows_4__c, No_Vertical_or_Radical_Shadows_5__c, No_Vertical_or_Radical_Shadows_6__c, 
                     No_Vertical_or_Radical_Shadows_7__c, No_Vertical_or_Radical_Shadows_8__c, Normal_Polarity_Test_Ground_Closed__c, Normal_Polarity_Test_Ground_Open__c, Opportunity__c, OwnerId, 
                     PO_Number__c, ParentWorkOrderId, Part_Description_1__c, Part_Description_2__c, Part_Description_3__c, Part_Description_4__c, Part_Description_5__c, Part_Description_6__c, 
                     Part_Installed_Price_1__c, Part_Installed_Price_2__c, Part_Installed_Price_3__c, Part_Installed_Price_4__c, Part_Installed_Price_5__c, Part_Installed_Price_6__c, Part_Installed_Quantity_1__c, 
                     Part_Installed_Quantity_2__c, Part_Installed_Quantity_3__c, Part_Installed_Quantity_4__c, Part_Installed_Quantity_5__c, Part_Installed_Quantity_6__c, Part_Installed_Serial_Number_1__c, 
                     Part_Installed_Serial_Number_2__c, Part_Installed_Serial_Number_3__c, Part_Installed_Serial_Number_4__c, Part_Installed_Serial_Number_5__c, Part_Installed_Serial_Number_6__c,
                     Part_Removed_Quantity_1__c, Part_Removed_Quantity_2__c, Part_Removed_Quantity_3__c, Part_Removed_Quantity_4__c, Part_Removed_Quantity_5__c, Part_Removed_Quantity_6__c, Part_Removed_Serial_Number_1__c, 
                     Part_Removed_Serial_Number_2__c, Part_Removed_Serial_Number_3__c, Part_Removed_Serial_Number_4__c, Part_Removed_Serial_Number_5__c, Part_Removed_Serial_Number_6__c, Parts_Total__c, 
                     Perform_hard_drive_maintenance__c, Person_Requesting_WO_Email__c, Possible_Repairs__c, PostalCode, Power_Cord_Resistance__c, Preliminary_Comments_and_Findings__c, Pricebook2Id, Priority, RMA__c, 
                     RecordTypeId, Removed_Part_Number_1__c, Removed_Part_Number_2__c, Removed_Part_Number_3__c, Removed_Part_Number_4__c, Removed_Part_Number_5__c, Removed_Part_Number_6__c, Removed_Part_Rev_1__c, 
                     Removed_Part_Rev_2__c, Removed_Part_Rev_3__c, Removed_Part_Rev_4__c, Removed_Part_Rev_5__c, Removed_Part_Rev_6__c, Replacement_Probe_Serial__c, Replacement_Probe__c, Replacement_System_Serial__c, 
                     Replacement_System__c, Reported_Symptoms__c, Reverse_Polarity_Test_Ground_Closed__c, Reverse_Polarity_Test_Ground_Open__c, Review_Error_Logs_if_applicable__c, RootWorkOrderId, 
                     Run_System_Diagnostics_if_available__c, Serial_Number__c, ServiceAppointmentCount, ServiceContractId, Service_City__c, Service_Department__c, Service_Facility__c, Service_Report_Number__c, 
                     Service_State_Province__c, Service_Street__c, Service_Zip_Postal_Code__c, SlaExitDate, SlaStartDate, Software__c, Solution_Remarks__c, Special_Instructions__c, StartDate, State, Status, StatusCategory, 
                     StopStartDate, Street, Subject, Subtotal, Symptom_Code__c, SystemModstamp, System_Articulations_monitor_user_inte__c, Tax, Third_Party_Vendor_Cost__c, Third_Party_Vendor_Name__c, Third_Party_Vendor_PO__c, 
                     TotalPrice, Total_Labor__c, Total_Travel__c, Tranducer_Average_Brightness_Same_1__c, Tranducer_Average_Brightness_Same_2__c, Tranducer_Average_Brightness_Same_3__c, Tranducer_Average_Brightness_Same_4__c, 
                     Tranducer_Average_Brightness_Same_5__c, Tranducer_Average_Brightness_Same_6__c, Tranducer_Average_Brightness_Same_7__c, Tranducer_Average_Brightness_Same_8__c, Transducer_Max_Depth_1__c, 
                     Transducer_Max_Depth_2__c, Transducer_Max_Depth_3__c, Transducer_Max_Depth_4__c, Transducer_Max_Depth_5__c, Transducer_Max_Depth_6__c, Transducer_Max_Depth_7__c, Transducer_Max_Depth_8__c, Transducer_Model_1__c, 
                     Transducer_Model_2__c, Transducer_Model_3__c, Transducer_Model_4__c, Transducer_Model_5__c, Transducer_Model_6__c, Service_Date__c, Transducer_Model_7__c, Transducer_Model_8__c, Transducer_P_F_1__c, Transducer_P_F_2__c, 
                     Transducer_P_F_3__c, Transducer_P_F_4__c, Transducer_P_F_5__c, Transducer_P_F_6__c, Transducer_P_F_7__c, Transducer_P_F_8__c, Transducer_S_N_1__c, Transducer_S_N_2__c, Transducer_S_N_3__c, 
                     Transducer_S_N_4__c, Transducer_S_N_5__c, Transducer_S_N_6__c, Transducer_S_N_7__c, Transducer_S_N_8__c, Transducers_cleaned_after_each_use__c, Travel_Date_Time_In__c, Travel_Date_Time_Out__c, 
                     Travel_Price__c, Unit_Inspected_and_tested_per_OEM_servic__c, Verified_Symptoms__c, Verify_Boot_Process__c, Verify_Database__c, Verify_Power_Up__c, Verify_Remote_Diagnostics_if_applicable__c, 
                     Wheel_locks_functional__c, Wheels_securly_attached_and_rotate_prope__c, WorkOrderNumber, Work_Order_Cost__c, Work_Order_PDF_Type__c, Work_Order_Shipping__c, Work_Order_Tax__c, Work_Order_Total__c FROM WorkOrder WHERE WorkOrderNumber IN: woNumberSet];
        
        Map<String,WorkOrder> womergemap = new Map<String,WorkOrder>();
        
        for(WorkOrder individualwo : mergingwolist){
            womergemap.put(individualwo.WorkOrderNumber, individualwo);
        }
        
        for(WorkOrder wo: listWo){
        IF(wo.All_chords_and_cables_intact_no_Frays__c != NULL){womergemap.get(wo.Service_Report_Number__c).All_chords_and_cables_intact_no_Frays__c=wo.All_chords_and_cables_intact_no_Frays__c;}
        IF(wo.Asset2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Asset2__c=wo.Asset2__c;}
        IF(wo.Backup_Preset_and_Network_Settings__c != NULL){womergemap.get(wo.Service_Report_Number__c).Backup_Preset_and_Network_Settings__c=wo.Backup_Preset_and_Network_Settings__c;}
        IF(wo.Billable_Work_Order__c != NULL){womergemap.get(wo.Service_Report_Number__c).Billable_Work_Order__c=wo.Billable_Work_Order__c;}
        IF(wo.Billing_City__c != NULL){womergemap.get(wo.Service_Report_Number__c).Billing_City__c=wo.Billing_City__c;}
        IF(wo.Billing_State__c != NULL){womergemap.get(wo.Service_Report_Number__c).Billing_State__c=wo.Billing_State__c;}
        IF(wo.Billing_Status__c != NULL){womergemap.get(wo.Service_Report_Number__c).Billing_Status__c=wo.Billing_Status__c;}
        IF(wo.Billing_Street__c != NULL){womergemap.get(wo.Service_Report_Number__c).Billing_Street__c=wo.Billing_Street__c;}
        IF(wo.Billing_Zip_Postal_Code__c != NULL){womergemap.get(wo.Service_Report_Number__c).Billing_Zip_Postal_Code__c=wo.Billing_Zip_Postal_Code__c;}
        IF(wo.Check_2D_PW_Color_Incl_Angio_Power__c != NULL){womergemap.get(wo.Service_Report_Number__c).Check_2D_PW_Color_Incl_Angio_Power__c=wo.Check_2D_PW_Color_Incl_Angio_Power__c;}
        IF(wo.Check_3D_4D__c != NULL){womergemap.get(wo.Service_Report_Number__c).Check_3D_4D__c=wo.Check_3D_4D__c;}
        IF(wo.Check_CW_Doppler__c != NULL){womergemap.get(wo.Service_Report_Number__c).Check_CW_Doppler__c=wo.Check_CW_Doppler__c;}
        IF(wo.Check_Calibrate_power_supplies__c != NULL){womergemap.get(wo.Service_Report_Number__c).Check_Calibrate_power_supplies__c=wo.Check_Calibrate_power_supplies__c;}
        IF(wo.Check_Control_Panel_Keyboard__c != NULL){womergemap.get(wo.Service_Report_Number__c).Check_Control_Panel_Keyboard__c=wo.Check_Control_Panel_Keyboard__c;}
        IF(wo.Check_ECG_Cable_Signal__c != NULL){womergemap.get(wo.Service_Report_Number__c).Check_ECG_Cable_Signal__c=wo.Check_ECG_Cable_Signal__c;}
        IF(wo.Check_System_Battery__c != NULL){womergemap.get(wo.Service_Report_Number__c).Check_System_Battery__c=wo.Check_System_Battery__c;}
        IF(wo.Check_network_functionality__c != NULL){womergemap.get(wo.Service_Report_Number__c).Check_network_functionality__c=wo.Check_network_functionality__c;}
        IF(wo.Check_optimize_monitor__c != NULL){womergemap.get(wo.Service_Report_Number__c).Check_optimize_monitor__c=wo.Check_optimize_monitor__c;}
        IF(wo.Check_system_fans__c != NULL){womergemap.get(wo.Service_Report_Number__c).Check_system_fans__c=wo.Check_system_fans__c;}
        IF(wo.Checked_Basic_measurements__c != NULL){womergemap.get(wo.Service_Report_Number__c).Checked_Basic_measurements__c=wo.Checked_Basic_measurements__c;}
        IF(wo.City != NULL){womergemap.get(wo.Service_Report_Number__c).City=wo.City;}
        IF(wo.Clean_and_inspect_system_interior__c != NULL){womergemap.get(wo.Service_Report_Number__c).Clean_and_inspect_system_interior__c=wo.Clean_and_inspect_system_interior__c;}
        IF(wo.Clean_system_filters__c != NULL){womergemap.get(wo.Service_Report_Number__c).Clean_system_filters__c=wo.Clean_system_filters__c;}
        IF(wo.Clean_system_monitor_touch_panel__c != NULL){womergemap.get(wo.Service_Report_Number__c).Clean_system_monitor_touch_panel__c=wo.Clean_system_monitor_touch_panel__c;}
        IF(wo.Clean_trackball__c != NULL){womergemap.get(wo.Service_Report_Number__c).Clean_trackball__c=wo.Clean_trackball__c;}
        IF(wo.Contact_Phone__c != NULL){womergemap.get(wo.Service_Report_Number__c).Contact_Phone__c=wo.Contact_Phone__c;}
        IF(wo.Core_Probe_Serial__c != NULL){womergemap.get(wo.Service_Report_Number__c).Core_Probe_Serial__c=wo.Core_Probe_Serial__c;}
        IF(wo.Core_Probe__c != NULL){womergemap.get(wo.Service_Report_Number__c).Core_Probe__c=wo.Core_Probe__c;}
        IF(wo.Core_System_Serial_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Core_System_Serial_2__c=wo.Core_System_Serial_2__c;}
        IF(wo.Core_System__c != NULL){womergemap.get(wo.Service_Report_Number__c).Core_System__c=wo.Core_System__c;}
        IF(wo.Country != NULL){womergemap.get(wo.Service_Report_Number__c).Country=wo.Country;}
        IF(wo.Customer_ID__c != NULL){womergemap.get(wo.Service_Report_Number__c).Customer_ID__c=wo.Customer_ID__c;}
        //IF(wo.Customer_Signature__c != NULL){womergemap.get(wo.Service_Report_Number__c).Customer_Signature__c=wo.Customer_Signature__c;}
        IF(wo.Description != NULL){womergemap.get(wo.Service_Report_Number__c).Description=wo.Description;}
        IF(wo.Device_Current__c != NULL){womergemap.get(wo.Service_Report_Number__c).Device_Current__c=wo.Device_Current__c;}
        IF(wo.Discuss_Customer_Concerns__c != NULL){womergemap.get(wo.Service_Report_Number__c).Discuss_Customer_Concerns__c=wo.Discuss_Customer_Concerns__c;}
        IF(wo.Display_Characteristics_Completed__c != NULL){womergemap.get(wo.Service_Report_Number__c).Display_Characteristics_Completed__c=wo.Display_Characteristics_Completed__c;}
        IF(wo.Duration != NULL){womergemap.get(wo.Service_Report_Number__c).Duration=wo.Duration;}
        IF(wo.DurationType != NULL){womergemap.get(wo.Service_Report_Number__c).DurationType=wo.DurationType;}
        IF(wo.EndDate != NULL){womergemap.get(wo.Service_Report_Number__c).EndDate=wo.EndDate;}
        //IF(wo.Engineer_Signature__c != NULL){womergemap.get(wo.Service_Report_Number__c).Engineer_Signature__c=wo.Engineer_Signature__c;}
        IF(wo.Entitlement_Type__c != NULL){womergemap.get(wo.Service_Report_Number__c).Entitlement_Type__c=wo.Entitlement_Type__c;}
        IF(wo.Error_Code__c != NULL){womergemap.get(wo.Service_Report_Number__c).Error_Code__c=wo.Error_Code__c;}
        IF(wo.Field_Service_Engineer__c != NULL){womergemap.get(wo.Service_Report_Number__c).Field_Service_Engineer__c=wo.Field_Service_Engineer__c;}
        IF(wo.GeocodeAccuracy != NULL){womergemap.get(wo.Service_Report_Number__c).GeocodeAccuracy=wo.GeocodeAccuracy;}
        IF(wo.Hospital_grade_plug__c != NULL){womergemap.get(wo.Service_Report_Number__c).Hospital_grade_plug__c=wo.Hospital_grade_plug__c;}
        IF(wo.Inspect_accessories_peripherals_for_pro__c != NULL){womergemap.get(wo.Service_Report_Number__c).Inspect_accessories_peripherals_for_pro__c=wo.Inspect_accessories_peripherals_for_pro__c;}
        IF(wo.Installed_Part_Number_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).Installed_Part_Number_1__c=wo.Installed_Part_Number_1__c;}
        IF(wo.Installed_Part_Number_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Installed_Part_Number_2__c=wo.Installed_Part_Number_2__c;}
        IF(wo.Installed_Part_Number_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).Installed_Part_Number_3__c=wo.Installed_Part_Number_3__c;}
        IF(wo.Installed_Part_Number_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).Installed_Part_Number_4__c=wo.Installed_Part_Number_4__c;}
        IF(wo.Installed_Part_Number_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).Installed_Part_Number_5__c=wo.Installed_Part_Number_5__c;}
        IF(wo.Installed_Part_Number_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).Installed_Part_Number_6__c=wo.Installed_Part_Number_6__c;}
        IF(wo.Installed_Part_Rev_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).Installed_Part_Rev_1__c=wo.Installed_Part_Rev_1__c;}
        IF(wo.Installed_Part_Rev_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Installed_Part_Rev_2__c=wo.Installed_Part_Rev_2__c;}
        IF(wo.Installed_Part_Rev_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).Installed_Part_Rev_3__c=wo.Installed_Part_Rev_3__c;}
        IF(wo.Installed_Part_Rev_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).Installed_Part_Rev_4__c=wo.Installed_Part_Rev_4__c;}
        IF(wo.Installed_Part_Rev_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).Installed_Part_Rev_5__c=wo.Installed_Part_Rev_5__c;}
        IF(wo.Installed_Part_Rev_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).Installed_Part_Rev_6__c=wo.Installed_Part_Rev_6__c;}
        IF(wo.Intact_without_cracks_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).Intact_without_cracks_1__c=wo.Intact_without_cracks_1__c;}
        IF(wo.Intact_without_cracks_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Intact_without_cracks_2__c=wo.Intact_without_cracks_2__c;}
        IF(wo.Intact_without_cracks_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).Intact_without_cracks_3__c=wo.Intact_without_cracks_3__c;}
        IF(wo.Intact_without_cracks_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).Intact_without_cracks_4__c=wo.Intact_without_cracks_4__c;}
        IF(wo.Intact_without_cracks_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).Intact_without_cracks_5__c=wo.Intact_without_cracks_5__c;}
        IF(wo.Intact_without_cracks_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).Intact_without_cracks_6__c=wo.Intact_without_cracks_6__c;}
        IF(wo.Intact_without_cracks_7__c != NULL){womergemap.get(wo.Service_Report_Number__c).Intact_without_cracks_7__c=wo.Intact_without_cracks_7__c;}
        IF(wo.Intact_without_cracks_8__c != NULL){womergemap.get(wo.Service_Report_Number__c).Intact_without_cracks_8__c=wo.Intact_without_cracks_8__c;}
        IF(wo.Labor_Date_Time_In__c != NULL){womergemap.get(wo.Service_Report_Number__c).Labor_Date_Time_In__c=wo.Labor_Date_Time_In__c;}
        IF(wo.Labor_Date_Time_Out__c != NULL){womergemap.get(wo.Service_Report_Number__c).Labor_Date_Time_Out__c=wo.Labor_Date_Time_Out__c;}
        IF(wo.Labor_Price__c != NULL){womergemap.get(wo.Service_Report_Number__c).Labor_Price__c=wo.Labor_Price__c;}
        IF(wo.Lead_Isolation_P_F__c != NULL){womergemap.get(wo.Service_Report_Number__c).Lead_Isolation_P_F__c=wo.Lead_Isolation_P_F__c;}
        IF(wo.Lead_Isolation_Test_Value__c != NULL){womergemap.get(wo.Service_Report_Number__c).Lead_Isolation_Test_Value__c=wo.Lead_Isolation_Test_Value__c;}
        IF(wo.Lead_Leakage_P_F__c != NULL){womergemap.get(wo.Service_Report_Number__c).Lead_Leakage_P_F__c=wo.Lead_Leakage_P_F__c;}
        IF(wo.Lead_Leakage_Value__c != NULL){womergemap.get(wo.Service_Report_Number__c).Lead_Leakage_Value__c=wo.Lead_Leakage_Value__c;}
        IF(wo.Leakage_Value_GND_Open_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).Leakage_Value_GND_Open_1__c=wo.Leakage_Value_GND_Open_1__c;}
        IF(wo.Leakage_Value_GND_Open_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Leakage_Value_GND_Open_2__c=wo.Leakage_Value_GND_Open_2__c;}
        IF(wo.Leakage_Value_GND_Open_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).Leakage_Value_GND_Open_3__c=wo.Leakage_Value_GND_Open_3__c;}
        IF(wo.Leakage_Value_GND_Open_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).Leakage_Value_GND_Open_4__c=wo.Leakage_Value_GND_Open_4__c;}
        IF(wo.Leakage_Value_GND_Open_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).Leakage_Value_GND_Open_5__c=wo.Leakage_Value_GND_Open_5__c;}
        IF(wo.Leakage_Value_GND_Open_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).Leakage_Value_GND_Open_6__c=wo.Leakage_Value_GND_Open_6__c;}
        IF(wo.Leakage_Value_GND_Open_7__c != NULL){womergemap.get(wo.Service_Report_Number__c).Leakage_Value_GND_Open_7__c=wo.Leakage_Value_GND_Open_7__c;}
        IF(wo.Leakage_Value_GND_Open_8__c != NULL){womergemap.get(wo.Service_Report_Number__c).Leakage_Value_GND_Open_8__c=wo.Leakage_Value_GND_Open_8__c;}
        IF(wo.Longitude != NULL){womergemap.get(wo.Service_Report_Number__c).Longitude=wo.Longitude;}
        IF(wo.Make_Model__c != NULL){womergemap.get(wo.Service_Report_Number__c).Make_Model__c=wo.Make_Model__c;}
        IF(wo.No_Brightness_Transitions_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).No_Brightness_Transitions_1__c=wo.No_Brightness_Transitions_1__c;}
        IF(wo.No_Brightness_Transitions_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).No_Brightness_Transitions_2__c=wo.No_Brightness_Transitions_2__c;}
        IF(wo.No_Brightness_Transitions_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).No_Brightness_Transitions_3__c=wo.No_Brightness_Transitions_3__c;}
        IF(wo.No_Brightness_Transitions_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).No_Brightness_Transitions_4__c=wo.No_Brightness_Transitions_4__c;}
        IF(wo.No_Brightness_Transitions_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).No_Brightness_Transitions_5__c=wo.No_Brightness_Transitions_5__c;}
        IF(wo.No_Brightness_Transitions_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).No_Brightness_Transitions_6__c=wo.No_Brightness_Transitions_6__c;}
        IF(wo.No_Brightness_Transitions_7__c != NULL){womergemap.get(wo.Service_Report_Number__c).No_Brightness_Transitions_7__c=wo.No_Brightness_Transitions_7__c;}
        IF(wo.No_Brightness_Transitions_8__c != NULL){womergemap.get(wo.Service_Report_Number__c).No_Brightness_Transitions_8__c=wo.No_Brightness_Transitions_8__c;}
        IF(wo.No_Vertical_or_Radical_Shadows_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).No_Vertical_or_Radical_Shadows_1__c=wo.No_Vertical_or_Radical_Shadows_1__c;}
        IF(wo.No_Vertical_or_Radical_Shadows_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).No_Vertical_or_Radical_Shadows_2__c=wo.No_Vertical_or_Radical_Shadows_2__c;}
        IF(wo.No_Vertical_or_Radical_Shadows_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).No_Vertical_or_Radical_Shadows_3__c=wo.No_Vertical_or_Radical_Shadows_3__c;}
        IF(wo.No_Vertical_or_Radical_Shadows_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).No_Vertical_or_Radical_Shadows_4__c=wo.No_Vertical_or_Radical_Shadows_4__c;}
        IF(wo.No_Vertical_or_Radical_Shadows_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).No_Vertical_or_Radical_Shadows_5__c=wo.No_Vertical_or_Radical_Shadows_5__c;}
        IF(wo.No_Vertical_or_Radical_Shadows_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).No_Vertical_or_Radical_Shadows_6__c=wo.No_Vertical_or_Radical_Shadows_6__c;}
        IF(wo.No_Vertical_or_Radical_Shadows_7__c != NULL){womergemap.get(wo.Service_Report_Number__c).No_Vertical_or_Radical_Shadows_7__c=wo.No_Vertical_or_Radical_Shadows_7__c;}
        IF(wo.No_Vertical_or_Radical_Shadows_8__c != NULL){womergemap.get(wo.Service_Report_Number__c).No_Vertical_or_Radical_Shadows_8__c=wo.No_Vertical_or_Radical_Shadows_8__c;}
        IF(wo.Normal_Polarity_Test_Ground_Closed__c != NULL){womergemap.get(wo.Service_Report_Number__c).Normal_Polarity_Test_Ground_Closed__c=wo.Normal_Polarity_Test_Ground_Closed__c;}
        IF(wo.Normal_Polarity_Test_Ground_Open__c != NULL){womergemap.get(wo.Service_Report_Number__c).Normal_Polarity_Test_Ground_Open__c=wo.Normal_Polarity_Test_Ground_Open__c;}
        IF(wo.Opportunity__c != NULL){womergemap.get(wo.Service_Report_Number__c).Opportunity__c=wo.Opportunity__c;}
        IF(wo.PO_Number__c != NULL){womergemap.get(wo.Service_Report_Number__c).PO_Number__c=wo.PO_Number__c;}
        IF(wo.Part_Description_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Description_1__c=wo.Part_Description_1__c;}
        IF(wo.Part_Description_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Description_2__c=wo.Part_Description_2__c;}
        IF(wo.Part_Description_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Description_3__c=wo.Part_Description_3__c;}
        IF(wo.Part_Description_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Description_4__c=wo.Part_Description_4__c;}
        IF(wo.Part_Description_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Description_5__c=wo.Part_Description_5__c;}
        IF(wo.Part_Description_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Description_6__c=wo.Part_Description_6__c;}
        IF(wo.Part_Installed_Price_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Installed_Price_1__c=wo.Part_Installed_Price_1__c;}
        IF(wo.Part_Installed_Price_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Installed_Price_2__c=wo.Part_Installed_Price_2__c;}
        IF(wo.Part_Installed_Price_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Installed_Price_3__c=wo.Part_Installed_Price_3__c;}
        IF(wo.Part_Installed_Price_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Installed_Price_4__c=wo.Part_Installed_Price_4__c;}
        IF(wo.Part_Installed_Price_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Installed_Price_5__c=wo.Part_Installed_Price_5__c;}
        IF(wo.Part_Installed_Price_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Installed_Price_6__c=wo.Part_Installed_Price_6__c;}
        IF(wo.Part_Installed_Quantity_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Installed_Quantity_1__c=wo.Part_Installed_Quantity_1__c;}
        IF(wo.Part_Installed_Quantity_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Installed_Quantity_2__c=wo.Part_Installed_Quantity_2__c;}
        IF(wo.Part_Installed_Quantity_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Installed_Quantity_3__c=wo.Part_Installed_Quantity_3__c;}
        IF(wo.Part_Installed_Quantity_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Installed_Quantity_4__c=wo.Part_Installed_Quantity_4__c;}
        IF(wo.Part_Installed_Quantity_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Installed_Quantity_5__c=wo.Part_Installed_Quantity_5__c;}
        IF(wo.Part_Installed_Quantity_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Installed_Quantity_6__c=wo.Part_Installed_Quantity_6__c;}
        IF(wo.Part_Installed_Serial_Number_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Installed_Serial_Number_1__c=wo.Part_Installed_Serial_Number_1__c;}
        IF(wo.Part_Installed_Serial_Number_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Installed_Serial_Number_2__c=wo.Part_Installed_Serial_Number_2__c;}
        IF(wo.Part_Installed_Serial_Number_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Installed_Serial_Number_3__c=wo.Part_Installed_Serial_Number_3__c;}
        IF(wo.Part_Installed_Serial_Number_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Installed_Serial_Number_4__c=wo.Part_Installed_Serial_Number_4__c;}
        IF(wo.Part_Installed_Serial_Number_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Installed_Serial_Number_5__c=wo.Part_Installed_Serial_Number_5__c;}
        IF(wo.Part_Installed_Serial_Number_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Installed_Serial_Number_6__c=wo.Part_Installed_Serial_Number_6__c;}
        IF(wo.Part_Removed_Quantity_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Removed_Quantity_1__c=wo.Part_Removed_Quantity_1__c;}
        IF(wo.Part_Removed_Quantity_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Removed_Quantity_2__c=wo.Part_Removed_Quantity_2__c;}
        IF(wo.Part_Removed_Quantity_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Removed_Quantity_3__c=wo.Part_Removed_Quantity_3__c;}
        IF(wo.Part_Removed_Quantity_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Removed_Quantity_4__c=wo.Part_Removed_Quantity_4__c;}
        IF(wo.Part_Removed_Quantity_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Removed_Quantity_5__c=wo.Part_Removed_Quantity_5__c;}
        IF(wo.Part_Removed_Quantity_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Removed_Quantity_6__c=wo.Part_Removed_Quantity_6__c;}
        IF(wo.Part_Removed_Serial_Number_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Removed_Serial_Number_1__c=wo.Part_Removed_Serial_Number_1__c;}
        IF(wo.Part_Removed_Serial_Number_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Removed_Serial_Number_2__c=wo.Part_Removed_Serial_Number_2__c;}
        IF(wo.Part_Removed_Serial_Number_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Removed_Serial_Number_3__c=wo.Part_Removed_Serial_Number_3__c;}
        IF(wo.Part_Removed_Serial_Number_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Removed_Serial_Number_4__c=wo.Part_Removed_Serial_Number_4__c;}
        IF(wo.Part_Removed_Serial_Number_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Removed_Serial_Number_5__c=wo.Part_Removed_Serial_Number_5__c;}
        IF(wo.Part_Removed_Serial_Number_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).Part_Removed_Serial_Number_6__c=wo.Part_Removed_Serial_Number_6__c;}
        IF(wo.Parts_Total__c != NULL){womergemap.get(wo.Service_Report_Number__c).Parts_Total__c=wo.Parts_Total__c;}
        IF(wo.Perform_hard_drive_maintenance__c != NULL){womergemap.get(wo.Service_Report_Number__c).Perform_hard_drive_maintenance__c=wo.Perform_hard_drive_maintenance__c;}
        IF(wo.Person_Requesting_WO_Email__c != NULL){womergemap.get(wo.Service_Report_Number__c).Person_Requesting_WO_Email__c=wo.Person_Requesting_WO_Email__c;}
        IF(wo.Possible_Repairs__c != NULL){womergemap.get(wo.Service_Report_Number__c).Possible_Repairs__c=wo.Possible_Repairs__c;}
        IF(wo.PostalCode != NULL){womergemap.get(wo.Service_Report_Number__c).PostalCode=wo.PostalCode;}
        IF(wo.Power_Cord_Resistance__c != NULL){womergemap.get(wo.Service_Report_Number__c).Power_Cord_Resistance__c=wo.Power_Cord_Resistance__c;}
        IF(wo.Preliminary_Comments_and_Findings__c != NULL){womergemap.get(wo.Service_Report_Number__c).Preliminary_Comments_and_Findings__c=wo.Preliminary_Comments_and_Findings__c;}
        IF(wo.Priority != NULL){womergemap.get(wo.Service_Report_Number__c).Priority=wo.Priority;}
        IF(wo.RMA__c != NULL){womergemap.get(wo.Service_Report_Number__c).RMA__c=wo.RMA__c;}
        IF(wo.Removed_Part_Number_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).Removed_Part_Number_1__c=wo.Removed_Part_Number_1__c;}
        IF(wo.Removed_Part_Number_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Removed_Part_Number_2__c=wo.Removed_Part_Number_2__c;}
        IF(wo.Removed_Part_Number_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).Removed_Part_Number_3__c=wo.Removed_Part_Number_3__c;}
        IF(wo.Removed_Part_Number_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).Removed_Part_Number_4__c=wo.Removed_Part_Number_4__c;}
        IF(wo.Removed_Part_Number_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).Removed_Part_Number_5__c=wo.Removed_Part_Number_5__c;}
        IF(wo.Removed_Part_Number_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).Removed_Part_Number_6__c=wo.Removed_Part_Number_6__c;}
        IF(wo.Removed_Part_Rev_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).Removed_Part_Rev_1__c=wo.Removed_Part_Rev_1__c;}
        IF(wo.Removed_Part_Rev_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Removed_Part_Rev_2__c=wo.Removed_Part_Rev_2__c;}
        IF(wo.Removed_Part_Rev_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).Removed_Part_Rev_3__c=wo.Removed_Part_Rev_3__c;}
        IF(wo.Removed_Part_Rev_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).Removed_Part_Rev_4__c=wo.Removed_Part_Rev_4__c;}
        IF(wo.Removed_Part_Rev_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).Removed_Part_Rev_5__c=wo.Removed_Part_Rev_5__c;}
        IF(wo.Removed_Part_Rev_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).Removed_Part_Rev_6__c=wo.Removed_Part_Rev_6__c;}
        IF(wo.Replacement_Probe_Serial__c != NULL){womergemap.get(wo.Service_Report_Number__c).Replacement_Probe_Serial__c=wo.Replacement_Probe_Serial__c;}
        IF(wo.Replacement_Probe__c != NULL){womergemap.get(wo.Service_Report_Number__c).Replacement_Probe__c=wo.Replacement_Probe__c;}
        IF(wo.Replacement_System_Serial__c != NULL){womergemap.get(wo.Service_Report_Number__c).Replacement_System_Serial__c=wo.Replacement_System_Serial__c;}
        IF(wo.Replacement_System__c != NULL){womergemap.get(wo.Service_Report_Number__c).Replacement_System__c=wo.Replacement_System__c;}
        IF(wo.Reported_Symptoms__c != NULL){womergemap.get(wo.Service_Report_Number__c).Reported_Symptoms__c=wo.Reported_Symptoms__c;}
        IF(wo.Reverse_Polarity_Test_Ground_Closed__c != NULL){womergemap.get(wo.Service_Report_Number__c).Reverse_Polarity_Test_Ground_Closed__c=wo.Reverse_Polarity_Test_Ground_Closed__c;}
        IF(wo.Reverse_Polarity_Test_Ground_Open__c != NULL){womergemap.get(wo.Service_Report_Number__c).Reverse_Polarity_Test_Ground_Open__c=wo.Reverse_Polarity_Test_Ground_Open__c;}
        IF(wo.Review_Error_Logs_if_applicable__c != NULL){womergemap.get(wo.Service_Report_Number__c).Review_Error_Logs_if_applicable__c=wo.Review_Error_Logs_if_applicable__c;}
        IF(wo.Run_System_Diagnostics_if_available__c != NULL){womergemap.get(wo.Service_Report_Number__c).Run_System_Diagnostics_if_available__c=wo.Run_System_Diagnostics_if_available__c;}
        IF(wo.Serial_Number__c != NULL){womergemap.get(wo.Service_Report_Number__c).Serial_Number__c=wo.Serial_Number__c;}
        IF(wo.Service_City__c != NULL){womergemap.get(wo.Service_Report_Number__c).Service_City__c=wo.Service_City__c;}
        IF(wo.Service_Date__c != NULL){womergemap.get(wo.Service_Report_Number__c).Service_Date__c=wo.Service_Date__c;}
        IF(wo.Service_Department__c != NULL){womergemap.get(wo.Service_Report_Number__c).Service_Department__c=wo.Service_Department__c;}
        IF(wo.Service_Facility__c != NULL){womergemap.get(wo.Service_Report_Number__c).Service_Facility__c=wo.Service_Facility__c;}
        IF(wo.Service_Report_Number__c != NULL){womergemap.get(wo.Service_Report_Number__c).Service_Report_Number__c=wo.Service_Report_Number__c;}
        IF(wo.Service_State_Province__c != NULL){womergemap.get(wo.Service_Report_Number__c).Service_State_Province__c=wo.Service_State_Province__c;}
        IF(wo.Service_Street__c != NULL){womergemap.get(wo.Service_Report_Number__c).Service_Street__c=wo.Service_Street__c;}
        IF(wo.Service_Zip_Postal_Code__c != NULL){womergemap.get(wo.Service_Report_Number__c).Service_Zip_Postal_Code__c=wo.Service_Zip_Postal_Code__c;}
        IF(wo.Software__c != NULL){womergemap.get(wo.Service_Report_Number__c).Software__c=wo.Software__c;}
        IF(wo.Solution_Remarks__c != NULL){womergemap.get(wo.Service_Report_Number__c).Solution_Remarks__c=wo.Solution_Remarks__c;}
        IF(wo.Special_Instructions__c != NULL){womergemap.get(wo.Service_Report_Number__c).Special_Instructions__c=wo.Special_Instructions__c;}
        IF(wo.StartDate != NULL){womergemap.get(wo.Service_Report_Number__c).StartDate=wo.StartDate;}
        IF(wo.State != NULL){womergemap.get(wo.Service_Report_Number__c).State=wo.State;}
        IF(wo.Status != NULL){womergemap.get(wo.Service_Report_Number__c).Status=wo.Status;}
        IF(wo.Subject != NULL){womergemap.get(wo.Service_Report_Number__c).Subject=wo.Subject;}
        IF(wo.Tax != NULL){womergemap.get(wo.Service_Report_Number__c).Tax=wo.Tax;}
        IF(wo.Third_Party_Vendor_Cost__c != NULL){womergemap.get(wo.Service_Report_Number__c).Third_Party_Vendor_Cost__c=wo.Third_Party_Vendor_Cost__c;}
        IF(wo.Third_Party_Vendor_Name__c != NULL){womergemap.get(wo.Service_Report_Number__c).Third_Party_Vendor_Name__c=wo.Third_Party_Vendor_Name__c;}
        IF(wo.Third_Party_Vendor_PO__c != NULL){womergemap.get(wo.Service_Report_Number__c).Third_Party_Vendor_PO__c=wo.Third_Party_Vendor_PO__c;}
        IF(wo.Total_Travel__c != NULL){womergemap.get(wo.Service_Report_Number__c).Total_Travel__c=wo.Total_Travel__c;}
        IF(wo.Tranducer_Average_Brightness_Same_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).Tranducer_Average_Brightness_Same_1__c=wo.Tranducer_Average_Brightness_Same_1__c;}
        IF(wo.Tranducer_Average_Brightness_Same_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Tranducer_Average_Brightness_Same_2__c=wo.Tranducer_Average_Brightness_Same_2__c;}
        IF(wo.Tranducer_Average_Brightness_Same_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).Tranducer_Average_Brightness_Same_3__c=wo.Tranducer_Average_Brightness_Same_3__c;}
        IF(wo.Tranducer_Average_Brightness_Same_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).Tranducer_Average_Brightness_Same_4__c=wo.Tranducer_Average_Brightness_Same_4__c;}
        IF(wo.Tranducer_Average_Brightness_Same_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).Tranducer_Average_Brightness_Same_5__c=wo.Tranducer_Average_Brightness_Same_5__c;}
        IF(wo.Tranducer_Average_Brightness_Same_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).Tranducer_Average_Brightness_Same_6__c=wo.Tranducer_Average_Brightness_Same_6__c;}
        IF(wo.Tranducer_Average_Brightness_Same_7__c != NULL){womergemap.get(wo.Service_Report_Number__c).Tranducer_Average_Brightness_Same_7__c=wo.Tranducer_Average_Brightness_Same_7__c;}
        IF(wo.Tranducer_Average_Brightness_Same_8__c != NULL){womergemap.get(wo.Service_Report_Number__c).Tranducer_Average_Brightness_Same_8__c=wo.Tranducer_Average_Brightness_Same_8__c;}
        IF(wo.Transducer_Max_Depth_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_Max_Depth_1__c=wo.Transducer_Max_Depth_1__c;}
        IF(wo.Transducer_Max_Depth_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_Max_Depth_2__c=wo.Transducer_Max_Depth_2__c;}
        IF(wo.Transducer_Max_Depth_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_Max_Depth_3__c=wo.Transducer_Max_Depth_3__c;}
        IF(wo.Transducer_Max_Depth_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_Max_Depth_4__c=wo.Transducer_Max_Depth_4__c;}
        IF(wo.Transducer_Max_Depth_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_Max_Depth_5__c=wo.Transducer_Max_Depth_5__c;}
        IF(wo.Transducer_Max_Depth_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_Max_Depth_6__c=wo.Transducer_Max_Depth_6__c;}
        IF(wo.Transducer_Max_Depth_7__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_Max_Depth_7__c=wo.Transducer_Max_Depth_7__c;}
        IF(wo.Transducer_Max_Depth_8__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_Max_Depth_8__c=wo.Transducer_Max_Depth_8__c;}
        IF(wo.Transducer_Model_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_Model_1__c=wo.Transducer_Model_1__c;}
        IF(wo.Transducer_Model_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_Model_2__c=wo.Transducer_Model_2__c;}
        IF(wo.Transducer_Model_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_Model_3__c=wo.Transducer_Model_3__c;}
        IF(wo.Transducer_Model_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_Model_4__c=wo.Transducer_Model_4__c;}
        IF(wo.Transducer_Model_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_Model_5__c=wo.Transducer_Model_5__c;}
        IF(wo.Transducer_Model_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_Model_6__c=wo.Transducer_Model_6__c;}
        IF(wo.Transducer_Model_7__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_Model_7__c=wo.Transducer_Model_7__c;}
        IF(wo.Transducer_Model_8__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_Model_8__c=wo.Transducer_Model_8__c;}
        IF(wo.Transducer_P_F_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_P_F_1__c=wo.Transducer_P_F_1__c;}
        IF(wo.Transducer_P_F_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_P_F_2__c=wo.Transducer_P_F_2__c;}
        IF(wo.Transducer_P_F_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_P_F_3__c=wo.Transducer_P_F_3__c;}
        IF(wo.Transducer_P_F_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_P_F_4__c=wo.Transducer_P_F_4__c;}
        IF(wo.Transducer_P_F_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_P_F_5__c=wo.Transducer_P_F_5__c;}
        IF(wo.Transducer_P_F_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_P_F_6__c=wo.Transducer_P_F_6__c;}
        IF(wo.Transducer_P_F_7__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_P_F_7__c=wo.Transducer_P_F_7__c;}
        IF(wo.Transducer_P_F_8__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_P_F_8__c=wo.Transducer_P_F_8__c;}
        IF(wo.Transducer_S_N_1__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_S_N_1__c=wo.Transducer_S_N_1__c;}
        IF(wo.Transducer_S_N_2__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_S_N_2__c=wo.Transducer_S_N_2__c;}
        IF(wo.Transducer_S_N_3__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_S_N_3__c=wo.Transducer_S_N_3__c;}
        IF(wo.Transducer_S_N_4__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_S_N_4__c=wo.Transducer_S_N_4__c;}
        IF(wo.Transducer_S_N_5__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_S_N_5__c=wo.Transducer_S_N_5__c;}
        IF(wo.Transducer_S_N_6__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_S_N_6__c=wo.Transducer_S_N_6__c;}
        IF(wo.Transducer_S_N_7__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_S_N_7__c=wo.Transducer_S_N_7__c;}
        IF(wo.Transducer_S_N_8__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducer_S_N_8__c=wo.Transducer_S_N_8__c;}
        IF(wo.Transducers_cleaned_after_each_use__c != NULL){womergemap.get(wo.Service_Report_Number__c).Transducers_cleaned_after_each_use__c=wo.Transducers_cleaned_after_each_use__c;}
        IF(wo.Travel_Date_Time_In__c != NULL){womergemap.get(wo.Service_Report_Number__c).Travel_Date_Time_In__c=wo.Travel_Date_Time_In__c;}
        IF(wo.Travel_Date_Time_Out__c != NULL){womergemap.get(wo.Service_Report_Number__c).Travel_Date_Time_Out__c=wo.Travel_Date_Time_Out__c;}
        IF(wo.Travel_Price__c != NULL){womergemap.get(wo.Service_Report_Number__c).Travel_Price__c=wo.Travel_Price__c;}
        IF(wo.Unit_Inspected_and_tested_per_OEM_servic__c != NULL){womergemap.get(wo.Service_Report_Number__c).Unit_Inspected_and_tested_per_OEM_servic__c=wo.Unit_Inspected_and_tested_per_OEM_servic__c;}
        IF(wo.Verified_Symptoms__c != NULL){womergemap.get(wo.Service_Report_Number__c).Verified_Symptoms__c=wo.Verified_Symptoms__c;}
        IF(wo.Verify_Boot_Process__c != NULL){womergemap.get(wo.Service_Report_Number__c).Verify_Boot_Process__c=wo.Verify_Boot_Process__c;}
        IF(wo.Verify_Database__c != NULL){womergemap.get(wo.Service_Report_Number__c).Verify_Database__c=wo.Verify_Database__c;}
        IF(wo.Verify_Power_Up__c != NULL){womergemap.get(wo.Service_Report_Number__c).Verify_Power_Up__c=wo.Verify_Power_Up__c;}
        IF(wo.Verify_Remote_Diagnostics_if_applicable__c != NULL){womergemap.get(wo.Service_Report_Number__c).Verify_Remote_Diagnostics_if_applicable__c=wo.Verify_Remote_Diagnostics_if_applicable__c;}
        IF(wo.Wheel_locks_functional__c != NULL){womergemap.get(wo.Service_Report_Number__c).Wheel_locks_functional__c=wo.Wheel_locks_functional__c;}
        IF(wo.Wheels_securly_attached_and_rotate_prope__c != NULL){womergemap.get(wo.Service_Report_Number__c).Wheels_securly_attached_and_rotate_prope__c=wo.Wheels_securly_attached_and_rotate_prope__c;}
        IF(wo.Work_Order_PDF_Type__c != NULL){womergemap.get(wo.Service_Report_Number__c).Work_Order_PDF_Type__c=wo.Work_Order_PDF_Type__c;}
        IF(wo.Work_Order_Shipping__c != NULL){womergemap.get(wo.Service_Report_Number__c).Work_Order_Shipping__c=wo.Work_Order_Shipping__c;}
        IF(wo.Work_Order_Tax__c != NULL){womergemap.get(wo.Service_Report_Number__c).Work_Order_Tax__c=wo.Work_Order_Tax__c;}
        IF(wo.Work_Order_Total__c != NULL){womergemap.get(wo.Service_Report_Number__c).Work_Order_Total__c=wo.Work_Order_Total__c;}           
        }        
    update womergemap.Values();
    delete listWo;   
    }
    
}