public class OLIController {

     public class OLIWrapper {
        public OpportunityLineItem OLI {
            get;
            set;
        }
        public Boolean selectedOLI {
            get;
            set;
        }
        
        public OLIWrapper() {
            this.selectedOLI = false;
        }
        
        public OLIWrapper(OpportunityLineItem OLI) {
            this();
            this.OLI = OLI;
        }
    }
    
    public List<OLIWrapper> OLIList {get; set;}
    public Opportunity Opp {get;set;}
	public List<OpportunityLineItem> DeleteList {get; set;}
    
    
   
    
    public OLIController(ApexPages.StandardController controller){
        Opp = (Opportunity)controller.getRecord();
        OLIList = new List<OLIWrapper>();
        
        for (OpportunityLineItem OLI : [
            select id, Asset_No__c, Product_Name__c, UnitPrice, Cost__c, Serial_No__c
            from OpportunityLineItem where OpportunityID =:Opp.ID
        ]) {
            OLIList.add(new OLIWrapper(OLI));
        }
        
        
    }
    
    
    
    public PageReference MassDelete() {
        deleteList = new List<OpportunityLineItem>();
    	for (OLIWrapper wrapper : this.OLIList) {
            if(wrapper.SelectedOLI == true){
                DeleteList.add(wrapper.OLI);
            }
            
        }
        if(!DeleteList.isempty()){
            delete DeleteList;
        }
        	
        	return new PageReference('/' + Opp.id) ;
    }
    
}