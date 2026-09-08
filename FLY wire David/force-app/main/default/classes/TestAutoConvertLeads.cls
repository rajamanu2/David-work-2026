@isTest 
      public class TestAutoConvertLeads{
      static testMethod void createnewlead() {
          User userToCreate = [Select id from user where profile.name='System Administrator' and IsActive = true Limit 1];
          Test.startTest();    
          Lead leadToCreate =new Lead();
          List<id> Ids= New List<Id>();
          leadToCreate.ownerid= userToCreate.id;
          leadToCreate.LastName ='John';
          leadToCreate.FirstName ='John';
          leadToCreate.Email ='1@test.com';
          leadToCreate.Company='Salesforce';
          leadToCreate.LeadSource='Partner Referral';
          leadToCreate.Rating='';
          leadToCreate.Status='';
          leadToCreate.Lead_Bypass_DateTime__c = System.now();
          insert leadToCreate; 
          Ids.add(leadToCreate.id);
          AutoConvertLeads.LeadAssign(Ids);
          Test.stopTest();
   }
}