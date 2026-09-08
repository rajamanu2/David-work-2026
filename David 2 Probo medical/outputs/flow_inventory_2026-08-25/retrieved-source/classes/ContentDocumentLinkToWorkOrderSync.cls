public with sharing class ContentDocumentLinkToWorkOrderSync {

    private static final String US_COUNTRY_VALUE = 'United States';
    private static final String WORKTYPE_NAME_PPM = 'PPM';
    private static final String US_REQUIRED_WO_FIELDSET = 'US_FSL_FSR_Required_Fields';
    private static final String US_REQUIRED_FIELDS_ERROR_MESSAGE = 'You can\'t create an FSR until required fields on the Work Order are filled out.';

    public static void validateServiceReportWorkOrderPoNumber(List<ServiceReport> newReports) {
        if (newReports == null || newReports.isEmpty()) return;

        Schema.FieldSet requiredFields = Schema.SObjectType.WorkOrder.FieldSets.getMap().get(US_REQUIRED_WO_FIELDSET);
        if (requiredFields == null || requiredFields.getFields().isEmpty()) return;

        Set<Id> saIds = new Set<Id>();
        Set<Id> woIds = new Set<Id>();

        for (ServiceReport report : newReports) {
            if (report == null || report.ParentId == null) continue;

            Schema.SObjectType parentType = report.ParentId.getSObjectType();
            if (parentType == ServiceAppointment.SObjectType) {
                saIds.add(report.ParentId);
            } else if (parentType == WorkOrder.SObjectType) {
                woIds.add(report.ParentId);
            }
        }

        if (saIds.isEmpty() && woIds.isEmpty()) return;

        Map<Id, ServiceAppointment> saById = saIds.isEmpty()
            ? new Map<Id, ServiceAppointment>()
            : new Map<Id, ServiceAppointment>([
                SELECT Id, ParentRecordId
                FROM ServiceAppointment
                WHERE Id IN :saIds
            ]);

        for (ServiceAppointment sa : saById.values()) {
            if (sa.ParentRecordId != null && sa.ParentRecordId.getSObjectType() == WorkOrder.SObjectType) {
                woIds.add(sa.ParentRecordId);
            }
        }

        if (woIds.isEmpty()) return;

        Set<String> woFieldsToQuery = new Set<String>{ 'Id', 'Country' };
        List<Schema.FieldSetMember> requiredFieldMembers = requiredFields.getFields();
        for (Schema.FieldSetMember fieldMember : requiredFieldMembers) {
            if (fieldMember == null || String.isBlank(fieldMember.getFieldPath())) continue;
            woFieldsToQuery.add(fieldMember.getFieldPath());
        }

        String query = 'SELECT ' + String.join(new List<String>(woFieldsToQuery), ',') +
            ' FROM WorkOrder WHERE Id IN :woIds';
        Map<Id, WorkOrder> woById = new Map<Id, WorkOrder>((List<WorkOrder>)Database.query(query));

        for (ServiceReport report : newReports) {
            if (report == null || report.ParentId == null) continue;
            if (!report.IsSigned) continue;

            Id woId = resolveWorkOrderId(report.ParentId, saById);
            if (woId == null) continue;

            WorkOrder wo = woById.get(woId);
            if (wo == null || wo.Country != US_COUNTRY_VALUE) continue;

            if (hasAnyMissingRequiredWorkOrderField(wo, requiredFieldMembers)) {
                report.addError(US_REQUIRED_FIELDS_ERROR_MESSAGE);
            }
        }
    }

    public static void handleAfterInsert(List<ContentDocumentLink> newLinks) {
        if (newLinks == null || newLinks.isEmpty()) return;

        Set<Id> saIds = new Set<Id>();
        List<ContentDocumentLink> saLinks = new List<ContentDocumentLink>();
        List<ContentDocumentLink> woLinks = new List<ContentDocumentLink>();
        Set<Id> woIds = new Set<Id>();

        for (ContentDocumentLink cdl : newLinks) {
            if (cdl == null || cdl.LinkedEntityId == null || cdl.ContentDocumentId == null) continue;

            if (cdl.LinkedEntityId.getSObjectType() == ServiceAppointment.SObjectType) {
                saIds.add(cdl.LinkedEntityId);
                saLinks.add(cdl);
            } else if (cdl.LinkedEntityId.getSObjectType() == WorkOrder.SObjectType) {
                woIds.add(cdl.LinkedEntityId);
                woLinks.add(cdl);
            }
        }

        if (saIds.isEmpty() && woIds.isEmpty()) return;

        Map<Id, ServiceAppointment> saById = saIds.isEmpty()
            ? new Map<Id, ServiceAppointment>()
            : new Map<Id, ServiceAppointment>([
                SELECT Id, ParentRecordId
                FROM ServiceAppointment
                WHERE Id IN :saIds
            ]);

        for (ServiceAppointment sa : saById.values()) {
            if (sa.ParentRecordId != null && sa.ParentRecordId.getSObjectType() == WorkOrder.SObjectType) {
                woIds.add(sa.ParentRecordId);
            }
        }

        Map<Id, WorkOrder> woById = woIds.isEmpty()
            ? new Map<Id, WorkOrder>()
            : new Map<Id, WorkOrder>([
                SELECT Id, Opportunity__c, Country
                FROM WorkOrder
                WHERE Id IN :woIds
            ]);

        Set<Id> docIds = new Set<Id>();
        Set<Id> targetIds = new Set<Id>();
        Set<String> desiredPairs = new Set<String>();
        Map<String, ContentDocumentLink> sourceLinkByPair = new Map<String, ContentDocumentLink>();

        for (ContentDocumentLink saLink : saLinks) {
            ServiceAppointment sa = saById.get(saLink.LinkedEntityId);
            if (sa == null || sa.ParentRecordId == null || sa.ParentRecordId.getSObjectType() != WorkOrder.SObjectType) continue;

            Id docId = saLink.ContentDocumentId;
            Id woId = sa.ParentRecordId;
            WorkOrder wo = woById.get(woId);

            if (wo == null || wo.Country != US_COUNTRY_VALUE) {
                continue;
            }

            addDesiredPair(docId, woId, saLink, desiredPairs, sourceLinkByPair, docIds, targetIds);

            if (wo != null && wo.Opportunity__c != null) {
                addDesiredPair(docId, wo.Opportunity__c, saLink, desiredPairs, sourceLinkByPair, docIds, targetIds);
            }
        }

        for (ContentDocumentLink woLink : woLinks) {
            Id woId = woLink.LinkedEntityId;
            WorkOrder wo = woById.get(woId);
            if (wo == null || wo.Country != US_COUNTRY_VALUE || wo.Opportunity__c == null) continue;

            addDesiredPair(woLink.ContentDocumentId, wo.Opportunity__c, woLink, desiredPairs, sourceLinkByPair, docIds, targetIds);
        }

        insertMissingLinks(desiredPairs, sourceLinkByPair, docIds, targetIds);

    }

    public static void handleServiceReportAfterUpsert(
        List<ServiceReport> newReports,
        Map<Id, ServiceReport> oldMap
    ) {
        if (newReports == null || newReports.isEmpty()) return;

        List<ServiceReport> reportsToProcess = new List<ServiceReport>();
        Set<Id> contentVersionIds = new Set<Id>();
        Set<Id> saIds = new Set<Id>();
        Set<Id> woIds = new Set<Id>();

        for (ServiceReport report : newReports) {
            if (report == null || report.ContentVersionDocumentId == null) continue;

            if (oldMap != null && report.Id != null) {
                ServiceReport oldReport = oldMap.get(report.Id);
                if (oldReport != null && oldReport.ContentVersionDocumentId == report.ContentVersionDocumentId) {
                    continue;
                }
            }

            reportsToProcess.add(report);
            contentVersionIds.add(report.ContentVersionDocumentId);

            if (report.ParentId != null) {
                Schema.SObjectType parentType = report.ParentId.getSObjectType();
                if (parentType == ServiceAppointment.SObjectType) {
                    saIds.add(report.ParentId);
                } else if (parentType == WorkOrder.SObjectType) {
                    woIds.add(report.ParentId);
                }
            }
        }

        if (reportsToProcess.isEmpty()) return;

        Map<Id, ContentVersion> contentVersions = contentVersionIds.isEmpty()
            ? new Map<Id, ContentVersion>()
            : new Map<Id, ContentVersion>([
                SELECT Id, ContentDocumentId, VersionNumber, VersionData, FileExtension
                FROM ContentVersion
                WHERE Id IN :contentVersionIds
            ]);

        Map<Id, ServiceAppointment> saById = saIds.isEmpty()
            ? new Map<Id, ServiceAppointment>()
            : new Map<Id, ServiceAppointment>([
                SELECT Id, ParentRecordId
                FROM ServiceAppointment
                WHERE Id IN :saIds
            ]);

        for (ServiceAppointment sa : saById.values()) {
            if (sa.ParentRecordId != null && sa.ParentRecordId.getSObjectType() == WorkOrder.SObjectType) {
                woIds.add(sa.ParentRecordId);
            }
        }

        Map<Id, WorkOrder> woById = woIds.isEmpty()
            ? new Map<Id, WorkOrder>()
            : new Map<Id, WorkOrder>([
                SELECT Id, Opportunity__c, WorkOrderNumber, Country, WorkTypeId, WorkType.Name, Service_Site_Name__c
                FROM WorkOrder
                WHERE Id IN :woIds
            ]);

        Map<ServiceReport, Id> workOrderIdByReport = new Map<ServiceReport, Id>();
        Set<Id> workOrdersToUpdate = new Set<Id>();
        Set<Id> signedWorkOrderIds = new Set<Id>();

        for (ServiceReport report : reportsToProcess) {
            Id workOrderId = resolveWorkOrderId(report.ParentId, saById);
            if (workOrderId != null) {
                workOrderIdByReport.put(report, workOrderId);
                workOrdersToUpdate.add(workOrderId);
                if (report.IsSigned) {
                    signedWorkOrderIds.add(workOrderId);
                }
            }
        }

        // US-only renaming + collision-aware V#
        createRenamedServiceReportVersions(reportsToProcess, contentVersions, woById, workOrderIdByReport);

        // Linking: Service Report files (FSR + PMR) only copy across objects for US work orders.
        Set<Id> docIds = new Set<Id>();
        Set<Id> targetIds = new Set<Id>();
        Set<String> desiredPairs = new Set<String>();
        Map<String, ContentDocumentLink> sourceLinkByPair = new Map<String, ContentDocumentLink>();

        for (ServiceReport report : reportsToProcess) {
            ContentVersion cv = contentVersions.get(report.ContentVersionDocumentId);
            if (cv == null || cv.ContentDocumentId == null) continue;

            Id workOrderId = workOrderIdByReport.get(report);
            if (workOrderId == null) continue;

            WorkOrder wo = woById.get(workOrderId);
            if (wo == null || wo.Country != US_COUNTRY_VALUE) {
                continue;
            }

            addDesiredPair(cv.ContentDocumentId, workOrderId, null, desiredPairs, sourceLinkByPair, docIds, targetIds);

            if (wo != null && wo.Opportunity__c != null) {
                addDesiredPair(cv.ContentDocumentId, wo.Opportunity__c, null, desiredPairs, sourceLinkByPair, docIds, targetIds);
            }
        }

        insertMissingLinks(desiredPairs, sourceLinkByPair, docIds, targetIds);

        // Keep only the latest Service Report file visible on Opportunity per Work Order.
        cleanupOpportunityLinksToLatestReport(workOrdersToUpdate, woById);

        // Status update (US-only, signed reports only)
        Set<Id> usWorkOrdersToUpdate = new Set<Id>();
        for (Id woId : signedWorkOrderIds) {
            WorkOrder wo = woById.get(woId);
            if (wo != null && wo.Country == US_COUNTRY_VALUE) {
                usWorkOrdersToUpdate.add(woId);
            }
        }
        updateWorkOrdersReadyForClose(usWorkOrdersToUpdate);

       
    }

    public static void handleServiceReportAfterUpsert(
        List<SObject> newReports,
        Map<Id, SObject> oldMap
    ) {
        List<ServiceReport> typedNewReports = new List<ServiceReport>();
        if (newReports != null) {
            for (SObject recordItem : newReports) {
                if (recordItem instanceof ServiceReport) {
                    typedNewReports.add((ServiceReport)recordItem);
                }
            }
        }

        Map<Id, ServiceReport> typedOldMap = null;
        if (oldMap != null) {
            typedOldMap = new Map<Id, ServiceReport>();
            for (Id recordId : oldMap.keySet()) {
                SObject oldRecord = oldMap.get(recordId);
                if (oldRecord instanceof ServiceReport) {
                    typedOldMap.put(recordId, (ServiceReport)oldRecord);
                }
            }
        }

        handleServiceReportAfterUpsert(typedNewReports, typedOldMap);
    }

    private static void createRenamedServiceReportVersions(
        List<ServiceReport> reportsToProcess,
        Map<Id, ContentVersion> contentVersions,
        Map<Id, WorkOrder> woById,
        Map<ServiceReport, Id> workOrderIdByReport
    ) {
        String todayText = String.valueOf(Date.today());

        // Build prefix base per WO+isSigned combo — signed and unsigned reports have independent V# sequences.
        // Key format: woId + '|' + isSigned (e.g. 'a008X000...|true')
        Map<String, String> prefixBaseByKey = new Map<String, String>();
        Set<Id> targetEntityIds = new Set<Id>();

        for (ServiceReport report : reportsToProcess) {
            Id woId = workOrderIdByReport.get(report);
            if (woId == null) continue;

            WorkOrder wo = woById.get(woId);
            if (wo == null || String.isBlank(wo.WorkOrderNumber)) continue;
            if (wo.Country != US_COUNTRY_VALUE) continue;

            String key = woId + '|' + report.IsSigned;
            if (!prefixBaseByKey.containsKey(key)) {
                String prefix = getReportPrefix(wo, report.IsSigned);
                String sitePart = '';
                if (!String.isBlank(wo.Service_Site_Name__c)) {
                    Integer maxSiteLen = 222 - wo.WorkOrderNumber.length();
                    String siteName = (maxSiteLen > 0 && wo.Service_Site_Name__c.length() > maxSiteLen)
                        ? wo.Service_Site_Name__c.left(maxSiteLen)
                        : wo.Service_Site_Name__c;
                    if (maxSiteLen > 0 && !String.isBlank(siteName)) sitePart = ' - ' + siteName;
                }
                prefixBaseByKey.put(key, prefix + ' - ' + wo.WorkOrderNumber + sitePart + ' - ' + todayText + ' - V');
                targetEntityIds.add(woId);
                if (wo.Opportunity__c != null) targetEntityIds.add(wo.Opportunity__c);
            }
        }

        if (prefixBaseByKey.isEmpty()) return;

        // Pull doc ids linked to WO/Opportunity
        Set<Id> linkedDocIds = new Set<Id>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :targetEntityIds
        ]) {
            if (cdl.ContentDocumentId != null) linkedDocIds.add(cdl.ContentDocumentId);
        }

        // Existing titles + max V# per key
        Map<String, Set<String>> existingTitlesByKey = new Map<String, Set<String>>();
        Map<String, Integer> maxVByKey = new Map<String, Integer>();
        for (String key : prefixBaseByKey.keySet()) {
            existingTitlesByKey.put(key, new Set<String>());
            maxVByKey.put(key, 0);
        }

        if (!linkedDocIds.isEmpty()) {
            for (ContentVersion cv : [
                SELECT Title, ContentDocumentId
                FROM ContentVersion
                WHERE ContentDocumentId IN :linkedDocIds
                  AND Title != null
            ]) {
                String title = cv.Title;

                for (String key : prefixBaseByKey.keySet()) {
                    String prefixBase = prefixBaseByKey.get(key);
                    if (String.isBlank(prefixBase)) continue;

                    if (title.startsWith(prefixBase)) {
                        existingTitlesByKey.get(key).add(title);

                        Integer parsedV = parseTrailingVNumber(title, prefixBase);
                        if (parsedV != null && parsedV > maxVByKey.get(key)) {
                            maxVByKey.put(key, parsedV);
                        }
                    }
                }
            }
        }

        List<ContentVersion> toInsert = new List<ContentVersion>();

        for (ServiceReport report : reportsToProcess) {
            if (report == null || report.ContentVersionDocumentId == null) continue;

            ContentVersion sourceCv = contentVersions.get(report.ContentVersionDocumentId);
            if (sourceCv == null || sourceCv.ContentDocumentId == null || sourceCv.VersionData == null) continue;

            Id woId = workOrderIdByReport.get(report);
            WorkOrder wo = woById.get(woId);
            if (wo == null || String.isBlank(wo.WorkOrderNumber)) continue;
            if (wo.Country != US_COUNTRY_VALUE) continue;

            String key = woId + '|' + report.IsSigned;
            String prefixBase = prefixBaseByKey.get(key);
            if (String.isBlank(prefixBase)) continue;

            Integer baseVersion = 1;
            try {
                baseVersion = Integer.valueOf(sourceCv.VersionNumber);
                if (baseVersion < 1) baseVersion = 1;
            } catch (Exception e) {
                baseVersion = 1;
            }

            Integer v = baseVersion;
            String candidateTitle = prefixBase + v;

            Set<String> existingTitles = existingTitlesByKey.get(key);
            Integer maxV = maxVByKey.get(key);

            // If exact name exists, bump to next available V#
            if (existingTitles != null && existingTitles.contains(candidateTitle)) {
                v = (maxV == null ? 0 : maxV) + 1;
                candidateTitle = prefixBase + v;
            }

            String ext = String.isBlank(sourceCv.FileExtension) ? 'pdf' : sourceCv.FileExtension;

            ContentVersion newVersion = new ContentVersion();
            newVersion.ContentDocumentId = sourceCv.ContentDocumentId;
            newVersion.Title = candidateTitle;
            newVersion.PathOnClient = candidateTitle + '.' + ext;
            newVersion.VersionData = sourceCv.VersionData;
            newVersion.IsMajorVersion = true;
            toInsert.add(newVersion);

            // Update trackers for same-transaction collisions
            if (existingTitles == null) {
                existingTitles = new Set<String>();
                existingTitlesByKey.put(key, existingTitles);
            }
            existingTitles.add(candidateTitle);
            maxVByKey.put(key, Math.max((maxV == null ? 0 : maxV), v));
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }

    private static String getReportPrefix(WorkOrder wo, Boolean isSigned) {
        String base = (wo != null && wo.WorkTypeId != null && wo.WorkType != null && wo.WorkType.Name == WORKTYPE_NAME_PPM)
            ? 'PMR'
            : 'FSR';
        return (isSigned == true) ? base : 'Pre' + base;
    }

    private static Boolean hasAnyMissingRequiredWorkOrderField(
        WorkOrder wo,
        List<Schema.FieldSetMember> requiredFieldMembers
    ) {
        if (wo == null || requiredFieldMembers == null || requiredFieldMembers.isEmpty()) return false;

        for (Schema.FieldSetMember fieldMember : requiredFieldMembers) {
            if (fieldMember == null || String.isBlank(fieldMember.getFieldPath())) continue;

            String fieldPath = fieldMember.getFieldPath();
            Object fieldValue = getFieldValueByPath(wo, fieldPath);
            if (fieldValue == null) return true;
            if (fieldValue instanceof String && String.isBlank((String)fieldValue)) return true;
        }

        return false;
    }


    private static Object getFieldValueByPath(SObject rootRecord, String fieldPath) {
        if (rootRecord == null || String.isBlank(fieldPath)) return null;

        List<String> pathParts = fieldPath.split('\\.');
        SObject currentRecord = rootRecord;

        for (Integer i = 0; i < pathParts.size(); i++) {
            String pathPart = pathParts[i];
            if (String.isBlank(pathPart) || currentRecord == null) return null;

            Boolean isLastPart = (i == pathParts.size() - 1);
            if (isLastPart) {
                return currentRecord.get(pathPart);
            }

            currentRecord = currentRecord.getSObject(pathPart);
        }

        return null;
    }

    private static Integer parseTrailingVNumber(String title, String prefixBase) {
        if (String.isBlank(title) || String.isBlank(prefixBase)) return null;
        if (!title.startsWith(prefixBase)) return null;

        String suffix = title.substring(prefixBase.length());
        if (String.isBlank(suffix)) return null;

        for (Integer i = 0; i < suffix.length(); i++) {
            String ch = suffix.substring(i, i + 1);
            if (ch < '0' || ch > '9') return null;
        }

        try {
            Integer v = Integer.valueOf(suffix);
            return (v != null && v > 0) ? v : null;
        } catch (Exception e) {
            return null;
        }
    }

    private static Id resolveWorkOrderId(Id parentId, Map<Id, ServiceAppointment> saById) {
        if (parentId == null) return null;

        Schema.SObjectType parentType = parentId.getSObjectType();
        if (parentType == WorkOrder.SObjectType) return parentId;

        if (parentType == ServiceAppointment.SObjectType) {
            ServiceAppointment sa = saById.get(parentId);
            if (sa != null
                && sa.ParentRecordId != null
                && sa.ParentRecordId.getSObjectType() == WorkOrder.SObjectType) {
                return sa.ParentRecordId;
            }
        }
        return null;
    }

    private static void addDesiredPair(
        Id docId,
        Id targetId,
        ContentDocumentLink sourceLink,
        Set<String> desiredPairs,
        Map<String, ContentDocumentLink> sourceLinkByPair,
        Set<Id> docIds,
        Set<Id> targetIds
    ) {
        if (docId == null || targetId == null) return;

        docIds.add(docId);
        targetIds.add(targetId);

        String key = docId + '|' + targetId;
        desiredPairs.add(key);

        if (!sourceLinkByPair.containsKey(key)) {
            sourceLinkByPair.put(key, sourceLink);
        }
    }

    private static void insertMissingLinks(
        Set<String> desiredPairs,
        Map<String, ContentDocumentLink> sourceLinkByPair,
        Set<Id> docIds,
        Set<Id> targetIds
    ) {
        if (desiredPairs.isEmpty()) return;

        Set<String> existingPairs = new Set<String>();
        for (ContentDocumentLink existing : [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :docIds
              AND LinkedEntityId    IN :targetIds
        ]) {
            existingPairs.add(existing.ContentDocumentId + '|' + existing.LinkedEntityId);
        }

        List<ContentDocumentLink> toInsert = new List<ContentDocumentLink>();
        for (String key : desiredPairs) {
            if (existingPairs.contains(key)) continue;

            List<String> parts = key.split('\\|');
            if (parts == null || parts.size() < 2) continue;

            ContentDocumentLink source = sourceLinkByPair.get(key);

            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId = (Id)parts[0];
            link.LinkedEntityId = (Id)parts[1];
            link.ShareType = (source != null && source.ShareType != null) ? source.ShareType : 'V';
            link.Visibility = (source != null && source.Visibility != null) ? source.Visibility : 'AllUsers';
            toInsert.add(link);
        }

        if (!toInsert.isEmpty()) {
            Database.insert(toInsert, false);
        }
    }

    private static void updateWorkOrdersReadyForClose(Set<Id> workOrderIds) {
        if (workOrderIds == null || workOrderIds.isEmpty()) return;

        List<WorkOrder> updates = new List<WorkOrder>();
        for (WorkOrder wo : [
            SELECT Id, Status
            FROM WorkOrder
            WHERE Id IN :workOrderIds
        ]) {
            if (wo.Status != 'Ready for Close') {
                wo.Status = 'Ready for Close';
                updates.add(wo);
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }

    private static void cleanupOpportunityLinksToLatestReport(
        Set<Id> workOrderIds,
        Map<Id, WorkOrder> woById
    ) {
        if (workOrderIds == null || workOrderIds.isEmpty() || woById == null || woById.isEmpty()) return;

        Map<Id, List<WorkOrder>> workOrdersByOpportunityId = new Map<Id, List<WorkOrder>>();
        for (Id workOrderId : workOrderIds) {
            WorkOrder wo = woById.get(workOrderId);
            if (wo == null
                || wo.Country != US_COUNTRY_VALUE
                || wo.Opportunity__c == null
                || String.isBlank(wo.WorkOrderNumber)) {
                continue;
            }

            if (!workOrdersByOpportunityId.containsKey(wo.Opportunity__c)) {
                workOrdersByOpportunityId.put(wo.Opportunity__c, new List<WorkOrder>());
            }
            workOrdersByOpportunityId.get(wo.Opportunity__c).add(wo);
        }

        if (workOrdersByOpportunityId.isEmpty()) return;

        Map<Id, ContentDocumentLink> latestLinkByWorkOrderId = new Map<Id, ContentDocumentLink>();
        Map<Id, List<ContentDocumentLink>> matchingLinksByWorkOrderId = new Map<Id, List<ContentDocumentLink>>();

        for (ContentDocumentLink linkItem : [
            SELECT Id,
                   LinkedEntityId,
                   ContentDocumentId,
                   ContentDocument.LatestPublishedVersion.Title,
                   ContentDocument.LatestPublishedVersion.CreatedDate
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :workOrdersByOpportunityId.keySet()
        ]) {
            if (linkItem.ContentDocument == null
                || linkItem.ContentDocument.LatestPublishedVersion == null
                || String.isBlank(linkItem.ContentDocument.LatestPublishedVersion.Title)) {
                continue;
            }

            List<WorkOrder> relatedWorkOrders = workOrdersByOpportunityId.get(linkItem.LinkedEntityId);
            if (relatedWorkOrders == null || relatedWorkOrders.isEmpty()) continue;

            for (WorkOrder wo : relatedWorkOrders) {
                String wositePart = '';
                if (!String.isBlank(wo.Service_Site_Name__c)) {
                    Integer maxSiteLen = 222 - wo.WorkOrderNumber.length();
                    String siteName = (maxSiteLen > 0 && wo.Service_Site_Name__c.length() > maxSiteLen)
                        ? wo.Service_Site_Name__c.left(maxSiteLen)
                        : wo.Service_Site_Name__c;
                    if (maxSiteLen > 0 && !String.isBlank(siteName)) wositePart = ' - ' + siteName;
                }
                String titlePrefix = getReportPrefix(wo, true) + ' - ' + wo.WorkOrderNumber + wositePart + ' - ';
                if (!linkItem.ContentDocument.LatestPublishedVersion.Title.startsWith(titlePrefix)) {
                    continue;
                }

                if (!matchingLinksByWorkOrderId.containsKey(wo.Id)) {
                    matchingLinksByWorkOrderId.put(wo.Id, new List<ContentDocumentLink>());
                }
                matchingLinksByWorkOrderId.get(wo.Id).add(linkItem);

                ContentDocumentLink currentLatest = latestLinkByWorkOrderId.get(wo.Id);
                if (currentLatest == null
                    || currentLatest.ContentDocument.LatestPublishedVersion.CreatedDate < linkItem.ContentDocument.LatestPublishedVersion.CreatedDate
                    || (currentLatest.ContentDocument.LatestPublishedVersion.CreatedDate == linkItem.ContentDocument.LatestPublishedVersion.CreatedDate
                        && String.valueOf(currentLatest.ContentDocumentId) < String.valueOf(linkItem.ContentDocumentId))) {
                    latestLinkByWorkOrderId.put(wo.Id, linkItem);
                }
            }
        }

        List<ContentDocumentLink> linksToDelete = new List<ContentDocumentLink>();
        Set<Id> deletedLinkIds = new Set<Id>();

        for (Id workOrderId : matchingLinksByWorkOrderId.keySet()) {
            ContentDocumentLink latestLink = latestLinkByWorkOrderId.get(workOrderId);
            for (ContentDocumentLink linkItem : matchingLinksByWorkOrderId.get(workOrderId)) {
                if (latestLink != null && linkItem.Id == latestLink.Id) continue;
                if (deletedLinkIds.contains(linkItem.Id)) continue;

                linksToDelete.add(linkItem);
                deletedLinkIds.add(linkItem.Id);
            }
        }

        if (!linksToDelete.isEmpty()) {
            Database.delete(linksToDelete, false);
        }
    }
}