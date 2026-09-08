public with sharing class WorkOrderOpportunityProductSync {
    private static final String FSL_WORK_ORDER_RECORD_TYPE = 'FSL_Work_Order';
    private static final String US_COUNTRY = 'United States';
    private static final String WARRANTY_BILLING_TYPE = 'Warranty';
    private static final String CONTRACT_BILLING_TYPE = 'Contract';
    private static final String TIME_AND_MATERIAL_BILLING_TYPE = 'Time & Material';
    private static final String PART_RETURN_LINE_TYPE = 'Part Return';
    private static final String EXCLUDED_PRODUCT_NAME = 'Technician Removed Part/Probe';

    private static Boolean syncingFromOpportunity = false;
    private static Boolean syncingFromWorkOrder = false;

    // Pending swap cache intentionally removed for async safety.

    public static void enqueueFromOpportunity(
        List<OpportunityLineItem> newRows,
        Map<Id, OpportunityLineItem> oldMap,
        Boolean isDelete
    ) {
        // Prevent "Future method cannot be called from a future or batch method" failures
        // when OLI triggers fire from async sync operations.
        if (System.isFuture() || System.isBatch() || System.isQueueable()) {
            if (isDelete) {
                syncFromOpportunity(null, oldMap, true);
            } else {
                syncFromOpportunityById(collectOpportunityLineItemIds(newRows));
            }
            return;
        }

        if (isDelete) {
            List<Id> deletedOliIds = new List<Id>();
            List<Id> deletedOppIds = new List<Id>();
            List<Id> deletedWoliIds = new List<Id>();
            Set<Id> oppIds = new Set<Id>();

            if (oldMap != null) {
                for (OpportunityLineItem oldRow : oldMap.values()) {
                    if (oldRow == null || oldRow.Id == null || oldRow.OpportunityId == null) {
                        continue;
                    }
                    deletedOliIds.add(oldRow.Id);
                    deletedOppIds.add(oldRow.OpportunityId);
                    deletedWoliIds.add(oldRow.Work_Order_Line_Item__c);
                    oppIds.add(oldRow.OpportunityId);
                }
            }

            Set<Id> eligibleOppIds = getEligibleOpportunityIds(oppIds);
            if (!deletedOliIds.isEmpty() && !eligibleOppIds.isEmpty()) {
                List<Id> filteredOliIds = new List<Id>();
                List<Id> filteredOppIds = new List<Id>();
                List<Id> filteredWoliIds = new List<Id>();
                for (Integer i = 0; i < deletedOppIds.size(); i++) {
                    if (eligibleOppIds.contains(deletedOppIds[i])) {
                        filteredOliIds.add(deletedOliIds[i]);
                        filteredOppIds.add(deletedOppIds[i]);
                        filteredWoliIds.add(deletedWoliIds[i]);
                    }
                }

                if (!filteredOliIds.isEmpty()) {
                    syncFromOpportunityDeleteFuture(filteredOliIds, filteredOppIds, filteredWoliIds);
                }
            }
            return;
        }

        List<Id> newOliIds = new List<Id>();
        Set<Id> oppIds = new Set<Id>();
        if (newRows != null) {
            for (OpportunityLineItem row : newRows) {
                if (row == null || row.Id == null || row.OpportunityId == null) {
                    continue;
                }
                newOliIds.add(row.Id);
                oppIds.add(row.OpportunityId);
            }
        }

        Set<Id> eligibleOppIds = getEligibleOpportunityIds(oppIds);
        if (!newOliIds.isEmpty() && !eligibleOppIds.isEmpty()) {
            List<Id> filteredOliIds = new List<Id>();
            for (OpportunityLineItem row : newRows) {
                if (row != null
                    && row.Id != null
                    && row.OpportunityId != null
                    && eligibleOppIds.contains(row.OpportunityId)) {
                    filteredOliIds.add(row.Id);
                }
            }
            if (!filteredOliIds.isEmpty()) {
                syncFromOpportunityUpsertFuture(filteredOliIds);
            }
        }
    }

    private static Set<Id> collectOpportunityLineItemIds(List<OpportunityLineItem> rows) {
        Set<Id> ids = new Set<Id>();
        if (rows == null) {
            return ids;
        }

        for (OpportunityLineItem row : rows) {
            if (row != null && row.Id != null) {
                ids.add(row.Id);
            }
        }
        return ids;
    }

    private static void syncFromOpportunityById(Set<Id> oliIds) {
        if (oliIds == null || oliIds.isEmpty()) {
            return;
        }

        List<OpportunityLineItem> rows = [
            SELECT Id,
                   OpportunityId,
                   Description,
                   Quantity,
                   UnitPrice,
                   PricebookEntryId,
                   ProductItem__c,
                   Product2Id,
                   Product2.Name,
                   Exchange__c,
                   Work_Order_Line_Item__c
            FROM OpportunityLineItem
            WHERE Id IN :oliIds
        ];

        if (!rows.isEmpty()) {
            syncFromOpportunity(rows, null, false);
        }
    }

    @future
    private static void syncFromOpportunityUpsertFuture(List<Id> oliIds) {
        if (oliIds == null || oliIds.isEmpty()) {
            return;
        }

        syncFromOpportunityById(new Set<Id>(oliIds));
    }

    @future
    private static void syncFromOpportunityDeleteFuture(List<Id> oliIds, List<Id> oppIds, List<Id> woliIds) {
        if (oliIds == null || oppIds == null || oliIds.isEmpty() || oppIds.isEmpty()) {
            return;
        }

        Integer rowCount = Math.min(oliIds.size(), oppIds.size());
        if (woliIds != null) {
            rowCount = Math.min(rowCount, woliIds.size());
        }

        Map<Id, OpportunityLineItem> oldMap = new Map<Id, OpportunityLineItem>();
        for (Integer i = 0; i < rowCount; i++) {
            Id oliId = oliIds[i];
            Id oppId = oppIds[i];
            if (oliId == null || oppId == null) {
                continue;
            }
            oldMap.put(oliId, new OpportunityLineItem(
                Id = oliId,
                OpportunityId = oppId,
                Work_Order_Line_Item__c = (woliIds == null ? null : woliIds[i])
            ));
        }

        if (!oldMap.isEmpty()) {
            syncFromOpportunity(null, oldMap, true);
        }
    }

    private static Set<Id> getEligibleOpportunityIds(Set<Id> oppIds) {
        Set<Id> eligibleOppIds = new Set<Id>();
        if (oppIds == null || oppIds.isEmpty()) {
            return eligibleOppIds;
        }

        for (Opportunity opp : [
            SELECT Id,
                   Related_Work_Order__r.RecordType.DeveloperName,
                   Related_Work_Order__r.Country,
                   Related_Work_Order__r.Billing_Type__c
            FROM Opportunity
            WHERE Id IN :oppIds
        ]) {
            if (isEligibleWorkOrder(opp.Related_Work_Order__r)) {
                eligibleOppIds.add(opp.Id);
            }
        }

        return eligibleOppIds;
    }

    public static void syncFromOpportunity(
        List<OpportunityLineItem> newRows,
        Map<Id, OpportunityLineItem> oldMap,
        Boolean isDelete
    ) {
        if (syncingFromWorkOrder) {
            return;
        }

        List<OpportunityLineItem> sourceRows = isDelete
            ? ((oldMap == null) ? new List<OpportunityLineItem>() : oldMap.values())
            : ((newRows == null) ? new List<OpportunityLineItem>() : newRows);

        if (sourceRows.isEmpty()) {
            return;
        }

        Set<Id> oppIds = new Set<Id>();
        Set<Id> oliIds = new Set<Id>();
        for (OpportunityLineItem oli : sourceRows) {
            if (oli == null) {
                continue;
            }
            if (oli.OpportunityId != null) {
                oppIds.add(oli.OpportunityId);
            }
            if (oli.Id != null) {
                oliIds.add(oli.Id);
            }
        }
        if (oppIds.isEmpty() || oliIds.isEmpty()) {
            return;
        }

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>([
            SELECT Id,
                   Related_Work_Order__c,
                   Related_Work_Order__r.RecordType.DeveloperName,
                   Related_Work_Order__r.Country,
                   Related_Work_Order__r.Billing_Type__c
            FROM Opportunity
            WHERE Id IN :oppIds
        ]);

        Set<Id> qualifiedWorkOrderIds = new Set<Id>();
        for (Opportunity opp : oppById.values()) {
            if (isEligibleWorkOrder(opp.Related_Work_Order__r)) {
                qualifiedWorkOrderIds.add(opp.Related_Work_Order__c);
            }
        }
        if (qualifiedWorkOrderIds.isEmpty()) {
            return;
        }

        Map<Id, List<WorkOrderLineItem>> wolisByOppProductId = new Map<Id, List<WorkOrderLineItem>>();
        for (WorkOrderLineItem matchedWoli : [
            SELECT Id,
                   WorkOrderId,
                   Opportunity_Product__c,
                   Description,
                   Quantity,
                   UnitPrice,
                   PricebookEntryId,
                   Part_Used__c,
                   Part_Name__c,
                   Line_Type__c,
                   Line_Intent__c,
                   CreatedDate
            FROM WorkOrderLineItem
            WHERE WorkOrderId IN :qualifiedWorkOrderIds
              AND Opportunity_Product__c IN :oliIds
            ORDER BY CreatedDate ASC
        ]) {
            if (matchedWoli.Opportunity_Product__c == null) {
                continue;
            }
            if (!wolisByOppProductId.containsKey(matchedWoli.Opportunity_Product__c)) {
                wolisByOppProductId.put(matchedWoli.Opportunity_Product__c, new List<WorkOrderLineItem>());
            }
            wolisByOppProductId.get(matchedWoli.Opportunity_Product__c).add(matchedWoli);
        }

        Set<Id> priorWoliIds = new Set<Id>();
        for (OpportunityLineItem oli : sourceRows) {
            if (oli != null && oli.Work_Order_Line_Item__c != null) {
                priorWoliIds.add(oli.Work_Order_Line_Item__c);
            }
        }

        Map<Id, WorkOrderLineItem> priorWoliById = priorWoliIds.isEmpty()
            ? new Map<Id, WorkOrderLineItem>()
            : new Map<Id, WorkOrderLineItem>([
                SELECT Id,
                       Line_Type__c
                FROM WorkOrderLineItem
                WHERE Id IN :priorWoliIds
            ]);

        syncingFromOpportunity = true;
        try {
            if (isDelete) {
                List<WorkOrderLineItem> woliDeletes = new List<WorkOrderLineItem>();
                Set<Id> targetedWoliIds = new Set<Id>();
                for (OpportunityLineItem oli : sourceRows) {
                    Opportunity opp = oppById.get(oli.OpportunityId);
                    if (opp == null || !isEligibleWorkOrder(opp.Related_Work_Order__r)) {
                        continue;
                    }

                    if (oli.Work_Order_Line_Item__c != null) {
                        targetedWoliIds.add(oli.Work_Order_Line_Item__c);
                        continue;
                    }

                    List<WorkOrderLineItem> existingRows = wolisByOppProductId.get(oli.Id);
                    if (existingRows == null || existingRows.isEmpty()) {
                        continue;
                    }

                    // Fallback only when no explicit prior WOLI link is available.
                    woliDeletes.add(new WorkOrderLineItem(Id = existingRows[0].Id));
                }

                for (Id targetedWoliId : targetedWoliIds) {
                    woliDeletes.add(new WorkOrderLineItem(Id = targetedWoliId));
                }

                if (!woliDeletes.isEmpty()) {
                    delete woliDeletes;
                }
                return;
            }

            List<WorkOrderLineItem> wolisToUpdate = new List<WorkOrderLineItem>();
            Map<Id, OpportunityLineItem> oliUpdates = new Map<Id, OpportunityLineItem>();
            Set<Id> oliIdsForAsyncWoliInsert = new Set<Id>();

            for (OpportunityLineItem source : sourceRows) {
                Opportunity opp = oppById.get(source.OpportunityId);
                if (opp == null || !isEligibleWorkOrder(opp.Related_Work_Order__r)) {
                    continue;
                }

                List<WorkOrderLineItem> existingRows = wolisByOppProductId.get(source.Id);
                WorkOrderLineItem existing = (existingRows == null || existingRows.isEmpty()) ? null : existingRows[0];
                if (existing == null) {
                    oliIdsForAsyncWoliInsert.add(source.Id);
                } else {
                    WorkOrderLineItem toUpdate = new WorkOrderLineItem(Id = existing.Id);
                    mapOpportunityLineItemToWorkOrderLineItem(source, toUpdate, false);
                    applyIntentFromExchangeWhenEligible(source, toUpdate, existing.Line_Type__c, existing.Line_Intent__c);
                    if (isDifferent(existing, toUpdate)) {
                        wolisToUpdate.add(toUpdate);
                    }
                    if (source.Work_Order_Line_Item__c == null || source.Work_Order_Line_Item__c != existing.Id) {
                        oliUpdates.put(source.Id, new OpportunityLineItem(
                            Id = source.Id,
                            Work_Order_Line_Item__c = existing.Id
                        ));
                    }
                }
            }

            enqueueWoliInsertQueueable(oliIdsForAsyncWoliInsert);

            List<WorkOrderLineItem> duplicateWolisToDelete = new List<WorkOrderLineItem>();
            for (List<WorkOrderLineItem> existingRows : wolisByOppProductId.values()) {
                if (existingRows == null || existingRows.size() <= 1) {
                    continue;
                }
                for (Integer i = 1; i < existingRows.size(); i++) {
                    duplicateWolisToDelete.add(new WorkOrderLineItem(Id = existingRows[i].Id));
                }
            }
            if (!duplicateWolisToDelete.isEmpty()) {
                delete duplicateWolisToDelete;
            }


            if (!wolisToUpdate.isEmpty()) {
                update wolisToUpdate;
            }
            if (!oliUpdates.isEmpty()) {
                update oliUpdates.values();
            }
        } finally {
            syncingFromOpportunity = false;
        }
    }

    public static void syncFromWorkOrder(
        List<WorkOrderLineItem> newRows,
        Map<Id, WorkOrderLineItem> oldMap,
        Boolean isDelete
    ) {
        if (syncingFromOpportunity) {
            return;
        }

        List<WorkOrderLineItem> sourceRows = isDelete
            ? ((oldMap == null) ? new List<WorkOrderLineItem>() : oldMap.values())
            : ((newRows == null) ? new List<WorkOrderLineItem>() : newRows);
        if (sourceRows.isEmpty()) {
            return;
        }

        Set<Id> workOrderIds = new Set<Id>();
        for (WorkOrderLineItem sourceWoli : sourceRows) {
            if (sourceWoli != null && sourceWoli.WorkOrderId != null) {
                workOrderIds.add(sourceWoli.WorkOrderId);
            }
        }
        if (workOrderIds.isEmpty()) {
            return;
        }

        Map<Id, WorkOrder> woById = new Map<Id, WorkOrder>([
            SELECT Id,
                   Opportunity__c,
                   Opportunity__r.StageName,
                   RecordType.DeveloperName,
                   Country,
                   Billing_Type__c
            FROM WorkOrder
            WHERE Id IN :workOrderIds
        ]);

        Set<Id> eligibleWorkOrderIds = new Set<Id>();
        for (WorkOrder wo : woById.values()) {
            if (isEligibleWorkOrder(wo)) {
                eligibleWorkOrderIds.add(wo.Id);
            }
        }
        if (eligibleWorkOrderIds.isEmpty()) {
            return;
        }

        List<WorkOrderLineItem> eligibleSourceRows = new List<WorkOrderLineItem>();
        Set<Id> linkedOliIds = new Set<Id>();
        Set<Id> sourcePricebookEntryIds = new Set<Id>();
        for (WorkOrderLineItem sourceWoli : sourceRows) {
            if (sourceWoli == null || !eligibleWorkOrderIds.contains(sourceWoli.WorkOrderId)) {
                continue;
            }
            eligibleSourceRows.add(sourceWoli);
            if (sourceWoli.PricebookEntryId != null) {
                sourcePricebookEntryIds.add(sourceWoli.PricebookEntryId);
            }
            if (sourceWoli.Opportunity_Product__c != null) {
                linkedOliIds.add(sourceWoli.Opportunity_Product__c);
            }
        }
        if (eligibleSourceRows.isEmpty()) {
            return;
        }

        Map<Id, OpportunityLineItem> existingOliById = linkedOliIds.isEmpty()
            ? new Map<Id, OpportunityLineItem>()
            : new Map<Id, OpportunityLineItem>([
                SELECT Id,
                       OpportunityId,
                       Description,
                       Quantity,
                       UnitPrice,
                       PricebookEntryId,
                       ProductItem__c,
                       Purchasing_Approved__c,
                       Product2Id,
                       Exchange__c,
                       Work_Order_Line_Item__c
                FROM OpportunityLineItem
                WHERE Id IN :linkedOliIds
            ]);

        Map<Id, String> productNameByPricebookEntryId = new Map<Id, String>();
        if (!sourcePricebookEntryIds.isEmpty()) {
            for (PricebookEntry pbe : [
                SELECT Id, Product2.Name
                FROM PricebookEntry
                WHERE Id IN :sourcePricebookEntryIds
            ]) {
                productNameByPricebookEntryId.put(
                    pbe.Id,
                    pbe.Product2 == null ? null : pbe.Product2.Name
                );
            }
        }

        syncingFromWorkOrder = true;
        try {
            if (isDelete) {
                List<OpportunityLineItem> olisToDelete = new List<OpportunityLineItem>();
                for (WorkOrderLineItem sourceWoli : eligibleSourceRows) {
                    WorkOrder wo = woById.get(sourceWoli.WorkOrderId);
                    if (!isEligibleWorkOrder(wo) || sourceWoli.Opportunity_Product__c == null) {
                        continue;
                    }
                    if (existingOliById.containsKey(sourceWoli.Opportunity_Product__c)) {
                        olisToDelete.add(new OpportunityLineItem(Id = sourceWoli.Opportunity_Product__c));
                    }
                }
                if (!olisToDelete.isEmpty()) {
                    delete olisToDelete;
                }
                return;
            }

            List<OpportunityLineItem> olisToInsert = new List<OpportunityLineItem>();
            List<WorkOrderLineItem> sourceForInsert = new List<WorkOrderLineItem>();
            Map<Id, OpportunityLineItem> olisToUpdateById = new Map<Id, OpportunityLineItem>();
            List<WorkOrderLineItem> wolisToUpdate = new List<WorkOrderLineItem>();
            List<OpportunityLineItem> olisToDelete = new List<OpportunityLineItem>();

            for (WorkOrderLineItem source : eligibleSourceRows) {
                WorkOrder wo = woById.get(source.WorkOrderId);
                if (!isEligibleWorkOrder(wo) || wo.Opportunity__c == null) {
                    continue;
                }

                OpportunityLineItem existing = source.Opportunity_Product__c == null
                    ? null
                    : existingOliById.get(source.Opportunity_Product__c);

                String productName = source.PricebookEntryId == null
                    ? null
                    : productNameByPricebookEntryId.get(source.PricebookEntryId);

                if (isExcludedProductName(productName)) {
                    if (existing != null) {
                        olisToDelete.add(new OpportunityLineItem(Id = existing.Id));
                        wolisToUpdate.add(new WorkOrderLineItem(
                            Id = source.Id,
                            Opportunity_Product__c = null
                        ));
                    }
                    continue;
                }

                if (source.Line_Type__c == PART_RETURN_LINE_TYPE) {
                    if (existing != null
                        && wo.Billing_Type__c == TIME_AND_MATERIAL_BILLING_TYPE
                        && wo.Opportunity__r != null
                        && wo.Opportunity__r.StageName == 'Open') {
                        // Null the back-link on the OLI before deleting it so the async OLI-delete
                        // path in enqueueFromOpportunity sees Work_Order_Line_Item__c = null and
                        // does not attempt to cascade-delete this WOLI.
                        OpportunityLineItem linkClear = olisToUpdateById.containsKey(existing.Id)
                            ? olisToUpdateById.get(existing.Id)
                            : new OpportunityLineItem(Id = existing.Id);
                        linkClear.Work_Order_Line_Item__c = null;
                        olisToUpdateById.put(existing.Id, linkClear);
                        olisToDelete.add(new OpportunityLineItem(Id = existing.Id));
                        wolisToUpdate.add(new WorkOrderLineItem(
                            Id = source.Id,
                            Opportunity_Product__c = null
                        ));
                    }
                    continue;
                }

                if (existing == null) {
                    if (source.PricebookEntryId == null) {
                        continue;
                    }
                    OpportunityLineItem toInsert = new OpportunityLineItem(
                        OpportunityId = wo.Opportunity__c
                    );
                    mapWorkOrderLineItemToOpportunityLineItem(source, toInsert, true);
                    olisToInsert.add(toInsert);
                    sourceForInsert.add(source);
                } else {
                    OpportunityLineItem toUpdate = new OpportunityLineItem(Id = existing.Id);
                    mapWorkOrderLineItemToOpportunityLineItem(source, toUpdate, false);
                    if (isDifferent(existing, toUpdate)) {
                        olisToUpdateById.put(existing.Id, toUpdate);
                    }

                    if (existing.Work_Order_Line_Item__c == null || existing.Work_Order_Line_Item__c != source.Id) {
                        OpportunityLineItem linkUpdate = olisToUpdateById.containsKey(existing.Id)
                            ? olisToUpdateById.get(existing.Id)
                            : new OpportunityLineItem(Id = existing.Id);
                        linkUpdate.Work_Order_Line_Item__c = source.Id;
                        olisToUpdateById.put(existing.Id, linkUpdate);
                    }
                }
            }

            if (!olisToInsert.isEmpty()) {
                insert olisToInsert;
                for (Integer i = 0; i < olisToInsert.size(); i++) {
                    WorkOrderLineItem sourceWoli = sourceForInsert[i];
                    wolisToUpdate.add(new WorkOrderLineItem(
                        Id = sourceWoli.Id,
                        Opportunity_Product__c = olisToInsert[i].Id
                    ));
                    olisToUpdateById.put(olisToInsert[i].Id, new OpportunityLineItem(
                        Id = olisToInsert[i].Id,
                        Work_Order_Line_Item__c = sourceWoli.Id
                    ));
                }
            }

            if (!olisToUpdateById.isEmpty()) {
                update olisToUpdateById.values();
            }
            if (!olisToDelete.isEmpty()) {
                delete olisToDelete;
            }
            if (!wolisToUpdate.isEmpty()) {
                update wolisToUpdate;
            }
        } finally {
            syncingFromWorkOrder = false;
        }
    }

    private static Boolean isEligibleWorkOrder(WorkOrder wo) {
        return wo != null
            && wo.RecordType != null
            && wo.RecordType.DeveloperName == FSL_WORK_ORDER_RECORD_TYPE
            && wo.Country == US_COUNTRY
            && wo.Billing_Type__c != WARRANTY_BILLING_TYPE
            && wo.Billing_Type__c != CONTRACT_BILLING_TYPE;
    }

    private static void enqueueWoliInsertQueueable(Set<Id> opportunityLineItemIds) {
        if (opportunityLineItemIds == null || opportunityLineItemIds.isEmpty()) {
            return;
        }
        System.enqueueJob(new OpportunityToWorkOrderInsertQueueable(new List<Id>(opportunityLineItemIds)));
    }

    private static void performAsyncWoliInsert(List<Id> opportunityLineItemIds) {
        if (opportunityLineItemIds == null || opportunityLineItemIds.isEmpty()) {
            return;
        }

        Map<Id, OpportunityLineItem> oliById = new Map<Id, OpportunityLineItem>([
            SELECT Id,
                   OpportunityId,
                   Description,
                   Quantity,
                   UnitPrice,
                   PricebookEntryId,
                   ProductItem__c,
                   Product2Id,
                   Product2.Name,
                   Exchange__c,
                   Work_Order_Line_Item__c
            FROM OpportunityLineItem
            WHERE Id IN :opportunityLineItemIds
        ]);

        if (oliById.isEmpty()) {
            return;
        }

        Set<Id> oppIds = new Set<Id>();
        Set<Id> priorWoliIds = new Set<Id>();
        for (OpportunityLineItem oli : oliById.values()) {
            if (oli.OpportunityId != null) {
                oppIds.add(oli.OpportunityId);
            }
            if (oli.Work_Order_Line_Item__c != null) {
                priorWoliIds.add(oli.Work_Order_Line_Item__c);
            }
        }

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>([
            SELECT Id,
                   Related_Work_Order__c,
                   Related_Work_Order__r.RecordType.DeveloperName,
                   Related_Work_Order__r.Country,
                   Related_Work_Order__r.Billing_Type__c
            FROM Opportunity
            WHERE Id IN :oppIds
        ]);

        Map<Id, WorkOrderLineItem> existingWoliByOppProductId = new Map<Id, WorkOrderLineItem>();
        for (WorkOrderLineItem existingWoli : [
            SELECT Id,
                   Opportunity_Product__c,
                   Line_Type__c,
                   Line_Intent__c
            FROM WorkOrderLineItem
            WHERE Opportunity_Product__c IN :oliById.keySet()
            ORDER BY CreatedDate ASC
        ]) {
            if (existingWoli.Opportunity_Product__c != null && !existingWoliByOppProductId.containsKey(existingWoli.Opportunity_Product__c)) {
                existingWoliByOppProductId.put(existingWoli.Opportunity_Product__c, existingWoli);
            }
        }

        Map<Id, WorkOrderLineItem> priorWoliById = priorWoliIds.isEmpty()
            ? new Map<Id, WorkOrderLineItem>()
            : new Map<Id, WorkOrderLineItem>([
                SELECT Id,
                       Line_Type__c
                FROM WorkOrderLineItem
                WHERE Id IN :priorWoliIds
            ]);

        List<WorkOrderLineItem> wolisToInsert = new List<WorkOrderLineItem>();
        List<OpportunityLineItem> sourceForInsert = new List<OpportunityLineItem>();
        Map<Id, OpportunityLineItem> oliUpdatesById = new Map<Id, OpportunityLineItem>();

        for (OpportunityLineItem source : oliById.values()) {
            Opportunity opp = oppById.get(source.OpportunityId);
            if (opp == null || !isEligibleWorkOrder(opp.Related_Work_Order__r)) {
                continue;
            }

            WorkOrderLineItem existing = existingWoliByOppProductId.get(source.Id);
            if (existing != null) {
                if (source.Work_Order_Line_Item__c == null || source.Work_Order_Line_Item__c != existing.Id) {
                    oliUpdatesById.put(source.Id, new OpportunityLineItem(
                        Id = source.Id,
                        Work_Order_Line_Item__c = existing.Id
                    ));
                }
                continue;
            }

            WorkOrderLineItem toInsert = new WorkOrderLineItem(
                WorkOrderId = opp.Related_Work_Order__c
            );
            mapOpportunityLineItemToWorkOrderLineItem(source, toInsert, true);
            applyPreservedLineAttributes(source, toInsert, priorWoliById);
            applyIntentFromExchangeWhenEligible(source, toInsert, toInsert.Line_Type__c, null);
            wolisToInsert.add(toInsert);
            sourceForInsert.add(source);
        }

        if (!wolisToInsert.isEmpty()) {
            insert wolisToInsert;
            for (Integer i = 0; i < wolisToInsert.size(); i++) {
                oliUpdatesById.put(sourceForInsert[i].Id, new OpportunityLineItem(
                    Id = sourceForInsert[i].Id,
                    Work_Order_Line_Item__c = wolisToInsert[i].Id
                ));
            }
        }

        if (!oliUpdatesById.isEmpty()) {
            update oliUpdatesById.values();
        }
    }

    private class OpportunityToWorkOrderInsertQueueable implements Queueable {
        private final List<Id> opportunityLineItemIds;

        private OpportunityToWorkOrderInsertQueueable(List<Id> opportunityLineItemIds) {
            this.opportunityLineItemIds = opportunityLineItemIds;
        }

        public void execute(QueueableContext context) {
            performAsyncWoliInsert(opportunityLineItemIds);
        }
    }

    private static void applyPreservedLineAttributes(
        OpportunityLineItem source,
        WorkOrderLineItem target,
        Map<Id, WorkOrderLineItem> priorWoliById
    ) {
        if (target == null) {
            return;
        }

        WorkOrderLineItem priorWoli = (source == null || source.Work_Order_Line_Item__c == null || priorWoliById == null)
            ? null
            : priorWoliById.get(source.Work_Order_Line_Item__c);

        String priorLineType = priorWoli == null ? null : priorWoli.Line_Type__c;
        String derivedLineType = deriveLineTypeFromProductName(
            source != null && source.Product2 != null ? source.Product2.Name : null
        );
        if (derivedLineType != null) {
            target.Line_Type__c = derivedLineType;
        } else if (priorLineType == 'Labor' || priorLineType == 'Travel' || priorLineType == 'Shipping' || priorLineType == 'PM Call') {
            target.Line_Type__c = priorLineType;
        } else {
            target.Line_Type__c = 'Part Assigned';
        }
    }

    private static String deriveLineTypeFromProductName(String productName) {
        if (String.isBlank(productName)) {
            return null;
        }

        String normalizedName = productName.toLowerCase();
        if (normalizedName.contains('labor')) {
            return 'Labor';
        }
        if (normalizedName.contains('travel case')) {
            return null;
        }
        if (normalizedName.contains('travel')) {
            return 'Travel';
        }
        if (normalizedName.contains('ship')) {
            return 'Shipping';
        }
        if (normalizedName.contains('pm call')) {
            return 'PM Call';
        }
        return null;
    }

    private static void mapOpportunityLineItemToWorkOrderLineItem(OpportunityLineItem source, WorkOrderLineItem target, Boolean includePricebookEntry) {
        target.Description = source.Description;
        target.Quantity = source.Quantity;
        target.UnitPrice = source.UnitPrice;
        if (includePricebookEntry && source.PricebookEntryId != null) {
            target.PricebookEntryId = source.PricebookEntryId;
        }
        target.Part_Used__c = source.ProductItem__c;
        target.Opportunity_Product__c = source.Id;
        target.Line_Intent__c = deriveIntentFromExchange(source == null ? null : source.Exchange__c);

        // Store Product2 on the Work Order side for reference only.
        target.Part_Name__c = source.Product2Id;
    }

    private static void applyIntentFromExchangeWhenEligible(
        OpportunityLineItem source,
        WorkOrderLineItem target,
        String lineType,
        String existingLineIntent
    ) {
        if (target == null) {
            return;
        }

        // Never overwrite an already-set intent — only fire when the field is blank.
        if (String.isNotBlank(existingLineIntent)) {
            target.Line_Intent__c = existingLineIntent;
            return;
        }

        // Labor/Travel/Shipping/PM Call intents follow line type directly.
        if (lineType == 'Labor' || lineType == 'Travel' || lineType == 'Shipping' || lineType == 'PM Call') {
            target.Line_Intent__c = lineType;
            return;
        }

        target.Line_Intent__c = deriveIntentFromExchange(source == null ? null : source.Exchange__c);
    }

    private static String deriveIntentFromExchange(Boolean exchangeFlag) {
        return exchangeFlag == true ? 'Exchange' : 'Outright Sale';
    }

    private static void mapWorkOrderLineItemToOpportunityLineItem(WorkOrderLineItem source, OpportunityLineItem target, Boolean includePricebookEntry) {
        target.Description = source.Description;
        target.Quantity = source.Quantity;
        target.UnitPrice = source.UnitPrice;

        // For Opportunity Products, only drive product selection via PricebookEntryId.
        // Product2 is derived by Salesforce from the selected PricebookEntry.
        if (includePricebookEntry && source.PricebookEntryId != null) {
            target.PricebookEntryId = source.PricebookEntryId;
        }

        target.ProductItem__c = source.Part_Used__c;
        target.Purchasing_Approved__c = true;

        // Only set Exchange__c when creating a new OLI from a WOLI, not on subsequent edits.
        if (includePricebookEntry && source.Line_Type__c != 'Labor' && source.Line_Type__c != 'Travel' && source.Line_Type__c != 'Shipping' && source.Line_Type__c != 'PM Call') {
            if (source.Line_Intent__c == 'Exchange') {
                target.Exchange__c = true;
            } else if (source.Line_Intent__c == 'Outright Sale') {
                target.Exchange__c = false;
            }
        }
    }

    private static Boolean isDifferent(WorkOrderLineItem existing, WorkOrderLineItem candidate) {
        Boolean includesPricebookEntry = candidate.getPopulatedFieldsAsMap().containsKey('PricebookEntryId');
        return existing.Description != candidate.Description
            || existing.Quantity != candidate.Quantity
            || existing.UnitPrice != candidate.UnitPrice
            || (includesPricebookEntry && existing.PricebookEntryId != candidate.PricebookEntryId)
            || existing.Part_Used__c != candidate.Part_Used__c
            || existing.Part_Name__c != candidate.Part_Name__c
            || existing.Opportunity_Product__c != candidate.Opportunity_Product__c
            || existing.Line_Intent__c != candidate.Line_Intent__c;
    }

    @TestVisible
    private static Boolean test_isDifferentWoli(WorkOrderLineItem existing, WorkOrderLineItem candidate) {
        return isDifferent(existing, candidate);
    }

    private static Boolean isDifferent(OpportunityLineItem existing, OpportunityLineItem candidate) {
        Boolean includesPricebookEntry = candidate.getPopulatedFieldsAsMap().containsKey('PricebookEntryId');
        return existing.Description != candidate.Description
            || existing.Quantity != candidate.Quantity
            || existing.UnitPrice != candidate.UnitPrice
            || (includesPricebookEntry && existing.PricebookEntryId != candidate.PricebookEntryId)
            || existing.ProductItem__c != candidate.ProductItem__c
            || existing.Purchasing_Approved__c != candidate.Purchasing_Approved__c
            || existing.Exchange__c != candidate.Exchange__c;
    }

    @TestVisible
    private static Boolean test_isDifferentOli(OpportunityLineItem existing, OpportunityLineItem candidate) {
        return isDifferent(existing, candidate);
    }

    @TestVisible
    private static Boolean test_isExcludedProductName(String productName) {
        return isExcludedProductName(productName);
    }

    @TestVisible
    private static String test_deriveLineTypeFromProductName(String productName) {
        return deriveLineTypeFromProductName(productName);
    }

    @TestVisible
    private static String test_resolveLineIntent(String lineType, Boolean exchangeFlag, String existingLineIntent) {
        WorkOrderLineItem target = new WorkOrderLineItem();
        OpportunityLineItem source = new OpportunityLineItem(Exchange__c = exchangeFlag);
        applyIntentFromExchangeWhenEligible(source, target, lineType, existingLineIntent);
        return target.Line_Intent__c;
    }

    private static Boolean isExcludedProductName(String productName) {
        return productName == EXCLUDED_PRODUCT_NAME;
    }
}