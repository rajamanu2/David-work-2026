@isTest
private class TestNameTriggerTestClass {

    static testmethod void TestNameTriggerTest1() {
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Probe_Type__c = 'Transesophageal';
        insert pro;
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Serial_No__c='B0K81J';
        pi.Check_In_Type__c = 'Customer Repair';
        pi.Repair_Summary__c = 'abc';
        pi.Repair_Notes_Summary__c = 'abc';
        pi.Sold__c = false;
        pi.Estimated_Lead_Time__c = 3;
        pi.Estimated_Repair_Time__c = 1.5;
        pi.Repair_Status__c = 'Unassigned';
        insert pi;

        RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', false);
        rma.ProductItem__c = pi.Id;
        insert rma;

        ProductTest__c ptest = TestDataFactory.createProductTest(pi.Id, false);
        ptest.Cos_evaluation__c='abc';
        ptest.Fun_evaluation__c='cxv';
        ptest.Cosmetic_Bending_rubber__c='Heavy Discoloration';
        ptest.Cosmetic_Cable_jacket__c='Heavy Ink Stains';
        ptest.Cosmetic_Cap__c='Not Functioning';
        ptest.Cosmetic_Connector__c='Broken Locking Knob';
        ptest.Cosmetic_Insertion_tube__c='bite marks-minor';
        ptest.Cosmetic_Lens__c='Not Functioning';
        ptest.Cosmetic_Probe_Handle__c='minor scratches';
        ptest.Cosmetic_Strain_Relief__c='heavy discoloration';
        ptest.Cosmetic_Control_Housing__c = 'Major Discoloration';
        ptest.Cosmetic_Tip__c='Tip Case Cracked';
        ptest.Functional_Airscan__c='noticeably irregular';
        ptest.Functional_Articulation__c='Major Slack in Left/Right';
        ptest.Functional_Color_artifacts__c='Minor noise at bending section';
        ptest.Functional_CW_artifacts__c='Minor noise at bending section';
        ptest.Functional_CW_Pulse__c='Not Functioning';
        ptest.Functional_First_Call__c='4+ Dead element';
        ptest.Functional_Image__c='Dark shadow(s)';
        ptest.Functional_Leakage_current__c='Above Upper Limit at Tip';
        ptest.Functional_Motor__c='Motor Sounds Labored';
        ptest.Other_Notes_Cosmetic__c='abcd';
        ptest.Other_Notes_Functional__c='abcd';
        ptest.Functional_Interior__c = 'Fluid Intrusion Inside Tip';
        ptest.Functional_Orientation__c = 'Reversed';
        ptest.Cable_Length__c = 80;
        ptest.Last_4_Characters_of_SN__c = 'K81J';
        ptest.Test_Completed_By__c = 'Rachel Stockwell';
        insert ptest;

        Product_Repair__c prepair = TestDataFactory.createProductRepair('Cosmetic Repair', 'Repair Activity', pi.Id, false);
        prepair.Previous_Test__c = ptest.Id;
        insert prepair;

        Test.startTest();

        ptest.Functional_First_Call__c = 'No problem';
        update ptest;

        Test.stopTest();
    }
    
   
    static testmethod void testDeleteTest() {
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Probe_Type__c = 'Transesophageal';
        insert pro;
        ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
        pi.Serial_No__c='B0K81J';
        pi.Check_In_Type__c = 'Customer Repair';
        pi.Repair_Summary__c = 'abc';
        pi.Repair_Notes_Summary__c = 'abc';
        pi.Sold__c = false;
        pi.Estimated_Lead_Time__c = 3;
        pi.Estimated_Repair_Time__c = 1.5;
        pi.Repair_Status__c = 'Unassigned';
        insert pi;

       

        ProductTest__c ptest = TestDataFactory.createProductTest(pi.Id, false);
        ptest.Cos_evaluation__c='abc';
        ptest.Fun_evaluation__c='cxv';
        ptest.Cosmetic_Bending_rubber__c='Heavy Discoloration';
        ptest.Cosmetic_Cable_jacket__c='Heavy Ink Stains';
        ptest.Cosmetic_Cap__c='Not Functioning';
        ptest.Cosmetic_Connector__c='Broken Locking Knob';
        ptest.Cosmetic_Insertion_tube__c='bite marks-minor';
        ptest.Cosmetic_Lens__c='Not Functioning';
        ptest.Cosmetic_Probe_Handle__c='minor scratches';
        ptest.Cosmetic_Strain_Relief__c='heavy discoloration';
        ptest.Cosmetic_Control_Housing__c = 'Major Discoloration';
        ptest.Cosmetic_Tip__c='Tip Case Cracked';
        ptest.Functional_Airscan__c='noticeably irregular';
        ptest.Functional_Articulation__c='Major Slack in Left/Right';
        ptest.Functional_Color_artifacts__c='Minor noise at bending section';
        ptest.Functional_CW_artifacts__c='Minor noise at bending section';
        ptest.Functional_CW_Pulse__c='Not Functioning';
        ptest.Functional_First_Call__c='4+ Dead element';
        ptest.Functional_Image__c='Dark shadow(s)';
        ptest.Functional_Leakage_current__c='Above Upper Limit at Tip';
        ptest.Functional_Motor__c='Motor Sounds Labored';
        ptest.Other_Notes_Cosmetic__c='abcd';
        ptest.Other_Notes_Functional__c='abcd';
        ptest.Functional_Interior__c = 'Fluid Intrusion Inside Tip';
        ptest.Functional_Orientation__c = 'Reversed';
        ptest.Cable_Length__c = 80;
        ptest.Last_4_Characters_of_SN__c = 'K81J';
        ptest.Test_Completed_By__c = 'Rachel Stockwell';
        insert ptest;

        

        Test.startTest();

        
        try{
            delete ptest;           
        }Catch (DMLException e){
            System.assert(e.getMessage().contains('You can not delete this test !'), 'You can not delete this test !');
        }
        Test.stopTest();   
        
        
    }

}