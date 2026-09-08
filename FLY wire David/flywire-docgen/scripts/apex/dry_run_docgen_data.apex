Map<String, Object> input = new Map<String, Object>{
    'Id' => 'a2NhG000002ktrcUAA'
};

omnistudio.DRProcessResult extractResult = omnistudio.DRGlobal.processFromApex(
    input,
    'GetQuoteProposalDataSteppedUpPricing'
);
System.debug(LoggingLevel.ERROR, 'DRYRUN_EXTRACT_ERRORS=' + extractResult.hasErrors());
System.debug(LoggingLevel.ERROR, 'DRYRUN_EXTRACT=' + extractResult.toJson());

Map<String, Object> extracted = (Map<String, Object>) extractResult.toJson();
omnistudio.DRProcessResult transformResult = omnistudio.DRGlobal.processFromApex(
    extracted,
    'CPQQuoteProposalDocumentSteppedUpPricing'
);
System.debug(LoggingLevel.ERROR, 'DRYRUN_TRANSFORM_ERRORS=' + transformResult.hasErrors());
System.debug(LoggingLevel.ERROR, 'DRYRUN_TRANSFORM=' + transformResult.toJson());
