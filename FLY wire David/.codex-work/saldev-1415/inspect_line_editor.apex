Map<String, Schema.FieldSet> setsByName = Schema.SObjectType.SBQQ__QuoteLineGroup__c.fieldSets.getMap();
System.debug(LoggingLevel.ERROR, 'SALDEV1415_FIELDSET_KEYS=' + setsByName.keySet());
for (String key : setsByName.keySet()) {
    Schema.FieldSet fs = setsByName.get(key);
    System.debug(LoggingLevel.ERROR, 'SALDEV1415_FIELDSET=' + key + '|' + fs.getName() + '|' + fs.getLabel());
    Integer position = 0;
    for (Schema.FieldSetMember member : fs.getFields()) {
        position++;
        System.debug(LoggingLevel.ERROR,
            'SALDEV1415_FIELDSET_MEMBER=' + key + '|' + position + '|' + member.getFieldPath() +
            '|required=' + member.getRequired() + '|dbRequired=' + member.getDbRequired());
    }
}
