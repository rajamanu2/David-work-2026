trigger P_ProductAnalyticsTrigger on Product_Analytics__c (before delete) {
    for (Product_Analytics__c prod : Trigger.old) {
            prod.addError('Product Analytics records cannot be deleted.');            
    }
}