public class AQS_AAEnablementHomeController{

    // public variables for VF page
    public List<sbaa__EmailTemplate__c> currentEmailTemplates {get;set;}
    public AQS_AA_Enablement_IDs__c recordTypeSetting {get;set;}

    // constructor
    public AQS_AAEnablementHomeController(){
        fetchEmailTemplates();
        recordTypeSetting = AQS_AA_Enablement_IDs__c.getOrgDefaults();
    }
    

    //-------------------------------------- Methods -----------------------------------------------------------------
    //------------------------------------------
    
    //get Email Templates
    public void fetchEmailTemplates(){
        currentEmailTemplates =
            [   SELECT Id, Name, sbaa__TemplateId__c, CreatedDate, CreatedBy.Name
                FROM sbaa__EmailTemplate__c
                ORDER BY Name ASC
        ];
    }

    //------------------------------------------

    //method for creating email templates used by the button on VF page
    public PageReference createTemplates() {

        //collects email templates from installed folder
        List<EmailTemplate> installedEmailTemplates = 
            [   SELECT Id, Name, Folder.Name
                FROM EmailTemplate
                WHERE Folder.Name = 'AQS AA Email Templates'
            ];
            
        System.debug('installedEmailTemplates results: ' + installedEmailTemplates);
            
        //new email template list for creation later
        List <sbaa__EmailTemplate__c> emailTemplatesToCreate = new List<sbaa__EmailTemplate__c>();
            
            
        //loops through queried list, sets values for email template records
        for(EmailTemplate currentEmailTemplate : installedEmailTemplates) {
            sbaa__EmailTemplate__c addedSBAAEmailTemplate = new sbaa__EmailTemplate__c();
        
            addedSBAAEmailTemplate.Name = currentEmailTemplate.name;
            addedSBAAEmailTemplate.sbaa__templateID__c = currentEmailTemplate.Id;
        
            emailTemplatesToCreate.add(addedSBAAEmailTemplate);
        }
            
        System.debug('emailTemplatesToCreate results: ' + emailTemplatesToCreate);
            
        //inserts new email template records
        insert emailTemplatesToCreate;

        //rerenders the email template list
        fetchEmailTemplates();

        //adds a message displayed to the user when the creates email template records
        String emailTemplateMessage = 'Successfully added email templates!';
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, emailTemplateMessage));

        return null;
    }

    // ↓↓↓↓↓ DEPRECATED ↓↓↓↓↓
    //------------------------------------------------
    //method used to update the record type custom setting fields, used by a button on the VF page
    // public PageReference updateCustomSetting(){

    //     //gets record types to update into custom setting
    //     String approvedQuoteRecordTypeID = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('AQS Approved Quote').getRecordTypeId();
    //     String draftQuoteRecordTypeID = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('AQS Draft Quote').getRecordTypeId();
    //     String inProgressQuoteRecordTypeID = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('AQS In Progress Quote').getRecordTypeId();

    //     recordTypeSetting.AQS_Approved_Quote_RT__c = approvedQuoteRecordTypeID;
    //     recordTypeSetting.AQS_Draft_Quote_RT__c = draftQuoteRecordTypeID;
    //     recordTypeSetting.AQS_In_Progress_Quote_RT__c = inProgressQuoteRecordTypeID;

    //     System.debug('recordTypeSetting values: ' + recordTypeSetting);
        
    //     //update custom setting with id's from installed record types
    //     if (recordTypeSetting.Id == null) {
    //         insert recordTypeSetting;
    //     }
    //     else {
    //         update recordTypeSetting;
    //     }

    //     //adds a message displayed to the user when the button is clicked
    //     if (String.isBlank(recordTypeSetting.AQS_Approved_Quote_RT__c) ||
    //         String.isBlank(recordTypeSetting.AQS_Draft_Quote_RT__c) ||
    //         String.isBlank(recordTypeSetting.AQS_In_Progress_Quote_RT__c)
    //         ){
    //         String customSettingUpdateMessage = 'One or more record type fields in the custom setting is blank and will cause errors when submitting for approval. You may need to manually update the custom setting "SBAA__Enablement_IDs__c" with the proper values.';
    //         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, customSettingUpdateMessage));
    //     }
    //     else {
    //         String customSettingUpdateMessage = 'Successfully updated record type custom settings!';
    //         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, customSettingUpdateMessage));
    //     }

    //     return null;
    // }

    //------------------------------------------------
    //method used to update the email custom setting field, used by a button on the VF page
    // public PageReference updateEmailLogoId(){
    //     //updates the approval email logo id field based on the user input

    //     if (recordTypeSetting.Id == null) {
    //         insert recordTypeSetting;
    //     }
    //     else {
    //         update recordTypeSetting;
    //     }

    //     if (String.isBlank(recordTypeSetting.AQS_Approval_Email_Logo_ID__c)) {
    //         System.debug('Approval_Email_Logo_ID__c is blank');
    //     }
    //     else {
    //         System.debug('Approval_Email_Logo_ID__c length: ' + recordTypeSetting.AQS_Approval_Email_Logo_ID__c.length());
    //     }
        

    //     //adds a message displayed to the user when the button is clicked
    //     if (String.isBlank(recordTypeSetting.AQS_Approval_Email_Logo_ID__c)
    //         ||
    //         (
    //             recordTypeSetting.AQS_Approval_Email_Logo_ID__c.length() != 15
    //             &&
    //             recordTypeSetting.AQS_Approval_Email_Logo_ID__c.length() != 18
    //         )
    //         ){
    //         String emailSettingUpdateMessage = 'The custom setting field has been updated, but the value may not be in the proper format. Ensure that you have a 15 or 18 digit document ID populated in the field.';
    //         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, emailSettingUpdateMessage));
    //     }
    //     else {
    //         String emailSettingUpdateMessage = 'Successfully updated email custom setting!';
    //         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, emailSettingUpdateMessage));
    //     }

    //     return null;
    // }
    // ↑↑↑↑↑ DEPRECATED ↑↑↑↑↑
}