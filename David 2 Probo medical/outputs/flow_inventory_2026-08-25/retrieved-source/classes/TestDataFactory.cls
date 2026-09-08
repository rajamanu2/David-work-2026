//@isTest
public class TestDataFactory {

    public static String testUser() {
        return 'Adam Walter';
    }

    // these methods can be called from test classes or from anonymous Apex to populate records in the org

    // create a single Account with an option to save the new record
    // input param 1 - Boolean, true = insert new Account record
    // returns the new Account record
    public static Account createAccount(Boolean insertFlag) {
        Account thisAccount = new  Account();
        thisAccount.Name = 'testAccount';
        thisAccount.Payment_Term__c = 'Net 15';
        thisAccount.Accounting_Contact_E_mail__c = 'awalter@probomedical.com';
        thisAccount.RGBP_Category__c = 'House';
        //Added BY bugendaitech: when we create account the approval status by default selects New
        //so approval process starts and in test class update account fails because record will be locked once submited for approval
        thisAccount.Approval_Status__c = 'Approved';        
        if (insertFlag) {
            try {
                insert thisAccount;
            } catch (exception e) {
                return null;
            }
        }
        return thisAccount;
    }

    // create multiple Accounts with an option to save the new records
    // input param 1 - Integer, number of Accounts to create
    // input param 2 - Boolean, true = insert new Account records
    // returns a list of the new Account records
    public static List<Account> createAccounts(Integer numOfAccounts, Boolean insertFlag) {
        List<Account> accts = new List<Account>();
        if (numOfAccounts > 0) {
            for (Integer i = 0; i < numOfAccounts; i++) {
                Account a = new Account(Name='Test Account' + i, RGBP_Category__c = 'House', Payment_Term__c = 'Net 15', Approval_Status__c = 'Approved', Accounting_Contact_E_mail__c = 'awalter@probomedical.com');
                accts.add(a);
            }
            if (insertFlag) {
                try {
                    insert accts;
                } catch (exception e) {
                    return null;
                }
            }
        }
        return accts;
    }

    // create multiple accounts with associated contacts
    // input param 1 - Integer, number of Accounts to create
    // input param 2 - Integer, number of Contacts to create for each Account
    // returns a list of the new Account records
    public static List<Account> createAccountsWithContacts(Integer numOfAccounts, Integer numOfContacts) {
        List<Account> accts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        if (numOfAccounts > 0) {
            // create new Account records and insert them now
            for (Integer i = 0; i < numOfAccounts; i++) {
                Account a = new Account(Name='Test Account' + i, RGBP_Category__c = 'House', Payment_Term__c = 'Net 15', Approval_Status__c = 'Approved', Accounting_Contact_E_mail__c = 'awalter@probomedical.com');
                accts.add(a);
            }
            insert accts;

            // create new Contact records for new Account records
            for (Account a :accts) {
                for (Integer i = 0; i < numOfContacts; i++) {
                    Contact c = new Contact(FirstName = 'First' + i, LastName = 'Last' + i, AccountId = a.Id);
                    contacts.add(c);
                }
            }
            insert contacts;
        }
        return accts;
    }

    // create User record with an option to save the new record
    // input param 1 - String, First Name of User
    // input param 2 - String, Last Name of User
    // input param 3 - Boolean, true = insert new User record
    // returns the new User record
    public static User createUser(String fName, String lName, Boolean insertFlag) {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        Id profileId = UserInfo.getProfileId();

        User thisUser = new User();
        thisUser.firstname = fName;
        thisUser.lastName = lName;
        thisUser.email = uniqueName + '@test' + orgId + '.org';
        thisUser.Username = uniqueName + '@test' + orgId + '.org';
        thisUser.EmailEncodingKey = 'ISO-8859-1';
        thisUser.Alias = uniqueName.substring(18, 23);
        thisUser.TimeZoneSidKey = 'America/Los_Angeles';
        thisUser.LocaleSidKey = 'en_US';
        thisUser.LanguageLocaleKey = 'en_US';
        thisUser.ProfileId = profileId;
        thisUser.IsActive = true;
        if (insertFlag) {
            try {
                insert thisUser;
            } catch (exception e) {
                return null;
            }
        }
        return thisUser ;
    }

