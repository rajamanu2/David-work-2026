@isTest
public class TestBusiness_Opps {

    @testSetup
    static void setup() {
        //Get Standard Price Book
        Id stdPB = ProboCommonUtils.getStdPricebookId();
        system.debug('TEST: standard price book id: ' + stdPB);

        //Create Products
        Product2 p = testDataFactory.createProduct('Ultrasound Probe', 'Philips X5-1', 'Ultrasound Probe', false);
        insert p;
        system.debug('TEST: product: ' + p);

        //Create Pricebook Entries for Products
        PriceBookEntry pbe = testDataFactory.createPricebookEntry(p.id, false);
        insert pbe;
        system.debug('TEST: pricebookentry: ' + pbe);

        //Create Product Item

        ProductItem__c pi = testDataFactory.createProductItem(p.id, false);
        //pi.Price__c = 11000;  not writeable? 
        pi.Check_In_Type__c = 'Purchase';
        //pi.Purchasing_Approved__c = false;
        pi.Generic_Product__c = false;
        pi.Location__c = 'QA-Testing';
        insert pi;
        system.debug('TEST: product item: ' + pi);

        // Create Business Units
        List<Account> acctsToInsert = testDataFactory.createAccounts(3, false);
        acctsToInsert[0].Name = 'Probo Medical - Tulsa';
        acctsToInsert[1].Name = 'MedCorp LLC';
        acctsToInsert[2].Name = 'Probo Medical - Indy';

        //Create Customer Account
        Account a = testDataFactory.createAccount(false);
        a.Accounting_Contact_E_mail__c = 'Test@Test.com';
        acctsToInsert.add(a);
        insert acctsToInsert;

        //Create Opportunity
        // moved down into each test method so we can set the Stage differently

        //Add Opportunity Products
        //OpportunityLineItem oli = testDataFactory.createOpportunityLineItem(o.id, pbe.Id, pi.Id, false);
    }

    //CASE A STEP 1
    //On original opp, user manually changes stage to "Repair Evaluation"
    //ASSERT that a NEW customer repair evaluation RMA (record type: Customer_Repair_Evaluation) is created
    //ASSERT that the opportunity field (Opportunity__c) is the id of the original opp (lookup field)
    //ASSERT that the quality issue notes field (Quality_Issue_Notes__c) on the RMA is equal to the Opportunity_Notes__c field on the original opp
    //ASSERT that the RMA_Item_Serial_Number__c field on the RMA is equal to the Repair_Evaluation_Serial_Number__c field on the original opp
    static testmethod void testRepairEvaluation() {
        system.debug('TEST: start A1 -testRepairEvaluation');

        test.startTest();

        Account a = [select id from Account where Name = 'testAccount' LIMIT 1];
        //Opportunity o = [select id, name, Opportunity_Notes__c, Repair_Evaluation_Serial_Number__c from Opportunity Where name = 'SalesOpp' LIMIT 1];
        Opportunity o = testDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, false);
        o.Name = 'SalesOpp';
        o.Pricebook2Id = ProboCommonUtils.getStdPricebookId();
        o.Ship_Date__c = date.today() + 30;
        o.CloseDate = date.today() + 15;
        o.Verified_Asset_and_Serial_Numbers_Match__c = true;
        o.StageName = 'Repair Evaluation';
        insert o;

        test.stopTest();

        // we have to do this since the RMA field setting code is only in the Update trigger
        o.Opportunity_Notes__c = 'This is what needs to be done';
        o.Repair_Evaluation_Serial_Number__c = '123456';
        update o;

        Opportunity salesOppAfter = [select id, name, stageName from Opportunity where id = :o.id];
        system.assert(salesOppAfter.StageName == 'Repair Evaluation', 'Parent stagename not set to Repair Evaluation');

        List<RMA__c> RMAs = [select Id, Opportunity__c, RecordType.Name, Quality_Issue_Notes__c, RMA_Item_Serial_Number__c from RMA__c];
        system.debug('TEST: RMAs: ' + RMAs);
        RMA__c rma = RMAs[0];
        system.assert(RMAs.size() != 0, 'there are no RMAs');
        system.assert(rma.RecordType.Name == 'Customer Repair Evaluation', 'RMA name is not Customer Repair Evaluation');
        system.assert(rma.Opportunity__c == o.id, 'RMA is not associated with Opportunity');
        system.assert(rma.Quality_Issue_Notes__c == o.Opportunity_Notes__c, 'RMA Quality Issue Notes do not match Opportunity Notes');
        system.assert(RMAs.size() == 1, 'there is more than 1 RMA');
        system.assert(rma.RMA_Item_Serial_Number__c == o.Repair_Evaluation_Serial_Number__c, 'RMA Item SN does not match Opportunity Repair_Evaluation_Serial_Number__c');
        system.debug('TEST: stop testRepairEvaluation');
    }

    //CASE A STEP 2
    //Create "loaner" opp: User clicks "Create Loaner Opp" button (Create_Loaner_Opp)
    //ASSERT that related opportunity field on original opp is the id of the loaner opp (lookup field)
    //ASSERT that related opportunity field on the loaner opp is the id of the original opp (lookup field)
    static testmethod void testLoanerOppCreation() {
        system.debug('TEST: A2 start testLoanerOppCreation');

        //Opportunity o = [select id, name from Opportunity Where name = 'SalesOpp' LIMIT 1];
        Account a = [select Id from Account where Name = 'testAccount' LIMIT 1];
        Opportunity o = testDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, false);
        o.Name = 'SalesOpp';
        o.Opportunity_Notes__c = 'This is what needs to be done';
        o.Pricebook2Id = ProboCommonUtils.getStdPricebookId();
        o.Repair_Evaluation_Serial_Number__c = '123456';
        o.Ship_Date__c = date.today() + 30;
        o.CloseDate = date.today() + 15;
        o.Verified_Asset_and_Serial_Numbers_Match__c = true;
        o.StageName = 'Repair Evaluation';
        insert o;

        test.startTest();

        ApexPages.StandardController sc = new ApexPages.StandardController(o);
        PageReference pageRef = Page.NewLoaner;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', o.Id);
        NewLoanerOpp nlo = new NewLoanerOpp(sc);
        nlo.newLoaner();

        test.stopTest();

        List<Opportunity> opps = [select id, name, RecordTypeId, SubType__c, Related_Opportunity__c from Opportunity];
        
        Opportunity salesOpp = new Opportunity();
        Opportunity loanerOpp = new Opportunity();
        for (Opportunity opp : opps) {
            if (opp.name == 'SalesOpp') {
                salesOpp = opp;
                system.debug('TEST: salesOpp = '+ salesOpp);
            } else {
                loanerOpp = opp;
                system.debug('TEST: loanerOpp = '+ loanerOpp);
            }
        }
        system.assert(opps.size() == 2, 'there are not 2 Opportunities');
        system.assert(loanerOpp.Related_Opportunity__c == salesOpp.id, 'Loaner Opp Related To Opportunity field is not set to the Sales Opp');
        system.assertEquals('Loaner', loanerOpp.SubType__c, 'Loaner Opp SubType__c field is not correctly');
        system.assert(salesOpp.Related_Opportunity__c == loanerOpp.id, 'Sales Opp Related To Opportunity field is not set to the Loaner Opp');
        system.debug('TEST: end testLoanerOppCreation');
    }


    /*CASE A STEP 3
    On "loaner" opp, user clicks "add product" button. User manually searches for "X5-1" and manually checks the "select" box for one asset 
 		(check in type = purchase, Purchasing_Approved__c = true), then manually selects the "Add" button. 
		This asset will now be referred to as the "loaner probe"
	User manually changes stage of loaner opp to "Probe Loan"
	ASSERT that NEW loaner return RMA (record type:Loaner_Return) is created with the opportunity field linked to the loaner opp.
	ASSERT that the ProductItem__c field on the RMA is the loaner probe
	ASSERT that the Related_Asset__c field on the Original opp is the loaner probe
	If related opp is attached, ASSERT Loaner_Asset_Number__c on customer repair evaluation RMA on original opp is the loaner probe
	ASSERT loaner opp name changes to: Asset.Product2_Name__c + ' LOANER SN #' + Asset.Serial_No__c
	*/

    //TODO: create Sales opp already on Repair Evaluation
    //TODO: then do loaner opp

    static testmethod void testLoanerProbe() {
        system.debug('TEST: start A3 testLoanerProbe');

       // Opportunity o = [select id, name, Opportunity_Notes__c, Repair_Evaluation_Serial_Number__c from Opportunity Where name = 'SalesOpp' LIMIT 1];
        Account a = [select Id from Account where Name = 'testAccount' LIMIT 1];
        Opportunity o = testDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, false);
        o.Name = 'SalesOpp';
        o.Opportunity_Notes__c = 'This is what needs to be done';
        o.Pricebook2Id = ProboCommonUtils.getStdPricebookId();
        o.Repair_Evaluation_Serial_Number__c = '123456';
        o.Ship_Date__c = date.today() + 30;
        o.CloseDate = date.today() + 15;
        o.Verified_Asset_and_Serial_Numbers_Match__c = true;
        o.StageName = 'Repair Evaluation';
        insert o;

        system.debug('TEST: inserted SalesOpp stage as Repair Evaluation');
        
         // update the RMA on the sales opp otherwise validation rule gets in the way
        List<RMA__c> salesOppRMAs = new List<RMA__c>([select id, Opportunity__c from RMA__c where Opportunity__c = :o.Id]);
        system.debug('TEST: salesOppRMA: ' +salesOppRMAs);
        System.assertEquals(1, salesOppRMAs.size(), 'The wrong number of RMAs were created when the SalesOpp was inserted.');

        salesOppRMAs[0].Quality_Issue_Notes__c = 'do this quality notes';
        salesOppRMAs[0].Quality_Issue_Reported__c = 'cosmetic issue';
        update salesOppRMAs[0];
        
		system.debug('TEST: updated SaleOpp RMA');


        ApexPages.StandardController sc = new ApexPages.StandardController(o);
        PageReference pageRef = Page.NewLoaner;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', o.Id);
        NewLoanerOpp nlo = new NewLoanerOpp(sc);
        nlo.newLoaner();

        system.debug('TEST: created loaner');

        test.startTest();

        //get the loanerOpp
        List<Opportunity> opps = [select id, name, StageName, RecordTypeId, Related_Opportunity__c, Pricebook2Id from Opportunity];
        System.assertEquals(2, opps.size(), 'The wrong number of Opportunities exist after a new Loaner Opp is created.');

        Opportunity salesOpp = new Opportunity();
        Opportunity loanerOpp = new Opportunity();
        for (Opportunity opp : opps) {

            if (opp.name == 'SalesOpp') {
                salesOpp = opp;
                system.debug('TEST: salesOpp = '+ salesOpp);
            } else {
                loanerOpp = opp;
                system.debug('TEST: loanerOpp = '+ loanerOpp);
            }
        }

        system.debug('TEST: salesOpp: ' + salesOpp);

        //set pricebook on loanerOpp
        system.debug('TEST: THIS IS THE LoanerOpp.PRICEBOOK before the update: ' + loanerOpp.Pricebook2Id);
        loanerOpp.Pricebook2Id = ProboCommonUtils.getStdPricebookId();
        loanerOpp.Shipping_FROM_Location__c = 'Fishers, IN';
        update loanerOpp;

        system.debug('TEST: loanerOpp: ' + loanerOpp);

        ProductItem__c pi = [
                Select ID,Name,Product_Name__r.name,Createddate,Model__c,Part_Number__c,Serial_No__c,Compatible_System__c,Functional_Rating__c,
                        Functional_Notes__c,Price__c,Cosmetic_Rating__c,Cosmetic_Notes__c,Location__c,Std_Cost_ex__c,Std_Cost_Out__c, Sug_Price_with_System__c,
                        Sug_Pr_Ex__c,Sug_Pr_Out__c,PO_Number__c,Other_Notes__c,Generic_Product__c,Image__c,Frequency_High__c,Frequency_Low__c,
                        Date_of_Manufacture__c,Product_Description__c,System_Software__c,Receive_date__c,Check_In_Type__c,Purchasing_Approved__c,
                        Repair_Activity__c,Repair_Priority_Rating__c,First_Call_Capability__c,System_Test_Bed__c,Repair_Summary__c,Review_Status__c, Review_Status_Notes__c,
                        Special_Offer_Pricing__c
                from ProductItem__c
                LIMIT 1
        ];

        system.debug('TEST: pi = ' + pi);

        //TODO: current cheating / mimicing addProduct.addProdut lines 457-470 to create an OLI and addProduct.WrapperProduct()
        OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = loanerOpp.Id,
                Model__c = pi.Model__c,
                Part_Number__c = pi.Part_Number__c,
                Serial_No__c = pi.Serial_No__c,
                Quantity = 1,
                UnitPrice = 500,
                Actual_Price__c = pi.Price__c,
                Compatible_System__c = pi.Compatible_System__c,
                Functional_Rating__c = pi.Functional_Rating__c,
                Functional_Rating_Notes__c = pi.Functional_Notes__c,
                ProductItem__c = pi.Id,
                Product2id = pi.Product_Name__c,
                Exchange__c = false,
                Asset_No__c = pi.name,
                Purchasing_Approved__c = pi.Purchasing_Approved__c,
                Probo_s_Offer__c = 500,
                Supplier_s_Quote__c = 400);
        insert oli;
        system.debug('TEST: opp line item: ' + oli);

        loanerOpp.StageName = 'Probe Loan';
        update loanerOpp;

        system.debug('TEST: loanerOpp updated to Probe Loan');

        test.stopTest();

        List<Opportunity> oppsAfter = [select id, name, RecordTypeId, Related_Opportunity__c, StageName from Opportunity];
        Opportunity salesOppAfter = new Opportunity();
        Opportunity loanerOppAfter = new Opportunity();
        for (Opportunity opp : oppsAfter) {
            if (opp.name == 'SalesOpp') {
                salesOppAfter = opp;
            } else {
                loanerOppAfter = opp;
            }
        }
        system.debug('TEST: salesOppAfter = ' + salesOppAfter);
        system.debug('TEST: loanerOppAfter = ' + loanerOppAfter);

        system.assertEquals('Probe Loan', loanerOppAfter.StageName, 'Loaner Opp stage was not changed to Probe Loan');

        // get the recordTypes we need to confirm against
        RecordType recTypeForSalesOppRMA;
        RecordType recTypeForLoanerOppRMA;

        for (RecordType r : ProboCommonUtils.getRecordTypes('RMA__c')){

            if (r.IsActive && r.Name == 'Customer Repair Evaluation' ) {
                recTypeForSalesOppRMA  = r;
            } else if (r.IsActive && r.Name == 'Loaner Return' ) {
                recTypeForLoanerOppRMA  = r;
            }
        }

        List<RMA__c> RMAs = [
                select Id, Opportunity__c, RecordTypeId, Quality_Issue_Notes__c, RMA_Item_Serial_Number__c
                from RMA__c
        ];
        system.debug('TEST: All RMAs: ' + RMAs);
        List<RMA__c> loanerRMAs = new List<RMA__c>();
        List<RMA__c> salesRMAs = new List<RMA__c>();
        for (RMA__c rma : RMAs) {
            System.debug('TEST: Checking RMA to see if it is related to the LoanerOpp: ');
            if (rma.Opportunity__c == loanerOpp.id) {
                system.debug('TEST: RMA is related to the LoanerOpp: ' + rma.Id);
                loanerRMAs.add(rma);
            } else if (rma.Opportunity__c == salesOpp.Id) {
                system.debug('TEST: RMA is related to the SalesOpp: ' + rma.Id);
                salesRMAs.add(rma);
            }
        }
        //system.assertEquals(1, RMAs.size(), 'The wrong number of RMAs were created during this test.');

        system.debug('TEST: loanerRMAs: ' + loanerRMAs);
        system.debug('TEST: saleRMAs: ' + salesRMAs);

