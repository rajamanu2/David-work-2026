$ErrorActionPreference = 'Stop'
$docx = 'C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\SCC-3386-architect-review.docx'
$qaDir = 'C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\scc3386-docx-qa'
$pdf = Join-Path $qaDir 'SCC-3386-architect-review.pdf'
New-Item -ItemType Directory -Path $qaDir -Force | Out-Null

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
