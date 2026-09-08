/*
	File Name		: PriceRulesFiredInitializer.cls
	@description	: Sets milestone Price Rules for the Price Rules Fired fields on the Quote and Quote Line
	@author			: Rich Sweetnam @ATG - Advanced Technology Group
	
Modification Log
===================================================================================================
* Ver.    Date          Author              	Modification
---------------------------------------------------------------------------------------------------
* 1.0     10/5/2021      RS @ATG					Created
*/

public class PriceRulesFiredInitializer{
    
    public static void initializingRecords(){        
        
        List<String> initializerNames = new List<String>{
            '-On Initialization-','-Before Calculate-','-On Calculate-','-After Calculate-'
        };
                    
        List<SBQQ__PriceRule__c> ruleInserts = new List<SBQQ__PriceRule__c>();
        List<Id> insertedIds = new List<Id>();
        
        Boolean hasConfigEdit = false;
        Boolean hasConfigSave = false;
        Boolean hasCalcInit = false;
        Boolean hasCalcBefore = false;
        Boolean hasCalcOn = false;
        Boolean hasCalcAfter = false;
        
        
        system.debug('**Begin Query for Initializer');
        for(SBQQ__Pricerule__c p:[
            SELECT Id,Name 
            FROM SBQQ__PriceRule__c 
            WHERE Name =:initializerNames
        ]){
            if(p.Name == '-On Initialization-'){
                system.debug('**hasCalcInit');
                hasCalcInit = true;
            }
            if(p.Name == '-Before Calculate-'){
                system.debug('**hasCalcBefore');
                hasCalcBefore = true;
            }
            if(p.Name == '-On Calculate-'){
                system.debug('**hasCalcOn');
                hasCalcOn = true;
            }
            if(p.Name == '-After Calculate-'){
                system.debug('**hasCalcAfter');
                hasCalcAfter = true;
            }
            
        }
        
        if(!hasCalcInit){
            system.debug('**Building hasCalcInit');
            //					   						  ruleBuilder(STRING prName,STRING evalScope,STRING configEvent,STRING calcEvent)
            SBQQ__PriceRule__c p = PriceRulesFiredBuilder.ruleBuilder('-On Initialization-','Calculator',null,'On Initialization');
            ruleInserts.add(p);
        }
        
        if(!hasCalcBefore){
            system.debug('**Building hasCalcBefore');
            //					   						  ruleBuilder(STRING prName,STRING evalScope,STRING configEvent,STRING calcEvent)
            SBQQ__PriceRule__c p = PriceRulesFiredBuilder.ruleBuilder('-Before Calculate-','Calculator',null,'Before Calculate');
            ruleInserts.add(p);
        }
        
        if(!hasCalcOn){
            system.debug('**Building hasCalcOn');
            //					   						  ruleBuilder(STRING prName,STRING evalScope,STRING configEvent,STRING calcEvent)
            SBQQ__PriceRule__c p = PriceRulesFiredBuilder.ruleBuilder('-On Calculate-','Calculator',null,'On Calculate');
            ruleInserts.add(p);
        }
        
        if(!hasCalcAfter){
            system.debug('**Building hasCalcAfter');
            //					   						  ruleBuilder(STRING prName,STRING evalScope,STRING configEvent,STRING calcEvent)
            SBQQ__PriceRule__c p = PriceRulesFiredBuilder.ruleBuilder('-After Calculate-','Calculator',null,'After Calculate');
            ruleInserts.add(p);
        }
        
        // Insert the Milestone Rules established above, and grab their IDs
        system.debug('**Inserting ruleInserts: '+ruleInserts.size());        
        Database.SaveResult[] srList = Database.insert(ruleInserts,false);
        for(Database.SaveResult sr : srList){
            if(sr.isSuccess()){
                system.debug('**isSuccess');
                insertedIds.add(sr.getId());
            }else{
                for(Database.Error objErr : sr.getErrors()){
                    system.debug('Error occurred during ruleInserts: ');
                    System.debug(objErr.getStatusCode() + ': ' + objErr.getMessage());
                    System.debug('Invoice object field which are affected by the error:' 
                                 + objErr.getFields());
                }
            }
        }
        system.debug('**insertedIds size: '+insertedIds.size());
        if(!insertedIds.isEmpty()){
            system.debug('**Sending to initializerActions');
            initializerActions();
        }
    }
    
    // Using the IDs from the Milestone Rules, create appropriate Price Actions targeting Price_Rules_Fired__c for Objects: Quote/Quote Line
    private static void initializerActions(){
        system.debug('**initializerActions Fired');
        List<SBQQ__PriceAction__c> actionInserts = new List<SBQQ__PriceAction__c>();
        
        for(SBQQ__PriceRule__c p:[
            SELECT Id,Name,SBQQ__EvaluationOrder__c,SBQQ__TargetObject__c
            FROM SBQQ__PriceRule__c
            WHERE Name LIKE '-%' AND Name LIKE '%-'
        ]){
            system.debug('Inside For Loop: '+p.Id);
            if(p.Name == '-On Initialization-'){
                SBQQ__PriceAction__c paWq = PriceRulesFiredBuilder.wipeActionBuilder(p,'Quote');
                SBQQ__PriceAction__c paWql = PriceRulesFiredBuilder.wipeActionBuilder(p,'Quote Line');
                actionInserts.add(paWq);
                actionInserts.add(paWql);
            }else{
                SBQQ__PriceAction__c paQ = PriceRulesFiredBuilder.milestoneActionBuilder(p,'Quote');
                SBQQ__PriceAction__c paQL = PriceRulesFiredBuilder.milestoneActionBuilder(p,'Quote Line');
                actionInserts.add(paQ);
                actionInserts.add(paQL);
            }
        }
        
        system.debug('**actionInserts Count: '+actionInserts.size());
        
        if(!actionInserts.isEmpty()){
            try{
                insert actionInserts;
            }catch(DMLException e){
                system.debug('Failed actionInserts: '+e);
            }
        }
    }
}