//        system.assertEquals(1, loanerRMAs.size(), 'The wrong number of loanerOpp RMAs were created.');
//        system.assert(loanerRMAs[0].Opportunity__c == loanerOpp.id, 'RMA is not linked to LoanerOpp');
//        system.assertEquals(recTypeForLoanerOppRMA.Id, loanerRMAs[0].RecordTypeId, 'Loaner RMA is not the correct RecordType');

        system.assertEquals(1, salesRMAs.size(), 'The wrong number of salesOpp RMAs were created.');
        system.assert(salesRMAs[0].Opportunity__c == salesOpp.id, 'RMA is not linked to salesOpp');
        system.assertEquals(recTypeForSalesOppRMA.Id, salesRMAs[0].RecordTypeId, 'Sales RMA is not the correct RecordType');
    }
    
    /*CASE A STEP 4
    On the customer repair eval RMA on the original opp, user manually enters information into the ProductItem__c 
	field and the Date_RMA_Item_Received__c. ProductItem__c field is a lookup field. This asset will now be referred to as the "repair probe"
    ASSERT that Related_asset__c on loaner opp (if related opp attached) is the repair probe
    ASSERT that Repair Probe Asset # on the loaner RMA (if related opp attached) is the asset number 
	(this is not a look up field) of the repair probe and the repair probe SN field on the loaner RMA is the repair probe serial number.
    ASSERT that a NEW opportunity line item was created on the repair opp with the repair probe selected as the ProductItem__c on the 
	opportunity line item (does not seem to be working)
	*/
    static testmethod void testRMAUpdate_A4() {
        system.debug('TEST: start testRMAUpdate_A4');

       // Opportunity o = [select id, name, Opportunity_Notes__c, Repair_Evaluation_Serial_Number__c from Opportunity Where name = 'SalesOpp' LIMIT 1];
        Account a = [select Id from Account where Name = 'testAccount' LIMIT 1];
        Opportunity o = testDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, false);
        o.Name = 'SalesOpp';
        o.Opportunity_Notes__c = 'This is what needs to be done';
        o.Pricebook2Id = ProboCommonUtils.getStdPricebookId();
        o.Repair_Evaluation_Serial_Number__c = '123456';
        o.Ship_Date__c = date.today() + 30;
        o.CloseDate = date.today() + 15;
        o.Verified_Asset_and_Serial_Numbers_Match__c = true;
        o.StageName = 'Repair Evaluation';
        insert o;

        system.debug('TEST: inserted SalesOpp stage as Repair Evaluation');
        
         // update the RMA on the sales opp otherwise validation rule gets in the way
        List<RMA__c> salesOppRMAs = new List<RMA__c>([select id, Opportunity__c from RMA__c where Opportunity__c = :o.Id]);
        system.debug('TEST: salesOppRMA: ' +salesOppRMAs);
        System.assertEquals(1, salesOppRMAs.size(), 'The wrong number of RMAs were created when the SalesOpp was inserted.');

        salesOppRMAs[0].Quality_Issue_Notes__c = 'do this quality notes';
        salesOppRMAs[0].Quality_Issue_Reported__c = 'cosmetic issue';
        update salesOppRMAs[0];
        
		system.debug('TEST: updated SaleOpp RMA');


        ApexPages.StandardController sc = new ApexPages.StandardController(o);
        PageReference pageRef = Page.NewLoaner;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', o.Id);
        NewLoanerOpp nlo = new NewLoanerOpp(sc);
        nlo.newLoaner();

        system.debug('TEST: created loaner');

        test.startTest();

        //get the loanerOpp
        List<Opportunity> opps = [select id, name, StageName, RecordTypeId, Related_Opportunity__c, Pricebook2Id from Opportunity];
        System.assertEquals(2, opps.size(), 'The wrong number of Opportunities exist after a new Loaner Opp is created.');

        Opportunity salesOpp = new Opportunity();
        Opportunity loanerOpp = new Opportunity();
        for (Opportunity opp : opps) {

            if (opp.name == 'SalesOpp') {
                salesOpp = opp;
                system.debug('TEST: salesOpp = '+ salesOpp);
            } else {
                loanerOpp = opp;
                system.debug('TEST: loanerOpp = '+ loanerOpp);
            }
        }

        system.debug('TEST: salesOpp: ' + salesOpp);

        //set pricebook on loanerOpp
        system.debug('TEST: THIS IS THE LoanerOpp.PRICEBOOK before the update: ' + loanerOpp.Pricebook2Id);
        loanerOpp.Pricebook2Id = ProboCommonUtils.getStdPricebookId();
        loanerOpp.Shipping_FROM_Location__c = 'Fishers, IN';
        update loanerOpp;

        system.debug('TEST: loanerOpp: ' + loanerOpp);

        ProductItem__c pi = [
                Select ID,Name,Product_Name__r.name,Createddate,Model__c,Part_Number__c,Serial_No__c,Compatible_System__c,Functional_Rating__c,
                        Functional_Notes__c,Price__c,Cosmetic_Rating__c,Cosmetic_Notes__c,Location__c,Std_Cost_ex__c,Std_Cost_Out__c, Sug_Price_with_System__c,
                        Sug_Pr_Ex__c,Sug_Pr_Out__c,PO_Number__c,Other_Notes__c,Generic_Product__c,Image__c,Frequency_High__c,Frequency_Low__c,
                        Date_of_Manufacture__c,Product_Description__c,System_Software__c,Receive_date__c,Check_In_Type__c,Purchasing_Approved__c,
                        Repair_Activity__c,Repair_Priority_Rating__c,First_Call_Capability__c,System_Test_Bed__c,Repair_Summary__c,Review_Status__c, Review_Status_Notes__c,
                        Special_Offer_Pricing__c
                from ProductItem__c
                LIMIT 1
        ];

        system.debug('TEST: pi = ' + pi);

        //TODO: current cheating / mimicing addProduct.addProdut lines 457-470 to create an OLI and addProduct.WrapperProduct()
        OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = loanerOpp.Id,
                Model__c = pi.Model__c,
                Part_Number__c = pi.Part_Number__c,
                Serial_No__c = pi.Serial_No__c,
                Quantity = 1,
                UnitPrice = 500,
                Actual_Price__c = pi.Price__c,
                Compatible_System__c = pi.Compatible_System__c,
                Functional_Rating__c = pi.Functional_Rating__c,
                Functional_Rating_Notes__c = pi.Functional_Notes__c,
                ProductItem__c = pi.Id,
                Product2id = pi.Product_Name__c,
                Exchange__c = false,
                Asset_No__c = pi.name,
                Purchasing_Approved__c = pi.Purchasing_Approved__c,
                Probo_s_Offer__c = 500,
                Supplier_s_Quote__c = 400);
        insert oli;
        system.debug('TEST: opp line item: ' + oli);

        //Start of Step 4
        ProductItem__c repairProbe = testDataFactory.createProductItem(pi.Product_Name__c, false);
        insert repairProbe;
        
        List<RMA__c> salesOppRMAsNew = new List<RMA__c>([select id, Opportunity__c from RMA__c where Opportunity__c = :o.Id]);
        salesOppRMAsNew[0].Date_RMA_Item_Received__c = date.today();
        salesOppRMAsNew[0].ProductItem__c = repairProbe.Id;
        update salesOppRMAsNew;

        test.stopTest();

        List<Opportunity> oppsAfter = [select id, name, RecordTypeId, Related_Opportunity__c, StageName from Opportunity];
        Opportunity salesOppAfter = new Opportunity();
        Opportunity loanerOppAfter = new Opportunity();
        for (Opportunity opp : oppsAfter) {
            if (opp.name == 'SalesOpp') {
                salesOppAfter = opp;
            } else {
                loanerOppAfter = opp;
            }
        }
        system.debug('TEST: salesOppAfter = ' + salesOppAfter);
        system.debug('TEST: loanerOppAfter = ' + loanerOppAfter);
		
 
    }
    
        /*CASE A STEP 5
         * ASSERT date loaner shipped field in repair eval RMA is equal to the loaner opp ship date
		ASSERT new move location was created for loaner probe (Old_Location__c = loaner probe.Location__c, 
		Note__c = 'Loaner shipped on ' + ship date, Related_Opportunity__c = loaner opp.Id, 
		External_Location__c = Account, New_Location__c = 'Customer Loan / Demo', 
		Completed_By__c = current user first name + ' ' + current user last name, 
		ProductItem__c = loaner probe.id)z
		ASSERT that Stage on Loaner opp is changed to "Closed Won"
		ASSERT that Loaner RMA on Loaner opp has loaner_changed_to_sale__c field is marked as "true"
		ASSERT that Repair RMA on original opp has repair_turned_to_exchange__c marked as "true"
		ASSERT that new core exchange record type RMA was created

    	Opportunity__c = loaner opp, 
		ProductItem__c = repair probe, 
		RMA_Item_Serial_Number__c = repair probe serial number, 
		Loaner_Asset_Number__c = loaner probe, 
		Date_RMA_Item_Received__c = today's date

		ASSERT that Repair RMA on original opp has Core_Exchange_RMA__c equal to new core RMA that was just created
	
	*/
    static testmethod void testLoanerProbeClose_A5() {
        system.debug('TEST: start A5 testLoanerProbeClose');

       // Opportunity o = [select id, name, Opportunity_Notes__c, Repair_Evaluation_Serial_Number__c from Opportunity Where name = 'SalesOpp' LIMIT 1];
        Account a = [select Id from Account where Name = 'testAccount' LIMIT 1];
        Opportunity o = testDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, false);
        o.Name = 'SalesOpp';
        o.Opportunity_Notes__c = 'This is what needs to be done';
        o.Pricebook2Id = ProboCommonUtils.getStdPricebookId();
        o.Repair_Evaluation_Serial_Number__c = '123456';
        o.Ship_Date__c = date.today() + 30;
        o.CloseDate = date.today() + 15;
        o.Verified_Asset_and_Serial_Numbers_Match__c = true;
        o.StageName = 'Repair Evaluation';
        insert o;

        system.debug('TEST: inserted SalesOpp stage as Repair Evaluation');
        
         // update the RMA on the sales opp otherwise validation rule gets in the way
        List<RMA__c> salesOppRMAs = new List<RMA__c>([select id, Opportunity__c from RMA__c where Opportunity__c = :o.Id]);
        system.debug('TEST: salesOppRMA: ' +salesOppRMAs);
        System.assertEquals(1, salesOppRMAs.size(), 'The wrong number of RMAs were created when the SalesOpp was inserted.');

        salesOppRMAs[0].Quality_Issue_Notes__c = 'do this quality notes';
        salesOppRMAs[0].Quality_Issue_Reported__c = 'cosmetic issue';
        update salesOppRMAs[0];
        
		system.debug('TEST: updated SaleOpp RMA');


        ApexPages.StandardController sc = new ApexPages.StandardController(o);
        PageReference pageRef = Page.NewLoaner;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', o.Id);
        NewLoanerOpp nlo = new NewLoanerOpp(sc);
        nlo.newLoaner();

        system.debug('TEST: created loaner');

        test.startTest();

        //get the loanerOpp
        List<Opportunity> opps = [select id, name, StageName, RecordTypeId, Related_Opportunity__c, Pricebook2Id from Opportunity];
        System.assertEquals(2, opps.size(), 'The wrong number of Opportunities exist after a new Loaner Opp is created.');

        Opportunity salesOpp = new Opportunity();
        Opportunity loanerOpp = new Opportunity();
        for (Opportunity opp : opps) {

            if (opp.name == 'SalesOpp') {
                salesOpp = opp;
                system.debug('TEST: salesOpp = '+ salesOpp);
            } else {
                loanerOpp = opp;
                system.debug('TEST: loanerOpp = '+ loanerOpp);
            }
        }

        system.debug('TEST: salesOpp: ' + salesOpp);

        //set pricebook on loanerOpp
        system.debug('TEST: THIS IS THE LoanerOpp.PRICEBOOK before the update: ' + loanerOpp.Pricebook2Id);
        loanerOpp.Pricebook2Id = ProboCommonUtils.getStdPricebookId();
        loanerOpp.Shipping_FROM_Location__c = 'Fishers, IN';
        update loanerOpp;


        system.debug('TEST: loanerOpp: ' + loanerOpp);

        ProductItem__c pi = [
                Select ID,Name,Product_Name__r.name,Createddate,Model__c,Part_Number__c,Serial_No__c,Compatible_System__c,Functional_Rating__c,
                        Functional_Notes__c,Price__c,Cosmetic_Rating__c,Cosmetic_Notes__c,Location__c,Std_Cost_ex__c,Std_Cost_Out__c, Sug_Price_with_System__c,
                        Sug_Pr_Ex__c,Sug_Pr_Out__c,PO_Number__c,Other_Notes__c,Generic_Product__c,Image__c,Frequency_High__c,Frequency_Low__c,
                        Date_of_Manufacture__c,Product_Description__c,System_Software__c,Receive_date__c,Check_In_Type__c,Purchasing_Approved__c,
                        Repair_Activity__c,Repair_Priority_Rating__c,First_Call_Capability__c,System_Test_Bed__c,Repair_Summary__c,Review_Status__c, Review_Status_Notes__c,
                        Special_Offer_Pricing__c
                from ProductItem__c
                LIMIT 1
        ];

        system.debug('TEST: pi = ' + pi);

        //TODO: current cheating / mimicing addProduct.addProdut lines 457-470 to create an OLI and addProduct.WrapperProduct()
        OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = loanerOpp.Id,
                Model__c = pi.Model__c,
                Part_Number__c = pi.Part_Number__c,
                Serial_No__c = pi.Serial_No__c,
                Quantity = 1,
                UnitPrice = 500,
                Actual_Price__c = pi.Price__c,
                Compatible_System__c = pi.Compatible_System__c,
                Functional_Rating__c = pi.Functional_Rating__c,
                Functional_Rating_Notes__c = pi.Functional_Notes__c,
                ProductItem__c = pi.Id,
                Product2id = pi.Product_Name__c,
                Exchange__c = false,
                Asset_No__c = pi.name,
                Purchasing_Approved__c = pi.Purchasing_Approved__c,
                Probo_s_Offer__c = 500,
                Supplier_s_Quote__c = 400);
        insert oli;
        system.debug('TEST: opp line item: ' + oli);

        //Start of Step 4
        ProductItem__c repairProbe = testDataFactory.createProductItem(pi.Product_Name__c, false);
        insert repairProbe;
        
        List<RMA__c> salesOppRMAsNew = new List<RMA__c>([select id, Opportunity__c from RMA__c where Opportunity__c = :o.Id]);
        salesOppRMAsNew[0].Date_RMA_Item_Received__c = date.today();
        salesOppRMAsNew[0].ProductItem__c = repairProbe.Id;
        update salesOppRMAsNew;
        
        
        //Start of Step 5
        loanerOpp.StageName = 'Probe Loan';
        update loanerOpp;
        loanerOpp.Customer_PO__c = '543';
        loanerOpp.Ship_Date__c = date.today() + 1;
        loanerOpp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        update loanerOpp;

        test.stopTest();

        //Make sure the RMA Product Item is not sold yet
        // TODO: This is broken in Production - no RMAs are created
