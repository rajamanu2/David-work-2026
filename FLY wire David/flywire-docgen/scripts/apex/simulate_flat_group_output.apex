Savepoint sp = Database.setSavepoint();
try {
    Map<Id, String> paths = new Map<Id, String>{
        '0kdhG0000002nKnQAI' => 'Group:ProductName',
        '0kdhG0000002nMPQAY' => 'Group:ShipToAccountName',
        '0kdhG0000002nO1QAI' => 'Group:Quantity',
        '0kdhG0000002nPdQAI' => 'Group:BillingFrequency',
        '0kdhG0000002nRFQAY' => 'Group:LineDescription',
        '0kdhG0000002nSrQAI' => 'Group:Price',
        '0kdhG0000002nW5QAI' => 'Group:RateDetails',
        '0kdhG0000002nXhQAI' => 'Group:QuoteLineType',
        '0kdhG0000002nZJQAY' => 'Group:LineDescriptionWithType'
    };
    List<OmniDataTransformItem> items = [
        SELECT Id, OutputFieldName FROM OmniDataTransformItem WHERE Id IN :paths.keySet()
    ];
    for (OmniDataTransformItem item : items) item.OutputFieldName = paths.get(item.Id);
    update items;

    Map<String, Object> input = new Map<String, Object>{'Id' => 'a2NhG000002ktrcUAA'};
    omnistudio.DRProcessResult extractResult = omnistudio.DRGlobal.processFromApex(
        input, 'GetQuoteProposalDataSteppedUpPricing'
    );
    Map<String, Object> extracted = (Map<String, Object>) extractResult.toJson();
    omnistudio.DRProcessResult transformed = omnistudio.DRGlobal.processFromApex(
        extracted, 'CPQQuoteProposalDocumentSteppedUpPricing'
    );
    System.debug(LoggingLevel.ERROR, 'SIMULATED_FLAT_OUTPUT=' + transformed.toJson());
} finally {
    Database.rollback(sp);
    System.debug(LoggingLevel.ERROR, 'SIMULATION_ROLLED_BACK=true');
}
