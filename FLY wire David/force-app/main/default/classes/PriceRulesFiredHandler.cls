/*
	File Name		: PriceRulesFiredBuilder.cls
	@description	: Handler for PriceRulesFired
						- Creates a Price Action when a Price Action targets a Quote or Quote Line
						- Populates that Price Action to paste into respective Price_Rules_Fired__c field
							- Populates with: Price_Rules_Fired__c Prior Value | <line break> Rule Name | Evaluation Order | Rule ID
	@author			: Rich Sweetnam @ATG - Advanced Technology Group
	
Modification Log
===================================================================================================
* Ver.    Date          Author              	Modification
---------------------------------------------------------------------------------------------------
* 1.0     10/5/2021      RS @ATG					Created
*/

public class PriceRulesFiredHandler extends TriggerHandler{

    protected override void afterInsert(){
        createPriceRulesFired(trigger.new);
        PriceRulesFiredInitializer.initializingRecords();
    }

    protected override void afterDelete(){
        createPriceRulesFired(trigger.old); 
        PriceRulesFiredInitializer.initializingRecords();
    }
    
    // Checks if the Milestone Price Rules exist, if they do not, create them
    // Runs when a Price Action is acted upon (Insert/Update/Delete) to ensure Milestones exist
    public static void createPriceRulesFired(List<SBQQ__PriceAction__c> newList){
        
        Map<Id,Boolean> ruleHasQuote = new Map<Id,Boolean>();
        Map<Id,Boolean> ruleHasQuoteLine = new Map<Id,Boolean>();
        Map<Id,Boolean> ruleNeedsQuote = new Map<Id,Boolean>();
        Map<Id,Boolean> ruleNeedsQuoteLine = new Map<Id,Boolean>();
        Map<String,Id> prfActionIdMap = new Map<String,Id>();
        List<SBQQ__PriceAction__c> actionInserts = new List<SBQQ__PriceAction__c>();
        Set<Id> ruleIdSet = new Set<ID>();
        Set<Id> actionDeleteIdSet = new Set<Id>();

		// Queries Price Rules in the system to check for Milestone Price Rules        
        for(SBQQ__PriceAction__c p:newList){
                system.debug('creating ruleIdSet: '+p.SBQQ__Rule__c);
                ruleIdSet.add(p.SBQQ__Rule__c);
        }
        
        // Establishes baseline of 'false' for each Milestone 
        if(!ruleIdSet.isEmpty()){
            system.debug('Iterating to create ruleIdSet');
            for(Id i:ruleIdSet){
                ruleHasQuote.put(i,false);
                ruleHasQuoteLine.put(i,false);
                ruleNeedsQuote.put(i,false);
                ruleNeedsQuoteLine.put(i,false);
            }
            
            // Iteration of Price Rules to catch if the Price Rule is one of the pre-determined Milestone Price Rule and flags as true
            system.debug('Iterating to set Maps');
            for(SBQQ__PriceAction__c p:[
                SELECT Id,SBQQ__TargetObject__c,SBQQ__Field__c,SBQQ__Rule__c
                FROM SBQQ__PriceAction__c 
                WHERE SBQQ__Rule__c =:ruleIdSet
            ]){
                Boolean hasQuote;
                Boolean hasQuoteLine;
                Boolean needsQuote;
                Boolean needsQuoteLine;
                if(p.SBQQ__TargetObject__c == 'Quote' && p.SBQQ__Field__c == 'Price_Rules_Fired__c'){
                    system.debug('ruleHasQuote True: '+p.SBQQ__Rule__c+' || '+p.SBQQ__TargetObject__c+' || '+p.SBQQ__Field__c);
                    ruleHasQuote.put(p.SBQQ__Rule__c,true);
                    prfActionIdMap.put(p.SBQQ__Rule__c+'Quote',p.Id);
                }
                if(p.SBQQ__TargetObject__c == 'Quote' && p.SBQQ__Field__c != 'Price_Rules_Fired__c'){
                    system.debug('ruleNeedsQuote True: '+p.SBQQ__Rule__c+' || '+p.SBQQ__TargetObject__c+' || '+p.SBQQ__Field__c);
                    ruleNeedsQuote.put(p.SBQQ__Rule__c,true);
                }
                if(p.SBQQ__TargetObject__c == 'Quote Line' && p.SBQQ__Field__c == 'Price_Rules_Fired__c'){
                    system.debug('ruleHasQuoteLine True: '+p.SBQQ__Rule__c+' || '+p.SBQQ__TargetObject__c+' || '+p.SBQQ__Field__c);
                    ruleHasQuoteLine.put(p.SBQQ__Rule__c,true);
                    prfActionIdMap.put(p.SBQQ__Rule__c+'Quote Line',p.Id);
                }
                if(p.SBQQ__TargetObject__c == 'Quote Line' && p.SBQQ__Field__c != 'Price_Rules_Fired__c'){
                    system.debug('ruleNeedsQuoteLine True: '+p.SBQQ__Rule__c+' || '+p.SBQQ__TargetObject__c+' || '+p.SBQQ__Field__c);
                    ruleNeedsQuoteLine.put(p.SBQQ__Rule__c,true);
                }
            }
        } 
        
        // Iterates through the list of existing Actions per Rule to determine if remaining Price Rules Fired targeting actions need to continue to exist
        for(SBQQ__PriceRule__c p:[
            SELECT Id,Name,SBQQ__EvaluationOrder__c
            FROM SBQQ__PriceRule__c
            WHERE Id=:ruleIdSet AND (NOT Name Like '-%') AND (NOT Name Like '%-')
        ]){
            if(!ruleHasQuote.get(p.Id) && ruleNeedsQuote.get(p.Id)){
                system.debug('Creating Quote');
                SBQQ__PriceAction__c a = PriceRulesFiredBuilder.actionBuilder(p,'Quote');
                actionInserts.add(a);
            }
            if(ruleHasQuote.get(p.Id) && !ruleNeedsQuote.get(p.Id)){
                system.debug('Deleting Quote: '+prfActionIdMap.get(p.Id+'Quote Line'));
                actionDeleteIdSet.add(prfActionIdMap.get(p.Id+'Quote'));    
            }
            if(!ruleHasQuoteLine.get(p.Id) && ruleNeedsQuoteLine.get(p.Id)){
                system.debug('Creating Quote');
                SBQQ__PriceAction__c a = PriceRulesFiredBuilder.actionBuilder(p,'Quote Line');
                actionInserts.add(a);
            }
            if(ruleHasQuoteLine.get(p.Id) && !ruleNeedsQuoteLine.get(p.Id)){
                system.debug('Deleting QuoteLine: '+prfActionIdMap.get(p.Id+'Quote Line'));
                actionDeleteIdSet.add(prfActionIdMap.get(p.Id+'Quote Line'));
            }
        }
        
        if(!actionInserts.isEmpty()){
            insert actionInserts;
        }
        
        if(!actionDeleteIdSet.isEmpty()){
            // deleteActions(Set<Id> idDeletes)
            deleteActions(actionDeleteIdSet);
        }
    }
    
