@isTest
private class RecordTypeUtilityTest {
    
    static testmethod void testGetRecordTypeByName() {
        List<RecordType> listRecordTypes = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SobjectType = 'Opportunity' AND Name = 'Sales Opportunity' LIMIT 1];
        Id salesRecordTypeId;
        test.startTest();
        salesRecordTypeId = RecordTypeUtility.getRecordTypeByName('Opportunity', listRecordTypes[0].Name);
        test.stopTest();
        
        system.assertEquals(listRecordTypes[0].Id, salesRecordTypeId, 'Record Type Id is not the Sales Record Type Id');
    }     

    static testmethod void testGetRecordTypeByDeveloperName() {
        List<RecordType> listRecordTypes = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SobjectType = 'Opportunity' AND Name = 'Sales Opportunity' LIMIT 1];
        Id salesRecordTypeId;
        test.startTest();
        salesRecordTypeId = RecordTypeUtility.getRecordTypeByDeveloperName('Opportunity', listRecordTypes[0].DeveloperName);
        test.stopTest();
        
        system.assertEquals(listRecordTypes[0].Id, salesRecordTypeId, 'Record Type Id is not the Sales Record Type Id');
    }
    
    static testmethod void testGetRecordTypeID() {
        List<RecordType> listRecordTypes = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SobjectType = 'Opportunity' AND Name = 'Sales Opportunity' LIMIT 1];
        Id salesRecordTypeId;
        test.startTest();
        salesRecordTypeId = RecordTypeUtility.getRecordTypeID('Opportunity', listRecordTypes[0].Name);
        test.stopTest();
        
        system.assertEquals(listRecordTypes[0].Id, salesRecordTypeId, 'Record Type Id is not the Sales Record Type Id');
    } 
    
    static testmethod void testRecordTypePickListValues() {
        Map<Id, RecordType> mapRecordTypes = new Map<Id, RecordType>([SELECT Id, Name, DeveloperName FROM RecordType WHERE SobjectType = 'Opportunity']);
        List<RecordTypeUtility.Option> recordTypeOptions = new List<RecordTypeUtility.Option>();
        Map<Id,String> recordTypesForObject = new Map<Id,String>();
        
		test.startTest(); 
        recordTypeOptions = (List<RecordTypeUtility.Option>)RecordTypeUtility.getRecordTypePickListValues('Opportunity');
        test.stopTest();
        
        for (RecordTypeUtility.Option opt:  recordTypeOptions) {
             recordTypesForObject.put(opt.value, opt.label);
        }
        
        system.assert(!recordTypeOptions.isEmpty(), 'No picklist values found');
        
        for (Id recordTypeId: mapRecordTypes.keySet()) {
             system.assert(recordTypesForObject.containsKey(recordTypeId), 'Record type Id not found');
             RecordType r = mapRecordTypes.get(recordTypeId);
             system.assertEquals(r.Name, recordTypesForObject.get(recordTypeId), 'Record type Id not found');
        }
        
    }    
    

}