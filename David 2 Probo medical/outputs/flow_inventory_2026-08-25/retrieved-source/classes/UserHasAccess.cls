public without sharing class UserHasAccess {
    public static Map<String, Schema.SObjectType> mapGlobalDescribe {get; set;}

	@AuraEnabled(cacheable=true)
    public static Map<String, Map<String, Boolean>> getObjectsAccess(List<String> objectNames){
       Map<String, Map<String, Boolean>> mapObjectsAccess = getObjectsAccessInfo(objectNames);
       return mapObjectsAccess;
    } 
    
    @AuraEnabled
    public static Map<String, Map<String, Boolean>> getObjectsAccessImperative(List<String> objectNames){
       Map<String, Map<String, Boolean>> mapObjectsAccess = getObjectsAccessInfo(objectNames);
       return mapObjectsAccess;
    } 
    
    public static Map<String, Map<String, Boolean>> getObjectsAccessInfo(List<String> objectNames){
       Map<String, Map<String, Boolean>> mapObjectsAccess = new Map<String, Map<String, Boolean>>();
      
        for(String s: objectNames) {
          Map<String, Boolean> mapIndividualObjectAccess = getObjectAccess(s);
          mapObjectsAccess.put(s, mapIndividualObjectAccess);
        }
        
        system.debug('mapObjectsAccess: ' + mapObjectsAccess);
        return mapObjectsAccess;
    } 

    @AuraEnabled
    public static Map<String, Boolean> getObjectAccess(String objectName){
        Map<String, Boolean> mapObjectAccess = new Map<String, Boolean>();
        Boolean isAccessible = hasObjectReadAccess(objectName);
        mapObjectAccess.put('Read', isAccessible);  
        Boolean isCreatable = hasObjectCreateAccess(objectName);
        mapObjectAccess.put('Create', isCreatable); 
        Boolean isUpdatetable = hasObjectEditAccess(objectName);
        mapObjectAccess.put('Edit', isUpdatetable);
        Boolean isDeletable = hasObjectDeleteAccess(objectName);
        mapObjectAccess.put('Delete', isDeletable); 
        
        return mapObjectAccess;
    }    
    
    @AuraEnabled
    public static Boolean hasObjectReadAccess(String objectName){
        Schema.DescribeSObjectResult objectResult = getObjectResult(objectName); 
        return objectResult.isAccessible();
    }  
    
    @AuraEnabled
    public static Boolean hasObjectCreateAccess(String objectName){
        Schema.DescribeSObjectResult objectResult = getObjectResult(objectName); 
        return objectResult.isCreateable();
    }  
    
    @AuraEnabled
    public static Boolean hasObjectEditAccess(String objectName){
        Schema.DescribeSObjectResult objectResult = getObjectResult(objectName); 
        return objectResult.isCreateable();
    } 
    
    @AuraEnabled
    public static Boolean hasObjectDeleteAccess(String objectName){
        Schema.DescribeSObjectResult objectResult = getObjectResult(objectName); 
        return objectResult.isDeletable();
    }  

    private static Schema.DescribeSObjectResult getObjectResult(String objectName){
       if (mapGlobalDescribe == null) {
            mapGlobalDescribe = Schema.getGlobalDescribe();  
        } 
        
        Schema.DescribeSObjectResult objectResult = mapGlobalDescribe.get(objectName).getDescribe();  
        return objectResult;
    } 
    
    public static Boolean hasPermissionSetAccess(String permissionSetName) {
        Boolean hasPermissions = false;
       
        for (PermissionSetAssignment p: [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name =: permissionSetName]) {
            if (p.AssigneeId == userInfo.getUserId()) {
                hasPermissions = true; 
                break;
            }
        }
        
       	return hasPermissions;
    }


}