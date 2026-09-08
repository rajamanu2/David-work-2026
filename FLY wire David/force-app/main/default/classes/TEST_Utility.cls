/*
	File Name		: TEST_Utility.cls
	@description	: Utility Class for dynamically creating records as needed for other test classes
	@author			: Rich Sweetnam @ATG - Advanced Technology Group
	
Modification Log
===================================================================================================
* Ver.    Date          Author              	Modification
---------------------------------------------------------------------------------------------------
* 1.0     10/5/2021      RS @ATG					Created
*/

@isTest
public class TEST_Utility{

    // Standard Objects    
    public static void instantiateStandardPriceBook(){

        PriceBook2 standardPriceBook = new PriceBook2(
            Id=Test.getStandardPriceBookId(),
            isActive=true
        );
        update standardPriceBook;
    }
    
    public static PriceBook2 createPriceBook(String pbName){

        PriceBook2 p = new PriceBook2(
            name=pbName,
            IsActive=true
        );
        return p;
    }

    public static Product2 createProduct(String productName,String priceBooks){

        Product2 p = new Product2(
            name=productName,
            isActive=true
        );
        return p;

    }

    // CPQ Managed Objects
    public static SBQQ__PriceRule__c createPriceRule(String prName,String evalScope,String lookupObject){
        SBQQ__PriceRule__c p = new SBQQ__PriceRule__c(
            name=prName,
            SBQQ__TargetObject__c=evalScope,
            SBQQ__LookupObject__c=lookupObject,
            SBQQ__EvaluationOrder__c=1,
            SBQQ__active__c=true
        );
        return p;
    }

    public static SBQQ__LookupData__c createLookupData(String category){

        SBQQ__LookupData__c l = new SBQQ__LookupData__c(
            SBQQ__Category__c=category
        );
        return l;
    }

    public static SBQQ__PriceCondition__c createPriceCondition(Id ruleID, String targetObject, String targetField,String filterValue){

        SBQQ__PriceCondition__c p = new SBQQ__PriceCondition__c(
            SBQQ__Rule__c=ruleId,
            SBQQ__Object__c=targetObject,
            SBQQ__Field__c=targetField,
            SBQQ__Operator__c='equals',
            SBQQ__FilterType__c='value',
            SBQQ__Value__c=filterValue
        );
        return p;
    }

    public static SBQQ__LookupQuery__c createLookupQuery(Id ruleID){

        SBQQ__LookupQuery__c p = new SBQQ__LookupQuery__c(
            SBQQ__PriceRule2__c=ruleId,
            SBQQ__MatchType__c='Static Value',
            SBQQ__TestedValue__c='equals',
            SBQQ__LookupField__c='Category'
        );
        return p;
    }

    public static SBQQ__PriceAction__c createPriceAction(Id ruleId, String targetObject,String targetField,String paValue){

        SBQQ__PriceAction__c p = new SBQQ__PriceAction__c(
            SBQQ__Rule__c=ruleId,
            SBQQ__TargetObject__c=targetObject,
            SBQQ__Field__c=targetField,
            SBQQ__Value__c=paValue
        );
        return p;
    }

}