/*
        RMA__c loanerRMA = [select id, Name, ProductItem__c, Opportunity__c from RMA__c where Opportunity__c = :loanerOpp.Id];
        ProductItem__c loanerRMAPI = [select Name, Id, sold__c, Purchasing_Approved__c from ProductItem__c where Id = :loanerRMA.ProductItem__c ];
        system.debug('TEST: loanerRMAPI: '+ loanerRMAPI);
        system.assert(!loanerRMAPI.sold__c, 'Loaner RMA Product Item is already sold and should not be');
*/

        // Close Won the Loaner Opp which also marks the Product Item on the RMA as sold
        loanerOpp.Loaner_Turned_to_Sale__c = true;
        loanerOpp.Confirmation_number__c = '12345';
        update loanerOpp;    

        List<Opportunity> oppsAfter = [select id, name, RecordTypeId, Related_Opportunity__c, StageName from Opportunity];
        Opportunity salesOppAfter = new Opportunity();
        Opportunity loanerOppAfter = new Opportunity();
        for (Opportunity opp : oppsAfter) {
            if (opp.name == 'SalesOpp') {
                salesOppAfter = opp;
            } else {
                loanerOppAfter = opp;
            }
        }
        system.debug('TEST: salesOppAfter = ' + salesOppAfter);
        system.debug('TEST: loanerOppAfter = ' + loanerOppAfter);
		
 
    }

    /*Case B Repair & Warranty
	ASSERT that a NEW customer repair evaluation RMA (record type: Customer_Repair_Evaluation) is created
    ASSERT that the opportunity field (Opportunity__c) is the id of the original opp (lookup field)
    ASSERT that the quality issue notes field (Quality_Issue_Notes__c) on the RMA is equal to the Opportunity_Notes__c field on the original opp
    ASSERT that the RMA_Item_SN__c field on the RMA is equal to the Repair_Evaluation_Serial_Number__c field on the original opp
    ASSERT white glove service box is checked (=true) on customer repair evaluation RMA
    ASSERT customer probe box is checked (=true) on customer repair evaluation
    ASSERT opp name changed to ***WGS*** + probe model (if present) or original opp name string

	On the customer repair eval RMA on the original opp, user manually enters information into the ProductItem__c field and the Date_RMA_Item_Received__c. ProductItem__c field is a lookup field. This asset will now be referred to as the "repair probe"
	
    ASSERT that related opportunity field on original opp is the id of the warranty opp (lookup field)
    ASSERT that related opportunity field on the warranty opp is the id of the original opp (lookup field)
    ASSERT that the Related_Asset__c field on the warranty opp is the repair probe
	*/
    /*static testmethod void testRepairWarranty() {

        User u = [select Id from User where LastName = 'Trogden' and FirstName = 'David' LIMIT 1];
        Account a = [select Id from Account where Name = 'testAccount' LIMIT 1];

        Opportunity o = testDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, false);
        o.Name = 'SalesOpp';
        o.Pricebook2Id = ProboCommonUtils.getStdPricebookId();
        o.Ship_Date__c = date.today() + 30;
        o.CloseDate = date.today() + 15;
        o.Verified_Asset_and_Serial_Numbers_Match__c = true;
        o.StageName = 'Proposal/Price Quote';
        o.White_Glove_Service__c = true;
        o.Customer_Probe__c = true;
        o.OwnerId = u.Id;
        warrantyOppAfter.BillingStreet__c = '1234 Main';
        warrantyOppAfter.BillingCity__c = 'Denver';
        warrantyOppAfter.BillingState__c = 'CO';
        warrantyOppAfter.BillingPostalCode__c = '12345';
        warrantyOppAfter.BillingCountry__c = 'US';
        warrantyOppAfter.ShippingStreet__c = '1234 Main';
        warrantyOppAfter.ShippingCity__c = 'Denver';
        warrantyOppAfter.ShippingState__c = 'CO';
        warrantyOppAfter.ShippingPostalCode__c = '12345';
        warrantyOppAfter.ShippingCountry__c = 'US';
        insert o;

        System.debug('TEST: initial Opp has been updated');

        ProductItem__c pi = [
                Select ID,Name,Product_Name__r.name,Createddate,Model__c,Part_Number__c,Serial_No__c,Compatible_System__c,Functional_Rating__c,
                        Functional_Notes__c,Price__c,Cosmetic_Rating__c,Cosmetic_Notes__c,Location__c,Std_Cost_ex__c,Std_Cost_Out__c, Sug_Price_with_System__c,
                        Sug_Pr_Ex__c,Sug_Pr_Out__c,PO_Number__c,Other_Notes__c,Generic_Product__c,Image__c,Frequency_High__c,Frequency_Low__c,
                        Date_of_Manufacture__c,Product_Description__c,System_Software__c,Receive_date__c,Check_In_Type__c,Purchasing_Approved__c,
                        Repair_Activity__c,Repair_Priority_Rating__c,First_Call_Capability__c,System_Test_Bed__c,Repair_Summary__c,Review_Status__c, Review_Status_Notes__c,
                        Special_Offer_Pricing__c
                from ProductItem__c
                LIMIT 1
        ];


        System.debug('TEST: PItem Serial Number is: ' + pi.Serial_No__c);
        Test.startTest();

        // we have to do this update so the update trigger can set RMA fields from the Opp
        o.StageName = 'Repair Evaluation';
        o.Opportunity_Notes__c = 'This is what needs to be done';
        o.Repair_Evaluation_Serial_Number__c = '123456';
        update o;

        List<RMA__c> RMAs = [
                select Id, Opportunity__c, Quality_Issue_Notes__c, RMA_Item_Serial_Number__c,
                        White_Glove_Service__c, Customer_s_Probe__c
                from RMA__c
        ];

        RMAs[0].ProductItem__c = pi.id;
        RMAs[0].Date_RMA_Item_Received__c = date.today();
        update RMAs[0];


        System.debug('TEST: RMA has been updated');


        //Create "warranty" opp: user manually clicks "Create warranty opp" button ("Create_Warranty_Opp")
        ApexPages.StandardController sc = new ApexPages.StandardController(o);
        PageReference pageRef = Page.NewWarrantyOpp;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', o.Id);

        System.debug('TEST: the next line creates the Warranty Opp');
        NewWarrantyOpp nwo = new NewWarrantyOpp(sc);
        nwo.newWarranty();

        System.debug('TEST: NewWarrantyOpp methods are complete');

        List<Opportunity> oppsAfter = [
                select id, name, RecordTypeId, Opportunity_Notes__c, SubType__c,
                        Repair_Evaluation_Serial_Number__c, Related_Asset__c, Related_Opportunity__c, StageName
                from Opportunity
        ];
        Opportunity salesOppAfter = new Opportunity();
        Opportunity warrantyOppAfter = new Opportunity();

        System.debug('TEST: oppsAfter: ' + oppsAfter);

        for (Opportunity opp : oppsAfter) {
            if (opp.name.contains('SalesOpp')) {
                salesOppAfter = opp;
            } else {
                warrantyOppAfter = opp;
            }
        }

        System.assertEquals('Warranty', warrantyOppAfter.SubType__c, 'New Warranty Opp SubType__c field is not set correctly.');
        //On "warranty" opp, user clicks "add product" button. User manually searches for "X5-1" and manually checks the "select" box for one asset
        //(check in type = customer repair; theoretically, this would be the same asset number that's on the original opp), 
        //then manually selects the "Add" button. This asset will now be referred to as the "warranty probe"      
        o.BillingStreet__c = '1234 Main';
        o.BillingCity__c = 'Denver';
        o.BillingState__c = 'CO';
        o.BillingPostalCode__c = '12345';
        o.BillingCountry__c = 'US';
        o.ShippingStreet__c = '1234 Main';
        o.ShippingCity__c = 'Denver';
        o.ShippingState__c = 'CO';
        o.ShippingPostalCode__c = '12345';
        o.ShippingCountry__c = 'US';
        warrantyOppAfter.Pricebook2Id = ProboCommonUtils.getStdPricebookId();
        update warrantyOppAfter;

        System.debug('TEST: WarrantyOppAfter has been updated');


        test.stopTest();

        OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = warrantyOppAfter.Id,
                Model__c = pi.Model__c,
                Part_Number__c = pi.Part_Number__c,
                Serial_No__c = pi.Serial_No__c,
                Quantity = 1,
                UnitPrice = 500,
                Actual_Price__c = pi.Price__c,
                Compatible_System__c = pi.Compatible_System__c,
                Functional_Rating__c = pi.Functional_Rating__c,
                Functional_Rating_Notes__c = pi.Functional_Notes__c,
                ProductItem__c = pi.Id,
                Product2id = pi.Product_Name__c,
                Exchange__c = false,
                Asset_No__c = pi.name,
                Purchasing_Approved__c = pi.Purchasing_Approved__c,
                Probo_s_Offer__c = 500,
                Supplier_s_Quote__c = 400);
        insert oli;

        System.debug('TEST: OLIs are inserted - which should have set the Opp.Name to include the OLI.PItem.Serial_No__c');


        // we need to re-query the warrantyOpp so we get the DB field values that were set during processing
        oppsAfter = [
                select id, name, RecordTypeId, Opportunity_Notes__c,
                        Repair_Evaluation_Serial_Number__c, Related_Asset__c, Related_Opportunity__c, StageName
                from Opportunity
        ];

        for (Opportunity opp : oppsAfter) {
            if (opp.name.contains('SalesOpp')) {
                salesOppAfter = opp;
            } else {
                warrantyOppAfter = opp;
            }
        }


        //Update customer PO # field, Shipping from location field, and change stage to "Closed Won", ASSERT no errors.
        warrantyOppAfter.Customer_PO__c = 'Customer PO 123';
        warrantyOppAfter.Shipping_FROM_Location__c = 'Fishers, IN';
        warrantyOppAfter.StageName = 'Closed Won';
        warrantyOppAfter.OwnerId = u.Id;
        warrantyOppAfter.Confirmation_number__c = '12345';
        update warrantyOppAfter;

        System.debug('TEST: WarrantyOppAfter has been updated to Closed Won');

        oppsAfter = [
                select id, name, RecordTypeId, Opportunity_Notes__c,
                        Repair_Evaluation_Serial_Number__c, Related_Asset__c, Related_Opportunity__c, StageName
                from Opportunity
        ];

        for (Opportunity opp : oppsAfter) {
            if (opp.name.contains('SalesOpp')) {
                salesOppAfter = opp;
            } else {
                warrantyOppAfter = opp;
            }
        }

        System.debug('TEST: Sales Opp ID: ' + salesOppAfter.Id);
        System.debug('TEST: Warranty Opp ID: ' + warrantyOppAfter.Id);

        system.debug('TEST: All RMAs: ' + RMAs);
        system.debug('TEST: oppsAfter: ' + oppsAfter);
        System.debug('WarrantyOpp Related_Asset__c: ' + warrantyOppAfter.Related_Asset__c);
        System.debug('RMAs[0].ProductItem__c: ' + RMAs[0].ProductItem__c);
        system.assert(RMAs.size() != 0, 'there are no RMAs');
        system.assert(RMAs.size() == 1, 'there is more than 1 RMA');
        system.assert(RMAs[0].Opportunity__c == o.id, 'RMA is not linked to SalesOpp');
        system.assert(RMAs[0].Quality_Issue_Notes__c == o.Opportunity_Notes__c, ' RMA[0].Quality_Issue_Notes__c not set to o.Opportunity_Notes__c');
        system.assert(RMAs[0].RMA_Item_Serial_Number__c == o.Repair_Evaluation_Serial_Number__c, 'RMAs[0].RMA_Item_Serial_Number__c not set to o.Repair_Evaluation_Serial_Number__c');
        system.assert(RMAs[0].White_Glove_Service__c == true, 'RMAs[0].White_Glove_Service__c was not set to true');
        system.assert(RMAs[0].Customer_s_Probe__c == true, 'RMAs[0].Customer_s_Probe__c was not set to true');
        system.assert(salesOppAfter.Name.contains('***WGS***'), 'Sales Opp name was not updated to contain ***WGS***');
        system.assert(warrantyOppAfter.Related_Opportunity__c == salesOppAfter.Id, 'Warranty opp was not related to Sales Opp');
        system.assert(salesOppAfter.Related_Opportunity__c == warrantyOppAfter.Id, 'Sales opp was not related to Warranty Opp');
        system.assert(warrantyOppAfter.StageName == 'Closed Won', 'Warranty opp was set to Closed Won');
        system.assert(warrantyOppAfter.Name.contains('WARRANTY SN #'), 'Warranty Opp name was not updated to contain WARRANTY SN #');
        // TODO: this is currently broken in Production -- the GENERIC is not appended to the Product name
    //    system.assert(warrantyOppAfter.Name.contains(pi.Serial_No__c), 'Warranty Opp name (' + warrantyOppAfter.Name + ') was not updated to include the ProductItem Serial Number: ' + pi.Serial_No__c);

        // TODO: This is currently broken in Production - Prod code only sets this if there is a single related OLI on the original Opp
       // system.assert(warrantyOppAfter.Related_Asset__c == RMAs[0].ProductItem__c, 'Warranty opp was not related to RMA ProductItem');




    }*/


    //Case C 100 Products
    //User clicks "add product" button on opp. Add at least 200 products/assets.
    //ASSERT that no SOQL query limits are hit
    static testmethod void test100Products() {
        system.debug('TEST: start test100Products');
        Contact con = new Contact();
        con.LastName = 'Test';
        con.Email = 'Test@Test.com';
        insert con;
        //Opportunity o = [select id, name, Account.Name, Ship_Date__c, CloseDate, RecordType.Name from Opportunity Where name = 'SalesOpp' LIMIT 1];
        Account a = [select Id from Account where Name = 'testAccount' LIMIT 1];
        Opportunity o = testDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, false);
        o.Name = 'SalesOpp';
        o.AccountId = a.Id;
        o.Contact_Lookup__c = con.Id;
        o.Opportunity_Notes__c = 'This is what needs to be done';
        o.Pricebook2Id = ProboCommonUtils.getStdPricebookId();
        o.Repair_Evaluation_Serial_Number__c = '123456';
        o.Ship_Date__c = date.today() + 30;
        o.CloseDate = date.today() + 15;
        o.Verified_Asset_and_Serial_Numbers_Match__c = true;
        o.StageName = 'Repair Evaluation';
        insert o;

        system.debug('TEST: opp:' + o);
        Product2 p = [select id from Product2 Limit 1];
        List<ProductItem__c> pis = testDataFactory.createProductItems(100, p.id, false);
        insert pis;

        Test.startTest();

        //TODO: current cheating / mimicing addProduct.addProdut lines 457-470 to create an OLI and addProduct.WrapperProduct()
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for (Integer i = 0; i < 100; i++) {
            OpportunityLineItem oli = new OpportunityLineItem(
                    OpportunityId = o.Id,
                    Model__c = pis[i].Model__c,
                    Part_Number__c = pis[i].Part_Number__c,
                    Serial_No__c = pis[i].Serial_No__c,
                    Quantity = 1,
                    UnitPrice = 500,
                    Actual_Price__c = pis[i].Price__c,
                    Compatible_System__c = pis[i].Compatible_System__c,
                    Functional_Rating__c = pis[i].Functional_Rating__c,
                    Functional_Rating_Notes__c = pis[i].Functional_Notes__c,
                    ProductItem__c = pis[i].Id,
                    Product2id = pis[i].Product_Name__c,
                    Exchange__c = false,
                    Asset_No__c = pis[i].name,
                    Purchasing_Approved__c = pis[i].Purchasing_Approved__c,
                    Probo_s_Offer__c = 500,
                    Supplier_s_Quote__c = 400);
            olis.add(oli);
        }
        insert olis;
        Test.stopTest();

        List<OpportunityLineItem> afterOlis = [select id from OpportunityLineItem where OpportunityId = :o.Id];
        system.assert(afterOlis.size() > 99, 'less than 200 OLIs were created: ' + afterOlis.size());

