@isTest 
Private class ReviewStatusUpdateTest{
    static testMethod void myTest(){
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Name = 'testProduct';
        pro.Probe_Type__c = 'Sector';
        pro.Family = 'Ultrasound Part';
        insert pro;
        
        ProductItem__c newPitem = new ProductItem__c(Product_Name__c = pro.Id, Check_In_Type__c = 'Purchase', Serial_No__c = 'S00', Cost__c = 100.20, Location__c = 'Cage', Receive_date__c = System.today());
        insert newPitem;
        
        Review_Status__c newReview=new Review_Status__c(ProductItem__c=newPitem.Id,New_Review_Status__c='Repair Queue',Completed_By__c='Alex Buse');
        insert newReview;
    }
}