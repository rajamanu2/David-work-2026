/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_ProductItemTrigger on ProductItem__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    Validator_Class.SetByPassProductItemTrigger(true);
    dlrs.RollupService.triggerHandler(ProductItem__c.SObjectType);
    Validator_Class.SetByPassProductItemTrigger(false);
}