// SALDEV-1420: create inactive OmniStudio-only Data Mapper drafts.
// Existing components are not modified.
Map<Id, String> sourceNames = new Map<Id, String>{
    '0jIhG0000000GsnUAE' => 'SALDEV1420_GetApprovalQuoteEmailData',
    '0jIhG0000000HX7UAM' => 'SALDEV1420_BuildApprovalEmailGroups',
    '0jIhG00000005pPUAQ' => 'SALDEV1420_GetDocumentTemplate'
};

Map<String, Schema.SObjectField> transformFieldMap = Schema.SObjectType.OmniDataTransform.fields.getMap();
List<String> transformFields = new List<String>{'Id'};
for (String fieldName : transformFieldMap.keySet()) {
    if (transformFieldMap.get(fieldName).getDescribe().isCreateable()) transformFields.add(fieldName);
}

Map<String, Schema.SObjectField> itemFieldMap = Schema.SObjectType.OmniDataTransformItem.fields.getMap();
List<String> itemFields = new List<String>{'Id'};
for (String fieldName : itemFieldMap.keySet()) {
    if (itemFieldMap.get(fieldName).getDescribe().isCreateable()) itemFields.add(fieldName);
}

for (Id sourceId : sourceNames.keySet()) {
    String targetName = sourceNames.get(sourceId);
    List<OmniDataTransform> existing = [SELECT Id, Name FROM OmniDataTransform WHERE Name = :targetName LIMIT 1];
    if (!existing.isEmpty()) {
        System.debug(LoggingLevel.ERROR, 'SALDEV1420_EXISTS|' + targetName + '|' + existing[0].Id);
        continue;
    }

    OmniDataTransform sourceTransform = (OmniDataTransform) Database.query(
        'SELECT ' + String.join(transformFields, ',') + ' FROM OmniDataTransform WHERE Id = :sourceId'
    );
    OmniDataTransform targetTransform = new OmniDataTransform();
    for (String fieldName : transformFields) {
        if (fieldName == 'Id' || fieldName == 'Name' || fieldName == 'IsActive' || fieldName == 'VersionNumber') continue;
        Object fieldValue = sourceTransform.get(fieldName);
        if (fieldValue != null) targetTransform.put(fieldName, fieldValue);
    }
    targetTransform.Name = targetName;
    targetTransform.IsActive = false;
    targetTransform.VersionNumber = 1;
    insert targetTransform;

    List<OmniDataTransformItem> sourceItems = (List<OmniDataTransformItem>) Database.query(
        'SELECT ' + String.join(itemFields, ',') +
        ' FROM OmniDataTransformItem WHERE OmniDataTransformationId = :sourceId'
    );
    List<OmniDataTransformItem> targetItems = new List<OmniDataTransformItem>();
    for (OmniDataTransformItem sourceItem : sourceItems) {
        OmniDataTransformItem targetItem = new OmniDataTransformItem();
        for (String fieldName : itemFields) {
            if (fieldName == 'Id' || fieldName == 'OmniDataTransformationId') continue;
            Object fieldValue = sourceItem.get(fieldName);
            if (fieldValue != null) targetItem.put(fieldName, fieldValue);
        }
        targetItem.Name = targetName;
        targetItem.OmniDataTransformationId = targetTransform.Id;
        targetItems.add(targetItem);
    }
    insert targetItems;

    // The approval-email group header needs the group-level subscription term.
    if (sourceId == '0jIhG0000000GsnUAE') {
        OmniDataTransformItem startDateItem = [
            SELECT InputObjectName, InputFieldName, OutputObjectName, OutputFieldName,
                   OutputCreationSequence, InputObjectQuerySequence, IsDisabled
            FROM OmniDataTransformItem
            WHERE OmniDataTransformationId = :targetTransform.Id
              AND OutputFieldName = 'QuoteLineGroup:StartDate'
            LIMIT 1
        ];
        OmniDataTransformItem termItem = startDateItem.clone(false, true, false, false);
        termItem.OmniDataTransformationId = targetTransform.Id;
        termItem.Name = targetName;
        termItem.InputFieldName = 'SBQuote:QuoteLineGroup:SBQQ__SubscriptionTerm__c';
        termItem.OutputFieldName = 'QuoteLineGroup:SubscriptionTerm';
        insert termItem;
    }

    // Select this SALDEV-1420 Draft directly rather than all active Quote templates.
    if (sourceId == '0jIhG00000005pPUAQ') {
        OmniDataTransformItem activeFilter = [
            SELECT Id, InputFieldName, FilterValue
            FROM OmniDataTransformItem
            WHERE OmniDataTransformationId = :targetTransform.Id
              AND InputObjectName = 'DocumentTemplate'
              AND InputFieldName = 'IsActive'
            LIMIT 1
        ];
        activeFilter.InputFieldName = 'Name';
        activeFilter.FilterValue = '\'SALDEV1420 Approval Quote Document\'';
        update activeFilter;
    }

    System.debug(LoggingLevel.ERROR,
        'SALDEV1420_CREATED|' + targetName + '|' + targetTransform.Id +
        '|type=' + targetTransform.Type + '|active=' + targetTransform.IsActive +
        '|items=' + [SELECT COUNT() FROM OmniDataTransformItem WHERE OmniDataTransformationId = :targetTransform.Id]
    );
}
