public class P_ProductRepairTrigger2Handler {
    
    public static void beforeInsert1(List<Product_Repair__c> prodReps){
        
        for (Product_Repair__c oProductRepair : prodReps) {
            //Set Product Repair Name based on Repair Activity
            if(String.isNotBlank(oProductRepair.Repair_Activity__c)){
                oProductRepair.Product_Repair_Name__c = oProductRepair.Repair_Activity__c;
            }
            
            // set No longer needed stamps
            if(oProductRepair.No_longer_needed__c){
                oProductRepair.No_longer_needed_checked_by__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
                oProductRepair.Time_Stamp_No_Longer_Needed__c = System.Now();
            }   
            
            // Repair tech email update
            if(String.isNotBlank(oProductRepair.Repair_Technician__c) && !oProductRepair.Repair_Technician__c.equalsIgnoreCase('Tampa Tech')){
                List<String> lstRepairTech = oProductRepair.Repair_Technician__c.split(' ');
                String secondPart ='';
                if(lstRepairTech.size () >= 2){
                    secondPart = lstRepairTech[1];
                }   
                oProductRepair.Repair_Tech_Email__c =  oProductRepair.Repair_Technician__c.substring(0,1) + secondPart + '@probomedical.com';
            }
            
            //Update RMA Owner Email
            if(String.isNotBlank(oProductRepair.RMA_Owner__c)){
                List<String> lstRAMOwner = oProductRepair.RMA_Owner__c.split(' ');
                String secondPart ='';
                if(lstRAMOwner.size () >= 2){
                    secondPart = lstRAMOwner[1];
                }   
                oProductRepair.RMA_Owner_Email__c =  oProductRepair.RMA_Owner__c.substring(0,1) + secondPart + '@probomedical.com';
            }
            
            //Time Stamp In Process Test
            if(oProductRepair.In_Process_Test_Complete__c){
                oProductRepair.In_Process_Test_Completed_By__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
                oProductRepair.In_Process_Test_Time_Stamp__c = System.Now();
            }
            
            //Repair Result Entered
            if(oProductRepair.Repair_Result__c !=null && (oProductRepair.Repair_Result__c.equalsIgnoreCase('FAIL') || oProductRepair.Repair_Result__c.equalsIgnoreCase('SUCCESS'))){
                oProductRepair.Repair_Result_Changed_By__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
                oProductRepair.Repair_Result_Timestamp__c = System.Now();
            }
            
            // Repair Date Entered
            if(oProductRepair.Repair_date__c != null){
                oProductRepair.Part_Priority_Rating_at_Repair__c = oProductRepair.Product_Item__r.Product_Name__r.Parts_Priority_Rating__c;
            }
        }
    }
    
    
    public static void beforeUpdate1(List<Product_Repair__c> prodReps, map<Id, Product_Repair__c> oldprod){
        
        for (Product_Repair__c oProductRepair : prodReps) {
            
            Product_Repair__c oldProductRepair = oldprod.get(oProductRepair.Id);
            
            //Set Product Repair Name based on Repair Activity
            if(String.isNotBlank(oProductRepair.Repair_Activity__c) && oldProductRepair.Repair_Activity__c != oProductRepair.Repair_Activity__c){
                oProductRepair.Product_Repair_Name__c = oProductRepair.Repair_Activity__c;
            }
            
            // set No longer needed stamps
            if(oProductRepair.No_longer_needed__c && oProductRepair.No_longer_needed__c != oldProductRepair.No_longer_needed__c){
                oProductRepair.No_longer_needed_checked_by__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
                oProductRepair.Time_Stamp_No_Longer_Needed__c = System.Now();
            }   
            
            // Repair tech email update
            if(String.isNotBlank(oProductRepair.Repair_Technician__c) && !oProductRepair.Repair_Technician__c.equalsIgnoreCase('Tampa Tech') &&
               oProductRepair.Repair_Technician__c != oldProductRepair.Repair_Technician__c){
                   
                   List<String> lstRepairTech = oProductRepair.Repair_Technician__c.split(' ');
                   String secondPart ='';
                   if(lstRepairTech.size () >= 2){
                       secondPart = lstRepairTech[1];
                   }   
                   oProductRepair.Repair_Tech_Email__c =  oProductRepair.Repair_Technician__c.substring(0,1) + secondPart + '@probomedical.com';
               }
            
            //Update RMA Owner Email
            if(String.isNotBlank(oProductRepair.RMA_Owner__c) && oProductRepair.RMA_Owner__c != oldProductRepair.RMA_Owner__c){
                List<String> lstRAMOwner = oProductRepair.RMA_Owner__c.split(' ');
                String secondPart ='';
                if(lstRAMOwner.size () >= 2){
                    secondPart = lstRAMOwner[1];
                }   
                oProductRepair.RMA_Owner_Email__c =  oProductRepair.RMA_Owner__c.substring(0,1) + secondPart + '@probomedical.com';
            }
            
            //Time Stamp In Process Test
            if(oProductRepair.In_Process_Test_Complete__c && oProductRepair.In_Process_Test_Complete__c != oldProductRepair.In_Process_Test_Complete__c){
                oProductRepair.In_Process_Test_Completed_By__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
                oProductRepair.In_Process_Test_Time_Stamp__c = System.Now();
            }
            
            //Repair Result Entered
            if(oProductRepair.Repair_Result__c !=null && oProductRepair.Repair_Result__c != oldProductRepair.Repair_Result__c && (oProductRepair.Repair_Result__c.equalsIgnoreCase('FAIL') || oProductRepair.Repair_Result__c.equalsIgnoreCase('SUCCESS'))){
                oProductRepair.Repair_Result_Changed_By__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
                oProductRepair.Repair_Result_Timestamp__c = System.Now();
            }
            
            // Repair Date Entered
            if(oProductRepair.Repair_date__c != null && oProductRepair.Repair_Date__c != oldProductRepair.Repair_Date__c){
                oProductRepair.Part_Priority_Rating_at_Repair__c = oProductRepair.Product_Item__r.Product_Name__r.Parts_Priority_Rating__c;
            }
        }
    }
    
    
}