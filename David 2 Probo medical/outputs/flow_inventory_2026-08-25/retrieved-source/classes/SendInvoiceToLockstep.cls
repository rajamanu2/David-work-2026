public class SendInvoiceToLockstep {
@InvocableMethod
    public static void SendInvoicePDFtoLockstep(List<Id> ids){
    for(Id id: ids){
           SendEmail(id);
    	} 
    }
    
    @future(callout=true)
    public static void SendEmail(String Id){
        Invoice__c Invoice = [SELECT Id, Name, Opportunity__c, Send_Invoice_To__c FROM Invoice__c WHERE Id =: id];
        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity WHERE Id =: Invoice.Opportunity__c];
        String InvoiceName = Invoice.Name;
        // Reference the attachment page, pass in the opportunity ID
        PageReference pdfPage = new PageReference('/apex/Invoice_PDF');
        
        IF(Opp.ownerId == '005U00000034bYGIAY'){
        pdfPage = new PageReference('/apex/Service_Contract_Invoice_PDF');    
        }
        
        pdfPage.getParameters().put('ID', id);
        
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
        cont.Title = InvoiceName;
        cont.PathOnClient =InvoiceName + '.pdf';
        
            
        insert cont;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cont.Id].ContentDocumentId;
        cdl.LinkedEntityId = id;
		cdl.Visibility = 'AllUsers';
        cdl.ShareType = 'I';
		
        insert cdl;
        
        // Create the email attachment
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(InvoiceName + '.pdf');
        efa.setBody(pdfContent);
            
        //get org wide from address
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'ar@probomedical.com'];
        EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where Name = 'Invoice PDF Email Template'];
        
        // Compile and send the email to the address
        List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        /* Swap out with Lockstep once ready to go ↓*/
        list<String> toAddresses = new List<String>();
        toAddresses.add('brandon@delegate.team');
        toAddresses.add('82270018-ce49-4d36-86b1-8985ee2f7602@my.anytimecollect.com');
        mail.toAddresses = toAddresses;          
        mail.setOrgWideEmailAddressId(owea.get(0).Id);
        String[] ccAddresses = new String[] {'sentinvoices@probomedical.com'};
        mail.setCCAddresses(ccAddresses);
        mail.setSubject('Probo Medical ' + Invoice.Name + ' Lockstep');
  		mail.setHtmlBody(emailTemplate.HtmlValue);
        mail.setPlainTextBody('Dear Lockstep,\n\nPlease see attached invoice '+ Invoice.Name + ' from Probo Medical.');
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
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