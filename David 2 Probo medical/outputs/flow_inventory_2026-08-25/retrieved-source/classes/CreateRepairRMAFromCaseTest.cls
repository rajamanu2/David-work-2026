@isTest
    private class CreateRepairRMAFromCaseTest {
    
        static testmethod void CaseCreationTest() {
            
            Case customerCase = new Case(Repair_Eval_Probe_Type__c = 'Convex', Repair_Eval_Probe_Manufacturer__c = 'GE', Repair_Eval_Probe_Model__c = 'Test',
                                        Repair_Eval_Contact_First_Name__c = 'John', Repair_Eval_Contact_Last_Name__c = 'Doe', Repair_Eval_Contact_Email__c = 'awalter@probomedical.com');
           
            insert customerCase;
    
            
            Test.startTest();
            GH_Logger.debug('TEST: starts here');
            PageReference pRef = Page.CustomerForm;
            Test.setCurrentPage(pRef);
            ApexPages.currentPage().getParameters().put('id',customerCase.Id);
            ApexPages.StandardController sc = new ApexPages.StandardController(customerCase);
            CreateRepairRMAFromCase createRMA = new CreateRepairRMAFromCase(sc);
            createRMA.savecustomersubmission();
            
            RMA__c testrma = TestDataFactory.createRMA('Customer Repair Evaluation', true);
            
            zkmulti__MCShipment__c portalShipment = new zkmulti__MCShipment__c(RMA__c = testrma.id, zkmulti__Sender_Country__c = 'US',
                                                      zkmulti__Ship_Date__c = Date.today(),zkmulti__Recipient_Country__c = 'US',
                                                      zkmulti__Recipient_Name__c = 'Probo Medical', zkmulti__Recipient_Email__c = 'amadson@probomedical.com',
                                                      zkmulti__Billing_Account_Number__c = '562051309', zkmulti__Billing_Country__c = 'US', 
                                                      zkmulti__Billing_Zip_Postal_Code__c = '46037', 
                                                      zkmulti__Reference1_Type__c = 'Your Reference', 
                                                      zkmulti__Label_Image_Type__c = 'PDF',
                                                      zkmulti__DropoffType__c = 'REGULAR_PICKUP', zkmulti__Recipient_Company__c = 'Probo Medical',
                                                     zkmulti__Recipient_Phone__c = '1-(866)513-8322',
                                                       zkmulti__Package_Type__c = 'Your Packaging',
                                                      zkmulti__Service_Type__c = 'FEDEX_GROUND', zkmulti__Carrier__c = 'FedEx', zkmulti__Currency__c = 'USD', 
                                                      zkmulti__Dimension_Units__c = 'IN', zkmulti__Weight_Units__c = 'LB', zkmulti__Return_Shipment__c = true
                                                      );  
            
            insert portalShipment;
            
            Attachment attach=new Attachment();   	
            attach.Name='Unit Test Attachment';
            Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
            attach.body=bodyBlob;
            attach.parentId=portalShipment.id;
            insert attach;
            
            invocableEmailAttachment.flowinput flow;
			flow = new invocableEmailAttachment.flowinput();
            flow.currentRecordId = portalShipment.id;
            flow.eMail = 'natalie.boger@gmail.com';
            flow.sendAttachment = true;
            flow.eSubject = 'Test';
            flow.eBody = 'Test';
            
            invocableEmailAttachment.currentRecordID(
                new List<invocableEmailAttachment.flowinput>{ flow }
            );
            
    		invocableEmailAttachmentUK.flowinput flow2;
			flow2 = new invocableEmailAttachmentUK.flowinput();
            flow2.currentRecordId = portalShipment.id;
            flow2.eMail = 'natalie.boger@gmail.com';
            flow2.sendAttachment = true;
            flow2.eSubject = 'Test';
            flow2.eBody = 'Test';
            
            invocableEmailAttachmentUK.currentRecordID(
                new List<invocableEmailAttachmentUK.flowinput>{ flow2 }
            );
    
            Test.stopTest();
        }
     
        static testmethod void CaseCreationQuoteTest() {
            
            Case customerCase = new Case(Repair_Eval_Probe_Type__c = 'Convex', Repair_Eval_Probe_Manufacturer__c = 'GE', Repair_Eval_Probe_Model__c = 'Test',
                                        Repair_Eval_Contact_First_Name__c = 'John', Repair_Eval_Contact_Last_Name__c = 'Doe', Repair_Eval_Contact_Email__c = 'awalter@probomedical.com');
           
            insert customerCase;
    
            
            Test.startTest();
            GH_Logger.debug('TEST: starts here');
            PageReference pRef = Page.CustomerForm;
            Test.setCurrentPage(pRef);
            ApexPages.currentPage().getParameters().put('id',customerCase.Id);
            ApexPages.StandardController sc = new ApexPages.StandardController(customerCase);
            CreateRepairRMAFromCase createRMA = new CreateRepairRMAFromCase(sc);
            createRMA.savecustomersubmission();
            
            RMA__c testrma = TestDataFactory.createRMA('Customer Repair Evaluation', true);
            

            invocableEmailAttachmentRepairQuote.flowinput flow;
			flow = new invocableEmailAttachmentRepairQuote.flowinput();
            flow.currentRecordId = customerCase.id;
            flow.eMail = 'natalie.boger@gmail.com';
            flow.sendAttachment = true;
            flow.eSubject = 'Test';
            flow.eBody = 'Test';
            
            invocableEmailAttachmentRepairQuote.currentRecordID(
                new List<invocableEmailAttachmentRepairQuote.flowinput>{ flow }
            );
            
            invocableEmailAttachmentRepairQuoteUK.flowinput flow2;
			flow2 = new invocableEmailAttachmentRepairQuoteUK.flowinput();
            flow2.currentRecordId = customerCase.id;
            flow2.eMail = 'natalie.boger@gmail.com';
            flow2.sendAttachment = true;
            flow2.eSubject = 'Test';
            flow2.eBody = 'Test';
            
            invocableEmailAttachmentRepairQuoteUK.currentRecordID(
                new List<invocableEmailAttachmentRepairQuoteUK.flowinput>{ flow2 }
            );
            
    
    
            Test.stopTest();
        }
        
    
        
    
        
        
    }