$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$exportDir = Join-Path $PSScriptRoot 'security_access_export'
$workbook = Join-Path $PSScriptRoot '..\outputs\user_permission_set_mapping_2026-08-20\Pro_Biomedical_User_Permission_Set_Mapping_2026-08-20.xlsx'
$tempWorkbook = "$workbook.streaming"
$assignments = @(Import-Csv -LiteralPath (Join-Path $exportDir 'permission_set_assignments.csv'))
$userRows = @(Import-Csv -LiteralPath (Join-Path $exportDir 'user_mapping_users_rows.csv'))
$detailRows = @(Import-Csv -LiteralPath (Join-Path $exportDir 'permission_set_detail_rows.csv'))
$assignmentEnd = $assignments.Count + 1

if (Test-Path -LiteralPath $tempWorkbook) { Remove-Item -LiteralPath $tempWorkbook -Force }
Copy-Item -LiteralPath $workbook -Destination $tempWorkbook -Force

$userCounts = @{}
$psCounts = @{}
function Ensure-Counts([hashtable]$map, [string]$key) {
    if (-not $map.ContainsKey($key)) { $map[$key] = @{ Total = 0; Direct = 0; Group = 0; Profile = 0; Active = 0 } }
}

foreach ($record in $assignments) {
    if ($record.'PermissionSet.IsOwnedByProfile' -eq 'true') { $type = 'Profile Backing Permission Set' }
    elseif ($record.PermissionSetGroupId) { $type = 'Permission Set Group' }
    else { $type = 'Direct Permission Set' }

    Ensure-Counts $userCounts $record.AssigneeId
    $userCounts[$record.AssigneeId].Total++
    if ($type -eq 'Direct Permission Set') { $userCounts[$record.AssigneeId].Direct++ }
    elseif ($type -eq 'Permission Set Group') { $userCounts[$record.AssigneeId].Group++ }

    Ensure-Counts $psCounts $record.PermissionSetId
    $psCounts[$record.PermissionSetId].Total++
    if ($record.'Assignee.IsActive' -eq 'true') { $psCounts[$record.PermissionSetId].Active++ }
    if ($type -eq 'Direct Permission Set') { $psCounts[$record.PermissionSetId].Direct++ }
    elseif ($type -eq 'Permission Set Group') { $psCounts[$record.PermissionSetId].Group++ }
    else { $psCounts[$record.PermissionSetId].Profile++ }
}

function Escape-Xml([string]$value) {
    if ($null -eq $value) { return '' }
    return [System.Security.SecurityElement]::Escape($value)
}

function Add-TextCell([System.Text.StringBuilder]$builder, [string]$cell, [string]$value) {
    if (-not $value) { return }
    [void]$builder.Append(('<x:c r="{0}" t="str"><x:v>{1}</x:v></x:c>' -f $cell, (Escape-Xml $value)))
}

function Add-BooleanCell([System.Text.StringBuilder]$builder, [string]$cell, [string]$value) {
    if (-not $value) { return }
    $numeric = if ($value -eq 'true') { '1' } else { '0' }
    [void]$builder.Append(('<x:c r="{0}" t="b"><x:v>{1}</x:v></x:c>' -f $cell, $numeric))
}

function Add-FormulaCell([System.Text.StringBuilder]$builder, [string]$cell, [string]$formula, [int]$cachedValue) {
    [void]$builder.Append(('<x:c r="{0}" t="n"><x:f>{1}</x:f><x:v>{2}</x:v></x:c>' -f $cell, (Escape-Xml $formula), $cachedValue))
}

