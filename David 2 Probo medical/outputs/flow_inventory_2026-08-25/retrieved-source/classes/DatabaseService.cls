/**
 * This class provides common Database (DML) methods that provide logging, and record handling.
 */
public class DatabaseService {

    public static void insertList(List<sObject> obsforDML){
        DatabaseService.insertList(obsforDML, true);
    }

    public static void updateList(List<sObject> obsforDML){
        DatabaseService.updateList(obsforDML, true);
    }

    public static void upsertList(List<sObject> obsforDML){
        DatabaseService.upsertList(obsforDML, true);
    }

    public static void deleteList(List<sObject> obsforDML){
        DatabaseService.deleteList(obsforDML, true);
    }

    public static void insertRecord(sObject obsforDML){
        DatabaseService.insertList(new List<sObject>{obsforDML}, true);
    }

    public static void updateRecord(sObject obsforDML){
        DatabaseService.updateList(new List<sObject>{obsforDML}, true);
    }

    public static void deleteRecord(sObject obsforDML){
        DatabaseService.deleteList(new List<sObject>{obsforDML}, true);
    }

    private static List<Database.SaveResult> insertList(List<sObject> obsforDML, Boolean allOrNone){
        List<Database.SaveResult> ret = new List<Database.SaveResult>();
        insert obsforDML;
        return ret;

        // TODO: implement Database insert support
       // Database.insert(obsforDML, false);
    }

    private static List<Database.SaveResult> updateList(List<sObject> obsforDML, Boolean allOrNone){
        List<Database.SaveResult> ret = new List<Database.SaveResult>();
        update obsforDML;
        return ret;

        // TODO: implement Database update support
        //Database.update(obsforDML, false);

    }

    private static List<Database.SaveResult> upsertList(List<sObject> obsforDML, Boolean allOrNone){
        List<Database.SaveResult> ret = new List<Database.SaveResult>();
        upsert obsforDML;
        return ret;

        // TODO: implement Database update support
        //Database.upsert(obsforDML, false);

    }

    private static List<Database.DeleteResult> deleteList(List<sObject> obsforDML, Boolean allOrNone){
        List<Database.DeleteResult> ret = new List<Database.DeleteResult>();
        delete obsforDML;
        return ret;

        // TODO: implement Database delete support
        //Database.delete(obsforDML, false);

    }

}