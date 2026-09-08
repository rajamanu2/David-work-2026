public class CustomSearchController {
	
    // SOQL, DML, hardcoded OK

    public string searchText {get;set;}
    public string newpage {get;set;}
    public pagereference pageref {get;set;}
    public string sbstr {get;set;}
    
    public CustomSearchController() {}
    
    public PageReference search() {

        System.debug('Custom Searching on value: ' + searchText);
        if (searchText != null) {
            searchText = searchText.leftPad(6, '0');

            system.debug('THIS IS THE SEARCH TEXT: ' + searchText);
            list<ProductItem__c> newitem = [select id, name from ProductItem__c where name LIKE :('%'+searchtext+'%')];
            if(newitem.size() == 1){
                NewPage = '/' + newitem[0].id;
            }
        }
        system.debug('THIS IS THE NEW PAGE: ' + newpage);

        // TODO: this will throw an exception if none or multiple matches found - could generate a nice error msg
        pageRef = new PageReference(NewPage);
		pageRef.setRedirect(true);

        return pageref;
    }
}