param(
    [string]$TargetOrg = "FlywirePartial",
    [string]$ManifestDirectory = "manifest/chunks",
    [int]$WaitMinutes = 60
)

$results = @()
$manifests = Get-ChildItem -LiteralPath $ManifestDirectory -Filter "package-*.xml" | Sort-Object Name

foreach ($manifest in $manifests) {
    Write-Output ("Retrieving {0}..." -f $manifest.Name)
    $stderrPath = Join-Path $env:TEMP ("sf-retrieve-{0}.stderr" -f $manifest.BaseName)
    $raw = & sf project retrieve start --manifest $manifest.FullName --target-org $TargetOrg --api-version 67.0 --wait $WaitMinutes --json 2> $stderrPath
    $exitCode = $LASTEXITCODE

    try {
        $response = ($raw -join [Environment]::NewLine) | ConvertFrom-Json
        $result = [pscustomobject]@{
            Manifest = $manifest.Name
            ExitCode = $exitCode
            JobId = $response.result.id
            Status = $response.result.status
            Success = $response.result.success
            Files = @($response.result.files).Count
            ErrorStatusCode = $response.result.errorStatusCode
            ErrorMessage = $response.result.errorMessage
        }
    }
    catch {
        $result = [pscustomobject]@{
            Manifest = $manifest.Name
            ExitCode = $exitCode
            JobId = $null
            Status = "UnparseableResponse"
            Success = $false
            Files = 0
            ErrorStatusCode = $null
            ErrorMessage = ($raw -join [Environment]::NewLine)
        }
    }

    $results += $result
    $result | Format-Table -AutoSize | Out-String | Write-Output
}

$results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "manifest/retrieve-results.json" -Encoding UTF8
$results | Format-Table Manifest, JobId, Status, Success, Files, ErrorStatusCode -AutoSize

if (@($results | Where-Object { -not $_.Success }).Count -gt 0) {
    exit 1
}
