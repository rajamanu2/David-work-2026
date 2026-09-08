@isTest
private class MoveLocationTestClass{
    
    static testMethod void mytest(){
         Account acc=new Account(name='TestAccount');
         insert acc;
         Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
         pro.Name = 'Ultrasound Probe-Philips C5-1';
         pro.Probe_Type__c = 'Linear';
         insert pro;
         
          ProductItem__c prItem = new ProductItem__c (Product_Name__c=pro.Id,Model__c='Philips C5-1',
                    Serial_No__c='B0K81J',Location__c='WIP',PO_Number__c='2425', Check_In_Type__c = 'Customer Repair',
                    Other_Notes__c='Cable needs cleaned',Added_To_Opportunity__c = false,Receive_date__c=Date.parse('01/08/2015'));
          insert prItem;
          
          apexPages.currentPage().getParameters().put('CF00NU00000060eTa_lkid',prItem.Id);
          Move_Location__c moveL=new Move_Location__c(ProductItem__c=prItem.Id,External_Location__c=acc.ID,Note__c='Demo Note');
          Insert moveL;
          ApexPAges.StandardController sc = new ApexPages.StandardController(moveL);      
          MoveLocation movetest = new MoveLocation(sc);
          movetest.newMoveLocation();
         
    }
}