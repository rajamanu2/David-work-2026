// Official Passfort documentation https://developer.passfort.com/api#tag/Audit/paths/~1profiles~1%7Bprofile_id%7D~1audit-items/get

public with sharing class PassfortAuditReport {
    
    public String action;
    public String filename;
    public String id;
    public String message;
    public String profileID;
    public PassfortAuditReport.refData ref_data;
    public String signature;
    public Long timestamp;
    public PassfortAuditReport.User user;
    public PassfortAuditReport.ApiKey apikey;
    public String filehash;

    public class refData {}
    
    public class User {
        public String email;
        public String id;
        public Boolean is_active;
        public String name;
    }
    
    public class ApiKey {}

    public static List<PassfortAuditReport> parseMultiple(String jsonString) {

        List<PassfortAuditReport> auditList = new List<PassfortAuditReport>();

        try {
            JSONParser parser = JSON.createParser(jsonString);
    
            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                    while (parser.nextToken() != JSONToken.END_ARRAY) {
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                            PassfortAuditReport audit = (PassfortAuditReport) parser.readValueAs(PassfortAuditReport.class);
                            auditList.add(audit);
                            // Skip any nested objects/arrays to speed the parse. Remove if needed
                            parser.skipChildren();
                        }                    
                    }
                }
            }
        } catch (Exception e) {
            throw new PassfortAuditReportException('Failed to parseMultiple: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }

        return auditList;
    }

    public class PassfortAuditReportException extends Exception {}
}