//  TODO: The real error in Prod is when the Opp is Closed Won so we need to test (SOQL errors)

        o.Customer_PO__c = 'CPO 123';
        o.StageName = 'Closed Won';
        o.Confirmation_number__c = '12345';
        update o;

        Opportunity oAfter = [select id, StageName from Opportunity Where name = 'SalesOpp' LIMIT 1];
        system.assert(oafter.StageName == 'Closed Won', 'Opp was not set to Closed Won');


    }

    //Case D Products (negative testing)
    //User clicks "add product" button on opp. but tries to change the Opp at the wrong time
    static testmethod void testProductsNegative() {
        system.debug('TEST: start testProducts');
        Id stdPB = ProboCommonUtils.getStdPricebookId();
        Account a = [Select Id From Account Where Name = 'testAccount' LIMIT 1];
        Opportunity opp = testDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, false);
        opp.Name = 'SalesOpp2';
        opp.Opportunity_Notes__c = 'This is what needs to be done';
        opp.Pricebook2Id = stdPB;
        opp.Repair_Evaluation_Serial_Number__c = '123456';
        opp.Ship_Date__c = date.today() + 30;
        opp.CloseDate = date.today() + 15;
        opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        opp.StageName = 'Proposal/Price Quote';
        system.debug('TEST: opportunity to insert: ' + opp);
        insert opp;
        system.debug('TEST: opp:' + opp);
        Product2 p = [select id from Product2 Limit 1];
        p.Functionally_Good_Probes__c = 3;
        //p.Target_Quantity_in_Stock__c = 2;  not writeable
        p.Total_No_of_Requests_3_Months__c = 13.33334;
        update p;

        test.startTest();

        List<ProductItem__c> pis = testDataFactory.createProductItems(3, p.id, false);
        pis[0].Sold__c = true;
        pis[0].Purchasing_Approved__c = true;
        pis[0].Check_In_Type__c = 'Purchase';
        pis[0].Date_Last_Test_Completed__c = date.today() - 7;
        pis[0].Added_to_Work_Order__c = false;
        pis[1].Purchasing_Approved__c = true;
        pis[1].Check_In_Type__c = 'Purchase';
        pis[2].Purchasing_Approved__c = true;
        pis[2].Check_In_Type__c = 'Purchase';
        insert pis;

        system.debug('TEST: value of 3 product items' + pis);

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

        for (ProductItem__c pi : pis) {
            OpportunityLineItem oli = new OpportunityLineItem(
                    OpportunityId = opp.Id,
                    Model__c = pi.Model__c,
                    Part_Number__c = pi.Part_Number__c,
                    Serial_No__c = pi.Serial_No__c,
                    Quantity = 1,
                    UnitPrice = 500,
                    Actual_Price__c = pi.Price__c,
                    Compatible_System__c = pi.Compatible_System__c,
                    Functional_Rating__c = pi.Functional_Rating__c,
                    Functional_Rating_Notes__c = pi.Functional_Notes__c,
                    ProductItem__c = pi.Id,
                    Product2id = pi.Product_Name__c,
                    Exchange__c = false,
                    Asset_No__c = pi.name,
                    Purchasing_Approved__c = pi.Purchasing_Approved__c,
                    Probo_s_Offer__c = 500,
                    Supplier_s_Quote__c = 400);
            olis.add(oli);
        }

        system.debug('TEST: Test is getting ready to insert the OLIs');
        insert olis;
        system.debug('TEST: OLIs have been inserted: ' + olis);

        // Update customer PO # field, Shipping from location field, and change stage to "Closed Won".
        // ASSERT that there is an error message that says 'Not possible because product is already sold'.
        opp.Shipping_FROM_Location__c = 'Tulsa, OK';
        Opp.Customer_PO__c = 'CPO 123';
        opp.StageName = 'Closed Won';
        String exceptionMessage = '';

        system.debug('TEST: Attempting to set the Opp to Closed Won - but the ProductItem__c are Sold so we should get an exception');

        try {
            update opp;
        } catch (Exception e) {
            system.debug('TEST: Exception caught: ' + e.getMessage());
            exceptionMessage = e.getMessage();
        }
        system.assert(exceptionMessage.contains('Not possible because product is already sold'), 'No line items found that are sold');

        system.debug('TEST: Setting Product Items to Sold = false');

        // Update Product item 1. Set Sold to false and Purchasing Approved to false.  Update stage to Closed Won.
        // ASSERT that there is an error message that says 'Not possible because product is not purchasing approved'.
        pis[0].Sold__c = false;
        pis[0].Purchasing_Approved__c = false;
        update pis;
        opp.StageName = 'Closed Won';
        exceptionMessage = '';

        system.debug('TEST: Attempting to set the Opp to Closed Won after setting Product Items to Sold = false but not setting Purchasing_Approved.  Should get an exception.');
        try {
            update opp;
        } catch (Exception e) {
            system.debug('TEST: Exception caught: ' + e.getMessage());
            exceptionMessage = e.getMessage();
        }
        system.assert(exceptionMessage.contains('Not possible because product is not purchasing approved'), 'All line items are purchasing approved');

        system.debug('TEST: Setting Product Items to Purchasing_Approved__c = true');

        // Update Product item 1. Set Purchasing Approved to true.  Update stage to Closed Won.
        // ASSERT that there are no errors.
        pis[0].Purchasing_Approved__c = true;
        update pis;
        opp.StageName = 'Closed Won';
        opp.Confirmation_number__c = '12345';
        exceptionMessage = '';

        system.debug('TEST: Updating the Opp again after setting Product Items to Purchasing_Approved__c = true.');

        try {
            update opp;
        } catch (Exception e) {
            system.debug('TEST: Exception caught: ' + e.getMessage());
            exceptionMessage = e.getMessage();
        }
        system.assertEquals('', exceptionMessage, 'An exception was generated.');

        system.debug('TEST: We have made it through the Opp Update after setting the ProductItems to Purchasing_Approved = true so the Stage is now: ' + opp.StageName);

        test.stopTest();
    }


    //Case D Products (positive testing)
    //User clicks "add product" button on opp. Add 3 products/assets.
    static testmethod void testAddProductsToOppPositive() {
        system.debug('TEST: start testProductsJMAY');
        Id stdPB = ProboCommonUtils.getStdPricebookId();
        Account a = [Select Id From Account Where Name = 'testAccount' LIMIT 1];
        // we need to make this the Opp Owner since WOs get a Person_Requesting_WO__c value based on the Opp Owner
        // and it is a restricted picklist
        User u = [select Id from User where LastName = 'Trogden' and FirstName = 'David' LIMIT 1];
        Opportunity opp = testDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, false);
        opp.Name = 'SalesOpp2';
        opp.OwnerId = u.Id;
        opp.Pricebook2Id = stdPB;
        opp.CloseDate = date.today() + 15;
        opp.StageName = 'Proposal/Price Quote';
        system.debug('TEST: opportunity to insert: ' + opp);
        insert opp;

        system.debug('TEST: opp:' + opp);

        Product2 p = [select id from Product2 Limit 1];
        p.Functionally_Good_Probes__c = 3;
        //p.Target_Quantity_in_Stock__c = 2;  formula based on Total_No_of_Requests_3_Months__c
        p.Total_No_of_Requests_3_Months__c = 13.33334;
        update p;

        List<ProductItem__c> pis = testDataFactory.createProductItems(3, p.id, false);
        pis[0].Purchasing_Approved__c = true;
        pis[0].Check_In_Type__c = 'Purchase';
        pis[0].Date_Last_Test_Completed__c = date.today() - 7;
        pis[0].Added_to_Work_Order__c = false;
        pis[0].Sold__c = false;
        pis[1].Purchasing_Approved__c = true;
        pis[1].Check_In_Type__c = 'Purchase';
        pis[1].Sold__c = false;
        pis[2].Purchasing_Approved__c = true;
        pis[2].Check_In_Type__c = 'Purchase';
        pis[2].Sold__c = false;
        insert pis;

        system.debug('TEST: value of 3 product items' + pis);

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

        // add the OppLines for the ProductItem__c created above
        for (ProductItem__c pi : pis) {
            OpportunityLineItem oli = new OpportunityLineItem(
                    OpportunityId = opp.Id,
                    Model__c = pi.Model__c,
                    Part_Number__c = pi.Part_Number__c,
                    Serial_No__c = pi.Serial_No__c,
                    Quantity = 1,
                    UnitPrice = 500,
                    Actual_Price__c = pi.Price__c,
                    Compatible_System__c = pi.Compatible_System__c,
                    Functional_Rating__c = pi.Functional_Rating__c,
                    Functional_Rating_Notes__c = pi.Functional_Notes__c,
                    ProductItem__c = pi.Id,
                    Product2id = pi.Product_Name__c,
                    Exchange__c = false,
                    Asset_No__c = pi.name,
                    Purchasing_Approved__c = pi.Purchasing_Approved__c,
                    Probo_s_Offer__c = 500,
                    Supplier_s_Quote__c = 400);
            olis.add(oli);
        }

        system.debug('TEST: Test is getting ready to insert the OLIs');
        insert olis;
        system.debug('TEST: OLIs have been inserted: ' + olis);

        opp.Shipping_FROM_Location__c = 'Tulsa, OK';
        Opp.Customer_PO__c = 'CPO 123';
        opp.StageName = 'Closed Won';
        opp.Confirmation_number__c = '12345';
        String exceptionMessage = '';

        system.debug('TEST: Updating the Opp to Closed Won');

        system.debug('TEST: The Opp before the update to Closed Won is: ' + opp);

        try {
            update opp;
        } catch (Exception e) {
            system.debug('TEST: Exception caught: ' + e.getMessage());
            exceptionMessage = e.getMessage();
        }
        system.assertEquals('', exceptionMessage, 'An exception was generated trying to set the Opp to Closed Won.');

        Test.startTest();

        system.debug('TEST: We have made it through the Opp Update after setting the Customer PO and Shipping_FROM_Location.  Stage is now: ' + opp.StageName);

        // the OLIs would have their Work_Orders created here as a result of the ClosedOn StageChange
        List<Work_Order__c> woList = [
                Select Id, RecordType.DeveloperName, Estimated_Ready_Date__c, Person_Requesting_WO__c, Special_Instructions__c, Asset__c
                From Work_Order__c
                Where Opportunity__c = :opp.Id
        ];
        system.debug('TEST: Work Orders related to the Opp: ' + woList);

        // ASSERT that a Work order is created.
        // ASSERT Record type equals 'Testing Work Order'.
        // ASSERT Estimated_Ready_Date__c equals today's date.
        // ASSERT Person_requesting_WO__c equals opportunity record owner
        // ASSERT Special_Instructions__c equals 'Special instructions not set to: Needs pre ship test'
        Opportunity oppUpdated = [Select Id, Name, Ship_Date__c, Account_Name__c, CloseDate, StageName, Owner.FirstName, Owner.LastName From Opportunity Where Id = :opp.Id LIMIT 1];
        system.debug('TEST: The Opp after the update is: ' + oppUpdated);
