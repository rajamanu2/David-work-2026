@isTest
public class ActivityComponentControllerTest {

    @TestSetup
    static void makeData() {
        Database.SaveResult sr = Database.insert(new Account(
            Name = 'Test Account',
            ShippingCountry = 'United States',
            ShippingState = 'MA',
            ShippingStreet = 'Suite 10, 141 Tremont Street',
            ShippingCity = 'Boston',
            ShippingPostalCode = '02111',
            BillingCountry = 'United States',
            BillingState = 'MA',
            BillingStreet = 'Suite 10, 141 Tremont Street',
            BillingCity = 'Boston',
            BillingPostalCode = '02111'
        ));        
    }

    // ActivityHistory object can't be accessed or created from tests
    // This test is only to ensure code coverage
    @isTest
    static void nonMarketoActivityTest() {

        Test.startTest();
        ActivityComponentController.getActivities([SELECT Id FROM Account LIMIT 1].Id);
        Test.stopTest();
    }
    
    // ActivityHistory object can't be accessed or created from tests
    // This test is only to ensure code coverage
    @isTest
    static void keyObjectiveActivityTest() {

        Test.startTest();
        ActivityComponentController.getKeyObjectiveActivities([SELECT Id FROM Account LIMIT 1].Id, 1);
        Test.stopTest();
    }
    
    // OpenActivity object can't be accessed or created from tests
    // This test is only to ensure code coverage
    @isTest
    static void OpenkeyObjectiveActivityTest() {
        
        Test.startTest();
        ActivityComponentController.getOpenKeyObjectiveActivities([SELECT Id FROM Account LIMIT 1].Id, 10);
        Test.stopTest();
    }
    
    // OpenActivity object can't be accessed or created from tests
    // This test is only to ensure code coverage
    @isTest
    static void openNonMarketoActivitiesTest() {

        Test.startTest();
        ActivityComponentController.getOpenNonMarketoActivities([SELECT Id FROM Account LIMIT 1].Id);
        Test.stopTest();
    }
}