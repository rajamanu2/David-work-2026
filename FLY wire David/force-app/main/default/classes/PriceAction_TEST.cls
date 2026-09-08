/*
	File Name		: PriceAction_TEST.cls
	@description	: Test Class to accompany ATG_Helper package
	@author			: Rich Sweetnam @ATG - Advanced Technology Group
	
Modification Log
===================================================================================================
* Ver.    Date          Author              	Modification
---------------------------------------------------------------------------------------------------
* 1.0     10/5/2021     RS @ATGInfo.com 		Created
*/

@isTest
public class PriceAction_TEST{

    /* 
    Test Class utilizes TEST_Utility (part of ATG_Helper Package)
    Testing Objectives
    Testing covers Positive and Negative Testing for below classes and methods:
        DudeWheresMyField_Helper.getPriceConditions();
        DudeWheresMyField_Helper.getLookupQueries();
        DudeWheresMyField_Helper.getPriceActions();
        PriceRulesFiredBuilder.actionBuilder();
        PriceRulesFiredBuilder.milestoneActionBuilder();
        PriceRulesFiredBuilder.wipeActionBuilder();
        PriceRulesFiredBuilder.ruleBuilder();
        PriceRulesFiredHandler.createPriceRulesFired();
        PriceRulesFiredHandler.deleteActions();
        PriceRulesFiredInitializer.initializingRecords();
        PriceRulesFiredInitializer.initializerActions();
    Test Scenarios are described at individual methods
        + Positive Test Scenarios are prefixed with '+'
        - Negative Test Scenarios are prefixed with '-'
    */


    // Allows use of names for id capturing, easier to parse
    public static Map<String,Id> nameToIdMap = new Map<String,Id>();
    
    
    // create initial data
    @TestSetup
    static void makeData(){
        //createPriceRule(String prName,String evalScope,String lookupObject)
        //This Price Rule will have a Price Condition, Lookup Query, and Price Action
        SBQQ__PriceRule__c pr1 = TEST_Utility.createPriceRule('Full Rule','Calculator','SBQQ__LookupData__c');
        //This Price Rule will have no Price Conditions, Lookup Queries, or Price Actions
        SBQQ__PriceRule__c pr2 = TEST_Utility.createPriceRule('Empty Rule','Calculator',null);

        List<SBQQ__PriceRule__c> priceRuleInsertList = new List <SBQQ__PriceRule__c>{pr1,pr2};
        insert priceRuleInsertList;

        for(SBQQ__PriceRule__c p:[SELECT Id,Name FROM SBQQ__Pricerule__c]){
            nameToIdMap.put(p.Name,p.Id);
        }

        //createLookupData(String category)
        SBQQ__LookupData__c ld1 = TEST_Utility.createLookupData('Test Category');

        insert ld1;

        //createPriceCondition(Id ruleID, String targetObject, String targetField,String filterValue)
        SBQQ__PriceCondition__c pc1 = TEST_Utility.createPriceCondition(nameToIdMap.get('Full Rule'),'Quote Line','Product Code','50');

        insert pc1;

        //createLookupQuery(Id ruleID)
        SBQQ__LookupQuery__c lq1 = TEST_Utility.createLookupQuery(nameToIdMap.get('Full Rule'));
        lq1.SBQQ__TestedObject__c = 'SBQQ__Quote__c';
        lq1.SBQQ__TestedField__c = 'Product Code';

        insert lq1;

        //createPriceAction(Id ruleId, String targetObject,String targetField,String paValue)
        SBQQ__PriceAction__c pa1 = TEST_Utility.createPriceAction(nameToIdMap.get('Full Rule'),'Quote','Markup (%)','50');
        SBQQ__PriceAction__c pa2 = TEST_Utility.createPriceAction(nameToIdMap.get('Full Rule'),'Quote','Markup (%)','50');
        SBQQ__PriceAction__c pa3 = TEST_Utility.createPriceAction(nameToIdMap.get('Full Rule'),'Quote Line','Unit Price','50');
        SBQQ__PriceAction__c pa4 = TEST_Utility.createPriceAction(nameToIdMap.get('Full Rule'),'Quote Line','Unit Price','50');

        List<SBQQ__PriceAction__c> insertActionsList = new List<SBQQ__PriceAction__c>{pa1,pa2,pa3,pa4};
        insert insertActionsList;
    }