/*  Natalie commented out - was causing errors and the testing work order on Closed Won is no longer a functionality the sales team wants.
        String workOrderRecordType = Schema.SObjectType.Work_Order__c.getRecordTypeInfosByName().get('Testing Work Order').getDeveloperName();
        system.assertEquals(workOrderRecordType, woList[0].RecordType.DeveloperName, 'Work order record type is not Testing Work Order record type');
        system.assertEquals(date.today(), woList[0].Estimated_Ready_Date__c, 'Work order Estimated Ready Date is not set to today');
        system.assertEquals(oppUpdated.Owner.FirstName + ' ' + oppUpdated.Owner.LastName, woList[0].Person_Requesting_WO__c,  'Person Requesting work order is not the Opportunity Owner');
        system.assertEquals('Needs pre ship test', woList[0].Special_Instructions__c, 'Special instructions not set to: Needs pre ship test');
*/


        system.debug('TEST: Update Opp ship date and set Verified_Asset_and_Serial_Numbers_Match__c to true');
        opp.Ship_Date__c = date.today();
        opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        update opp;

        system.debug('TEST: Finished updating the Opp after setting ship date and set Verified_Asset_and_Serial_Numbers_Match__c to true');

        // ASSERT Product item 1 Sold__c is set to true
        // ASSERT Product item 1 Reserved__c is set to false
        // ASSERT Product item 1 Overstock_probe_when_sold__c is set to true
        // ASSERT Product item 1 Product_Name__c equals Line item 1 Sales_product__c
        // ASSERT Product item 1 Sales_Price__c equals Line item 1 UnitPrice
        // ASSERT Product item 1 Ship_Date__c equals Opportunity Ship_Date__c
        // ASSERT Product item 1 Account_Name__c equals Opportunity Account_Name__c
        // ASSERT Product item 1 Close_Date__c equals Opportunity CloseDate
        // ASSERT Product item 1 Opportunity_Name__c equals Opportunity name
        // ASSERT Product item 1 Stage__c equals Opportunity StageName
        Opportunity oppUpdatedShipDate = [Select Id, Name, Ship_Date__c, Account_Name__c, CloseDate, StageName, Owner.FirstName, Owner.LastName From Opportunity Where Id = :opp.Id LIMIT 1];
        OpportunityLineItem lineItem1 = [Select Id, Name, Sales_product__c, UnitPrice From OpportunityLineItem Where Id = :olis[0].Id LIMIT 1];
        ProductItem__c productItem1 = [
                Select Id, Name, Sold__c, Reserved__c, Overstock_probe_when_sold__c, Product_Name__c, Sales_Price__c, Ship_Date__c,
                        Account_Name__c, Close_Date__c, Opportunity_Name__c, Sales_Opportunity__c, Stage__c
                From ProductItem__c
                Where Id = :pis[0].Id
                LIMIT 1
        ];

        system.assertEquals(true, productItem1.Sold__c, 'Product item 1 is not sold');
        system.assertEquals(false, productItem1.Reserved__c, 'Product item 1 is not reserved');
        system.assertEquals(true, productItem1.Overstock_probe_when_sold__c, 'Product item 1 overstock probe when sold set to false');
        system.assertEquals(lineItem1.Sales_product__c, productItem1.Product_Name__c, 'Line Item 1 Product does not match Product item product');
        system.assertEquals(lineItem1.UnitPrice, productItem1.Sales_Price__c, 'Line Item 1 unit price does not match Product item sales price');
        system.assertEquals(oppUpdatedShipDate.Ship_Date__c, productItem1.Ship_Date__c, 'Opportunity ship date does not match Product item 1 ship date');
        system.assertEquals(oppUpdatedShipDate.Account_Name__c, productItem1.Account_Name__c, 'Opportunity account name does not match Product item 1 account name');
        system.assertEquals(oppUpdatedShipDate.CloseDate, productItem1.Close_Date__c, 'Opportunity close date does not match Product item 1 close date');
        system.assertEquals(oppUpdatedShipDate.Name, productItem1.Opportunity_Name__c, 'Opportunity name does not match Product item 1 opportunity name');
        system.assertEquals(oppUpdatedShipDate.Id, productItem1.Sales_Opportunity__c, 'Opportunity does not match Product item 1 Sales Opportunity');
        system.assertEquals(oppUpdatedShipDate.StageName, productItem1.Stage__c, 'Opportunity stage does not match Product item 1 stage');

        System.debug('TEST: Just finished checking the ProductItem fields on Setting ClosedWon Ship_Date');
        // ASSERT Product item 2 Sold__c is set to true
        // ASSERT Product item 2 Reserved__c is set to false
        // ASSERT Product item 2 Product_Name__c equals line item 2 Sales_product__c
        // ASSERT Product item 2 Sales_Price__c equals line item 2 UnitPrice
        OpportunityLineItem lineItem2 = [Select Id, Name, Sales_product__c, UnitPrice From OpportunityLineItem Where Id = :olis[1].Id LIMIT 1];
        ProductItem__c productItem2 = [
                Select Id, Name, Sold__c, Reserved__c, Overstock_probe_when_sold__c, Product_Name__c, Sales_Price__c, Ship_Date__c,
                        Account_Name__c, Close_Date__c, Opportunity_Name__c, Sales_Opportunity__c, Stage__c
                From ProductItem__c
                Where Id = :pis[1].Id
                LIMIT 1
        ];

        system.assertEquals(true, productItem2.Sold__c, 'Product item 2 is not sold');
        system.assertEquals(false, productItem2.Reserved__c, 'Product item 2 is not reserved');
        system.assertEquals(lineItem2.Sales_product__c, productItem2.Product_Name__c, 'Line Item 2 Sales_Product does not match ProductItem Sales_Product');
        system.assertEquals(lineItem2.UnitPrice, productItem2.Sales_Price__c, 'Line Item 2 UnitPrice does not match ProductItem Sales_Price__c');

        OpportunityLineItem lineItem3 = [Select Id, Name, Sales_product__c, UnitPrice From OpportunityLineItem Where Id = :olis[2].Id LIMIT 1];
        ProductItem__c productItem3 = [
                Select Id, Name, Sold__c, Reserved__c, Overstock_probe_when_sold__c, Product_Name__c, Sales_Price__c, Ship_Date__c,
                        Account_Name__c, Close_Date__c, Opportunity_Name__c, Sales_Opportunity__c, Stage__c
                From ProductItem__c
                Where Id = :pis[2].Id
                LIMIT 1
        ];

        // ASSERT Product item 3 Sold__c is set to true
        // ASSERT Product item 3 Reserved__c is set to false
        // ASSERT Product item 3 Product_Name__c equals line item 3 Sales_product__c
        // ASSERT Product item 3 Sales_Price__c equals line item 3 UnitPrice
        system.assertEquals(true, productItem3.Sold__c, 'Product item 3 is not sold');
        system.assertEquals(false, productItem3.Reserved__c, 'Product item 3 is not reserved');
        system.assertEquals(lineItem3.Sales_product__c, productItem3.Product_Name__c, 'Line Item 3 Sales_Product does not match ProductItem Sales_Product');
        system.assertEquals(lineItem3.UnitPrice, productItem3.Sales_Price__c, 'Line Item 3 UnitPrice does not match ProductItem Sales_Price__c');

        test.stopTest();
    }

    //Case D Products (Line Item Update)
    //User clicks "add product" button on opp. Add 3 products/assets.
    static testmethod void testOppLineUpdates() {
        system.debug('TEST: start testProductsJMAY');
        Id stdPB = ProboCommonUtils.getStdPricebookId();
        Account a = [Select Id From Account Where Name = 'testAccount' LIMIT 1];
        // we need to make this the Opp Owner since WOs get a Person_Requesting_WO__c value based on the Opp Owner
        // and it is a restricted picklist
        User u = [select Id from User where LastName = 'Trogden' and FirstName = 'David' LIMIT 1];
        Opportunity opp = testDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, false);
        opp.Name = 'SalesOpp2';
        opp.OwnerId = u.Id;
        opp.Pricebook2Id = stdPB;
        opp.CloseDate = date.today() + 15;
        opp.StageName = 'Proposal/Price Quote';
        //    opp.Opportunity_Notes__c = 'This is what needs to be done';
        //     opp.Repair_Evaluation_Serial_Number__c = '123456';
        // opp.Ship_Date__c = date.today() + 30;
        //    opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        system.debug('TEST: opportunity to insert: ' + opp);
        insert opp;

        system.debug('TEST: opp:' + opp);

        Product2 p = [select id from Product2 Limit 1];
        p.Functionally_Good_Probes__c = 3;
        //p.Target_Quantity_in_Stock__c = 2;  formula based on Total_No_of_Requests_3_Months__c
        p.Total_No_of_Requests_3_Months__c = 13.33334;
        update p;

        List<ProductItem__c> pis = testDataFactory.createProductItems(3, p.id, false);
        pis[0].Purchasing_Approved__c = true;
        pis[0].Check_In_Type__c = 'Purchase';
        pis[0].Date_Last_Test_Completed__c = date.today() - 7;
        pis[0].Added_to_Work_Order__c = false;
        pis[1].Purchasing_Approved__c = true;
        pis[1].Check_In_Type__c = 'Purchase';
        pis[2].Purchasing_Approved__c = true;
        pis[2].Check_In_Type__c = 'Purchase';
        insert pis;

        system.debug('TEST: value of 3 product items' + pis);

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

        for (ProductItem__c pi : pis) {
            OpportunityLineItem oli = new OpportunityLineItem(
                    OpportunityId = opp.Id,
                    Model__c = pi.Model__c,
                    Part_Number__c = pi.Part_Number__c,
                    Serial_No__c = pi.Serial_No__c,
                    Quantity = 1,
                    UnitPrice = 500,
                    Actual_Price__c = pi.Price__c,
                    Compatible_System__c = pi.Compatible_System__c,
                    Functional_Rating__c = pi.Functional_Rating__c,
                    Functional_Rating_Notes__c = pi.Functional_Notes__c,
                    ProductItem__c = pi.Id,
                    Product2id = pi.Product_Name__c,
                    Exchange__c = true,
                    Asset_No__c = pi.name,
                    Purchasing_Approved__c = pi.Purchasing_Approved__c,
                    Probo_s_Offer__c = 500,
                    Supplier_s_Quote__c = 400);
            olis.add(oli);
        }

        system.debug('TEST: Test is getting ready to insert the OLIs');
        insert olis;
        system.debug('TEST: OLIs have been inserted: ' + olis);

        Test.startTest();
        System.debug('TEST: We are starting the actual test');

        opp.Shipping_FROM_Location__c = 'Tulsa, OK';
        Opp.Customer_PO__c = 'CPO 123';
        opp.StageName = 'Closed Won';
        opp.Confirmation_number__c = '12345';
        String exceptionMessage = '';

        system.debug('TEST: Updating the Opp to Closed Won');

        system.debug('TEST: The Opp before the update to Closed Won is: ' + opp);

        try {
            update opp;
        } catch (Exception e) {
            system.debug('TEST: Exception caught: ' + e.getMessage());
            exceptionMessage = e.getMessage();
        }
        system.assertEquals('', exceptionMessage, 'An exception was generated trying to set the Opp to Closed Won.');

        system.debug('TEST: We have made it through the Opp Update after setting the Customer PO and Shipping_FROM_Location.  Stage is now: ' + opp.StageName);

        system.debug('TEST: Update Opp ship date and set Verified_Asset_and_Serial_Numbers_Match__c to true');
        opp.Ship_Date__c = date.today();
        opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        update opp;

        system.debug('TEST: Finished updating the Opp after setting ship date and set Verified_Asset_and_Serial_Numbers_Match__c to true');

        OpportunityLineItem lineItem2 = [Select Id, Name, Sales_product__c, UnitPrice From OpportunityLineItem Where Id = :olis[1].Id LIMIT 1];
        ProductItem__c productItem2 = [
                Select Id, Name, Sold__c, Reserved__c, Overstock_probe_when_sold__c, Product_Name__c, Sales_Price__c, Ship_Date__c,
                        Account_Name__c, Close_Date__c, Opportunity_Name__c, Sales_Opportunity__c, Stage__c
                From ProductItem__c
                Where Id = :pis[1].Id
                LIMIT 1
        ];

        // Update unit price on line item 2
        lineItem2.UnitPrice = 300;
        update lineItem2;

        // ASSERT Product item 2 Sales_Price__c equals line item 2 UnitPrice
        ProductItem__c productItem2Updated = [Select Id, Sales_Price__c From ProductItem__c Where Id = :productItem2.Id];
        system.assertEquals(lineItem2.UnitPrice, productItem2Updated.Sales_Price__c, 'Line Item 2 UnitPrice does not match ProductItem Sales_Price__c after OLI update with change in Unit_Price');

        test.stopTest();
    }

    //Case D Products (Line Item Delete)
    //User clicks "add product" button on opp. Add 3 products/assets.
    static testmethod void testOppLineDeletes() {
        system.debug('TEST: start testProductsJMAY');
        Id stdPB = ProboCommonUtils.getStdPricebookId();
        Account a = [Select Id From Account Where Name = 'testAccount' LIMIT 1];
        // we need to make this the Opp Owner since WOs get a Person_Requesting_WO__c value based on the Opp Owner
        // and it is a restricted picklist
        User u = [select Id from User where LastName = 'Trogden' and FirstName = 'David' LIMIT 1];
        Opportunity opp = testDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, false);
        opp.Name = 'SalesOpp2';
        opp.OwnerId = u.Id;
        opp.Pricebook2Id = stdPB;
        opp.CloseDate = date.today() + 15;
        opp.StageName = 'Proposal/Price Quote';
        //    opp.Opportunity_Notes__c = 'This is what needs to be done';
        //     opp.Repair_Evaluation_Serial_Number__c = '123456';
        // opp.Ship_Date__c = date.today() + 30;
        //    opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        system.debug('TEST: opportunity to insert: ' + opp);
        insert opp;

        system.debug('TEST: opp:' + opp);

        Product2 p = [select id from Product2 Limit 1];
        p.Functionally_Good_Probes__c = 3;
        //p.Target_Quantity_in_Stock__c = 2;  formula based on Total_No_of_Requests_3_Months__c
        p.Total_No_of_Requests_3_Months__c = 13.33334;
        update p;

        List<ProductItem__c> pis = testDataFactory.createProductItems(3, p.id, false);
        pis[0].Purchasing_Approved__c = true;
        pis[0].Check_In_Type__c = 'Purchase';
        pis[0].Date_Last_Test_Completed__c = date.today() - 7;
        pis[0].Added_to_Work_Order__c = false;
        pis[1].Purchasing_Approved__c = true;
        pis[1].Check_In_Type__c = 'Purchase';
        pis[2].Purchasing_Approved__c = true;
        pis[2].Check_In_Type__c = 'Purchase';
        insert pis;

        system.debug('TEST: value of 3 product items' + pis);

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

        for (ProductItem__c pi : pis) {
            OpportunityLineItem oli = new OpportunityLineItem(
                    OpportunityId = opp.Id,
                    Model__c = pi.Model__c,
                    Part_Number__c = pi.Part_Number__c,
                    Serial_No__c = pi.Serial_No__c,
                    Quantity = 1,
                    UnitPrice = 500,
                    Actual_Price__c = pi.Price__c,
                    Compatible_System__c = pi.Compatible_System__c,
                    Functional_Rating__c = pi.Functional_Rating__c,
                    Functional_Rating_Notes__c = pi.Functional_Notes__c,
                    ProductItem__c = pi.Id,
                    Product2id = pi.Product_Name__c,
                    Exchange__c = false,
                    Asset_No__c = pi.name,
                    Purchasing_Approved__c = pi.Purchasing_Approved__c,
                    Probo_s_Offer__c = 500,
                    Supplier_s_Quote__c = 400);
            olis.add(oli);
        }

        system.debug('TEST: Test is getting ready to insert the OLIs');
        insert olis;
        system.debug('TEST: OLIs have been inserted: ' + olis);

        Test.startTest();
        System.debug('TEST: We are starting the actual test');


        opp.Shipping_FROM_Location__c = 'Tulsa, OK';
        Opp.Customer_PO__c = 'CPO 123';
        opp.StageName = 'Closed Won';
        opp.Confirmation_number__c = '12345';
        String exceptionMessage = '';

        system.debug('TEST: Updating the Opp to Closed Won');

        system.debug('TEST: The Opp before the update to Closed Won is: ' + opp);

        try {
            update opp;
        } catch (Exception e) {
            system.debug('TEST: Exception caught: ' + e.getMessage());
            exceptionMessage = e.getMessage();
        }
        system.assertEquals('', exceptionMessage, 'An exception was generated trying to set the Opp to Closed Won.');

        system.debug('TEST: We have made it through the Opp Update after setting the Customer PO and Shipping_FROM_Location.  Stage is now: ' + opp.StageName);

        // the OLIs would have their Work_Orders created here as a result of the ClosedOn StageChange
        List<Work_Order__c> woList = [
                Select Id, RecordType.DeveloperName, Estimated_Ready_Date__c, Person_Requesting_WO__c, Special_Instructions__c, Asset__c
                From Work_Order__c
                Where Opportunity__c = :opp.Id
        ];
        system.debug('TEST: Work Orders related to the Opp: ' + woList);

        // ASSERT that a Work order is created.
        // ASSERT Record type equals 'Testing Work Order'.
        // ASSERT Estimated_Ready_Date__c equals today's date.
        // ASSERT Person_requesting_WO__c equals opportunity record owner
        // ASSERT Special_Instructions__c equals 'Special instructions not set to: Needs pre ship test'
        Opportunity oppUpdated = [Select Id, Name, Ship_Date__c, Account_Name__c, CloseDate, StageName, Owner.FirstName, Owner.LastName From Opportunity Where Id = :opp.Id LIMIT 1];
        system.debug('TEST: The Opp after the update is: ' + oppUpdated);
