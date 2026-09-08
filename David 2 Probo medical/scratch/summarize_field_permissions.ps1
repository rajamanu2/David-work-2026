$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot 'security_access_export\field_permissions_rest.csv'
$target = Join-Path $PSScriptRoot 'security_access_export\field_permission_summary.csv'
$summary = @{}

Import-Csv -LiteralPath $source | ForEach-Object {
    $key = "$($_.ParentId)|$($_.SobjectType)"
    if (-not $summary.ContainsKey($key)) {
        $summary[$key] = [ordered]@{ ParentId = $_.ParentId; SobjectType = $_.SobjectType; Total = 0; Readable = 0; Editable = 0 }
    }
    $summary[$key].Total++
    if ($_.PermissionsRead -eq 'true') { $summary[$key].Readable++ }
    if ($_.PermissionsEdit -eq 'true') { $summary[$key].Editable++ }
}

$rows = foreach ($item in $summary.Values) { [pscustomobject]$item }
$rows | Sort-Object ParentId, SobjectType | Export-Csv -LiteralPath $target -NoTypeInformation -Encoding utf8
Write-Output "Wrote $($rows.Count) field-access summary rows to $target"
