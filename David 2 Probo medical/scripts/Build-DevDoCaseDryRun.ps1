param(
    [Parameter(Mandatory = $true)][string]$CaseIndexPath,
    [Parameter(Mandatory = $true)][string]$InventoryDirectory,
    [Parameter(Mandatory = $true)][string]$OutputCsv,
    [Parameter(Mandatory = $true)][string]$OutputSummaryJson
)

$ErrorActionPreference = 'Stop'

function Read-Records([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    return @((Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json).records)
}

$cases = @(Import-Csv -LiteralPath $CaseIndexPath | Where-Object DryRunDisposition -eq 'Ready for case-level requirements analysis')
$entities = Read-Records (Join-Path $InventoryDirectory 'entity_definitions.json')
$flows = Read-Records (Join-Path $InventoryDirectory 'flow_definitions.json')
$validations = Read-Records (Join-Path $InventoryDirectory 'validation_rules.json')
$triggers = Read-Records (Join-Path $InventoryDirectory 'apex_triggers.json')
$classes = Read-Records (Join-Path $InventoryDirectory 'apex_classes.json')
$lwcs = Read-Records (Join-Path $InventoryDirectory 'lwc_bundles.json')
$auras = Read-Records (Join-Path $InventoryDirectory 'aura_bundles.json')

$entityByDurableId = @{}
$entities | ForEach-Object { $entityByDurableId[[string]$_.DurableId] = [string]$_.QualifiedApiName }

$fieldCounts = @{}
Get-ChildItem -LiteralPath (Join-Path $InventoryDirectory 'fields') -Filter 'field_definitions_*.json' | ForEach-Object {
    $records = Read-Records $_.FullName
    foreach ($group in ($records | Group-Object { [string]$_.EntityDefinition.QualifiedApiName })) {
        if ($group.Name) { $fieldCounts[$group.Name] = $group.Count }
    }
}

$targetMap = @{
    'Asset2' = @('ProductItem__c')
    'Opportunity' = @('Opportunity','OpportunityLineItem')
    'Field Service Lightning' = @('ServiceAppointment','WorkOrder','WorkOrderLineItem')
    'Product' = @('Product2','Product_Analytics__c')
    'Work Order' = @('WorkOrder','Work_Order__c')
    'RMA' = @('RMA__c')
    'Intacct' = @('Opportunity','Item_Receipt__c','Invoice__c')
    'Account' = @('Account')
    'Lead' = @('Lead')
    'Equipment' = @('Equipment__c')
    'Permission(s)/Permission Set' = @('User')
    'Invoice' = @('Invoice__c')
    'Shipment/ZenKraft' = @('zkmulti__MCShipment__c')
    'Contact' = @('Contact')
    'Evaluation' = @('Evaluation_Natalie__c')
    'Product Repair' = @('Product_Repair__c')
    'Service Contract' = @('ServiceContract')
    'AvaTax' = @('Opportunity')
    'Purchasing Return' = @('WorkOrder','RMA__c')
    'Case' = @('Case')
    'PandaDoc' = @('Opportunity')
    'User' = @('User')
    'Loaner/Loaner Asset' = @('Loaner__c','Loaner_Asset__c')
    'Product Test' = @('ProductTest__c','Product_Test_Line_Item__c')
    'Move Location' = @('Move_Location__c')
}

$patternMap = @{
    'ProductItem__c' = 'asset|product.?item|inventory'
    'Opportunity' = 'opportunity|\bopp\b'
    'OpportunityLineItem' = 'opportunity.?line|\boli\b'
    'ServiceAppointment' = 'service.?appointment|\bsa\b|dispatch|gantt|fsl'
    'WorkOrder' = 'work.?order|\bwo\b|fsl'
    'WorkOrderLineItem' = 'work.?order.?line|woli'
    'Product2' = 'product'
    'Product_Analytics__c' = 'product.?analytics'
    'RMA__c' = '\brma\b'
    'Item_Receipt__c' = 'item.?receipt|receipt'
    'Invoice__c' = 'invoice'
    'Account' = 'account'
    'Lead' = 'lead'
    'Equipment__c' = 'equipment'
    'User' = 'user|permission|access'
    'zkmulti__MCShipment__c' = 'shipment|shipping|zenkraft|tracking'
    'Contact' = 'contact|persona'
    'Evaluation_Natalie__c' = 'evaluation|eval'
    'Product_Repair__c' = 'product.?repair|repair'
    'ServiceContract' = 'service.?contract|contract'
    'Case' = 'case'
    'Loaner__c' = 'loaner'
    'Loaner_Asset__c' = 'loaner.?asset'
    'ProductTest__c' = 'product.?test|test'
    'Product_Test_Line_Item__c' = 'product.?test.?line|test.?line'
    'Move_Location__c' = 'move.?location|location'
    'Work_Order__c' = 'shop.?work.?order|work.?order'
}

$activeFlows = @($flows | Where-Object { $_.ActiveVersionId })
$customClasses = @($classes | Where-Object { -not $_.NamespacePrefix })
$customLwcs = @($lwcs | Where-Object { -not $_.NamespacePrefix })
$customAuras = @($auras | Where-Object { -not $_.NamespacePrefix })

$rows = [System.Collections.Generic.List[object]]::new()
foreach ($case in $cases) {
    $related = [string]$case.SalesforceRelatedObject
    $theme = [string]$case.WorkbookTheme
    $description = [string]$case.SalesforceDescription
    $subject = [string]$case.SalesforceSubject
    $targets = @($targetMap[$related] | Where-Object { $_ })

    $external = $related -match 'Intacct|AvaTax|ZenKraft|PandaDoc' -or "$subject $description" -match 'Outlook|carrier|UPS|USPS|FedEx'
    $access = $theme -match 'Access|Validation' -or $related -match 'Permission|User'
    $data = $theme -eq 'Data'
    $reports = $theme -match 'Report|Dashboard' -or $case.SalesforceClassification -eq 'Administrative (Reports & Dashboards)'
    $bug = $theme -eq 'BUG' -or $case.SalesforceClassification -eq 'Salesforce Error' -or "$subject $description" -match '(?i)not appearing|not generated|not working|unable to|can.?t |cannot |error|incorrect|wrong |missing |issue|reopened|delay|inoperable|stops working'

    if ($external) {
        $bucket = 'Integration / managed package'
        $readiness = 'Partial in Dev - sandbox endpoint or vendor support required'
        $action = 'Reproduce with sandbox-safe credentials; trace Flow/Apex/package boundary; test vendor callback; prohibit production endpoint calls.'
    }
    elseif ($data) {
        $bucket = 'Data correction / migration'
        $readiness = 'Rehearse in Dev; final production data action requires separate approval'
        $action = 'Create an idempotent query/update script, synthetic records, dry-run diff, rollback file, and production read-back plan.'
    }
    elseif ($access) {
        $bucket = 'Access / validation'
        $readiness = 'Buildable in Dev after exact persona and acceptance criteria are confirmed'
        $action = 'Compare profile, permission sets, object/field/Apex access and validation bypasses; implement least privilege; test as target persona.'
    }
    elseif ($bug) {
        $bucket = 'Defect investigation'
        $readiness = 'Reproducible in Dev after sanitized records and exact steps are created'
        $action = 'Create a minimal reproduction, trace active Flow/Apex/LWC/validation paths, add regression tests, and compare before/after behavior.'
    }
    elseif ($reports) {
        $bucket = 'Reports / dashboards / notifications'
        $readiness = 'Buildable in Dev with representative data and folder-sharing personas'
        $action = 'Locate report type, report/folder or notification metadata; reproduce visibility/filter behavior; update in Dev and run persona UAT.'
    }
    elseif ($related -eq 'OTHER' -or $targets.Count -eq 0) {
        $bucket = 'Clarification / cross-object'
        $readiness = 'Blocked until target object and acceptance criteria are confirmed'
        $action = 'Confirm exact object, record type, affected persona, example record, expected result, and success criteria before building.'
    }
    else {
        $bucket = 'Metadata configuration / automation'
        $readiness = 'Buildable in Dev after representative test data is created'
        $action = 'Retrieve scoped metadata, implement the smallest change, add Flow/Apex tests where applicable, complete persona UAT, then validate deployment.'
    }

    $patterns = @($targets | ForEach-Object { $patternMap[$_] } | Where-Object { $_ })
    $combinedPattern = if ($patterns.Count) { ($patterns -join '|') } else { '(?!)' }
    $targetSet = @{}; $targets | ForEach-Object { $targetSet[$_] = $true }

    $matchingFlows = @($activeFlows | Where-Object { $_.DeveloperName -match $combinedPattern } | Select-Object -ExpandProperty DeveloperName -First 8)
    $matchingValidations = @($validations | Where-Object {
        $entityName = if ($entityByDurableId.ContainsKey([string]$_.EntityDefinitionId)) { $entityByDurableId[[string]$_.EntityDefinitionId] } else { [string]$_.EntityDefinitionId }
        $targetSet.ContainsKey($entityName)
    } | Select-Object -ExpandProperty ValidationName -First 8)
    $matchingTriggers = @($triggers | Where-Object {
        $entityName = if ($entityByDurableId.ContainsKey([string]$_.TableEnumOrId)) { $entityByDurableId[[string]$_.TableEnumOrId] } else { [string]$_.TableEnumOrId }
        $targetSet.ContainsKey($entityName)
    } | Select-Object -ExpandProperty Name -First 8)
    $matchingCode = @($customClasses | Where-Object { $_.Name -match $combinedPattern } | Select-Object -ExpandProperty Name -First 5)
    $matchingUi = @($customLwcs | Where-Object { $_.DeveloperName -match $combinedPattern } | Select-Object -ExpandProperty DeveloperName -First 5)
    if ($matchingUi.Count -lt 5) { $matchingUi += @($customAuras | Where-Object { $_.DeveloperName -match $combinedPattern } | Select-Object -ExpandProperty DeveloperName -First (5 - $matchingUi.Count)) }

    $fieldCount = 0
    foreach ($target in $targets) { $fieldCount += [int]($fieldCounts[$target]) }
    $testData = if ($related -eq 'Field Service Lightning') {
        'Work Order, Service Appointment, Service Resource, Assigned Resource, operating hours, mobile/dispatcher persona'
    } elseif ($targets.Count) {
        (($targets -join ', ') + ' records with required parents, record types, owners, products and statuses')
    } else {
        'Exact production example must be converted to sanitized test data'
    }

    $rows.Add([pscustomobject]@{
        CaseNumber = $case.CaseNumber
        Subject = $subject
        Priority = $case.SalesforcePriority
        Owner = $case.SalesforceOwner
        Classification = $case.SalesforceClassification
        RelatedObject = $related
        WorkbookTheme = $theme
        DevWorkBucket = $bucket
        DevReadiness = $readiness
        ProposedDryRunAction = $action
        TargetApiNames = ($targets -join '; ')
        TargetFieldCount = $fieldCount
        CandidateActiveFlows = ($matchingFlows -join '; ')
        CandidateValidationRules = ($matchingValidations -join '; ')
        CandidateTriggers = ($matchingTriggers -join '; ')
        CandidateApexClasses = ($matchingCode -join '; ')
        CandidateUiBundles = ($matchingUi -join '; ')
        RequiredTestData = $testData
        ProductionWriteRequiredEventually = if ($data) { 'Yes - data change after approval' } elseif ($access) { 'Yes - production assignment/deployment after approval' } else { 'Only controlled metadata deployment after approval' }
    })
}

New-Item -ItemType Directory -Path (Split-Path -Parent $OutputCsv) -Force | Out-Null
$rows | Sort-Object DevWorkBucket, Priority, CaseNumber | Export-Csv -LiteralPath $OutputCsv -NoTypeInformation -Encoding UTF8

$summary = [ordered]@{
    GeneratedAt = (Get-Date).ToString('o')
    CaseCount = $rows.Count
    ActiveFlowDefinitions = $activeFlows.Count
    TotalFlowDefinitions = $flows.Count
    ActiveValidationRules = @($validations | Where-Object Active).Count
    TotalValidationRules = $validations.Count
    ApexTriggers = $triggers.Count
    ApexClasses = $classes.Count
    LwcBundles = $lwcs.Count
    AuraBundles = $auras.Count
    PermissionSets = @(Read-Records (Join-Path $InventoryDirectory 'permission_sets.json')).Count
    EmailTemplates = @(Read-Records (Join-Path $InventoryDirectory 'email_templates.json')).Count
    Reports = @(Read-Records (Join-Path $InventoryDirectory 'reports.json')).Count
    Dashboards = @(Read-Records (Join-Path $InventoryDirectory 'dashboards.json')).Count
    Buckets = @($rows | Group-Object DevWorkBucket | Sort-Object Count -Descending | ForEach-Object { [ordered]@{ Name = $_.Name; Count = $_.Count } })
    Readiness = @($rows | Group-Object DevReadiness | Sort-Object Count -Descending | ForEach-Object { [ordered]@{ Name = $_.Name; Count = $_.Count } })
    HighPriorityCases = @($rows | Where-Object Priority -eq 'High' | Select-Object CaseNumber, Subject, DevWorkBucket, DevReadiness)
}
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputSummaryJson -Encoding UTF8
$summary | ConvertTo-Json -Depth 8
