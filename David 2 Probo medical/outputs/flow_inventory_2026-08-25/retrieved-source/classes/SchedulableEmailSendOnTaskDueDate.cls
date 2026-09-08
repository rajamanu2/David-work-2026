global class SchedulableEmailSendOnTaskDueDate implements Schedulable,Database.Batchable<SObject>{

    // TODO: Hardcoded is all set, but there is a SendMail in a loop
    global void execute(SchedulableContext SC) {
        /*
        List<Task> taskList = [Select Id,ActivityDate, Owner.name, OwnerId,Who.FirstName, Who.LastName,What.Name,What.Id, Owner.Email,Description,Subject from Task Where ActivityDate <= Today and Status!='Completed'];
        for(Task t: taskList){
        
            try{ 
                //EmailTemplate etemp = [select id from EmailTemplate where Name='TaskDueDateEmailTemplate' and isactive=TRUE ]; 
                
                Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage (); 
                
                mail.setSenderDisplayName('Automated Process'); 
                mail.setReplyTo(t.Owner.email); 
                mail.setTargetObjectId(t.OwnerId); 
                //mail.setTemplateId(etemp.id);
                mail.setSaveAsActivity(false);
                mail.setToAddresses(new String[]{t.Owner.email});
                mail.setSubject('This task is due');  
                
                String body = 'The task is due. Please take appropriate action.\n '+
                'Subject: '+(t.Subject==null?'':t.Subject)+'\n'+
                'Name of the Person: '+(t.Who.FirstName==null?'':t.Who.FirstName)+' '+ (t.Who.LastName==null?'':t.Who.LastName)+'\n'+
                'Related To: '+(t.What.Name==null?'':t.What.Name)+'\n'+
                'Related To Id: '+(t.What.Id==null?'':t.What.Id)+'\n'+
                'The task description: '+(t.Description==null?'':t.Description)+'\n'+
                'Link to the Task :'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + t.Id;
                
                mail.setPlainTextBody(body) ;
                try
                { 
                    messaging.sendEmail(new messaging.Singleemailmessage[]{mail}); 
                }
                catch(Exception e){
                    system.debug('ERROR SENDING EMAIL:'+e.getMessage()); 
                } 
            }catch(Exception Ex){ 
            
                system.debug(Ex); 
            } 
        
            
        }*/
        /*
        if(!Test.isRunningTest()){      
            Id cronTrigId = SC.getTriggerId();
            System.abortJob(cronTrigId);
        }*/
        SchedulableEmailSendOnTaskDueDate job = new SchedulableEmailSendOnTaskDueDate();
        Integer batchSize =10;
        ID batchProecssedId = Database.executeBatch(job, batchSize);
      
        
    }
    global Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([Select Id,ActivityDate, Owner.name, OwnerId,Who.FirstName, Who.LastName,What.Name,What.Id, Owner.Email,Description,Subject from Task Where ActivityDate <= Today and Status!='Completed' and Owner.Name != 'Matt Mooney']);

        
    }
    global void execute(Database.BatchableContext context,List<SObject> scope) {
        for(Sobject sobj : scope){
            Task t= (Task)sobj;
            try{ 
                //EmailTemplate etemp = [select id from EmailTemplate where Name='TaskDueDateEmailTemplate' and isactive=TRUE ]; 
                
                Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage (); 
                
                mail.setSenderDisplayName('Automated Process'); 
                mail.setReplyTo(t.Owner.email); 
                mail.setTargetObjectId(t.OwnerId); 
                //mail.setTemplateId(etemp.id);
                mail.setSaveAsActivity(false);
                //mail.setToAddresses(new String[]{t.Owner.email});
                mail.setSubject('This task is due');  
                
                String body = 'The task is due. Please take appropriate action.\n '+
                'Subject: '+(t.Subject==null?'':t.Subject)+'\n'+
                'Name of the Person: '+(t.Who.FirstName==null?'':t.Who.FirstName)+' '+ (t.Who.LastName==null?'':t.Who.LastName)+'\n'+
                'Related To: '+(t.What.Name==null?'':t.What.Name)+'\n'+
                'Related To Id: '+(t.What.Id==null?'':t.What.Id)+'\n'+
                'The task description: '+(t.Description==null?'':t.Description)+'\n'+
                'Link to the Task :'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + t.Id;
                
                mail.setPlainTextBody(body) ;
                try
                { 
                    messaging.sendEmail(new messaging.Singleemailmessage[]{mail}); 
                }
                catch(Exception e){
                    system.debug('ERROR SENDING EMAIL:'+e.getMessage()); 
                } 
            }catch(Exception Ex){ 
            
                system.debug(Ex); 
            } 
        }
    }
    global void finish(Database.BatchableContext context) {
        system.debug('This method is required by the interface.');
    }
}