OmniDataTransform mapper = [
    SELECT Id, Name, OutputType, OutputParsingClass
    FROM OmniDataTransform
    WHERE Id = '0jIhG0000000HX7UAM'
    FOR UPDATE
];
System.debug(LoggingLevel.ERROR, 'BEFORE|OutputType=' + mapper.OutputType +
    '|OutputParsingClass=' + mapper.OutputParsingClass);
mapper.OutputType = 'Custom';
mapper.OutputParsingClass = 'CPQQuoteProposalOutputSerializer';
update mapper;
System.debug(LoggingLevel.ERROR, 'AFTER|OutputType=' + mapper.OutputType +
    '|OutputParsingClass=' + mapper.OutputParsingClass);
