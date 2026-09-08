public class RecordTypeUtility {
    // Utility for fetching record types
    public static Map<String,Map<String,ID>> recordTypesByObjectByDev{get;set;}
    public static Map<String,Map<String,ID>> recordTypesByObjectByName{get;set;}
    
    public static id getRecordTypeID(String sObjectName,String RecordType){
        id recTypeID = getRecordTypeByDeveloperName(sObjectName,RecordType);
        if(recTypeID == null){
            recTypeID = getRecordTypeByName(sObjectName,RecordType);
        }
        return recTypeID;
    }
    
    public static Map<String,ID> getAllRecordTypesByName(String sObjectName){

        if(recordTypesByObjectByName == null ){
            recordTypesByObjectByName = new map<String,Map<String,ID>>();
        }
        
        if(recordTypesByObjectByName != null && recordTypesByObjectByName.containsKey(sObjectName)){
            return recordTypesByObjectByName.get(sObjectName);
        }
        
        Schema.DescribeSObjectResult sobjectResult = Schema.getGlobalDescribe().get(sObjectName).getDescribe();
        List<Schema.RecordTypeInfo> recordTypeInfo = sobjectResult.getRecordTypeInfos();
        Map<String,Id> recordTypes = new Map<String,Id>();
        for(Schema.RecordTypeInfo info : recordTypeInfo){
            if (info.isActive()) {
                recordTypes.put(info.getName(),info.getRecordTypeId());
            }
        }
        
        recordTypesByObjectByName.put(sObjectName,recordTypes);
        
        return recordTypes;
        
    }
    
    public static ID getRecordTypeByName(String sObjectName, String recordTypeName){
        return getAllRecordTypesByName(sObjectName).get(recordTypeName);
    }
    
    public static ID getRecordTypeByDeveloperName(String sObjectName, String DeveloperName){
        return getAllRecordTypesByDevName(sObjectName).get(DeveloperName);
    }
    
    public static Map<String,ID> getAllRecordTypesByDevName(String sObjectName){
        
        if(recordTypesByObjectByDev == null){
            recordTypesByObjectByDev = new Map<String,Map<String,ID>>();
        }
        
        if(recordTypesByObjectByDev.containsKey(sObjectName)){
            return recordTypesByObjectByDev.get(sObjectName);
        }
        
        map<String,ID> mapResults = new map<String,ID>();
        for(RecordType rt: [Select Id, DeveloperName from RecordType WHERE SobjectType =: sObjectName]){
            mapResults.put(rt.DeveloperName,rt.id);
        }
        
        recordTypesByObjectByDev.put(sObjectName,mapResults);
        return mapResults;
    }
    
    @AuraEnabled
    public static Object getRecordTypePickListValues(String sObjectName){
        List<Option> recordTypeOptions = new List<Option>();
        Map<String,Id> recordTypesForObject = new Map<String,Id>();
        
        recordTypesForObject = getAllRecordTypesByName(sObjectName);
        
        for (String s: recordTypesForObject.keySet()) {
            Option recordTypeOption = new Option(s, recordTypesForObject.get(s));
            recordTypeOptions.add(recordTypeOption);
        }       
        
        GH_Logger.debug('calling getRecordTypePickListValues. return value: ' + recordTypeOptions);
        return recordTypeOptions;
    }
    
    public class Option {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled       
        public String value {get;set;}
        
        public Option(String label, String value){
            this.label = label;
            this.value = value;
        }
        
    }
}