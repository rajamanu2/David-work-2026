OmniDataTransform mapper = [
    SELECT Id, Name, Type, InputType, OutputType, InputParsingClass,
           OutputParsingClass, IsNullInputsIncludedInOutput,
           IsProcessSuperBulk, SourceObject, TargetOutputDocumentIdentifier,
           ExpectedInputJson, ExpectedOutputJson, PreviewJsonData
    FROM OmniDataTransform
    WHERE Id = '0jIhG0000000HX7UAM'
];
System.debug(LoggingLevel.ERROR, 'MAPPER_HEADER=' + JSON.serialize(mapper));
