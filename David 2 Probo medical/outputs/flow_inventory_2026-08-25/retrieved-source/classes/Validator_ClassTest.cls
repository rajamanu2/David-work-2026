/**
* @author Delagate
* @date 7/21/2021
*
* @description
*/

@isTest
public with sharing class Validator_ClassTest {
    @isTest
    public static void Validator_ClassTest() {
        Validator_Class.setAlreadyDone1();
        System.assertEquals(Validator_Class.hasAlreadyDone1(), 1);
        Validator_Class.setAlreadyDone3();
        System.assertEquals(Validator_Class.hasAlreadyDone3(), 1);
        Validator_Class.setAlreadyDone4();
        System.assertEquals(Validator_Class.hasAlreadyDone4(), true);
        Validator_Class.setAlreadyDone9();
        System.assertEquals(Validator_Class.hasAlreadyDone9(), 1);
        Validator_Class.setAlreadyDone10();
        System.assertEquals(Validator_Class.hasAlreadyDone10(), 1);
        Validator_Class.setAlreadyDone11();
        System.assertEquals(Validator_Class.hasAlreadyDone11(), 1);
        Validator_Class.setAlreadyDone15();
        System.assertEquals(Validator_Class.hasAlreadyDone15(), 1);
        Validator_Class.setAlreadyDone16();
        System.assertEquals(Validator_Class.hasAlreadyDone16(), 1);
        Validator_Class.setAlreadyDone17();
        System.assertEquals(Validator_Class.hasAlreadyDone17(), 1);
        Validator_Class.SetByPassProductItemTrigger(true);
        System.assertEquals(Validator_Class.byPassProductItemTrigger(), true);
        Validator_Class.SetByPassReviewTrigger(true);
        System.assertEquals(Validator_Class.byPassReviewTrigger(), true);
        Validator_Class.SetByPassOppTrigger(true);
        System.assertEquals(Validator_Class.byPassOppTrigger(), true);
        Validator_Class.SetByPassRMATrigger(true);
        System.assertEquals(Validator_Class.byPassRMATrigger(), true);
    }
}