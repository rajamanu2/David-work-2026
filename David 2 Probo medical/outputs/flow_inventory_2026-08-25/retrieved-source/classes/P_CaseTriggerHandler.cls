public class P_CaseTriggerHandler {
    
    static Map<String, List<ProductTestData__c>> probeTypeToProdTestData;
	private Map<String, Decimal> RMap = new Map<String, Decimal>();
    private List<ProductTestData__c> prodTestDataList = new List<ProductTestData__c>();

    private Map<String, Decimal> GetValues(Product2 r) {
        Map<String, Decimal> thisInfo = new Map<String, Decimal>{
            // This is the pricing map that links the price for each repair from the product page to the repair.
                                        'Cable Advanced Whitening' => r.Cable_Advanced_Whitening__c,
                                        'Cable Jacket Splice' => r.Cable_Jacket_Splice__c,
                                        'Connector Housing Replacement' => r.Connector_Housing_Replacement__c,
                                        'Connector Housing Paint' => r.Connector_Housing_Paint__c,
                                        'Lens Refurbishment' => r.Lens_Refurb__c,
                                        'Lens Relens' => r.Lens_Relens__c,
                                        'Strain Relief Replacement' => r.Strain_Relief_Replacement__c,
                                        'Array Replacement' => r.Array_Replacement__c,
                                        'Cable Replacement' => r.Cable_Replacement__c,
                                        'Motor Repair' => r.Motor_Repair__c,
                                        'Cap Replacement with Oil Fill' => r.Cap_Replacement_with_Oil_Fill__c,
                                        'Connector Repair' => r.Connector_Repair__c,
                                        'Electrical' => r.Electrical__c,
                                        'Oil Fill' => r.Oil_Fill__c,
                                        'Probe Handle Replacement' => r.Probe_Handle_Replacement__c,
                                        'Retermination' => r.Retermination__c,
                                        'Bending Rubber/Glue Beads Replacement' => r.Bending_Rubber_Glue_Beads_Replacement__c,
                                        'Control Housing Polish' => r.Control_Housing_Polish__c,
                                        'Grommet Replacement' => r.Grommet_Replacement__c,
                                        'Knob Replacement' => r.Knob_Replacement__c,
                                        'Tip Polish' => r.Tip_Polish__c,
                                        'Lens Remove Coating/RTV Seal Replacement' => r.Lens_Remove_Coating_RTV_Seal_Replacement__c,
                                        'RTV Seal Replacement' => r.RTV_Seal_Replacement__c,
                                        'Array Drive Switch or Board Replacement' => r.Array_Drive_Switch_or_Board_Replacement__c,
                                        'Control Housing Overhaul' => r.Control_Housing_Overhaul__c,
                                        'Array Drive System Replacement' => r.Array_Drive_System_Replacement__c,
                                        'Steering Cable Adjustment' => r.Steering_Cable_Adjustment__c,
                                        'Connector Boards Replacement' => r.Connector_Boards_Replacement__c,
                                        'Insertion Tube Replacement' => r.Insertion_Tube_Replacement__c,
                                        'Steering Cable Replacement' => r.Steering_Cable_Replacement__c,
                                        'Tip Overhaul' => r.Tip_Overhaul__c,
                                        'Probe Handle Reverse' => r.Probe_Handle_Reverse__c,
                                        'Cable Jacket Refurbishment' => r.Cable_Jacket_Refurbishment__c,
                                        'Connector Refurbishment' => r.Connector_Refurbishment__c,
                                        'Probe Handle Refurbishment' => r.Probe_Handle_Refurbishment__c,
                                        'Cap Refurbishment' => r.Cap_Refurbishment__c,
                                        'Connector Overhaul' => r.Connector_Overhaul__c,
                                        'Strain Relief Refurbishment' => r.Strain_Relief_Refurbishment__c,
                                        'Array Carriage Replacement' => r.Array_Carriage_Replacement__c,
                                        'Ferrule Assembly' => 1,
                                        'Electrical - miscellaneous' => r.Electrical__c,
                                        'Carriage Drive Cable Replacement' => r.Carriage_Drive_Cable_Replacement__c,
                                        'Oil Bladder Replacement' => r.Oil_Bladder_Replacement__c,
                                        'Wire splice' => r.Wire_splice__c,
                                        'Max Repair' => r.Max_Repair__c,
                                        'Max Non Functional Repair' => r.Max_Non_Functional__c    
                                };
        return thisInfo;
    }
    
    private Map<String, Contact> getContactMap(List<String> emailList, List<String> phoneList) {
        
        List<Contact> contactList = [SELECT Id, Email, HomePhone, MobilePhone, Name, OwnerId
                                                FROM Contact 
                                                WHERE Email in:emailList
                                    			OR HomePhone in:phoneList
                                    			OR MobilePhone in:phoneList];
        
        Map<String, Contact> contactMap = new Map<String, Contact>();
        for(Contact c : contactList) {
            if(emailList.contains(c.Email)){
                contactMap.put(c.Email, c);
            }
            else if(phoneList.contains(c.HomePhone)){
                contactMap.put(c.HomePhone, c);
            }
            else if(phoneList.contains(c.MobilePhone)){
                contactMap.put(c.MobilePhone, c);
            }
            
        }
        return contactMap;
    }
    
    public void processRecords(List<Case> newRecs){
        
        Set<String> prodIDs = new Set<String>();
        Set<String> probTypes = new Set<String>();
        List<String> emailList = new List<String>();
        List<String> phoneList = new List<String>();
		
        for (Case c: newRecs) {
            system.debug('THIS IS THE CURRENT CASE >>> ' + c);
            if(c.Repair_Eval_Endoscopy_Type__c != null){
                if(c.Repair_Eval_Endoscopy_Type__c.contains('Rigid')){
                    c.Repair_Eval_Probe_Type__c = 'Endoscopy - Rigid';
                } 
                if(c.Repair_Eval_Endoscopy_Type__c.contains('Flexible')){
                    c.Repair_Eval_Probe_Type__c = 'Endoscopy - Flexible';
                } 
                if(c.Subject == null){
                    c.Subject = 'Online Repair Evaluator Tool Endoscopy - '+ c.Repair_Eval_Endoscope_Manufacturer__c + ' ' + c.Repair_Eval_Endoscope_Model__c;
                }
            }
            if(c.Repair_Eval_Probe_Type__c != null){
                String productName = '';
                if (c.Repair_Eval_Probe_Manufacturer__c != null) {
                    productName = c.Repair_Eval_Probe_Manufacturer__c;
                }
                
                if (c.Repair_Eval_Probe_Model_Acuson__c != null) {
                    productName += ' ' + c.Repair_Eval_Probe_Model_Acuson__c;
                }
                else if (c.Repair_Eval_Probe_Model_GE__c != null) {
                    productName += ' ' + c.Repair_Eval_Probe_Model_GE__c;
                }
                else if (c.Repair_Eval_Probe_Model_Philips__c != null) {
                    productName += ' ' + c.Repair_Eval_Probe_Model_Philips__c;
                }
                else if (c.Repair_Eval_Probe_Model_Siemens__c != null) {
                    productName += ' ' + c.Repair_Eval_Probe_Model_Siemens__c;
                }
                else if (c.Repair_Eval_Probe_Model_SonoSite__c != null) {
                    productName += ' ' + c.Repair_Eval_Probe_Model_SonoSite__c;
                }
                else if (c.Repair_Eval_Probe_Model_Toshiba__c != null) {
                    productName += ' ' + c.Repair_Eval_Probe_Model_Toshiba__c;
                }
                else if (c.Repair_Eval_Probe_Model_Zonare__c != null) {
                    productName += ' ' + c.Repair_Eval_Probe_Model_Zonare__c;
                }
               
                
                if(productName != null){
                    prodIDs.add(productName);
                }
            	
                probTypes.add(c.Repair_Eval_Probe_Type__c);
                
                if(c.Repair_Eval_Contact_Email__c != null){
                    emailList.add(c.Repair_Eval_Contact_Email__c);
                }
                if(c.Repair_Eval_Contact_Phone__c != null){
                    phoneList.add(c.Repair_Eval_Contact_Phone__c);
                }
            }
        }
        
        system.debug('Right BEFORE probe type check in Case >> ' + probTypes);
        if(probTypes.size() > 0){ 
        		system.debug('Right INSIDE probe type check in Case >> ' + prodIDs);
        Map<String, Contact> newContactMap = getContactMap(emailList, phoneList);
        Map<String, Product2> prodIDToProducts;
        if(prodIDs.size() > 0){
            prodIDToProducts = new Map<String, Product2>([SELECT Id,Name,Cable_Advanced_Whitening__c,Cable_Jacket_Splice__c,Connector_Housing_Replacement__c, Connector_Housing_Paint__c,Refurb__c,
                                Lens_Refurb__c, Lens_Remove__c, Lens_Relens__c, Strain_Relief_Remove__c, Strain_Relief_Replacement__c, Array_Replacement__c,
                                Cable_Replacement__c, Cap_Replacement_with_Oil_Fill__c, Connector_Repair__c, Electrical__c, Motor_Repair__c, Oil_Fill__c,
                                Probe_Handle_Close__c, Probe_Handle_Open__c, Probe_Handle_Replacement__c, Retermination__c, Bending_Rubber_Glue_Beads_Replacement__c,
                                Control_Housing_Polish__c, Grommet_Replacement__c, Knob_Replacement__c, Lens_Remove_Coating_RTV_Seal_Replacement__c,
                                RTV_Seal_Replacement__c, Tip_Polish__c, Array_Drive_Switch_or_Board_Replacement__c, Array_Drive_System_Replacement__c,
                                Connector_Boards_Replacement__c, Control_Housing_Overhaul__c, Insertion_Tube_Replacement__c, Steering_Cable_Adjustment__c,
                                Steering_Cable_Replacement__c, Tip_Overhaul__c, Probe_Handle_Reverse__c, Cap_Refurbishment__c, Cable_Jacket_Refurbishment__c,
                                Connector_Refurbishment__c, Probe_Handle_Refurbishment__c, Strain_Relief_Refurbishment__c, Wire_splice__c,
                                Oil_Bladder_Replacement__c, Carriage_Drive_Cable_Replacement__c, IsActive,
                                Array_Carriage_Replacement__c, Connector_Overhaul__c, Max_Repair__c, Max_Non_Functional__c
                        FROM Product2
                        WHERE IsActive = true AND Name IN :prodIDs
                ]);
        }
        system.debug('THIS IS THE PRODUCT >> ' + prodIDToProducts);
        
        // we need a map of Maps for each ProductID
        Map<String, Map<String, Decimal>> prodIDtoRMaps = new Map<String, Map<String, Decimal>>();
        if(prodIdToProducts.size() > 0){
            for (Product2 r : prodIDToProducts.values()) {

                Map<String, Decimal> thisInfo = GetValues(r);
                system.debug('THIS IS THE NEW PROD ID TO R MAP >> ' + r.Name + ' AND ' + thisInfo);
                prodIDtoRMaps.put(r.Name, thisInfo);
                
            }
        }
                
		system.debug('THIS IS THE R MAP >> ' + prodIDtoRMaps + ' AND THIS IS THE PROBE TYPES >> ' + probTypes);        
        // Product test data is a custom object that's a matrix that indicates the proper repair activity, repairability, and rating based on the symptom from the test.
           Map<String, List<ProductTestData__c>> probeTypeToProdTestData = new Map<String, List<ProductTestData__c>>();
		   List<ProductTestData__c> testDataList = [SELECT Id, Field_API_Name__c, Field_API_Value__c, Probe_Type__c, 
                                repair_evaluation__c, Repairable__c
                        FROM ProductTestData__c
                        WHERE Probe_Type__c IN: probTypes];
             system.debug('THIS IS THE PRODUCT TEST DATA >> ' + testDataList);  
                for (ProductTestData__c r : testDataList) {
			
                    if (!probeTypeToProdTestData.containsKey(r.Probe_Type__c)) {
                        probeTypeToProdTestData.put(r.Probe_Type__c, new List<ProductTestData__c>());
                    }
                    probeTypeToProdTestData.get(r.Probe_Type__c).add(r);
                }
         
        
        for(Case c: newRecs){
            String productName = '';
            Contact newContact;
            if(newContactMap.get(c.Repair_Eval_Contact_Email__c) != null){
                newContact = newContactMap.get(c.Repair_Eval_Contact_Email__c);
            }
            else if(newContactMap.get(c.Repair_Eval_Contact_Phone__c) != null){
                newContact = newContactMap.get(c.Repair_Eval_Contact_Phone__c);
            }
            if(newContact != null){
                c.ContactId = newContact.id;
                c.OwnerId = newContact.OwnerId;
                
            }
            
            if(c.Repair_Eval_Contact_Country__c == 'United States' || c.Repair_Eval_Contact_Country__c == null){
                c.CurrencyIsoCode = 'USD';
            }  
            else if(c.Repair_Eval_Contact_Country__c == 'United Kingdom'){
                c.CurrencyIsoCode = 'GBP';
                if(newContact == null){
                    c.OwnerId = '005U0000004H1ag';
                }
            }
            else {
                c.CurrencyIsoCode = 'EUR';
                if(newContact == null){
                    c.OwnerId = '005U0000004H1ag';
                }
            }
            if (c.Repair_Eval_Probe_Manufacturer__c != null) {
                productName = c.Repair_Eval_Probe_Manufacturer__c;
            }
            
			if (c.Repair_Eval_Probe_Model_Acuson__c != null) {
                productName += ' ' + c.Repair_Eval_Probe_Model_Acuson__c;
            }
            else if (c.Repair_Eval_Probe_Model_GE__c != null) {
                productName += ' ' + c.Repair_Eval_Probe_Model_GE__c;
            }
            else if (c.Repair_Eval_Probe_Model_Philips__c != null) {
                productName += ' ' + c.Repair_Eval_Probe_Model_Philips__c;
            }
            else if (c.Repair_Eval_Probe_Model_Siemens__c != null) {
                productName += ' ' + c.Repair_Eval_Probe_Model_Siemens__c;
            }
            else if (c.Repair_Eval_Probe_Model_SonoSite__c != null) {
                productName += ' ' + c.Repair_Eval_Probe_Model_SonoSite__c;
            }
            else if (c.Repair_Eval_Probe_Model_Toshiba__c != null) {
                productName += ' ' + c.Repair_Eval_Probe_Model_Toshiba__c;
            }
            else if (c.Repair_Eval_Probe_Model_Zonare__c != null) {
                productName += ' ' + c.Repair_Eval_Probe_Model_Zonare__c;
            }
            
            c.Repair_Eval_Probe_Model__c = productName;
            
            system.debug('THIS IS THE PRODUCT NAME >> ' + productName + ' AND THIS IS PROD ID R MAP >>> ' + prodIDtoRMaps.get(productName));
            if (productName != null && prodIDtoRMaps.containsKey(productName)) {
               RMap = prodIDtoRMaps.get(productName);
               
            }
            if (c.Repair_Eval_Probe_Type__c != null && probeTypeToProdTestData.containsKey(c.Repair_Eval_Probe_Type__c)) {
               prodTestDataList = probeTypeToProdTestData.get(c.Repair_Eval_Probe_Type__c);
            }
           
            // create the ProdTestWrapper for this ProdTest record
            ProdTestInfoWrapper thisPTestInfo = new ProdTestInfoWrapper();
            
            if (c.Repair_Eval_Cable_Jacket__c != null) {
                //String cable = c.Repair_Eval_Cable_Jacket__c.SubStringBefore('<');
                System.debug('Adding CLIST for c.Repair_Eval_Cable_Jacket__c');
                thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, c.Repair_Eval_Cable_Jacket__c, 'Cable Jacket'));
            }
            
            if (c.Repair_Eval_Cap__c != null) {
                System.debug('Adding CLIST for c.Repair_Eval_Cap__c');
                thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, c.Repair_Eval_Cap__c, 'Cap'));
            }
            if (c.Repair_Eval_Connector__c != null) {
                        System.debug('Adding CLIST for c.Repair_Eval_Connector__c');
                        thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, c.Repair_Eval_Connector__c, 'Connector'));
                    }
            if (c.Repair_Eval_Lens__c != null) {
                System.debug('Adding CLIST for c.Repair_Eval_Lens__c');
                thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, c.Repair_Eval_Lens__c, 'Lens'));
            }
            
            if (c.Repair_Eval_Probe_Handle__c != null) {
                System.debug('Adding CLIST for c.Repair_Eval_Probe_Handle__c');
                thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, c.Repair_Eval_Probe_Handle__c, 'Probe Handle'));
            }
            
            if (c.Repair_Eval_Strain_Relief__c != null) {
                System.debug('Adding CLIST for c.Repair_Eval_Strain_Relief__c');
                thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, c.Repair_Eval_Strain_Relief__c, 'Strain Relief'));
            }
            
            if (c.Repair_Eval_Airscan__c != null) {
                System.debug('Adding FLIST for c.Repair_Eval_Airscan__c');
                thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, c.Repair_Eval_Airscan__c, 'Airscan'));
            }
            
            if (c.Repair_Eval_Color_Artifacts__c != null) {
                System.debug('Adding FLIST for c.Repair_Eval_Color_Artifacts__c');
                thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, c.Repair_Eval_Color_Artifacts__c , 'Color Artifacts'));
            }
            
            if (c.Repair_Eval_CW_Artifacts__c != null) {
                System.debug('Adding FLIST for c.Repair_Eval_CW_Artifacts__c');
                thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, c.Repair_Eval_CW_Artifacts__c, 'CW Artifacts'));
            }
            
            if (c.Repair_Eval_Image__c != null) {
                System.debug('Adding FLIST for Functional_Image__c');
                thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, c.Repair_Eval_Image__c, 'Image'));
            } 
            
            if (c.Repair_Eval_Motor__c != null) {
                System.debug('Adding FLIST for c.Repair_Eval_Motor__c');
                thisPTestInfo.FinalList.addAll(complexListSplitter(thisPTestInfo, c.Repair_Eval_Motor__c, 'Motor'));
            }
            
            

            String pos_repairs = '';        

            for (ComplexStringWrapper finaltest : thisPTestInfo.FinalList) {
                System.debug('Working with Final Cosmetic: ' + finaltest);
                if (!pos_repairs.contains(finaltest.repairs)) {
                      pos_repairs = pos_repairs + finaltest.repairs;
                }
            }
            
            List<String> POStemp2 = pos_repairs.split(';');
            Set<String> POStemp = new Set<String>();
            POStemp.addAll(POStemp2);
            
            if (POStemp.contains('Retermination') && (productName.containsIgnoreCase('PVT-375BT') ||
                            						productName.containsIgnoreCase('PLT-805AT'))) {
                     POStemp.remove('Retermination');
                     POStemp.add('Array Replacement');
                     POStemp.add('Probe Handle Replacement');
                     POStemp.add('Strain Relief Replacement');
            }
            
            if (POStemp.contains('Ferrule Assembly')) {
                POStemp.add('Strain Relief Replacement');
            }
            
            if (POStemp.contains('Retermination')) {
                POStemp.add('Strain Relief Replacement');
            }
			for (String pr : POStemp) {

                if (POStemp.contains('Array Replacement') && (pr == 'Lens Relens' || pr == 'Lens Refurbishment')) {
                    POStemp.remove(pr);
                }
                if (POStemp.contains('Cable Replacement')
                    && (pr == 'Cable Jacket Splice' || pr == 'Cable Advanced Whitening' || pr == 'Cable Jacket Refurbishment'
                        || pr == 'Retermination' || pr == 'Strain Relief Replacement' || pr == 'Strain Relief Refurbishment'
                        || pr == 'Ferrule Assembly')) {
                            POStemp.remove(pr);
                        }
                if (POStemp.contains('Cap Replacement with Oil Fill') && (pr == 'Oil Fill' || pr == 'Cap Refurbishment')) {
                    POStemp.remove(pr);
                }
                if (POStemp.contains('Connector Housing Replacement') && (pr == 'Connector Housing Paint' || pr == 'Connector Refurbishment')) {
                    POStemp.remove(pr);
                }
                if (POStemp.contains('Connector Overhaul') && (pr == 'Connector Repair')) {
                    POStemp.remove(pr);
                }
                if (POStemp.contains('Control Housing Replacement') && (pr == 'Control Housing Polish')) {
                    POStemp.remove(pr);
                }
                if (POStemp.contains('Control Housing Overhaul') && (pr == 'Control Housing Polish')) {
                    POStemp.remove(pr);
                }
                if (POStemp.contains('Insertion Tube Replacement') && (pr == 'Steering Cable Adjustment')) {
                    POStemp.remove(pr);
                }
                if (POStemp.contains('Lens Relens') && (pr == 'Lens Refurbishment')) {
                    POStemp.remove(pr);
                }
                if (POStemp.contains('Lens Remove Coating/RTV Seal Replacement') && (pr == 'RTV Seal Replacement')) {
                    POStemp.remove(pr);
                }
                if (POStemp.contains('Probe Handle Replacement') && (pr == 'Probe Handle Refurbishment')) {
                    POStemp.remove(pr);
                }
                if (POStemp.contains('Retermination') && (pr == 'Ferrule Assembly')) {
                    POStemp.remove(pr);
                }
                if (POStemp.contains('Strain Relief Replacement') && (pr == 'Strain Relief Refurbishment')) {
                    POStemp.remove(pr);
                }
                if (POStemp.contains('Steering Cable Replacement') && (pr == 'Steering Cable Adjustment')) {
                    POStemp.remove(pr);
                }
                
                if (POStemp.contains('Tip Overhaul') && (pr == 'Tip Polish')) {
                    POStemp.remove(pr);
                }
            }
			Decimal functionalcost = 0;
            Decimal fullcost = 0;
            String finalrepairs = '';
            for (String pos : POStemp) {
                if (pos != null && RMap.get(pos) != null) {
                    System.debug('THIS IS THE REPAIRFINAL LOOP >>>>>> ' + pos + ' AND THIS IS THE FULL COST >> ' + fullcost);
                    if (ProboConstants.functional_repair_list.contains(pos) || pos == 'Lens Relens') {
                        functionalcost += RMap.get(pos);
                    }
                    fullcost += RMap.get(pos);
                    finalrepairs += pos + '; ';
                }
            }
            system.debug('THIS IS R MAP MAX NON FUNCTIONAL REPAIR >> ' + RMap.get('Max Non Functional Repair'));
            Decimal cosmeticcost = fullcost - functionalcost;
            
            if (RMap.get('Max Non Functional Repair') != null && cosmeticcost > RMap.get('Max Non Functional Repair')) {
                cosmeticcost = RMap.get('Max Non Functional Repair');
                fullcost = cosmeticcost + functionalcost;
            }
            system.debug('THIS IS R MAP MAX REPAIR >> ' + RMap.get('Max Repair'));
            if (RMap.get('Max Repair') != null && fullcost > RMap.get('Max Repair')) {
                fullcost = RMap.get('Max Repair');
            }
            
            
            c.Repair_Eval_Suggested_Repairs__c = finalrepairs;
            c.Repair_Eval_Quote__c = fullcost;
            c.Subject = 'Online Repair Evaluator Tool: ' + productName;
            c.Origin = 'Web';
            
        }
        
        
        }
        
    }
    
   
    private List<ComplexStringWrapper> complexListSplitter(ProdTestInfoWrapper theProdTestWrapper, String theField, String theLabel) {

        	List<ComplexStringWrapper> retList = new List<ComplexStringWrapper>();

            List<String> fieldValues = theField.split(';');
            
            String repairs = '';
            

            for (String thisTest : fieldValues) {

                for (ProductTestData__c ptdtemp : prodTestDataList) {
                    if (thisTest.equalsIgnoreCase(ptdtemp.Field_API_Value__c) && ptdtemp.Field_API_Name__c == theLabel) {
                        system.debug('This is the ptdtemp >>>>> ' + ptdtemp);
                        if (ptdtemp.repair_evaluation__c != null && ptdtemp.Repairable__c != 'No') {
                            if (RMap.get(ptdtemp.repair_evaluation__c.trim()) > 0) {
                                repairs = repairs + ptdtemp.repair_evaluation__c.trim() + (';');
                        } 
                        
                        break;
                    }
                }
            }
        
        	ComplexStringWrapper w = new ComplexStringWrapper(repairs);
                System.debug('String ITERATION: ' + w);
                retList.add(w);


            }

        return retList;
   
    }
    public class ProdTestInfoWrapper {

        public List<ComplexStringWrapper> FinalList;
        
        public ProdTestInfoWrapper() {
            FinalList = new List<ComplexStringWrapper>();
        }
    }
    public class ComplexStringWrapper {

        public String repairs { get; set; }

        public ComplexStringWrapper(String theRepairs) {
            repairs = theRepairs;
        }
    }

}