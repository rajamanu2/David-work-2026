public with sharing class SchemaUtils {

    @InvocableMethod(label='Get Default Record Type' description='Returns a list of 1 element containing the Default Record Type for an sObject.' category='Schema')
    public static List<String> getDefaultRecordType(List<String> sObjectType) {
        Schema.DescribeSObjectResult dsr = Schema.getGlobalDescribe().get(sObjectType[0]).getDescribe();
        String defaultRecordTypeId;
        for (Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()) {
            if (rti.isDefaultRecordTypeMapping()) {
                defaultRecordTypeId = rti.getRecordTypeId();
            }
        }
        return new List<String>{defaultRecordTypeId};
    }
}