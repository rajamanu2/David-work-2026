/*
	File Name		: dudeWheresMyField_TEST.cls
	@description	: Test Class to accompany ATG_Helper package
	@author			: Rich Sweetnam @ATG - Advanced Technology Group
	
Modification Log
===================================================================================================
* Ver.    Date          Author              	Modification
---------------------------------------------------------------------------------------------------
* 1.0     10/5/2021     RS @ATGInfo.com 		Created
*/

@IsTest
public with sharing class dudeWheresMyField_TEST {

    @IsTest
    public static void testRefresher(){

        Test.startTest();
            PriceRulesFiredHandler.refresher();
        Test.stopTest();

    }
}