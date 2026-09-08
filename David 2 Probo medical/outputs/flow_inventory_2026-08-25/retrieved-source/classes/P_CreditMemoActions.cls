public class P_CreditMemoActions {
    @future (callout=true)
    public static void SendCreditMemoToIntacct(Set<ID> CMList){
        for(Id CMId: CMList){
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('https://www.workato.com/webhooks/notify/salesforce?sobject=Credit_Memo__c&org_id=00DU0000000LaKo');
                request.setMethod('POST');
            	IF(test.isrunningtest() == false){HttpResponse response = http.send(request);}
            }
        }
    }