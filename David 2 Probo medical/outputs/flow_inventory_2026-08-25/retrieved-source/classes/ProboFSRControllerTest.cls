@IsTest
public class ProboFSRControllerTest {

    @IsTest
    static void testController_Asset() {
        Account acct = new Account(Name='Test Account');
        insert acct;

        Asset a = new Asset(
            Name            = 'Test Asset',
            AccountId       = acct.Id,
            Make_Model__c   = 'Standard Model',
            OEM_Serial__c   = 'OEM-111',
            SerialNumber    = 'AS-111'
        );
        insert a;

        WorkOrder wo = new WorkOrder(
            AccountId = acct.Id,
            Subject   = 'Test WO',
            Status    = 'New',
            AssetId   = a.Id
        );
        insert wo;

        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(wo);
        ProboFSRController controller = new ProboFSRController(stdCtrl);

        System.assertEquals('Standard Model', controller.equipmentMakeModel);
        System.assertEquals('OEM-111',        controller.equipmentOemSerial);
        System.assertEquals('AS-111',         controller.equipmentSerial);
    }

    @IsTest
    static void testController_ContactAndWorkType() {
// Create a WorkType so our controller query returns a name
WorkType wt = new WorkType(
    Name = 'Test Work Type',
    EstimatedDuration = 60
);
insert wt;


        // Create Contact
        Contact c = new Contact(LastName='Smith');
        insert c;

        // Create Account
        Account acct = new Account(Name='Contact Test Account');
        insert acct;

        // Create Asset
        Asset a = new Asset(
            Name            = 'Asset2',
            AccountId       = acct.Id,
            Make_Model__c   = 'Model2',
            OEM_Serial__c   = 'OEM-222',
            SerialNumber    = 'AS-222'
        );
        insert a;

        // Create WorkOrder referencing the Contact and WorkType
        WorkOrder wo = new WorkOrder(
            AccountId   = acct.Id,
            Subject     = 'WO with Contact and WT',
            Status      = 'New',
            AssetId     = a.Id,
            ContactId   = c.Id,
            WorkTypeId  = wt.Id
        );
        insert wo;

        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(wo);
        ProboFSRController controller = new ProboFSRController(stdCtrl);

        System.assertEquals('Smith',          controller.contactOrLeadName);
        System.assertEquals('Test Work Type', controller.workTypeName);
    }
    
    @IsTest
static void testController_NoAsset() {
    // Create minimal Account and WorkOrder with NO AssetId
    Account acct = new Account(Name='Account – No Asset');
    insert acct;

    WorkOrder wo = new WorkOrder(
        AccountId = acct.Id,
        Subject   = 'WO with no Asset',
        Status    = 'New'
        // AssetId intentionally omitted
    );
    insert wo;

    ApexPages.StandardController stdCtrl = new ApexPages.StandardController(wo);
    ProboFSRController controller = new ProboFSRController(stdCtrl);

    // All equipment fields should be null since no Asset was supplied
    System.assertEquals(null, controller.equipmentMakeModel);
    System.assertEquals(null, controller.equipmentOemSerial);
    System.assertEquals(null, controller.equipmentSerial);
}

}