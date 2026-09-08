@isTest(SeeAllData = True)
public class UKBusinessHoursTest {
    static testMethod void Main_Test(){
        ServiceContract sc = new ServiceContract();
        sc.RecordTypeID = '0125b000000LWZGAA4';
        sc.Name = 'SC Test Contract';
        sc.AccountId = '001U000000pNlq7IAC';
        sc.Coverage_Type__c  = 'Warranty';
        sc.Modalities__c = 'CT';
        sc.CurrencyIsoCode = 'EUR';
        sc.Contract_Billing__c = 'Monthly';
        
        insert sc;
        
        WorkOrder wo = new WorkOrder();
        wo.RecordTypeID='0125b000000LW89AAG';
        wo.Status= 'New';
        wo.Priority= 'Low';
        wo.Classification__c= 'Out for Repair';
        wo.StartDate = system.now()-5;
        wo.Shipping_FROM_Location__c = 'Bristol, UK';
        wo.Reported_Symptoms__c = 'Symptoms';
        wo.CurrencyIsoCode = 'EUR';
        wo.ServiceContractId = sc.id;
        
        insert wo;
        
        test.startTest();
        wo.Service_Completed_Date__c = system.now();
        update wo;        
        test.stopTest();
    }
}