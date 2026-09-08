for (OmniDataTransform mapper : [
    SELECT Id, Name, Type, OutputParsingClass, InputParsingClass
    FROM OmniDataTransform
    WHERE OutputParsingClass != null OR InputParsingClass != null
    ORDER BY Name
    LIMIT 100
]) {
    System.debug(LoggingLevel.ERROR, 'PARSER|' + mapper.Id + '|' + mapper.Name +
        '|input=' + mapper.InputParsingClass + '|output=' + mapper.OutputParsingClass);
}
