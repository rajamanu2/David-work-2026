global class CreateRepairRMAFromCase {
    
    public Case customerCaseId { get; set; }
    public Case customerCase { get; set; }
    
    public String customerName { get; set; }
    public String caseNo { get; set; }
    public String customerStreet { get; set; }
    public String customerCity { get; set; }
    public String customerState { get; set; }
    public String customerPostalCode { get; set; }
    public String customerCountry { get; set; }
    public String customerPhone { get; set; }
    public String customerEmail { get; set; }
    public String customerProbeType { get; set; }
    public String customerProbeManufacturer { get; set; }
    public String customerProbeModel { get; set; }
    public String customerFullProbeModel { get; set; }
    public String customerProbeSerial { get; set; }
    public Id customerAccountId { get; set; }
    public String customerAccountName { get; set; }
    public Decimal customerQuote { get; set; }
    public Boolean customerLoaner { get; set; }
    public Date customerQuoteDate { get; set; }
    public String customerQuoteNumber { get; set; }
    public String couponCode { get; set; }
    public String formGCLID { get; set; }
    public String accountOwner { get; set; }
    public String accountFSE { get; set; }
    public String ProboName { get; set; }
    public String ProboAddress1 { get; set; }
    public String ProboAddress2 { get; set; }
    public String ProboWebsite { get; set; }
    public String ProboPhone { get; set; }
    public String customerCurrency { get; set; }
    public String updateOwner { get; set; }

    
    
    public CreateRepairRMAFromCase(ApexPages.StandardController controller) {
        
        customerCaseId = (Case)controller.getRecord();
        system.debug('THIS IS THE CUSTOMER CASE >>> ' + customerCaseId);
        
        caseNo = customerCaseId.Id;
        system.debug(CaseNo);
        if(CaseNo != NULL){
        customerCase = [select Id, Repair_Eval_Contact_Email__c, Repair_Eval_Contact_Phone__c, Repair_Eval_Contact_First_Name__c, 
                        Repair_Eval_Contact_Last_Name__c, Repair_Eval_Contact_Street__c, Repair_Eval_Contact_City__c, 
                        Repair_Eval_Contact_State__c, Repair_Eval_Contact_Postal_Code__c, Repair_Eval_Probe_Type__c, 
                       Repair_Eval_Probe_Manufacturer__c, Repair_Eval_Probe_Model_Acuson__c, Repair_Eval_Probe_Model_GE__c,
                       Repair_Eval_Probe_Model_Philips__c, Repair_Eval_Probe_Model_Siemens__c, Repair_Eval_Probe_Model_SonoSite__c,
                        Repair_Eval_Probe_Model_Toshiba__c, Repair_Eval_Probe_Model_Zonare__c, AccountId, Account_Name__c,
                        Repair_Eval_Probe_Model__c, Repair_Eval_Quote__c, CreatedDate, CaseNumber, Repair_Eval_Coupon_Code__c, 
                        Repair_Eval_GCLID__c, Account_Owner_ID__c, Account_FSE__c, Repair_Eval_Contact_Country__c
                        from Case where Id=:CaseNo limit 1];
            if(customerCase.Repair_Eval_Contact_Country__c == null || customerCase.Repair_Eval_Contact_Country__c == 'United States'){
                customerCountry = 'United States';
                customerCurrency = 'USD';
                ProboName = 'Probo Medical, LLC';
                updateOwner = '005U00000045xUy';
            }
            else {
                customerCountry = customerCase.Repair_Eval_Contact_Country__c;
                updateOwner = '005U0000004H1ag';
                ProboName = 'Probo Medical, LTD';
                if(customerCountry == 'United Kingdom'){
                    customerCurrency = 'GBP';
                }
                else {
                    customerCurrency = 'EUR';
                }
            }
        
        accountOwner = customerCase.Account_Owner_ID__c;
        accountFSE = customerCase.Account_FSE__c;
        formGCLID = customerCase.Repair_Eval_GCLID__c;
        couponCode = customerCase.Repair_Eval_Coupon_Code__c;
        customerQuoteNumber = 'Q-' + customerCase.CaseNumber;
        customerQuote = customerCase.Repair_Eval_Quote__c;
        customerQuoteDate = date.newinstance(customerCase.CreatedDate.year(), customerCase.CreatedDate.month(), customerCase.CreatedDate.day());
        customerEmail = customerCase.Repair_Eval_Contact_Email__c;
        customerPhone = customerCase.Repair_Eval_Contact_Phone__c;
        customerName = customerCase.Repair_Eval_Contact_First_Name__c + ' ' + customerCase.Repair_Eval_Contact_Last_Name__c;
        customerStreet = customerCase.Repair_Eval_Contact_Street__c;
        customerCity = customerCase.Repair_Eval_Contact_City__c;
        customerState = customerCase.Repair_Eval_Contact_State__c;
        customerPostalCode = customerCase.Repair_Eval_Contact_Postal_Code__c;
        customerAccountId = customerCase.AccountId;
        customerAccountName = customerCase.Account_Name__c;
        ProboAddress1 = '9715 Kincaid Dr Suite 1000';
        ProboAddress2 = 'Fishers, IN 46037';
        ProboWebsite = 'www.probomedical.com';
        ProboPhone = '1.866.513.8322';
        
         if(customerCountry == 'United Kingdom'){
                ProboAddress1 = 'Mount Court, Edison Close, Waterwells Business Park';
                ProboAddress2 = 'Gloucester, Gloucestershire GL2 2FN';
                ProboWebsite = 'www.probomedical.co.uk';
                ProboPhone = '01452 729380';
            }
        if(customerCase.Repair_Eval_Probe_Type__c != null){
            customerProbeType = customerCase.Repair_Eval_Probe_Type__c;
            if (customerCase.Repair_Eval_Probe_Manufacturer__c != null) {
                customerProbeManufacturer = customerCase.Repair_Eval_Probe_Manufacturer__c;
                customerFullProbeModel = customerCase.Repair_Eval_Probe_Manufacturer__c;
            }
            
            if (customerCase.Repair_Eval_Probe_Model_Acuson__c != null) {
                customerProbeModel = customerCase.Repair_Eval_Probe_Model_Acuson__c;
                customerFullProbeModel += ' ' + customerCase.Repair_Eval_Probe_Model_Acuson__c;
            }
            else if (customerCase.Repair_Eval_Probe_Model_GE__c != null) {
                customerProbeModel = customerCase.Repair_Eval_Probe_Model_GE__c;
                customerFullProbeModel += ' ' + customerCase.Repair_Eval_Probe_Model_GE__c;
            }
            else if (customerCase.Repair_Eval_Probe_Model_Philips__c != null) {
                customerProbeModel = customerCase.Repair_Eval_Probe_Model_Philips__c;
                customerFullProbeModel += ' ' + customerCase.Repair_Eval_Probe_Model_Philips__c;
            }
            else if (customerCase.Repair_Eval_Probe_Model_Siemens__c != null) {
                customerProbeModel = customerCase.Repair_Eval_Probe_Model_Siemens__c;
                customerFullProbeModel += ' ' + customerCase.Repair_Eval_Probe_Model_Siemens__c;
            }
            else if (customerCase.Repair_Eval_Probe_Model_SonoSite__c != null) {
                customerProbeModel = customerCase.Repair_Eval_Probe_Model_SonoSite__c;
                customerFullProbeModel += ' ' + customerCase.Repair_Eval_Probe_Model_SonoSite__c;
            }
            else if (customerCase.Repair_Eval_Probe_Model_Toshiba__c != null) {
                customerProbeModel = customerCase.Repair_Eval_Probe_Model_Toshiba__c;
                customerFullProbeModel += ' ' + customerCase.Repair_Eval_Probe_Model_Toshiba__c;
            }
            else if (customerCase.Repair_Eval_Probe_Model_Zonare__c != null) {
                customerProbeModel = customerCase.Repair_Eval_Probe_Model_Zonare__c;
                customerFullProbeModel += ' ' + customerCase.Repair_Eval_Probe_Model_Zonare__c;
            }
            
			system.debug('THIS IS FULL PROBE MODEL 1 >> ' + customerFullProbeModel);            
        }
            
    }
        
        
        
    }
    
    public PageReference SaveCustomerSubmission() {
        
        
        if(accountOwner != null){
            updateOwner = accountOwner;
        }
        
        Opportunity customerOpp = new Opportunity(AccountId = customerAccountId, RecordTypeId = '0124O000000tE2oQAE', 
                                                 StageName = 'Repair Evaluation', CloseDate = Date.Today(), 
                                                 Name = 'Repair Evaluation Tool - ' + customerFullProbeModel + ' - ' + customerAccountName, 
                                                 CurrencyIsoCode = customerCurrency, LeadSource = 'Web Lead - Form Submission', OwnerId = updateOwner,
                                                 Sales_Lead_Source__c = 'Marketing', Lead_Source_Detail__c = 'Customer Repair Evaluation Tool',
                                                 GCLID__c = formGCLID, Coupon_Code__c = couponCode, Field_Service_Engineer__c = accountFSE
                                                 );
        
        insert customerOpp;
        
        
        customerCase.Repair_Eval_Contact_Street__c = customerStreet;
        customerCase.Repair_Eval_Contact_City__c = customerCity;
        customerCase.Repair_Eval_Contact_State__c = customerState;
        customerCase.Repair_Eval_Contact_Postal_Code__c = customerPostalCode;
        customerCase.Repair_Eval_Probe_Serial_No__c = customerProbeSerial; 
        customerCase.Repair_Eval_Contact_Country__c = customerCountry;
        customerCase.CurrencyIsoCode = customerCurrency;
        if(customerFullProbeModel != null && customerCase.Repair_Eval_Probe_Model__c == null){
            customerCase.Repair_Eval_Probe_Model__c = customerFullProbeModel;
        }
        customerCase.Opportunity__c = customerOpp.Id;
        customerCase.OwnerID = updateOwner;
        if(customerLoaner != null){
            customerCase.Loaner_Requested__c = customerLoaner;
        }
        
            
        system.debug('THIS IS PROBE MODEL >> ' + customerProbeModel);
        system.debug('THIS IS FULL PROBE MODEL 2 >> ' + customerFullProbeModel);
        
        update customerCase;
        
        RMA__c customerRMA = [select Id, Opportunity__c from RMA__c where Opportunity__c =: customerOpp.Id limit 1];
        if(customerRMA.id != null){
            customerRMA.RMA_Item_Serial_Number__c = customerProbeSerial;
            customerRMA.Customer_Probe_Type__c = customerProbeType;
            customerRMA.Customer_Company_Name__c = customerAccountName; 
            customerRMA.Contact_Name__c = customerName;
            customerRMA.Customer_Email__c = customerEmail;
            customerRMA.Customer_Phone__c = customerPhone;
            customerRMA.Customer_Return_Street__c = customerStreet;
            customerRMA.Customer_Return_City__c = customerCity;
            customerRMA.Customer_Return_State__c = customerState;
            customerRMA.Customer_Return_Postal_Code__c = customerPostalCode;
            customerRMA.Customer_Return_Country__c = customerCountry;
            customerRMA.Quality_Issue_Notes__c = 'Customer Repair Evaluation Tool - ' + customerFullProbeModel;
            //customerRMA.Notify_Rep_to_Create_Label__c = true;
            customerRMA.Create_Shipment__c = true;
        
        	update customerRMA;
            
            id tmpVar1 = UserInfo.getUserId();
            
            User newUser = [SELECT FirstName, LastName, Phone, Email, zkmulti__Registered_Preference__c FROM User WHERE Id = :tmpVar1 LIMIT 1];
            
            system.debug('THIS IS THE NEWUSER >> ' + newUser);
        }
        
        
        
        
        
        return new PageReference('/apex/RepairEvaluationToolApproval');
    }

}