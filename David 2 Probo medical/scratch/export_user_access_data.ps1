$ErrorActionPreference = 'Stop'

$targetOrg = 'ProboMedical'
$outputDirectory = Join-Path $PSScriptRoot 'user_access_export'
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

$exports = @(
    @{
        Name = 'organization'
        Query = 'SELECT Id, Name, IsSandbox, OrganizationType, InstanceName, DefaultLocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, FiscalYearStartMonth, CreatedDate FROM Organization'
    },
    @{
        Name = 'users'
        Query = 'SELECT Id, Username, Name, FirstName, LastName, Email, Alias, IsActive, UserType, ProfileId, Profile.Name, Profile.UserLicenseId, Profile.UserLicense.Name, UserRoleId, UserRole.Name, ManagerId, Manager.Name, Department, Division, Title, CompanyName, Phone, MobilePhone, TimeZoneSidKey, LocaleSidKey, LanguageLocaleKey, EmailEncodingKey, FederationIdentifier, CreatedDate, LastLoginDate, LastModifiedDate FROM User ORDER BY IsActive DESC, Name'
    },
    @{
        Name = 'user_login'
        Query = 'SELECT Id, UserId, IsFrozen, IsPasswordLocked, LastModifiedDate FROM UserLogin'
    },
    @{
        Name = 'profiles'
        Query = 'SELECT Id, Name, UserLicenseId, UserLicense.Name, UserType, Description, CreatedDate, LastModifiedDate FROM Profile ORDER BY Name'
    },
    @{
        Name = 'roles'
        Query = 'SELECT Id, Name, DeveloperName, ParentRoleId, ParentRole.Name, RollupDescription, OpportunityAccessForAccountOwner, CaseAccessForAccountOwner, ContactAccessForAccountOwner, PortalType, ForecastUserId, MayForecastManagerShare, LastModifiedDate FROM UserRole ORDER BY Name'
    },
    @{
        Name = 'permission_sets'
        Query = 'SELECT Id, Name, Label, Description, LicenseId, IsCustom, IsOwnedByProfile, ProfileId, Profile.Name, NamespacePrefix, Type, HasActivationRequired, PermissionSetGroupId, CreatedDate, LastModifiedDate FROM PermissionSet ORDER BY Label'
    },
    @{
        Name = 'permission_set_assignments'
        Query = 'SELECT Id, AssigneeId, Assignee.Username, Assignee.Name, Assignee.IsActive, PermissionSetId, PermissionSet.Name, PermissionSet.Label, PermissionSet.IsOwnedByProfile, PermissionSetGroupId, PermissionSetGroup.DeveloperName, PermissionSetGroup.MasterLabel, IsActive, ExpirationDate FROM PermissionSetAssignment'
    },
    @{
        Name = 'permission_set_groups'
        Query = 'SELECT Id, DeveloperName, MasterLabel, Description, Status, HasActivationRequired, NamespacePrefix, CreatedDate, LastModifiedDate FROM PermissionSetGroup ORDER BY MasterLabel'
    },
    @{
        Name = 'permission_set_group_components'
        Query = 'SELECT Id, PermissionSetGroupId, PermissionSetGroup.DeveloperName, PermissionSetGroup.MasterLabel, PermissionSetId, PermissionSet.Name, PermissionSet.Label, PermissionSet.Type, CreatedDate, LastModifiedDate FROM PermissionSetGroupComponent'
    },
    @{
        Name = 'permission_set_licenses'
        Query = 'SELECT Id, DeveloperName, MasterLabel, Status, TotalLicenses, UsedLicenses, PermissionSetLicenseKey, ExpirationDate, LicenseExpirationPolicy, IsSupplementLicense, IsAvailableForIntegrations, CreatedDate, LastModifiedDate FROM PermissionSetLicense ORDER BY MasterLabel'
    },
    @{
        Name = 'permission_set_license_assignments'
        Query = 'SELECT Id, AssigneeId, Assignee.Username, Assignee.Name, Assignee.IsActive, PermissionSetLicenseId, PermissionSetLicense.DeveloperName, PermissionSetLicense.MasterLabel, CreatedDate, LastModifiedDate FROM PermissionSetLicenseAssign'
    },
    @{
        Name = 'user_licenses'
        Query = 'SELECT Id, Name, MasterLabel, LicenseDefinitionKey, Status, TotalLicenses, UsedLicenses, UsedLicensesLastUpdated, CreatedDate, LastModifiedDate FROM UserLicense ORDER BY Name'
    },
    @{
        Name = 'groups'
        Query = 'SELECT Id, Name, DeveloperName, Description, Type, RelatedId, DoesIncludeBosses, DoesSendEmailToMembers, Email, OwnerId, CreatedDate, LastModifiedDate FROM Group ORDER BY Type, Name'
    },
    @{
        Name = 'group_members'
        Query = 'SELECT Id, GroupId, Group.Name, Group.DeveloperName, Group.Type, UserOrGroupId, SystemModstamp FROM GroupMember'
    },
    @{
        Name = 'queue_objects'
        Query = 'SELECT Id, QueueId, Queue.Name, SobjectType FROM QueueSobject ORDER BY Queue.Name, SobjectType'
    }
)

$manifest = @()
foreach ($export in $exports) {
    $outputFile = Join-Path $outputDirectory ($export.Name + '.csv')
    Write-Host ('Exporting ' + $export.Name + '...')
    & sf data query --target-org $targetOrg --query $export.Query --result-format csv --output-file $outputFile
    if ($LASTEXITCODE -ne 0) {
        throw ('Salesforce export failed for ' + $export.Name)
    }

    $rowCount = [Math]::Max(0, (Import-Csv -LiteralPath $outputFile).Count)
    $manifest += [PSCustomObject]@{
        Dataset = $export.Name
        Rows = $rowCount
        File = $outputFile
        Query = $export.Query
    }
}

$manifestPath = Join-Path $outputDirectory 'export_manifest.csv'
$manifest | Export-Csv -NoTypeInformation -LiteralPath $manifestPath
Write-Host ('Export complete: ' + $manifestPath)
