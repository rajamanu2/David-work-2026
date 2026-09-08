param(
    [Parameter(Mandatory = $true)][string]$TargetOrg,
    [Parameter(Mandatory = $true)][string]$CaseExportPath,
    [Parameter(Mandatory = $true)][string]$ContentLinksPath,
    [Parameter(Mandatory = $true)][string]$ContentVersionsPath,
    [Parameter(Mandatory = $true)][string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$cases = Get-Content -LiteralPath $CaseExportPath -Raw | ConvertFrom-Json
$links = Get-Content -LiteralPath $ContentLinksPath -Raw | ConvertFrom-Json
$versions = Get-Content -LiteralPath $ContentVersionsPath -Raw | ConvertFrom-Json

$caseNumbers = @{}
$cases.records | ForEach-Object { $caseNumbers[[string]$_.Id] = [string]$_.CaseNumber }
$versionMap = @{}
$versions.records | ForEach-Object { $versionMap[[string]$_.Id] = $_ }

$results = [System.Collections.Generic.List[object]]::new()
foreach ($link in $links.records) {
    $versionId = [string]$link.ContentDocument.LatestPublishedVersionId
    $version = $versionMap[$versionId]
    if (-not $version) { continue }

    $caseNumber = $caseNumbers[[string]$link.LinkedEntityId]
    $safeTitle = ([string]$version.Title -replace '[^a-zA-Z0-9._-]+', '_').Trim('_')
    if ([string]::IsNullOrWhiteSpace($safeTitle)) { $safeTitle = $versionId }
    $extension = ([string]$version.FileExtension).Trim('.').ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($extension)) { $extension = 'bin' }
    $fileName = "${caseNumber}_${safeTitle}_${versionId}.${extension}"
    $outputPath = Join-Path $OutputDirectory $fileName
    $endpoint = "/services/data/v67.0/sobjects/ContentVersion/$versionId/VersionData"

    $cliOutput = & sf api request rest $endpoint --target-org $TargetOrg --stream-to-file $outputPath 2>&1
    $results.Add([pscustomobject]@{
        CaseNumber = $caseNumber
        VersionId = $versionId
        File = $outputPath
        ExitCode = $LASTEXITCODE
        Message = ($cliOutput -join "`n")
    })
}

$results | ConvertTo-Json -Depth 4