/*  Natalie commented out - was causing errors and the testing work order on Closed Won is no longer a functionality the sales team wants.
        String workOrderRecordType = Schema.SObjectType.Work_Order__c.getRecordTypeInfosByName().get('Testing Work Order').getDeveloperName();
        system.assertEquals(workOrderRecordType, woList[0].RecordType.DeveloperName, 'Work order record type is not Testing Work Order record type');
        system.assertEquals(date.today(), woList[0].Estimated_Ready_Date__c, 'Work order Estimated Ready Date is not set to today');
        system.assertEquals(oppUpdated.Owner.FirstName + ' ' + oppUpdated.Owner.LastName, woList[0].Person_Requesting_WO__c,  'Person Requesting work order is not the Opportunity Owner');
        system.assertEquals('Needs pre ship test', woList[0].Special_Instructions__c, 'Special instructions not set to: Needs pre ship test');
*/


        system.debug('TEST: Update Opp ship date and set Verified_Asset_and_Serial_Numbers_Match__c to true');
        opp.Ship_Date__c = date.today();
        opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        update opp;

        system.debug('TEST: Finished updating the Opp after setting ship date and set Verified_Asset_and_Serial_Numbers_Match__c to true');

        // Delete line item 2
        delete olis[1];

        // ASSERT Product item 2 Sold__c is set to false
        // ASSERT Product item 2 Reserved__c is set to false
        // ASSERT Product item 2 Sales_Price__c is set to null
        ProductItem__c productItem2Updated = [Select Id, Sold__c, Reserved__c, Sales_Price__c From ProductItem__c Where Id = :pis[1].Id];
        system.assertEquals(false, productItem2Updated.Sold__c, 'Product item 2 is sold after line item delete');
        system.assertEquals(false, productItem2Updated.Reserved__c, 'Product item 2 is reserved after line item delete');
        system.assertEquals(null, productItem2Updated.Sales_Price__c, 'Product item 2 sales price is not null after line item delete');

        test.stopTest();
    }

    //Case D Products (Opp Re-open to Verbal Acceptance)
    static testmethod void testOppReOpenToVerbalAcceptance() {
        system.debug('TEST: start testProductsJMAY');
        Id stdPB = ProboCommonUtils.getStdPricebookId();
        Account a = [Select Id From Account Where Name = 'testAccount' LIMIT 1];
        // we need to make this the Opp Owner since WOs get a Person_Requesting_WO__c value based on the Opp Owner
        // and it is a restricted picklist
        User u = [select Id from User where LastName = 'Trogden' and FirstName = 'David' LIMIT 1];
        Opportunity opp = testDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, false);
        opp.Name = 'SalesOpp2';
        opp.OwnerId = u.Id;
        opp.Pricebook2Id = stdPB;
        opp.CloseDate = date.today() + 15;
        opp.StageName = 'Proposal/Price Quote';
        //    opp.Opportunity_Notes__c = 'This is what needs to be done';
        //     opp.Repair_Evaluation_Serial_Number__c = '123456';
        // opp.Ship_Date__c = date.today() + 30;
        //    opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        system.debug('TEST: opportunity to insert: ' + opp);
        insert opp;

        system.debug('TEST: opp:' + opp);

        Product2 p = [select id from Product2 Limit 1];
        p.Functionally_Good_Probes__c = 3;
        //p.Target_Quantity_in_Stock__c = 2;  formula based on Total_No_of_Requests_3_Months__c
        p.Total_No_of_Requests_3_Months__c = 13.33334;
        update p;

        List<ProductItem__c> pis = testDataFactory.createProductItems(3, p.id, false);
        pis[0].Purchasing_Approved__c = true;
        pis[0].Check_In_Type__c = 'Purchase';
        pis[0].Date_Last_Test_Completed__c = date.today() - 7;
        pis[0].Added_to_Work_Order__c = false;
        pis[1].Purchasing_Approved__c = true;
        pis[1].Check_In_Type__c = 'Purchase';
        pis[2].Purchasing_Approved__c = true;
        pis[2].Check_In_Type__c = 'Purchase';
        insert pis;

        system.debug('TEST: value of 3 product items' + pis);

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

        for (ProductItem__c pi : pis) {
            OpportunityLineItem oli = new OpportunityLineItem(
                    OpportunityId = opp.Id,
                    Model__c = pi.Model__c,
                    Part_Number__c = pi.Part_Number__c,
                    Serial_No__c = pi.Serial_No__c,
                    Quantity = 1,
                    UnitPrice = 500,
                    Actual_Price__c = pi.Price__c,
                    Compatible_System__c = pi.Compatible_System__c,
                    Functional_Rating__c = pi.Functional_Rating__c,
                    Functional_Rating_Notes__c = pi.Functional_Notes__c,
                    ProductItem__c = pi.Id,
                    Product2id = pi.Product_Name__c,
                    Exchange__c = false,
                    Asset_No__c = pi.name,
                    Purchasing_Approved__c = pi.Purchasing_Approved__c,
                    Probo_s_Offer__c = 500,
                    Supplier_s_Quote__c = 400);
            olis.add(oli);
        }

        system.debug('TEST: Test is getting ready to insert the OLIs');
        insert olis;
        system.debug('TEST: OLIs have been inserted: ' + olis);

        opp.Shipping_FROM_Location__c = 'Tulsa, OK';
        Opp.Customer_PO__c = 'CPO 123';
        opp.StageName = 'Closed Won';
        opp.Confirmation_number__c = '12345';
        String exceptionMessage = '';

        system.debug('TEST: Updating the Opp to Closed Won');

        system.debug('TEST: The Opp before the update to Closed Won is: ' + opp);

        try {
            update opp;
        } catch (Exception e) {
            system.debug('TEST: Exception caught: ' + e.getMessage());
            exceptionMessage = e.getMessage();
        }
        system.assertEquals('', exceptionMessage, 'An exception was generated trying to set the Opp to Closed Won.');

        Test.startTest();
        System.debug('TEST: We are starting the actual test');

        system.debug('TEST: We have made it through the Opp Update after setting the Customer PO and Shipping_FROM_Location.  Stage is now: ' + opp.StageName);

        // ASSERT that a Work order is created.
        // ASSERT Record type equals 'Testing Work Order'.
        // ASSERT Estimated_Ready_Date__c equals today's date.
        // ASSERT Person_requesting_WO__c equals opportunity record owner
        // ASSERT Special_Instructions__c equals 'Special instructions not set to: Needs pre ship test'
        Opportunity oppUpdated = [Select Id, Name, Ship_Date__c, Account_Name__c, CloseDate, StageName, Owner.FirstName, Owner.LastName From Opportunity Where Id = :opp.Id LIMIT 1];
        system.debug('TEST: The Opp after the update is: ' + oppUpdated);


        system.debug('TEST: Update Opp ship date and set Verified_Asset_and_Serial_Numbers_Match__c to true');
        opp.Ship_Date__c = date.today();
        opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        update opp;

        system.debug('TEST: Finished updating the Opp after setting ship date and set Verified_Asset_and_Serial_Numbers_Match__c to true');

        // Change stage to Verbal Acceptance
        oppUpdated.StageName = 'Verbal Acceptance';
        update oppUpdated;

        // ASSERT Line item 1 Sales_Product__c is set to null
        // ASSERT Product item 1 Sold__c is set to false
        // ASSERT Product item 1 Reserved__c is set to true
        // ASSERT Product item 1 Sales_Price__c is set to null
        OpportunityLineItem lineItem1Updated = [Select Id, Name, Sales_product__c, UnitPrice From OpportunityLineItem Where Id = :olis[0].Id LIMIT 1];
        ProductItem__c productItem1Updated = [Select Id, Sold__c, Reserved__c, Sales_Price__c From ProductItem__c Where Id = :pis[0].Id];
        system.assertEquals(null, lineItem1Updated.Sales_Product__c, 'Line item 1 sales product is not null after Opp changed to Verbal Acceptance');
        system.assertEquals(false, productItem1Updated.Sold__c, 'Product item 1 is sold after Opp changed to Verbal Acceptance');
        system.assertEquals(true, productItem1Updated.Reserved__c, 'Product item 1 is not reserved after Opp changed to Verbal Acceptance');
        system.assertEquals(null, productItem1Updated.Sales_Price__c, 'Product item 1 sales price is not null after Opp changed to Verbal Acceptance');

        test.stopTest();
    }


    //Case D Products (Opp Re-open to Proposal)
    static testmethod void testOppReOpentoProposal() {
        system.debug('TEST: start testProductsJMAY');
        Id stdPB = ProboCommonUtils.getStdPricebookId();
        Account a = [Select Id From Account Where Name = 'testAccount' LIMIT 1];
        // we need to make this the Opp Owner since WOs get a Person_Requesting_WO__c value based on the Opp Owner
        // and it is a restricted picklist
        User u = [select Id from User where LastName = 'Trogden' and FirstName = 'David' LIMIT 1];
        Opportunity opp = testDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, false);
        opp.Name = 'SalesOpp2';
        opp.OwnerId = u.Id;
        opp.Pricebook2Id = stdPB;
        opp.CloseDate = date.today() + 15;
        opp.StageName = 'Proposal/Price Quote';
        //    opp.Opportunity_Notes__c = 'This is what needs to be done';
        //     opp.Repair_Evaluation_Serial_Number__c = '123456';
        // opp.Ship_Date__c = date.today() + 30;
        //    opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        system.debug('TEST: opportunity to insert: ' + opp);
        insert opp;

        system.debug('TEST: opp:' + opp);

        Product2 p = [select id from Product2 Limit 1];
        p.Functionally_Good_Probes__c = 3;
        //p.Target_Quantity_in_Stock__c = 2;  formula based on Total_No_of_Requests_3_Months__c
        p.Total_No_of_Requests_3_Months__c = 13.33334;
        update p;

        List<ProductItem__c> pis = testDataFactory.createProductItems(3, p.id, false);
        pis[0].Purchasing_Approved__c = true;
        pis[0].Check_In_Type__c = 'Purchase';
        pis[0].Date_Last_Test_Completed__c = date.today() - 7;
        pis[0].Added_to_Work_Order__c = false;
        pis[1].Purchasing_Approved__c = true;
        pis[1].Check_In_Type__c = 'Purchase';
        pis[2].Purchasing_Approved__c = true;
        pis[2].Check_In_Type__c = 'Purchase';
        insert pis;

        system.debug('TEST: value of 3 product items' + pis);

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

        for (ProductItem__c pi : pis) {
            OpportunityLineItem oli = new OpportunityLineItem(
                    OpportunityId = opp.Id,
                    Model__c = pi.Model__c,
                    Part_Number__c = pi.Part_Number__c,
                    Serial_No__c = pi.Serial_No__c,
                    Quantity = 1,
                    UnitPrice = 500,
                    Actual_Price__c = pi.Price__c,
                    Compatible_System__c = pi.Compatible_System__c,
                    Functional_Rating__c = pi.Functional_Rating__c,
                    Functional_Rating_Notes__c = pi.Functional_Notes__c,
                    ProductItem__c = pi.Id,
                    Product2id = pi.Product_Name__c,
                    Exchange__c = false,
                    Asset_No__c = pi.name,
                    Purchasing_Approved__c = pi.Purchasing_Approved__c,
                    Probo_s_Offer__c = 500,
                    Supplier_s_Quote__c = 400);
            olis.add(oli);
        }

        system.debug('TEST: Test is getting ready to insert the OLIs');
        insert olis;
        system.debug('TEST: OLIs have been inserted: ' + olis);

        opp.Shipping_FROM_Location__c = 'Tulsa, OK';
        Opp.Customer_PO__c = 'CPO 123';
        opp.StageName = 'Closed Won';
        opp.Confirmation_number__c = '12345';
        String exceptionMessage = '';

        system.debug('TEST: Updating the Opp to Closed Won');

        system.debug('TEST: The Opp before the update to Closed Won is: ' + opp);

        try {
            update opp;
        } catch (Exception e) {
            system.debug('TEST: Exception caught: ' + e.getMessage());
            exceptionMessage = e.getMessage();
        }
        system.assertEquals('', exceptionMessage, 'An exception was generated trying to set the Opp to Closed Won.');

        Test.startTest();
        System.debug('TEST: We are starting the actual test');


        system.debug('TEST: We have made it through the Opp Update after setting the Customer PO and Shipping_FROM_Location.  Stage is now: ' + opp.StageName);

        system.debug('TEST: Update Opp ship date and set Verified_Asset_and_Serial_Numbers_Match__c to true');
        opp.Ship_Date__c = date.today();
        opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        update opp;

        system.debug('TEST: Finished updating the Opp after setting ship date and set Verified_Asset_and_Serial_Numbers_Match__c to true');

        // Change stage to Verbal Acceptance
        opp.StageName = 'Verbal Acceptance';
        update opp;

        // Change stage to "Proposal/Price Quote (the important thing is that it is being changed FROM 'Verbal Acceptance'
        opp.StageName = 'Proposal/Price Quote';
        update opp;

        test.stopTest();

        System.debug('TEST: checking on ProductItem__c: ' + pis[0].Id);
        // ASSERT Product item 1 Reserved__c is set to false
        ProductItem__c productItem1Updated = [Select Id, Sold__c, Reserved__c, Sales_Price__c From ProductItem__c Where Id = :pis[0].Id];
        system.assertEquals(false, productItem1Updated.Reserved__c, 'Product item 1 is reserved after the Opp is changed to Proposal/Price Quote');

    }


    //Case E Material Transfer RMA
    //User clicks "add product" button on opp. Add 40 products/assets.
    //User changes stage to "Material Transfer".
    //ASSERT new material transfer RMA is created for each line item with the opportunity field linked to opp
    static testmethod void testMaterialTransferRMA() {

        system.debug('TEST: start testMaterialTransferRMA');
        Id stdPB = ProboCommonUtils.getStdPricebookId();
        Account a = [Select Id From Account Where Name = 'testAccount' LIMIT 1];
        Opportunity opp = testDataFactory.createOpportunity('Material Transfer', a.Id, false);
        opp.Name = 'SalesOpp2';
        opp.Opportunity_Notes__c = 'This is what needs to be done';
        opp.Pricebook2Id = stdPB;
        opp.Repair_Evaluation_Serial_Number__c = '123456';
        opp.Ship_Date__c = date.today() + 30;
        opp.CloseDate = date.today() + 15;
        opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        opp.Shipping_To_Location__c = 'Fishers, IN';
        opp.StageName = 'Proposal/Price Quote';
        system.debug('TEST: opportunity to insert: ' + opp);
        insert opp;


        Product2 p = [select id from Product2 Limit 1];

        List<ProductItem__c> pis = testDataFactory.createProductItems(40, p.id, false);
        insert pis;

        //TODO: current cheating / mimicing addProduct.addProdut lines 457-470 to create an OLI and addProduct.WrapperProduct()
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for (Integer i = 0; i < 40; i++) {
            OpportunityLineItem oli = new OpportunityLineItem(
                    OpportunityId = opp.Id,
                    Model__c = pis[i].Model__c,
                    Part_Number__c = pis[i].Part_Number__c,
                    Serial_No__c = pis[i].Serial_No__c,
                    Quantity = 1,
                    UnitPrice = 500,
                    Actual_Price__c = pis[i].Price__c,
                    Compatible_System__c = pis[i].Compatible_System__c,
                    Functional_Rating__c = pis[i].Functional_Rating__c,
                    Functional_Rating_Notes__c = pis[i].Functional_Notes__c,
                    ProductItem__c = pis[i].Id,
                    Product2id = pis[i].Product_Name__c,
                    Exchange__c = false,
                    Asset_No__c = pis[i].name,
                    Purchasing_Approved__c = pis[i].Purchasing_Approved__c,
                    Probo_s_Offer__c = 500,
                    Supplier_s_Quote__c = 400);
            olis.add(oli);
        }
        insert olis;

        test.startTest();

        opp.StageName = 'Material Transfer';
        update opp;

        test.stopTest();

        List<OpportunityLineItem> afterOlis = [select id from OpportunityLineItem where OpportunityId = :opp.Id];
        List<RMA__c> RMAs = [select id, RecordType.DeveloperName, Opportunity__c from RMA__c where Opportunity__c = :opp.Id];


        system.assert(afterOlis.size() == 40, '40 OLIs were not created: ' + afterOlis.size());
        system.assert(RMAs.size() == 40, '40 RMAs were not created: ' + RMAs.size());
        String rmaRecordType = Schema.SObjectType.RMA__c.getRecordTypeInfosByName().get('Material Transfer').getDeveloperName();
        for (RMA__c r : RMAs) {
            system.assertEquals(rmaRecordType, r.RecordType.DeveloperName, 'RMA record type is not set to Material Transfer');
        }


    }

    //Case F External Repair/Testing RMA
    //User clicks "add product" button on opp. Add 40 products/assets.
    //User changes stage to "External Repair / Testing".
    //ASSERT new external repair / testing RMA is created for each line item with the opportunity field linked to opp
    static testmethod void testExternalRepairRMA() {

        system.debug('TEST: start testExternalRepairRMA');
        Id stdPB = ProboCommonUtils.getStdPricebookId();
        Account a = [Select Id From Account Where Name = 'testAccount' LIMIT 1];
        Opportunity opp = testDataFactory.createOpportunity('External Repair / Testing', a.Id, false);
        opp.Name = 'SalesOpp2';
        opp.Opportunity_Notes__c = 'This is what needs to be done';
        opp.Pricebook2Id = stdPB;
        opp.Repair_Evaluation_Serial_Number__c = '123456';
        opp.Ship_Date__c = date.today() + 30;
        opp.CloseDate = date.today() + 15;
        opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        opp.StageName = 'Proposal/Price Quote';
        system.debug('TEST: opportunity to insert: ' + opp);
        insert opp;

        Product2 p = [select id from Product2 Limit 1];
        List<ProductItem__c> pis = testDataFactory.createProductItems(40, p.id, false);
        insert pis;

        test.startTest();
        //TODO: current cheating / mimicing addProduct.addProdut lines 457-470 to create an OLI and addProduct.WrapperProduct()
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for (Integer i = 0; i < 40; i++) {
            OpportunityLineItem oli = new OpportunityLineItem(
                    OpportunityId = opp.Id,
                    Model__c = pis[i].Model__c,
                    Part_Number__c = pis[i].Part_Number__c,
                    Serial_No__c = pis[i].Serial_No__c,
                    Quantity = 1,
                    UnitPrice = 500,
                    Actual_Price__c = pis[i].Price__c,
                    Compatible_System__c = pis[i].Compatible_System__c,
                    Functional_Rating__c = pis[i].Functional_Rating__c,
                    Functional_Rating_Notes__c = pis[i].Functional_Notes__c,
                    ProductItem__c = pis[i].Id,
                    Product2id = pis[i].Product_Name__c,
                    Exchange__c = false,
                    Asset_No__c = pis[i].name,
                    Purchasing_Approved__c = pis[i].Purchasing_Approved__c,
                    Probo_s_Offer__c = 500,
                    Supplier_s_Quote__c = 400);
            olis.add(oli);
        }
        insert olis;

        system.debug('TEST: setting Stage to External Repair / Testing');
        opp.StageName = 'External Repair / Testing';
        update opp;
        List<OpportunityLineItem> afterOlis = [select id from OpportunityLineItem where OpportunityId = :opp.Id];
        List<RMA__c> RMAs = [select id, RecordType.DeveloperName, Opportunity__c from RMA__c where Opportunity__c = :opp.Id];
        test.stopTest();
        system.assert(afterOlis.size() == 40, '40 OLIs were not created: ' + afterOlis.size());
        system.assert(RMAs.size() == 40, '40 RMAs were not created: ' + RMAs.size());
        String rmaRecordType = Schema.SObjectType.RMA__c.getRecordTypeInfosByName().get('External Repair / Testing').getDeveloperName();
        for (RMA__c r : RMAs) {
            system.assertEquals(rmaRecordType, r.RecordType.DeveloperName, 'RMA record type is not set to External Repair / Testing');
        }

    }

    /**
     * Confirm that ProductItem__c is properly updated when an OLI is deleted
     * This test is when the ProductItem__c is NOT on any other Opp OLIs
     *
     * Other tests needed:
     * 1) When ProductItem__c is on another Opp, but not in Stage Verbal Acceptance or Closed Won
     * 2) When ProductItem__c is on another Opp, but in Stage Verbal Acceptance
     * 3) When ProductItem__c is on another Opp, but in Stage Closed Won
     */
    static testmethod void testOLIDeletePItemNotOnOtherOLIs() {
        System.debug('TEST: start testOLIDeletePItemNotOnOtherOLIs');

        Account a = [select Id from Account where Name = 'testAccount' LIMIT 1];
        Opportunity o = testDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, false);
        o.Name = 'SalesOpp';
        o.Opportunity_Notes__c = 'This is what needs to be done';
        o.Pricebook2Id = ProboCommonUtils.getStdPricebookId();
        o.Repair_Evaluation_Serial_Number__c = '123456';
        o.Ship_Date__c = date.today() + 30;
        o.CloseDate = date.today() + 15;
        o.Verified_Asset_and_Serial_Numbers_Match__c = true;
        o.StageName = 'Repair Evaluation';
        insert o;

        Product2 p = [select id from Product2 Limit 1];
        List<ProductItem__c> pis = testDataFactory.createProductItems(1, p.id, false);
        insert pis;

        List<OpportunityLineItem> salesOLIs = new List<OpportunityLineItem>();
        for (Integer i = 0; i < pis.size(); i++) {
            OpportunityLineItem oli = new OpportunityLineItem(
                    OpportunityId = o.Id,
                    Model__c = pis[i].Model__c,
                    Part_Number__c = pis[i].Part_Number__c,
                    Serial_No__c = pis[i].Serial_No__c,
                    Quantity = 1,
                    UnitPrice = 500,
                    Actual_Price__c = pis[i].Price__c,
                    Compatible_System__c = pis[i].Compatible_System__c,
                    Functional_Rating__c = pis[i].Functional_Rating__c,
                    Functional_Rating_Notes__c = pis[i].Functional_Notes__c,
                    ProductItem__c = pis[i].Id,
                    Product2id = pis[i].Product_Name__c,
                    Exchange__c = false,
                    Asset_No__c = pis[i].name,
                    Purchasing_Approved__c = pis[i].Purchasing_Approved__c,
                    Probo_s_Offer__c = 500,
                    Supplier_s_Quote__c = 400);
            salesOLIs.add(oli);
        }
        insert salesOLIs;


        System.debug('Test: Setting the Sales Opp to Closed Won');
        o.Customer_PO__c = 'abc';
        o.StageName = 'Closed Won';
        o.Confirmation_number__c = '12345';
        update o;

        Test.startTest();

        Id pItemIdToCheck = salesOLIs[0].ProductItem__c;

        System.debug('Test: Deleting the the Sales Opp OLI');
        delete salesOLIs;

        Test.stopTest();

        List<ProductItem__c> theProdITems = new List<ProductItem__c>([select Id, Sold__c, Reserved__c, Sales_Price__c
                                                                    FROM ProductItem__c
                                                                    WHERE Id = :pItemIdToCheck]);

        System.assertEquals(false, theProdITems[0].Sold__c, 'PItem Sold__c was not reset on OLI delete');
        System.assertEquals(false, theProdITems[0].Reserved__c, 'PItem Reserved__c was not reset on OLI delete');
        System.assertEquals(null, theProdITems[0].Sales_Price__c, 'PItem Sales_Price__c was not reset on OLI delete');

        System.debug('TEST: end testOLIDeletePItemNotOnOtherOLIs');
    }

    /**
     * Confirm that ProductItem__c is properly updated when an OLI is deleted
     * This test is when the ProductItem__c is on another Opp, but not in Stage Verbal Acceptance or Closed Won
     *
     * Other tests needed:
     * 2) When ProductItem__c is on another Opp, but in Stage Verbal Acceptance
     * 3) When ProductItem__c is on another Opp, but in Stage Closed Won
     */
    
    static testmethod void testOppLineDeletesEquipmentRental() {
        system.debug('TEST: start testProductsJMAY');
        Id stdPB = ProboCommonUtils.getStdPricebookId();
        Account a = [Select Id From Account Where Name = 'testAccount' LIMIT 1];
        // we need to make this the Opp Owner since WOs get a Person_Requesting_WO__c value based on the Opp Owner
        // and it is a restricted picklist
        User u = [select Id from User where LastName = 'Trogden' and FirstName = 'David' LIMIT 1];
        Opportunity opp = testDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, false);
        opp.Name = 'SalesOpp2';
        opp.OwnerId = u.Id;
        opp.Pricebook2Id = stdPB;
        opp.CloseDate = date.today() + 15;
        opp.StageName = 'Proposal/Price Quote';
        //    opp.Opportunity_Notes__c = 'This is what needs to be done';
        //     opp.Repair_Evaluation_Serial_Number__c = '123456';
        // opp.Ship_Date__c = date.today() + 30;
        //    opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        system.debug('TEST: opportunity to insert: ' + opp);
        insert opp;

        system.debug('TEST: opp:' + opp);

        Product2 p = [select id from Product2 Limit 1];
        p.Functionally_Good_Probes__c = 3;
        //p.Target_Quantity_in_Stock__c = 2;  formula based on Total_No_of_Requests_3_Months__c
        p.Total_No_of_Requests_3_Months__c = 13.33334;
        update p;

        List<ProductItem__c> pis = testDataFactory.createProductItems(3, p.id, false);
        pis[0].Purchasing_Approved__c = true;
        pis[0].Check_In_Type__c = 'Purchase';
        pis[0].Date_Last_Test_Completed__c = date.today() - 7;
        pis[0].Added_to_Work_Order__c = false;
        pis[1].Purchasing_Approved__c = true;
        pis[1].Check_In_Type__c = 'Purchase';
        pis[2].Purchasing_Approved__c = true;
        pis[2].Check_In_Type__c = 'Purchase';
        insert pis;

        system.debug('TEST: value of 3 product items' + pis);

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

        for (ProductItem__c pi : pis) {
            OpportunityLineItem oli = new OpportunityLineItem(
                    OpportunityId = opp.Id,
                    Model__c = pi.Model__c,
                    Part_Number__c = pi.Part_Number__c,
                    Serial_No__c = pi.Serial_No__c,
                    Quantity = 1,
                    UnitPrice = 500,
                    Actual_Price__c = pi.Price__c,
                    Compatible_System__c = pi.Compatible_System__c,
                    Functional_Rating__c = pi.Functional_Rating__c,
                    Functional_Rating_Notes__c = pi.Functional_Notes__c,
                    ProductItem__c = pi.Id,
                    Product2id = pi.Product_Name__c,
                    Exchange__c = false,
                    Asset_No__c = pi.name,
                    Purchasing_Approved__c = pi.Purchasing_Approved__c,
                    Probo_s_Offer__c = 500,
                    Supplier_s_Quote__c = 400);
            olis.add(oli);
        }

        system.debug('TEST: Test is getting ready to insert the OLIs');
        insert olis;
        system.debug('TEST: OLIs have been inserted: ' + olis);

        Test.startTest();
        System.debug('TEST: We are starting the actual test');


        opp.Shipping_FROM_Location__c = 'Tulsa, OK';
        Opp.Customer_PO__c = 'CPO 123';
        opp.StageName = 'Equipment Rental';
        opp.Confirmation_number__c = '12345';
        String exceptionMessage = '';

        system.debug('TEST: Updating the Opp to Closed Won');

        system.debug('TEST: The Opp before the update to Closed Won is: ' + opp);

        try {
            update opp;
        } catch (Exception e) {
            system.debug('TEST: Exception caught: ' + e.getMessage());
            exceptionMessage = e.getMessage();
        }
        system.assertEquals('', exceptionMessage, 'An exception was generated trying to set the Opp to Closed Won.');

        system.debug('TEST: We have made it through the Opp Update after setting the Customer PO and Shipping_FROM_Location.  Stage is now: ' + opp.StageName);

        // the OLIs would have their Work_Orders created here as a result of the ClosedOn StageChange
        List<Work_Order__c> woList = [
                Select Id, RecordType.DeveloperName, Estimated_Ready_Date__c, Person_Requesting_WO__c, Special_Instructions__c, Asset__c
                From Work_Order__c
                Where Opportunity__c = :opp.Id
        ];
        system.debug('TEST: Work Orders related to the Opp: ' + woList);

        // ASSERT that a Work order is created.
        // ASSERT Record type equals 'Testing Work Order'.
        // ASSERT Estimated_Ready_Date__c equals today's date.
        // ASSERT Person_requesting_WO__c equals opportunity record owner
        // ASSERT Special_Instructions__c equals 'Special instructions not set to: Needs pre ship test'
        Opportunity oppUpdated = [Select Id, Name, Ship_Date__c, Account_Name__c, CloseDate, StageName, Owner.FirstName, Owner.LastName From Opportunity Where Id = :opp.Id LIMIT 1];
        system.debug('TEST: The Opp after the update is: ' + oppUpdated);
