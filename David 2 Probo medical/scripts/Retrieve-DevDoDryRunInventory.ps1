param(
    [Parameter(Mandatory = $true)][string]$TargetOrg,
    [Parameter(Mandatory = $true)][string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$results = [System.Collections.Generic.List[object]]::new()

function Export-InventoryQuery {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Query,
        [switch]$Tooling
    )

    $outputPath = Join-Path $OutputDirectory ($Name + '.json')
    $arguments = @('data', 'query', '--target-org', $TargetOrg, '--query', $Query, '--result-format', 'json', '--output-file', $outputPath)
    if ($Tooling) { $arguments += '--use-tooling-api' }
    $cliOutput = & sf @arguments 2>&1
    $exitCode = $LASTEXITCODE
    $recordCount = $null
    if ($exitCode -eq 0 -and (Test-Path -LiteralPath $outputPath)) {
        $payload = Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json
        $recordCount = @($payload.records).Count
    }
    $results.Add([pscustomobject]@{
        Name = $Name
        Tooling = [bool]$Tooling
        ExitCode = $exitCode
        RecordCount = $recordCount
        OutputPath = $outputPath
        Message = ($cliOutput -join "`n")
    })
}

Export-InventoryQuery -Name 'entity_definitions' -Query 'SELECT DurableId, QualifiedApiName, Label, PluralLabel, KeyPrefix, IsCustomizable FROM EntityDefinition ORDER BY Label'
Export-InventoryQuery -Name 'flow_definitions' -Query 'SELECT Id, DeveloperName, MasterLabel, ActiveVersionId, LatestVersionId FROM FlowDefinition ORDER BY DeveloperName' -Tooling
Export-InventoryQuery -Name 'validation_rules' -Query 'SELECT Id, ValidationName, Active, EntityDefinitionId, Description, ErrorMessage FROM ValidationRule ORDER BY ValidationName' -Tooling
Export-InventoryQuery -Name 'apex_triggers' -Query 'SELECT Id, Name, TableEnumOrId, Status, NamespacePrefix, ApiVersion FROM ApexTrigger ORDER BY Name' -Tooling
Export-InventoryQuery -Name 'apex_classes' -Query 'SELECT Id, Name, Status, NamespacePrefix, ApiVersion FROM ApexClass ORDER BY Name' -Tooling
Export-InventoryQuery -Name 'lwc_bundles' -Query 'SELECT Id, DeveloperName, MasterLabel, NamespacePrefix, ApiVersion FROM LightningComponentBundle ORDER BY DeveloperName' -Tooling
Export-InventoryQuery -Name 'aura_bundles' -Query 'SELECT Id, DeveloperName, MasterLabel, NamespacePrefix, ApiVersion FROM AuraDefinitionBundle ORDER BY DeveloperName' -Tooling
Export-InventoryQuery -Name 'permission_sets' -Query 'SELECT Id, Name, Label, IsOwnedByProfile, Profile.Name, NamespacePrefix FROM PermissionSet ORDER BY Label'
Export-InventoryQuery -Name 'email_templates' -Query 'SELECT Id, Name, DeveloperName, FolderId, TemplateType, IsActive, Subject FROM EmailTemplate ORDER BY Name'
Export-InventoryQuery -Name 'reports' -Query 'SELECT Id, Name, DeveloperName, FolderName, Format, LastRunDate FROM Report ORDER BY Name'
Export-InventoryQuery -Name 'dashboards' -Query 'SELECT Id, Title, DeveloperName, FolderName, LastViewedDate FROM Dashboard ORDER BY Title'

$results | ConvertTo-Json -Depth 5