    // create Opportunity record with an option to save the new record
    // input param 1 - String, Record Type Name for the Opportunity
    // input param 2 - Id, Account Id (if null, create new Account)
    // input param 3 - Boolean, true = insert new Opportunity record
    // returns the new Opportunity record
    public static Opportunity createOpportunity(String recordTypeName, Id accountId, Boolean insertFlag) {
        List<Opportunity> oppList = buildOpportunities(1, recordTypeName, accountId, insertFlag);
        if (oppList == null)
            return null;
        return oppList[0];
    }

    public static OpportunityContactRole createOpportunityContactRole(Id opportunityId, Id contactId, boolean isPrimary, string role, boolean insertFlag) {
        OpportunityContactRole oppRole = new OpportunityContactRole();
        oppRole.isPrimary = isPrimary;
        oppRole.Role = role;
        oppRole.ContactId = contactId;
        oppRole.OpportunityId = opportunityId;
        if(insertFlag) {
            insert oppRole;
        }
        return oppRole;
    }

    // create a list of Opportunity records with an option to save the new records
    // input param 1 - Integer, number of records to create
    // input param 2 - String, Record Type Name for the Opportunity
    // input param 3 - Id, Account Id (if null, create new Account)
    // input param 4 - Boolean, true = insert new Opportunity records
    // returns a list of the new Opportunity records
    public static List<Opportunity> createOpportunities(Integer count, String recordTypeName, Id accountId, Boolean insertFlag) {
        List<Opportunity> oppList = buildOpportunities(count, recordTypeName, accountId, insertFlag);
        return oppList;
    }

    // build Opportunities helper routine
    private static List<Opportunity> buildOpportunities(Integer count, String recordTypeName, Id accountId, Boolean insertFlag) {
        Id rtId, pbId;
        List<Opportunity> oppList = new List<Opportunity>();

        try {
            rtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        } catch (exception e) {
            return null;
        }

        // if called from a test class, use the test pricebook, otherwise use the standard pricebook for the org
        pbId = ProboCommonUtils.getStdPricebookId();

        if (accountId == null)
            accountId = createAccount(true).Id;

        for (Integer i = 0; i < count; i++) {
            Opportunity opp = new Opportunity();
            opp.RecordTypeId = rtId;
            opp.Pricebook2Id = pbId;
            opp.AccountId = accountId;
            opp.Name = 'Test Opportunity' + i;
            opp.StageName = 'Prospecting';
            opp.CloseDate = system.today() + 21;
            opp.Amount = 50;
            opp.TotalOpportunityQuantity = 7;
            opp.Shipping_FROM_Location__c = 'Fishers, IN';
            opp.LeadSource = 'Other';
            opp.BillingStreet__c = '1234 Main';
            opp.BillingCity__c = 'Denver';
            opp.BillingState__c = 'CO';
            opp.BillingPostalCode__c = '12345';
            opp.BillingCountry__c = 'US';
            opp.ShippingStreet__c = '1234 Main';
            opp.ShippingCity__c = 'Denver';
            opp.ShippingState__c = 'CO';
            opp.ShippingPostalCode__c = '12345';
            opp.ShippingCountry__c = 'US';
            // field below required for some record types
            opp.Shipping_Cost__c = 20;
            opp.Warranty_Length__c = 'AS-IS';
            opp.CurrencyIsoCode = 'USD';
            oppList.add(opp);
        }

        if (insertFlag) {
            try {
                insert oppList;
            } catch (exception e) {
                return null;
            }
        }
        return oppList;
    }