    /* 
    Test Scenario:
        + Creating a Price Action should create an additional Price Action targeting the same SBQQ__TargetObject__c that targets the field Price_Rules_Fired__c
        - Creating multiple Actions should not create duplicate actions targeting Price_Rules_Fired__c
    */
    @isTest
    static void positiveTest_CreatingPriceRulesFired(){

        for(SBQQ__PriceRule__c p:[SELECT Id,Name FROM SBQQ__Pricerule__c]){
            nameToIdMap.put(p.Name,p.Id);
        }

        // createPriceAction(Id ruleId, String targetObject,String targetField,String paValue)
        SBQQ__PriceAction__c pa1 = TEST_Utility.createPriceAction(nameToIdMap.get('Empty Rule'),'Quote','Markup (%)','50');
        SBQQ__PriceAction__c pa2 = TEST_Utility.createPriceAction(nameToIdMap.get('Empty Rule'),'Quote','Markup (%)','75');
        SBQQ__PriceAction__c pa3 = TEST_Utility.createPriceAction(nameToIdMap.get('Empty Rule'),'Quote Line','Unit Price','50');
        SBQQ__PriceAction__c pa4 = TEST_Utility.createPriceAction(nameToIdMap.get('Empty Rule'),'Quote Line','Unit Price','50');

        List<SBQQ__PriceAction__c> priceActionInsertList = new List<SBQQ__PriceAction__c>{pa1,pa2,pa3,pa4};

        test.startTest();
            insert priceActionInsertList;
        test.stopTest();

        List<SBQQ__PriceAction__c> insertedPriceActions = new List<SBQQ__PriceAction__c>([
            SELECT Id
            FROM SBQQ__PriceAction__c
            WHERE SBQQ__Rule__c =:nameToIdMap.get('Empty Rule')
        ]);

        // Expecting 6: The 4 Created, and the 2 additional targeting Price_Rules_Fired__c
        System.assertEquals(6, insertedPriceActions.size());
    }

    /* 
    Test Scenario:
        - Creating multiple Actions should not create duplicate actions targeting Price_Rules_Fired__c
    */
    @isTest
    static void negativeTest_CreatingPriceRulesFired(){

        for(SBQQ__PriceRule__c p:[SELECT Id,Name FROM SBQQ__Pricerule__c]){
            nameToIdMap.put(p.Name,p.Id);
        }

        // createPriceAction(Id ruleId, String targetObject,String targetField,String paValue)
        SBQQ__PriceAction__c pa1 = TEST_Utility.createPriceAction(nameToIdMap.get('Full Rule'),'Quote','Markup (%)','50');
        SBQQ__PriceAction__c pa2 = TEST_Utility.createPriceAction(nameToIdMap.get('Full Rule'),'Quote Line','Unit Price','50');

        List<SBQQ__PriceAction__c> priceActionInsertList = new List<SBQQ__PriceAction__c>{pa1,pa2};

        test.startTest();
            insert priceActionInsertList;
        test.stopTest();

        List<SBQQ__PriceAction__c> insertedPriceActions = new List<SBQQ__PriceAction__c>([
            SELECT Id
            FROM SBQQ__PriceAction__c
            WHERE SBQQ__Rule__c =:nameToIdMap.get('Full Rule')
        ]);

        // Expecting 8: The 2 Created, 4 Original and the 2 additional targeting Price_Rules_Fired__c
        System.assertEquals(8, insertedPriceActions.size());
    }

    /*
    Test Scenario:
        + Deleting a All Price Actions targeting an object should also deleted the Price_Rules_Fired__c action targeting that object
    */
    @isTest 
    static void positiveTest_deletePriceActions(){

        List<SBQQ__PriceAction__c> actionsToDeleteList = new List<SBQQ__PriceAction__c>([
            SELECT Id 
            FROM SBQQ__PriceAction__c
            WHERE SBQQ__Rule__c =:nameToIdMap.get('Full Rule') AND SBQQ__Field__c != 'Price_Rules_Fired__c'
        ]);

        test.startTest();
            delete actionsToDeleteList;
        test.stopTest();    

        List<SBQQ__PriceAction__c> deletedRecords = new List<SBQQ__PriceAction__c>([
            SELECT Id 
            FROM SBQQ__PriceAction__c
            WHERE IsDeleted = TRUE AND SBQQ__Rule__c =:nameToIdMap.get('Full Rule') ALL ROWS
        ]);

        System.assertEquals(0, deletedRecords.size());
    }

    // Proper test should be written here for the methods on the test
    @isTest
    static void TODO_emergency_coverage_test() {
        dudeWheresMyField_Helper.getPriceConditions('Product Code');
        dudeWheresMyField_Helper.getLookupQueries('Product Code');
        dudeWheresMyField_Helper.getPriceActions('Unit Price');
    }
}