global class EmailPostRepairEvalPDF {
 
    //class to get multiple inputs from flow
    global class flowInput {                  
        @InvocableVariable(required=true)
        global String eMail;
        
        @InvocableVariable
        global String ccMail;
        
        @InvocableVariable(required=true)
        global String eSubject;
        
        @InvocableVariable
        global String ebody;
         
        @InvocableVariable
        global id currentRecordId;
        
         
    }
    
    //invocable method
    @InvocableMethod(label='Email Post Repair Eval') 
    
    global static void currentRecordID(flowInput[] currentInput){      
        
        system.debug('List of Ids = '+currentInput);
        
            ID rId;
            Evaluation_Natalie__c newEval;
        
          for(flowInput singleID :currentInput ){
                
             //fetching record id
             rId = singleID.currentRecordId;                            
                
            system.debug('recordID= '+singleID + ' rID = '+rId);
                
            //Get the eval from record id
            newEval = [select Id, Account_Name__c, Probe_Serial_Number__c from Evaluation_Natalie__c where Id =:rId];
            
            
        }
        system.debug('THIS IS THE RID >>> ' + rID + ' AND EVAL >>> ' + newEval);
                    
        
        
        //New email message method
        Messaging.SingleEmailMessage mail= new Messaging.SingleEmailMessage();    
        
        // set up eval as attachment
      	PageReference newPDF;
        String subject = 'Post Repair Evaluation for ' + newEval.Account_Name__c + ' SN #' + newEval.Probe_Serial_Number__c;
        String attachmentname = 'Post Repair Evaluation ' + newEval.Probe_Serial_Number__c + '.doc';
        newPDF = Page.EvaluationPostRepairSummary;
        newPDF.getParameters().put('id',newEval.id);
        newPDF.setRedirect(true);
         Blob b;
        if (Test.isRunningTest()) {
            b = Blob.valueOf('this is a pdf string');
        } else {
            // Take the PDF content
            b = newPDF.getContent();
        }
    
                // Create the email attachment
                Messaging.EmailFileAttachment pfile = new Messaging.EmailFileAttachment();
                pfile.setFileName(attachmentname);
                pfile.setBody(b);
        		mail.setFileAttachments(new Messaging.EmailFileAttachment[]{
            		pfile
                });
      
              
            //List of TO email id's 
              List<String> sendTo = new list<String>();
                      
                        for(String emailId : currentInput[0].eMail.split(',')){
                            if(emailId !=Null){
                                sendTo.add(emailId.trim());
                            }
                            
                        }    
                  
              system.debug('send TO = '+sendTo);  
                    mail.setToAddresses(sendTo);        
              
        //List of CC email id's:
        
        if(currentInput[0].ccMail!=Null  && currentInput[0].ccMail.trim() != ''){            system.debug('ccMail '+currentInput[0].ccMail );
            List<String> ccSendTo = new list<String>();
            
                    for(String ccEmailId : currentInput[0].ccMail.split(',')){
                        if(ccEmailId!=Null){
                            ccSendTo.add(ccEmailId.trim());
                        }
                        
                    }
              
              mail.setCcAddresses(ccSendTo);
                    system.debug('cc : '+ccSendTo);    
        }
            
                 //Email Body
                     mail.setPlainTextBody(currentInput[0].eBody);
        
            //Email subject
              mail.setSubject(currentInput[0].eSubject);
        
        	//Email sender
        	OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'mmooney@probomedical.com'];

            if ( owea.size() > 0 ) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }
        	
         
            //Send Email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
    }

 }