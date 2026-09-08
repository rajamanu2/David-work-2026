public virtual with sharing class OppContactRolesBaseController {

    public Id opportunityId { get; private set; }
    public String mode { get; private set; } // 'add' or 'edit'

    public List<OpportunityContactRole> rows { get; private set; }
    public List<RowWrap> rowWraps { get; private set; }

    public Integer rowIndex { get; set; }

    private List<OpportunityContactRole> rowsToDelete = new List<OpportunityContactRole>();

    public class RowWrap {
        public Integer idx { get; set; }
        public OpportunityContactRole r { get; set; }
        public RowWrap(Integer i, OpportunityContactRole rec) { idx = i; r = rec; }
    }

    // Derived controllers call init('add') or init('edit')
    protected void init(String modeArg) {
        mode = String.isBlank(modeArg) ? 'edit' : modeArg.toLowerCase();
        opportunityId = ApexPages.currentPage().getParameters().get('id');

        rows = new List<OpportunityContactRole>();

        if (opportunityId == null) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Missing Opportunity Id. Pass ?id=<OpportunityId>.'
            ));
            rebuildWraps();
            return;
        }

        if (mode == 'edit') {
            List<OpportunityContactRole> existing = [
                SELECT Id, OpportunityId, ContactId, Role, IsPrimary
                FROM OpportunityContactRole
                WHERE OpportunityId = :opportunityId
                ORDER BY IsPrimary DESC, CreatedDate ASC
            ];
            
    if (existing.isEmpty()) {
        // If no existing roles, show one row so user can start without clicking Add Row
        rows.add(new OpportunityContactRole(OpportunityId = opportunityId));
    } else {
        // Otherwise show ONLY existing rows (no blank row)
        rows.addAll(existing);
    }
        } else {
            // add mode starts with one blank row
            rows.add(new OpportunityContactRole(OpportunityId = opportunityId));
        }

        rebuildWraps();
    }

    public String getTitle() {
        return (mode == 'add') ? 'Add Contact Roles' : 'Edit Contact Roles';
    }

    private void rebuildWraps() {
        rowWraps = new List<RowWrap>();
        for (Integer i = 0; i < rows.size(); i++) {
            rowWraps.add(new RowWrap(i, rows[i]));
        }
    }

    public PageReference addRow() {
        rows.add(new OpportunityContactRole(OpportunityId = opportunityId));
        rebuildWraps();
        return null;
    }

    public PageReference removeRow() {
        if (rowIndex == null || rowIndex < 0 || rowIndex >= rows.size()) return null;

        OpportunityContactRole target = rows[rowIndex];
        if (target != null && target.Id != null) {
            rowsToDelete.add(target);
        }

        rows.remove(rowIndex);
        rebuildWraps();
        return null;
    }

    public PageReference save() {
        if (opportunityId == null) return null;

        List<OpportunityContactRole> toInsert = new List<OpportunityContactRole>();
        List<OpportunityContactRole> toUpdate = new List<OpportunityContactRole>();

        Integer primaryCount = 0;

        for (OpportunityContactRole r : rows) {
            Boolean blankNew =
                r.Id == null &&
                r.ContactId == null &&
                String.isBlank(r.Role) &&
                (r.IsPrimary == null || r.IsPrimary == false);

            if (blankNew) continue;

            // Required fields
            if (r.ContactId == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                    'Contact is required on all non-empty rows.'
                ));
                return null;
            }
            if (String.isBlank(r.Role)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                    'Role is required on all non-empty rows.'
                ));
                return null;
            }

            r.OpportunityId = opportunityId;

            if (r.IsPrimary == true) primaryCount++;

            if (r.Id == null) toInsert.add(r);
            else toUpdate.add(r);
        }

        if (primaryCount > 1) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                'Only one Contact Role can be marked Primary.'
            ));
            return null;
        }

        try {
            if (!rowsToDelete.isEmpty()) {
                delete rowsToDelete;
                rowsToDelete.clear();
            }

            // Respect FLS
            if (!toInsert.isEmpty()) {
                SObjectAccessDecision decIns = Security.stripInaccessible(AccessType.CREATABLE, toInsert);
                Database.SaveResult[] insResults = Database.insert(decIns.getRecords(), false);
                String insErr = firstDmlError(insResults);
                if (insErr != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, insErr));
                    rebuildWraps();
                    return null;
                }
            }

            if (!toUpdate.isEmpty()) {
                SObjectAccessDecision decUpd = Security.stripInaccessible(AccessType.UPDATABLE, toUpdate);
                Database.SaveResult[] updResults = Database.update(decUpd.getRecords(), false);
                String updErr = firstDmlError(updResults);
                if (updErr != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, updErr));
                    rebuildWraps();
                    return null;
                }
            }

            PageReference pr = new PageReference('/' + opportunityId);
            pr.setRedirect(true);
            return pr;

        } catch (DmlException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
            rebuildWraps();
            return null;
        }
    }

    private static String firstDmlError(Database.SaveResult[] results) {
        if (results == null) return null;
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                if (sr.getErrors() != null && sr.getErrors().size() > 0) {
                    return sr.getErrors()[0].getMessage();
                }
                return 'Unknown DML error.';
            }
        }
        return null;
    }

    public PageReference cancel() {
        PageReference pr = new PageReference('/' + opportunityId);
        pr.setRedirect(true);
        return pr;
    }
}