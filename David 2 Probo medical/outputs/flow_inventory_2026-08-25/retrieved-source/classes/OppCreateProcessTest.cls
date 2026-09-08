/**
* @author Delagate
* @date 7/21/2021
*
* @description Test class to test current process from 
*/

@isTest
public with sharing class OppCreateProcessTest {
    @TestSetup
    static void makeData(){
        TestDataFactory.createAccountsWithContacts(1,1);
        TestDataFactory.createUser('Unit', 'Tester', true);
    }
    @isTest
    public static void TestContactIsAssigned() {
        User u = [SELECT ID, Email
                    FROM User
                    WHERE Name = 'Unit Tester'];
        Account acct = [SELECT ID  
                        FROM Account
                        LIMIT 1];
        Opportunity opp = TestDataFactory.createOpportunity('Lost Probe Opportunity', acct.Id, false);
        Contact con = [SELECT Id       
                        FROM Contact
                        LIMIT 1]; 
        con.OwnerId = u.Id;
        update con;
        opp.Contact_Lookup__c = con.Id;
        opp.LeadSource = 'Call In';
        opp.Lead_Source_Detail__c = 'Facebook';
        insert opp;
        opp = [SELECT OwnerId, Contact_Owner_Email__c
                FROM Opportunity
                LIMIT 1];
        System.debug(opp.Contact_Owner_Email__c);
        System.assertEquals(opp.OwnerId, u.Id, 'OwnerId Not Assigned');
        System.assertEquals(opp.Contact_Owner_Email__c, u.Email, 'Contact Owner Email Not Assigned');
    }
    @isTest
    public static void TestContactNotAssignedMatchedLeadSourceDetail() {
        User u = [SELECT ID
                    FROM User
                    WHERE Name = 'Unit Tester'];
        Account acct = [SELECT ID  
                        FROM Account
                        LIMIT 1];
        Opportunity opp = TestDataFactory.createOpportunity('Lost Probe Opportunity', acct.Id, false);
        Contact con = [SELECT Id       
                        FROM Contact
                        LIMIT 1]; 
        con.OwnerId = u.Id;
        update con;
        opp.Contact_Lookup__c = con.Id;
        opp.LeadSource = 'Call In';
        opp.Lead_Source_Detail__c = 'Return Customer';
        insert opp;
        opp = [SELECT OwnerId, Contact_Owner_Email__c
                FROM Opportunity
                LIMIT 1];
        System.assertEquals(opp.OwnerId, UserInfo.getUserId());
    }
    @isTest
    public static void TestContactNotAssignedMatchedLeadSource() {
        User u = [SELECT ID
                    FROM User
                    WHERE Name = 'Unit Tester'];
        Account acct = [SELECT ID  
                        FROM Account
                        LIMIT 1];
        Opportunity opp = TestDataFactory.createOpportunity('Lost Probe Opportunity', acct.Id, false);
        Contact con = [SELECT Id       
                        FROM Contact
                        LIMIT 1]; 
        con.OwnerId = u.Id;
        update con;
        opp.Contact_Lookup__c = con.Id;
        opp.LeadSource = 'Web Lead - Form Submission';
        opp.Lead_Source_Detail__c = 'Facebook';
        insert opp;
        opp = [SELECT OwnerId, Contact_Owner_Email__c
                FROM Opportunity
                LIMIT 1];
        System.assertEquals(opp.OwnerId, UserInfo.getUserId());
    }
}