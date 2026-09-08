trigger LoanerAssetTrigger on Loaner_Asset__c (before insert, before update, after insert, after update) {
    
	LoanerAssetTriggerHandler th = new LoanerAssetTriggerHandler();
    th.run();
    
}