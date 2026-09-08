trigger P_OpportunityTrigger on Opportunity (before insert, after insert, before update, after update, before delete) {
    String debug = '';
    System.debug('CC...P_OpportunityTrigger: ' + Validator_Class.ByPassOppTrigger());
    if(!Validator_Class.ByPassOppTrigger()) {
        if(Trigger.isbefore) {
            debug = 'CC...before';
        } else {
            debug = 'CC...after';
        } 
        if(Trigger.isInsert) {
            debug += ' Insert ';
        } else {
            debug += ' Update ';
        }
        System.debug(debug + 'Start of P_OpportunityTrigger' );
        P_OpportunityTriggerHandler hndlr = new P_OpportunityTriggerHandler();
        hndlr.doTriggerWork(Trigger.new, Trigger.newMap, Trigger.oldMap);
    }
}