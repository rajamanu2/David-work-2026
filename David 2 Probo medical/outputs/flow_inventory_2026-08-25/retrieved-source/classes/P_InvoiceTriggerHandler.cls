public class P_InvoiceTriggerHandler {
    private Map<String, ID> getContactMap(List<String> FSENames) {
        List<Contact> contactList = [SELECT Id, Name, Account.Name 
                                     FROM Contact 
                                     WHERE Name in :FSENames
                                     AND Account.Name = 'Probo Medical - Portal'
                                    ];
        system.debug('THIS IS THE FULL CONTACT LIST >> ' + contactList);
        Map<String, ID> contactMap = new Map<String, ID>();
        for(Contact c : contactList) {
            contactMap.put(c.Name, c.id);
        }
        return contactMap;
    }
    
    private Map<Id, String> getFSEMap(List<Id> oppIds) {
        List<Opportunity> oppList = [SELECT Id, Field_Service_Engineer__c, AccountId
                                     FROM Opportunity 
                                     WHERE Id in :oppIds 
                                    ];
        system.debug('THIS IS THE FULL OPP LIST >>> ' + oppList);
        Map<Id, String> FSEMap = new Map<Id, String>();
        for(Opportunity opp : oppList) {
            system.debug('THIS IS THE STRING VALUE OF FSE >>> ' + string.valueof(opp.Field_Service_Engineer__c));
            FSEMap.put(opp.id, string.valueof(opp.Field_Service_Engineer__c));
        }
        return FSEMap;
    }
    
    public void doTriggerWork(List<Invoice__c> invoiceList, Map<Id, Invoice__c> oldInvoices) {
        if (Trigger.isDelete) {
            checkDeletes(oldInvoices);
        } else {
            if (Trigger.IsUpdate) {
                checkUpdates(invoiceList, oldInvoices);
                processFSEPortalInfo(invoiceList, oldInvoices);
            }
        }
    }
    
    
    public void processFSEPortalInfo(List<Invoice__c> invoiceList, Map<Id, Invoice__c> oldInvoices){
        List<String> FSENames = new List<String>();
        List<Id> oppIds = new List<Id>();
        for (Invoice__c invoiceItem : invoiceList) {
            if(invoiceItem.Opportunity__c != null){
                oppIds.add(invoiceItem.Opportunity__c);
            }
            
        }
        system.debug('THIS IS THE OPP ID LIST >>> ' + oppIds);
        Map<ID, String> FSEMap = getFSEMap(oppIds);
        system.debug('THIS IS THE FSE MAP >>> ' + FSEMap);
        for(Id oppId: oppIds){
            
            if(FSEMap.get(oppId) != null){
                system.debug('THIS IS THE FSE NAME >> ' + FSEMap.get(oppId));
                FSENames.add(FSEMap.get(oppId));
            }
        }
        
        Map<String, ID> contactMap = getcontactMap(FSENames);
        system.debug('THIS IS THE CONTACT MAP >>> ' + contactMap);
        for(Invoice__c invoiceItem:InvoiceList){
            String FSEText = FSEMap.get(invoiceItem.Opportunity__c);
            system.debug('THIS IS THE FSE TEXT >> ' + FSEText);
            
            if (FSEText != null){
                try{
                    if(invoiceItem.FSE_Portal_Contact__c != contactMap.get(FSEText)){
                        system.debug('THIS IS THE CONTACT MAP FOR FSE TEXT >> ' + contactMap.get(FSEText) + ' AND THE INVOICE FSE PORTAL >> ' + invoiceItem.FSE_Portal_Contact__c);
                        
                        invoiceItem.FSE_Portal_Contact__c = contactMap.get(FSEText);
                    } 
                    
                }
                catch(DmlException e){
                    system.debug('Error finding FSE Portal Contact >>> ' + FSEText);
                }
                
                
            }
            
        }
        
    }
    
    // This prevents anyone from deleted an invoice that is synced to intacct.
    private void checkDeletes(Map<Id, Invoice__c> oldRecs) {
        for (Invoice__c i : oldRecs.values()) {
            if (i.Intacct_Invoice_Sync_Status__c != '' && i.Intacct_Invoice_Sync_Status__c != null) {
                if (!i.Allow_Delete__c) {
                	i.addError('You can not delete an Invoice that has been synced with Intacct');                    
                } else {
                    Synced_Record_Delete_Log__c dl = new Synced_Record_Delete_Log__c(
                        Name=i.Name,
                        Record_Id__c=i.Id,
                        Record_Type__c='Invoice__c'
                    );
                    insert dl;
                }
            }
        }
    }
    
    // This prevents anyone from changing the status if it is synced to intacct.
    public void checkUpdates(List<Invoice__c> newRecs, Map<Id, Invoice__c> oldRecs) {
        Boolean hasPermission = FeatureManagement.checkPermission('Manage_Intacct_Synced_Records');
        for (Invoice__c inv : newRecs) {
            if (oldRecs.get(inv.Id).Intacct_Invoice_Sync_Status__c == 'Synced' && inv.Intacct_Invoice_Sync_Status__c != 'Synced' && !hasPermission) {
                inv.addError('You can not change the status of an Invoice that has been synced with Intacct');
            }
        }
    }
}