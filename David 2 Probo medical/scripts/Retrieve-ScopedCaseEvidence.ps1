param(
    [Parameter(Mandatory = $true)]
    [string]$TargetOrg,

    [Parameter(Mandatory = $true)]
    [string]$CaseExportPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'

$caseExport = Get-Content -LiteralPath $CaseExportPath -Raw | ConvertFrom-Json
$caseIds = @($caseExport.records | ForEach-Object { [string]$_.Id } | Where-Object { $_ -match '^500[a-zA-Z0-9]{15}$' } | Sort-Object -Unique)
if ($caseIds.Count -eq 0) {
    throw 'No valid Case IDs were found in the case export.'
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$quotedCaseIds = ($caseIds | ForEach-Object { "'$_'" }) -join ','
$results = [System.Collections.Generic.List[object]]::new()

function Export-Soql {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Query
    )

    $outputPath = Join-Path $OutputDirectory ($Name + '.json')
    $cliOutput = & sf data query --target-org $TargetOrg --query $Query --result-format json --output-file $outputPath 2>&1
    $exitCode = $LASTEXITCODE
    $recordCount = $null
    if ($exitCode -eq 0 -and (Test-Path -LiteralPath $outputPath)) {
        $payload = Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json
        $recordCount = @($payload.records).Count
    }
    $results.Add([pscustomobject]@{
        Name = $Name
        ExitCode = $exitCode
        RecordCount = $recordCount
        OutputPath = $outputPath
        Message = ($cliOutput -join "`n")
    })
}

Export-Soql -Name 'case_comments' -Query "SELECT Id, ParentId, IsPublished, CommentBody, CreatedById, CreatedBy.Name, CreatedDate, LastModifiedDate FROM CaseComment WHERE ParentId IN ($quotedCaseIds) ORDER BY ParentId, CreatedDate"
Export-Soql -Name 'email_messages' -Query "SELECT Id, ParentId, MessageDate, FromAddress, ToAddress, CcAddress, BccAddress, Subject, Status, Incoming, TextBody, HtmlBody, HasAttachment, CreatedById, CreatedDate, LastModifiedDate FROM EmailMessage WHERE ParentId IN ($quotedCaseIds) ORDER BY ParentId, MessageDate"
Export-Soql -Name 'content_document_links' -Query "SELECT Id, LinkedEntityId, ContentDocumentId, ShareType, Visibility, ContentDocument.Title, ContentDocument.FileType, ContentDocument.ContentSize, ContentDocument.LatestPublishedVersionId, ContentDocument.CreatedDate FROM ContentDocumentLink WHERE LinkedEntityId IN ($quotedCaseIds)"
Export-Soql -Name 'legacy_attachments' -Query "SELECT Id, ParentId, Name, ContentType, BodyLength, Description, CreatedById, CreatedBy.Name, CreatedDate, LastModifiedDate FROM Attachment WHERE ParentId IN ($quotedCaseIds) ORDER BY ParentId, CreatedDate"
Export-Soql -Name 'case_history' -Query "SELECT Id, CaseId, Field, OldValue, NewValue, CreatedById, CreatedBy.Name, CreatedDate FROM CaseHistory WHERE CaseId IN ($quotedCaseIds) ORDER BY CaseId, CreatedDate"
Export-Soql -Name 'tasks' -Query "SELECT Id, WhatId, WhoId, Subject, Status, Priority, ActivityDate, OwnerId, Owner.Name, Description, CreatedById, CreatedDate, LastModifiedDate FROM Task WHERE WhatId IN ($quotedCaseIds) ORDER BY WhatId, CreatedDate"
Export-Soql -Name 'events' -Query "SELECT Id, WhatId, WhoId, Subject, StartDateTime, EndDateTime, OwnerId, Owner.Name, Description, CreatedById, CreatedDate, LastModifiedDate FROM Event WHERE WhatId IN ($quotedCaseIds) ORDER BY WhatId, CreatedDate"
Export-Soql -Name 'feed_items' -Query "SELECT Id, ParentId, Type, Body, Title, RelatedRecordId, CreatedById, CreatedBy.Name, CreatedDate, LastModifiedDate FROM FeedItem WHERE ParentId IN ($quotedCaseIds) ORDER BY ParentId, CreatedDate"
Export-Soql -Name 'case_contact_roles' -Query "SELECT Id, CasesId, ContactId, Contact.Name, Role, CreatedDate FROM CaseContactRole WHERE CasesId IN ($quotedCaseIds)"
Export-Soql -Name 'case_team_members' -Query "SELECT Id, ParentId, MemberId, Member.Name, TeamRoleId, TeamRole.Name FROM CaseTeamMember WHERE ParentId IN ($quotedCaseIds)"
Export-Soql -Name 'case_milestones' -Query "SELECT Id, CaseId, MilestoneTypeId, MilestoneType.Name, StartDate, CompletionDate, IsCompleted, IsViolated, TargetDate FROM CaseMilestone WHERE CaseId IN ($quotedCaseIds)"

$feedPath = Join-Path $OutputDirectory 'feed_items.json'
if (Test-Path -LiteralPath $feedPath) {
    $feedPayload = Get-Content -LiteralPath $feedPath -Raw | ConvertFrom-Json
    $feedIds = @($feedPayload.records | ForEach-Object { [string]$_.Id } | Where-Object { $_ -match '^0D5[a-zA-Z0-9]{15}$' } | Sort-Object -Unique)
    if ($feedIds.Count -gt 0) {
        $quotedFeedIds = ($feedIds | ForEach-Object { "'$_'" }) -join ','
        Export-Soql -Name 'feed_comments' -Query "SELECT Id, FeedItemId, CommentBody, CreatedById, CreatedBy.Name, CreatedDate FROM FeedComment WHERE FeedItemId IN ($quotedFeedIds) ORDER BY FeedItemId, CreatedDate"
    }
}

$results | ConvertTo-Json -Depth 5
