param(
    [Parameter(Mandatory = $true)][string]$TargetOrg,
    [Parameter(Mandatory = $true)][string]$OutputDirectory,
    [Parameter(Mandatory = $true)][string[]]$Objects
)

$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$results = [System.Collections.Generic.List[object]]::new()

foreach ($objectName in $Objects) {
    if ($objectName -notmatch '^[a-zA-Z0-9_]+$') { throw "Unsafe object API name: $objectName" }
    $query = "SELECT DurableId, EntityDefinition.QualifiedApiName, QualifiedApiName, Label, DataType, IsCalculated FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = '$objectName' LIMIT 2000"
    $safeName = $objectName.ToLowerInvariant()
    $outputPath = Join-Path $OutputDirectory ("field_definitions_{0}.json" -f $safeName)
    $cliOutput = & sf data query --target-org $TargetOrg --query $query --result-format json --output-file $outputPath 2>&1
    $count = $null
    if ($LASTEXITCODE -eq 0) {
        $payload = Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json
        $count = @($payload.records).Count
    }
    $results.Add([pscustomobject]@{ Object = $objectName; ExitCode = $LASTEXITCODE; RecordCount = $count; OutputPath = $outputPath; Message = ($cliOutput -join "`n") })
}

$results | ConvertTo-Json -Depth 4
