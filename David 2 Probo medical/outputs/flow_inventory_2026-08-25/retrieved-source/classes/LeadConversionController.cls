public with sharing class LeadConversionController {

    // ---------- Response DTO ----------
    public class ConvertResponse {
        @AuraEnabled public Id accountId;
        @AuraEnabled public Id contactId;
        @AuraEnabled public Id opportunityId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String contactName;
        @AuraEnabled public String opportunityName;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Id serviceContractId;
        @AuraEnabled public String serviceContractName;
        @AuraEnabled public String serviceContractSObject; // 'ServiceContract' or custom object API name

    }

        public class LeadPrefill {
        @AuraEnabled public Id relatedAccountId;
        @AuraEnabled public String relatedAccountName;
        @AuraEnabled public Id matchedContactId;
        @AuraEnabled public String matchedContactName;
        @AuraEnabled public String opportunityNumber;
    }

    // Generic row (id + label + subtitle) for lookups
    public class LookupRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String label;
        @AuraEnabled public String subtitle;
        @AuraEnabled public String meta;        // already used by other lookups
        @AuraEnabled public Id parentId;        // <-- NEW (e.g., Opportunity's AccountId)
        @AuraEnabled public String parentName;  // <-- NEW (e.g., Opportunity's Account.Name)
        public LookupRow() {}
        public LookupRow(Id i, String l, String s) { id = i; label = l; subtitle = s; }
    }

    // Simple Id/Name pair (for record types)
    public class IdName {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        public IdName() {}
        public IdName(Id i, String n) { id = i; name = n; }
    }

    // ---------- Convert (single, unique Aura method) ----------
    @AuraEnabled(cacheable=false)
    public static ConvertResponse convertLeadFlat(
        Id      leadId,
        Id      accountId,
        Id      contactId,
        Id      opportunityId,
        Boolean createOpportunity,
        String  opportunityName,
        Id      opportunityRecordTypeId   // optional, for new Opp only
    ) {
        if (leadId == null) return error('Lead Id is required.');
    
        LeadStatus convertedStatus = [
            SELECT MasterLabel
            FROM LeadStatus
            WHERE IsConverted = true
            ORDER BY SortOrder
            LIMIT 1
        ];
    
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadId);
        lc.setConvertedStatus(convertedStatus.MasterLabel);
        
        // ✅ Force converted records to be owned by a User (current user)
        lc.setOwnerId(UserInfo.getUserId());
    
        if (accountId != null) lc.setAccountId(accountId);
        if (contactId != null) lc.setContactId(contactId);
    
        // Opportunity handling
        if (createOpportunity == true) {
            lc.setDoNotCreateOpportunity(false);
            if (opportunityId != null) {
                lc.setOpportunityId(opportunityId); // use existing opp
            } else {
                if (String.isBlank(opportunityName)) {
                    return error('Opportunity Name is required to create a new Opportunity.');
                }
                lc.setOpportunityName(opportunityName.trim()); // create new opp
                // NOTE: LeadConvert cannot set RecordType here; we update it after convert.
            }
        } else {
            if (opportunityId != null) {
                lc.setDoNotCreateOpportunity(false);
                lc.setOpportunityId(opportunityId);
            } else {
                lc.setDoNotCreateOpportunity(true);
            }
        }
    
        Database.LeadConvertResult lcr = Database.convertLead(lc, true);
        if (!lcr.isSuccess()) return error(joinMessages(lcr.getErrors()));
    
        ConvertResponse resp = new ConvertResponse();
        resp.success = true;
        resp.message = 'Lead converted successfully.';
        resp.accountId = lcr.getAccountId();
        resp.contactId = lcr.getContactId();
        resp.opportunityId = lcr.getOpportunityId();
        
        if (resp.opportunityId != null) {
            Opportunity o2 = [
                SELECT Id, Service_Contract__c, Service_Contract__r.Name
                FROM Opportunity
                WHERE Id = :resp.opportunityId
                LIMIT 1
            ];
            if (o2.Service_Contract__c != null) {
                resp.serviceContractId = o2.Service_Contract__c;
                resp.serviceContractName = o2.Service_Contract__r.Name;
                // Derive the API name from the Id’s sObjectType for robust linking
                resp.serviceContractSObject = String.valueOf(
                    o2.Service_Contract__c.getSObjectType().getDescribe().getName()
                );
            }
        }

    
        // --- POST-CONVERSION: set record type on newly created opp (if requested) ---
        // Only when we asked to create a NEW opp (no existing opportunityId was passed)
        if (createOpportunity == true
            && opportunityId == null
            && opportunityRecordTypeId != null
            && resp.opportunityId != null) {
            try {
                update new Opportunity(Id = resp.opportunityId, RecordTypeId = opportunityRecordTypeId);
            } catch (DmlException dmx) {
                // Keep conversion success; append a warning to the message for visibility
                resp.message += ' (Warning: could not set Opportunity Record Type - ' + dmx.getDmlMessage(0) + ')';
            }
        }
    
        // Names for LWC display
        if (resp.accountId != null)     resp.accountName     = [SELECT Name FROM Account     WHERE Id = :resp.accountId].Name;
        if (resp.contactId != null)     resp.contactName     = [SELECT Name FROM Contact     WHERE Id = :resp.contactId].Name;
        if (resp.opportunityId != null) resp.opportunityName = [SELECT Name FROM Opportunity WHERE Id = :resp.opportunityId].Name;
    
        return resp;
    }
    
    // ---------- Lookup: Get Service Account Information ----------
    public class IdNameType {
    @AuraEnabled public Id id;
    @AuraEnabled public String name;
    @AuraEnabled public String sobjectApiName;
    public IdNameType() {}
    public IdNameType(Id i, String n, String s) { id = i; name = n; sobjectApiName = s; }
    }
    
    @AuraEnabled(cacheable=true)
    public static IdNameType getServiceContractForOpp(Id opportunityId) {
        IdNameType out = new IdNameType();
        if (opportunityId == null) return out;
    
        Opportunity o = [
            SELECT Service_Contract__c, Service_Contract__r.Name
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        if (o.Service_Contract__c != null) {
            out.id = o.Service_Contract__c;
            out.name = o.Service_Contract__r.Name;
            out.sobjectApiName = String.valueOf(
                o.Service_Contract__c.getSObjectType().getDescribe().getName()
            );
        }
        return out;
    }


    // ---------- Lookup: Opportunity by custom number ----------
    @AuraEnabled(cacheable=true)
    public static List<LookupRow> searchOpportunitiesByNumber(String searchTerm, Integer limitSize) {
        List<LookupRow> out = new List<LookupRow>();
        if (String.isBlank(searchTerm)) return out;

        Integer lim = (limitSize == null || limitSize <= 0) ? 20 : Math.min(50, limitSize);
        String likeTerm = '%' + searchTerm.replaceAll('[^a-zA-Z0-9]', '%') + '%';
        Boolean termIsNumeric = searchTerm.replaceAll('\\D', '').length() == searchTerm.length();
        List<Opportunity> opps;

        if (termIsNumeric) {
            opps = [
                SELECT Id, Name, StageName, Account.Name, Opportunity_Number__c, AccountId
                FROM Opportunity
                WHERE Opportunity_Number__c = :searchTerm
                ORDER BY LastModifiedDate DESC
                LIMIT :lim
            ];
            if (opps.isEmpty()) {
                opps = [
                    SELECT Id, Name, StageName, Account.Name, Opportunity_Number__c, AccountId
                    FROM Opportunity
                    WHERE Opportunity_Number__c LIKE :likeTerm
                    ORDER BY Opportunity_Number__c
                    LIMIT :lim
                ];
            }
        } else {
            opps = [
                SELECT Id, Name, StageName, Account.Name, Opportunity_Number__c, AccountId
                FROM Opportunity
                WHERE Opportunity_Number__c LIKE :likeTerm
                ORDER BY Opportunity_Number__c
                LIMIT :lim
            ];
        }

        for (Opportunity o : opps) {
            String subtitle = (o.Name == null ? '' : o.Name) +
                (o.StageName == null ? '' : ' • ' + o.StageName) +
                (o.Account != null && o.Account.Name != null ? ' • ' + o.Account.Name : '');
            LookupRow r = new LookupRow(o.Id, o.Opportunity_Number__c, subtitle);
            r.parentId = o.AccountId;
            r.parentName = (o.Account != null ? o.Account.Name : null);
            out.add(r);
        }
        return out;
    }

    // ---------- Lookup: Contacts under a specific Account ----------
    @AuraEnabled(cacheable=true)
    public static List<LookupRow> searchContactsForAccount(Id accountId, String searchTerm, Integer limitSize) {
        List<LookupRow> out = new List<LookupRow>();
        if (accountId == null || String.isBlank(searchTerm)) return out;

        Integer lim = (limitSize == null || limitSize <= 0) ? 20 : Math.min(50, limitSize);
        String likeTerm = '%' + searchTerm.trim() + '%';

        for (Contact c : [
            SELECT Id, Name, Email, Phone
            FROM Contact
            WHERE AccountId = :accountId
              AND (Name LIKE :likeTerm OR Email LIKE :likeTerm OR Phone LIKE :likeTerm)
            ORDER BY Name
            LIMIT :lim
        ]) {
            String subtitle = (c.Email != null ? c.Email : (c.Phone != null ? c.Phone : ''));
            out.add(new LookupRow(c.Id, c.Name, subtitle));
        }
        return out;
    }

    // ---------- Picklist: Opportunity record types (alphabetical, active) ----------
    @AuraEnabled(cacheable=true)
    public static List<IdName> getOpportunityRecordTypes() {
        List<IdName> out = new List<IdName>();
        for (RecordType rt : [
            SELECT Id, Name
            FROM RecordType
            WHERE SobjectType = 'Opportunity' AND IsActive = true
            ORDER BY Name ASC
        ]) {
            out.add(new IdName(rt.Id, rt.Name));
        }
        return out;
    }
    
        // ---------- Prefill loader ----------
    @AuraEnabled(cacheable=true)
    public static LeadPrefill getLeadPrefill(Id leadId) {
        LeadPrefill out = new LeadPrefill();
        if (leadId == null) return out;
    
        // Pull the three custom fields + names in one query
        Lead l = [
            SELECT
                Related_Account__c,
                Related_Account__r.Name,
                Matched_Contact__c,
                Matched_Contact__r.Name,
                Opportunity__c
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];
    
        out.relatedAccountId   = l.Related_Account__c;
        out.relatedAccountName = (l.Related_Account__c != null) ? l.Related_Account__r.Name : null;
        out.matchedContactId   = l.Matched_Contact__c;
        out.matchedContactName = (l.Matched_Contact__c != null) ? l.Matched_Contact__r.Name : null;
        out.opportunityNumber  = l.Opportunity__c;
    
        return out;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<LookupRow> searchAccountsRich(String searchTerm, Integer limitSize) {
        List<LookupRow> out = new List<LookupRow>();
        if (String.isBlank(searchTerm)) return out;
    
        Integer lim = (limitSize == null || limitSize <= 0) ? 20 : Math.min(50, limitSize);
        String likeTerm = '%' + searchTerm.trim() + '%';
    
        List<Account> rows = [
            SELECT Id, Name,
                   BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                   Payment_Terms__c
            FROM Account
            WHERE Name LIKE :likeTerm
               OR BillingStreet LIKE :likeTerm
               OR BillingCity LIKE :likeTerm
               OR BillingState LIKE :likeTerm
               OR BillingPostalCode LIKE :likeTerm
               OR BillingCountry LIKE :likeTerm
               OR Payment_Terms__c LIKE :likeTerm
            ORDER BY Name
            LIMIT :lim
        ];
    
        for (Account a : rows) {
            List<String> parts = new List<String>{ a.BillingStreet, a.BillingCity, a.BillingState, a.BillingPostalCode, a.BillingCountry };
            for (Integer i = parts.size()-1; i >= 0; i--) if (String.isBlank(parts[i])) parts.remove(i);
            String addr = String.join(parts, ', ');
    
            LookupRow r = new LookupRow(a.Id, a.Name, addr);
            r.meta = a.Payment_Terms__c; // <-- Terms separately
            out.add(r);
        }
        return out;
    }




    // ---------- helpers ----------
    private static ConvertResponse error(String msg) {
        ConvertResponse r = new ConvertResponse();
        r.success = false; r.message = msg; return r;
    }
    private static String joinMessages(Database.Error[] errs) {
        List<String> msgs = new List<String>();
        for (Database.Error e : errs) msgs.add(e.getMessage());
        return String.join(msgs, ' ');
    }
}