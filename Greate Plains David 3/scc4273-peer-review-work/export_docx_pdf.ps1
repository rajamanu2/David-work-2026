param(
    [Parameter(Mandatory = $true)][string]$DocxPath,
    [Parameter(Mandatory = $true)][string]$PdfPath
)

$ErrorActionPreference = 'Stop'
$docx = (Resolve-Path -LiteralPath $DocxPath).Path
$pdf = [System.IO.Path]::GetFullPath($PdfPath)
$pdfDir = Split-Path -Parent $pdf
New-Item -ItemType Directory -Force -Path $pdfDir | Out-Null

$word = $null
$document = $null
try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $document = $word.Documents.Open($docx, $false, $true)
    $document.ExportAsFixedFormat($pdf, 17)
    Write-Output $pdf
}
finally {
    if ($null -ne $document) {
        $document.Close(0)
    }
    if ($null -ne $word) {
        $word.Quit()
    }
}