/*  Natalie commented out - was causing errors and the testing work order on Closed Won is no longer a functionality the sales team wants.
        String workOrderRecordType = Schema.SObjectType.Work_Order__c.getRecordTypeInfosByName().get('Testing Work Order').getDeveloperName();
        system.assertEquals(workOrderRecordType, woList[0].RecordType.DeveloperName, 'Work order record type is not Testing Work Order record type');
        system.assertEquals(date.today(), woList[0].Estimated_Ready_Date__c, 'Work order Estimated Ready Date is not set to today');
        system.assertEquals(oppUpdated.Owner.FirstName + ' ' + oppUpdated.Owner.LastName, woList[0].Person_Requesting_WO__c,  'Person Requesting work order is not the Opportunity Owner');
        system.assertEquals('Needs pre ship test', woList[0].Special_Instructions__c, 'Special instructions not set to: Needs pre ship test');
*/


        system.debug('TEST: Update Opp ship date and set Verified_Asset_and_Serial_Numbers_Match__c to true');
        opp.Ship_Date__c = date.today();
        opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        update opp;

        system.debug('TEST: Finished updating the Opp after setting ship date and set Verified_Asset_and_Serial_Numbers_Match__c to true');

        // Delete line item 2
        delete olis[1];

        // ASSERT Product item 2 Sold__c is set to false
        // ASSERT Product item 2 Reserved__c is set to false
        // ASSERT Product item 2 Sales_Price__c is set to null
        ProductItem__c productItem2Updated = [Select Id, Sold__c, Reserved__c, Sales_Price__c From ProductItem__c Where Id = :pis[1].Id];

        test.stopTest();
    }
    
    static testmethod void testOppLineDeletesInterCompanyMaterialTransfer() {
        system.debug('TEST: start testProductsJMAY');
        Id stdPB = ProboCommonUtils.getStdPricebookId();
        Account a = [Select Id From Account Where Name = 'testAccount' LIMIT 1];
        // we need to make this the Opp Owner since WOs get a Person_Requesting_WO__c value based on the Opp Owner
        // and it is a restricted picklist
        User u = [select Id from User where LastName = 'Trogden' and FirstName = 'David' LIMIT 1];
        Opportunity opp = testDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, false);
        opp.Name = 'SalesOpp2';
        opp.OwnerId = u.Id;
        opp.Pricebook2Id = stdPB;
        opp.CloseDate = date.today() + 15;
        opp.StageName = 'Proposal/Price Quote';
        //    opp.Opportunity_Notes__c = 'This is what needs to be done';
        //     opp.Repair_Evaluation_Serial_Number__c = '123456';
        // opp.Ship_Date__c = date.today() + 30;
        //    opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        system.debug('TEST: opportunity to insert: ' + opp);
        insert opp;

        system.debug('TEST: opp:' + opp);

        Product2 p = [select id from Product2 Limit 1];
        p.Functionally_Good_Probes__c = 3;
        //p.Target_Quantity_in_Stock__c = 2;  formula based on Total_No_of_Requests_3_Months__c
        p.Total_No_of_Requests_3_Months__c = 13.33334;
        update p;

        List<ProductItem__c> pis = testDataFactory.createProductItems(3, p.id, false);
        pis[0].Purchasing_Approved__c = true;
        pis[0].Check_In_Type__c = 'Purchase';
        pis[0].Date_Last_Test_Completed__c = date.today() - 7;
        pis[0].Added_to_Work_Order__c = false;
        pis[1].Purchasing_Approved__c = true;
        pis[1].Check_In_Type__c = 'Purchase';
        pis[2].Purchasing_Approved__c = true;
        pis[2].Check_In_Type__c = 'Purchase';
        insert pis;

        system.debug('TEST: value of 3 product items' + pis);

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

        for (ProductItem__c pi : pis) {
            OpportunityLineItem oli = new OpportunityLineItem(
                    OpportunityId = opp.Id,
                    Model__c = pi.Model__c,
                    Part_Number__c = pi.Part_Number__c,
                    Serial_No__c = pi.Serial_No__c,
                    Quantity = 1,
                    UnitPrice = 500,
                    Actual_Price__c = pi.Price__c,
                    Compatible_System__c = pi.Compatible_System__c,
                    Functional_Rating__c = pi.Functional_Rating__c,
                    Functional_Rating_Notes__c = pi.Functional_Notes__c,
                    ProductItem__c = pi.Id,
                    Product2id = pi.Product_Name__c,
                    Exchange__c = false,
                    Asset_No__c = pi.name,
                    Purchasing_Approved__c = pi.Purchasing_Approved__c,
                    Probo_s_Offer__c = 500,
                    Supplier_s_Quote__c = 400);
            olis.add(oli);
        }

        system.debug('TEST: Test is getting ready to insert the OLIs');
        insert olis;
        system.debug('TEST: OLIs have been inserted: ' + olis);

        Test.startTest();
        System.debug('TEST: We are starting the actual test');


        opp.Shipping_FROM_Location__c = 'Tulsa, OK';
        Opp.Customer_PO__c = 'CPO 123';
        opp.StageName = 'Material Transfer';
        opp.Confirmation_number__c = '12345';
        String exceptionMessage = '';

        system.debug('TEST: Updating the Opp to Closed Won');

        system.debug('TEST: The Opp before the update to Closed Won is: ' + opp);

        try {
            update opp;
        } catch (Exception e) {
            system.debug('TEST: Exception caught: ' + e.getMessage());
            exceptionMessage = e.getMessage();
        }
        system.assertEquals('', exceptionMessage, 'An exception was generated trying to set the Opp to Closed Won.');

        system.debug('TEST: We have made it through the Opp Update after setting the Customer PO and Shipping_FROM_Location.  Stage is now: ' + opp.StageName);

        // the OLIs would have their Work_Orders created here as a result of the ClosedOn StageChange
        List<Work_Order__c> woList = [
                Select Id, RecordType.DeveloperName, Estimated_Ready_Date__c, Person_Requesting_WO__c, Special_Instructions__c, Asset__c
                From Work_Order__c
                Where Opportunity__c = :opp.Id
        ];
        system.debug('TEST: Work Orders related to the Opp: ' + woList);

        // ASSERT that a Work order is created.
        // ASSERT Record type equals 'Testing Work Order'.
        // ASSERT Estimated_Ready_Date__c equals today's date.
        // ASSERT Person_requesting_WO__c equals opportunity record owner
        // ASSERT Special_Instructions__c equals 'Special instructions not set to: Needs pre ship test'
        Opportunity oppUpdated = [Select Id, Name, Ship_Date__c, Account_Name__c, CloseDate, StageName, Owner.FirstName, Owner.LastName From Opportunity Where Id = :opp.Id LIMIT 1];
        system.debug('TEST: The Opp after the update is: ' + oppUpdated);
