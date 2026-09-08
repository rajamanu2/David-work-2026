global class UpdateRMABatch implements Database.Batchable<sObject>,Schedulable,Database.AllowsCallouts{
    
        String Query;
        
        global Database.QueryLocator start(Database.BatchableContext bc){
    
            Query = 'Select Id, Create_Shipment__c, Run_Shipment_Flow__c from RMA__c WHERE Create_Shipment__c = true AND Run_Shipment_Flow__c = false';                         
            return Database.getQueryLocator(query);
        }
    
         global void execute(Database.BatchableContext bc, List<RMA__c> rmalist){
             list<RMA__c> updateRMAList = new list<RMA__c>();
            
			system.debug('THIS IS THE RMA LIST SIZE >> ' + rmalist);             
             for(RMA__c newRMA:rmalist){
                 if(newRMA.Create_Shipment__c == true && newRMA.Run_Shipment_Flow__c == false){
                     newRMA.Run_Shipment_Flow__c = true;
                     updateRMAList.add(newRMA);
                 }
             }
             system.debug('AND THIS IS THE UPDATE RMA LIST >> ' + updateRMAList);
             update updateRMAList;
         }
    
        global void execute(SchedulableContext sc) {
              UpdateRMABatch  bc = new UpdateRMABatch(); 
              database.executebatch(bc,1000);
        /*  System.schedule('Scheduled Job RMAs 1', '0 0 * * * ?', new UpdateRMABatch());
          System.schedule('Scheduled Job RMAs 2', '0 15 * * * ?', new UpdateRMABatch());
          System.schedule('Scheduled Job RMAs 3', '0 30 * * * ?', new UpdateRMABatch());
          System.schedule('Scheduled Job RMAs 4', '0 45 * * * ?', new UpdateRMABatch());*/
            
        }
    
        
    
        global void finish(Database.BatchableContext bc){
            system.debug('This method is required by the interface.');
        }
}