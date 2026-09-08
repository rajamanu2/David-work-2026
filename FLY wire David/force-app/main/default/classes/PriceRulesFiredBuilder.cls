/*
	File Name		: PriceRulesFiredBuilder.cls
	@description	: Builder methods for the Price Rules and Price Actions for PriceRulesFiredHandler
	@author			: Rich Sweetnam @ATG - Advanced Technology Group
	
Modification Log
===================================================================================================
* Ver.    Date          Author              	Modification
---------------------------------------------------------------------------------------------------
* 1.0     10/5/2021      RS @ATG					Created
*/

public class PriceRulesFiredBuilder{
    private static STRING FIELD = 'Price_Rules_Fired__c';
    
    // Returns standard Price Action targeting Price_Rules_Fired__c
    public static SBQQ__PriceAction__c actionBuilder(SBQQ__PriceRule__c priceRule,STRING objectName){
        STRING formula = FIELD+'+"<br/><li>Rule:'+priceRule.Name+' || Order: '+priceRule.SBQQ__EvaluationOrder__c+' || Id: '+priceRule.id+'</li>"';
        SBQQ__PriceAction__c a=new SBQQ__PriceAction__c(
            SBQQ__Rule__c=priceRule.Id,
            SBQQ__TargetObject__c=objectName,
            SBQQ__Field__c= FIELD,
            SBQQ__Formula__c=formula
        );
        return a;
    }
    
    // Return Price Action for Price Rules Fired
    public static SBQQ__PriceAction__c milestoneActionBuilder(SBQQ__PriceRule__c priceRule,STRING objectName){
        STRING formula = FIELD+'+"<br/><b>'+priceRule.Name+'</b>"';
        SBQQ__PriceAction__c a=new SBQQ__PriceAction__c(
            SBQQ__Rule__c=priceRule.Id,
            SBQQ__TargetObject__c=objectName,
            SBQQ__Field__c= FIELD,
            SBQQ__Formula__c=formula
        );
        return a;
    }
    
    // Return Price Action for Price Rules Fired
    public static SBQQ__PriceAction__c wipeActionBuilder(SBQQ__PriceRule__c priceRule,STRING objectName){
        STRING formula = '"<b>'+priceRule.Name+'</b>"';
        SBQQ__PriceAction__c a=new SBQQ__PriceAction__c(
            SBQQ__Rule__c=priceRule.Id,
            SBQQ__TargetObject__c=objectName,
            SBQQ__Field__c= FIELD,
            SBQQ__Formula__c= formula
        );
        return a;
    }
    
    public static SBQQ__PriceRule__c ruleBuilder(STRING prName,STRING evalScope,STRING configEvent,STRING calcEvent){
        INTEGER evalOrder = 0;
        SBQQ__PriceRule__c p = new SBQQ__PriceRule__c(
            Name = prName,
            SBQQ__TargetObject__c = evalScope,
            SBQQ__ConfiguratorEvaluationEvent__c = configEvent,
            SBQQ__EvaluationEvent__c = calcEvent,
            SBQQ__EvaluationOrder__c = evalOrder,
            SBQQ__Active__c = true
        );
        
        return p;
    }
    
}