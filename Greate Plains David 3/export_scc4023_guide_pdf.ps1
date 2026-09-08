$ErrorActionPreference = 'Stop'
$docx = 'C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\SCC-4023-Development-Guide.docx'
$qaDir = 'C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\scc4023-development-guide-work\final-render-v3'
$pdf = Join-Path $qaDir 'SCC-4023-Development-Guide.pdf'
New-Item -ItemType Directory -Path $qaDir -Force | Out-Null

$word = $null
$document = $null
try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $document = $word.Documents.Open($docx, $false, $true)
    $document.Fields.Update() | Out-Null
    foreach ($section in $document.Sections) {
        foreach ($footer in $section.Footers) {
            $footer.Range.Fields.Update() | Out-Null
        }
    }
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
