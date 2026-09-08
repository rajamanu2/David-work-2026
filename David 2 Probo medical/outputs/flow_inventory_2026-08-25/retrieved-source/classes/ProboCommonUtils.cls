public class ProboCommonUtils {

    private static Pricebook2 stdPriceBook;
    private static User theCurrentUser;
    private static Map<String, List<RecordType>> recTypeMap;

    public static List<RecordType> getRecordTypes(String sObjectType) {

        // get all the record types we have so there is only 1 SOQL
        if (recTypeMap == null) {
            recTypeMap = new Map<String, List<RecordType>>();

            for (RecordType r : [
                    select Id, SobjectType, Name, DeveloperName, isActive
                    from RecordType
            ]) {
                if (!recTypeMap.containsKey(r.SobjectType)) {
                    recTypeMap.put(r.SobjectType, new List<RecordType>());
                }

                recTypeMap.get(r.SobjectType).add(r);
            }
        }

        // then return the record types for the requested sObjectType or an empty list
        return (recTypeMap.containsKey(sObjectType) ? recTypeMap.get(sObjectType) : new List<RecordType>());
    }

    public static Id getStdPricebookId() {

        if (stdPriceBook == null) {

            if (Test.isRunningTest()) {
                Pricebook2 standardPricebook = new Pricebook2(
                        Id = Test.getStandardPricebookId(),
                        IsActive = true
                );

                stdPriceBook = standardPricebook;

            } else {
                try {
                    stdPriceBook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true and IsActive = true LIMIT 1];

                } catch (Exception e) {
                    System.debug('UTILS: Unable to find Standard PriceBook.');
                }
            }

            // Run an update DML on the Pricebook2 record
            // This is the weird workaround that enables IsStandard to become true
            // on the PricebookEntry record
//            update standardPricebook;
        }
        return stdPriceBook.Id;
    }

    public static User getCurrentUser() {

        if (theCurrentUser == null) {
            theCurrentUser = [
                    SELECT Id, Name, Username, FirstName, LastName, Title, Email, ProfileId, Profile.Name,
                            Phone, MobilePhone, Fax, Street, City, State, PostalCode, Country, UserType,
                            CommunityNickname, TimeZoneSidKey, LanguageLocaleKey, Location__c, User_Location__c,
                            LocaleSidKey, Extension, Contact.Email
                    FROM User
                    WHERE Id = :UserInfo.getUserId()
            ];
        }

        return theCurrentUser;
    }

    /**
      * Used to store the GlobalDescribeResults so we can reuse it in a transaction
     */
    private static Map<String, Schema.SObjectType> globalDescribeResults;

    // we cache this since it is an expensive call
    public static Map<String, Schema.SObjectType> getGlobalDescribeResults() {

        if (globalDescribeResults == null) {
            globalDescribeResults = Schema.getGlobalDescribe();
        }
        return globalDescribeResults;
    }

    //gets all the available fields to be included in the query
    public static String fullObjectSelect(String objectName) {

        String query = 'SELECT ';

        Map<String, Schema.SObjectField> objectFields = getGlobalDescribeResults().get(objectName).getDescribe().fields.getMap();

        GH_Logger.debug('Have this many fields from the ' + objectName + ' object: ' + objectFields.size());
        for (String s : objectFields.keySet()) {
            // we don't need to include these 2 fields since they are not reliably defined in an org
            if (!s.equalsIgnoreCase('LastReferencedDate') && !s.equalsIgnoreCase('LastViewedDate')) {
                query += ' ' + s + ',';
            }
        }

        // Strip off the last comma if it exists.
        query = query.removeEnd(',');

        // Add FROM statement
        query += ' FROM ' + objectName;

        GH_Logger.debug('field String being returned: ' + query);
        return query;

    }
}