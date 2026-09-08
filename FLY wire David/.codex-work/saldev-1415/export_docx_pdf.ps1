param(
    [Parameter(Mandatory = $true)] [string] $InputDocx,
    [Parameter(Mandatory = $true)] [string] $OutputPdf
)

$inputPath = [System.IO.Path]::GetFullPath($InputDocx)
$outputPath = [System.IO.Path]::GetFullPath($OutputPdf)
$outputDir = [System.IO.Path]::GetDirectoryName($outputPath)
[System.IO.Directory]::CreateDirectory($outputDir) | Out-Null

$word = $null
$doc = $null
try {
    Write-Output "Starting Word"
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $word.Options.SaveNormalPrompt = $false
    Write-Output "Opening document"
    $doc = $word.Documents.OpenNoRepairDialog($inputPath, $false, $true, $false)
    Write-Output "Exporting PDF"
    $doc.ExportAsFixedFormat($outputPath, 17)
    Write-Output "Export complete"
}
finally {
    if ($null -ne $doc) {
        $doc.Close($false)
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc)
    }
    if ($null -ne $word) {
        $word.Quit()
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($word)
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

Get-Item -LiteralPath $outputPath | Select-Object FullName, Length
