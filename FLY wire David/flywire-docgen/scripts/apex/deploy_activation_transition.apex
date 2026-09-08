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
System.debug(LoggingLevel.ERROR, 'ACTIVATION_DEPLOY_PASS: template active; OmniScript v2 active; v1 inactive');