    // create a single Product with an option to save the new record
    // input param 1 - String, Record Type Name for this Product
    // input param 2 - Boolean, true = insert new Product record
    // returns the new Product record
    public static Product2 createProduct(String recordTypeName, String prodName, String prodFamily, Boolean insertFlag) {
        Id rtId;

        try {
            rtId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        } catch (Exception e) {
            GH_Logger.debug('createProduct unable to find Product2 Record Type named: ' + recordTypeName);
            return null;
        }

        Product2 thisProduct = new Product2 ();
        thisProduct.RecordTypeId = rtId;
        thisProduct.Name = prodName == null ? 'Test Product' : prodName;
        thisProduct.Model__c = prodName == null ? 'Test Product' : prodName;
        thisProduct.Description = 'Test Product';
        thisProduct.productCode = 'TP';
        thisProduct.isActive = true;
        thisProduct.Family = recordTypeName;
        thisProduct.Always_Save_for_parts__c = true; // true for both Purchase and Customer Repair
        // required fields below
        thisProduct.OEM__c = 'GE_Healthcare';
        thisProduct.Part_Type__c = 'Assembly';
        thisProduct.Modality__c = 'Ultrasound';
        thisProduct.CurrencyIsoCode = 'USD';

        if (insertFlag) {
            try {
                insert thisProduct;
            } catch (Exception e) {
                GH_Logger.debug('createProduct unable to insert Product2: ' + e.getMessage());
                return null;
            }
        }
        return thisProduct;
    }

    public static Product2 createProduct(String recordTypeName, Boolean insertFlag) {
        return createProduct(recordTypeName, null, null, insertFlag);
    }

    // create multiple Products with an option to save the new records
    // input param 1 - String, Record Type Name for these Products
    // input param 2 - Integer, number of Products to create
    // input param 3 - Boolean, true = insert new Product records
    // returns a list of the new Product records
    public static List<Product2> createProducts(Integer numOfProducts, String recordTypeName, Boolean insertFlag) {
        Id rtId;
        List<Product2> prods = new List<Product2>();
        List<Product_Analytics__c> prodAnalytics = new List<Product_Analytics__c>();
        if(recordTypeName == null){ recordTypeName = 'Ultrasound Probe';}
        try {
            rtId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        } catch (exception e) {
            return null;
        }
		
        
        if (numOfProducts > 0) {
            for (Integer i = 0; i < numOfProducts; i++) {
                Product2 thisProduct = new Product2();
                thisProduct.RecordTypeId = rtId  ;
                thisProduct.Name = 'Test Product' + i;
                thisProduct.Model__c = 'Test Product' + i;
                thisProduct.Description = 'Test Product' + i;
                thisProduct.productCode = 'TP' + i;
                thisProduct.Probe_Type__c = 'Phased Array';
                thisProduct.Family = recordTypeName;
                thisProduct.Always_Save_for_parts__c = true; // true for both Purchase and Customer Repair
                thisProduct.isActive = true;
                // required fields below
            thisProduct.OEM__c = 'GE_Healthcare';
            thisProduct.Part_Type__c = 'Assembly';
            thisProduct.Modality__c = 'Ultrasound';
            thisProduct.CurrencyIsoCode = 'USD';
                prods.add(thisProduct);
            }

            if (insertFlag) {
                try {
                    insert prods;
                } catch (exception e) {
                    return null;
                }
            }
        }
        Map<String,Id> prodMap = new Map<String,Id> ();
        List<Product2> prodList = [SELECT Id, Name FROM Product2];
        for (Product2 prod2: prodList){
            prodMap.put(prod2.Name, prod2.Id);
        }
        // must insert product analytics object as well
		if (numOfProducts > 0) {
            for (Integer i = 0; i < numOfProducts; i++) {
                Product_Analytics__c thisProductAnalytics = new Product_Analytics__c();
                thisProductAnalytics.Name = 'Test Product' + i;
                thisProductAnalytics.CurrencyIsoCode = 'USD';
                thisProductAnalytics.Product__c = prodMap.get('Test Product' + i);
                
                prodAnalytics.add(thisProductAnalytics);
            }

            if (insertFlag) {
                try {
                    insert prodAnalytics;
                } catch (exception e) {
                    return null;
                }
            }
        }
        return prods;
    }

    // create a single ProductItem__c (Asset2) record with an option to save the new record
    // input param 1 - String, Product Id (if null, create new Product)
    // input param 2 - Boolean, true = insert new ProductItem__c record
    // returns the new ProductItem__c record
    public static ProductItem__c createProductItem(Id productId, Boolean insertFlag) {
        List<ProductItem__c> pi = buildProductItems(1, productId, insertFlag);
        if (pi == null) {
            return null;
        }
        return pi[0];
    }

