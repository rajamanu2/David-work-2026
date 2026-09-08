public class EmailWorkOrderPDF {
    
    public WorkOrder WO { get; set; }
    private static Id serviceRT;
    private static Id maintenanceRT;
    
    public EmailWorkOrderPDF(ApexPages.StandardController controller) {
        WO =  (WorkOrder) controller.getRecord();
        system.debug('THIS IS THE NEW WO >>> ' + WO);
    }
     @invocablemethod(label='send WO PDF Email')
    public static void sendPDFEmail(list<WorkOrder> newRecs){
         // SEND EMAIL TO FSE WITH ATTACHED PDF FORM
        getRecordTypes();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		for(WorkOrder newWO:newRecs){
            system.debug('THIS IS THE WO INSIDE NEW RECS LOOP >>> ' + newWO);
            Boolean preventativeMaintenance = false;
            Boolean fieldServiceReport = false;
            if(newWO.Work_Order_PDF_Type__c == 'Preventative Maintenance Report' || (newWO.Work_Order_PDF_Type__c == null && newWO.RecordTypeId == maintenanceRT)){
                preventativeMaintenance = true;
            }
            if(newWO.Work_Order_PDF_Type__c == 'Field Service Report' || (newWO.Work_Order_PDF_Type__c == null && newWO.RecordTypeId == serviceRT)){
                fieldServiceReport = true;
            }
            if((newWO.Status == 'PO Requested' || newWO.Status.contains('Completed')) && newWO.id != null && (preventativeMaintenance == true || fieldServiceReport == true)){
                String subject = '';
        		String attachmentname = '';
               
                PageReference newPDF;
                if(preventativeMaintenance == true){
                    subject = 'PMR Form for ' + newWO.Account_Name__c + ' WO #' + newWO.WorkOrderNumber;
                    attachmentname = 'PMR Form ' + newWO.WorkOrderNumber + '.pdf';
                    newPDF = Page.Preventative_Maintenance_Report_PDF;
                }
                if(fieldServiceReport == true){
                    subject = 'FSR Form for ' + newWO.Account_Name__c + ' WO #' + newWO.WorkOrderNumber;
                    attachmentname = 'FSR Form ' + newWO.WorkOrderNumber + '.pdf';
                    newPDF = Page.Field_Service_Report_PDF;
                }
                String Body = '<Html><body><div> Thank you for choosing Probo Medical! We have completed your service ticket. Attached, you will find the service form. </div>' +
               '<div Style="margin-top:10px">If you have any questions please don\'t hesitate to contact your Probo Medical representative. </div></body></Html>';
                
                system.debug('THIS IS THE CURRENT WO FOR EMAIL >>> ' + newWO);
                newPDF.getParameters().put('id',newWO.id);
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
                String sendEmailTo = 'sfsupport@probomedical.com';
                system.debug('THIS IS THE WO FSE FIELD BEFORE EMAIL >>> ' + newWO.Field_Service_Engineer__c);
                if(newWO.Field_Service_Engineer__c != null){
                    list<String> FSEList = newWO.Field_Service_Engineer__c.split(';');
                    
                    List<String> engineer = FSEList[0].split(' ');String secondPart ='';if(engineer.size () >= 2){secondPart = engineer[1];
                    }   
                    sendEmailTo =  FSEList[0].substring(0,1) + secondPart + '@probomedical.com';
                }
                system.debug('THIS IS THE SEND TO EMAIL >>> ' + sendEmailTo);
               /* if(newWO.FSE_Email__c != null){
                    sendEmailTo = newWO.FSE_Email__c;
                }*/
                email.setToAddresses(new String[]{
                    sendEmailTo
                });
                email.setSenderDisplayName('Probo Medical');
                //email.setTargetObjectId(UserInfo.getUserId());
                email.setSubject(subject);
                email.setHtmlBody(Body);
                email.setSaveAsActivity(false);
        
                email.setFileAttachments(new Messaging.EmailFileAttachment[]{
                        pfile
                });
        
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                        email
                });

            }
            
        }

        
    }
    public PageReference SendEmail() {
        String subject = '';
        String attachmentname = '';
        PageReference newPDF;
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        system.debug('THIS IS THE NEW WO INSIDE THE PAGE REFERENCE >>> ' + WO);
        if(WO.Work_Order_PDF_Type__c == 'Preventative Maintenance Report'){
            subject = 'PMR Form for ' + WO.Account.Name + ' WO #' + WO.WorkOrderNumber;
            attachmentname = 'PMR Form ' + WO.WorkOrderNumber + '.pdf';
            newPDF = Page.Preventative_Maintenance_Report_PDF;
        }
        if(WO.Work_Order_PDF_Type__c == 'Field Service Report'){
            subject = 'FSR Form for ' + WO.Account.Name + ' WO #' + WO.WorkOrderNumber;
            attachmentname = 'FSR Form ' + WO.WorkOrderNumber + '.pdf';
            newPDF = Page.Field_Service_Report_PDF;
        }
        String Body = '<Html><body><div> Thank you for choosing Probo Medical! We have completed your service ticket. Attached, you will find the service form. </div>' +
            '<div Style="margin-top:10px">If you have any questions please don\'t hesitate to contact your Probo Medical representative. </div></body></Html>';
        
        system.debug('THIS IS THE CURRENT WO FOR EMAIL >>> ' + WO);
        newPDF.getParameters().put('id',WO.id);
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
        String sendEmailTo = 'natalie.boger@gmail.com';
        /*if(WO.FSE_Email__c != null){
            sendEmailTo = WO.FSE_Email__c;
        }*/
        if(WO.Field_Service_Engineer__c != null){
            list<String> FSEList = WO.Field_Service_Engineer__c.split(';');
            
            List<String> engineer = FSEList[0].split(' ');String secondPart ='';if(engineer.size () >= 2){secondPart = engineer[1];
                                                                                                         }   
            sendEmailTo =  FSEList[0].substring(0,1) + secondPart + '@probomedical.com';
        }
        email.setToAddresses(new String[]{
            sendEmailTo
                });
        email.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
        email.setTargetObjectId(UserInfo.getUserId());
        email.setSubject(subject);
        email.setHtmlBody(Body);
        email.setSaveAsActivity(false);
        
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{
            pfile
                });
        
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
            email
                });

        GH_Logger.debug('Email sent results: ' + results);

        return new PageReference('/apex/EmailSent');
    }
    
    public static void getRecordTypes() {
        for (RecordType r : ProboCommonUtils.getRecordTypes('WorkOrder')) {
            switch on r.Name {
                when 'Service Call' {
                    serviceRT = r.id;
                }
                when 'Preventative Maintenance' {
                    maintenanceRT = r.id;
                }
            }
     	}
     }

}