$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$exportDir = Join-Path $PSScriptRoot 'security_access_export'
$workbook = Join-Path $PSScriptRoot '..\outputs\user_permission_set_mapping_2026-08-20\Pro_Biomedical_User_Permission_Set_Mapping_2026-08-20.xlsx'
$tempWorkbook = "$workbook.streaming"
$assignments = @(Import-Csv -LiteralPath (Join-Path $exportDir 'permission_set_assignments.csv'))
$users = @(Import-Csv -LiteralPath (Join-Path $exportDir 'users.csv'))
$permissionSets = @(Import-Csv -LiteralPath (Join-Path $exportDir 'permission_sets.csv'))

if (Test-Path -LiteralPath $tempWorkbook) { Remove-Item -LiteralPath $tempWorkbook -Force }
Copy-Item -LiteralPath $workbook -Destination $tempWorkbook -Force

$userCounts = @{}
$psCounts = @{}
$rowXml = [System.Text.StringBuilder]::new(16000000)
$columns = @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O')

function Add-Count([hashtable]$map, [string]$key, [string]$field) {
    if (-not $map.ContainsKey($key)) { $map[$key] = @{ Total = 0; Direct = 0; Group = 0; Profile = 0; Active = 0 } }
    $map[$key][$field]++
}

function Escape-Xml([string]$value) {
    if ($null -eq $value) { return '' }
    return [System.Security.SecurityElement]::Escape($value)
}

for ($index = 0; $index -lt $assignments.Count; $index++) {
    $record = $assignments[$index]
    $excelRow = $index + 2
    if ($record.'PermissionSet.IsOwnedByProfile' -eq 'true') { $type = 'Profile Backing Permission Set' }
    elseif ($record.PermissionSetGroupId) { $type = 'Permission Set Group' }
    else { $type = 'Direct Permission Set' }

    Add-Count $userCounts $record.AssigneeId 'Total'
    if ($type -eq 'Direct Permission Set') { Add-Count $userCounts $record.AssigneeId 'Direct' }
    elseif ($type -eq 'Permission Set Group') { Add-Count $userCounts $record.AssigneeId 'Group' }

    Add-Count $psCounts $record.PermissionSetId 'Total'
    if ($record.'Assignee.IsActive' -eq 'true') { Add-Count $psCounts $record.PermissionSetId 'Active' }
    if ($type -eq 'Direct Permission Set') { Add-Count $psCounts $record.PermissionSetId 'Direct' }
    elseif ($type -eq 'Permission Set Group') { Add-Count $psCounts $record.PermissionSetId 'Group' }
    else { Add-Count $psCounts $record.PermissionSetId 'Profile' }

    $values = @(
        $record.Id, $type, $record.AssigneeId, $record.'Assignee.Username', $record.'Assignee.Name',
        $record.'Assignee.IsActive', $record.PermissionSetId, $record.'PermissionSet.Name', $record.'PermissionSet.Label',
        $record.'PermissionSet.IsOwnedByProfile', $record.PermissionSetGroupId,
        $record.'PermissionSetGroup.DeveloperName', $record.'PermissionSetGroup.MasterLabel',
        $record.IsActive, $record.ExpirationDate
    )
    [void]$rowXml.Append(('<x:row r="{0}">' -f $excelRow))
    for ($columnIndex = 0; $columnIndex -lt $values.Count; $columnIndex++) {
        $value = [string]$values[$columnIndex]
        if (-not $value) { continue }
        $cell = "$($columns[$columnIndex])$excelRow"
        if ($columnIndex -in @(5,9,13)) {
            $booleanValue = if ($value -eq 'true') { '1' } else { '0' }
            [void]$rowXml.Append(('<x:c r="{0}" t="b"><x:v>{1}</x:v></x:c>' -f $cell, $booleanValue))
        } else {
            [void]$rowXml.Append(('<x:c r="{0}" t="str"><x:v>{1}</x:v></x:c>' -f $cell, (Escape-Xml $value)))
        }
    }
    [void]$rowXml.Append('</x:row>')
}

function Read-ZipEntry([System.IO.Compression.ZipArchive]$zip, [string]$name) {
    $entry = $zip.GetEntry($name)
    $reader = [System.IO.StreamReader]::new($entry.Open())
    $text = $reader.ReadToEnd()
    $reader.Close()
    return $text
}

function Replace-ZipEntry([System.IO.Compression.ZipArchive]$zip, [string]$name, [string]$text) {
    $oldEntry = $zip.GetEntry($name)
    $oldEntry.Delete()
    $newEntry = $zip.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal)
    $writer = [System.IO.StreamWriter]::new($newEntry.Open(), [System.Text.UTF8Encoding]::new($false))
    $writer.Write($text)
    $writer.Close()
}

