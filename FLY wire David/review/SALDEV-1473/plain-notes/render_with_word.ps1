$ErrorActionPreference = "Stop"

$docxPath = "C:\Users\LIKKI\Documents\ChatGPT\david\review\SALDEV-1473\SALDEV-1473_Plain_Implementation_Notes.docx"
$renderDir = "C:\Users\LIKKI\Documents\ChatGPT\david\review\SALDEV-1473\plain-notes\word-render-4"
$pdfPath = Join-Path $renderDir "SALDEV-1473_Plain_Implementation_Notes.pdf"

New-Item -ItemType Directory -Force -Path $renderDir | Out-Null

$word = $null
$document = $null
try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $document = $word.Documents.Open($docxPath, $false, $true)
    $document.ExportAsFixedFormat($pdfPath, 17)
}
finally {
    if ($null -ne $document) {
        $document.Close(0)
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($document)
    }
    if ($null -ne $word) {
        $word.Quit()
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($word)
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

Write-Output $pdfPath
