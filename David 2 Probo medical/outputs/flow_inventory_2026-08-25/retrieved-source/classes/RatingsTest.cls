/**
 * Created by jeff on 8/15/18.
 */

@IsTest
private class RatingsTest {

    static testMethod void basicTest() {

        ProductItem__c p = new ProductItem__c();
        p.Cosmetic_Rating__c = 'A';
        p.Functional_Rating__c = 'B';
        p.Receive_date__c = Date.today();
        insert p;

        apexPages.currentPage().getParameters().put('CF00N0B0000066uAE_lkid',p.Id);

        ApexPAges.StandardController sc = new ApexPages.StandardController(p);

        Ratings r = new Ratings(sc);
        r.newCosmeticRating();
        r.newFunctionalRating();


    }


}