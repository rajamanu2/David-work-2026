public class P_SystemWorkOrderTriggerHandler extends GH_TriggerHandlerBase {
    protected override void beforeInsert() {}
    protected override void beforeUpdate(){
        validateStatus((List<System_Work_Order__c>) newList, (Map<Id, System_Work_Order__c>) oldMap);
    }
    protected override void beforeDelete(){}
    protected override void afterInsert(){}
    protected override void afterUpdate(){}
    protected override void afterDelete(){}
    protected override void afterUndelete(){}
    
    
    private static void validateStatus(List<System_Work_Order__c> lstTriggerNew, Map<Id, System_Work_Order__c> mapTriggerOld) {
        GH_Logger.debug('#### calling validateStatus method ####');
        Set<Id> setSystemWorkOrdersToValidate = new Set<Id>();
        Set<Id> setSystemWorkOrdersWithInvalidClosedStatus = new Set<Id>();
        
        for (System_Work_Order__c s:  lstTriggerNew) {
            System_Work_Order__c oldRecord;
            if (mapTriggerOld != null) {
                oldRecord = mapTriggerOld.get(s.Id);
            }
            
            if (s.W_O_Status__c == 'Closed' && (oldRecord == null || s.W_O_Status__c != oldRecord.W_O_Status__c)) {
                setSystemWorkOrdersToValidate.add(s.Id);
            }
        }
        
        if (!setSystemWorkOrdersToValidate.isEmpty()) {
            
            for (ProductItem__c p: [SELECT Id, Label_Printed__c, Harvest_Work_Order__c, Harvest_Work_Order__r.System_Work_Order__c FROM ProductItem__c WHERE Harvest_Work_Order__c != null AND Harvest_Work_Order__r.System_Work_Order__c IN: setSystemWorkOrdersToValidate]) {
                if (p.Label_Printed__c == false) {
                    setSystemWorkOrdersWithInvalidClosedStatus.add(p.Harvest_Work_Order__r.System_Work_Order__c);
                }
            }
            
        }
        
        for (System_Work_Order__c s:  lstTriggerNew) {
            if (!setSystemWorkOrdersWithInvalidClosedStatus.isEmpty() && setSystemWorkOrdersWithInvalidClosedStatus.contains(s.Id)) {
                GH_Logger.debug('#### found Asset with Label not printed ####');
                s.W_O_Status__c.addError('System Work Order cannot be set to Closed until all assets in the Harvest Work Orders have labels printed');
            }
        }    
    
    }
}