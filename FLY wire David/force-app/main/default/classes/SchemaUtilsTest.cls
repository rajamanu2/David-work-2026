@isTest
public class SchemaUtilsTest {

    @isTest
    static void shouldGetDefaultRecordType() {
        Test.startTest();
        List<String> defaultRecordType = SchemaUtils.getDefaultRecordType(new List<String>{'Opportunity'});
        Test.stopTest();

        // System Administrator default Opportunity record type
        String eduRt = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Education').getRecordTypeId();
        Assert.areEqual(eduRt, defaultRecordType[0]);
    }
}