    // create a List of ProductItem__c (Asset2) records with an option to save the new records
    // input param 1 - Integer, number of records to create
    // input param 2 - String, Product Id (if null, create new Product)
    // input param 3 - Boolean, true = insert new ProductItem__c records
    // returns the list of new ProductItem__c records
    public static List<ProductItem__c> createProductItems(Integer count, Id productId, Boolean insertFlag) {
        List<ProductItem__c> pi = buildProductItems(count, productId, insertFlag);
        return pi;
    }

    // build ProductItems helper routine
    private static List<ProductItem__c> buildProductItems(Integer count, Id productId, Boolean insertFlag) {
        List<ProductItem__c> results = new List<ProductItem__c>();
        if (productId == null) {
            productId = createProduct('Non Inventory Item', true).Id;
        }
		List<Product_Analytics__c> prodAnalyticList = [SELECT Id, Name, Product__c FROM Product_Analytics__c WHERE Product__c =:productId LIMIT 1];
        Product_Analytics__c prodAnalytic;
        if(prodAnalyticList.size() == 0){
            Product_Analytics__c thisProductAnalytics = new Product_Analytics__c(Name = 'Test', Product__c = productId, CurrencyIsoCode = 'USD');
            insert thisProductAnalytics;
            prodAnalytic = [SELECT Id, Name, Product__c FROM Product_Analytics__c WHERE Product__c =: productId];
        }
        else{
            prodAnalytic = prodAnalyticList[0];
        }
        
        // set some reasonable defaults for most of the fields
        for (Integer i = 0; i < count; i++) {
            ProductItem__c pi = new ProductItem__c();
            pi.Product_Analytics__c = prodAnalytic.Id;
            pi.Product_Name__c = productId;
            //TODO: add a parameter for Check in Type
            pi.Check_In_Type__c = 'Customer Repair'; // change to 'Customer Repair' sometimes
            pi.Serial_No__c = '12345' + i;
            pi.Receive_date__c = system.today() - 3;
            pi.Cost__c = 111.00;
            pi.Location__c = 'Cage';
            pi.Generic_Product__c = false; //should always be false except on purchasing
            pi.Purchasing_Approved__c = true; // should always be approved for testing
            //pi.sold__c = true;
            pi.Possible_Cosmetic_Repairs__c='Array/Cable Assembly Replacement'; // added by dipika
            pi.Possible_Functional_Repairs__c ='Probe Handle Replacement';//added by dipika
            pi.Added_to_Work_Order__c = false;
            
            pi.Added_To_Opportunity__c = false;
            results.add(pi);
        }

        if (insertFlag) {
            try {
                insert results;
            } catch (exception e) {
                GH_Logger.debug('buildProductItems unable to insert ProductItem__c: ' + e.getMessage());
                return null;
            }
        }
        return results;
    }

    // create a single PriceBookEntry record with an option to save the new record
    // input param 1 - String, Product Id (if null, create new Product)
    // input param 2 - Boolean, true = insert new PriceBookEntry record
    // returns the new PriceBookEntry record
    public static PricebookEntry createPricebookEntry(Id productId, Boolean insertFlag) {

        // see if the PBE already exists in the standard PriceBook -- if not, create it
        PricebookEntry pbeToReturn = getPriceBookEntry(productId, ProboCommonUtils.getStdPricebookId());

        if (pbeToReturn == null){
            List<PricebookEntry> listPBE = buildPricebookEntries(1, productId, insertFlag);
            if (listPBE != null) {
                pbeToReturn = listPBE[0];
            }
        }
        return pbeToReturn;
    }

    // returns the PriceBookEntry if it exists
    public static PricebookEntry getPriceBookEntry(Id theProdId, Id thePriceBook2Id){

        try{
            return [SELECT Id FROM PricebookEntry
                    WHERE IsActive = TRUE
                    AND Product2Id = :theProdId
                    AND Pricebook2Id = :thePriceBook2Id
                    LIMIT 1];
        } catch (Exception e){
            GH_Logger.debug('getPriceBookEntry did not find a matching PBE');
            return null;
        }
    }

