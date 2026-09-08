@istest
public class UpdateActionPlanStatusTest {
static testMethod void mytest(){
        CAPA__c CAPA = new CAPA__c ();
    insert CAPA;
    	CAPA_Action_Plan__c Plan = new CAPA_Action_Plan__c (Associated_CAPA__c = CAPA.id, Target_Completion_Date__c = Date.parse('03/24/2017'), Action_Plan_Ready_for_Approval__c = false, 
                                                            Root_Cause__c = 'Inadequate training');
    insert Plan;
    
    Plan.Action_Plan_Ready_For_Approval__c = true;
    Plan.Action_Plan_Approved__c = false;
    
    update Plan;
    
    Plan.Action_Plan_Approved__c = true;
    Plan.Action_Plan_Complete__c = false;
    
    update Plan;
    
    Plan.Action_Plan_Complete__c = true;
    Plan.Action_Plan_Effectiveness__c = null;
    
    update Plan;
    
    Plan.Action_Plan_Effectiveness__c = 'Not Effective';
    
    update Plan;
    
    Plan.Action_Plan_Effectiveness__c = 'Effective';
    
    update Plan;
} 
}