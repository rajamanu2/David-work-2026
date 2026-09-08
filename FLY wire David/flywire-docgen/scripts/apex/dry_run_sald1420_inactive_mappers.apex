for (Id quoteId : new List<Id>{
    'a2NhG000002ktrcUAA',
    'a2NhG000003EetVUAS',
    'a2NhG000002YPkPUAW'
}) {
    omnistudio.DRProcessResult extractResult = omnistudio.DRGlobal.processFromApex(
        new Map<String, Object>{'Id' => quoteId},
        'SALDEV1420_GetApprovalQuoteEmailData'
    );
    Map<String, Object> extracted = (Map<String, Object>) extractResult.toJson();
    omnistudio.DRProcessResult transformResult = omnistudio.DRGlobal.processFromApex(
        extracted,
        'SALDEV1420_BuildApprovalEmailGroups'
    );
    Map<String, Object> transformed = (Map<String, Object>) transformResult.toJson();
    List<Object> groups = transformed.get('Group') instanceof List<Object>
        ? (List<Object>) transformed.get('Group') : new List<Object>();
    List<String> headers = new List<String>();
    Integer lines = 0;
    Integer amendmentLines = 0;
    for (Object groupValue : groups) {
        Map<String, Object> groupRow = (Map<String, Object>) groupValue;
        Decimal term = groupRow.get('SubscriptionTerm') == null
            ? null : Decimal.valueOf(String.valueOf(groupRow.get('SubscriptionTerm')));
        String header = 'Term ' + (headers.size() + 1) +
            (term == null ? '' : ': ' + term.setScale(0) + ' Months');
        headers.add(header);
        List<Object> groupLines = groupRow.get('QuoteLine') instanceof List<Object>
            ? (List<Object>) groupRow.get('QuoteLine') : new List<Object>();
        lines += groupLines.size();
        for (Object lineValue : groupLines) {
            Map<String, Object> line = (Map<String, Object>) lineValue;
            if (String.valueOf(line.get('QuoteLineType')) == 'Amendment') amendmentLines++;
        }
    }
    System.debug(LoggingLevel.ERROR,
        'SALDEV1420_DRYRUN|' + quoteId +
        '|extractErrors=' + extractResult.hasErrors() +
        '|transformErrors=' + transformResult.hasErrors() +
        '|groups=' + groups.size() +
        '|lines=' + lines +
        '|amendmentLines=' + amendmentLines +
        '|multipleShipTo=' + String.valueOf(transformed.get('MultipleShipToAccounts')) +
        '|headers=' + String.join(headers, ',')
    );
}