$assignmentXml = [System.Text.StringBuilder]::new(16000000)
$assignmentColumns = @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O')
for ($index = 0; $index -lt $assignments.Count; $index++) {
    $record = $assignments[$index]
    $excelRow = $index + 2
    if ($record.'PermissionSet.IsOwnedByProfile' -eq 'true') { $type = 'Profile Backing Permission Set' }
    elseif ($record.PermissionSetGroupId) { $type = 'Permission Set Group' }
    else { $type = 'Direct Permission Set' }
    $values = @(
        $record.Id, $type, $record.AssigneeId, $record.'Assignee.Username', $record.'Assignee.Name',
        $record.'Assignee.IsActive', $record.PermissionSetId, $record.'PermissionSet.Name', $record.'PermissionSet.Label',
        $record.'PermissionSet.IsOwnedByProfile', $record.PermissionSetGroupId,
        $record.'PermissionSetGroup.DeveloperName', $record.'PermissionSetGroup.MasterLabel',
        $record.IsActive, $record.ExpirationDate
    )
    [void]$assignmentXml.Append(('<x:row r="{0}">' -f $excelRow))
    for ($columnIndex = 0; $columnIndex -lt $values.Count; $columnIndex++) {
        $cell = "$($assignmentColumns[$columnIndex])$excelRow"
        if ($columnIndex -in @(5,9,13)) { Add-BooleanCell $assignmentXml $cell ([string]$values[$columnIndex]) }
        else { Add-TextCell $assignmentXml $cell ([string]$values[$columnIndex]) }
    }
    [void]$assignmentXml.Append('</x:row>')
}

$usersXmlRows = [System.Text.StringBuilder]::new(4000000)
$userColumns = @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AC','AD','AE')
for ($index = 0; $index -lt $userRows.Count; $index++) {
    $row = $userRows[$index]
    $excelRow = $index + 2
    $counts = if ($userCounts.ContainsKey($row.C1)) { $userCounts[$row.C1] } else { @{ Total = 0; Direct = 0; Group = 0 } }
    [void]$usersXmlRows.Append(('<x:row r="{0}">' -f $excelRow))
    for ($columnIndex = 0; $columnIndex -lt $userColumns.Count; $columnIndex++) {
        $cell = "$($userColumns[$columnIndex])$excelRow"
        if ($columnIndex -eq 24) {
            Add-FormulaCell $usersXmlRows $cell ("COUNTIFS('User Permission Sets'!`$C`$2:`$C`$$assignmentEnd,A$excelRow,'User Permission Sets'!`$B`$2:`$B`$$assignmentEnd,`"Direct Permission Set`")") $counts.Direct
        } elseif ($columnIndex -eq 26) {
            Add-FormulaCell $usersXmlRows $cell ("COUNTIFS('User Permission Sets'!`$C`$2:`$C`$$assignmentEnd,A$excelRow,'User Permission Sets'!`$B`$2:`$B`$$assignmentEnd,`"Permission Set Group`")") $counts.Group
        } elseif ($columnIndex -eq 29) {
            Add-FormulaCell $usersXmlRows $cell ("COUNTIF('User Permission Sets'!`$C`$2:`$C`$$assignmentEnd,A$excelRow)") $counts.Total
        } elseif ($columnIndex -in @(4,22,23)) {
            Add-BooleanCell $usersXmlRows $cell ([string]$row.("C$($columnIndex + 1)"))
        } else {
            Add-TextCell $usersXmlRows $cell ([string]$row.("C$($columnIndex + 1)"))
        }
    }
    [void]$usersXmlRows.Append('</x:row>')
}

