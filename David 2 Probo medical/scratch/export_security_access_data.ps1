$ErrorActionPreference = 'Stop'

$targetOrg = 'ProboMedical'
$outputDirectory = Join-Path $PSScriptRoot 'security_access_export'
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

function Invoke-SfQuery {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Query
    )
    $outputFile = Join-Path $outputDirectory ($Name + '.csv')
    Write-Host ('Exporting ' + $Name + '...')
    & sf data query --target-org $targetOrg --query $Query --result-format csv --output-file $outputFile
    if ($LASTEXITCODE -ne 0) {
        throw ('Salesforce query failed for ' + $Name)
    }
}

function Invoke-SfOptionalQuery {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Query
    )
    $outputFile = Join-Path $outputDirectory ($Name + '.csv')
    Write-Host ('Exporting optional dataset ' + $Name + '...')
    & sf data query --target-org $targetOrg --query $Query --result-format csv --output-file $outputFile
    if ($LASTEXITCODE -ne 0) {
        Write-Warning ('Optional Salesforce query unavailable: ' + $Name)
        Remove-Item -LiteralPath $outputFile -ErrorAction SilentlyContinue
    }
}

function Invoke-SfBulkQuery {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Query
    )
    $outputFile = Join-Path $outputDirectory ($Name + '.csv')
    Write-Host ('Bulk exporting ' + $Name + '...')
    & sf data export bulk --target-org $targetOrg --query $Query --result-format csv --output-file $outputFile --wait 60 --line-ending CRLF
    if ($LASTEXITCODE -ne 0) {
        throw ('Salesforce bulk export failed for ' + $Name)
    }
}

Invoke-SfQuery -Name 'organization' -Query 'SELECT Id, Name, IsSandbox, OrganizationType, InstanceName FROM Organization'
Invoke-SfQuery -Name 'users' -Query 'SELECT Id, Username, Name, FirstName, LastName, Email, Alias, IsActive, UserType, ProfileId, Profile.Name, Profile.UserLicenseId, Profile.UserLicense.Name, UserRoleId, UserRole.Name, ManagerId, Manager.Name, Department, Division, Title, CompanyName, TimeZoneSidKey, FederationIdentifier, CreatedDate, LastLoginDate, LastModifiedDate FROM User ORDER BY IsActive DESC, Name'
Invoke-SfQuery -Name 'user_login' -Query 'SELECT Id, UserId, IsFrozen, IsPasswordLocked, LastModifiedDate FROM UserLogin'
Invoke-SfQuery -Name 'profiles' -Query 'SELECT Id, Name, UserLicenseId, UserLicense.Name, UserType, Description, CreatedDate, LastModifiedDate FROM Profile ORDER BY Name'
Invoke-SfQuery -Name 'roles' -Query 'SELECT Id, Name, DeveloperName, ParentRoleId, ParentRole.Name, RollupDescription, OpportunityAccessForAccountOwner, CaseAccessForAccountOwner, ContactAccessForAccountOwner, PortalType, ForecastUserId, MayForecastManagerShare, LastModifiedDate FROM UserRole ORDER BY Name'
Invoke-SfQuery -Name 'permission_sets' -Query 'SELECT Id, Name, Label, Description, LicenseId, IsCustom, IsOwnedByProfile, ProfileId, Profile.Name, NamespacePrefix, Type, HasActivationRequired, PermissionSetGroupId, CreatedDate, LastModifiedDate FROM PermissionSet ORDER BY Label'
Invoke-SfQuery -Name 'permission_set_assignments' -Query 'SELECT Id, AssigneeId, Assignee.Username, Assignee.Name, Assignee.IsActive, PermissionSetId, PermissionSet.Name, PermissionSet.Label, PermissionSet.IsOwnedByProfile, PermissionSetGroupId, PermissionSetGroup.DeveloperName, PermissionSetGroup.MasterLabel, IsActive, ExpirationDate FROM PermissionSetAssignment'
Invoke-SfQuery -Name 'permission_set_groups' -Query 'SELECT Id, DeveloperName, MasterLabel, Description, Status, HasActivationRequired, NamespacePrefix, CreatedDate, LastModifiedDate FROM PermissionSetGroup ORDER BY MasterLabel'
Invoke-SfQuery -Name 'permission_set_group_components' -Query 'SELECT Id, PermissionSetGroupId, PermissionSetGroup.DeveloperName, PermissionSetGroup.MasterLabel, PermissionSetId, PermissionSet.Name, PermissionSet.Label, PermissionSet.Type, CreatedDate, LastModifiedDate FROM PermissionSetGroupComponent'

