public class InvoiceOppProducts {
    public List<OpportunityLineItem> SortedlineItems { get; set; }
    public Boolean isCanada { get; set; }
    public Boolean isUSA { get; set; }
    public Boolean isGSTHST { get; set; }
    public String entityName { get; set; }
    public String addressLine1 { get; set; }
    public String addressLine2 { get; set; }
    public String displayCurrency { get; set; }
    public String checkRemittance { get; set; }
    public String wiringACHFundsBank { get; set; }
    public String overnightedChecks { get; set; }
    
    
    Public InvoiceOppProducts( ApexPages.StandardController std )
    {
        if( std.getRecord().Id != null )
        {
            isGSTHST = false;
            isCanada = false;
            isUSA = true;
            entityName = 'Probo Medical, LLC';
            addressLine1 = 'Tampa, FL 33634';
            addressLine2 = '';
            displayCurrency = '$';
            checkRemittance = 'Probo Medical LLC<br/>P.O. Box 735363<br/>Chicago, IL 60673-5363<br/><br/>Delivery via Overnight Courier Service:<br/>Probo Medical LLC<br/>JPMorgan Chase<br/>Attn: Probo Medical LLC 735363 131 S<br/>Dearborn, 6th Floor<br/>Chicago, IL 60603';
            wiringACHFundsBank = 'Bank Routing Number: 074000010<br/>Account Number: 900070019<br/>Account Name: Probo Medical LLC<br/><br/>Wire Transfers:<br/>Bank Routing Number: 021000021<br/>SWIFT Code: CHASUS33<br/><br/>Account #: 900070019<br/>JPMorgan Chase New York, NY 10017';
            overnightedChecks = 'Probo Medical, LLC<br/>JPMorgan Chase<br/>Attn: Probo Medical LLC 735363 131 S<br/>Dearborn, 6th Floor<br/>Chicago, IL 60603';
            Invoice__c con = [ Select Id, Name, CurrencyIsoCode, Opportunity__c, Account__c, Total_Storage_Days__c, Storage_Unit_Price__c, Entity_Location__c from Invoice__c where Id =: std.getRecord().Id ];
            if(con.Account__c != '001U000000pNlw4IAC' && con.CurrencyIsoCode == 'CAD'){
                isGSTHST = true;
            }
            if(con.Entity_Location__c.contains('1700')){
                isCanada = true;
                isUSA = false;
                entityName = 'PROBO MEDICAL, INC.';
                addressLine1 = '1193 North Service Rd W Unit C2,';
                addressLine2 = 'Oakville, ON, L6M 2V8';
                displayCurrency = 'CA$';
                wiringACHFundsBank = 'Beneficiary Account Name: Probo Medical, Inc.<br/> Beneficiary Account Number: 4011771964<br/>Beneficiary Address: SUITE 2500, 666 BURRARD STREET, VANCOUVER, BC, V6C 2X8, CA<br/><br/>Beneficiary Bank Name: JPMORGAN CHASE BANK, N.A. - TORONTO BRANCH<br/>Beneficiary Bank Swift BIC: CHASCATTCTS<br/>Canadian Clearing Code: 027000012<br/>Intermediary Bank Name: ROYAL BANK OF CANADA TORONTO<br/>Intermediary Bank Swift BIC: ROYCCAT2<br/>';
            }
            String myGeneratedFileName = con.Name+'.pdf';
            Apexpages.currentPage().getHeaders().put('content-disposition', 'inline; filename='+myGeneratedFilename); 
            
            List<OpportunityLineItem> lineItems = [ Select Id,Name,Serial_No__c,RMA__r.RMA_Item_Serial_Number__c,Quantity,TotalPrice,Product2Id,Product_Name__c,Product_Description__c,UnitPrice, Product_Family__c from OpportunityLineItem where Opportunityid =: con.Opportunity__c AND Invoice2__c =: con.id];
            SortedLineItems = new List<OpportunityLineItem>();
            OpportunityLineItem shippingline = new OpportunityLineItem();
            OpportunityLineItem GSTHSTline = new OpportunityLineItem();
            for(OpportunityLineItem lineItem : lineItems){
                if(lineItem.product2Id != '01tU0000002WUUbIAO' && !lineItem.Name.contains('GST/HST')){
                    if(lineItem.Product_Family__c.contains('Storage') && lineItem.Name.contains('Storage Bay')){
                        if(con.Total_Storage_Days__c != null){
                            lineItem.Quantity = con.Total_Storage_Days__c;
                            if(con.Storage_Unit_Price__c != null){
                                lineItem.TotalPrice = con.Total_Storage_Days__c * con.Storage_Unit_Price__c;
                            }
                            
                        }
                        
                    }
                    SortedLineItems.add(lineItem);
                    
                }
                else{
                    if(lineItem.product2Id == '01tU0000002WUUbIAO'){
                        shippingline = lineItem;
                        
                    }
                    if(lineItem.Name.contains('GST/HST')){
                        GSTHSTline = lineItem;
                        
                    }   
                }
            }
            if(shippingline.Id != NULL){
                SortedLineItems.add(shippingline);
            }
            if(GSTHSTline.Id != NULL){
                SortedLineItems.add(GSTHSTline);
            }
                                    
        }
        else
        {
            SortedLineItems = new List<OpportunityLineItem>();
        }
    }         
}