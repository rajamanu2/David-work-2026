public class ProductTest {
    ProductItem__c p;
    String pitemId;
    String probtype;
    String recordTypeId;
    String name;
    String repairs = '';
    String Preset = '';
    String AFrequency = '';
    String AGain = '';
    String ADepth= '';
    String AFocal = '';
    String APosition = '';
    String ProbeTest = '';
    String PFrequency = '';
    String PGain = '';
    String PDepth = '';
    String PFocal = '';
    String PPosition = '';
    String ColorGain = '';
    Decimal PRF = 0;
    String CWGain = '';
    String Live3D = '';
    Decimal Capacitance = 0;
    Decimal Sensitivity = 0;
    String MaxLC = '';
    String ProbeRepair = '';
    String SystemTestBed = '';
    Decimal AvgCap = 0;
    Decimal CapLowerCalc = 0;
    Decimal CapUpperCalc = 0;
    Decimal CapLower = 0;
    Decimal CapUpper = 0;
    Decimal AvgSen = 0;
    Decimal SenLowerCalc = 0;
    Decimal SenUpperCalc = 0;
    Decimal SenLower = 0;
    Decimal SenUpper = 0;
    String depotTest = '';
    String UITheme = '';
    
    public ProductTest__c theProdTest;
    
    public ProductTest(ApexPages.StandardController controller){
        
        // pitemId = ApexPages.currentPage().getParameters().get('CF00NU0000004kTU2_lkid');
        pitemId = ApexPages.currentPage().getParameters().get('asset2Id');
        
        // call init() instead of having the code inline here
        init(pitemId);
    }
    
    public void init(String pitemId){
        
        UITheme = URL.getCurrentRequestUrl().toExternalForm();
        system.debug('pitemId================'+pitemId);
        system.debug('UI THEME >> ' + UITheme);
        
        if (pitemId != null){
            
            p =[Select id, Name, Product_Name__c, Check_In_Type__c from ProductItem__c where Id =:pitemId];
            Product2 PRO = [select id, Preset__c, Airscan_Frequency__c, Airscan_Gain__c, Airscan_Depth__c, Airscan_Focal_Points__c, Airscan_Focal_pt_position__c,
                            Probe_Testing_Notes__c, Phantom_Frequency__c, Phantom_Gain__c, Phantom_Depth_cm__c, Phantom_Focal_Points__c, Phantom_Focal_pt_position__c,
                            Color_Gain__c, PRF__c, CW_Gain__c, Live_3D__c, Calculated_Avg_Capacitance__c, Calculated_Avg_Sensitivity__c, Max_allowable_leakage_current__c,
                            Probe_Repair_Notes__c, Probe_Type__c, System_Test_Bed__c, Capacitance_Tolerance__c, Sensitivity_Tolerance__c, Family,
                            Set_Sensitivity_Lower_Limit__c, Set_Sensitivity_Upper_Limit__c, Set_Capacitance_Lower_Limit__c, Set_Capacitance_Upper_Limit__c from Product2 where id=:p.Product_Name__c];
            
            List<Product_Repair__c> productRepairlist = [SELECT id, Repair_Activity__c, Post_Test__c, Repair_date__c, Product_Item__c FROM Product_Repair__c
                                                         WHERE Product_Item__c =: p.id AND Repair_Date__c != null AND Post_Test__c=null ORDER BY CreatedDate DESC];
            
            system.debug('THIS IS THE INITIAL LIST> ' + productRepairlist);
            
            set<string> repairlist = new set<string>();
            if(productRepairlist.size() > 0) {
                for(Product_Repair__c pr : productRepairlist) {
                    repairlist.add(pr.Repair_Activity__c);
                }
            }
            
            system.debug('THIS IS THE REPAIR LIST> ' + repairlist);
            
            for(string r:repairlist){
                repairs += r + '; ';
            }
            depotTest = 'Standard System';
            if(PRO.Preset__c != null){
                Preset = PRO.Preset__c;     
            }    
            
            if(PRO.Airscan_Frequency__c != null){
                AFrequency = PRO.Airscan_Frequency__c;
            }
            if(PRO.Airscan_Gain__c != null){
                AGain = PRO.Airscan_Gain__c;
            }
            if(PRO.Airscan_Depth__c != null){
                ADepth = PRO.Airscan_Depth__c;
            }
            if(PRO.Airscan_Focal_Points__c != null){
                AFocal = PRO.Airscan_Focal_Points__c;
            }
            if(PRO.Airscan_Focal_pt_position__c != null){
                APosition = PRO.Airscan_Focal_pt_position__c;
            }
            if(PRO.Probe_Testing_Notes__c != null){
                ProbeTest = PRO.Probe_Testing_Notes__c;
            }
            if(PRO.Phantom_Frequency__c != null){
                PFrequency = PRO.Phantom_Frequency__c;
            }
            if(PRO.Phantom_Gain__c != null){
                PGain = PRO.Phantom_Gain__c;
            }
            if(PRO.Phantom_Depth_cm__c != null){
                PDepth = PRO.Phantom_Depth_cm__c;
            }
            if(PRO.Phantom_Focal_Points__c != null){
                PFocal = PRO.Phantom_Focal_Points__c;
            }
            if(PRO.Phantom_Focal_pt_position__c != null){
                PPosition = PRO.Phantom_Focal_pt_position__c;
            }
            if(PRO.Color_Gain__c != null){
                ColorGain = PRO.Color_Gain__c;
            }
            if(PRO.PRF__c != null){
                PRF = PRO.PRF__c;
            }
            if(PRO.CW_Gain__c != null){
                CWGain = PRO.CW_Gain__c;
            }
            if(PRO.Live_3D__c != null){
                Live3D = PRO.Live_3D__c;
            }
            
            AvgCap = PRO.Calculated_Avg_Capacitance__c;
            if(AvgCap == null){
                AvgCap = 0;
            }
            
            AvgSen = PRO.Calculated_Avg_Sensitivity__c;
            if(AvgSen == null){
                AvgSen = 0;
            }
            system.debug('TEST AT 91' + AvgCap + ' ' + PRO.Capacitance_Tolerance__c);
            if(AvgCap != 0){
                CapLowerCalc = AvgCap - (AvgCap * (PRO.Capacitance_Tolerance__c/100));
            }
            system.debug('TEST AT 95');
            if(PRO.Set_Capacitance_Lower_Limit__c != null){
                CapLowerCalc = PRO.Set_Capacitance_Lower_Limit__c;
            }
            CapLower = CapLowerCalc;
            system.debug('TEST AT 100');
            if(AvgCap != 0){
                CapUpperCalc = AvgCap + (AvgCap * (PRO.Capacitance_Tolerance__c/100));
            }
            if(PRO.Set_Capacitance_Upper_Limit__c != null){
                CapUpperCalc = PRO.Set_Capacitance_Upper_Limit__c;
            }
            CapUpper = CapUpperCalc;
            system.debug('TEST AT 108');
            if(AvgSen != 0){
                SenLowerCalc = AvgSen - (AvgSen * (PRO.Sensitivity_Tolerance__c/100));
            }
            if(PRO.Set_Sensitivity_Lower_Limit__c != null){
                SenLowerCalc = PRO.Set_Sensitivity_Lower_Limit__c;
            }
            SenLower = SenLowerCalc;
            if(AvgSen != 0){
                SenUpperCalc = AvgSen + (AvgSen * (PRO.Sensitivity_Tolerance__c/100));
            }
            if(PRO.Set_Sensitivity_Upper_Limit__c != null){
                SenUpperCalc = PRO.Set_Sensitivity_Upper_Limit__c;
            }
            system.debug('TEST AT 122');
            SenUpper = SenUpperCalc;
            Capacitance = AvgCap;
            Sensitivity = AvgSen;
            if(PRO.Max_allowable_leakage_current__c != null){
                MaxLC = PRO.Max_allowable_leakage_current__c;
            }
            if(PRO.Probe_Repair_Notes__c != null){
                ProbeRepair = PRO.Probe_Repair_Notes__c; 
            }
            if(PRO.System_Test_Bed__c != null){
                SystemTestBed = PRO.System_Test_Bed__c;
            }
            
            if(PRO.Probe_Type__c != null){
                probtype = PRO.Probe_Type__c;
                if(probtype.contains('Processor') || probtype.contains('Camera') || probtype.contains('Power')){
                    probtype = 'Endoscopy - Other';
                }
                if(probtype.contains('EUS')){		
                    probtype = 'Endoscopy - Flexible';		
                }		
                
            }
            if(PRO.Probe_Type__c == null){
                if(PRO.Family.contains('Part') && !PRO.Family.contains('Endoscopy')){
                    probtype = 'Parts';
                }
                else if(PRO.Family.contains('Coil')){
                    probtype = 'Coil';
                }
                else if(PRO.Family.contains('Depot') || (PRO.Family == 'Ultrasound System' && p.Check_In_Type__c == 'Customer Repair')){
                    probtype = 'Depot Systems';
                    depotTest = 'Depot System';
                }
                else if((PRO.Family.contains('Part') && PRO.Family.contains('Endoscopy')) || PRO.Family == 'Instrument Tray'){
                    probtype = 'Endoscopy - Other';
                }
                else{
                    probtype = 'Systems';
                }
                
            }
            
            name = p.Name;
            system.debug('probtype: '+probtype);
            
            // populate fields on a ProductTest__c obj var to make the param passing more readable
            populateProdTest();
        }
    }
    
    private void populateProdTest(){
        theProdTest = new ProductTest__c();
        
        // set the fields from the calc'd variables
        theProdTest.Name = String.valueOf(Date.today());
        theProdTest.Product_Item__c = pitemId;
        theProdTest.Repairs_Completed_Since_Last_Test__c = repairs;
        theProdTest.Preset__c = Preset;
        theProdTest.Airscan_Frequency__c = AFrequency;
        theProdTest.Airscan_Gain__c = AGain;
        theProdTest.Airscan_Depth__c = ADepth;
        theProdTest.Airscan_Focal_Points__c = AFocal;
        theProdTest.Airscan_Focal_pt_position__c = APosition;
        theProdTest.Probe_Testing_Notes__c = ProbeTest;
        theProdTest.Phantom_Frequency__c = PFrequency;
        theProdTest.Phantom_Gain__c = PGain;
        theProdTest.Phantom_Depth_cm__c = PDepth;
        theProdTest.Phantom_Focal_Points__c = PFocal;
        theProdTest.Phantom_Focal_Pt_Position__c = PPosition;
        theProdTest.Color_Gain__c = ColorGain;
        theProdTest.CW_Gain__c = CWGain;
        theProdTest.PRF__c = PRF;
        theProdTest.Live_3D__c = Live3D;
        theProdTest.Max_allowable_leakage_current__c = MaxLC;
        theProdTest.Probe_Repair_Notes__c = ProbeRepair;
        theProdTest.System_Test_Bed__c = SystemTestBed;
        theProdTest.Product_Avg_Capacitance__c = Capacitance;
        theProdTest.Product_Avg_Sensitivity__c = Sensitivity;
        theProdTest.Capacitance_Lower_Limit__c = CapLower;
        theProdTest.Capacitance_Upper_Limit__c = CapUpper;
        theProdTest.Sensitivity_Lower_Limit__c = SenLower;
        theProdTest.Sensitivity_Upper_Limit__c = SenUpper;
    }
	
    /* 
    public PageReference newPreShippingTest(){
    	recordTypeId = '0120B000000kK11';
    	return setPageURL(recordTypeId);
    }
    
    public PageReference newDepotSystemTest(){
    	recordtypeId = RecordTypeUtility.getRecordTypeByName('ProductTest__c', 'Depot Systems');
    	depotTest = 'Depot System';
    	return setPageURL(recordTypeId);
    }    
	*/
    
    public PageReference newProductTest(){
        recordtypeId = RecordTypeUtility.getRecordTypeByName('ProductTest__c', probtype);
        system.debug('newProductTest recordTypeId to use: '+recordTypeId);
        
        return setPageURL(recordTypeId);
    }
    
    private PageReference setPageURL(String recTypeId){
        
        string pageURL = '';
        system.debug('UI THEME CONTAINS LIGHTNING: ' + UITheme.contains('lightning') + ' AND HERE IS THE RECORD TYPE >> ' + recTypeId);
        if(UITheme.contains('lightning')){ //recordTypeId=' + recTypeId + '&
            pageURL = '/lightning/o/ProductTest__c/new?defaultFieldValues=Name=' + string.valueOf(Date.Today()) + ',Product_Item__c=' + pitemId + 
                ',Depot_Standard_System_Test__c=' + depotTest + ',Repairs_Completed_Since_Last_Test__c=' + repairs + ',Preset__c=' + Preset + ',Airscan_Frequency__c=' + AFrequency +
                ',Airscan_Gain__c=' + AGain + ',Airscan_Depth__c=' + ADepth + ',Airscan_Focal_Points__c=' + AFocal + ',Airscan_Focal_pt_position__c=' + APosition +
                ',Probe_Testing_Notes__c=' + ProbeTest + ',Phantom_Frequency__c=' + PFrequency + ',Phantom_Gain__c=' + PGain + ',Phantom_Depth_cm__c=' + PDepth +
                ',Phantom_Focal_Points__c=' + PFocal + ',Phantom_Focal_Pt_Position__c=' + PPosition + ',Color_Gain__c=' + ColorGain + ',CW_Gain__c=' + CWGain + ',PRF__c=' + PRF +
                ',Live_3D__c=' + Live3D + ',Max_allowable_leakage_current__c=' + MaxLC + ',Probe_Repair_Notes__c=' + ProbeRepair + ',System_Test_Bed__c=' + SystemTestBed +
                ',Product_Avg_Capacitance__c=' + Capacitance + ',Product_Avg_Sensitivity__c=' + Sensitivity + ',Capacitance_Lower_Limit__c=' + CapLower +
                ',Capacitance_Upper_Limit__c=' + CapUpper + ',Sensitivity_Lower_Limit__c=' + SenLower + ',Sensitivity_Upper_Limit__c=' + SenUpper;
            
            system.debug('LIGHTNING URL >>> ' + pageURL);
        }
        else{
            pageURL = '/a0d/e?CF00NU0000004kTU2='+name+'&CF00NU0000004kTU2_lkid='+pitemId+'&retURL='+pitemId+'&RecordType='+recTypeId+'&ent=01IU0000000ofKb'+'&Name='+string.valueOf(Date.Today());
            system.debug('NON-LIGHTNING URL >>> ' + pageURL);
        }
        
        
        
        PageReference pr = new PageReference(pageURL);
        pr.getParameters().put('nooverride', '1');
        system.debug('PAGE REF BEFORE NO OVERRIDE >> ' + pr);
        
        
        if(!UItheme.contains('lightning')){
            // setting URL from local ProductTest__c obj var
            pr.getParameters().put('00N0B000005uGdj', theProdTest.Repairs_Completed_Since_Last_Test__c);
            pr.getParameters().put('00N0B0000065vZD', theProdTest.Preset__c);
            pr.getParameters().put('00N0B0000065vZX', theProdTest.Airscan_Frequency__c);
            pr.getParameters().put('00N0B0000065vZc', theProdTest.Airscan_Gain__c);
            pr.getParameters().put('00N0B0000065vZI', theProdTest.Airscan_Depth__c);
            pr.getParameters().put('00N0B0000065vZN', theProdTest.Airscan_Focal_Points__c);
            pr.getParameters().put('00N0B0000065vZS', theProdTest.Airscan_Focal_pt_position__c);
            pr.getParameters().put('00N0B0000065vak', theProdTest.Probe_Testing_Notes__c);
            pr.getParameters().put('00N0B0000065vaQ', theProdTest.Phantom_Frequency__c);
            pr.getParameters().put('00N0B0000065vaV', theProdTest.Phantom_Gain__c);
            pr.getParameters().put('00N0B0000065vaB', theProdTest.Phantom_Depth_cm__c);
            pr.getParameters().put('00N0B0000065vaG', theProdTest.Phantom_Focal_Points__c);
            pr.getParameters().put('00N0B0000065vaL', theProdTest.Phantom_Focal_Pt_Position__c);
            pr.getParameters().put('00N0B0000065vZh', theProdTest.Color_Gain__c);
            pr.getParameters().put('00N0B0000065vZm', theProdTest.CW_Gain__c);
            pr.getParameters().put('00N0B0000065vaa', String.valueOf(theProdTest.PRF__c));
            pr.getParameters().put('00N0B0000065vZr', theProdTest.Live_3D__c);
            pr.getParameters().put('00N0B0000065vZw', theProdTest.Max_allowable_leakage_current__c);
            pr.getParameters().put('00N0B0000065vaf', theProdTest.Probe_Repair_Notes__c);
            pr.getParameters().put('00N0B0000066XQO', theProdTest.System_Test_Bed__c);
            pr.getParameters().put('01IU0000000ofKb', depotTest);
            //Production Site
            pr.getParameters().put('00N0B0000066mkn', String.valueOf(theProdTest.Product_Avg_Capacitance__c));
            pr.getParameters().put('00N0B0000066mks', String.valueOf(theProdTest.Product_Avg_Sensitivity__c ));
            pr.getParameters().put('00N0B0000066sfK', String.valueOf(theProdTest.Capacitance_Lower_Limit__c));
            pr.getParameters().put('00N0B0000066sfF', String.valueOf(theProdTest.Capacitance_Upper_Limit__c));
            pr.getParameters().put('00N0B0000066sfU', String.valueOf(theProdTest.Sensitivity_Lower_Limit__c));
            pr.getParameters().put('00N0B0000066sfP', String.valueOf(theProdTest.Sensitivity_Upper_Limit__c));
            
            
            //Test Site
            /* pr.getParameters().put('00NW0000001bzDE', Capacitance);
            pr.getParameters().put('00NW0000001bzDT', Sensitivity);
            pr.getParameters().put('00NW0000002C1WP', CapLower);
            pr.getParameters().put('00NW0000002C1WU', CapUpper);
            pr.getParameters().put('00NW0000002C1W5', SenLower);
            pr.getParameters().put('00NW0000002C1WF', SenUpper);*/
            
        }
        //pr.setRedirect(false);
        return pr;
    }
    
    @AuraEnabled
    public static TestWrapperClass createProductTest(String pItemId){
        
        String probtype;
        String recordTypeId;
        String name;
        String repairs = '';
        String Preset = '';
        String AFrequency = '';
        String AGain = '';
        String ADepth= '';
        String AFocal = '';
        String APosition = '';
        String ProbeTest = '';
        String PFrequency = '';
        String PGain = '';
        String PDepth = '';
        String PFocal = '';
        String PPosition = '';
        String ColorGain = '';
        Decimal PRF = 0;
        String CWGain = '';
        String Live3D = '';
        Decimal Capacitance = 0;
        Decimal Sensitivity = 0;
        String MaxLC = '';
        String ProbeRepair = '';
        String SystemTestBed = '';
        Decimal AvgCap = 0;
        Decimal CapLowerCalc = 0;
        Decimal CapUpperCalc = 0;
        Decimal CapLower = 0;
        Decimal CapUpper = 0;
        Decimal AvgSen = 0;
        Decimal SenLowerCalc = 0;
        Decimal SenUpperCalc = 0;
        Decimal SenLower = 0;
        Decimal SenUpper = 0;
        String depotTest = '';
        String UITheme = '';
        
        ProductItem__c p =[
            SELECT id, Name, Product_Name__c, Check_In_Type__c
            FROM ProductItem__c
            WHERE Id =:pItemId
        ];
        
        Product2 PRO = [
            SELECT id, Preset__c, Airscan_Frequency__c, Airscan_Gain__c, Airscan_Depth__c, Airscan_Focal_Points__c, Airscan_Focal_pt_position__c,
            Probe_Testing_Notes__c, Phantom_Frequency__c, Phantom_Gain__c, Phantom_Depth_cm__c, Phantom_Focal_Points__c, Phantom_Focal_pt_position__c,
            Color_Gain__c, PRF__c, CW_Gain__c, Live_3D__c, Calculated_Avg_Capacitance__c, Calculated_Avg_Sensitivity__c, Max_allowable_leakage_current__c,
            Probe_Repair_Notes__c, Probe_Type__c, System_Test_Bed__c, Capacitance_Tolerance__c, Sensitivity_Tolerance__c, Family,
            Set_Sensitivity_Lower_Limit__c, Set_Sensitivity_Upper_Limit__c, Set_Capacitance_Lower_Limit__c, Set_Capacitance_Upper_Limit__c
            FROM Product2
            WHERE id =: p.Product_Name__c
        ];
        
        List<Product_Repair__c> productRepairlist = [
            SELECT id, Repair_Activity__c, Post_Test__c, Repair_date__c, Product_Item__c
            FROM Product_Repair__c
            WHERE Product_Item__c =: p.id AND Repair_Date__c != null AND Post_Test__c = null
            ORDER BY CreatedDate DESC
        ];
        
        set<string> repairlist = new set<string>();
        if(productRepairlist.size() > 0) {
            for(Product_Repair__c pr : productRepairlist) {
                repairlist.add(pr.Repair_Activity__c);
            }
        }
        
        system.debug('THIS IS THE REPAIR LIST> ' + repairlist);
        
        for(string r:repairlist){
            repairs += r + '; ';
        }
        depotTest = 'Standard System';
        if(PRO.Preset__c != null){
            Preset = PRO.Preset__c;     
        }    
        
        if(PRO.Airscan_Frequency__c != null){
            AFrequency = PRO.Airscan_Frequency__c;
        }
        if(PRO.Airscan_Gain__c != null){
            AGain = PRO.Airscan_Gain__c;
        }
        if(PRO.Airscan_Depth__c != null){
            ADepth = PRO.Airscan_Depth__c;
        }
        if(PRO.Airscan_Focal_Points__c != null){
            AFocal = PRO.Airscan_Focal_Points__c;
        }
        if(PRO.Airscan_Focal_pt_position__c != null){
            APosition = PRO.Airscan_Focal_pt_position__c;
        }
        if(PRO.Probe_Testing_Notes__c != null){
            ProbeTest = PRO.Probe_Testing_Notes__c;
        }
        if(PRO.Phantom_Frequency__c != null){
            PFrequency = PRO.Phantom_Frequency__c;
        }
        if(PRO.Phantom_Gain__c != null){
            PGain = PRO.Phantom_Gain__c;
        }
        if(PRO.Phantom_Depth_cm__c != null){
            PDepth = PRO.Phantom_Depth_cm__c;
        }
        if(PRO.Phantom_Focal_Points__c != null){
            PFocal = PRO.Phantom_Focal_Points__c;
        }
        if(PRO.Phantom_Focal_pt_position__c != null){
            PPosition = PRO.Phantom_Focal_pt_position__c;
        }
        if(PRO.Color_Gain__c != null){
            ColorGain = PRO.Color_Gain__c;
        }
        if(PRO.PRF__c != null){
            PRF = PRO.PRF__c;
        }
        if(PRO.CW_Gain__c != null){
            CWGain = PRO.CW_Gain__c;
        }
        if(PRO.Live_3D__c != null){
            Live3D = PRO.Live_3D__c;
        }
        
        AvgCap = PRO.Calculated_Avg_Capacitance__c;
        if(AvgCap == null){
            AvgCap = 0;
        }
        
        AvgSen = PRO.Calculated_Avg_Sensitivity__c;
        if(AvgSen == null){
            AvgSen = 0;
        }
        system.debug('TEST AT 91' + AvgCap + ' ' + PRO.Capacitance_Tolerance__c);
        if(AvgCap != 0){
            CapLowerCalc = AvgCap - (AvgCap * (PRO.Capacitance_Tolerance__c/100));
        }
        system.debug('TEST AT 95');
        if(PRO.Set_Capacitance_Lower_Limit__c != null){
            CapLowerCalc = PRO.Set_Capacitance_Lower_Limit__c;
        }
        CapLower = CapLowerCalc;
        system.debug('TEST AT 100');
        if(AvgCap != 0){
            CapUpperCalc = AvgCap + (AvgCap * (PRO.Capacitance_Tolerance__c/100));
        }
        if(PRO.Set_Capacitance_Upper_Limit__c != null){
            CapUpperCalc = PRO.Set_Capacitance_Upper_Limit__c;
        }
        CapUpper = CapUpperCalc;
        system.debug('TEST AT 108');
        if(AvgSen != 0){
            SenLowerCalc = AvgSen - (AvgSen * (PRO.Sensitivity_Tolerance__c/100));
        }
        if(PRO.Set_Sensitivity_Lower_Limit__c != null){
            SenLowerCalc = PRO.Set_Sensitivity_Lower_Limit__c;
        }
        SenLower = SenLowerCalc;
        if(AvgSen != 0){
            SenUpperCalc = AvgSen + (AvgSen * (PRO.Sensitivity_Tolerance__c/100));
        }
        if(PRO.Set_Sensitivity_Upper_Limit__c != null){
            SenUpperCalc = PRO.Set_Sensitivity_Upper_Limit__c;
        }
        system.debug('TEST AT 122');
        SenUpper = SenUpperCalc;
        Capacitance = AvgCap;
        Sensitivity = AvgSen;
        if(PRO.Max_allowable_leakage_current__c != null){
            MaxLC = PRO.Max_allowable_leakage_current__c;
        }
        if(PRO.Probe_Repair_Notes__c != null){
            ProbeRepair = PRO.Probe_Repair_Notes__c; 
        }
        if(PRO.System_Test_Bed__c != null){
            SystemTestBed = PRO.System_Test_Bed__c;
        }
        
        if(PRO.Probe_Type__c != null){
            probtype = PRO.Probe_Type__c;
            if(probtype.contains('Processor') || probtype.contains('Camera') || probtype.contains('Power')){
                probtype = 'Endoscopy - Other';
            }
            if(probtype.contains('EUS')){		
                probtype = 'Endoscopy - Flexible';		
            }		
            
        }
        if(PRO.Probe_Type__c == null){
            if(PRO.Family.contains('Part') && !PRO.Family.contains('Endoscopy')){
                probtype = 'Parts';
            }
            else if(PRO.Family.contains('Coil')){
                probtype = 'Coil';
            }
            else if(PRO.Family.contains('Depot') || (PRO.Family == 'Ultrasound System' && p.Check_In_Type__c == 'Customer Repair')){
                probtype = 'Depot Systems';
                depotTest = 'Depot System';
            }
            else if((PRO.Family.contains('Part') && PRO.Family.contains('Endoscopy')) || PRO.Family == 'Instrument Tray'){
                probtype = 'Endoscopy - Other';
            }
            else{
                probtype = 'Systems';
            }
            
        }
        
        name = p.Name;
        
        // Create a wrapper class to return selected fields
        TestWrapperClass wrapper = new TestWrapperClass();
        wrapper.name = name;
        wrapper.recordTypeId = RecordTypeUtility.getRecordTypeByName('ProductTest__c', probtype);
        wrapper.Depot_Standard_System_Test = depotTest;
        wrapper.Name = String.valueOf(Date.today());
        wrapper.Product_Item = pitemId;
        wrapper.Repairs_Completed_Since_Last_Test = repairs;
        wrapper.Preset = Preset;
        wrapper.Airscan_Frequency = AFrequency;
        wrapper.Airscan_Gain = AGain;
        wrapper.Airscan_Depth = ADepth;
        wrapper.Airscan_Focal_Points = AFocal;
        wrapper.Airscan_Focal_pt_position = APosition;
        wrapper.Probe_Testing_Notes = ProbeTest;
        wrapper.Phantom_Frequency = PFrequency;
        wrapper.Phantom_Gain = PGain;
        wrapper.Phantom_Depth_cm = PDepth;
        wrapper.Phantom_Focal_Points = PFocal;
        wrapper.Phantom_Focal_Pt_Position = PPosition;
        wrapper.Color_Gain = ColorGain;
        wrapper.CW_Gain = CWGain;
        wrapper.PRF = PRF;
        wrapper.Live_3D = Live3D;
        wrapper.Max_allowable_leakage_current = MaxLC;
        wrapper.Probe_Repair_Notes = ProbeRepair;
        wrapper.System_Test_Bed = SystemTestBed;
        wrapper.Product_Avg_Capacitance = Capacitance;
        wrapper.Product_Avg_Sensitivity = Sensitivity;
        wrapper.Capacitance_Lower_Limit = CapLower;
        wrapper.Capacitance_Upper_Limit = CapUpper;
        wrapper.Sensitivity_Lower_Limit = SenLower;
        wrapper.Sensitivity_Upper_Limit = SenUpper;
        system.debug(wrapper);
        return wrapper;
        
    }
    
    // Wrapper class to structure the returned data
    public class TestWrapperClass {
        @AuraEnabled public Id id {get;set;}
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public Id recordTypeId {get;set;}
        @AuraEnabled public String Depot_Standard_System_Test {get;set;}
        @AuraEnabled public String Product_Item {get;set;}
        @AuraEnabled public String Repairs_Completed_Since_Last_Test {get;set;}
        @AuraEnabled public String Preset {get;set;}
        @AuraEnabled public String Airscan_Frequency {get;set;}
        @AuraEnabled public String Airscan_Gain {get;set;}
        @AuraEnabled public String Airscan_Depth {get;set;}
        @AuraEnabled public String Airscan_Focal_Points {get;set;}
        @AuraEnabled public String Airscan_Focal_pt_position {get;set;}
        @AuraEnabled public String Probe_Testing_Notes {get;set;}
        @AuraEnabled public String Phantom_Frequency {get;set;}
        @AuraEnabled public String Phantom_Gain {get;set;}
        @AuraEnabled public String Phantom_Depth_cm {get;set;}
        @AuraEnabled public String Phantom_Focal_Points {get;set;}
        @AuraEnabled public String Phantom_Focal_Pt_Position {get;set;}
        @AuraEnabled public String Color_Gain {get;set;}
        @AuraEnabled public String CW_Gain {get;set;}
        @AuraEnabled public Decimal PRF {get;set;}
        @AuraEnabled public String Live_3D {get;set;}
        @AuraEnabled public String Max_allowable_leakage_current {get;set;}
        @AuraEnabled public String Probe_Repair_Notes {get;set;}
        @AuraEnabled public String System_Test_Bed {get;set;}
        @AuraEnabled public Decimal Product_Avg_Capacitance {get;set;}
        @AuraEnabled public Decimal Product_Avg_Sensitivity {get;set;}
        @AuraEnabled public Decimal Capacitance_Lower_Limit {get;set;}
        @AuraEnabled public Decimal Capacitance_Upper_Limit {get;set;}
        @AuraEnabled public Decimal Sensitivity_Lower_Limit {get;set;}
        @AuraEnabled public Decimal Sensitivity_Upper_Limit {get;set;}
        @AuraEnabled public String Functional_Rating {get;set;}
		@AuraEnabled public String Functional_Evaluation {get;set;}
		@AuraEnabled public String Fun_evaluation {get;set;}
		@AuraEnabled public String Cosmetic_Rating {get;set;}
		@AuraEnabled public String Cosmetic_Evaluation {get;set;}
		@AuraEnabled public String Cos_evaluation {get;set;}
		@AuraEnabled public String Repair_Evaluation {get;set;}
		@AuraEnabled public String Test_Completed_By {get;set;}
        @AuraEnabled public String recordLink {get;set;}
    }
    
    @AuraEnabled
    public static List<TestWrapperClass> getProductTests(String pItemId){
        List<ProductTest__c> productTests = [
            SELECT Id, Name, Functional_Rating__c, Functional_Evaluation__c, Fun_evaluation__c, Cosmetic_Rating__c, Cosmetic_Evaluation__c, Cos_evaluation__c, Repair_Evaluation__c, Test_Completed_By__c
            FROM ProductTest__c
            WHERE Product_Item__c =: pItemId
        ];
        
        List<TestWrapperClass> wrapperList = new List<TestWrapperClass>();
        for (ProductTest__c pt : productTests) {
            TestWrapperClass wrapper = new TestWrapperClass();
            wrapper.id = pt.Id;
            wrapper.recordLink = '/lightning/r/ProductTest__c/'+pt.Id+'/view';
            wrapper.name = pt.Name;
            wrapper.Functional_Rating = pt.Functional_Rating__c;
            wrapper.Functional_Evaluation = pt.Functional_Evaluation__c;
            wrapper.Fun_evaluation = pt.Fun_evaluation__c; 
            wrapper.Cosmetic_Rating = pt.Cosmetic_Rating__c;
            wrapper.Cosmetic_Evaluation = pt.Cosmetic_Evaluation__c;
            wrapper.Cos_evaluation = pt.Cos_evaluation__c;
            wrapper.Repair_Evaluation = pt.Repair_Evaluation__c;
            wrapper.Test_Completed_By = pt.Test_Completed_By__c;
            wrapperList.add(wrapper);
        }

        return wrapperList;
    }
    
}