Set<Id> ids = new Set<Id>{
    '0kdhG0000002nKnQAI',
    '0kdhG0000002iubQAA'
};
for (OmniDataTransformItem item : [
    SELECT Id, OmniDataTransformationId,
           OmniDataTransformation.Name,
           OmniDataTransformation.Type,
           OmniDataTransformation.PreviewJsonData,
           OmniDataTransformation.ExpectedInputJson,
           OmniDataTransformation.ExpectedOutputJson
    FROM OmniDataTransformItem
    WHERE Id IN :ids
]) {
    OmniDataTransform mapper = item.OmniDataTransformation;
    System.debug(LoggingLevel.ERROR,
        'MAPPER_DIAG|' + mapper.Id + '|' + mapper.Name + '|' + mapper.Type +
        '|PREVIEW=' + mapper.PreviewJsonData +
        '|EXPECTED_INPUT=' + mapper.ExpectedInputJson +
        '|EXPECTED_OUTPUT=' + mapper.ExpectedOutputJson
    );
}
