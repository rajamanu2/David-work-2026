OmniProcess processRecord = [
    SELECT Id, Name, Type, SubType, Language, VersionNumber, IsActive
    FROM OmniProcess WHERE Id = '0jNhG0000000yLxUAI'
];
System.debug(LoggingLevel.ERROR, 'SALDEV1420_OS|' + JSON.serialize(processRecord));

for (OmniProcessElement element : [
    SELECT Name, Type, ParentElementId, PropertySetConfig
    FROM OmniProcessElement WHERE OmniProcessId = :processRecord.Id
    ORDER BY Level, SequenceNumber
]) {
    System.debug(LoggingLevel.ERROR,
        'SALDEV1420_ELEMENT|' + element.Name + '|' + element.Type + '|parent=' + element.ParentElementId +
        '|config=' + element.PropertySetConfig
    );
}

DocumentTemplate templateRecord = [
    SELECT Id, Name, Status, IsActive, Type, DocumentGenerationMechanism,
           ExtractOmniDataTransformName, MapperOmniDataTransformName
    FROM DocumentTemplate WHERE Id = '2dthG0000000O5ZQAU'
];
System.debug(LoggingLevel.ERROR, 'SALDEV1420_TEMPLATE|' + JSON.serialize(templateRecord));

omnistudio.DRProcessResult selectorResult = omnistudio.DRGlobal.processFromApex(
    new Map<String, Object>{
        'templateType' => 'MicrosoftWord',
        'vertical' => 'All',
        'docType' => 'Legal'
    },
    'SALDEV1420_GetDocumentTemplate'
);
System.debug(LoggingLevel.ERROR,
    'SALDEV1420_SELECTOR|errors=' + selectorResult.hasErrors() + '|output=' + JSON.serialize(selectorResult.toJson())
);

for (Id quoteId : new List<Id>{
    'a2NhG000002ktrcUAA', 'a2NhG000003EetVUAS', 'a2NhG000002YPkPUAW',
    'a2NhG000002LhK9UAK', 'a2NhG000003efkNUAQ', 'a2NhG000003gCpSUAU'
}) {
    omnistudio.DRProcessResult extractResult = omnistudio.DRGlobal.processFromApex(
        new Map<String, Object>{'Id' => quoteId}, 'SALDEV1420_GetApprovalQuoteEmailData'
    );
    omnistudio.DRProcessResult transformResult = omnistudio.DRGlobal.processFromApex(
        (Map<String, Object>) extractResult.toJson(), 'SALDEV1420_BuildApprovalEmailGroups'
    );
    Map<String, Object> output = (Map<String, Object>) transformResult.toJson();
    List<Object> groups = output.get('Group') instanceof List<Object>
        ? (List<Object>) output.get('Group') : new List<Object>();
    List<Object> lines = output.get('Line') instanceof List<Object>
        ? (List<Object>) output.get('Line') : new List<Object>();
    Integer amendmentCount = 0;
    Integer groupedLineCount = 0;
    Integer rateDetails = 0;
    Integer rateDetailsAppended = 0;
    List<String> headers = new List<String>();
    Decimal previousTerm;
    Boolean descending = true;
    for (Object groupValue : groups) {
        Map<String, Object> groupRow = (Map<String, Object>) groupValue;
        Decimal term = groupRow.get('SubscriptionTerm') == null ? null
            : Decimal.valueOf(String.valueOf(groupRow.get('SubscriptionTerm')));
        if (previousTerm != null && term != null && term > previousTerm) descending = false;
        if (term != null) previousTerm = term;
        headers.add('Term ' + (headers.size() + 1) +
            (term == null ? '' : ': ' + term.setScale(0) + ' Months'));
        List<Object> groupLines = groupRow.get('QuoteLine') instanceof List<Object>
            ? (List<Object>) groupRow.get('QuoteLine') : new List<Object>();
        groupedLineCount += groupLines.size();
        for (Object lineValue : groupLines) {
            Map<String, Object> line = (Map<String, Object>) lineValue;
            if (String.valueOf(line.get('QuoteLineType')) == 'Amendment') amendmentCount++;
            if (line.get('RateDetails') != null) {
                rateDetails++;
                if (String.valueOf(line.get('LineDescriptionWithType')).contains(String.valueOf(line.get('RateDetails')))) {
                    rateDetailsAppended++;
                }
            }
        }
    }
    System.debug(LoggingLevel.ERROR,
        'SALDEV1420_SCENARIO|' + quoteId +
        '|extractErrors=' + extractResult.hasErrors() + '|transformErrors=' + transformResult.hasErrors() +
        '|groups=' + groups.size() + '|groupedLines=' + groupedLineCount + '|ungroupedLines=' + lines.size() +
        '|amendments=' + amendmentCount + '|multipleShipTo=' + output.get('MultipleShipToAccounts') +
        '|rateDetails=' + rateDetails + '|rateDetailsAppended=' + rateDetailsAppended +
        '|descendingTerms=' + descending + '|headers=' + String.join(headers, ',')
    );
}
