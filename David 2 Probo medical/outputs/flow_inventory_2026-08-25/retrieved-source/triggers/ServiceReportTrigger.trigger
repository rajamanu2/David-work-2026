trigger ServiceReportTrigger on ServiceReport (before insert, after insert, after update) {

    if (Trigger.isBefore && Trigger.isInsert) {
        ContentDocumentLinkToWorkOrderSync.validateServiceReportWorkOrderPoNumber(Trigger.new);
    }
    
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        // Cast to SObject types to match handler signature (List<SObject>, Map<Id,SObject>)
        List<SObject> newList = new List<SObject>();
        newList.addAll(Trigger.new);

        Map<Id, SObject> oldMapSobj = null;
        if (Trigger.isUpdate && Trigger.oldMap != null) {
            oldMapSobj = new Map<Id, SObject>();
            for (Id key : Trigger.oldMap.keySet()) {
                oldMapSobj.put(key, Trigger.oldMap.get(key));
            }
        }

        ContentDocumentLinkToWorkOrderSync.handleServiceReportAfterUpsert(
            newList,
            oldMapSobj
        );
    }
}