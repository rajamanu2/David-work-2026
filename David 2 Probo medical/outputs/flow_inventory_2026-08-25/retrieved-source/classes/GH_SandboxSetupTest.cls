@IsTest
private class GH_SandboxSetupTest {

    @IsTest
    static void createGHUsersTest() {
        GH_SandboxSetup.createGHUsers();
    }

    @IsTest
    static void runSandboxSetupTest() {
        GH_SandboxSetup.runSandboxSetup();
    }

    @isTest
    static void testSandboxPostCopyScript()
    {
        Test.startTest();

        // Using any Ids as orgId and sandboxId for test, e.g. Account Ids
        // Id possible pass valid id
        Test.testSandboxPostCopyScript(
                new GH_SandboxSetup(),
                UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(),
                'TestSBox'
        );

        Test.stopTest();
    }
}