public class P_ItemReceiptActions {
        @future (callout=true)
    public static void SendItemReceiptToIntacct(Set<ID> IRList){
        for(Id IRId: IRList){
            
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('https://www.workato.com/webhooks/notify/salesforce?sobject=Item_Receipt__c&org_id=00DU0000000LaKo');
                request.setMethod('POST');
            	IF(test.isrunningtest() == false){HttpResponse response = http.send(request);}
            }
        }

}