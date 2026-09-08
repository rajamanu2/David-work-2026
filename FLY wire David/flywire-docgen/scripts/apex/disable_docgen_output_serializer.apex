OmniDataTransform mapper = [
    SELECT Id, OutputType, OutputParsingClass
    FROM OmniDataTransform
    WHERE Id = '0jIhG0000000HX7UAM'
    FOR UPDATE
];
mapper.OutputType = 'JSON';
mapper.OutputParsingClass = null;
update mapper;
System.debug(LoggingLevel.ERROR, 'ROLLBACK|OutputType=JSON|OutputParsingClass=null');
