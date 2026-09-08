public with sharing class GenarateBarcode2 {

    // DML, hardcoded OK, SOQL OK

    public String barcode { get; set; }
    public String imageUrl{get;set;} //CH07
    private final ProductItem__c pro;
    public ProductItem__c pro1 { get; set; }
    public String partNumber;
    public String modelNumber;
    public String finalModelNumber {get;set;}
    public String finalPartNumber { get; set; }
    public String compatibleSystem;
    public String finalCompatibleSystem { get; set; }
    public String BarcodeCode { get; set; }
    Integer length = 52;
    
    //public String [] compatibleSystem;
    //public String   finalCompatibleSystem;*/

    public GenarateBarcode2(ApexPages.StandardController controller) {
		finalCompatibleSystem = '';
        this.pro = (ProductItem__c) Controller.getRecord();
        String proId = pro.Id;
        system.debug('ID=====================' + proId);
        

        try{
            pro1 = [
                    select Barcode_No__c,Product_Name__c,Serial_No__c,Part_Number__c, Asset_Model_No__c,
                            PO_Number__c,Compatible_System__c,Receive_date__c,Check_In_Type__c,Name, 
                			Product_Name__r.Name, Label_Printed__c
                    from ProductItem__c
                    where Id = :proId
                    limit 1
            ];

            barcode = pro1.Barcode_No__c;
            system.debug('THIS IS THE BARCODE >>> ' + barcode);

            partNumber = pro1.Part_Number__c;
            modelNumber = pro1.Asset_Model_No__c;

            if (pro1.Compatible_System__c != null && pro1.Compatible_System__c.length() > 0) {
                compatibleSystem = pro1.Compatible_System__c;
            }
            //compatibleSystem = pro1.Compatible_System__c.split(',');

        } catch (Exception e){
            system.debug('Unable to find ProductItem__c for ID: ' + proId);
        }


        if (partNumber != null && partNumber.length() > length) {
            finalPartNumber = partNumber.substring(0, length + 1) + '..';
        } else {

            finalPartNumber = partNumber;

        }

        if (modelNumber != null && modelNumber.length() > length) {
            finalModelNumber = modelNumber.substring(0, length + 1) + '..';
        } else {

            finalModelNumber = modelNumber;

        }


        if (compatibleSystem != null && compatibleSystem.length() > length) {
            finalCompatibleSystem = compatibleSystem.substring(0, length + 1) + '.........';
        } else {

            string tempSystemName = '';
            list<string> systemname = new list<string>();
            //systemname = '';
            /* Modifed Code for Error fixing */
            if (compatibleSystem != null && compatibleSystem.length() > length) {
                finalCompatibleSystem = compatibleSystem.trim();
                systemname = finalCompatibleSystem.split(' ');
            }
            // end of modification

            for (integer i = 0; i < systemname.size(); i++) {
                if (math.mod(i, 2) == 0 && i != 0){
                    tempSystemName += '\n' + systemname[i];
                } else {
                    tempSystemName += ' ' + systemname[i];
                }
            }

            finalCompatibleSystem = tempSystemName ;

        }

        //finalPartNumber = partNumber[0] + ',' + partNumber[1];
        //finalCompatibleSystem

        system.debug('THIS IS THE PART NUMBER >>> ' + partnumber);
        system.debug('THIS IS THE FINAL PART NUMBER >>> ' + finalPartNumber);
        system.debug('THIS IS THE FINAL MODEL NUMBER >>> ' + finalModelNumber);
        system.debug('THIS IS THE COMPATIBLE SYSTEM >>>> ' + compatiblesystem);
        system.debug('THIS IS THE FINAL COMPATIBLE SYSTEM >>> ' + finalcompatiblesystem);
        
        
        
        if(pro1.Name.contains('PI')){
            imageUrl='https://generator.barcodetools.com/barcode.png?gen=0&data='+pro1.Barcode_No__c+'&bcolor=FFFFFF&fcolor=000000&tcolor=000000&fh=14&bred=0&w2n=2.5&xdim=1&w=&h=50&debug=1&btype=7&angle=0&quiet=1&balign=2&talign=2&guarg=1&text=0&tdown=1&stst=1&schk=0&cchk=1&ntxt=1&c128=0';
        }
        else{
        	imageUrl='https://generator.barcodetools.com/barcode.png?gen=0&data='+pro1.Barcode_No__c+'&bcolor=FFFFFF&fcolor=000000&tcolor=000000&fh=14&bred=0&w2n=2.5&xdim=2&w=&h=50&debug=1&btype=7&angle=0&quiet=1&balign=2&talign=2&guarg=1&text=0&tdown=1&stst=1&schk=0&cchk=1&ntxt=1&c128=0';
        }
        
        
    }
    
    public PageReference updateAsset() {
        try {
            if (pro1.Label_Printed__c == false) {
                pro1.Label_Printed__c = true;
                update pro1;
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Asset updated successfully!'));
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error updating asset: ' + e.getMessage()));
        }
        return null; // Stay on the same page after action
    }

}