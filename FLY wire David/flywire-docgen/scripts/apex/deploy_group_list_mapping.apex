Id wholeGroupMappingId = '0kdhG0000002lhDQAQ';
Set<Id> disableIds = new Set<Id>{
    '0kdhG0000002lhEQAQ', // Group StartDate
    '0kdhG0000002mWnQAI', // Group EndDate
    '0kdhG0000002nELQAY', // root GroupNumber (fans out root)
    '0kdhG0000002nKnQAI',
    '0kdhG0000002nMPQAY',
    '0kdhG0000002nO1QAI',
    '0kdhG0000002nPdQAI',
    '0kdhG0000002nRFQAY',
    '0kdhG0000002nSrQAI',
    '0kdhG0000002nW5QAI',
    '0kdhG0000002nXhQAI',
    '0kdhG0000002nZJQAY'
};
Set<Id> allIds = new Set<Id>(disableIds);
allIds.add(wholeGroupMappingId);
List<OmniDataTransformItem> items = [
    SELECT Id, InputFieldName, OutputFieldName, OutputFieldFormat, IsDisabled
    FROM OmniDataTransformItem
    WHERE Id IN :allIds
    FOR UPDATE
];
System.assertEquals(13, items.size(), 'Expected all 13 targeted mapper rows');
for (OmniDataTransformItem item : items) {
    if (item.Id == wholeGroupMappingId) {
        item.InputFieldName = 'QuoteLineGroup';
        item.OutputFieldName = 'Group';
        item.OutputFieldFormat = null;
        item.IsDisabled = false;
    } else {
        item.IsDisabled = true;
    }
}
update items;
System.debug(LoggingLevel.ERROR,
    'GROUP_LIST_MAPPING_DEPLOYED|wholeList=1|disabledFanoutMappings=12');
