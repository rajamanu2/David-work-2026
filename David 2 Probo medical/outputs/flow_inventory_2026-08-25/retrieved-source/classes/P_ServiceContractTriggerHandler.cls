public class P_ServiceContractTriggerHandler {
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
    

    public void processFSEInfo(List<ServiceContract> contractList, Map<Id, ServiceContract> oldContracts){
        
        
        
        List<String> FSENames = new List<String>();
        List<Id> oppIds = new List<Id>();
        for (ServiceContract contractItem : contractList) {
            if(contractItem.Field_Service_Engineers__c != null && contractItem.FSE_Email__c == null){
                list<String> FSEList = contractItem.Field_Service_Engineers__c.split(';');
                
                List<String> engineer = FSEList[0].split(' ');String secondPart ='';if(engineer.size () >= 2){secondPart = engineer[1];
                } 
                
                contractItem.FSE_Email__c =  FSEList[0].substring(0,1) + secondPart + '@probomedical.com';
                
            
            }
            if(contractItem.Opportunity__c != null){
                oppIds.add(contractItem.Opportunity__c);
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
        for(ServiceContract contractItem:contractList){
            String FSEText = FSEMap.get(contractItem.Opportunity__c);
            system.debug('THIS IS THE FSE TEXT >> ' + FSEText);
            
         	if (FSEText != null){
                try{
                    if(contractItem.FSE_Portal_Contact__c != contactMap.get(FSEText)){
                        system.debug('THIS IS THE CONTACT MAP FOR FSE TEXT >> ' + contactMap.get(FSEText) + ' AND THE CONTRACT FSE PORTAL >> ' + contractItem.FSE_Portal_Contact__c);
                        
                        contractItem.FSE_Portal_Contact__c = contactMap.get(FSEText);
                    } 
                    
                }
                catch(DmlException e){
                    system.debug('Error finding FSE Portal Contact >>> ' + FSEText);
                }
                     
                        
            }
           
        }
        
        
        
    }
    
    
}