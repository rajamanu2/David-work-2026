@isTest
private class ReviewStatusTestClass{
    
    static testMethod void mytest(){
         Account acc=new Account(name='TestAccount');
         insert acc;
         Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
         pro.Name = 'Ultrasound Probe-Philips C5-1';
         pro.Probe_Type__c = 'Linear';
         insert pro;
         
          ProductItem__c prItem = new ProductItem__c (Product_Name__c=pro.Id,Model__c='Philips C5-1',
                    Serial_No__c='B0K81J',Location__c='WIP',PO_Number__c='2425',Review_Status__c='Repair Queue',
                    Other_Notes__c='Cable needs cleaned',Added_To_Opportunity__c = false,Receive_date__c=Date.parse('01/08/2015'));
          insert prItem;
          
          apexPages.currentPage().getParameters().put('CF00NU00000060eU3_lkid',prItem.Id);
          Review_Status__c revStatus=new Review_Status__c(ProductItem__c=prItem.Id,Notes__c='Demo Note',New_Review_Status__c='Repair Queue');
          Insert revStatus;
          ApexPAges.StandardController sc = new ApexPages.StandardController(revStatus);      
          ReviewStatus reviewtest = new ReviewStatus(sc);
          reviewtest.newReviewStatus();
         
    }
}