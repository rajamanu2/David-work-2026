$ErrorActionPreference = 'Stop'

$taskRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$outputRoot = Join-Path $taskRoot 'outputs\next_four_architect_reviews_2026-09-01'
$caseIds = @('00009998', '00010158', '00009589', '00010514')

$wordApp = New-Object -ComObject Word.Application
$wordApp.Visible = $false
$wordApp.DisplayAlerts = 0
$wordApp.AutomationSecurity = 3
$wordApp.Options.ConfirmConversions = $false
$wordApp.Options.SaveNormalPrompt = $false

try {
    foreach ($caseId in $caseIds) {
        $docxPath = Join-Path $outputRoot "Case_${caseId}_Architect_Review.docx"
        $renderDir = Join-Path $outputRoot "render_${caseId}"
        if (-not (Test-Path -LiteralPath $renderDir)) {
            New-Item -ItemType Directory -Path $renderDir | Out-Null
        }
        $pdfPath = Join-Path $renderDir "Case_${caseId}_Architect_Review.pdf"
        $wordDoc = $wordApp.Documents.Open(
            $docxPath,
            $false,
            $true,
            $false,
            '',
            '',
            $false,
            '',
            '',
            0,
            0,
            $false,
            $true,
            0,
            $true
        )
        try {
            $wordDoc.ExportAsFixedFormat($pdfPath, 17)
            Write-Output $pdfPath
        }
        finally {
            $wordDoc.Close($false)
        }
    }
}
finally {
    $wordApp.Quit()
    [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($wordApp) | Out-Null
}
