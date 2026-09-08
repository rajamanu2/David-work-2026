Id sourceProcessId = '0jNhG0000000umzUAA';
String targetName = 'SALDEV1420 Approval Quote Document';
List<OmniProcess> existing = [SELECT Id, Name, IsActive FROM OmniProcess WHERE Name = :targetName LIMIT 1];
if (!existing.isEmpty()) {
    System.debug(LoggingLevel.ERROR, 'SALDEV1420_OS_EXISTS|' + existing[0].Id + '|active=' + existing[0].IsActive);
} else {
    Map<String, Schema.SObjectField> processFieldMap = Schema.SObjectType.OmniProcess.fields.getMap();
    List<String> processFields = new List<String>{'Id'};
    for (String fieldName : processFieldMap.keySet()) {
        if (processFieldMap.get(fieldName).getDescribe().isCreateable()) processFields.add(fieldName);
    }
    OmniProcess sourceProcess = (OmniProcess) Database.query(
        'SELECT ' + String.join(processFields, ',') + ' FROM OmniProcess WHERE Id = :sourceProcessId'
    );
    OmniProcess targetProcess = new OmniProcess();
    Set<String> processOverrides = new Set<String>{
        'Id','Name','IsActive','VersionNumber','OmniProcessKey','UniqueName','OverrideKey','WebComponentKey'
    };
    for (String fieldName : processFields) {
        if (processOverrides.contains(fieldName)) continue;
        Object fieldValue = sourceProcess.get(fieldName);
        if (fieldValue != null) targetProcess.put(fieldName, fieldValue);
    }
    targetProcess.Name = targetName;
    targetProcess.IsActive = false;
    targetProcess.VersionNumber = 1;
    targetProcess.OmniProcessKey = 'SALDEV1420_CPQ_ApprovalQuoteDocument_English';
    targetProcess.UniqueName = 'SALDEV1420_CPQ_ApprovalQuoteDocument_English';
    insert targetProcess;

    Map<String, Schema.SObjectField> elementFieldMap = Schema.SObjectType.OmniProcessElement.fields.getMap();
    List<String> elementFields = new List<String>{'Id'};
    for (String fieldName : elementFieldMap.keySet()) {
        if (elementFieldMap.get(fieldName).getDescribe().isCreateable()) elementFields.add(fieldName);
    }
    List<OmniProcessElement> sourceElements = (List<OmniProcessElement>) Database.query(
        'SELECT ' + String.join(elementFields, ',') +
        ' FROM OmniProcessElement WHERE OmniProcessId = :sourceProcessId ORDER BY Level, SequenceNumber'
    );
    Map<Id, Id> oldToNew = new Map<Id, Id>();
    Map<Id, Id> oldParentByNewChild = new Map<Id, Id>();
    for (OmniProcessElement sourceElement : sourceElements) {
        OmniProcessElement targetElement = new OmniProcessElement();
        for (String fieldName : elementFields) {
            if (new Set<String>{'Id','OmniProcessId','ParentElementId'}.contains(fieldName)) continue;
            Object fieldValue = sourceElement.get(fieldName);
            if (fieldValue != null) targetElement.put(fieldName, fieldValue);
        }
        targetElement.OmniProcessId = targetProcess.Id;
        String config = targetElement.PropertySetConfig;
        if (config != null) {
            config = config.replace('GetQuoteProposalDataSteppedUpPricing', 'SALDEV1420_GetApprovalQuoteEmailData');
            config = config.replace('GetDocumentTemplate', 'SALDEV1420_GetDocumentTemplate');
            config = config.replace('Quote Proposal - ', 'SALDEV1420 Approval Quote - ');
            targetElement.PropertySetConfig = config;
        }
        insert targetElement;
        oldToNew.put(sourceElement.Id, targetElement.Id);
        if (sourceElement.ParentElementId != null) oldParentByNewChild.put(targetElement.Id, sourceElement.ParentElementId);
    }
    List<OmniProcessElement> parentUpdates = new List<OmniProcessElement>();
    for (Id newChildId : oldParentByNewChild.keySet()) {
        parentUpdates.add(new OmniProcessElement(
            Id = newChildId,
            ParentElementId = oldToNew.get(oldParentByNewChild.get(newChildId))
        ));
    }
    if (!parentUpdates.isEmpty()) update parentUpdates;

    System.debug(LoggingLevel.ERROR,
        'SALDEV1420_OS_CREATED|' + targetProcess.Id + '|active=' + targetProcess.IsActive +
        '|elements=' + [SELECT COUNT() FROM OmniProcessElement WHERE OmniProcessId = :targetProcess.Id]
    );
}
