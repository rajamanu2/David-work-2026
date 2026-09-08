/********************************
* @Author: Degelate 
* @Date: 5/1/2021
* @description: utility functions for objecgts
*/

public with sharing class Delegate_ObjUntils {
    public static Boolean CheckPropertyChanged(sObject newObj, sObject oldObj, List<string> properties) {
        for(string prop : properties) {
            if(newObj.get(prop) !=  oldObj.get(prop)) {
                return true;
            }
        }
        return false;
    }
}