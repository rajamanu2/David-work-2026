public class POBillActions {
	@future (callout=true)
    public static void SendPOToIntacct(Set<ID> POList){
        for(Id POId: POList){
            
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('https://www.workato.com/webhooks/notify/salesforce?sobject=PO_Bill__c&org_id=00DU0000000LaKo');
                request.setMethod('POST');
            	IF(test.isrunningtest() == false){HttpResponse response = http.send(request);}
            }
        }
}