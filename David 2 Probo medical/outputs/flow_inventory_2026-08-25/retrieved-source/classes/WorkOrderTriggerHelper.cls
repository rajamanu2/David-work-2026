public class WorkOrderTriggerHelper {
    
    public void handler (Boolean isAfter, Boolean isBefore, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, List<WorkOrder> newList, List<WorkOrder> oldList, Map<Id,WorkOrder> newMap, Map<Id,WorkOrder> OldMap) {
        if (isBefore) {
            for (WorkOrder wo : newList) {
                List<String> techIds;
                String fieldServiceEngineers = '';
                if (isInsert) {
                    if (wo.Service_Fusion_Techs__c != null) {
                        techIds = wo.Service_Fusion_Techs__c.split(';');
                        List<Field_Service_Engineer__c> techs = [SELECT Id, Name, Service_Fusion_ID__c FROM Field_Service_Engineer__c WHERE Service_Fusion_ID__c in: techIds];
                        for (Field_Service_Engineer__c fse : techs) {
                            fieldServiceEngineers += fse.Name + ';';
                        } 
                        wo.Field_Service_Engineer__c = fieldServiceEngineers;
                    } else if (wo.Field_Service_Engineer__c != null) {
                        techIds = wo.Field_Service_Engineer__c.split(';');
                        List<Field_Service_Engineer__c> techs = [SELECT Id, Name, Service_Fusion_ID__c FROM Field_Service_Engineer__c WHERE Name in: techIds];
                        for (Field_Service_Engineer__c fse : techs) {
                            fieldServiceEngineers += fse.Service_Fusion_ID__c + ';';
                        } 
                        wo.Service_Fusion_Techs__c = fieldServiceEngineers;
                    }
                } else if (isUpdate) {
                    if (wo.Service_Fusion_Techs__c != null && wo.Service_Fusion_Techs__c != oldMap.get(wo.Id).Service_Fusion_Techs__c) {
                        techIds = wo.Service_Fusion_Techs__c.split(';');
                        List<Field_Service_Engineer__c> techs = [SELECT Id, Name, Service_Fusion_ID__c FROM Field_Service_Engineer__c WHERE Service_Fusion_ID__c in: techIds];
                        for (Field_Service_Engineer__c fse : techs) {
                            fieldServiceEngineers += fse.Name + ';';
                        } 
                        wo.Field_Service_Engineer__c = fieldServiceEngineers;
                    } else if (wo.Field_Service_Engineer__c != null && wo.Field_Service_Engineer__c != oldMap.get(wo.Id).Field_Service_Engineer__c) {
                        techIds = wo.Field_Service_Engineer__c.split(';');
                        List<Field_Service_Engineer__c> techs = [SELECT Id, Name, Service_Fusion_ID__c FROM Field_Service_Engineer__c WHERE Name in: techIds];
                        for (Field_Service_Engineer__c fse : techs) {
                            fieldServiceEngineers += fse.Service_Fusion_ID__c + ';';
                        } 
                        wo.Service_Fusion_Techs__c = fieldServiceEngineers;
                    }
                }
            }
        }
    }
    
}