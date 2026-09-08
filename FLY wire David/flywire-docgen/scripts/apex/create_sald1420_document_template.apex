String targetName = 'SALDEV1420 Approval Quote Document';
List<DocumentTemplate> existing = [SELECT Id, Name, Status FROM DocumentTemplate WHERE Name = :targetName LIMIT 1];
if (!existing.isEmpty()) {
    System.debug(LoggingLevel.ERROR, 'SALDEV1420_TEMPLATE_EXISTS|' + existing[0].Id + '|status=' + existing[0].Status);
} else {
    Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.DocumentTemplate.fields.getMap();
    List<String> fields = new List<String>{'Id'};
    for (String fieldName : fieldMap.keySet()) {
        if (fieldMap.get(fieldName).getDescribe().isCreateable()) fields.add(fieldName);
    }
    DocumentTemplate sourceTemplate = (DocumentTemplate) Database.query(
        'SELECT ' + String.join(fields, ',') + ' FROM DocumentTemplate WHERE Id = \'2dtPb0000000BwLIAU\''
    );
    DocumentTemplate targetTemplate = new DocumentTemplate();
    for (String fieldName : fields) {
        if (new Set<String>{'Id','Name','Status','ExtractOmniDataTransformName','MapperOmniDataTransformName','UniqueName','GlobalKey'}.contains(fieldName)) continue;
        Object fieldValue = sourceTemplate.get(fieldName);
        if (fieldValue != null) targetTemplate.put(fieldName, fieldValue);
    }
    targetTemplate.Name = targetName;
    targetTemplate.UniqueName = 'SALDEV1420_Approval_Quote_Document';
    targetTemplate.GlobalKey = 'SALDEV1420 Approval Quote Document/1/00DhG0000000jOX/20260823';
    targetTemplate.Status = 'Draft';
    targetTemplate.ExtractOmniDataTransformName = 'SALDEV1420_GetApprovalQuoteEmailData';
    targetTemplate.MapperOmniDataTransformName = 'SALDEV1420_BuildApprovalEmailGroups';
    insert targetTemplate;

    DocumentTemplateContentDoc contentLink = new DocumentTemplateContentDoc(
        Name = 'SALDEV1420 Approval Quote Document - v1',
        DocumentTemplateId = targetTemplate.Id,
        ContentDocumentId = '069hG000003OUjBQAW',
        FileStageType = 'Original'
    );
    insert contentLink;
    System.debug(LoggingLevel.ERROR,
        'SALDEV1420_TEMPLATE_CREATED|' + targetTemplate.Id + '|status=' + targetTemplate.Status +
        '|contentLink=' + contentLink.Id + '|contentDocument=' + contentLink.ContentDocumentId
    );
}
