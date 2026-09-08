/**
* @author Delagate
* @date 8/4/2021
*
* @description container class for items needed in order to create various list repair items
*/

public class RepairLists {
    public String ApprovedRepairs {get;set;}
    public List<String> functionalRepairs {get;set;} //fnewrepair
    public List<String> cosmeticRepairs {get;set;} //cnewrepair
    public List<Integer> repairOrder {get;set;} //reserveorder
    public List<Integer> repairOrderSorted {
        get {
            repairOrder.sort();
            return repairOrder;
        }
    }
    public string declined {get;set;}
    public string declinedList {get;set;}
    public string newLocation {
        get {
            if(cosmeticRepairs != null) {
                return 'Repair Area - Cosmetic';
            } else if (functionalRepairs != null) {
                return 'Repair Area - Electrical';
            }
            return '';
        }
    }
}