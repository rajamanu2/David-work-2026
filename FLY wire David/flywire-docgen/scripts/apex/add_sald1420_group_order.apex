Id mapperId = '0jIhG0000000I3NUAU';
List<OmniDataTransformItem> existingOrder = [
    SELECT Id FROM OmniDataTransformItem
    WHERE OmniDataTransformationId = :mapperId
      AND FilterOperator = 'ORDER BY'
      AND OutputFieldName = 'SBQuote:QuoteLineGroup'
];
if (existingOrder.isEmpty()) {
    OmniDataTransformItem groupQuery = [
        SELECT Name, InputObjectName, OutputObjectName, OutputFieldName,
               OutputCreationSequence, InputObjectQuerySequence, FilterGroup, IsDisabled
        FROM OmniDataTransformItem
        WHERE OmniDataTransformationId = :mapperId
          AND InputObjectName = 'SBQQ__QuoteLineGroup__c'
          AND OutputFieldName = 'SBQuote:QuoteLineGroup'
        LIMIT 1
    ];
    OmniDataTransformItem orderItem = groupQuery.clone(false, true, false, false);
    orderItem.OmniDataTransformationId = mapperId;
    orderItem.Name = 'SALDEV1420_GetApprovalQuoteEmailData';
    orderItem.InputFieldName = null;
    orderItem.FilterOperator = 'ORDER BY';
    orderItem.FilterValue = 'SBQQ__SubscriptionTerm__c DESC, SBQQ__Number__c ASC';
    insert orderItem;
    System.debug(LoggingLevel.ERROR, 'SALDEV1420_ORDER_CREATED|' + orderItem.Id);
} else {
    System.debug(LoggingLevel.ERROR, 'SALDEV1420_ORDER_EXISTS|' + existingOrder[0].Id);
}