    // create a List of PriceBookEntry records with an option to save the new records
    // input param 1 - Integer, number of records to create
    // input param 1 - String, Product Id (if null, create new Product)
    // input param 2 - Boolean, true = insert new PriceBookEntry records
    // returns the new PriceBookEntry records
    public static List<PricebookEntry> createPricebookEntries(Integer count, Id productId, Boolean insertFlag) {
        List<PricebookEntry> listPBE = buildPricebookEntries(count, productId, insertFlag);
        return listPBE;
    }

    // build PriceBookEntry helper routine
    private static List<PricebookEntry> buildPricebookEntries(Integer count, Id productId, Boolean insertFlag) {
        Id pbId;
        List<PricebookEntry> listPBE = new List<PricebookEntry>();

        // if called from a test class, use the test pricebook, otherwise use the standard pricebook for the org
        pbId = ProboCommonUtils.getStdPricebookId();

        // TODO - create one new product for each pricebookentry?
        if (productId == null) {
            productId = createProduct('Non Inventory Item', true).Id;
        }

        for (Integer i = 0; i < count; i++) {
            PricebookEntry thisPBE = new PricebookEntry();
            thisPBE.Product2Id = productId;
            thisPBE.Pricebook2ID = pbId;
            thisPBE.UnitPrice = 111.00;
            thisPBE.isActive = true;
            thisPBE.CurrencyIsoCode = 'USD';
            listPBE.add(thisPBE);
        }

        if (insertFlag) {
            try {
                insert listPBE;
            } catch (exception e) {
                GH_Logger.debug('buildPricebookEntries cannot insert PriceBookEntries: ' + e.getMessage());
                return null;
            }
        }
        return listPBE;
    }

    // create a single OpportunityLineItem record with an option to save the new record
    // input param 1 - String, Opportunity Id
    // input param 2 - String, PriceBookEntry Id
    // input param 3 - String, Product Id (if null, create new Product)
    // input param 4 - Boolean, true = insert new OpportunityLineItem record
    // returns the new OpportunityLineItem record
    public static OpportunityLineItem createOpportunityLineItem(Id opportunityId, Id priceBookEntryId, Id productItemId, Boolean insertFlag) {
        List<OpportunityLineItem> listOLI = buildOpportunityLineItems(1, opportunityId, priceBookEntryId, productItemId, insertFlag);
        if (listOLI == null) {
            return null;
        }
        return listOLI[0];
    }

    // create a list of OpportunityLineItem records with an option to save the new records
    // input param 1 - Integer, number of records to create
    // input param 2 - String, Opportunity Id
    // input param 3 - String, PriceBookEntry Id
    // input param 4 - String, Product Id (if null, create new Product)
    // input param 5 - Boolean, true = insert new OpportunityLineItem records
    // returns the new OpportunityLineItem records
    public static List<OpportunityLineItem> createOpportunityLineItems(Integer count, Id opportunityId, Id priceBookEntryId, Id productItemId, Boolean insertFlag) {
        List<OpportunityLineItem> listOLI = buildOpportunityLineItems(count, opportunityId, priceBookEntryId, productItemId, insertFlag);
        return listOLI;
    }

    // build OpportunityLineItem helper routine
    private static List<OpportunityLineItem> buildOpportunityLineItems(Integer count, Id opportunityId, Id priceBookEntryId, Id productItemId, Boolean insertFlag) {
        List<OpportunityLineItem> listOLI = new List<OpportunityLineItem>();

        for (Integer i = 0; i < count; i++) {
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.OpportunityId = opportunityId;
            if (productItemId != null) {
                oli.ProductItem__c = productItemId;
            } else {
                oli.ProductItem__c = createProductItem(null, true).Id;
            }
            oli.PricebookEntryId = priceBookEntryId;
            oli.Quantity = 1;
            oli.TotalPrice = 111.00;
            listOLI.add(oli);
        }

        if (insertFlag) {
            try {
                insert listOLI;
            } catch (exception e) {
                return null;
            }
        }
        return listOLI;
    }

