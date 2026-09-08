@IsTest
public class OppContactRolesAddControllerTest {

    private static final Id RUNNING_USER_ID = UserInfo.getUserId();
    // specific counter to ensure unique emails
    private static Integer contactCounter = 0; 

    // --- Helper Methods ---

    private static Account createAccount() {
        Account acc = new Account(Name = 'Test Account', OwnerId = RUNNING_USER_ID);
        insert acc;
        return acc;
    }

    private static Contact createContact(Id accountId) {
        contactCounter++;
        Contact con = new Contact(
            FirstName = 'Test', 
            LastName = 'Contact ' + contactCounter, 
            AccountId = accountId, 
            // Unique email to bypass duplicate rules
            Email = 'testuser' + contactCounter + '_' + System.currentTimeMillis() + '@example.com'
        );
        insert con;
        return con;
    }

    private static Opportunity createOpportunity(Id accountId) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = accountId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1),
            OwnerId = RUNNING_USER_ID
        );
        insert opp;
        return opp;
    }

    // --- TEST METHODS ---

    /** ✅ Scenario 1: Initialization & Navigation (Success Path) **/
    @IsTest
    static void testInitialization() {
        // --- 1. Setup Data ---
        Account acc = createAccount();
        Opportunity opp = createOpportunity(acc.Id);

        // --- 2. Execution ---
        Test.startTest();
            // Set Page Parameters
            Test.setCurrentPageReference(new PageReference('Page.OppContactRolesAdd')); 
            ApexPages.currentPage().getParameters().put('id', opp.Id);

            OppContactRolesAddController ctrl = new OppContactRolesAddController();
        Test.stopTest();

        // --- 3. Assertions ---
        System.assertEquals('add', ctrl.mode, 'Mode should be initialized to "add".');
        System.assertEquals(opp.Id, ctrl.opportunityId, 'Opportunity ID should be captured from parameters.');
        // Add mode starts with 1 blank row
        System.assertEquals(1, ctrl.rows.size(), 'Add mode should start with 1 blank row.');
        System.assertEquals(1, ctrl.rowWraps.size(), 'Wrapper list should match rows list.');
        
        System.assertEquals('Add Contact Roles', ctrl.getTitle(), 'Title should reflect Add mode.');
        
        // Test Cancel
        PageReference cancelRef = ctrl.cancel();
        System.assertEquals('/' + opp.Id, cancelRef.getUrl(), 'Cancel should redirect back to Opportunity.');
    }

    /** ❌ Scenario 2: Missing Opportunity ID (Failure Path) **/
    @IsTest
    static void testMissingOpportunityId() {
        // --- 1. Execution (No ID in parameters) ---
        Test.startTest();
            Test.setCurrentPageReference(new PageReference('Page.OppContactRolesAdd')); 
            OppContactRolesAddController ctrl = new OppContactRolesAddController();
            ctrl.save(); // Try to save without ID
        Test.stopTest();

        // --- 2. Assertions ---
        List<ApexPages.Message> msgs = ApexPages.getMessages();
        Boolean foundError = false;
        for(ApexPages.Message msg : msgs) {
            if(msg.getDetail().contains('Missing Opportunity Id')) foundError = true;
        }
        System.assert(foundError, 'Should display error when Opportunity ID is missing.');
    }

    /** ✅ Scenario 3: Add and Remove Rows (UI Logic) **/
    @IsTest
    static void testAddRemoveRows() {
        // --- 1. Setup Data ---
        Account acc = createAccount();
        Opportunity opp = createOpportunity(acc.Id);

        Test.setCurrentPageReference(new PageReference('Page.OppContactRolesAdd')); 
        ApexPages.currentPage().getParameters().put('id', opp.Id);
        OppContactRolesAddController ctrl = new OppContactRolesAddController();

        // --- 2. Execution ---
        Test.startTest();
            // Initial state: 1 row
            ctrl.addRow(); // Add 2nd row
            ctrl.addRow(); // Add 3rd row
            
            System.assertEquals(3, ctrl.rows.size(), 'Should have 3 rows after adding 2.');

            // Remove middle row (Index 1)
            ctrl.rowIndex = 1;
            ctrl.removeRow();
        Test.stopTest();

        // --- 3. Assertions ---
        System.assertEquals(2, ctrl.rows.size(), 'Should have 2 rows after removing one.');
        // Ensure the indices in wrappers were rebuilt
        System.assertEquals(0, ctrl.rowWraps[0].idx);
        System.assertEquals(1, ctrl.rowWraps[1].idx);
    }

    /** ✅ Scenario 4: Save Records Successfully (DML Success) **/
    @IsTest
    static void testSaveSuccess() {
        // --- 1. Setup Data ---
        Account acc = createAccount();
        Opportunity opp = createOpportunity(acc.Id);
        Contact con = createContact(acc.Id);

        Test.setCurrentPageReference(new PageReference('Page.OppContactRolesAdd')); 
        ApexPages.currentPage().getParameters().put('id', opp.Id);
        OppContactRolesAddController ctrl = new OppContactRolesAddController();

        // --- 2. Execution ---
        Test.startTest();
            // Fill the first blank row
            ctrl.rows[0].ContactId = con.Id;
            ctrl.rows[0].Role = 'Decision Maker';
            ctrl.rows[0].IsPrimary = true;

            PageReference result = ctrl.save();
        Test.stopTest();

        // --- 3. Assertions ---
        System.assertNotEquals(null, result, 'Save should return a PageReference on success.');
        System.assertEquals(true, result.getRedirect(), 'Save should redirect.');

        List<OpportunityContactRole> savedRoles = [SELECT Id, Role, IsPrimary, ContactId FROM OpportunityContactRole WHERE OpportunityId = :opp.Id];
        System.assertEquals(1, savedRoles.size(), 'One record should be saved.');
        System.assertEquals('Decision Maker', savedRoles[0].Role);
        System.assertEquals(true, savedRoles[0].IsPrimary);
    }

    /** ❌ Scenario 5: Validation Errors (Required Fields & Multi-Primary) **/
    @IsTest
    static void testSaveValidations() {
        // --- 1. Setup Data ---
        Account acc = createAccount();
        Opportunity opp = createOpportunity(acc.Id);
        // These will now have unique emails
        Contact con1 = createContact(acc.Id);
        Contact con2 = createContact(acc.Id);

        Test.setCurrentPageReference(new PageReference('Page.OppContactRolesAdd')); 
        ApexPages.currentPage().getParameters().put('id', opp.Id);
        OppContactRolesAddController ctrl = new OppContactRolesAddController();

        // --- 2. Execution & Assertions ---
        Test.startTest();
            
            // A. Test Missing Role/Contact
            ctrl.rows[0].ContactId = con1.Id; 
            // Role is left null
            ctrl.save();
            
            Boolean roleError = false;
            for(ApexPages.Message msg : ApexPages.getMessages()) {
                if(msg.getDetail().contains('Role is required')) roleError = true;
            }
            System.assert(roleError, 'Should error if Role is missing.');

            // B. Test Multiple Primaries
            ctrl.rows[0].Role = 'Influencer'; // Fix previous error
            ctrl.rows[0].IsPrimary = true;
            
            ctrl.addRow();
            ctrl.rows[1].ContactId = con2.Id;
            ctrl.rows[1].Role = 'Evaluator';
            ctrl.rows[1].IsPrimary = true; // Second Primary

            ctrl.save();

            Boolean primaryError = false;
            for(ApexPages.Message msg : ApexPages.getMessages()) {
                if(msg.getDetail().contains('Only one Contact Role can be marked Primary')) primaryError = true;
            }
            System.assert(primaryError, 'Should error if multiple rows are marked Primary.');
            
        Test.stopTest();
    }
    
    /** ✅ Scenario 6: Delete Row Logic (DML) **/
    @IsTest
    static void testDeleteRowDml() {
        // --- 1. Setup Data ---
        Account acc = createAccount();
        Opportunity opp = createOpportunity(acc.Id);
        Contact con = createContact(acc.Id);
        
        // Insert an existing role
        OpportunityContactRole existingRole = new OpportunityContactRole(
            OpportunityId = opp.Id, 
            ContactId = con.Id, 
            Role = 'Influencer',
            IsPrimary = false
        );
        insert existingRole;

        Test.setCurrentPageReference(new PageReference('Page.OppContactRolesAdd')); 
        ApexPages.currentPage().getParameters().put('id', opp.Id);
        
        // Initialize controller
        OppContactRolesAddController ctrl = new OppContactRolesAddController();
        
        // --- 2. Execution ---
        Test.startTest();
            // Since this controller starts in 'add' mode, it ignores existing rows in DB.
            // To test the deletion logic in the Base class, we manually add the existing record 
            // to the rows list.
            ctrl.rows.add(existingRole);
            
            // Index 0 = The blank row created by init()
            // Index 1 = The existingRole we just added manually
            ctrl.rowIndex = 1; 
            
            // Calling removeRow() will:
            // 1. Identify the row at index 1 has an ID.
            // 2. Add it to rowsToDelete list.
            // 3. Remove it from rows list.
            // 4. Call rebuildWraps() internally.
            ctrl.removeRow();
            
            // Now save(), which triggers the delete DML on rowsToDelete
            ctrl.save();
        Test.stopTest();
        
        // --- 3. Assertions ---
        List<OpportunityContactRole> checkRoles = [SELECT Id FROM OpportunityContactRole WHERE Id = :existingRole.Id];
        System.assertEquals(0, checkRoles.size(), 'The existing role should be deleted from DB.');
    }
}