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
System.assertEquals(11, items.size(), 'All 11 target items must exist');

for (OmniDataTransformItem item : items) {
    if (outputPathUpdates.containsKey(item.Id)) {
        item.OutputFieldName = outputPathUpdates.get(item.Id);
    } else {
        item.FormulaExpression = 'IF(QuoteLineGroupsPresent = "false", true, false)';
    }
}
update items;
System.debug(LoggingLevel.ERROR, 'DEPLOY_PASS: committed 11 Data Mapper item updates');
