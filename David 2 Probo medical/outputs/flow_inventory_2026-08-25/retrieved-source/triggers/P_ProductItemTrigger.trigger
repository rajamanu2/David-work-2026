trigger P_ProductItemTrigger on ProductItem__c (before insert, after insert, before update, after update, before delete) {

    if(Validator_Class.ByPassProductItemTrigger() == false){
        if(Trigger.IsInsert){
            if(Trigger.IsBefore){
                system.debug('THIS IS THE ASSET BEFORE INSERT >> ' + Validator_Class.assetBeforeInsert);
                if(Validator_Class.assetBeforeInsert < 2){
                    P_ProductItemTriggerHandler hndlr = new P_ProductItemTriggerHandler();
           			hndlr.processRecords(Trigger.new, Trigger.newMap, Trigger.oldMap);
                }
                Validator_Class.assetBeforeInsert += 1;
                
            }
            if(Trigger.IsAfter){
                system.debug('THIS IS THE ASSET AFTER INSERT >> ' + Validator_Class.assetAfterInsert);
                if(Validator_Class.assetAfterInsert < 2){
                    P_ProductItemTriggerHandler hndlr = new P_ProductItemTriggerHandler();
           			hndlr.processRecords(Trigger.new, Trigger.newMap, Trigger.oldMap);
                }
                Validator_Class.assetAfterInsert += 1;
            }
            
        }
        if(Trigger.IsUpdate){
            if(Trigger.IsBefore){
                system.debug('THIS IS THE ASSET BEFORE UPDATE >> ' + Validator_Class.assetBeforeUpdate);
                if(Validator_Class.assetBeforeUpdate < 2){
                    P_ProductItemTriggerHandler hndlr = new P_ProductItemTriggerHandler();
           			hndlr.processRecords(Trigger.new, Trigger.newMap, Trigger.oldMap);
                }
                Validator_Class.assetBeforeUpdate += 1;
            }
            if(Trigger.IsAfter){
                system.debug('THIS IS THE ASSET AFTER UPDATE >> ' + Validator_Class.assetAfterUpdate);
                if(Validator_Class.assetAfterUpdate < 2){
                    P_ProductItemTriggerHandler hndlr = new P_ProductItemTriggerHandler();
           			hndlr.processRecords(Trigger.new, Trigger.newMap, Trigger.oldMap);
                }
                Validator_Class.assetAfterUpdate += 1;
            }
            
        }
        
        
        
    }
    	
   
    if(Trigger.IsDelete){
        P_ProductItemDeleteHandler rh = new P_ProductItemDeleteHandler();
        rh.checkDeletes(Trigger.oldMap);
    }
}