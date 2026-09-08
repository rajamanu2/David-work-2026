@isTest
private class setCustomModifyDateTestClass{

    static testmethod void test() {
        Account acc = new Account(name='abc');
        insert acc;
    
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Name = 'Ultrasound Probe-Philips C5-1';
        insert pro;
        
        ProductItem__c prItem1 = new ProductItem__c(Product_Name__c=pro.Id,Check_In_Type__c='Purchase',Serial_No__c='12345',Receive_date__c=Date.parse('01/08/2015'),Cost__c=1000.00,Location__c='WIP');
        insert prItem1;

        Test.startTest();
        setCustomModifyDate  upfb = new setCustomModifyDate();
        Database.executeBatch(upfb,200);
        Test.stopTest();
    }

}