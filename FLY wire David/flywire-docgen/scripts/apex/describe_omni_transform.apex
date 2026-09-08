for (String objectName : new List<String>{'OmniDataTransform', 'OmniDataTransformItem'}) {
    Schema.DescribeSObjectResult d = Schema.getGlobalDescribe().get(objectName).getDescribe();
    List<String> fields = new List<String>();
    for (String fieldName : d.fields.getMap().keySet()) {
        Schema.DescribeFieldResult f = d.fields.getMap().get(fieldName).getDescribe();
        fields.add(fieldName + ':' + f.getType() + ':update=' + f.isUpdateable());
    }
    fields.sort();
    System.debug(LoggingLevel.ERROR, 'DESCRIBE|' + objectName + '|' + String.join(fields, ','));
}
