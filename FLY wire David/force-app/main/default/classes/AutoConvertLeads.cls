Public class AutoConvertLeads {     
    
    @InvocableMethod   
    public static void LeadAssign(List<Id> LeadIds){
    	system.debug('here');        
        LeadStatus CLeadStatus= [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true Limit 1];    
        List<Lead> leads = [SELECT Id, Account__c, Email FROM Lead WHERE Id IN :LeadIds];  
        
        //get related contacts if any
        set<string> leadContactSet = new set<string>();
        for(Lead currentlead: leads){ 
            if(currentlead.Email != null && currentlead.Email != ''){
                leadContactSet.add(currentlead.Email);
            }
        }
        Map<string,Id> leadEmailVsContactIdMap =  new Map<string,Id>();
        for(Contact conForVar : [SELECT Id, Email FROM Contact WHERE Email IN :leadContactSet]){
            leadEmailVsContactIdMap.put(conForVar.Email, conForVar.Id);
        }
        
        List<Database.LeadConvert> MassLeadconvert = new List<Database.LeadConvert>();    
        for(Lead currentlead: leads){                
            Database.LeadConvert Leadconvert = new Database.LeadConvert();    
            Leadconvert.setLeadId(currentlead.Id);                               
            Leadconvert.setAccountId(currentlead.Account__c);
            if(leadEmailVsContactIdMap.get(currentlead.Email) != null){
                Leadconvert.setContactId(leadEmailVsContactIdMap.get(currentlead.Email));
            }
            Leadconvert.setConvertedStatus('SQL (Sales Qualified Lead)');             
            Leadconvert.setDoNotCreateOpportunity(TRUE); //Remove this line if you want to create an opportunity from Lead Conversion  
            MassLeadconvert.add(Leadconvert);    
        } 
        system.debug('here');              
        if (!MassLeadconvert.isEmpty()){            
            List<Database.LeadConvertResult> lcr = Database.convertLead(MassLeadconvert, false);  
        }    
    } 
}