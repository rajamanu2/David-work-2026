// Read-only baseline: Extract and Transform only. No DML or document generation.
// Both mapper configs were inspected: no preprocessor/input/output parsing classes.
for (SBQQ__Quote__c quote : [SELECT Id, Name FROM SBQQ__Quote__c
    WHERE Name IN ('Q-37723', 'Q-37780', 'Q-38021', 'Q-38029')]) {
    omnistudio.DRProcessResult extracted = omnistudio.DRGlobal.processFromApex(
        new Map<String,Object>{'Id' => quote.Id}, 'GetQuoteProposalDataSteppedUpPricing');
    omnistudio.DRProcessResult transformed = omnistudio.DRGlobal.processFromApex(
        (Map<String,Object>)extracted.toJson(), 'CPQQuoteProposalDocumentSteppedUpPricing');
    System.debug(LoggingLevel.ERROR, 'SALDEV1403_BASELINE|' + quote.Name + '|' + JSON.serialize(
        new Map<String,Object>{'extractErrors'=>extracted.hasErrors(),
        'transformErrors'=>transformed.hasErrors(), 'extracted'=>extracted.toJson(),
        'transformed'=>transformed.toJson()}));
}

