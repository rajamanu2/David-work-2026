@isTest
public class MassBarcodeControllerTest {

@testSetup
static void setupTestData() {
    ProductItem__c testAsset = new ProductItem__c(
        Label_Printed__c = false
    );
    insert testAsset;
}
    @isTest
    static void testControllerWithValidIds() {
        ProductItem__c testAsset = [SELECT Id FROM ProductItem__c LIMIT 1];

        PageReference pageRef = Page.MassPrintBarcodes;
        pageRef.getParameters().put('ids', testAsset.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        MassBarcodeController controller = new MassBarcodeController();
        controller.updateLabels();
        Test.stopTest();

        System.assertNotEquals(0, controller.assetWrappers.size(), 'Should have at least one wrapper');

        ProductItem__c updated = [SELECT Label_Printed__c FROM ProductItem__c WHERE Id = :testAsset.Id];
        System.assertEquals(true, updated.Label_Printed__c, 'Label_Printed__c should be true');
    }

    @isTest
    static void testControllerWithNoIds() {
        PageReference pageRef = Page.MassPrintBarcodes;
        Test.setCurrentPage(pageRef);

        Test.startTest();
        MassBarcodeController controller = new MassBarcodeController();
        Test.stopTest();

        System.assertEquals(0, controller.assetWrappers.size(), 'Should have no wrappers');
    }

    @isTest
    static void testControllerWithMultipleIds() {
ProductItem__c testAsset2 = new ProductItem__c(
    Label_Printed__c = false
);
insert testAsset2;

        List<ProductItem__c> assets = [SELECT Id FROM ProductItem__c];
        String ids = assets[0].Id + ',' + assets[1].Id;

        PageReference pageRef = Page.MassPrintBarcodes;
        pageRef.getParameters().put('ids', ids);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        MassBarcodeController controller = new MassBarcodeController();
        controller.updateLabels();
        Test.stopTest();

        System.assertEquals(2, controller.assetWrappers.size(), 'Should have two wrappers');
    }

}