$detailsXmlRows = [System.Text.StringBuilder]::new(5000000)
$detailColumns = @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AC','AD','AE','AF')
for ($index = 0; $index -lt $detailRows.Count; $index++) {
    $row = $detailRows[$index]
    $excelRow = $index + 2
    $counts = if ($psCounts.ContainsKey($row.C1)) { $psCounts[$row.C1] } else { @{ Total = 0; Active = 0; Direct = 0; Group = 0; Profile = 0 } }
    [void]$detailsXmlRows.Append(('<x:row r="{0}">' -f $excelRow))
    for ($columnIndex = 0; $columnIndex -lt $detailColumns.Count; $columnIndex++) {
        $cell = "$($detailColumns[$columnIndex])$excelRow"
        if ($columnIndex -eq 11) {
            Add-FormulaCell $detailsXmlRows $cell ("COUNTIF('User Permission Sets'!`$G`$2:`$G`$$assignmentEnd,A$excelRow)") $counts.Total
        } elseif ($columnIndex -eq 12) {
            Add-FormulaCell $detailsXmlRows $cell ("COUNTIFS('User Permission Sets'!`$G`$2:`$G`$$assignmentEnd,A$excelRow,'User Permission Sets'!`$F`$2:`$F`$$assignmentEnd,TRUE)") $counts.Active
        } elseif ($columnIndex -eq 13) {
            Add-FormulaCell $detailsXmlRows $cell ("COUNTIFS('User Permission Sets'!`$G`$2:`$G`$$assignmentEnd,A$excelRow,'User Permission Sets'!`$B`$2:`$B`$$assignmentEnd,`"Direct Permission Set`")") $counts.Direct
        } elseif ($columnIndex -eq 14) {
            Add-FormulaCell $detailsXmlRows $cell ("COUNTIFS('User Permission Sets'!`$G`$2:`$G`$$assignmentEnd,A$excelRow,'User Permission Sets'!`$B`$2:`$B`$$assignmentEnd,`"Permission Set Group`")") $counts.Group
        } elseif ($columnIndex -eq 15) {
            Add-FormulaCell $detailsXmlRows $cell ("COUNTIFS('User Permission Sets'!`$G`$2:`$G`$$assignmentEnd,A$excelRow,'User Permission Sets'!`$B`$2:`$B`$$assignmentEnd,`"Profile Backing Permission Set`")") $counts.Profile
        } elseif ($columnIndex -in @(4,7,10)) {
            Add-BooleanCell $detailsXmlRows $cell ([string]$row.("C$($columnIndex + 1)"))
        } else {
            Add-TextCell $detailsXmlRows $cell ([string]$row.("C$($columnIndex + 1)"))
        }
    }
    [void]$detailsXmlRows.Append('</x:row>')
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

function Replace-SheetData([string]$xml, [System.Text.StringBuilder]$rowBuilder, [string]$dimension, [string]$filterRange) {
    $header = [regex]::Match($xml, '<x:row r="1".*?</x:row>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if (-not $header.Success) { throw "Could not find header row for $dimension" }
    $sheetData = "<x:sheetData>$($header.Value)$($rowBuilder.ToString())</x:sheetData>"
    $xml = [regex]::Replace($xml, '<x:sheetData>.*?</x:sheetData>', $sheetData, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $xml = [regex]::Replace($xml, '<x:dimension ref="[^"]*"\s*/>', ('<x:dimension ref="{0}"/>' -f $dimension))
    $xml = $xml.Replace('</x:sheetData>', ('</x:sheetData><x:autoFilter ref="{0}"/>' -f $filterRange))
    return $xml
}

$zip = [System.IO.Compression.ZipFile]::Open($tempWorkbook, [System.IO.Compression.ZipArchiveMode]::Update)
$sheet1 = Replace-SheetData (Read-ZipEntry $zip 'xl/worksheets/sheet1.xml') $usersXmlRows ("A1:AE$($userRows.Count + 1)") ("A1:AE$($userRows.Count + 1)")
Replace-ZipEntry $zip 'xl/worksheets/sheet1.xml' $sheet1
$sheet2 = Replace-SheetData (Read-ZipEntry $zip 'xl/worksheets/sheet2.xml') $assignmentXml ("A1:O$($assignments.Count + 1)") ("A1:O$($assignments.Count + 1)")
Replace-ZipEntry $zip 'xl/worksheets/sheet2.xml' $sheet2
$sheet3 = Replace-SheetData (Read-ZipEntry $zip 'xl/worksheets/sheet3.xml') $detailsXmlRows ("A1:AF$($detailRows.Count + 1)") ("A1:AF$($detailRows.Count + 1)")
Replace-ZipEntry $zip 'xl/worksheets/sheet3.xml' $sheet3

$workbookXml = Read-ZipEntry $zip 'xl/workbook.xml'
if ($workbookXml -match '<x:calcPr[^>]*/>') {
    $workbookXml = [regex]::Replace($workbookXml, '<x:calcPr[^>]*/>', '<x:calcPr calcMode="auto" fullCalcOnLoad="1" forceFullCalc="1"/>')
} else {
    $workbookXml = $workbookXml.Replace('</x:workbook>', '<x:calcPr calcMode="auto" fullCalcOnLoad="1" forceFullCalc="1"/></x:workbook>')
}
Replace-ZipEntry $zip 'xl/workbook.xml' $workbookXml
$zip.Dispose()

Move-Item -LiteralPath $tempWorkbook -Destination $workbook -Force
Write-Output "Streamed $($userRows.Count) users, $($assignments.Count) mappings, and $($detailRows.Count) permission sets into $workbook"
