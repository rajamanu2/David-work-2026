/*
	File Name		: dudeWheresMyField_Helper.cls
	@description	: Gathers information for ATG Helper Lightning Page
	@author			: Rich Sweetnam @ATG - Advanced Technology Group
	
Modification Log
===================================================================================================
* Ver.    Date          Author              	Modification
---------------------------------------------------------------------------------------------------
* 1.0     10/5/2021     RS @ATGInfo.com 		Created
*/

public with sharing class dudeWheresMyField_Helper {

    @auraEnabled(cacheable=true)
    public static List<DataTableWrapper> getPriceConditions(String searchAPI) {

        List<DataTableWrapper> response = new List<DataTableWrapper>();

        for(SBQQ__PriceCondition__c p:[
            SELECT Id,Name,SBQQ__Rule__r.Sort_Order__c,SBQQ__Rule__r.Name,SBQQ__Rule__r.Id,SBQQ__ParentRuleIsActive__c
            FROM SBQQ__PriceCondition__c
            WHERE SBQQ__Field__c =: searchAPI
            ORDER BY SBQQ__Rule__r.Sort_Order__c
        ]){
            DataTableWrapper obj = new DataTableWrapper();
                obj.recordID = p.Id;
                obj.ruleID = p.SBQQ__Rule__r.Id;
                obj.ruleName = p.SBQQ__Rule__r.Name;
                obj.recordName = p.Name;
                obj.sortOrder = p.SBQQ__Rule__r.Sort_Order__c;
                obj.nameURL = '/'+p.Id;
                obj.ruleURL = '/'+p.SBQQ__Rule__r.Id;
                obj.isActive = p.SBQQ__ParentRuleIsActive__c;
                response.add(obj);
        }
        return response;

    }

    @auraEnabled(cacheable=true)
    public static List<DataTableWrapper> getLookupQueries(String searchAPI) {

        List<DataTableWrapper> response = new List<DataTableWrapper>();

        for(SBQQ__LookupQuery__c p:[
            SELECT Id,Name,SBQQ__PriceRule2__r.Sort_Order__c,SBQQ__PriceRule2__r.Name,SBQQ__PriceRule2__r.Id,SBQQ__ParentRuleIsActive__c
            FROM SBQQ__LookupQuery__c
            WHERE SBQQ__TestedField__c =: searchAPI
            ORDER BY SBQQ__PriceRule2__r.Sort_Order__c
        ]){
            DataTableWrapper obj = new DataTableWrapper();
                obj.recordID = p.Id;
                obj.ruleID = p.SBQQ__PriceRule2__r.Id;
                obj.ruleName = p.SBQQ__PriceRule2__r.Name;
                obj.recordName = p.Name;
                obj.sortOrder = p.SBQQ__PriceRule2__r.Sort_Order__c;
                obj.nameURL = '/'+p.Id;
                obj.ruleURL = '/'+p.SBQQ__PriceRule2__r.Id;
                obj.isActive = p.SBQQ__ParentRuleIsActive__c;
                response.add(obj);
        }
        return response;

    }

    @auraEnabled(cacheable=true)
    public static List<DataTableWrapper> getPriceActions(String searchAPI) {

        List<DataTableWrapper> response = new List<DataTableWrapper>();

        for(SBQQ__PriceAction__c p:[
            SELECT Id,Name,SBQQ__Rule__r.Sort_Order__c,SBQQ__Rule__r.Name,SBQQ__Rule__r.Id,SBQQ__ParentRuleIsActive__c,SBQQ__TargetObject__c
            FROM SBQQ__PriceAction__c
            WHERE SBQQ__Field__c =: searchAPI
            ORDER BY SBQQ__Rule__r.Sort_Order__c
        ]){
            DataTableWrapper obj = new DataTableWrapper();
                obj.recordID = p.Id;
                obj.ruleID = p.SBQQ__Rule__r.Id;
                obj.ruleName = p.SBQQ__Rule__r.Name;
                obj.recordName = p.Name;
                obj.sortOrder = p.SBQQ__Rule__r.Sort_Order__c;
                obj.nameURL = '/'+p.Id;
                obj.ruleURL = '/'+p.SBQQ__Rule__r.Id;
                obj.isActive = p.SBQQ__ParentRuleIsActive__c;
                response.add(obj);
        }
        return response;

    }

    private class DataTableWrapper {
        @AuraEnabled
        public Id recordID {get;set;}
        @AuraEnabled
        public Id ruleID {get;set;}
        @AuraEnabled
        public String recordName {get;set;}
        @AuraEnabled
        public String nameURL {get;set;}
        @AuraEnabled
        public String ruleURL {get;set;}
        @AuraEnabled
        public String sortOrder {get;set;}
        @AuraEnabled
        public String ruleName {get;set;}
        @AuraEnabled 
        public Boolean isActive {get;set;}
        @AuraEnabled
        public Id tObject {get;set;}
    }
}