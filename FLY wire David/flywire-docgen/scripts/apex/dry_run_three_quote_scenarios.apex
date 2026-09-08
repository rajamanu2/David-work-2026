for (Id quoteId : new List<Id>{
    'a2NhG000002ktrcUAA',
    'a2NhG000003EetVUAS',
    'a2NhG000002YPkPUAW'
}) {
    omnistudio.DRProcessResult extractResult = omnistudio.DRGlobal.processFromApex(
        new Map<String, Object>{'Id' => quoteId},
        'GetQuoteProposalDataSteppedUpPricing'
    );
    Map<String, Object> extracted = (Map<String, Object>) extractResult.toJson();
    omnistudio.DRProcessResult transformResult = omnistudio.DRGlobal.processFromApex(
        extracted,
        'CPQQuoteProposalDocumentSteppedUpPricing'
    );
    Object transformedValue = transformResult.toJson();
    String rootType = transformedValue instanceof Map<String, Object> ? 'Map' :
        (transformedValue instanceof List<Object> ? 'List' : 'Other');
    Map<String, Object> transformed = transformedValue instanceof Map<String, Object>
        ? (Map<String, Object>) transformedValue
        : new Map<String, Object>();
    Integer groupCount = transformed.get('Group') instanceof List<Object>
        ? ((List<Object>) transformed.get('Group')).size() : 0;
    Integer lineCount = transformed.get('Line') instanceof List<Object>
        ? ((List<Object>) transformed.get('Line')).size() : 0;
    System.debug(LoggingLevel.ERROR,
        'SCENARIO|' + quoteId +
        '|extractErrors=' + extractResult.hasErrors() +
        '|transformErrors=' + transformResult.hasErrors() +
        '|rootType=' + rootType +
        '|groups=' + groupCount +
        '|ungroupedLines=' + lineCount +
        '|groupsPresent=' + transformed.get('QuoteLineGroupsPresent') +
        '|ifGroupsTrue=' + transformed.get('IF_QuoteLineGroupsPresentTrue') +
        '|ifGroupsFalse=' + transformed.get('IF_QuoteLineGroupsPresentFalse') +
        '|multipleShipTo=' + transformed.get('MultipleShipToAccounts') +
        '|ifMulti=' + transformed.get('IF_MultipleShipToAccounts') +
        '|ifNoMulti=' + transformed.get('IF_NoMultipleShipToAccounts')
    );
}
