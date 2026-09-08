/**
* @author Delagate
* @date 7/21/2021
*
* @description
*/

public class UserUtilities {
    //private static Map<Id, User> thisUserMap;
    public static Map<Id, User> GetActiveUsers() {
        //if(thisUserMap == null) {
        //    System.debug('CCu...found usermap');
            List<User> userList = [SELECT ID, FirstName, LastName, Email, Location__c
                                    FROM User
                                    WHERE IsActive = true];
            Map<Id, User> userMap = new Map<Id, User>();
            for(User u : userList) {
                userMap.put(u.Id, u);
            }
            //thisUserMap = userMap;
        //}
        return userMap;
    }
}