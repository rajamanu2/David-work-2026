/**
* @author Delagate
* @date 7/21/2021
*
* @description Breaking out of the P_OpportunityTriggerHandler for readability
*/

public with sharing class P_OpportunityTriggerHandler2 {
    public static void AssignByContactLookup(List<Opportunity> opps) {
        List<Opportunity> updatedOpps = new List<Opportunity>();
        List<Id> contactIds = new List<Id>();
        for(Opportunity opp : opps) {
            if(opp.Contact_Lookup__c != null && opp.LeadSource != 'Web Lead - Form Submission' && opp.Lead_Source_Detail__c != 'Return Customer') {
                contactIds.add(opp.Contact_Lookup__c); 
                updatedOpps.add(opp);
            }
        }
        List<Contact> cons = [SELECT Id, OwnerId, Owner.Email
                                FROM Contact
                                WHERE Id in :contactIds];
        Map<Id, Contact> conMap = new Map<Id, Contact>();
        for(Contact con : cons) {
            conMap.put(con.Id, con);
        }
        for(Opportunity opp : updatedOpps) {
            Contact con = conMap.get(opp.Contact_Lookup__c);
            opp.Contact_Owner_Email__c = con.Owner.Email;
            //Owner removed 06.24.24
            //opp.OwnerId = con.OwnerId;
        }
    }
}