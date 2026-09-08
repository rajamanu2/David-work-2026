$ErrorActionPreference = 'Stop'

function Invoke-SfJson {
    param([string[]]$Arguments)
    $raw = & sf @Arguments 2>$null
    $parsed = $raw | ConvertFrom-Json
    if ($parsed.status -ne 0) {
        throw ($parsed | ConvertTo-Json -Depth 8)
    }
    return $parsed.result
}

$aliases = @('ProboDevDO', 'ProboMedical')
$objects = @('WorkOrderLineItem', 'WorkOrder', 'Asset', 'Product2', 'Opportunity', 'ServiceContract')
$fieldPattern = 'asset|serial|part|description|cost|customer|opportun|order|price|product|service|contract|quantity|total|subject|status'
$output = @()

foreach ($alias in $aliases) {
    try {
        $org = Invoke-SfJson @('data','query','--target-org',$alias,'--query','SELECT Id, Name, OrganizationType, IsSandbox FROM Organization','--json')
    }
    catch {
        $output += [pscustomobject][ordered]@{
            alias = $alias
            connectionError = $_.Exception.Message
        }
        continue
    }
    $entry = [ordered]@{
        alias = $alias
        organization = $org.records
        objects = @{}
        reports = @()
        opportunities = @()
        customReportTypes = @()
    }

    foreach ($objectName in $objects) {
        try {
            $desc = Invoke-SfJson @('sobject','describe','--sobject',$objectName,'--target-org',$alias,'--json')
            $fields = $desc.fields | Where-Object {
                $_.name -match $fieldPattern -or $_.label -match $fieldPattern -or $_.relationshipName -match $fieldPattern
            } | Select-Object name,label,type,relationshipName,referenceTo,calculated,createable,updateable
            $entry.objects[$objectName] = [ordered]@{
                available = $true
                keyPrefix = $desc.keyPrefix
                fields = @($fields)
            }
        }
        catch {
            $entry.objects[$objectName] = [ordered]@{ available = $false; error = $_.Exception.Message }
        }
    }

    try {
        $reports = Invoke-SfJson @('data','query','--target-org',$alias,'--query',"SELECT Id, Name, DeveloperName, FolderName, Format, LastRunDate FROM Report WHERE Name LIKE '%GE%' OR Name LIKE '%Work Order%' OR Name LIKE '%Part%' OR Name LIKE '%CPC%' ORDER BY Name",'--json')
        $entry.reports = @($reports.records)
    }
    catch {
        $entry.reports = @([ordered]@{ error = $_.Exception.Message })
    }

    try {
        $opps = Invoke-SfJson @('data','query','--target-org',$alias,'--query',"SELECT Id, Name, StageName, CloseDate, Amount, Account.Name FROM Opportunity WHERE Name LIKE '%CPC%' OR Name LIKE '%302808%' ORDER BY Name",'--json')
        $entry.opportunities = @($opps.records)
    }
    catch {
        $entry.opportunities = @([ordered]@{ error = $_.Exception.Message })
    }

    try {
        $types = Invoke-SfJson @('data','query','--use-tooling-api','--target-org',$alias,'--query',"SELECT Id, DeveloperName, MasterLabel, Description, BaseObject, Deployed FROM CustomReportType WHERE MasterLabel LIKE '%Work%' OR MasterLabel LIKE '%Part%' OR MasterLabel LIKE '%Service%'",'--json')
        $entry.customReportTypes = @($types.records)
    }
    catch {
        $entry.customReportTypes = @([ordered]@{ error = $_.Exception.Message })
    }

    $output += [pscustomobject]$entry
}

$output | ConvertTo-Json -Depth 12
