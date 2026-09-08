@isTest
public class WorkOrderTriggerHelperTest {
    @testSetup
    static void setupTestData(){
        Field_Service_Engineer__c fse = new Field_Service_Engineer__c(
            Name='Adam Walter',
            Service_Fusion_Id__c='980381690',
            Field_Worker__c=true
        );
        insert fse;
    }
    static testMethod void test_insertWorkOrderWithSfTech(){
        Test.startTest();
        String recordTypeId = [SELECT Id From RecordType WHERE sObjectType='WorkOrder' AND isActive=true AND Name='Preventative Maintenance'].Id;
        WorkOrder wo = new WorkOrder(
            RecordTypeId=recordTypeId,
            Status='New',
            Priority='Low',
            Service_Fusion_Techs__c='980381690;'
        );
        insert wo;
        Test.stopTest();
        
        String assertValue = [SELECT Id, Field_Service_Engineer__c FROM WorkOrder WHERE Id =: wo.Id].Field_Service_Engineer__c;
        
        system.assertEquals('Adam Walter', assertValue);
    }
    static testMethod void test_insertWorkOrderWithSfdcTech(){
        Test.startTest();
        String recordTypeId = [SELECT Id From RecordType WHERE sObjectType='WorkOrder' AND isActive=true AND Name='Preventative Maintenance'].Id;
        WorkOrder wo = new WorkOrder(
            RecordTypeId=recordTypeId,
            Status='New',
            Priority='Low',
            Field_Service_Engineer__c='Adam Walter'
        );
        insert wo;
        Test.stopTest();
        
        String assertValue = [SELECT Id, Service_Fusion_Techs__c FROM WorkOrder WHERE Id =: wo.Id].Service_Fusion_Techs__c;
        
        system.assertEquals('980381690;', assertValue);
    }
    static testMethod void test_updateWorkOrderWithSfTech(){
        Test.startTest();
        String recordTypeId = [SELECT Id From RecordType WHERE sObjectType='WorkOrder' AND isActive=true AND Name='Preventative Maintenance'].Id;
        WorkOrder wo = new WorkOrder(
            RecordTypeId=recordTypeId,
            Status='New',
            Priority='Low'
        );
        insert wo;
        
        wo.Service_Fusion_Techs__c='980381690;';
        update wo;
        
        Test.stopTest();
        
        String assertValue = [SELECT Id, Field_Service_Engineer__c FROM WorkOrder WHERE Id =: wo.Id].Field_Service_Engineer__c;
        
        system.assertEquals('Adam Walter', assertValue);
    }
    static testMethod void test_updateWorkOrderWithSfdcTech(){
        Test.startTest();
        String recordTypeId = [SELECT Id From RecordType WHERE sObjectType='WorkOrder' AND isActive=true AND Name='Preventative Maintenance'].Id;
        WorkOrder wo = new WorkOrder(
            RecordTypeId=recordTypeId,
            Status='New',
            Priority='Low'
        );
        insert wo;
        
        wo.Field_Service_Engineer__c='Adam Walter';
        update wo;
        
        Test.stopTest();
        
        String assertValue = [SELECT Id, Service_Fusion_Techs__c FROM WorkOrder WHERE Id =: wo.Id].Service_Fusion_Techs__c;
        
        system.assertEquals('980381690;', assertValue);
    }
}