@isTest(seeAllData=true)
private class UpdateOpportunityFieldsTestClass {

    static testMethod void myTestMethod(){
        
        Account acc = new Account(name='abc');
        insert acc;
         
        RecordType RC = [select id from  RecordType where SobjectType='opportunity' AND DeveloperName='Purchasing_Opportunity'];
        opportunity opp = new opportunity(Name='newopp',AccountId=acc.Id,CloseDate=Date.parse('12/13/2014'),StageName='Prospecting',RecordTypeId=RC.Id);
        insert opp; 
        
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Name = 'Ultrasound Probe-Philips C5-1';
        pro.Functionally_Good_Probes__c = 190;
        insert pro;
        
        
        
        ProductItem__c prItem = new ProductItem__c (Product_Name__c=pro.Id,Model__c='Philips C5-1',
                                                    Serial_No__c='B0K81J',Functional_Rating__c='B',Functional_Notes__c='Good',Reserved__c=false,
                                                    Cosmetic_Rating__c='C',Cosmetic_Notes__c='Yellow Cable',Location__c='WIP',PO_Number__c='2425',
                                                    Other_Notes__c='Cable needs cleaned',Added_To_Opportunity__c = true,Receive_date__c=Date.parse('01/08/2015'), Purchasing_Opportunity__C = opp.id);
        insert prItem;
        
        pricebook2 pb = [select id from Pricebook2 where isStandard=true];
         
        PricebookEntry pbe = new PricebookEntry (Pricebook2Id=pb.id, Product2Id=pro.Id, IsActive=true, UnitPrice=100.00);
        insert pbe;
        
        OpportunityLineItem oppLine=new OpportunityLineItem(OpportunityId=opp.Id,Quantity=100,PricebookEntryId=pbe.Id, TotalPrice=500,Probo_s_Offer__c=100,Supplier_s_Quote__c=100,
                                                            ProductItem__c=prItem.ID);
        insert oppLine;
    }
}