/**
* @author Delagate
* @date 4/26/2021
*
* @description Tests for testing PB Opportunity Item
*/

@isTest
public with sharing class PB_OpportunityItemTests {
    @isTest
    public static void TestDeleteOpportunityItem() {
        test.startTest();
        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity('Sales Opportunity', acc.Id, false);
        User u = TestDataFactory.createUser('fName', 'lName', false);
        u.Location__c = 'Tulsa, OK';
        insert u;
        opp.OwnerId = u.Id;
        insert opp;
        opp = [SELECT OwnerId
                FROM Opportunity
                LIMIT 1];
        System.debug('CC...' + opp.OwnerId);
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', 'Test Product', 'Ultrasound Probe', true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Purchasing_Approved__c = true;
        pi.Generic_Product__c = false;
        pi.sold__c = true; 
        insert pi;
        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, false);
        oli.Opportunity = opp;
        insert oli;
        delete oli;
        test.stopTest();
    }
    @isTest
    public static void TestSetRecordType() {
        test.startTest();
        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity('Sales Opportunity', acc.Id, false);
        User u = TestDataFactory.createUser('fName', 'lName', false);
        u.Location__c = 'Tulsa, OK';
        insert u;
        opp.OwnerId = u.Id;
        insert opp;
        opp = [SELECT OwnerId
                FROM Opportunity
                LIMIT 1];
        System.debug('CC...' + opp.OwnerId);
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', 'Test Product', 'Ultrasound Probe', true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Purchasing_Approved__c = true;
        pi.Generic_Product__c = false;
        pi.sold__c = true; 
        insert pi;
        OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(opp.Id, pbe.Id, pi.Id, false);
        oli.Opportunity = opp;
        insert oli;
        test.stopTest();
        System.debug('CC...' + oli.ProductItem__c);
        ProductItem__c item = [SELECT Opportunity_Record_Type__c, Physical_Location__c
                                FROM ProductItem__c
                                WHERE Id = :oli.ProductItem__c
                                LIMIT 1];
        System.assertequals(item.Physical_Location__c, 'Tulsa, OK');
        System.assertequals(item.Opportunity_Record_Type__c, 'Sales Opportunity');
    }
}