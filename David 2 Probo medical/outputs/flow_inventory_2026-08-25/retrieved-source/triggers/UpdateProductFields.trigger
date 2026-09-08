trigger UpdateProductFields on Product2 (before update) {

    // SOQL, DML, hardcoded all set  - Deployed to devint
    for (Product2 p: trigger.new){

        // automatically update changes the product information last updated date
        if((Trigger.oldMap.get(p.id).Std_Cost_ex__c != p.Std_Cost_ex__c)
                || (Trigger.oldMap.get(p.id).Std_Cost_Out__c != p.Std_Cost_Out__c)
                || (Trigger.oldMap.get(p.id).Sug_Pr_Ex__c != p.Sug_Pr_Ex__c)
                || (Trigger.oldMap.get(p.id).Sug_Pr_Out__c != p.Sug_Pr_Out__c)){
            p.Product_Information_Last_Updated__c = date.today();
        }
    }

}