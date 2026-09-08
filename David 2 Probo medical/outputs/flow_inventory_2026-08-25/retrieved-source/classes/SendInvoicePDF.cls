public class SendInvoicePDF{
    
    //class to get multiple inputs from flow
    public class flowInput {  
        @InvocableVariable(required=true)
        public id currentRecordId;
        
        @InvocableVariable(required=true)
        public List<String> eMailList;
        
        @InvocableVariable(required=true)
        public id oppRecordId;
        
        @InvocableVariable
        public String invoiceName;
         
        @InvocableVariable(required=true)
        public boolean sendFSRAttachment;
        
        @InvocableVariable(required=true)
        public boolean includeHIPAAWarning;
         
    }
    
    public class flowOutput {
        @InvocableVariable(label='Record ID' required=true)
        public Id currentRecordId; // To identify which record failed
        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }
    
    
    
    
//invocable method
    @InvocableMethod(label='Email Invoice Attachment' description='Used to send invoice email alert along with invoice and FSR attachments.') 
    
    public static List<FlowOutput> processRecords(List<FlowInput> currentInput){ 
        system.debug('List of Ids = '+currentInput);
          List<FlowOutput> results = new List<FlowOutput>();
        
          for(flowInput singleID :currentInput ){
             
             //fetching record id
              Id rId = singleID.currentRecordId; 
              
              FlowOutput output = new FlowOutput();
              output.currentRecordId = singleID.currentRecordId; // Pass the recordId back

              String sendEmailTo = String.join(singleID.eMailList, ';');
              Id oppId = singleID.oppRecordId;
              String invoiceNameText = ' ';
              Boolean sendFSR = true;
              Boolean includeHIPAA = false;
              
              if(singleID.invoiceName != null){
                    invoiceNameText = singleID.invoiceName;
              }
              
              if(singleID.sendFSRAttachment != null){
                    sendFSR = singleID.sendFSRAttachment;
              }
              
              if(singleID.includeHIPAAWarning != null){
                    includeHIPAA = singleID.includeHIPAAWarning;
              }
              
              
               
              try{
                 SendEmail(rId, sendEmailTo, oppId, invoiceNameText, sendFSR, includeHIPAA);   
                 system.debug('recordID= '+singleID + ' rID = '+rId + ' send email to = ' + sendEmailTo + ' invoice name = ' + invoiceNameText + ' send FSR = ' + sendFSR + ' include HIPAA = ' + includeHIPAA);
                 output.errorMessage = null;
              } catch (Exception e) {
                   output.errorMessage = 'Error processing record ' + rID + ': ' + e.getMessage();
              }
              results.add(output);
            
        }
        return results;
    }
    
   
    public static void SendEmail(String recordId, String sendEmailTo, Id oppId, String invoiceNameText, Boolean sendFSR, Boolean includeHIPAA){
        List<ContentVersion> contentList = new List<ContentVersion> ();
        List<ContentDocumentLink> linkList = new List<ContentDocumentLink> ();
        List<Messaging.EmailFileAttachment> emlAttList = new List<Messaging.EmailFileAttachment> ();
        
        if(sendFSR){
        
        // Fetch Content Document to Upload
        List<ContentDocumentLink> cdlList = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :oppId];
        system.debug('This is the CDL LIST >>> ' + cdlList);
            List<Id> cdlListId = new List<Id> ();
            for(ContentDocumentLink cdlItem: cdlList){
                cdlListId.add(cdlItem.ContentDocumentId);            
            }
        List<ContentVersion> cvList = [SELECT VersionData, FileExtension, Title, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :cdlListId AND (Title like '%FSR%' OR Title like '%PMR%')];
            system.debug('THIS IS THE FSR >> ' + cvList[0].Title);
            
            for(ContentVersion cv:cvList){
                Messaging.EmailFileAttachment emlAtt = new Messaging.EmailFileAttachment();
                Blob fileData = cv.VersionData; // <= This step converts the version data into a blob for the attachment
                emlAtt.setFilename(cv.Title +'.pdf');
                emlAtt.setBody(fileData);
                
                // Attach FSR to invoice object
                ContentVersion contFSR = new ContentVersion();      
                contFSR.VersionData = cv.VersionData;
                contFSR.Title =cv.Title+'.pdf';
                contFSR.PathOnClient = cv.Title+'.pdf';
                  
                contentList.add(contFSR);
                emlAttList.add(emlAtt);
                
            }    
       

        }
        
        // Reference the attachment page, pass in the opportunity ID
        PageReference pdfPage = new PageReference('/apex/Invoice_PDF');
        pdfPage.getParameters().put('ID', recordId);
        
        Blob pdfContent;
        // Take the PDF content
        if(Test.isRunningTest()) { 
            pdfContent = blob.valueOf('Unit.Test');
        }
        else{
            pdfContent = pdfPage.getContent();
        }
        
        // Get date and convert to standard formatting for attachment name
        DateTime d = Date.Today() + 1 ;
        String dateStr =  d.format('MM/dd/yyyy') ;
        
        ContentVersion cont = new ContentVersion();         
        if(Test.isRunningTest()) { 
            cont.VersionData = blob.valueOf('Unit.Test');
        }
        else{
            cont.VersionData = pdfPage.getContentAsPDF();
        }
        cont.Title = invoiceNameText +'.pdf';
        cont.PathOnClient = invoiceNameText + '.pdf';
        contentList.add(cont);
        
        system.debug('THIS IS THE CONTENT LIST >>> ' + contentList);
        insert contentList;
        List<Id> contentIdList = new List<Id>();
        for(ContentVersion cv:contentList){
            contentIdList.add(cv.id);
        }
        
        List<ContentVersion> newContentList = [select Id, ContentDocumentId from ContentVersion where id IN :contentIdList];
        for(ContentVersion cv:newContentList){
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = recordId;
            cdl.Visibility = 'AllUsers';
            cdl.ShareType = 'I';
            linkList.add(cdl);
            
        }
       
        system.debug('THIS IS THE LINK LIST >> ' + linkList);
        insert linkList;
        

        
        // Create the email attachment
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(invoiceNameText +'.pdf');
        efa.setBody(pdfContent);
        efa.setContentType('application/pdf');
        emlAttList.add(efa);    
        //get org wide from address
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'ar@probomedical.com'];
        EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where Name = 'Invoice PDF Email Template'];
        
        // Compile and send the email to the address
        List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        //ParseforAddresses
        String finalAddressString = '';
        List<String> finalAddressList = new List<String>();
        if(sendEmailTo != null){
            finalAddressList = sendEmailTo.split(';');
            mail.setToAddresses(finalAddressList);
        }
        
                
        mail.setOrgWideEmailAddressId(owea.get(0).Id);
        String[] ccAddresses = new String[] {'sentinvoices@probomedical.com'};
        String[] BCCAddresses = new String[] {'82270018-ce49-4d36-86b1-8985ee2f7602@my.anytimecollect.com'};
        mail.setCCAddresses(ccAddresses);
        mail.setBccAddresses(BCCAddresses);
        mail.setSubject('Probo Medical ' + 'Invoice Due ' + '(' + invoiceNameText + ')');
        mail.setHtmlBody(emailTemplate.HtmlValue);
        if(includeHIPAA){
            mail.setPlainTextBody('Dear Customer,\n\nPlease see your attached invoice from Probo Medical. \n\nWe are in the process of updating our records and noticed that the email address we have on file for you appears to be a personal email address. To ensure that we can provide you with the best possible service and comply with HIPAA requirements, we kindly ask that you verify whether this email address is indeed a business email address. \n\nIf the email address provided is a personal one, could you please update us with your business email address at your earliest convenience? This will help us maintain accurate records and ensure that all communications are directed appropriately.\n\nIf you have any questions regarding this invoice, please email AR@probomedical.com or call us at (866) 828-1800\n\nThere is a link in your invoice, but for convenience we have also included a link to pay your invoice online by following this link here: https://www.probomedical.com/pay-probo-medical \n\nImportant Update Regarding Invoicing Schedule:\nStarting September 15th 2025, we will begin issuing invoices on the 15th of each month. If you have any questions or concerns regarding this change, please contact our Customer Service team. \n\nThank you for your continued trust and partnership.\n\nSincerely,\nProbo Medical, LLC\n\n1.866.828.1800\nwww.ProboMedical.com');
        
        }
        else{
            mail.setPlainTextBody('Dear Customer,\n\nPlease see your attached invoice from Probo Medical. If you have any questions regarding this invoice, please email AR@probomedical.com or call us at (866) 828-1800\n\nThere is a link in your invoice, but for convenience we have also included a link to pay your invoice online by following this link here: https://www.probomedical.com/pay-probo-medical/.\n\nSincerely,\nProbo Medical, LLC\n\n1.866.828.1800\nwww.ProboMedical.com');
        
        }
        mail.setFileAttachments(emlAttList);    
        
        mails.add(mail);
        
        Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
        
        if (results[0].success){
            System.debug('The email was sent successfully.');
            } 
        else{
            System.debug('The email failed to send: ' + results[0].errors[0].message);
            } 
    
    }
}