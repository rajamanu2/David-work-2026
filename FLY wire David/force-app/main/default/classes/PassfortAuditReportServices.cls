public with sharing class PassfortAuditReportServices {
    
    public static HttpResponse getProfileAuditReport(String profileId) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:PassfortAPI/profiles/' + EncodingUtil.urlEncode(profileId, 'UTF-8') + '/audit-items');
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res;

        try {
            res = http.send(req);
        } catch (Exception e) {
            throw new PassfortAuditReport.PassfortAuditReportException('Failed to getProfileAuditReport: ' + e.getMessage() + ' ' + e.getStackTraceString());            
        }

        return res;
    }
}