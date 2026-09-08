public class WorkOrderShippingCheckList {
    Public String WOid {get;set;}
    Public String Notes {get;set;}
    Public String customerPO {get;set;}
    public list<WorkOrderLineItem> WorkOrderProducts {get;set;}
    public list<string> HeaderInfo {get;set;}

    public WorkOrderShippingCheckList(ApexPages.StandardController controller){
        WOId = ApexPages.currentPage().getParameters().get('id');
        system.debug('THIS IS THE WORK ORDER ID >>>> ' + WOid);
        WorkOrderProducts = [select id, WorkOrder.Opportunity__r.Opportunity_Number__c, WorkOrder.Opportunity__r.Name, WorkOrder.Opportunity__r.RecordType.DeveloperName, Part_Check_In_Type__c,
                WorkOrder.Opportunity__r.Owner.FirstName, WorkOrder.Opportunity__r.Owner.LastName, WorkOrder.Account.Name, Part_Used__r.Name,
                Part_Used__c, Part_Name__c, Part_Location__c, WorkOrder.Ship_Date__c, WorkOrder.Scheduled_Service_Date__c,
                Part_Used__r.Serial_No__c, Part_Used__r.Part_number__c,  WorkOrder.Customer_PO__c, Serial_No__c 
        from WorkOrderLineItem where WorkOrderId =:WOid];
        
        HeaderInfo = new List<String>();
        if (!WorkOrderProducts.isEmpty()){
            customerPO = '';
            if(WorkOrderProducts[0].WorkOrder.Customer_PO__c != null){
                customerPO = WorkOrderProducts[0].WorkOrder.Customer_PO__c;
            }
            HeaderInfo.add('Customer PO');
            HeaderInfo.add(customerPO);
            system.debug('THIS IS THE OPP PRODUCTS >>> ' + WorkOrderProducts[0].WorkOrder.Opportunity__r.Opportunity_Number__c);
            HeaderInfo.add('Opportunity No');
            HeaderInfo.add(WorkOrderProducts[0].WorkOrder.Opportunity__r.Opportunity_Number__c);
            system.debug('THIS IS THE OPP NO >>> ' + HeaderInfo);
            HeaderInfo.add('Opportunity Name');
            HeaderInfo.add(WorkOrderProducts[0].WorkOrder.Opportunity__r.Name);
            system.debug('THIS IS THE OPP NAME >>> ' + HeaderInfo);
            HeaderInfo.add('Opportunity Type');
            HeaderInfo.add(WorkOrderProducts[0].WorkOrder.Opportunity__r.RecordType.DeveloperName);
            system.debug('THIS IS THE OPP TYPE >>> ' + HeaderInfo);
            HeaderInfo.add('Opportunity Owner');
            HeaderInfo.add(WorkOrderProducts[0].WorkOrder.Opportunity__r.Owner.FirstName + ' ' + WorkOrderProducts[0].WorkOrder.Opportunity__r.Owner.LastName);
            system.debug('THIS IS THE OPP OWNER >>> ' + HeaderInfo);
            HeaderInfo.add('Customer Name');
            HeaderInfo.add(WorkOrderProducts[0].WorkOrder.Account.Name);
            system.debug('THIS IS THE ACCOUNT >>> ' + HeaderInfo);
            HeaderInfo.add('White Glove Service?');
            //NOT SURE WHAT TO DO WITH THIS ONE, WHITE GLOVE SERVICE IS NOT ON THE WOLINEITEM :/
            HeaderInfo.add('NO');
            system.debug('THIS IS THE WGS >>> ' + HeaderInfo);
            HeaderInfo.add('Ship Date');
            if(WorkOrderProducts[0].WorkOrder.Ship_Date__c != null){
                HeaderInfo.add(String.valueof(WorkOrderProducts[0].WorkOrder.Ship_Date__c));
            } else {
                HeaderInfo.add('No ship date provided');
            }
            system.debug('THIS IS THE SHIP DATE >>> ' + HeaderInfo);
            HeaderInfo.add('Estimated Ready Date');
            if(WorkOrderProducts[0].WorkOrder.Scheduled_Service_Date__c != null){
                HeaderInfo.add(String.valueof(WorkOrderProducts[0].WorkOrder.Scheduled_Service_Date__c).removeEnd(' 00:00:00'));
            } else {
                HeaderInfo.add('No estimated ready date provided');
            }
        }
        system.debug('THIS IS THE ESTIMATED READY DATE >>> ' + HeaderInfo);

    }
}