function Set-CachedValue([string]$xml, [string]$cell, [int]$value) {
    $pattern = '(<x:c r="' + [regex]::Escape($cell) + '"[^>]*>.*?<x:v>)[^<]*(</x:v>.*?</x:c>)'
    return [regex]::Replace($xml, $pattern, { param($match) $match.Groups[1].Value + $value + $match.Groups[2].Value }, [System.Text.RegularExpressions.RegexOptions]::Singleline)
}

$zip = [System.IO.Compression.ZipFile]::Open($tempWorkbook, [System.IO.Compression.ZipArchiveMode]::Update)

$mappingXml = Read-ZipEntry $zip 'xl/worksheets/sheet2.xml'
$headerMatch = [regex]::Match($mappingXml, '<x:row r="1".*?</x:row>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $headerMatch.Success) { throw 'Could not locate the User Permission Sets header row.' }
$sheetData = "<x:sheetData>$($headerMatch.Value)$($rowXml.ToString())</x:sheetData>"
$mappingXml = [regex]::Replace($mappingXml, '<x:sheetData>.*?</x:sheetData>', $sheetData, [System.Text.RegularExpressions.RegexOptions]::Singleline)
$mappingXml = [regex]::Replace($mappingXml, '<x:dimension ref="[^"]*"\s*/>', ('<x:dimension ref="A1:O{0}"/>' -f ($assignments.Count + 1)))
$mappingXml = $mappingXml.Replace('</x:sheetData>', ('</x:sheetData><x:autoFilter ref="A1:O{0}"/>' -f ($assignments.Count + 1)))
Replace-ZipEntry $zip 'xl/worksheets/sheet2.xml' $mappingXml

$usersXml = Read-ZipEntry $zip 'xl/worksheets/sheet1.xml'
for ($index = 0; $index -lt $users.Count; $index++) {
    $excelRow = $index + 2
    $counts = if ($userCounts.ContainsKey($users[$index].Id)) { $userCounts[$users[$index].Id] } else { @{ Total = 0; Direct = 0; Group = 0 } }
    $usersXml = Set-CachedValue $usersXml "Y$excelRow" $counts.Direct
    $usersXml = Set-CachedValue $usersXml "AA$excelRow" $counts.Group
    $usersXml = Set-CachedValue $usersXml "AD$excelRow" $counts.Total
}
$usersXml = $usersXml.Replace('</x:sheetData>', ('</x:sheetData><x:autoFilter ref="A1:AE{0}"/>' -f ($users.Count + 1)))
Replace-ZipEntry $zip 'xl/worksheets/sheet1.xml' $usersXml

$detailsXml = Read-ZipEntry $zip 'xl/worksheets/sheet3.xml'
for ($index = 0; $index -lt $permissionSets.Count; $index++) {
    $excelRow = $index + 2
    $counts = if ($psCounts.ContainsKey($permissionSets[$index].Id)) { $psCounts[$permissionSets[$index].Id] } else { @{ Total = 0; Active = 0; Direct = 0; Group = 0; Profile = 0 } }
    $detailsXml = Set-CachedValue $detailsXml "L$excelRow" $counts.Total
    $detailsXml = Set-CachedValue $detailsXml "M$excelRow" $counts.Active
    $detailsXml = Set-CachedValue $detailsXml "N$excelRow" $counts.Direct
    $detailsXml = Set-CachedValue $detailsXml "O$excelRow" $counts.Group
    $detailsXml = Set-CachedValue $detailsXml "P$excelRow" $counts.Profile
}
$detailsXml = $detailsXml.Replace('</x:sheetData>', ('</x:sheetData><x:autoFilter ref="A1:AF{0}"/>' -f ($permissionSets.Count + 1)))
Replace-ZipEntry $zip 'xl/worksheets/sheet3.xml' $detailsXml

$workbookXml = Read-ZipEntry $zip 'xl/workbook.xml'
if ($workbookXml -match '<x:calcPr[^>]*/>') {
    $workbookXml = [regex]::Replace($workbookXml, '<x:calcPr[^>]*/>', '<x:calcPr calcMode="auto" fullCalcOnLoad="1" forceFullCalc="1"/>')
} else {
    $workbookXml = $workbookXml.Replace('</x:workbook>', '<x:calcPr calcMode="auto" fullCalcOnLoad="1" forceFullCalc="1"/></x:workbook>')
}
Replace-ZipEntry $zip 'xl/workbook.xml' $workbookXml
$zip.Dispose()

Move-Item -LiteralPath $tempWorkbook -Destination $workbook -Force
Write-Output "Injected $($assignments.Count) user-permission mapping rows into $workbook"