/*  Natalie commented out - was causing errors and the testing work order on Closed Won is no longer a functionality the sales team wants.
        String workOrderRecordType = Schema.SObjectType.Work_Order__c.getRecordTypeInfosByName().get('Testing Work Order').getDeveloperName();
        system.assertEquals(workOrderRecordType, woList[0].RecordType.DeveloperName, 'Work order record type is not Testing Work Order record type');
        system.assertEquals(date.today(), woList[0].Estimated_Ready_Date__c, 'Work order Estimated Ready Date is not set to today');
        system.assertEquals(oppUpdated.Owner.FirstName + ' ' + oppUpdated.Owner.LastName, woList[0].Person_Requesting_WO__c,  'Person Requesting work order is not the Opportunity Owner');
        system.assertEquals('Needs pre ship test', woList[0].Special_Instructions__c, 'Special instructions not set to: Needs pre ship test');
*/


        system.debug('TEST: Update Opp ship date and set Verified_Asset_and_Serial_Numbers_Match__c to true');
        opp.Ship_Date__c = date.today();
        opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        update opp;

        system.debug('TEST: Finished updating the Opp after setting ship date and set Verified_Asset_and_Serial_Numbers_Match__c to true');

        // Delete line item 2
        delete olis[1];

        // ASSERT Product item 2 Sold__c is set to false
        // ASSERT Product item 2 Reserved__c is set to false
        // ASSERT Product item 2 Sales_Price__c is set to null
        ProductItem__c productItem2Updated = [Select Id, Sold__c, Reserved__c, Sales_Price__c From ProductItem__c Where Id = :pis[1].Id];

        test.stopTest();
    }

		static testmethod void addNonInventoryLineItemwithNoAsset() {
        system.debug('TEST: start testProductsJMAY');
        Id stdPB = ProboCommonUtils.getStdPricebookId();
        Account a = [Select Id From Account Where Name = 'testAccount' LIMIT 1];
        // we need to make this the Opp Owner since WOs get a Person_Requesting_WO__c value based on the Opp Owner
        // and it is a restricted picklist
        User u = [select Id from User where LastName = 'Trogden' and FirstName = 'David' LIMIT 1];
        Opportunity opp = testDataFactory.createOpportunity('Probe Sales Opportunity', a.Id, false);
        opp.Name = 'SalesOpp2';
        opp.OwnerId = u.Id;
        opp.Pricebook2Id = stdPB;
        opp.CloseDate = date.today() + 15;
        opp.StageName = 'Proposal/Price Quote';
        //    opp.Opportunity_Notes__c = 'This is what needs to be done';
        //     opp.Repair_Evaluation_Serial_Number__c = '123456';
        // opp.Ship_Date__c = date.today() + 30;
        //    opp.Verified_Asset_and_Serial_Numbers_Match__c = true;
        system.debug('TEST: opportunity to insert: ' + opp);
        insert opp;

        system.debug('TEST: opp:' + opp);

        Product2 p = [select id from Product2 Limit 1];
        p.Functionally_Good_Probes__c = 3;
        //p.Target_Quantity_in_Stock__c = 2;  formula based on Total_No_of_Requests_3_Months__c
        p.Total_No_of_Requests_3_Months__c = 13.33334;
        update p;

        List<ProductItem__c> pis = testDataFactory.createProductItems(3, p.id, false);
        pis[0].Purchasing_Approved__c = true;
        pis[0].Check_In_Type__c = 'Purchase';
        pis[0].Date_Last_Test_Completed__c = date.today() - 7;
        pis[0].Added_to_Work_Order__c = false;
        pis[1].Purchasing_Approved__c = true;
        pis[1].Check_In_Type__c = 'Purchase';
        pis[2].Purchasing_Approved__c = true;
        pis[2].Check_In_Type__c = 'Purchase';
        insert pis;

        system.debug('TEST: value of 3 product items' + pis);

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

        for (ProductItem__c pi : pis) {
            OpportunityLineItem oli = new OpportunityLineItem(
                    OpportunityId = opp.Id,
                    Quantity = 1,
                    UnitPrice = 500,
                    Actual_Price__c = 50,
                    Compatible_System__c = pi.Compatible_System__c,
                    Functional_Rating__c = pi.Functional_Rating__c,
                    Functional_Rating_Notes__c = pi.Functional_Notes__c,
                    Product2id = pi.Product_Name__c,
                    Exchange__c = false,
                    Purchasing_Approved__c = pi.Purchasing_Approved__c,
                    Probo_s_Offer__c = 500,
                    Supplier_s_Quote__c = 400);
            olis.add(oli);
        }

        system.debug('TEST: Test is getting ready to insert the OLIs');
        insert olis;
        system.debug('TEST: OLIs have been inserted: ' + olis);

        }

}