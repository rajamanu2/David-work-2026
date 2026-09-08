// Class used to check KYC application forms expiry state
// Official Passfort documentation https://developer.passfort.com/api#tag/Audit/paths/~1profiles~1%7Bprofile_id%7D~1audit-items/get

public with sharing class PassfortApplicationFormExpiryChecker {
    
    // For a list of accounts returns a map of Account Ids to -> Expired (true or false)
    public static Map<String,Boolean> areExpired(List<Account> accountsToCheck) {

        Map<String,Boolean> areExpired = new Map<String,Boolean>();

        for (Account currentAccount : accountsToCheck) {
            // An audit report of each profile is requested to the passfort API
            HttpResponse res = PassfortAuditReportServices.getProfileAuditReport(currentAccount.Passfort_Profile_Id__c);
            String jsonString = res.getBody();
            List<PassfortAuditReport> auditReports = PassfortAuditReport.parseMultiple(jsonString);
            Boolean isExpired = isCurrentFormExpired(auditReports);
            areExpired.put(currentAccount.Id, isExpired);
        }

        return areExpired;
    }

    // The audit report action and dates are used to determine if a form is expired
    private static Boolean isCurrentFormExpired(List<PassfortAuditReport> auditReports) {

        Boolean isExpired = false;
        Long latestInstatiatedFormDate = 0L;
        Long latestExpiredFormDate = 0L;

        for (PassfortAuditReport currentAuditReport : auditReports) {
            // A form is created for the profile
            if (currentAuditReport.action.equals('instantiated-form')) {
                latestInstatiatedFormDate = currentAuditReport.timestamp;
            // A form is expired for the profile
            } else if (currentAuditReport.action.equals('expired-form')) {
                latestExpiredFormDate = currentAuditReport.timestamp;
            }
        }

        if (latestInstatiatedFormDate < latestExpiredFormDate) {
            isExpired = true;
        }

        return isExpired;
    }
}