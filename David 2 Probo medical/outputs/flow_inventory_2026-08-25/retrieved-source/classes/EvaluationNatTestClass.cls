@isTest
    private class EvaluationNatTestClass {
    
        static testmethod void TestEvaluationNatalieTest() {
            Pricebook2 pricebookstd = new Pricebook2(Name = 'Standard Price Book', isActive = true);
            //ProboCommonUtils.getStdPricebookId();
            insert pricebookstd;
            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
            pro.Probe_Type__c = 'Linear';
            insert pro;
            ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
            Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', null, true);
            PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
            OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(o.Id, pbe.Id, pi.Id, true);
    
            RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', false);
            rma.ProductItem__c = pi.Id;
            rma.Opportunity__c = o.Id;
            insert rma;
    
            Evaluation_Natalie__c newEval = TestDataFactory.createEvaluationNatalie(rma.Id, true);
    
            String evalNatFullQuery = ProboCommonUtils.fullObjectSelect('Evaluation_Natalie__c');
            evalNatFullQuery += ' WHERE Id = \'' + newEval.Id + '\' LIMIT 1';
            Evaluation_Natalie__c evalNat = Database.query(evalNatFullQuery);
    
            Test.startTest();
            GH_Logger.debug('TEST: starts here');
            PageReference pRef = Page.ApprovalForm;
            Test.setCurrentPage(pRef);
            ApexPages.currentPage().getParameters().put('id',evalNat.Id);
            ApexPAges.StandardController sc = new ApexPages.StandardController(evalNat);
            EvaluationNat eval = new EvaluationNat(sc);
            eval.savecustomerapproval();
            eval.sendcustomeremail();
    
    
            Test.stopTest();
        }
     
        static testmethod void TestEvaluationNatalieTriggerTest() {
            Pricebook2 pricebookstd = new Pricebook2(Name = 'Standard Price Book', isActive = true);
            //ProboCommonUtils.getStdPricebookId();
            insert pricebookstd;
            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
            pro.Probe_Type__c = 'Linear';
            insert pro;
            Account acct = TestDataFactory.createAccount(false);
            acct.Name = 'Conquest Imaging';  
            insert acct;
            ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
            Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
            PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
            OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(o.Id, pbe.Id, pi.Id, true);
    
            Test.startTest();
    
            RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', false);
            rma.ProductItem__c = pi.Id;
            rma.Opportunity__c = o.Id;
            insert rma;
            System.debug('CC...RMA' + rma.Opportunity__r.Account.Name);
            System.debug('CC...RMA' + rma.OwnerId);
            Evaluation_Natalie__c evalNat = TestDataFactory.createEvaluationNatalie(rma.Id, false);
            evalNat.Associated_RMA__c = rma.Id;
            evalNat.Post_Repair_Evaluation__c = true;
            
            System.debug('CC...RMA' + rma.Customer_email__c);
            insert evalNat;
                        System.debug('CC...RMA' + evalNat.RMA_Owner__c);
            PageReference pRef = Page.ApprovalForm;
            Test.setCurrentPage(pRef);
            ApexPages.currentPage().getParameters().put('id',evalNat.Id);
            ApexPAges.StandardController sc = new ApexPages.StandardController(evalNat);
            EvaluationNat eval = new EvaluationNat(sc);
            eval.savecustomerapproval();
            eval.sendcustomeremail();
            eval.redirect();
            Test.stopTest();
        }
    
        static testmethod void TestEvaluationNatalieTriggerTestApproved() {
            Pricebook2 pricebookstd = new Pricebook2(Name = 'Standard Price Book', isActive = true);
            //ProboCommonUtils.getStdPricebookId();
            insert pricebookstd;
            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
            pro.Probe_Type__c = 'Convex 3D';
            insert pro;
            Account acct = TestDataFactory.createAccount(false);
            acct.Name = 'Conquest Imagine';  
            insert acct;
            ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
            Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
            PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
            OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(o.Id, pbe.Id, pi.Id, true);
    
            Test.startTest();
    
            RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', false);
            rma.ProductItem__c = pi.Id;
            rma.Opportunity__c = o.Id;
            insert rma;
            System.debug('CC...RMA' + rma.Opportunity__r.Account.Name);
            System.debug('CC...RMA' + rma.OwnerId);
            Evaluation_Natalie__c evalNat = TestDataFactory.createEvaluationNatalie(rma.Id, false);
            evalNat.Associated_RMA__c = rma.Id;
            evalNat.Post_Repair_Evaluation__c = true;
            evalNat.Approved__c = 'Test Exchange';
            System.debug('CC...RMA' + rma.Customer_email__c);
            insert evalNat;
                        System.debug('CC...RMA' + evalNat.RMA_Owner__c);
            PageReference pRef = Page.ApprovalForm;
            Test.setCurrentPage(pRef);
            ApexPages.currentPage().getParameters().put('id',evalNat.Id);
            ApexPAges.StandardController sc = new ApexPages.StandardController(evalNat);
            EvaluationNat eval = new EvaluationNat(sc);
            eval.savecustomerapproval();
            eval.sendcustomeremail();
            eval.redirect();
            Test.stopTest();
        }
    
        static testmethod void TestEvaluationNatalieTriggerTestProductRepair() {
            Pricebook2 pricebookstd = new Pricebook2(Name = 'Standard Price Book', isActive = true);
            //ProboCommonUtils.getStdPricebookId();
            insert pricebookstd;
            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
            pro.Probe_Type__c = 'Convex 3D';
            insert pro;
            Account acct = TestDataFactory.createAccount(false);
            acct.Name = 'Conquest Imagine';  
            insert acct;
            ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
            Product_Repair__c pr = TestDataFactory.createProductRepair('Cosmetic Repair', '', pi.Id, false);
            pr.No_longer_needed__c = false;
            pr.Repair_Technician__c = 'Bill Grider';
            pr.Repair_date__c = System.today();
            insert pr;
            Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
            PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
            OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(o.Id, pbe.Id, pi.Id, true);
    
            Test.startTest();
    
            RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', false);
            rma.ProductItem__c = pi.Id;
            rma.Opportunity__c = o.Id;
            insert rma;
            System.debug('CC...RMA' + rma.Opportunity__r.Account.Name);
            System.debug('CC...RMA' + rma.OwnerId);
            Evaluation_Natalie__c evalNat = TestDataFactory.createEvaluationNatalie(rma.Id, false);
            evalNat.Associated_RMA__c = rma.Id;
            evalNat.Post_Repair_Evaluation__c = true;
            evalNat.Approved__c = 'Test Exchange';
            System.debug('CC...RMA' + rma.Customer_email__c);
            insert evalNat;
                        System.debug('CC...RMA' + evalNat.RMA_Owner__c);
            PageReference pRef = Page.ApprovalForm;
            Test.setCurrentPage(pRef);
            ApexPages.currentPage().getParameters().put('id',evalNat.Id);
            ApexPAges.StandardController sc = new ApexPages.StandardController(evalNat);
            EvaluationNat eval = new EvaluationNat(sc);
            eval.savecustomerapproval();
            eval.sendcustomeremail();
            eval.redirect();
            Test.stopTest();
        }

        static testmethod void TestEvaluationNatalieTriggerTestFullRepairs() {
            Pricebook2 pricebookstd = new Pricebook2(Name = 'Standard Price Book', isActive = true);
            //ProboCommonUtils.getStdPricebookId();
            insert pricebookstd;

            Pricebook2 standardPricebook = new Pricebook2(
                Id = Test.getStandardPricebookId(),
                IsActive = true
            );
             
            //Execute an update DML on the Pricebook2 record, to make IsStandard to true
            Update standardPricebook;
             
            Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
            pro.Probe_Type__c = 'Transesophageal';
            pro.Name = 'Test';
            insert pro;
            Account acct = TestDataFactory.createAccount(false);
            acct.Name = 'Conquest Imaging';  
            acct.Accounting_Contact_E_mail__c = 'Test@Test.com';
            insert acct;
            ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, true);
            Opportunity o = TestDataFactory.createOpportunity('Probe Sales Opportunity', acct.Id, true);
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
            update o;
            PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id, true);
            OpportunityLineItem oli = TestDataFactory.createOpportunityLineItem(o.Id, pbe.Id, pi.Id, true);
            oli.TotalPrice = 10;
            update oli;
            Test.startTest();
            System.debug('CCc.. start of TestEvaluationNatalieTriggerTestFullRepairs: ' + Limits.getQueries()); 
            RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', false);
            rma.ProductItem__c = pi.Id;
            rma.Opportunity__c = o.Id;
            insert rma;
            Loaner__c lo = new Loaner__c();
            lo.Repair_Opportunity__c = o.Id;
            insert lo;
            System.debug('CC...RMA' + rma.Opportunity__r.Account.Name);
            System.debug('CC...RMA' + rma.OwnerId);
            Evaluation_Natalie__c evalNat = TestDataFactory.createEvaluationNatalie(rma.Id, false);
            evalNat.Associated_RMA__c = rma.Id;
            evalNat.Post_Repair_Evaluation__c = true;
            evalNat.Approved_Price__c = 10;
            evalNat.Required_Repairs__c = 'Array/Cable Assembly Replacement;Cap Refurbishment;Ferrule Assembly';
            System.debug('CC...RMA' + rma.Customer_email__c);
            insert evalNat;
            System.debug('CC...RMA' + evalNat.RMA_Owner__c);
            PageReference pRef = Page.ApprovalForm;
            Test.setCurrentPage(pRef);
            ApexPages.currentPage().getParameters().put('id',evalNat.Id);
            ApexPAges.StandardController sc = new ApexPages.StandardController(evalNat);
            EvaluationNat eval = new EvaluationNat(sc);
            eval.Approved = 'Full Repairs (Recommended and Required)';
            eval.s_PONumber = 'TEST PO';
            eval.ApprovedPrice = '$555';
            eval.savecustomerapproval();
            eval.sendcustomeremailpdf();
            eval.redirect();
            o = [SELECT ID, Customer_PO__c
                    FROM Opportunity
                    LIMIT 1];
            rma = [SELECT Approved_Repairs__c, Declined_Repairs__c
                    FROM RMA__c
                    LIMIT 1];
            oli = [SELECT TotalPrice
                    FROM OpportunityLineItem
                    LIMIT 1];
            System.assertEquals(555, oli.TotalPrice);     
            System.assertEquals('NONE;', rma.Declined_Repairs__c);
            System.assertEquals('Cap Refurbishment;Ferrule Assembly;Array/Cable Assembly Replacement', rma.Approved_Repairs__c);
            System.assertEquals('TEST PO', o.Customer_PO__c);
            System.debug('CCc.. end of TestEvaluationNatalieTriggerTestFullRepairs: ' + Limits.getQueries()); 
            Test.stopTest();
        }
        
        static testmethod void TestEvaluationNatalieTestEndoscopy() {
            Pricebook2 pricebookstd = new Pricebook2(Name = 'Standard Price Book', isActive = true);
            //ProboCommonUtils.getStdPricebookId();
            insert pricebookstd;
            Product2 pro = TestDataFactory.createProduct('Instrument Tray', false);
            pro.Probe_Type__c = 'Endoscopy';
            pro.Family = 'Instrument Tray';
            insert pro;
            ProductItem__c pi = TestDataFactory.createProductItem(pro.Id, false);
            pi.Serial_No__c = '1234';
            insert pi;
            Opportunity o = TestDataFactory.createOpportunity('Endoscopy Sales Opportunity', null, true);
           
            RMA__c rma = TestDataFactory.createRMA('Customer Repair Evaluation', false);
            rma.ProductItem__c = pi.Id;
            rma.Opportunity__c = o.Id;
            rma.Endoscope_Evaluation_Notes__c = 'Test';
            insert rma;
            
            ProductTest__c prodTest = new ProductTest__c(Name = 'TEST', Test_Completed_By__c = 'Rachel Stockwell', Product_Item__c = pi.Id, Last_4_Characters_of_SN__c = '1234');
            insert prodTest;
            
            Product_Test_Line_Item__c prodTestLI = new Product_Test_Line_Item__c(ProductTest__c = prodTest.id, Item_Description__c = 'test', Quantity__c = 1, Complaint__c = 'test', Repairs_Needed__c = 'test');
            insert prodTestLI;
    
            Evaluation_Natalie__c newEval = TestDataFactory.createEvaluationNatalie(rma.Id, false);
            newEval.Endoscopy_Evaluation_Results__c = 'test';
            insert newEval;
    
            String evalNatFullQuery = ProboCommonUtils.fullObjectSelect('Evaluation_Natalie__c');
            evalNatFullQuery += ' WHERE Id = \'' + newEval.Id + '\' LIMIT 1';
            Evaluation_Natalie__c evalNat = Database.query(evalNatFullQuery);
    
            Test.startTest();
            GH_Logger.debug('TEST: starts here');
            PageReference pRef = Page.ApprovalForm;
            Test.setCurrentPage(pRef);
            ApexPages.currentPage().getParameters().put('id',evalNat.Id);
            ApexPAges.StandardController sc = new ApexPages.StandardController(evalNat);
            EvaluationNat eval = new EvaluationNat(sc);
            
    
    
            Test.stopTest();
        }
        
    }