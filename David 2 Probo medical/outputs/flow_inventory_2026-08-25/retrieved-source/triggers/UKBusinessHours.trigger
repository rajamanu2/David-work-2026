trigger UKBusinessHours on WorkOrder (before update) {
    //Selecting UK business hours (BH) record
    BusinessHours ukBH = [SELECT Id FROM BusinessHours WHERE Name = 'UK Business Hours' Limit 1];
    //Making sure BH record exists
    if(ukBH != NULL){
        for(WorkOrder WOobj : trigger.new ){
            //Making sure that Service Completed Date field is populated and is updated
            if(WOobj.Service_Completed_Date__c != NULL && Trigger.oldMap.get(WOobj.Id).Service_Completed_Date__c != WOobj.Service_Completed_Date__c){
                //For BH method we assign (BH record id, start time field, end time field)
                decimal result = BusinessHours.diff(ukBH.Id, WOobj.StartDate, WOobj.Service_Completed_Date__c );
                //Result from the method is divided by 60*60*100 (milliseconds to be then converted into hours)
                Decimal resultingHours = result/(60*60*1000);
                //Populating result into our custom field & setting number of decimals
                WOobj.Total_Down_Time_Calculated__c = resultingHours.setScale(1); 
            }  
        }    
    } 
}