    // Deletes the Price Actions that target Price_Rules_Fired__c if the Price Rule no longer targets the respective Object (Quote/Quote Line)
    public static void deleteActions(Set<Id> idDeletes){
        system.debug('Running Deletes');
        List<SBQQ__PriceAction__c> deleteList = new List<SBQQ__PriceAction__c>([
            SELECT Id 
            FROM SBQQ__PriceAction__c
            WHERE Id =:idDeletes
        ]);
        delete deleteList;
    }
    
    // Lightning Web Component that will wipe the Milestone Rules and Price Actions targeting Price_Rules_Fired__c
    // Deleting these will trigger the builder to re-buld the Milestone Rules and Price Actions targeting Price_Rules_Fired__c
    @TestVisible
    @AuraEnabled
    public static String refresher(){

        String lastRefresh;

        List<String> initializerNames = new List<String>{
            '-On Initialization-','-Before Calculate-','-On Calculate-','-After Calculate-'
        };
        List<SBQQ__PriceRule__c> initializerRules = new list<SBQQ__PriceRule__c>([
                SELECT Id 
                FROM SBQQ__PriceRule__c 
                WHERE Name =:initializerNames]);
        if(!initializerRules.isEmpty()){
            delete initializerRules;
        }
        
        List<SBQQ__PriceAction__c> priceRulesFiredActions = new List<SBQQ__PriceAction__c>([
            SELECT ID
            FROM SBQQ__PriceAction__c
            WHERE SBQQ__Field__c = 'Price_Rules_Fired__c'
        ]);
        
        system.debug('** priceRulesFiredActions size:'+priceRulesFiredActions.size());
        
        if(!priceRulesFiredActions.isEmpty()){
            delete priceRulesFiredActions;
        }
        
        List<SBQQ__PriceAction__c> priceActions = new List<SBQQ__PriceAction__c>([
            SELECT Id,SBQQ__Rule__c
            FROM SBQQ__PriceAction__c
        ]);
        
        if(!priceActions.isEmpty()){
            createPriceRulesFired(priceactions);
        }

        lastRefresh = System.Now().format();
        return lastRefresh;
    }

    // Lightnig Web Component Code for Displaying that the Refresh was run
    @TestVisible
    @AuraEnabled
    public static string getLastRefreshRun(){

        String lastRefresh;

        SBQQ__PriceRule__c onInitialization = [SELECT Id,CreatedDate FROM SBQQ__PriceRule__c WHERE Name = '-On Initialization-' LIMIT 1];

        lastRefresh = onInitialization.CreatedDate.format();

        system.debug('Last Refresh: '+lastRefresh);

        return lastRefresh;
    }
}