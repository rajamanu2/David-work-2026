public class MoveLocation {

    // DML, SOQL, hardcoded OK

    ProductItem__c  p;
    String location,Name,sublocation, UITheme;
    String pitemId;
    public MoveLocation(ApexPages.StandardController controller) {
        UITheme = URL.getCurrentRequestUrl().toExternalForm();
        system.debug('THIS IS THE UI THEME >>> ' + UITheme);
        pitemId = ApexPages.currentPage().getParameters().get('CF00NU00000060eTa_lkid');
        
        
         system.debug('pitemId================'+pitemId);
         p =[Select Location__c, Sub_Location__c,Name from ProductItem__c where Id =:pitemId];
         location=p.Location__c;
        sublocation = p.Sub_Location__c;
         Name=p.Name;
         System.Debug('Location--'+ location);
    }

    public PageReference newMoveLocation() {

        // DEVINT -- the sublocation field ID is different than in Production
//        PageReference pr = new PageReference('/a04/e?&CF00NU00000060eTa_lkid='+pitemId+'&retURL='+pitemId+'&CF00NU00000060eTa='+Name+'&00NU00000060eTZ='+location+'&00Nn0000001zsus='+sublocation);
        // PROD -- the sublocation field ID is different than in devint
        string pageURL = '';
        if(UITheme.contains('lightning')){
            //pageURL = '/lightning/o/Move_Location__c/new?useRecordTypeCheck=1&navigationLocation=RELATED_LIST&uid=160580874048512985&backgroundContext=lightning,ProductItem__c=' + pitemID;
            pageURL = '/lightning/o/Move_Location__c/new?defaultFieldValues=Name=' + Name + ',ProductItem__c=' + pitemID + ',Old_Location__c=' + location;
    		if(sublocation != null){
            	pageURL += ',Old_Sub_Location__c=' + sublocation;
        	}
        }
        else{
           pageURL =  '/a04/e?&CF00NU00000060eTa_lkid='+pitemId+'&retURL='+pitemId+'&CF00NU00000060eTa='+Name+'&00NU00000060eTZ='+location;
        }
        system.debug('THIS IS THE PAGE URL >>> ' + pageURL);
        PageReference pr = new PageReference(pageURL);
        //PageReference pr = new PageReference('/a04/e?&CF00NU00000060eTa_lkid='+pitemId+'&retURL='+pitemId+'&CF00NU00000060eTa='+Name+'&00NU00000060eTZ='+location+'&00N4O000006fbF5='+sublocation);
        pr.getParameters().put('nooverride','1');
        if(!UItheme.contains('lightning')){
             if (sublocation != null) {
                    pr.getParameters().put('00N4O000006fbF5', sublocation);
                }
        }
        pr.setRedirect(false);
        return pr;
    }
}