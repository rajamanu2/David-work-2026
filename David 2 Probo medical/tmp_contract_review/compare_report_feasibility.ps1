$ErrorActionPreference = 'Stop'

function Invoke-SfJson {
    param([string[]]$Arguments)
    $raw = & sf @Arguments 2>$null
    $parsed = $raw | ConvertFrom-Json
    if ($parsed.status -ne 0) {
        throw "$($parsed.name): $($parsed.message)"
    }
    return $parsed.result
}

function Query-Records {
    param([string]$Alias, [string]$Query)
    try {
        $result = Invoke-SfJson @('data','query','--target-org',$Alias,'--query',$Query,'--json')
        return [ordered]@{ ok = $true; totalSize = $result.totalSize; records = @($result.records) }
    }
    catch {
        return [ordered]@{ ok = $false; error = $_.Exception.Message; query = $Query }
    }
}

function Id-List {
    param([object[]]$Records)
    $ids = @($Records | ForEach-Object { $_.Id } | Where-Object { $_ })
    if ($ids.Count -eq 0) { return $null }
    return ($ids | ForEach-Object { "'$_'" }) -join ','
}

$aliases = @('ProboDevDO', 'ProboMedical')
$objectNames = @('WorkOrderLineItem','WorkOrder','Asset','ServiceContract','Opportunity','Product2')
$interesting = 'Asset|Serial|Part|Description|Cost|Customer_ID|Product|Price|Quantity|Subtotal|Total|Discount|WorkOrder|Opportunity|ServiceContract|Contract|Order'
$poNumbers = @('302808083','302808142','302808182','302808107','302808091','302808186')
$opportunityWhere = ($poNumbers | ForEach-Object { "Name LIKE '%$_%'" }) -join ' OR '
$all = @()

foreach ($alias in $aliases) {
    $orgResult = Query-Records $alias 'SELECT Id, Name, OrganizationType, IsSandbox FROM Organization'
    $entry = [ordered]@{
        alias = $alias
        organization = $orgResult
        schema = @{}
        opportunities = $null
        serviceContracts = $null
        workOrders = $null
        workOrderLineItems = $null
        candidateReports = $null
    }
    if (-not $orgResult.ok) {
        $all += [pscustomobject]$entry
        continue
    }

    $fieldSets = @{}
    foreach ($objectName in $objectNames) {
        try {
            $desc = Invoke-SfJson @('sobject','describe','--sobject',$objectName,'--target-org',$alias,'--json')
            $fieldSets[$objectName] = @($desc.fields)
            $entry.schema[$objectName] = @($desc.fields | Where-Object {
                $_.name -match $interesting -or $_.label -match $interesting
            } | Select-Object name,label,type,relationshipName,referenceTo,calculated)
        }
        catch {
            $entry.schema[$objectName] = @([ordered]@{ error = $_.Exception.Message })
            $fieldSets[$objectName] = @()
        }
    }

    $entry.opportunities = Query-Records $alias "SELECT Id, Name, StageName, CloseDate, Amount, AccountId, Account.Name FROM Opportunity WHERE $opportunityWhere ORDER BY Name"
    $oppRecords = if ($entry.opportunities.ok) { @($entry.opportunities.records) } else { @() }
    $oppIds = Id-List $oppRecords

    $scFields = @($fieldSets['ServiceContract'] | ForEach-Object { $_.name })
    if ($oppIds -and $scFields -contains 'Opportunity__c') {
        $select = @('Id','Name','ContractNumber','Status','Opportunity__c','Opportunity__r.Name')
        foreach ($candidate in @('Customer_PO__c','Total_Cost__c','TotalPrice','GrandTotal','StartDate','EndDate')) {
            if ($scFields -contains $candidate) { $select += $candidate }
        }
        $entry.serviceContracts = Query-Records $alias ("SELECT " + ($select -join ',') + " FROM ServiceContract WHERE Opportunity__c IN ($oppIds) ORDER BY Name")
    }
    else {
        $entry.serviceContracts = [ordered]@{ ok = $false; error = 'No matching opportunities or ServiceContract.Opportunity__c is unavailable.' }
    }
    $scRecords = if ($entry.serviceContracts.ok) { @($entry.serviceContracts.records) } else { @() }
    $scIds = Id-List $scRecords

    $woFields = @($fieldSets['WorkOrder'] | ForEach-Object { $_.name })
    $woWhere = @()
    if ($scIds -and $woFields -contains 'ServiceContractId') { $woWhere += "ServiceContractId IN ($scIds)" }
    if ($oppIds -and $woFields -contains 'Opportunity__c') { $woWhere += "Opportunity__c IN ($oppIds)" }
    if ($woWhere.Count -gt 0) {
        $select = @('Id','WorkOrderNumber','Status','Subject')
        foreach ($candidate in @('ServiceContractId','Opportunity__c','AssetId','AccountId','Order__c','CreatedDate')) {
            if ($woFields -contains $candidate) { $select += $candidate }
        }
        $entry.workOrders = Query-Records $alias ("SELECT " + ($select -join ',') + " FROM WorkOrder WHERE " + ($woWhere -join ' OR ') + " ORDER BY CreatedDate DESC")
    }
    else {
        $entry.workOrders = [ordered]@{ ok = $false; error = 'No queryable Opportunity or Service Contract relationship was available for WorkOrder.' }
    }
    $woRecords = if ($entry.workOrders.ok) { @($entry.workOrders.records) } else { @() }
    $woIds = Id-List $woRecords

    $woliFields = @($fieldSets['WorkOrderLineItem'] | ForEach-Object { $_.name })
    if ($woIds) {
        $select = @('Id','LineItemNumber','WorkOrderId')
        foreach ($candidate in @('Description','AssetId','Product2Id','PricebookEntryId','Quantity','UnitPrice','ListPrice','Subtotal','Discount','TotalPrice','Cost__c','Unit_Cost__c','Part_Number__c','SerialNumber__c')) {
            if ($woliFields -contains $candidate) { $select += $candidate }
        }
        $entry.workOrderLineItems = Query-Records $alias ("SELECT " + ($select -join ',') + " FROM WorkOrderLineItem WHERE WorkOrderId IN ($woIds) ORDER BY CreatedDate DESC LIMIT 200")
    }
    else {
        $entry.workOrderLineItems = [ordered]@{ ok = $true; totalSize = 0; records = @(); note = 'No linked Work Orders found for the six opportunities.' }
    }

    $entry.candidateReports = Query-Records $alias "SELECT Id, Name, DeveloperName, FolderName, Format, LastRunDate FROM Report WHERE Name LIKE '%GE Capitated%' OR Name LIKE '%Work Order Line%' OR Name LIKE '%Parts Shipped%' ORDER BY Name LIMIT 100"
    $all += [pscustomobject]$entry
}

$all | ConvertTo-Json -Depth 14
