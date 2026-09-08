@IsTest
private class OneTimeCalcExistingLastRepairDateTest {

    @IsTest
    static void testBatch() {

        List<Product2> pToInsert = new List<Product2>();

        Product2 p = TestDataFactory.createProduct('Ultrasound Probe', false);
        p.Name = 'test';
        p.Probe_Type__c = 'Linear';
        pToInsert.add(p);

        Product2 p2 = TestDataFactory.createProduct('Ultrasound Probe', false);
        p2.Name = 'Array - test';
        p2.Probe_Type__c = 'Linear';
        p2.Family = 'Ultrasound Part';
        p2.Parent_Product__c = p.Id;
        pToInsert.add(p2);

        insert pToInsert;

        ProductItem__c pi = new ProductItem__c(Product_Name__c = p.Id, Check_In_Type__c = 'Purchase', Serial_No__c = '64603208',
                Cost__c = 259.57, Location__c = 'Repair Area', Receive_date__c = Date.today());
        insert pi;

        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SobjectType = 'Product_Repair__c' AND Name = 'Harvest' LIMIT 1];

        Datetime myDate = Datetime.newInstance(2016, 1, 1, 12, 30, 0);

        Product_Repair__c pr2 = new Product_Repair__c(RecordTypeId = rt.Id, Product_Item__c = pi.Id,
                Repair_date__c = myDate, Part_to_Harvest__c = 'Array Carriage');
        insert pr2;

        Test.startTest();
        System.debug('TEST - start of test');
        Database.executeBatch(new OneTimeCalcExistingLastRepairDates(), 200);
        Test.stopTest();

        ProductItem__c thePI = [SELECT Id, Last_Repair__c FROM ProductItem__c WHERE Id = :pi.Id LIMIT 1];
        System.assertEquals(pr2.Repair_date__c, thePI.Last_Repair__c, 'Batch did not set the Repair_date__c correctly');
    }

}