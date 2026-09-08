@isTest
public class BypassTriggerActionTest {
   
    @isTest
    static void bypassTriggerTrue() {
        List<BypassTriggerAction.BypassTriggerInput> inputList = new List<BypassTriggerAction.BypassTriggerInput>();
        BypassTriggerAction.BypassTriggerInput testInput = new BypassTriggerAction.BypassTriggerInput();
        testInput.objectTrigger = 'Opportunity';
        testInput.setAction = true;
        inputList.add(testInput);
        
        BypassTriggerAction.BypassTriggerInput testInput2 = new BypassTriggerAction.BypassTriggerInput();
        testInput2.objectTrigger = 'ProductItem__c';
        testInput2.setAction = true;
        inputList.add(testInput2);
        
        BypassTriggerAction.BypassTriggerInput testInput3 = new BypassTriggerAction.BypassTriggerInput();
        testInput3.objectTrigger = 'Review_Status__c';
        testInput3.setAction = true;
        inputList.add(testInput3);
        
        BypassTriggerAction.BypassTriggerInput testInput4 = new BypassTriggerAction.BypassTriggerInput();
        testInput4.objectTrigger = 'RMA__c';
        testInput4.setAction = true;
        inputList.add(testInput4);

        Test.startTest();
        ByPassTriggerAction.bypassTrigger(inputList);
        Test.stopTest();

        System.assertEquals(true, Validator_Class.ByPassOppTrigger(), 'Should change opp variable to true');
        System.assertEquals(true, Validator_Class.ByPassProductItemTrigger(), 'Should change product item variable to true');
        System.assertEquals(true, Validator_Class.ByPassReviewTrigger(), 'Should change review status variable to true');
        System.assertEquals(true, Validator_Class.ByPassRMATrigger(), 'Should change RMA variable to true');
        
    }
    
    @isTest
    static void bypassTriggerFalse() {
        List<BypassTriggerAction.BypassTriggerInput> inputList = new List<BypassTriggerAction.BypassTriggerInput>();
        BypassTriggerAction.BypassTriggerInput testInput = new BypassTriggerAction.BypassTriggerInput();
        testInput.objectTrigger = 'Opportunity';
        testInput.setAction = false;
        inputList.add(testInput);
        
        BypassTriggerAction.BypassTriggerInput testInput2 = new BypassTriggerAction.BypassTriggerInput();
        testInput2.objectTrigger = 'ProductItem__c';
        testInput2.setAction = false;
        inputList.add(testInput2);
        
        BypassTriggerAction.BypassTriggerInput testInput3 = new BypassTriggerAction.BypassTriggerInput();
        testInput3.objectTrigger = 'Review_Status__c';
        testInput3.setAction = false;
        inputList.add(testInput3);
        
        BypassTriggerAction.BypassTriggerInput testInput4 = new BypassTriggerAction.BypassTriggerInput();
        testInput4.objectTrigger = 'RMA__c';
        testInput4.setAction = false;
        inputList.add(testInput4);

        Test.startTest();
        ByPassTriggerAction.bypassTrigger(inputList);
        Test.stopTest();

        System.assertEquals(false, Validator_Class.ByPassOppTrigger(), 'Should change opp variable to false');
        System.assertEquals(false, Validator_Class.ByPassProductItemTrigger(), 'Should change product item variable to false');
        System.assertEquals(false, Validator_Class.ByPassReviewTrigger(), 'Should change review status variable to false');
        System.assertEquals(false, Validator_Class.ByPassRMATrigger(), 'Should change RMA variable to false');
        
    }
}