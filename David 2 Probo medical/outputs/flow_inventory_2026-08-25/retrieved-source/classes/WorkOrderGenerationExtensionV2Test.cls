@isTest
public class WorkOrderGenerationExtensionV2Test {
    @isTest
    public static void Test1(){
        
        ProductItem__c assettoInsert = new ProductItem__c(Serial_No__c='12345678', Receive_date__c= system.today());
        insert assettoInsert;
        
        Account accountoInsert = new Account(name='test account',Customer_ID__c='3920349', RGBP_Category__c = 'House');
        insert accountoInsert;
        
        Opportunity opptoInsert = new Opportunity(name='Test Opportunity 1', CloseDate=system.today()+1, AccountId=accountoInsert.id,StageName='Open');
        insert opptoInsert;
        
        ServiceContract serviceContractToInsert = new ServiceContract(Name='Test Service Contract 1', AccountId=accountoInsert.id, Contract_Billing__c='Monthly');
        insert serviceContracttoInsert;
        
        List<WorkOrder> ListWOToInsert = new List<WorkOrder>();
        
        WorkOrder objwo = new WorkOrder(Labor_Date_Time_Out__c = system.now(),Labor_Date_Time_In__c = system.now(),Travel_Date_Time_Out__c = system.now(),Travel_Date_Time_In__c = system.now(),Work_Order_PDF_Type__c='Preventative Maintenance Report');
        ListWOToInsert.add(objwo);
        
        WorkOrder objwo2 = new WorkOrder(Labor_Date_Time_Out__c = system.now(),Labor_Date_Time_In__c = system.now(),Travel_Date_Time_Out__c = system.now(),Travel_Date_Time_In__c = system.now(),Work_Order_PDF_Type__c='Field Service Report');
		ListWOToInsert.add(objwo2);
        
        insert ListWOToInsert;
				
		ApexPages.StandardController stdwo = new ApexPages.StandardController(objwo);
	    WorkOrderGenerationExtensionV2 objMywoController  = new WorkOrderGenerationExtensionV2(stdwo);
        
		objMywoController.workordertoInsert = objwo;
        system.debug(objwo2);
        objMywoController.oppName = opptoInsert.name;
        objMywoController.ServiceContractName = serviceContracttoInsert.name;
        objMywoController.WoNumber = objwo2.Id;
        objMywoController.CustomerID = '3920349';
        objMywoController.AssetID = '12345678';
		objMywoController.Save();
        objMywoController.doAssetSearch();
        objMywoController.doOpportunitySearch();
        objMywoController.doServiceContractSearch();
        objMywoController.doAccountSearch();
        objMywoController.calculatelabor();
        objMywoController.calculatetravel();
        objMywoController.calculatewototal();
        objMywoController.calculateparts();
        objMywoController.doWorkOrderSearch();
    }

}