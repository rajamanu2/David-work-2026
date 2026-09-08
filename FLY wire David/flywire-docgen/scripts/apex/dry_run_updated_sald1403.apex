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
    Map<String, Object> transformed = (Map<String, Object>) transformResult.toJson();
    List<Object> groups = transformed.get('Group') instanceof List<Object>
        ? (List<Object>) transformed.get('Group') : new List<Object>();
    List<Object> ungrouped = transformed.get('Line') instanceof List<Object>
        ? (List<Object>) transformed.get('Line') : new List<Object>();
    List<String> groupInfo = new List<String>();
    Integer groupedLineCount = 0;
    Integer rateDetailCount = 0;
    Integer rateDetailAppendedCount = 0;
    for (Object value : groups) {
        Map<String, Object> groupRow = (Map<String, Object>) value;
        List<Object> lines = groupRow.get('QuoteLine') instanceof List<Object>
            ? (List<Object>) groupRow.get('QuoteLine') : new List<Object>();
        groupedLineCount += lines.size();
        for (Object lineValue : lines) {
            Map<String, Object> line = (Map<String, Object>) lineValue;
            String rate = String.valueOf(line.get('RateDetails'));
            String descriptionText = String.valueOf(line.get('LineDescriptionWithType'));
            if (line.get('RateDetails') != null) {
                rateDetailCount++;
                if (descriptionText != null && descriptionText.contains(rate)) rateDetailAppendedCount++;
            }
        }
        groupInfo.add(
            String.valueOf(groupRow.get('Number')) + ':' +
            String.valueOf(groupRow.get('Name')) + ':' +
            String.valueOf(groupRow.get('StartDate')) + ':' +
            String.valueOf(groupRow.get('EndDate')) + ':' +
            'term=' + String.valueOf(groupRow.get('SubscriptionTerm')) + ':' +
            'lines=' + lines.size()
        );
    }
    System.debug(LoggingLevel.ERROR,
        'UPDATED_DRYRUN|' + quoteId +
        '|extractErrors=' + extractResult.hasErrors() +
        '|transformErrors=' + transformResult.hasErrors() +
        '|groups=' + groups.size() +
        '|groupedLines=' + groupedLineCount +
        '|ungroupedLines=' + ungrouped.size() +
        '|rateDetails=' + rateDetailCount +
        '|rateDetailsAppended=' + rateDetailAppendedCount +
        '|groupInfo=' + String.join(groupInfo, ',')
    );
}
