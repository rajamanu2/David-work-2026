trigger PriceActionTrigger on SBQQ__PriceAction__c (before insert, before update, before delete,after insert,after update,after delete){
    
    new PriceRulesFiredHandler().run();
}