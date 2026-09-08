trigger UpdateActionPlanStatus on CAPA_Action_Plan__c (after insert, after update) {

    // JMAY: SOQL, DML, and hardcoded are done - Deployed to devint

    // CAPAs are set up as custom object with CAPA action plans as custom object underneath them and CAPA
    // actions underneath the action plans. This code sets the CAPA action plan status.

    Set<Id> capaIdsToGet = new Set<Id>();

    for (CAPA_Action_Plan__c p : trigger.new) {
        if (p.Associated_CAPA__c != null) {
            capaIdsToGet.add(p.Associated_CAPA__c);
        }
    }

    Map<Id, CAPA__c> capaIDToCAPA = new Map<Id, CAPA__c>([
            select ID, Root_Cause__c, Action_Plan_Status__c, Target_Action_Plan_Completion_Date__c
            from CAPA__c
            WHERE id = :capaIdsToGet
    ]);

    Set<CAPA__c> capaToUpdate = new Set<CAPA__c>();

    for (CAPA_Action_Plan__c p : trigger.new) {

        if (p.Associated_CAPA__c != null && capaIDToCAPA.containsKey(p.Associated_CAPA__c)) {

            CAPA__c thisCAPA = capaIDToCAPA.get(p.Associated_CAPA__c);

            thisCAPA.Root_Cause__c = p.Root_Cause__c;
            thisCAPA.Target_Action_Plan_Completion_Date__c = p.Target_Completion_Date__c;
            system.debug('ROOT CAUSE >>>>>>>> ' + p.Root_Cause__c);
            if (p.Action_Plan_Ready_for_Approval__c == false) {
                thisCAPA.Action_Plan_Status__c = 'Waiting for Submission';
            }
            if (p.Action_Plan_Ready_for_Approval__c == true && p.Action_Plan_Approved__c == false) {
                thisCAPA.Action_Plan_Status__c = 'Submitted, Waiting for Approval';
            }
            if (p.Action_Plan_Approved__c == true && p.Action_Plan_Complete__c == false) {
                thisCAPA.Action_Plan_Status__c = 'Approved, Waiting for Completion';
            }
            if (p.Action_Plan_Complete__c == true && p.Action_Plan_Effectiveness__c == null) {
                thisCAPA.Action_Plan_Status__c = 'Completed, Waiting for Effectiveness Check';
            }
            if (p.Action_Plan_Effectiveness__c == 'Not Effective') {
                thisCAPA.Action_Plan_Status__c = 'Not Effective, New Action Plan Waiting for Submission';
            }
            if (p.Action_Plan_Effectiveness__c == 'Effective') {
                thisCAPA.Action_Plan_Status__c = 'Effective, No Further Action Required';
            }

            capaToUpdate.add(thisCAPA);
        }
    }

    system.debug('Getting ready to update this many CAPAs: ' + capaToUpdate.size());
    if(!capaToUpdate.isEmpty()){
        List<CAPA__c> capas = new List<CAPA__c>();
        capas.addAll(capaToUpdate);
        DatabaseService.updateList(capas);
    }

}