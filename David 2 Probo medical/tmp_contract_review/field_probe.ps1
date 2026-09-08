$ErrorActionPreference = 'Stop'
$aliases = @('ProboDevDO','ProboMedical')
$objects = @('WorkOrder','WorkOrderLineItem','Asset','Product2')
$wanted = '^(Id|Name|WorkOrderNumber|WorkOrderId|LineItemNumber|Subject|Status|Description|ServiceContractId|Opportunity__c|AssetId|Product2Id|PricebookEntryId|Quantity|UnitPrice|ListPrice|Subtotal|Discount|TotalPrice|Part_Number__c|SerialNumber|OEM_Serial__c|Customer_ID__c|AssetNumber|ProductCode|Std_Cost_Out__c|Std_Cost_ex__c|Average_Cost__c|Cost__c|Unit_Cost__c|Total_Cost__c)$'
foreach ($alias in $aliases) {
    foreach ($objectName in $objects) {
        $raw = & sf sobject describe --sobject $objectName --target-org $alias --json 2>$null
        $json = $raw | ConvertFrom-Json
        [pscustomobject]@{
            alias = $alias
            object = $objectName
            fields = @($json.result.fields | Where-Object { $_.name -match $wanted -or $_.label -match 'customer id|part number|std cost|average cost|unit cost|asset number|oem serial' } | Select-Object name,label,type,relationshipName,referenceTo,calculated)
        } | ConvertTo-Json -Depth 8 -Compress
    }
}