    // create a single RMA__c record with an option to save the new record
    // input param 1 - String, Record Type Name for this RMA__c record
    // input param 2 - Boolean, true = insert new RMA__c record
    // returns the new RMA__c record
    public static RMA__c createRMA(String recordTypeName, Boolean insertFlag) {
        List<RMA__c> listRMA = buildRMAs(1, recordTypeName, insertFlag);
        if (listRMA == null) {
            return null;
        }
        return listRMA[0];
    }

    // create a list of RMA__c records with an option to save the new records
    // input param 1 - Integer, number of records to create
    // input param 2 - String, Record Type Name for this RMA__c records
    // input param 3 - Boolean, true = insert new RMA__c records
    // returns the new RMA__c records
    public static List<RMA__c> createRMAs(Integer count, String recordTypeName, Boolean insertFlag) {
        List<RMA__c> listRMA = buildRMAs(count, recordTypeName, insertFlag);
        return listRMA;
    }

    // build RMA__c helper routine
    private static List<RMA__c> buildRMAs(Integer count, String recordTypeName, Boolean insertFlag) {
        Id rtId;
        List<RMA__c> listRMA = new List<RMA__c>();

        try {
            rtId = Schema.SObjectType.RMA__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        } catch (exception e) {
            system.debug('buildRMAs: Unable to get record type name: ' + recordTypeName);
            return null;
        }

        for (Integer i = 0; i < count; i++) {
            RMA__c thisRMA = new RMA__c();
            thisRMA.RecordTypeId = rtId;
            thisRMA.Approved_Repairs__c = 'All Repairs Approved';
            thisRMA.Declined_Repairs__c = '';
            thisRMA.Quality_Issue_Notes__c = 'TEST';
            thisRMA.Customer_Email__c = 'Test@Test.com';
            thisRMA.OwnerId = UserInfo.getUserId();
            
          
            // TODO - use custom metadata for RecordType/Picklist checking/verification? how to avoid this?
            if (recordTypeName == 'RFS/Warranty Claim' || recordTypeName == 'Warranty Claim') {
                thisRMA.Customer_Expectation__c = 'Customer wants Equipment Back';
                thisRMA.Quality_Issue_Notes__c = 'RMA Notes';
            }
            listRMA.add(thisRMA);
        }

        if (insertFlag) {
            try {
                insert listRMA;
            } catch (exception e) {
                return null;
            }
        }
        return listRMA;
    }

    // create a single Work_Order__c record with an option to save the new record
    // input param 1 - String, Record Type Name for this RMA__c records
    // input param 3 - Product Item Id
    // input param 3 - Boolean, true = insert new Work_Order__c record
    // returns the new Work_Order__c record
    public static Work_Order__c createWorkOrder(String recordTypeName, Id productItemId, Boolean insertFlag) {
        List<Work_Order__c> listWO = buildWorkOrders(1, recordTypeName, productItemId, insertFlag);
        if (listWO == null) {
            return null;
        }
        return listWO[0];
    }

    // create a list of Work_Order__c records with an option to save the new records
    // input param 1 - Integer, number of records to create
    // input param 2 - String, Record Type Name for this RMA__c records
    // input param 3 - Product Item Id
    // input param 4 - Boolean, true = insert new Work_Order__c record
    // returns the new Work_Order__c record
    public static List<Work_Order__c> createWorkOrders(Integer count, String recordTypeName, Id productItemId, Boolean insertFlag) {
        List<Work_Order__c> listWO = buildWorkOrders(count, recordTypeName, productItemId, insertFlag);
        return listWO;
    }

