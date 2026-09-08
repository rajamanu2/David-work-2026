/**
* @author Delagate
* @date 8/22/2021
*
* @description
*/

@isTest
public without sharing class RMAHelperTest {
    @TestSetup
    static void makeData(){
        Pricebook2 pricebookstd = new Pricebook2(Name = 'Standard Price Book', isActive = true);
        //ProboCommonUtils.getStdPricebookId();
        insert pricebookstd;
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', true);
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
        Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', null, true);

        system.debug('#### pi ' + pi);

        Test.startTest();

        RMA__c rma = TestDataFactory.createRMA('Warranty Claim', false);
        rma.ProductItem__c = pi.Id;
        rma.Opportunity__c = o.Id;
        rma.Customer_Expectation__c = 'Customer wants Equipment Back';
        rma.Date_RMA_Item_Received__c = system.today() - 20;
        rma.Date_Loaner_Shipped__c = system.today() - 10;
        rma.Quality_Issue_Notes__c = 'Bad image';
        rma.Tracking_number_of_RMA_Item_Received__c = '489561700';
        insert rma;
    }
    @IsTest
    static void TestSetEmailandApprovalFields(){
        
        Test.startTest();
        Opportunity opp = [SELECT Field_Service_Engineer__c
                            FROM Opportunity
                            LIMIT 1];
        opp.Field_Service_Engineer__c = 'Alan Adamson';
        update opp;
        RMA__c rma = [SELECT Id, Field_Service_Engineer__c 
                        FROM RMA__c
                        LIMIT 1];
        rma.Warranty_Claim_Approved__c = 'APPROVED';
        //UserInfo.getFirstName() + ' ' + UserInfo.getLastName()
        update rma;
        Test.stopTest();
        rma = [SELECT Id, Field_Service_Engineer_Email__c,	Warranty_Claim_Approved_By__c,Time_Warranty_Claim_Approved__c
                FROM RMA__c
                LIMIT 1];
        System.assert(rma.Warranty_Claim_Approved_By__c == UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
        System.assert(rma.Time_Warranty_Claim_Approved__c != null);
        //System.debug('CC...TestSetEmailandApprovalFields: ' + rma.Field_Service_Engineer_Email__c);
        System.debug('CC...TestSetEmailandApprovalFields: ' + rma.Warranty_Claim_Approved_By__c);
        System.debug('CC...TestSetEmailandApprovalFields: ' + rma.Time_Warranty_Claim_Approved__c);

        
    }
}