Savepoint activationCheck = Database.setSavepoint();
try {
    DocumentTemplate template = [SELECT Id, Status, IsActive FROM DocumentTemplate WHERE Id='2dtPb0000000BwLIAU' FOR UPDATE];
    template.Status = 'Active';
    template.IsActive = true;
    update template;

    OmniProcess oldVersion = [SELECT Id, IsActive FROM OmniProcess WHERE Id='0jNhG0000000NFxUAM' FOR UPDATE];
    oldVersion.IsActive = false;
    update oldVersion;
    OmniProcess newVersion = [SELECT Id, IsActive FROM OmniProcess WHERE Id='0jNhG0000000umzUAA' FOR UPDATE];
    newVersion.IsActive = true;
    update newVersion;

    System.assertEquals(true, [SELECT IsActive FROM DocumentTemplate WHERE Id='2dtPb0000000BwLIAU'].IsActive);
    System.assertEquals(true, [SELECT IsActive FROM OmniProcess WHERE Id='0jNhG0000000umzUAA'].IsActive);
    System.assertEquals(false, [SELECT IsActive FROM OmniProcess WHERE Id='0jNhG0000000NFxUAM'].IsActive);
    System.debug(LoggingLevel.ERROR, 'ACTIVATION_VALIDATION_PASS');
} finally {
    Database.rollback(activationCheck);
    System.debug(LoggingLevel.ERROR, 'ACTIVATION_VALIDATION_ROLLBACK_COMPLETE');
}
