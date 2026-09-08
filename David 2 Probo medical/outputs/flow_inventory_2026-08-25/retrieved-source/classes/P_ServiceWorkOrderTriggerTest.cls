@isTest
private class P_ServiceWorkOrderTriggerTest {

    static testMethod void mytest(){
        Account acc = TestDataFactory.createAccount(true);
        ServiceContract SC = new ServiceContract(name='TEST', AccountId = acc.id, Contract_Billing__c = 'Annual', Field_Service_Engineers__c = 'Hobie Sears', StartDate = date.Today() - 1, EndDate = date.Today() + 1, Coverage_Type__c = 'PM');
        insert SC;
        WorkOrder WO = new WorkOrder(/*ServiceContractID = SC.id,*/ Billable_Work_Order__c = 1000, AccountId = acc.id, Ship_Date__c = date.Today(), Tracking_Number__c = '123', Serial_Number__c = '111');
        insert WO;
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        WorkOrderLineItem WOLineItem = new WorkOrderLineItem(WorkOrderID = WO.id, Status = 'NEW', Part_Used__c = pi.id);
        insert WOLineItem;
        
        //delete WOLineItem;
    }
    
    static testMethod void mytest2(){
        Account acc = TestDataFactory.createAccount(true);
        ServiceContract SC = new ServiceContract(name='TEST', AccountId = acc.id, Contract_Billing__c = 'Annual', Field_Service_Engineers__c = 'Hobie Sears', 
                                                 StartDate = date.Today() - 1, EndDate = date.Today() + 1);
        insert SC;
        
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        Test.startTest();
        WorkOrder WO = new WorkOrder(ServiceContractID = SC.id, Billable_Work_Order__c = 1000, AccountId = acc.id, Status = 'Completed', Work_Order_PDF_Type__c = 'Preventative Maintenance Report');
        insert WO;
        
        WorkOrderLineItem WOLineItem = new WorkOrderLineItem(WorkOrderID = WO.id, Status = 'NEW', Part_Used__c = pi.id);
        insert WOLineItem;
        system.debug('THIS IS THE WO IN THE TEST >>> ' + WO);
        PageReference pRef = Page.SendEmailWorkOrderPDF;
            Test.setCurrentPage(pRef);
            ApexPages.currentPage().getParameters().put('id',WO.Id);
            ApexPages.StandardController sc2 = new ApexPages.StandardController(WO);
            EmailWorkOrderPDF newWO = new EmailWorkOrderPDF(sc2);
        system.debug('THIS IS THE NEW WO PAGE REF >>> ' + newWO);
            newWO.sendEmail();
        delete WOLineItem;
        Test.stopTest();
    }
    
    static testMethod void mytest3(){
        Account acc = TestDataFactory.createAccount(true);
        ServiceContract SC = new ServiceContract(name='TEST', AccountId = acc.id, Contract_Billing__c = 'Annual', Field_Service_Engineers__c = 'Hobie Sears', 
                                                 StartDate = date.Today() - 1, EndDate = date.Today() + 1);
        insert SC;
        
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        Test.startTest();
        WorkOrder WO = new WorkOrder(ServiceContractID = SC.id, Billable_Work_Order__c = 1000, AccountId = acc.id, Status = 'Completed', Work_Order_PDF_Type__c = 'Preventative Maintenance Report');
        insert WO;
        list<WorkOrder> WOList = new List<WorkOrder>();
        WOList.add(WO);
        WorkOrderLineItem WOLineItem = new WorkOrderLineItem(WorkOrderID = WO.id, Status = 'NEW', Part_Used__c = pi.id);
        insert WOLineItem;
        
        EmailWorkOrderPDF.sendPDFEmail(WOList);
       
        Test.stopTest();
    }
    
    static testMethod void mytest4(){
        Account acc = TestDataFactory.createAccount(true);
        ServiceContract SC = new ServiceContract(name='TEST', AccountId = acc.id, Contract_Billing__c = 'Annual', Field_Service_Engineers__c = 'Hobie Sears', StartDate = date.Today() - 1, EndDate = date.Today() + 1, Coverage_Type__c = 'PM');
        insert SC;
        WorkOrder WO = new WorkOrder(/*ServiceContractID = SC.id,*/ Billable_Work_Order__c = 1000, AccountId = acc.id, Serial_Number__c = '111');
        insert WO;
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        WorkOrderLineItem WOLineItem = new WorkOrderLineItem(WorkOrderID = WO.id, Status = 'NEW', Part_Used__c = pi.id);
        insert WOLineItem;
        
        WO.Ship_Date__c = date.Today();
        WO.Tracking_Number__c = '123';
        update WO;
    }
}