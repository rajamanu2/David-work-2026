public class BypassTriggerAction {
    public class BypassTriggerInput {
        @InvocableVariable(required=true description='Object trigger API name - i.e. ProductItem__c')
        public String objectTrigger;
    
        @InvocableVariable(required=true description='Set to true to bypass; false to reset')
        public Boolean setAction;
    
    }
    
    @invocableMethod(label='Bypass Trigger'
                    description='Set object trigger and boolean variable to bypass trigger')
    public static void bypassTrigger(List<BypassTriggerInput> bypassInput){
        for (BypassTriggerInput bypass : bypassInput) {
            String triggerName = bypass.objectTrigger;
            Boolean bypassAction = bypass.SetAction;
            switch on triggerName {
                when 'Opportunity' {
                    if(bypassAction){
                        Validator_Class.SetByPassOppTrigger(true);
                    }
                    else{
                        Validator_Class.SetByPassOppTrigger(false);
                    }
                }
                when 'ProductItem__c' {
                    if(bypassAction){
                        Validator_Class.SetByPassProductItemTrigger(true);
                    }
                    else{
                        Validator_Class.SetByPassProductItemTrigger(false);
                    }
                    
                }
                when 'Review_Status__c' {
                    if(bypassAction){
                        Validator_Class.SetByPassReviewTrigger(true);
                    }
                    else{
                        Validator_Class.SetByPassReviewTrigger(false);
                    }
                    
                }
                when 'RMA__c' {
                    if(bypassAction){
                        Validator_Class.SetByPassRMATrigger(true);
                    }
                    else{
                        Validator_Class.SetByPassRMATrigger(false);
                    }
                    
                }
            }
            
        }
        
        
    }
    
   

}