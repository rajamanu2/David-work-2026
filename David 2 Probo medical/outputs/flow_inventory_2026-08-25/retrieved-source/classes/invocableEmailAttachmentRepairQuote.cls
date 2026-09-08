global class invocableEmailAttachmentRepairQuote {
 
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
        
        @InvocableVariable
        global boolean sendAttachment;
         
    }
    
    //invocable method
    @InvocableMethod(label='Email with Quote Attachment' description='Used to send email alert along with attachments on the record.') 
    
    global static void currentRecordID(flowInput[] currentInput){      
        
        system.debug('List of Ids = '+currentInput);
        
            ID rId;
        
          for(flowInput singleID :currentInput ){
                
             //fetching record id
             rId = singleID.currentRecordId;                            
                
            system.debug('recordID= '+singleID + ' rID = '+rId);
                
            //Get the obbject of the record id
            sobject sO = rId.getSobjectType().newsobject(rId);
            
            system.debug('sO='+sO);
            
        }
        system.debug('THIS IS THE RID >>> ' + rID);
   
        //New email message method
        Messaging.SingleEmailMessage mail= new Messaging.SingleEmailMessage();    
        
        //defining list of email attachments
        List<Messaging.EmailFileAttachment> attach= new list<Messaging.EmailFileAttachment>();
        
        
        PageReference pdf = Page.RepairEvaluationToolQuote;
        pdf.getParameters().put('id', rID);
        pdf.setRedirect(true);

        Blob b;
        // TODO: the tests need to handle this so we remove the code here
        if (Test.isRunningTest()) {
            b = Blob.valueOf('this is a pdf string');
        } else {
            // Take the PDF content
            b = pdf.getContent();
        }
        // Create the email attachment
        Messaging.EmailFileAttachment pfile = new Messaging.EmailFileAttachment();
        pfile.setFileName('Repair Evaluation Quote from Probo Medical.PDF');
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
            List<ID> ccSendTo = new list<ID>();
            
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
        
            //Attachment
                   if(currentInput[0].sendAttachment ==True){
                            mail.setFileAttachments(attach);            
                    }
              
                    
            //Send Email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
    }

 }