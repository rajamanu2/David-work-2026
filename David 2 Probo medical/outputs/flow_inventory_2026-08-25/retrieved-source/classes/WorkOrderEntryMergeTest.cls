@isTest
public class WorkOrderEntryMergeTest {
    @isTest static void XeCurrencyCalloutTest(){
         
        List<WorkOrder> wotoinsert = new List<WorkOrder>();
        List<Id> woIds = new List<Id>();
		WorkOrder wo = new WorkOrder(Work_Order_PDF_Type__c = 'Field Service Report');
        wotoinsert.add(wo);
        WorkOrder wo2 = new WorkOrder(All_chords_and_cables_intact_no_Frays__c= 'Pass', Work_Order_PDF_Type__c='Preventative Maintenance Report');
        wotoinsert.add(wo2);
        insert wotoinsert;
        
        system.debug('wotoinsert: ' + wotoinsert);
        
        WorkOrder wo1 = [SELECT WorkOrderNumber,Work_Order_PDF_Type__c FROM WorkOrder WHERE id =: wo.id];
        WorkOrder wo3 = [SELECT WorkOrderNumber,Work_Order_PDF_Type__c FROM WorkOrder WHERE id =: wo2.id];
       	woIds.add(wo1.id);   
        woIds.add(wo3.id);  
        system.debug('wo1 number: ' + wo1.WorkOrderNumber);
        
        wo2.Service_Report_Number__c = wo1.WorkOrderNumber;
        update wo2;               
        
        Test.startTest();
        WorkOrderPDFGenerator.getWorkOrderPDF(woIds);
        WorkOrderPDFGenerator.getWorkOrderPDF(woIds);
        WorkOrderEntryMerge sh1 = new WorkOrderEntryMerge();
		String sch = '0 0 2 * * ?'; 
		system.schedule('Test Territory Check', sch, sh1); 
        Test.stopTest();
        
    }


}