trigger WorkOrderLineItemTrigger on WorkOrderLineItem(
    after insert, after update, after delete, after undelete
) {
    WorkOrderLineItemRollupHandler.enqueueRebuildWorkOrderTables(
        Trigger.isDelete ? Trigger.old : Trigger.new,
        Trigger.isDelete ? Trigger.oldMap : Trigger.newMap,
        Trigger.isUpdate ? Trigger.oldMap : null,
        Trigger.operationType
    );

    if (Trigger.isAfter) {
        WorkOrderOpportunityProductSync.syncFromWorkOrder(
            Trigger.isDelete ? null : Trigger.new,
            Trigger.oldMap,
            Trigger.isDelete
        );
    }
    
    
    if (!Trigger.isAfter) return;

    List<WorkOrderLineItem> rows = Trigger.isDelete ? Trigger.old : Trigger.new;
    if (rows == null || rows.isEmpty()) return;

    // Collect WorkOrderIds from the affected WOLIs
    Set<Id> workOrderIds = new Set<Id>();
    for (WorkOrderLineItem w : rows) {
        if (w != null && w.WorkOrderId != null) {
            workOrderIds.add(w.WorkOrderId);
        }
    }
    if (workOrderIds.isEmpty()) return;

    // Lookup the FSL Work Order record type id (SOQL, cached in handler or here)
    Id fslRtId;
    List<RecordType> rts = [
        SELECT Id
        FROM RecordType
        WHERE SObjectType = 'WorkOrder'
          AND DeveloperName = 'FSL_Work_Order'
        LIMIT 1
    ];
    if (rts.isEmpty()) return;
    fslRtId = rts[0].Id;

    // Filter Work Orders to only FSL
    Set<Id> fslWorkOrderIds = new Set<Id>();
    for (WorkOrder wo : [
        SELECT Id
        FROM WorkOrder
        WHERE Id IN :workOrderIds
          AND RecordTypeId = :fslRtId
    ]) {
        fslWorkOrderIds.add(wo.Id);
    }
    if (fslWorkOrderIds.isEmpty()) return;

    // Only pass WOLIs that belong to FSL Work Orders
    List<WorkOrderLineItem> fslRows = new List<WorkOrderLineItem>();
    for (WorkOrderLineItem w : rows) {
        if (fslWorkOrderIds.contains(w.WorkOrderId)) {
            fslRows.add(w);
        }
    }
    if (fslRows.isEmpty()) return;

    WorkOrderLineItemRollupHandler.rebuildWorkOrderTables(
        fslRows,
        Trigger.isDelete ? Trigger.oldMap : Trigger.newMap,
        Trigger.isUpdate ? Trigger.oldMap : null,
        Trigger.operationType
    );
}