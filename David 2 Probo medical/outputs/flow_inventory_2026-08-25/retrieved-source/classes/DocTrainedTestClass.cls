@istest
private class DocTrainedTestClass {
    
     static testMethod void mytest(){
         Training_Item__c train = new Training_Item__c (Name = 'TEST-001-A', Question_1__c = 'How are you today?', 
                                                        Question_1_Choice_A__c = 'Good', Question_1_Choice_B__c = 'Ok', 
                                                        Question_1_Choice_C__c = 'Not good', Question_1_Choice_D__c = 'None of the above',  
             											Question_2__c = 'Is this a test?', Question_2_Choice_A__c = 'Yes', 
                                                        Question_2_Choice_B__c = 'No', Question_2_Choice_C__c = 'Maybe', 
                                      					Question_2_Choice_D__c = 'Trick Question', 
                                                        Question_3__c = 'What is the weather like today?', Question_3_Choice_A__c = 'Hot', 
                                                        Question_3_Choice_B__c = 'Mild', Question_3_Choice_C__c = 'Cold', 
                                                        Question_3_Choice_D__c = 'Windy', Question_4__c = 'How many questions are on this test?', 
                                                        Question_4_Choice_A__c = '1', Question_4_Choice_B__c = '2', Question_4_Choice_C__c = '5', 
                                                        Question_4_Choice_D__c = '10', Question_5__c = 'Are you happy to be done with this test?',  
                                                        Question_5_Choice_A__c = 'Definitely', Question_5_Choice_B__c ='Maybe', 
                                                        Question_5_Choice_C__c = 'No', Question_5_Choice_D__c = 'I did not know the test was done',
                                                       Document_Title__c = 'Test Document', Document_Link__c = 'www.google.com', Revision_Number__c = '01',
                                                       Department__c = 'Quality (QMS)', Document_Type__c = 'Procedure');
         insert train;
         
          Document_Trained_Person__c doc = new Document_Trained_Person__c (Training_Item__c=train.Id);
        insert doc;
        
          
          //apexPages.currentPage().getParameters().put('CF00NJ0000002MOgw_lkid',train.Id);
          apexPages.currentPage().getParameters().put('CF00N0B000005u68Q_lkid',train.Id);
          ApexPAges.StandardController sc = new ApexPages.StandardController(doc);      
          DocTrained dtest = new DocTrained(sc);
          dtest.newDocTrain();
         
    }

}