param(
    [Parameter(Mandatory = $true)][string]$WorkbookScanPath,
    [Parameter(Mandatory = $true)][string]$CaseAnalysisPath,
    [Parameter(Mandatory = $true)][string]$RelatedDirectory,
    [Parameter(Mandatory = $true)][string]$OutputCsv,
    [Parameter(Mandatory = $true)][string]$OutputSummaryJson
)

$ErrorActionPreference = 'Stop'

$workbook = Get-Content -LiteralPath $WorkbookScanPath -Raw | ConvertFrom-Json
$casePayload = Get-Content -LiteralPath $CaseAnalysisPath -Raw | ConvertFrom-Json
$caseMap = @{}
$casePayload.records | ForEach-Object { $caseMap[[string]$_.CaseNumber] = $_ }

function Read-Records([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    $payload = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    return @($payload.records)
}

$history = Read-Records (Join-Path $RelatedDirectory 'case_history.json')
$feedItems = Read-Records (Join-Path $RelatedDirectory 'feed_items.json')
$feedComments = Read-Records (Join-Path $RelatedDirectory 'feed_comments.json')
$contentLinks = Read-Records (Join-Path $RelatedDirectory 'content_document_links.json')
$feedToCase = @{}
$feedItems | ForEach-Object { $feedToCase[[string]$_.Id] = [string]$_.ParentId }

$historyCounts = @{}
$history | Group-Object CaseId | ForEach-Object { $historyCounts[[string]$_.Name] = $_.Count }
$feedCounts = @{}
$feedItems | Group-Object ParentId | ForEach-Object { $feedCounts[[string]$_.Name] = $_.Count }
$feedCommentCounts = @{}
$feedComments | ForEach-Object {
    $caseId = $feedToCase[[string]$_.FeedItemId]
    if ($caseId) { $feedCommentCounts[$caseId] = 1 + [int]($feedCommentCounts[$caseId]) }
}
$fileCounts = @{}
$contentLinks | Group-Object LinkedEntityId | ForEach-Object { $fileCounts[[string]$_.Name] = $_.Count }

$indexRows = [System.Collections.Generic.List[object]]::new()
foreach ($sheet in $workbook) {
    foreach ($story in $sheet.caseRows) {
        $values = @($story.values)
        if ($sheet.sheet -eq 'Projects (Major and Minor)') {
            $workbookStatus = $values[7]
            $workType = $values[8]
            $workbookAssignedTo = $values[10]
        }
        elseif ($sheet.sheet -eq 'Errors & Just do its') {
            $workbookStatus = $values[5]
            $workType = $values[6]
            $workbookAssignedTo = $values[8]
        }
        else {
            $workbookStatus = $values[6]
            $workType = $values[7]
            $workbookAssignedTo = $values[9]
        }

        $caseNumbers = @([regex]::Matches([string]$story.caseNumber, '\d{4,8}') | ForEach-Object { $_.Value.PadLeft(8, '0') })
        foreach ($caseNumber in $caseNumbers) {
            $case = $caseMap[$caseNumber]
            $disposition = if (-not $case) {
                'Missing from production'
            }
            elseif ($sheet.sheet -eq 'Complete' -and $case.IsClosed) {
                'Exclude - complete in workbook and Salesforce'
            }
            elseif ($sheet.sheet -eq 'Complete') {
                'Review - workbook complete but Salesforce open'
            }
            elseif ($case.IsClosed) {
                'Review - active workbook row but Salesforce closed'
            }
            else {
                'Ready for case-level requirements analysis'
            }

            $indexRows.Add([pscustomobject]@{
                Sheet = $sheet.sheet
                WorkbookRow = [int]$story.rowNumber
                CaseNumber = $caseNumber
                WorkbookSummary = $values[0]
                WorkbookTheme = $values[1]
                WorkbookProductArea = $values[2]
                WorkbookStatus = $workbookStatus
                WorkTypeOrSize = $workType
                WorkbookAssignedTo = $workbookAssignedTo
                SalesforceCaseId = $case.Id
                SalesforceSubject = $case.Subject
                SalesforceStatus = $case.Status
                SalesforceIsClosed = $case.IsClosed
                SalesforcePriority = $case.Priority
                SalesforceClassification = $case.Classification__c
                SalesforceRelatedObject = $case.Related_Object__c
                SalesforceObjectOfIssue = $case.SFDC_Object_of_Issue__c
                SalesforceErrorType = $case.Error_Type__c
                SalesforceOwner = $case.Owner.Name
                SalesforceCreatedDate = $case.CreatedDate
                SalesforceLastModifiedDate = $case.LastModifiedDate
                SalesforceClosedDate = $case.ClosedDate
                SalesforceDescription = $case.Description
                SalesforceResolutionNotes = $case.Resolution_Notes__c
                SalesforceAssignedToId = $case.Assigned_To__c
                HistoryCount = [int]($historyCounts[[string]$case.Id])
                FeedItemCount = [int]($feedCounts[[string]$case.Id])
                FeedCommentCount = [int]($feedCommentCounts[[string]$case.Id])
                FileCount = [int]($fileCounts[[string]$case.Id])
                DryRunDisposition = $disposition
            })
        }
    }
}

$outputDirectory = Split-Path -Parent $OutputCsv
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$indexRows | Sort-Object CaseNumber | Export-Csv -LiteralPath $OutputCsv -NoTypeInformation -Encoding UTF8

$summary = [ordered]@{
    GeneratedAt = (Get-Date).ToString('o')
    WorkbookCaseReferences = $indexRows.Count
    ProductionMatches = @($indexRows | Where-Object SalesforceCaseId).Count
    MissingFromProduction = @($indexRows | Where-Object { -not $_.SalesforceCaseId }).Count
    OpenProductionCases = @($indexRows | Where-Object { $_.SalesforceCaseId -and -not $_.SalesforceIsClosed }).Count
    ClosedProductionCases = @($indexRows | Where-Object SalesforceIsClosed).Count
    WorkbookCompleteRows = @($indexRows | Where-Object Sheet -eq 'Complete').Count
    Dispositions = @($indexRows | Group-Object DryRunDisposition | Sort-Object Count -Descending | ForEach-Object { [ordered]@{ Name = $_.Name; Count = $_.Count } })
    SalesforceStatuses = @($indexRows | Group-Object SalesforceStatus | Sort-Object Count -Descending | ForEach-Object { [ordered]@{ Name = $_.Name; Count = $_.Count } })
    WorkbookThemes = @($indexRows | Group-Object WorkbookTheme | Sort-Object Count -Descending | ForEach-Object { [ordered]@{ Name = $_.Name; Count = $_.Count } })
    Owners = @($indexRows | Group-Object SalesforceOwner | Sort-Object Count -Descending | ForEach-Object { [ordered]@{ Name = $_.Name; Count = $_.Count } })
    RelatedEvidence = [ordered]@{
        CaseHistory = $history.Count
        FeedItems = $feedItems.Count
        FeedComments = $feedComments.Count
        Files = $contentLinks.Count
    }
}

$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputSummaryJson -Encoding UTF8
$summary | ConvertTo-Json -Depth 8
