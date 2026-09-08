@isTest
public class RatingsUpdateTest {

    static testMethod void cosmeticTest(){
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Name = 'testProduct';
        pro.Probe_Type__c = 'Convex';
        insert pro;

        ProductItem__c newPitem = new ProductItem__c(Product_Name__c = pro.Id, Check_In_Type__c = 'Purchase', Serial_No__c = 'S00', Cost__c = 100.20, Location__c = 'Cage',
                Receive_date__c = System.today(), Cosmetic_Rating__c = 'Fair', Functional_Rating__c = 'Fair');
        insert newPitem;

        Ratings__c newRating=new Ratings__c(Asset__c=newPitem.Id,New_Rating__c='Good', Old_Rating__c = 'Fair', Cosmetic_or_Functional_Change__c = 'Cosmetic Rating',
                Completed_By__c = 'Natalie Boger', Reason_for_change__c = 'TEST');
        insert newRating;
    }

    static testMethod void functionalTest(){
        Product2 pro = TestDataFactory.createProduct('Ultrasound Probe', false);
        pro.Name = 'testProduct';
        pro.Probe_Type__c = 'Convex';
        insert pro;

        ProductItem__c newPitem = new ProductItem__c(Product_Name__c = pro.Id, Check_In_Type__c = 'Purchase', Serial_No__c = 'S00', Cost__c = 100.20, Location__c = 'Cage',
                Receive_date__c = System.today(), Cosmetic_Rating__c = 'Fair', Functional_Rating__c = 'Fair');
        insert newPitem;

        Ratings__c newRating=new Ratings__c(Asset__c=newPitem.Id,New_Rating__c='Good', Old_Rating__c = 'Fair', Cosmetic_or_Functional_Change__c = 'Functional Rating',
                Completed_By__c = 'Natalie Boger', Reason_for_change__c = 'TEST');
        insert newRating;
    }

}