    // build Work_Order__c helper routine
    private static List<Work_Order__c> buildWorkOrders(Integer count, String recordTypeName, Id productItemId, Boolean insertFlag) {
        Id rtId;
        List<Work_Order__c> listWO = new List<Work_Order__c>();

        try {
            rtId = Schema.SObjectType.Work_Order__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        } catch (exception e) {
            return null;
        }

        for (Integer i = 0; i < count; i++) {
            Work_Order__c wo = new Work_Order__c();
            wo.RecordTypeId = rtId;
            wo.Asset__c = productItemId;
            wo.Work_Order_Repairs__c = 'Cable Replacement';
            wo.Person_Requesting_WO__c = 'David Trogden';
            wo.Estimated_Ready_Date__c = system.today() + 21;
            wo.Status__c = 'Completed';
            wo.CurrencyIsoCode = 'USD';
            listWO.add(wo);
        }

        if (insertFlag) {
            try {
                insert listWO;
            } catch (exception e) {
                return null;
            }
        }
        return listWO;
    }

    // create a single Product_Repair__c record with an option to save the new record
    // input param 1 - String, Record Type Name for this Product_Repair__c record
    // input param 2 - String, Repair_Activity__c picklist value - not verified against record type
    // input param 3 - Product Item Id
    // input param 4 - Boolean, true = insert new Product_Repair__c record
    // returns the new Product_Repair__c record
    public static Product_Repair__c createProductRepair(String recordTypeName, String repairActivity, Id productItemId, Boolean insertFlag) {
        Id rtId;

        try {
            rtId = Schema.SObjectType.Product_Repair__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        } catch (exception e) {
            return null;
        }

        Product_Repair__c thisPR = new Product_Repair__c();
        thisPR.RecordTypeId = rtId;
        thisPR.Repair_Activity__c = repairActivity;
        thisPR.Product_Item__c = productItemId;
        thisPR.Repair_Technician__c = 'Bill Grider';
        //thisPR.Repair_date__c = system.today() - 2;

        if (insertFlag) {
            try {
                insert thisPR;
            } catch (exception e) {
                return null;
            }
        }
        return thisPR;
    }

    // create a single ProductTest__c record with an option to save the new record
    // input param 1 - Product Item Id
    // input param 2 - Boolean, true = insert new ProductTest__c record
    // returns the new ProductTest__c record
    public static ProductTest__c createProductTest(Id productItemId, Boolean insertFlag) {
        ProductTest__c thisPT = new ProductTest__c();
        thisPT.Name = String.valueOf(System.today());
        thisPT.Product_Item__c = productItemId;
        thisPT.Test_Completed_By__c = 'Rachel Stockwell';
        thisPT.Last_4_Characters_of_SN__c = '1234';
        if (insertFlag) {
            try {
                insert thisPT;
            } catch (exception e) {
                return null;
            }
        }
        return thisPT;
    }

    // create a single ProductTestData__c record with an option to save the new record
    // input param 1 - String, Field API Name
    // input param 2 - String, Field API Value
    // input param 3 - Boolean, true = insert new ProductTestData__c record
    // returns the new ProductTestData__c record
    public static ProductTestData__c createProductTestData(String API_Name, String API_Value, Boolean insertFlag) {
        ProductTestData__c thisPTD = new ProductTestData__c();
        thisPTD.Probe_Type__c = 'Transesophageal';
        thisPTD.Field_API_Name__c = API_Name;
        thisPTD.Field_API_Value__c = API_Value;
        thisPTD.Outsource__c = false;
        thisPTD.rating__c = 'bad';
        thisPTD.repair_evaluation__c = 'fix this now';
        thisPTD.Repairable__c = 'Yes';
        if (insertFlag) {
            try {
                insert thisPTD;
            } catch (exception e) {
                return null;
            }
        }
        return thisPTD;
    }

    // create a single Evaluation_Natalie__c record with an option to save the new record
    // input param 1 - RMA__c Id
    // input param 2 - Boolean, true = insert new Evaluation_Natalie__c record
    // returns the new Evaluation_Natalie__c record
    public static Evaluation_Natalie__c createEvaluationNatalie(Id RMA_Id, Boolean insertFlag) {
        Evaluation_Natalie__c thisEN = new Evaluation_Natalie__c();
        thisEN.Associated_RMA__c = RMA_Id;
        if (insertFlag) {
            try {
                insert thisEN;
            } catch (exception e) {
                return null;
            }
        }
        return thisEN;
    }
}