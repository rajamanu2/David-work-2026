$ErrorActionPreference = 'Continue'

$targetOrg = 'ProboMedical'
$exportDir = Join-Path $PSScriptRoot 'security_access_export'
$permissionSetsPath = Join-Path $exportDir 'permission_sets.csv'
$outputPath = Join-Path $exportDir 'tab_settings_complete.csv'
$permissionSetIds = @(Import-Csv -LiteralPath $permissionSetsPath | ForEach-Object { $_.Id } | Where-Object { $_ })
$chunkSize = 20
$allRows = [System.Collections.Generic.List[object]]::new()

for ($offset = 0; $offset -lt $permissionSetIds.Count; $offset += $chunkSize) {
    $end = [Math]::Min($offset + $chunkSize - 1, $permissionSetIds.Count - 1)
    $chunk = $permissionSetIds[$offset..$end]
    $quotedIds = ($chunk | ForEach-Object { "'$_'" }) -join ','
    $query = "SELECT Id, ParentId, Name, Visibility FROM PermissionSetTabSetting WHERE ParentId IN ($quotedIds)"
    $csvText = & sf data query --target-org $targetOrg --query $query --result-format csv 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Salesforce query failed for permission-set chunk beginning at index $offset."
    }
    if ($csvText -and $csvText.Count -gt 1) {
        foreach ($row in ($csvText | ConvertFrom-Csv)) {
            $allRows.Add($row)
        }
    }
    if (($offset / $chunkSize) % 5 -eq 0) {
        Write-Output "Processed $($end + 1) of $($permissionSetIds.Count) permission sets; collected $($allRows.Count) rows."
    }
}

$deduplicated = @($allRows | Sort-Object Id -Unique)
$deduplicated | Export-Csv -LiteralPath $outputPath -NoTypeInformation -Encoding utf8
Write-Output "Wrote $($deduplicated.Count) unique tab-setting rows to $outputPath"
