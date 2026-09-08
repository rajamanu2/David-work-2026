global class GH_SandboxSetup implements SandboxPostCopy{

    private static final String ORGUSERNAMEPART = '.probo';
    private static final String USERPROFILETOUSE = 'System Administrator Custom';

    public static void runSandboxSetup() {
        SandboxContext context = new MockSandboxContext();

        System.debug('Org ID: ' 	+ context.organizationId());
        System.debug('Sandbox ID: ' 	+ context.sandboxId());
        System.debug('Sandbox Name: ' 	+ context.sandboxName());

        new GH_SandboxSetup().runApexClass(context);
    }

    public class MockSandboxContext implements SandboxContext
    {
        public Id organizationID(){return UserInfo.getOrganizationId();}
        public Id sandboxID(){return UserInfo.getOrganizationId();}
        public String sandboxName(){return UserInfo.getOrganizationName();}
    }

    global void runApexClass(SandboxContext context){
        if (context != null) {
            System.debug('Org ID: ' + context.organizationId());
            System.debug('Sandbox ID: ' + context.sandboxId());
            System.debug('Sandbox Name: ' + context.sandboxName());
            List<Organization> org = [SELECT IsSandbox FROM Organization LIMIT 1];
            Boolean isSandbox = org.get(0).IsSandbox;
            System.debug('Sandbox?: ' + isSandbox);

            if (isSandbox) {
                GH_SandboxSetup.createGHUsers();
            }
        }
    }

    //Create User records for the GH staff
    @future
    public static void createGHUsers (){

        // Add new GH staff here
        Map<String, String> nameToUserEmail = new Map<String, String>{
                'Jeff May' => 'jeff@growthheroes.com',
                'Maurice Cheshire' => 'maurice@growthheroes.com',
                'Alan Buckel' => 'alan@growthheroes.com',
                'Ryan Howard' => 'ryan@growthheroes.com'
        };

        Organization currOrg = [SELECT IsSandbox FROM Organization LIMIT 1];

        //needed to fetch the sandbox name for creating new usernames
        User existAdminUser = [
                SELECT Id, Username, ProfileId, TimeZoneSidKey
                FROM User
                WHERE Profile.Name = :USERPROFILETOUSE
                LIMIT 1
        ];
        String sBoxSuffix = existAdminUser.Username.substring(existAdminUser.Username.lastIndexOf('.'));

        // only create users in a sandbox
        if (currOrg.IsSandbox) {

            // free up licenses for the new users
            List<User> uToDeact = new List<User>();
            for (User u : [SELECT Id, IsActive FROM User
            WHERE Profile.UserLicense.Name = 'Salesforce'
            AND IsActive = TRUE
            AND (NOT Profile.Name LIKE '%Admin%')
            ORDER BY LastLoginDate ASC NULLS FIRST
            LIMIT :nameToUserEmail.size()]){

                u.IsActive = false;
                uToDeact.add(u);
            }

            update uToDeact;

            List<User> usrsToCreate = new List<User>();

            for (String uName : nameToUserEmail.keySet()) {
                User u = new User();
                u.LanguageLocaleKey = 'en_US';
                u.LocaleSidKey = 'en_US';
                u.EmailEncodingKey = 'UTF-8';
                u.ProfileId = existAdminUser.ProfileId;
                u.TimeZoneSidKey = existAdminUser.TimeZoneSidKey;
                u.LastName = uName;
                u.Email = nameToUserEmail.get(uName);
                u.Username = nameToUserEmail.get(uName) + ORGUSERNAMEPART + sBoxSuffix;
                if (Test.isRunningTest()){
                    u.Username += String.valueOf(DateTime.now().millisecond());
                }
                u.Alias = uName.remove(' ').left(4);

                usrsToCreate.add(u);
            }

            // doing partial in case one or more users already exist
            Database.insert(usrsToCreate, false);

            for (User thisUsr : usrsToCreate) {
                if (thisUsr.Id != null){
                    System.resetPassword(thisUsr.Id, true);
                }
            }
        }
    }
}