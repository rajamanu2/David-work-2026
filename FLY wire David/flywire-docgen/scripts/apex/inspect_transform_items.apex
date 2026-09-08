Id mapperId = '0jIhG0000000HX7UAM';
for (OmniDataTransformItem item : [
    SELECT Id, Name, InputObjectName, InputFieldName,
           OutputObjectName, OutputFieldName,
           OutputCreationSequence, InputObjectQuerySequence,
           FormulaExpression, FormulaResultPath, FormulaSequence,
           IsDisabled
    FROM OmniDataTransformItem
    WHERE OmniDataTransformationId = :mapperId
    ORDER BY OutputCreationSequence, FormulaSequence, InputObjectQuerySequence, Id
]) {
    System.debug(LoggingLevel.ERROR,
        'ITEM|' + item.Id +
        '|inObj=' + item.InputObjectName +
        '|inField=' + item.InputFieldName +
        '|outObj=' + item.OutputObjectName +
        '|outField=' + item.OutputFieldName +
        '|outSeq=' + item.OutputCreationSequence +
        '|inSeq=' + item.InputObjectQuerySequence +
        '|formula=' + item.FormulaExpression +
        '|formulaPath=' + item.FormulaResultPath +
        '|formulaSeq=' + item.FormulaSequence +
        '|disabled=' + item.IsDisabled
    );
}
