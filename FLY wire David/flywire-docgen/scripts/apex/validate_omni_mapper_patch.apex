Savepoint validationSavepoint = Database.setSavepoint();
try {
    Map<Id, String> outputPathUpdates = new Map<Id, String>{
        '0kdhG0000002nKnQAI' => 'Group:Line:ProductName',
        '0kdhG0000002nMPQAY' => 'Group:Line:ShipToAccountName',
        '0kdhG0000002nO1QAI' => 'Group:Line:Quantity',
        '0kdhG0000002nPdQAI' => 'Group:Line:BillingFrequency',
        '0kdhG0000002nRFQAY' => 'Group:Line:LineDescription',
        '0kdhG0000002nSrQAI' => 'Group:Line:Price',
        '0kdhG0000002nW5QAI' => 'Group:Line:RateDetails',
        '0kdhG0000002nXhQAI' => 'Group:Line:QuoteLineType',
        '0kdhG0000002nZJQAY' => 'Group:Line:LineDescriptionWithType',
        '0kdhG0000002iubQAA' => 'QuoteLineGroup:QuoteLine:AdjustedRatePercent'
    };

    Set<Id> itemIds = new Set<Id>(outputPathUpdates.keySet());
    itemIds.add('0kdhG0000002mWoQAI');

    List<OmniDataTransformItem> items = [
        SELECT Id, OutputFieldName, FormulaExpression
        FROM OmniDataTransformItem
        WHERE Id IN :itemIds
        FOR UPDATE
    ];
    System.assertEquals(11, items.size(), 'All 11 targeted Data Mapper items must exist');

    for (OmniDataTransformItem item : items) {
        if (outputPathUpdates.containsKey(item.Id)) {
            item.OutputFieldName = outputPathUpdates.get(item.Id);
        } else if (item.Id == '0kdhG0000002mWoQAI') {
            item.FormulaExpression = 'IF(QuoteLineGroupsPresent = "false", true, false)';
        }
    }

    Database.SaveResult[] results = Database.update(items, false);
    Integer successCount = 0;
    List<String> errors = new List<String>();
    for (Database.SaveResult result : results) {
        if (result.isSuccess()) {
            successCount++;
        } else {
            for (Database.Error error : result.getErrors()) {
                errors.add(String.valueOf(result.getId()) + ': ' + error.getStatusCode() + ' - ' + error.getMessage());
            }
        }
    }

    System.assertEquals(11, successCount, 'Org validation failures: ' + String.join(errors, ' | '));
    System.debug(LoggingLevel.ERROR, 'ORG_VALIDATION_PASS: 11/11 Data Mapper item updates accepted before rollback');
} finally {
    Database.rollback(validationSavepoint);
    System.debug(LoggingLevel.ERROR, 'ORG_VALIDATION_ROLLBACK_COMPLETE: no changes committed');
}
