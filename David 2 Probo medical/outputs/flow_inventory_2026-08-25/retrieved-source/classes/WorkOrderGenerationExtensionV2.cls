public with sharing class WorkOrderGenerationExtensionV2 {
   
   public WorkOrder workordertoInsert {get; set;} 
   public String CustomerID{get;set;}
   public String AssetID{get;set;}
   public Decimal total{get;set;}
   public String OppName{get;set;}
   public String FoundOppName{get;set;}
   public String ServiceContractName{get;set;}
   public String FoundServiceContractName{get;set;}
   public String SerialNumber{get;set;}
   public String WoNumber{get;set;}
   public Attachment ApprovedForm { get; set; }
    
    public WorkOrderGenerationExtensionV2(ApexPages.StandardController stdcontroller){
        this.workordertoInsert = (WorkOrder)stdcontroller.getRecord();
		workordertoInsert.Part_Installed_Price_1__c = 0;
        workordertoInsert.Part_Installed_Quantity_1__c = 0;
        workordertoInsert.Part_Installed_Price_2__c = 0;
        workordertoInsert.Part_Installed_Quantity_2__c = 0;
        workordertoInsert.Part_Installed_Price_3__c = 0;
        workordertoInsert.Part_Installed_Quantity_3__c = 0;
        workordertoInsert.Part_Installed_Price_4__c = 0;
        workordertoInsert.Part_Installed_Quantity_4__c = 0;
        workordertoInsert.Part_Installed_Price_5__c = 0;
        workordertoInsert.Part_Installed_Quantity_5__c = 0;
        workordertoInsert.Part_Installed_Price_6__c = 0;
        workordertoInsert.Part_Installed_Quantity_6__c = 0;
        workordertoInsert.Work_Order_Total__c = 0;
        workordertoInsert.Work_Order_Tax__c = 0;
        workordertoInsert.Work_Order_Shipping__c = 0;
        workordertoInsert.Total_Labor__c = 0;
        workordertoInsert.Total_Travel__c = 0;
        workordertoInsert.Parts_Total__c = 0;
        workordertoInsert.Labor_Price__c = 190.00;
        workordertoInsert.Travel_Price__c = 190.00;
        
   }
    
    //Account Search Based On 
    List<Account> AccountSearchResults;
    List<ProductItem__c> AssetSearchResults;
    List<WorkOrder> WorkOrderSearchResults;
    List<Opportunity> OppSearchResults;
    List<ServiceContract> ServiceContractSearchResults;
    
   public PageReference doAssetSearch() {
       System.debug('AssetID: ' + AssetID);
       workordertoInsert.Serial_Number__c = 'Null';
       IF(AssetID != NULL){
          workordertoInsert.Serial_Number__c = 'Not Null';
       	AssetSearchResults = [SELECT ID, Name, Serial_No__c FROM ProductItem__c WHERE Name =: AssetID OR Serial_No__c =:AssetID];
           workordertoInsert.Serial_Number__c = String.valueof(AssetSearchResults); 
           IF(AssetSearchResults.size() == 1){
               workordertoInsert.Serial_Number__c = AssetSearchResults[0].Serial_No__c;
               workordertoInsert.Asset2__c = AssetSearchResults[0].ID;
           }
       	}
       return null;
   }
    
   public PageReference doOpportunitySearch() {
       System.debug('Opportunity: ' + OppName);
       workordertoInsert.Serial_Number__c = 'Null';
       IF(AssetID != NULL){
       	OppSearchResults = [SELECT ID, Name FROM Opportunity WHERE Name =: OppName OR  Opportunity_Number__c =: OppName LIMIT 1];
           workordertoInsert.Serial_Number__c = String.valueof(OppSearchResults); 
           IF(OppSearchResults.size() == 1){
               workordertoInsert.Opportunity__c = OppSearchResults[0].ID;
               FoundOppName = OppSearchResults[0].Name;
           }
       	}
       return null;
   }
    
    
   public PageReference doServiceContractSearch() {
       System.debug('Service Contract: ' + ServiceContractName);
       workordertoInsert.Serial_Number__c = 'Null';
       IF(AssetID != NULL){
          workordertoInsert.Serial_Number__c = 'Not Null';
       	ServiceContractSearchResults = [SELECT ID, Name FROM ServiceContract WHERE Name =: ServiceContractName OR ContractNumber =: ServiceContractName LIMIT 1];
           workordertoInsert.Serial_Number__c = String.valueof(ServiceContractSearchResults); 
           IF(ServiceContractSearchResults.size() == 1){
               workordertoInsert.ServiceContractId = ServiceContractSearchResults[0].ID;
               FoundServiceContractName = ServiceContractSearchResults[0].Name;
           }
       	}
       return null;
   }
    
    
    public PageReference calculateparts() {        
        workordertoInsert.Parts_Total__c = (workordertoInsert.Part_Installed_Price_6__c * workordertoInsert.Part_Installed_Quantity_6__c) + 
                (workordertoInsert.Part_Installed_Price_5__c * workordertoInsert.Part_Installed_Quantity_5__c) +
                (workordertoInsert.Part_Installed_Price_4__c * workordertoInsert.Part_Installed_Quantity_4__c) +
                (workordertoInsert.Part_Installed_Price_3__c * workordertoInsert.Part_Installed_Quantity_3__c) +
                (workordertoInsert.Part_Installed_Price_2__c * workordertoInsert.Part_Installed_Quantity_2__c) +
                (workordertoInsert.Part_Installed_Price_1__c * workordertoInsert.Part_Installed_Quantity_1__c);
        workordertoInsert.Work_Order_Total__c = workordertoInsert.Parts_Total__c + workordertoInsert.Total_Labor__c + workordertoInsert.Total_Travel__c + workordertoInsert.Work_Order_Shipping__c + workordertoInsert.Work_Order_Tax__c;
       	return null;
    }
    
     public PageReference calculatelabor() {
        if(workordertoInsert.Labor_Date_Time_Out__c != NULL && workordertoInsert.Labor_Date_Time_In__c != NULL){
            double date1 = workordertoInsert.Labor_Date_Time_Out__c.getTime();
            double date2 = workordertoInsert.Labor_Date_Time_In__c.getTime();
            if(workordertoInsert.Labor_Price__c != NULL){ 
                workordertoInsert.Total_Labor__c = ((date1 - date2)/3600000)*workordertoInsert.Labor_Price__c;
            }
            else{
                workordertoInsert.Total_Labor__c = ((date1 - date2)/3600000)*190; 
            }
        workordertoInsert.Work_Order_Total__c = workordertoInsert.Parts_Total__c + workordertoInsert.Total_Labor__c + workordertoInsert.Total_Travel__c + workordertoInsert.Work_Order_Shipping__c + workordertoInsert.Work_Order_Tax__c;
        }
       	return null;
    }
    
     public PageReference calculatetravel() {
        if(workordertoInsert.Travel_Date_Time_Out__c != NULL && workordertoInsert.Travel_Date_Time_In__c != NULL){
            double date3 = workordertoInsert.Travel_Date_Time_Out__c.getTime();
            double date4 = workordertoInsert.Travel_Date_Time_In__c.getTime();
            if(workordertoInsert.Travel_Price__c != NULL){ 
                workordertoInsert.Total_Travel__c = ((date3 - date4)/3600000)*workordertoInsert.Travel_Price__c;
            }
            else{
                workordertoInsert.Total_Travel__c = ((date3 - date4)/3600000)*190; 
            }
        workordertoInsert.Work_Order_Total__c = workordertoInsert.Parts_Total__c + workordertoInsert.Total_Labor__c + workordertoInsert.Total_Travel__c + workordertoInsert.Work_Order_Shipping__c + workordertoInsert.Work_Order_Tax__c;
        }
       	return null;
    }
    
    public PageReference calculatewototal(){
        workordertoInsert.Work_Order_Total__c = workordertoInsert.Parts_Total__c + workordertoInsert.Total_Labor__c + workordertoInsert.Total_Travel__c + workordertoInsert.Work_Order_Shipping__c + workordertoInsert.Work_Order_Tax__c;
       	return null;
    }
    
   public PageReference doAccountSearch() {
      System.debug('CustomerID: ' + CustomerID); 
      IF(CustomerID != NULL){
      	AccountSearchResults = [SELECT ID, name, Customer_ID__c, phone, billingstreet, billingcity, billingstate, billingpostalcode, shippingstreet, shippingcity, shippingstate, shippingpostalcode FROM Account WHERE Customer_ID__c =: CustomerID];
          IF(AccountSearchResults.size() == 1){
            System.debug('AccountSearchResults: ' + AccountSearchResults);
            workordertoInsert.Service_Facility__c = AccountSearchResults[0].name;
            workordertoInsert.Service_Street__c = AccountSearchResults[0].shippingstreet;
            workordertoInsert.Service_City__c = AccountSearchResults[0].shippingcity;
            workordertoInsert.Service_State_Province__c = AccountSearchResults[0].shippingstate;
            workordertoInsert.Service_Zip_Postal_Code__c = AccountSearchResults[0].shippingpostalcode;
            workordertoInsert.Billing_Street__c = AccountSearchResults[0].billingstreet;
            workordertoInsert.Billing_City__c = AccountSearchResults[0].billingcity;
            workordertoInsert.Billing_State__c = AccountSearchResults[0].billingstate;
            workordertoInsert.Billing_Zip_Postal_Code__c = AccountSearchResults[0].billingpostalcode;
            workordertoInsert.Contact_Phone__c = AccountSearchResults[0].phone;
            workordertoInsert.Customer_ID__c = AccountSearchResults[0].Customer_ID__c;
            workordertoInsert.AccountId = AccountSearchResults[0].Id;
          }
      }
      return null;
   }
    
   public PageReference doWorkOrderSearch() {
      System.debug('Work Order ID: ' + WoNumber); 
      IF(WoNumber != NULL){
         WorkOrderSearchResults = [Select AccountId, Address, Total_Labor__c, Total_Travel__c, Service_Date__c,All_chords_and_cables_intact_no_Frays__c, AssetId, Backup_Preset_and_Network_Settings__c, Billable_Work_Order__c, Billing_City__c, Billing_State__c, Billing_Status__c, Billing_Street__c, Billing_Zip_Postal_Code__c, BusinessHoursId, CaseId, Check_2D_PW_Color_Incl_Angio_Power__c, Check_3D_4D__c, Check_CW_Doppler__c, Check_Calibrate_power_supplies__c, Check_Control_Panel_Keyboard__c, Check_ECG_Cable_Signal__c, Check_System_Battery__c, Check_network_functionality__c, Check_optimize_monitor__c, Check_system_fans__c, Checked_Basic_measurements__c, City, Clean_and_inspect_system_interior__c, Clean_system_filters__c, Clean_system_monitor_touch_panel__c, Clean_trackball__c, ContactId, Contact_Phone__c, Core_Probe_Serial__c, Core_Probe__c, Core_System_Serial_2__c, Core_System__c, Country, CreatedById, CreatedDate, Customer_ID__c, Description, Device_Current__c, Discount, Discuss_Customer_Concerns__c, Display_Characteristics_Completed__c, Duration, DurationInMinutes, DurationType, EndDate, Error_Code__c, Field_Service_Engineer__c, GeocodeAccuracy, GrandTotal, Hospital_grade_plug__c, Id, Inspect_accessories_peripherals_for_pro__c, Installed_Part_Number_1__c, Installed_Part_Number_2__c, Installed_Part_Number_3__c, Installed_Part_Number_4__c, Installed_Part_Number_5__c, Installed_Part_Number_6__c, Installed_Part_Rev_1__c, Installed_Part_Rev_2__c, Installed_Part_Rev_3__c, Installed_Part_Rev_4__c, Installed_Part_Rev_5__c, Installed_Part_Rev_6__c, Intact_without_cracks_1__c, Intact_without_cracks_2__c, Intact_without_cracks_3__c, Intact_without_cracks_4__c, Intact_without_cracks_5__c, Intact_without_cracks_6__c, Intact_without_cracks_7__c, Intact_without_cracks_8__c, IsClosed, IsDeleted, IsStopped, Labor_Date_Time_In__c, Labor_Date_Time_Out__c, LastModifiedById, LastModifiedDate, LastReferencedDate, LastViewedDate, Latitude, Lead_Isolation_P_F__c, Lead_Isolation_Test_Value__c, Lead_Leakage_P_F__c, Lead_Leakage_Value__c, Leakage_Value_GND_Open_1__c, Leakage_Value_GND_Open_2__c, Leakage_Value_GND_Open_3__c, Leakage_Value_GND_Open_4__c, Leakage_Value_GND_Open_5__c, Leakage_Value_GND_Open_6__c, Leakage_Value_GND_Open_7__c, Leakage_Value_GND_Open_8__c, LineItemCount, Line_Voltage__c, LocationId, Longitude, Make_Model__c, MilestoneStatus, Needs_Paid__c, No_Brightness_Transitions_1__c, No_Brightness_Transitions_2__c, No_Brightness_Transitions_3__c, No_Brightness_Transitions_4__c, No_Brightness_Transitions_5__c, No_Brightness_Transitions_6__c, No_Brightness_Transitions_7__c, No_Brightness_Transitions_8__c, No_Vertical_or_Radical_Shadows_1__c, No_Vertical_or_Radical_Shadows_2__c, No_Vertical_or_Radical_Shadows_3__c, No_Vertical_or_Radical_Shadows_4__c, No_Vertical_or_Radical_Shadows_5__c, No_Vertical_or_Radical_Shadows_6__c, No_Vertical_or_Radical_Shadows_7__c, No_Vertical_or_Radical_Shadows_8__c, Normal_Polarity_Test_Ground_Closed__c, Normal_Polarity_Test_Ground_Open__c, Opportunity__c, OwnerId, PO_Number__c, ParentWorkOrderId, Part_Description_1__c, Part_Description_2__c, Part_Description_3__c, Part_Description_4__c, Part_Description_5__c, Part_Description_6__c, Part_Installed_Price_1__c, Part_Installed_Price_2__c, Part_Installed_Price_3__c, Part_Installed_Price_4__c, Part_Installed_Price_5__c, Part_Installed_Price_6__c, Part_Installed_Quantity_1__c, Part_Installed_Quantity_2__c, Part_Installed_Quantity_3__c, Part_Installed_Quantity_4__c, Part_Installed_Quantity_5__c, Part_Installed_Quantity_6__c, Part_Installed_Serial_Number_1__c, Part_Installed_Serial_Number_2__c, Part_Installed_Serial_Number_3__c, Part_Installed_Serial_Number_4__c, Part_Installed_Serial_Number_5__c, Part_Installed_Serial_Number_6__c, Part_Removed_Quantity_1__c, Part_Removed_Quantity_2__c, Part_Removed_Quantity_3__c, Part_Removed_Quantity_4__c, Part_Removed_Quantity_5__c, Part_Removed_Quantity_6__c, Part_Removed_Serial_Number_1__c, Part_Removed_Serial_Number_2__c, Part_Removed_Serial_Number_3__c, Part_Removed_Serial_Number_4__c, Part_Removed_Serial_Number_5__c, Part_Removed_Serial_Number_6__c, Parts_Total__c, Perform_hard_drive_maintenance__c, Person_Requesting_WO_Email__c, Possible_Repairs__c, PostalCode, Power_Cord_Resistance__c, Preliminary_Comments_and_Findings__c, Pricebook2Id, Priority, RecordTypeId, Removed_Part_Number_1__c, Removed_Part_Number_2__c, Removed_Part_Number_3__c, Removed_Part_Number_4__c, Removed_Part_Number_5__c, Removed_Part_Number_6__c, Removed_Part_Rev_1__c, Removed_Part_Rev_2__c, Removed_Part_Rev_3__c, Removed_Part_Rev_4__c, Removed_Part_Rev_5__c, Removed_Part_Rev_6__c, Replacement_Probe_Serial__c, Replacement_Probe__c, Replacement_System_Serial__c, Replacement_System__c, Reported_Symptoms__c, Reverse_Polarity_Test_Ground_Closed__c, Reverse_Polarity_Test_Ground_Open__c, Review_Error_Logs_if_applicable__c, RootWorkOrderId, Run_System_Diagnostics_if_available__c, Serial_Number__c, ServiceAppointmentCount, ServiceContractId, Service_City__c, Service_Department__c, Service_Facility__c, Service_Report_Number__c, Service_State_Province__c, Service_Street__c, Service_Zip_Postal_Code__c, SlaExitDate, SlaStartDate, Software__c, Solution_Remarks__c, Special_Instructions__c, StartDate, State, Status, StatusCategory, StopStartDate, Street, Subject, Subtotal, Symptom_Code__c, SystemModstamp, System_Articulations_monitor_user_inte__c, Tax, Third_Party_Vendor_Cost__c, Third_Party_Vendor_Name__c, Third_Party_Vendor_PO__c, TotalPrice, Tranducer_Average_Brightness_Same_1__c, Tranducer_Average_Brightness_Same_2__c, Tranducer_Average_Brightness_Same_3__c, Tranducer_Average_Brightness_Same_4__c, Tranducer_Average_Brightness_Same_5__c, Tranducer_Average_Brightness_Same_6__c, Tranducer_Average_Brightness_Same_7__c, Tranducer_Average_Brightness_Same_8__c, Transducer_Max_Depth_1__c, Transducer_Max_Depth_2__c, Transducer_Max_Depth_3__c, Transducer_Max_Depth_4__c, Transducer_Max_Depth_5__c, Transducer_Max_Depth_6__c, Transducer_Max_Depth_7__c, Transducer_Max_Depth_8__c, Transducer_Model_1__c, Transducer_Model_2__c, Transducer_Model_3__c, Transducer_Model_4__c, Transducer_Model_5__c, Transducer_Model_6__c, Transducer_Model_7__c, Transducer_Model_8__c, Transducer_P_F_1__c, Transducer_P_F_2__c, Transducer_P_F_3__c, Transducer_P_F_4__c, Transducer_P_F_5__c, Transducer_P_F_6__c, Transducer_P_F_7__c, Transducer_P_F_8__c, Transducer_S_N_1__c, Transducer_S_N_2__c, Transducer_S_N_3__c, Transducer_S_N_4__c, Transducer_S_N_5__c, Transducer_S_N_6__c, Transducer_S_N_7__c, Transducer_S_N_8__c, Transducers_cleaned_after_each_use__c, Travel_Date_Time_In__c, Travel_Date_Time_Out__c, Unit_Inspected_and_tested_per_OEM_servic__c, Verified_Symptoms__c, Verify_Boot_Process__c, Verify_Database__c, Verify_Power_Up__c, Verify_Remote_Diagnostics_if_applicable__c, Wheel_locks_functional__c, Wheels_securly_attached_and_rotate_prope__c, WorkOrderNumber, Work_Order_Cost__c, Work_Order_PDF_Type__c FROM WorkOrder WHERE WorkOrderNumber =: WoNumber OR Id =: WoNumber];
          System.debug('WorkOrderSearchResults: ' + WorkOrderSearchResults);
          IF(WorkOrderSearchResults.size() == 1){
             
            workordertoInsert.All_chords_and_cables_intact_no_Frays__c = WorkOrderSearchResults[0].All_chords_and_cables_intact_no_Frays__c;
            workordertoInsert.AssetId = WorkOrderSearchResults[0].AssetId;
            workordertoInsert.Backup_Preset_and_Network_Settings__c = WorkOrderSearchResults[0].Backup_Preset_and_Network_Settings__c;
            workordertoInsert.Billing_Street__c = WorkOrderSearchResults[0].Billing_Street__c;
            workordertoInsert.Billing_City__c = WorkOrderSearchResults[0].Billing_City__c;
            workordertoInsert.Billing_State__c = WorkOrderSearchResults[0].Billing_State__c;
            workordertoInsert.Billing_Status__c = WorkOrderSearchResults[0].Billing_Status__c;
            workordertoInsert.Billing_Zip_Postal_Code__c = WorkOrderSearchResults[0].Billing_Zip_Postal_Code__c;
            workordertoInsert.Check_2D_PW_Color_Incl_Angio_Power__c = WorkOrderSearchResults[0].Check_2D_PW_Color_Incl_Angio_Power__c;
            workordertoInsert.Check_3D_4D__c = WorkOrderSearchResults[0].Check_3D_4D__c;
            workordertoInsert.Check_CW_Doppler__c = WorkOrderSearchResults[0].Check_CW_Doppler__c;
            workordertoInsert.Check_Calibrate_power_supplies__c = WorkOrderSearchResults[0].Check_Calibrate_power_supplies__c;
            workordertoInsert.Check_Control_Panel_Keyboard__c = WorkOrderSearchResults[0].Check_Control_Panel_Keyboard__c;
            workordertoInsert.Check_ECG_Cable_Signal__c = WorkOrderSearchResults[0].Check_ECG_Cable_Signal__c;
            workordertoInsert.Check_System_Battery__c = WorkOrderSearchResults[0].Check_System_Battery__c;
            workordertoInsert.Check_network_functionality__c = WorkOrderSearchResults[0].Check_network_functionality__c;
            workordertoInsert.Check_optimize_monitor__c = WorkOrderSearchResults[0].Check_optimize_monitor__c;
            workordertoInsert.Check_system_fans__c = WorkOrderSearchResults[0].Check_system_fans__c;
            workordertoInsert.Checked_Basic_measurements__c = WorkOrderSearchResults[0].Checked_Basic_measurements__c;
            workordertoInsert.Clean_and_inspect_system_interior__c = WorkOrderSearchResults[0].Clean_and_inspect_system_interior__c;
            workordertoInsert.Clean_system_filters__c = WorkOrderSearchResults[0].Clean_system_filters__c;
            workordertoInsert.Clean_system_monitor_touch_panel__c = WorkOrderSearchResults[0].Clean_system_monitor_touch_panel__c;
            workordertoInsert.Clean_trackball__c = WorkOrderSearchResults[0].Clean_trackball__c;
            workordertoInsert.Contact_Phone__c = WorkOrderSearchResults[0].Contact_Phone__c;
            workordertoInsert.Customer_ID__c = WorkOrderSearchResults[0].Customer_ID__c;
            workordertoInsert.Device_Current__c = WorkOrderSearchResults[0].Device_Current__c;
            workordertoInsert.Discuss_Customer_Concerns__c = WorkOrderSearchResults[0].Discuss_Customer_Concerns__c;
            workordertoInsert.Display_Characteristics_Completed__c = WorkOrderSearchResults[0].Display_Characteristics_Completed__c;
            workordertoInsert.Error_Code__c = WorkOrderSearchResults[0].Error_Code__c;
            workordertoInsert.Field_Service_Engineer__c = WorkOrderSearchResults[0].Field_Service_Engineer__c;
            workordertoInsert.Hospital_grade_plug__c = WorkOrderSearchResults[0].Hospital_grade_plug__c;
            workordertoInsert.Inspect_accessories_peripherals_for_pro__c = WorkOrderSearchResults[0].Inspect_accessories_peripherals_for_pro__c;
            workordertoInsert.Installed_Part_Number_1__c = WorkOrderSearchResults[0].Installed_Part_Number_1__c;
            workordertoInsert.Installed_Part_Number_2__c = WorkOrderSearchResults[0].Installed_Part_Number_2__c;
            workordertoInsert.Installed_Part_Number_3__c = WorkOrderSearchResults[0].Installed_Part_Number_3__c;
            workordertoInsert.Installed_Part_Number_4__c = WorkOrderSearchResults[0].Installed_Part_Number_4__c;
            workordertoInsert.Installed_Part_Number_5__c = WorkOrderSearchResults[0].Installed_Part_Number_5__c;
            workordertoInsert.Installed_Part_Number_6__c = WorkOrderSearchResults[0].Installed_Part_Number_6__c;
            workordertoInsert.Installed_Part_Rev_1__c = WorkOrderSearchResults[0].Installed_Part_Rev_1__c;
            workordertoInsert.Installed_Part_Rev_2__c = WorkOrderSearchResults[0].Installed_Part_Rev_2__c;
            workordertoInsert.Installed_Part_Rev_3__c = WorkOrderSearchResults[0].Installed_Part_Rev_3__c;
            workordertoInsert.Installed_Part_Rev_4__c = WorkOrderSearchResults[0].Installed_Part_Rev_4__c;
            workordertoInsert.Installed_Part_Rev_5__c = WorkOrderSearchResults[0].Installed_Part_Rev_5__c;
            workordertoInsert.Installed_Part_Rev_6__c = WorkOrderSearchResults[0].Installed_Part_Rev_6__c;
            workordertoInsert.Intact_without_cracks_1__c = WorkOrderSearchResults[0].Intact_without_cracks_1__c;
            workordertoInsert.Intact_without_cracks_2__c = WorkOrderSearchResults[0].Intact_without_cracks_2__c;
            workordertoInsert.Intact_without_cracks_3__c = WorkOrderSearchResults[0].Intact_without_cracks_3__c;
            workordertoInsert.Intact_without_cracks_4__c = WorkOrderSearchResults[0].Intact_without_cracks_4__c;
            workordertoInsert.Intact_without_cracks_5__c = WorkOrderSearchResults[0].Intact_without_cracks_5__c;
            workordertoInsert.Intact_without_cracks_6__c = WorkOrderSearchResults[0].Intact_without_cracks_6__c;
            workordertoInsert.Intact_without_cracks_7__c = WorkOrderSearchResults[0].Intact_without_cracks_7__c;
            workordertoInsert.Intact_without_cracks_8__c = WorkOrderSearchResults[0].Intact_without_cracks_8__c;
            workordertoInsert.Labor_Date_Time_In__c = WorkOrderSearchResults[0].Labor_Date_Time_In__c;
            workordertoInsert.Labor_Date_Time_Out__c = WorkOrderSearchResults[0].Labor_Date_Time_Out__c;
            workordertoInsert.Lead_Isolation_P_F__c = WorkOrderSearchResults[0].Lead_Isolation_P_F__c;
            workordertoInsert.Lead_Isolation_Test_Value__c = WorkOrderSearchResults[0].Lead_Isolation_Test_Value__c;
            workordertoInsert.Lead_Leakage_P_F__c = WorkOrderSearchResults[0].Lead_Leakage_P_F__c;
            workordertoInsert.Lead_Leakage_Value__c = WorkOrderSearchResults[0].Lead_Leakage_Value__c;
            workordertoInsert.Leakage_Value_GND_Open_1__c = WorkOrderSearchResults[0].Leakage_Value_GND_Open_1__c;
            workordertoInsert.Leakage_Value_GND_Open_2__c = WorkOrderSearchResults[0].Leakage_Value_GND_Open_2__c;
            workordertoInsert.Leakage_Value_GND_Open_3__c = WorkOrderSearchResults[0].Leakage_Value_GND_Open_3__c;
            workordertoInsert.Leakage_Value_GND_Open_4__c = WorkOrderSearchResults[0].Leakage_Value_GND_Open_4__c;
            workordertoInsert.Leakage_Value_GND_Open_5__c = WorkOrderSearchResults[0].Leakage_Value_GND_Open_5__c;
            workordertoInsert.Leakage_Value_GND_Open_6__c = WorkOrderSearchResults[0].Leakage_Value_GND_Open_6__c;
            workordertoInsert.Leakage_Value_GND_Open_7__c = WorkOrderSearchResults[0].Leakage_Value_GND_Open_7__c;
            workordertoInsert.Leakage_Value_GND_Open_8__c = WorkOrderSearchResults[0].Leakage_Value_GND_Open_8__c;
            workordertoInsert.Line_Voltage__c = WorkOrderSearchResults[0].Line_Voltage__c;
            workordertoInsert.Make_Model__c = WorkOrderSearchResults[0].Make_Model__c;
            workordertoInsert.No_Brightness_Transitions_1__c = WorkOrderSearchResults[0].No_Brightness_Transitions_1__c;
            workordertoInsert.No_Brightness_Transitions_2__c = WorkOrderSearchResults[0].No_Brightness_Transitions_2__c;
            workordertoInsert.No_Brightness_Transitions_3__c = WorkOrderSearchResults[0].No_Brightness_Transitions_3__c;
            workordertoInsert.No_Brightness_Transitions_4__c = WorkOrderSearchResults[0].No_Brightness_Transitions_4__c;
            workordertoInsert.No_Brightness_Transitions_5__c = WorkOrderSearchResults[0].No_Brightness_Transitions_5__c;
            workordertoInsert.No_Brightness_Transitions_6__c = WorkOrderSearchResults[0].No_Brightness_Transitions_6__c;
            workordertoInsert.No_Brightness_Transitions_7__c = WorkOrderSearchResults[0].No_Brightness_Transitions_7__c;
            workordertoInsert.No_Brightness_Transitions_8__c = WorkOrderSearchResults[0].No_Brightness_Transitions_8__c;
            workordertoInsert.No_Vertical_or_Radical_Shadows_1__c = WorkOrderSearchResults[0].No_Vertical_or_Radical_Shadows_1__c;
            workordertoInsert.No_Vertical_or_Radical_Shadows_2__c = WorkOrderSearchResults[0].No_Vertical_or_Radical_Shadows_2__c;
            workordertoInsert.No_Vertical_or_Radical_Shadows_3__c = WorkOrderSearchResults[0].No_Vertical_or_Radical_Shadows_3__c;
            workordertoInsert.No_Vertical_or_Radical_Shadows_4__c = WorkOrderSearchResults[0].No_Vertical_or_Radical_Shadows_4__c;
            workordertoInsert.No_Vertical_or_Radical_Shadows_5__c = WorkOrderSearchResults[0].No_Vertical_or_Radical_Shadows_5__c;
            workordertoInsert.No_Vertical_or_Radical_Shadows_6__c = WorkOrderSearchResults[0].No_Vertical_or_Radical_Shadows_6__c;
            workordertoInsert.No_Vertical_or_Radical_Shadows_7__c = WorkOrderSearchResults[0].No_Vertical_or_Radical_Shadows_7__c;
            workordertoInsert.No_Vertical_or_Radical_Shadows_8__c = WorkOrderSearchResults[0].No_Vertical_or_Radical_Shadows_8__c;
            workordertoInsert.Normal_Polarity_Test_Ground_Closed__c = WorkOrderSearchResults[0].Normal_Polarity_Test_Ground_Closed__c;
            workordertoInsert.Normal_Polarity_Test_Ground_Open__c = WorkOrderSearchResults[0].Normal_Polarity_Test_Ground_Open__c;
            workordertoInsert.Opportunity__c = WorkOrderSearchResults[0].Opportunity__c;
            workordertoInsert.PO_Number__c = WorkOrderSearchResults[0].PO_Number__c;
            workordertoInsert.Part_Description_1__c = WorkOrderSearchResults[0].Part_Description_1__c;
            workordertoInsert.Part_Description_2__c = WorkOrderSearchResults[0].Part_Description_2__c;
            workordertoInsert.Part_Description_3__c = WorkOrderSearchResults[0].Part_Description_3__c;
            workordertoInsert.Part_Description_4__c = WorkOrderSearchResults[0].Part_Description_4__c;
            workordertoInsert.Part_Description_5__c = WorkOrderSearchResults[0].Part_Description_5__c;
            workordertoInsert.Part_Description_6__c = WorkOrderSearchResults[0].Part_Description_6__c;
            workordertoInsert.Part_Installed_Price_1__c = WorkOrderSearchResults[0].Part_Installed_Price_1__c;
            workordertoInsert.Part_Installed_Price_2__c = WorkOrderSearchResults[0].Part_Installed_Price_2__c;
            workordertoInsert.Part_Installed_Price_3__c = WorkOrderSearchResults[0].Part_Installed_Price_3__c;
            workordertoInsert.Part_Installed_Price_4__c = WorkOrderSearchResults[0].Part_Installed_Price_4__c;
            workordertoInsert.Part_Installed_Price_5__c = WorkOrderSearchResults[0].Part_Installed_Price_5__c;
            workordertoInsert.Part_Installed_Price_6__c = WorkOrderSearchResults[0].Part_Installed_Price_6__c;
            workordertoInsert.Part_Installed_Quantity_1__c = WorkOrderSearchResults[0].Part_Installed_Quantity_1__c;
            workordertoInsert.Part_Installed_Quantity_2__c = WorkOrderSearchResults[0].Part_Installed_Quantity_2__c;
            workordertoInsert.Part_Installed_Quantity_3__c = WorkOrderSearchResults[0].Part_Installed_Quantity_3__c;
            workordertoInsert.Part_Installed_Quantity_4__c = WorkOrderSearchResults[0].Part_Installed_Quantity_4__c;
            workordertoInsert.Part_Installed_Quantity_5__c = WorkOrderSearchResults[0].Part_Installed_Quantity_5__c;
            workordertoInsert.Part_Installed_Quantity_6__c = WorkOrderSearchResults[0].Part_Installed_Quantity_6__c;
            workordertoInsert.Part_Installed_Serial_Number_1__c = WorkOrderSearchResults[0].Part_Installed_Serial_Number_1__c;
            workordertoInsert.Part_Installed_Serial_Number_2__c = WorkOrderSearchResults[0].Part_Installed_Serial_Number_2__c;
            workordertoInsert.Part_Installed_Serial_Number_3__c = WorkOrderSearchResults[0].Part_Installed_Serial_Number_3__c;
            workordertoInsert.Part_Installed_Serial_Number_4__c = WorkOrderSearchResults[0].Part_Installed_Serial_Number_4__c;
            workordertoInsert.Part_Installed_Serial_Number_5__c = WorkOrderSearchResults[0].Part_Installed_Serial_Number_5__c;
            workordertoInsert.Part_Installed_Serial_Number_6__c = WorkOrderSearchResults[0].Part_Installed_Serial_Number_6__c;
            workordertoInsert.Part_Removed_Quantity_1__c = WorkOrderSearchResults[0].Part_Removed_Quantity_1__c;
            workordertoInsert.Part_Removed_Quantity_2__c = WorkOrderSearchResults[0].Part_Removed_Quantity_2__c;
            workordertoInsert.Part_Removed_Quantity_3__c = WorkOrderSearchResults[0].Part_Removed_Quantity_3__c;
            workordertoInsert.Part_Removed_Quantity_4__c = WorkOrderSearchResults[0].Part_Removed_Quantity_4__c;
            workordertoInsert.Part_Removed_Quantity_5__c = WorkOrderSearchResults[0].Part_Removed_Quantity_5__c;
            workordertoInsert.Part_Removed_Quantity_6__c = WorkOrderSearchResults[0].Part_Removed_Quantity_6__c;
            workordertoInsert.Part_Removed_Serial_Number_1__c = WorkOrderSearchResults[0].Part_Removed_Serial_Number_1__c;
            workordertoInsert.Part_Removed_Serial_Number_2__c = WorkOrderSearchResults[0].Part_Removed_Serial_Number_2__c;
            workordertoInsert.Part_Removed_Serial_Number_3__c = WorkOrderSearchResults[0].Part_Removed_Serial_Number_3__c;
            workordertoInsert.Part_Removed_Serial_Number_4__c = WorkOrderSearchResults[0].Part_Removed_Serial_Number_4__c;
            workordertoInsert.Part_Removed_Serial_Number_5__c = WorkOrderSearchResults[0].Part_Removed_Serial_Number_5__c;
            workordertoInsert.Part_Removed_Serial_Number_6__c = WorkOrderSearchResults[0].Part_Removed_Serial_Number_6__c;
            workordertoInsert.Parts_Total__c = WorkOrderSearchResults[0].Parts_Total__c;
            workordertoInsert.Perform_hard_drive_maintenance__c = WorkOrderSearchResults[0].Perform_hard_drive_maintenance__c;
            workordertoInsert.Person_Requesting_WO_Email__c = WorkOrderSearchResults[0].Person_Requesting_WO_Email__c;
            workordertoInsert.Possible_Repairs__c = WorkOrderSearchResults[0].Possible_Repairs__c;
            workordertoInsert.Power_Cord_Resistance__c = WorkOrderSearchResults[0].Power_Cord_Resistance__c;
            workordertoInsert.Preliminary_Comments_and_Findings__c = WorkOrderSearchResults[0].Preliminary_Comments_and_Findings__c;
            workordertoInsert.Removed_Part_Number_1__c = WorkOrderSearchResults[0].Removed_Part_Number_1__c;
            workordertoInsert.Removed_Part_Number_2__c = WorkOrderSearchResults[0].Removed_Part_Number_2__c;
            workordertoInsert.Removed_Part_Number_3__c = WorkOrderSearchResults[0].Removed_Part_Number_3__c;
            workordertoInsert.Removed_Part_Number_4__c = WorkOrderSearchResults[0].Removed_Part_Number_4__c;
            workordertoInsert.Removed_Part_Number_5__c = WorkOrderSearchResults[0].Removed_Part_Number_5__c;
            workordertoInsert.Removed_Part_Number_6__c = WorkOrderSearchResults[0].Removed_Part_Number_6__c;
            workordertoInsert.Removed_Part_Rev_1__c = WorkOrderSearchResults[0].Removed_Part_Rev_1__c;
            workordertoInsert.Removed_Part_Rev_2__c = WorkOrderSearchResults[0].Removed_Part_Rev_2__c;
            workordertoInsert.Removed_Part_Rev_3__c = WorkOrderSearchResults[0].Removed_Part_Rev_3__c;
            workordertoInsert.Removed_Part_Rev_4__c = WorkOrderSearchResults[0].Removed_Part_Rev_4__c;
            workordertoInsert.Removed_Part_Rev_5__c = WorkOrderSearchResults[0].Removed_Part_Rev_5__c;
            workordertoInsert.Removed_Part_Rev_6__c = WorkOrderSearchResults[0].Removed_Part_Rev_6__c;
            workordertoInsert.Reported_Symptoms__c = WorkOrderSearchResults[0].Reported_Symptoms__c;
            workordertoInsert.Reverse_Polarity_Test_Ground_Closed__c = WorkOrderSearchResults[0].Reverse_Polarity_Test_Ground_Closed__c;
            workordertoInsert.Review_Error_Logs_if_applicable__c = WorkOrderSearchResults[0].Review_Error_Logs_if_applicable__c;
            workordertoInsert.Run_System_Diagnostics_if_available__c = WorkOrderSearchResults[0].Run_System_Diagnostics_if_available__c;
            workordertoInsert.Serial_Number__c = WorkOrderSearchResults[0].Serial_Number__c;
            workordertoInsert.Service_City__c = WorkOrderSearchResults[0].Service_City__c;
            workordertoInsert.Service_Date__c = WorkOrderSearchResults[0].Service_Date__c;
            workordertoInsert.Service_Department__c = WorkOrderSearchResults[0].Service_Department__c;
            workordertoInsert.Service_Facility__c = WorkOrderSearchResults[0].Service_Facility__c;
            workordertoInsert.Service_Report_Number__c = WorkOrderSearchResults[0].Service_Report_Number__c;
            workordertoInsert.Service_State_Province__c = WorkOrderSearchResults[0].Service_State_Province__c;
            workordertoInsert.Service_Street__c = WorkOrderSearchResults[0].Service_Street__c;
            workordertoInsert.Service_Zip_Postal_Code__c = WorkOrderSearchResults[0].Service_Zip_Postal_Code__c;
            workordertoInsert.Software__c = WorkOrderSearchResults[0].Software__c;
            workordertoInsert.Solution_Remarks__c = WorkOrderSearchResults[0].Solution_Remarks__c;
            workordertoInsert.Special_Instructions__c = WorkOrderSearchResults[0].Special_Instructions__c;
            workordertoInsert.Status = WorkOrderSearchResults[0].Status;
            workordertoInsert.Symptom_Code__c = WorkOrderSearchResults[0].Symptom_Code__c;
            workordertoInsert.System_Articulations_monitor_user_inte__c = WorkOrderSearchResults[0].System_Articulations_monitor_user_inte__c;
            workordertoInsert.Tranducer_Average_Brightness_Same_1__c = WorkOrderSearchResults[0].Tranducer_Average_Brightness_Same_1__c;
            workordertoInsert.Tranducer_Average_Brightness_Same_2__c = WorkOrderSearchResults[0].Tranducer_Average_Brightness_Same_2__c;
            workordertoInsert.Tranducer_Average_Brightness_Same_3__c = WorkOrderSearchResults[0].Tranducer_Average_Brightness_Same_3__c;
            workordertoInsert.Tranducer_Average_Brightness_Same_4__c = WorkOrderSearchResults[0].Tranducer_Average_Brightness_Same_4__c;
            workordertoInsert.Tranducer_Average_Brightness_Same_5__c = WorkOrderSearchResults[0].Tranducer_Average_Brightness_Same_5__c;
            workordertoInsert.Tranducer_Average_Brightness_Same_6__c = WorkOrderSearchResults[0].Tranducer_Average_Brightness_Same_6__c;
            workordertoInsert.Tranducer_Average_Brightness_Same_7__c = WorkOrderSearchResults[0].Tranducer_Average_Brightness_Same_7__c;
            workordertoInsert.Tranducer_Average_Brightness_Same_8__c = WorkOrderSearchResults[0].Tranducer_Average_Brightness_Same_8__c;
            workordertoInsert.Transducer_Max_Depth_1__c = WorkOrderSearchResults[0].Transducer_Max_Depth_1__c;
            workordertoInsert.Transducer_Max_Depth_2__c = WorkOrderSearchResults[0].Transducer_Max_Depth_2__c;
            workordertoInsert.Transducer_Max_Depth_3__c = WorkOrderSearchResults[0].Transducer_Max_Depth_3__c;
            workordertoInsert.Transducer_Max_Depth_4__c = WorkOrderSearchResults[0].Transducer_Max_Depth_4__c;
            workordertoInsert.Transducer_Max_Depth_5__c = WorkOrderSearchResults[0].Transducer_Max_Depth_5__c;
            workordertoInsert.Transducer_Max_Depth_6__c = WorkOrderSearchResults[0].Transducer_Max_Depth_6__c;
            workordertoInsert.Transducer_Max_Depth_7__c = WorkOrderSearchResults[0].Transducer_Max_Depth_7__c;
            workordertoInsert.Transducer_Max_Depth_8__c = WorkOrderSearchResults[0].Transducer_Max_Depth_8__c;
            workordertoInsert.Transducer_Model_1__c = WorkOrderSearchResults[0].Transducer_Model_1__c;
            workordertoInsert.Transducer_Model_2__c = WorkOrderSearchResults[0].Transducer_Model_2__c;
            workordertoInsert.Transducer_Model_3__c = WorkOrderSearchResults[0].Transducer_Model_3__c;
            workordertoInsert.Transducer_Model_4__c = WorkOrderSearchResults[0].Transducer_Model_4__c;
            workordertoInsert.Transducer_Model_5__c = WorkOrderSearchResults[0].Transducer_Model_5__c;
            workordertoInsert.Transducer_Model_6__c = WorkOrderSearchResults[0].Transducer_Model_6__c;
            workordertoInsert.Transducer_Model_7__c = WorkOrderSearchResults[0].Transducer_Model_7__c;
            workordertoInsert.Transducer_Model_8__c = WorkOrderSearchResults[0].Transducer_Model_8__c;
            workordertoInsert.Transducer_P_F_1__c = WorkOrderSearchResults[0].Transducer_P_F_1__c;
            workordertoInsert.Transducer_P_F_2__c = WorkOrderSearchResults[0].Transducer_P_F_2__c;
            workordertoInsert.Transducer_P_F_3__c = WorkOrderSearchResults[0].Transducer_P_F_3__c;
            workordertoInsert.Transducer_P_F_4__c = WorkOrderSearchResults[0].Transducer_P_F_4__c;
            workordertoInsert.Transducer_P_F_5__c = WorkOrderSearchResults[0].Transducer_P_F_5__c;
            workordertoInsert.Transducer_P_F_6__c = WorkOrderSearchResults[0].Transducer_P_F_6__c;
            workordertoInsert.Transducer_P_F_7__c = WorkOrderSearchResults[0].Transducer_P_F_7__c;
            workordertoInsert.Transducer_P_F_8__c = WorkOrderSearchResults[0].Transducer_P_F_8__c;
            workordertoInsert.Transducer_S_N_1__c = WorkOrderSearchResults[0].Transducer_S_N_1__c;
            workordertoInsert.Transducer_S_N_2__c = WorkOrderSearchResults[0].Transducer_S_N_2__c;
            workordertoInsert.Transducer_S_N_3__c = WorkOrderSearchResults[0].Transducer_S_N_3__c;
            workordertoInsert.Transducer_S_N_4__c = WorkOrderSearchResults[0].Transducer_S_N_4__c;
            workordertoInsert.Transducer_S_N_5__c = WorkOrderSearchResults[0].Transducer_S_N_5__c;
            workordertoInsert.Transducer_S_N_6__c = WorkOrderSearchResults[0].Transducer_S_N_6__c;
            workordertoInsert.Transducer_S_N_7__c = WorkOrderSearchResults[0].Transducer_S_N_7__c;
            workordertoInsert.Transducer_S_N_8__c = WorkOrderSearchResults[0].Transducer_S_N_8__c;
            workordertoInsert.Transducers_cleaned_after_each_use__c = WorkOrderSearchResults[0].Transducers_cleaned_after_each_use__c;
            workordertoInsert.Travel_Date_Time_In__c = WorkOrderSearchResults[0].Travel_Date_Time_In__c;
            workordertoInsert.Travel_Date_Time_Out__c = WorkOrderSearchResults[0].Travel_Date_Time_Out__c;
            workordertoInsert.Verified_Symptoms__c = WorkOrderSearchResults[0].Verified_Symptoms__c;
            workordertoInsert.Verify_Boot_Process__c = WorkOrderSearchResults[0].Verify_Boot_Process__c;
            workordertoInsert.Verify_Database__c = WorkOrderSearchResults[0].Verify_Database__c;
            workordertoInsert.Verify_Power_Up__c = WorkOrderSearchResults[0].Verify_Power_Up__c;
            workordertoInsert.Verify_Remote_Diagnostics_if_applicable__c = WorkOrderSearchResults[0].Verify_Remote_Diagnostics_if_applicable__c;
            workordertoInsert.Wheel_locks_functional__c = WorkOrderSearchResults[0].Wheel_locks_functional__c;
            workordertoInsert.Wheels_securly_attached_and_rotate_prope__c = WorkOrderSearchResults[0].Wheels_securly_attached_and_rotate_prope__c;
            workordertoInsert.Total_Labor__c = WorkOrderSearchResults[0].Total_Labor__c;
        	workordertoInsert.Total_Travel__c = WorkOrderSearchResults[0].Total_Travel__c;
            workordertoInsert.Service_Report_Number__c = WoNumber;
		
          }      	
      } 
      return null;
   }
        
    public PageReference save(){
        try{
            insert workordertoInsert;
            workordertoInsert.Service_Report_Number__c = workordertoInsert.WorkOrderNumber;
            system.debug('Inserted Work Order: '+ workordertoInsert);
            String returnURL = '';
            if(workordertoInsert.Work_Order_PDF_Type__c == 'Field Service Report'){
                returnURL ='https://probomedical.secure.force.com/workorder/Field_Service_Report_PDF?id=' + workordertoInsert.Id;
            }
			if(workordertoInsert.Work_Order_PDF_Type__c == 'Preventative Maintenance Report'){
                returnURL ='https://probomedical.secure.force.com/workorder/Preventative_Maintenance_Report_PDF?id=' + workordertoInsert.Id;
            }

   			PageReference newReturnURL = new PageReference(returnURL);
    		newReturnURL.setRedirect(true);
    		return newReturnURL;             
   
         }
     
         catch (Exception ex) {
             ApexPages.addMessages(ex);
             system.debug(ex);
             return null;
         }
    }
    
    public PageReference redirectBack(){
			String returnURL ='https://probomedical.secure.force.com/workorder/';
  			PageReference newReturnURL = new PageReference(returnURL);
    		newReturnURL.setRedirect(true);
    		return newReturnURL;              
    }

}