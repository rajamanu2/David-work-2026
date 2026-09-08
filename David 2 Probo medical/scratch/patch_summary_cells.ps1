$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression

$workbook = Join-Path $PSScriptRoot '..\outputs\security_access_review_2026-08-19\Pro_Biomedical_Detailed_User_Permission_Risk_Review_2026-08-19.xlsx'
$tempWorkbook = "$workbook.corrected"
Copy-Item -LiteralPath $workbook -Destination $tempWorkbook -Force

$zip = [System.IO.Compression.ZipFile]::Open($tempWorkbook, [System.IO.Compression.ZipArchiveMode]::Update)
$entry = $zip.GetEntry('xl/worksheets/sheet1.xml')
$reader = [System.IO.StreamReader]::new($entry.Open())
$xml = $reader.ReadToEnd()
$reader.Close()

$xml = [regex]::Replace($xml, '<x:c r="E13"[^>]*>.*?</x:c>', '<x:c r="E13" s="24" t="n"><x:f>21899</x:f><x:v>21899</x:v></x:c>')
$xml = [regex]::Replace($xml, '<x:c r="E14"[^>]*>.*?</x:c>', '<x:c r="E14" s="24" t="n"><x:f>455834</x:f><x:v>455834</x:v></x:c>')

$entry.Delete()
$newEntry = $zip.CreateEntry('xl/worksheets/sheet1.xml', [System.IO.Compression.CompressionLevel]::Optimal)
$writer = [System.IO.StreamWriter]::new($newEntry.Open(), [System.Text.UTF8Encoding]::new($false))
$writer.Write($xml)
$writer.Close()
$zip.Dispose()

Move-Item -LiteralPath $tempWorkbook -Destination $workbook -Force
Write-Output "Corrected Summary cells E13 and E14 in $workbook"