$describeText = (& sf sobject describe --sobject PermissionSet --target-org $targetOrg --json | Out-String)
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to describe PermissionSet for system permission extraction.'
}
$describe = $describeText | ConvertFrom-Json
$systemPermissionFields = @(
    $describe.result.fields |
        Where-Object { $_.name -like 'Permissions*' -and $_.type -eq 'boolean' } |
        Sort-Object name |
        ForEach-Object { $_.name }
)

$fieldListPath = Join-Path $outputDirectory 'system_permission_fields.csv'
$systemPermissionFields | ForEach-Object { [PSCustomObject]@{ Field = $_ } } | Export-Csv -NoTypeInformation -LiteralPath $fieldListPath

$chunkSize = 80
for ($offset = 0; $offset -lt $systemPermissionFields.Count; $offset += $chunkSize) {
    $lastIndex = [Math]::Min($offset + $chunkSize - 1, $systemPermissionFields.Count - 1)
    $chunk = $systemPermissionFields[$offset..$lastIndex]
    $chunkNumber = [Math]::Floor($offset / $chunkSize) + 1
    $chunkName = 'system_permissions_' + $chunkNumber.ToString('00')
    $query = 'SELECT Id, Name, Label, IsOwnedByProfile, ' + ($chunk -join ', ') + ' FROM PermissionSet'
    Invoke-SfQuery -Name $chunkName -Query $query
}

Invoke-SfBulkQuery -Name 'object_permissions' -Query 'SELECT Id, ParentId, SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords FROM ObjectPermissions'
Invoke-SfBulkQuery -Name 'field_permissions' -Query 'SELECT Id, ParentId, SobjectType, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions'
Invoke-SfBulkQuery -Name 'setup_entity_access' -Query 'SELECT Id, ParentId, SetupEntityId, SetupEntityType FROM SetupEntityAccess'
Invoke-SfBulkQuery -Name 'tab_settings' -Query 'SELECT Id, ParentId, Name, Visibility FROM PermissionSetTabSetting'

Invoke-SfOptionalQuery -Name 'apex_classes' -Query 'SELECT Id, Name, NamespacePrefix, Status FROM ApexClass'
Invoke-SfOptionalQuery -Name 'apex_pages' -Query 'SELECT Id, Name, NamespacePrefix FROM ApexPage'
Invoke-SfOptionalQuery -Name 'custom_permissions' -Query 'SELECT Id, DeveloperName, MasterLabel, NamespacePrefix FROM CustomPermission'
Invoke-SfOptionalQuery -Name 'flow_definitions' -Query 'SELECT Id, DeveloperName, MasterLabel, ActiveVersionId FROM FlowDefinition'
Invoke-SfOptionalQuery -Name 'connected_applications' -Query 'SELECT Id, Name FROM ConnectedApplication'
Invoke-SfOptionalQuery -Name 'entity_definitions' -Query 'SELECT DurableId, QualifiedApiName, Label FROM EntityDefinition'
Invoke-SfOptionalQuery -Name 'app_definitions' -Query 'SELECT DurableId, DeveloperName, Label FROM AppDefinition'

$manifest = Get-ChildItem -LiteralPath $outputDirectory -Filter '*.csv' |
    Where-Object { $_.Name -ne 'export_manifest.csv' } |
    Sort-Object Name |
    ForEach-Object {
        $rows = (Import-Csv -LiteralPath $_.FullName).Count
        [PSCustomObject]@{
            Dataset = [IO.Path]::GetFileNameWithoutExtension($_.Name)
            Rows = $rows
            File = $_.FullName
        }
    }
$manifest | Export-Csv -NoTypeInformation -LiteralPath (Join-Path $outputDirectory 'export_manifest.csv')
Write-Host ('Security access export complete: ' + $outputDirectory)
