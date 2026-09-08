// Activate only the new isolated SALDEV-1420 components in Partial.
// Existing CPQ/QuoteDocument and Quote DocumentTemplate remain unchanged.
DocumentTemplate templateRecord = [
    SELECT Id, Status, IsActive, Document_Type__c
    FROM DocumentTemplate WHERE Id = '2dthG0000000O5ZQAU'
];
templateRecord.Document_Type__c = 'Legal';
templateRecord.Status = 'Active';
templateRecord.IsActive = true;
update templateRecord;

OmniProcess processRecord = [
    SELECT Id, IsActive, Type, SubType FROM OmniProcess WHERE Id = '0jNhG0000000yLxUAI'
];
processRecord.SubType = 'ApprovalQuoteDocument';

OmniProcessElement setTemplateValues = [
    SELECT Id, PropertySetConfig
    FROM OmniProcessElement
    WHERE OmniProcessId = :processRecord.Id AND Name = 'SetTemplateValues'
    LIMIT 1
];
setTemplateValues.PropertySetConfig = setTemplateValues.PropertySetConfig.replace(
    '"DocType":"Quote"', '"DocType":"Legal"'
);
update setTemplateValues;

List<OmniDataTransform> mappers = [
    SELECT Id, Name, IsActive
    FROM OmniDataTransform WHERE Name LIKE 'SALDEV1420_%'
];
for (OmniDataTransform mapper : mappers) mapper.IsActive = true;
update mappers;

processRecord.IsActive = true;
update processRecord;

System.debug(LoggingLevel.ERROR,
    'SALDEV1420_ACTIVATED|template=' + templateRecord.Id + '|docType=' + templateRecord.Document_Type__c +
    '|process=' + processRecord.Id + '|runtime=' + processRecord.Type + '/' + processRecord.SubType +
    '|mappers=' + mappers.size()
);
