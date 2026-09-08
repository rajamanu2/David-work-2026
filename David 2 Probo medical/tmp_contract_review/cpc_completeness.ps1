$ErrorActionPreference = 'Stop'
$where = "WorkOrder.ServiceContractId IN ('810Ro00000XRhAjIAL','810Ro00000XRS0QIAX','810Ro00000XRdlSIAT','810Ro00000XR5LcIAL','810Ro00000XRuHdIAL','810Ro00000XRRxCIAX') OR WorkOrder.Opportunity__c IN ('006Ro00000iKOb7IAG','006Ro00000iL6QrIAK','006Ro00000iL5eTIAS','006Ro00000iL2NGIA0','006Ro00000iKrbVIAS','006Ro00000iLF5xIAG')"
$queries = [ordered]@{
    total_line_items = "SELECT COUNT(Id) total FROM WorkOrderLineItem WHERE $where"
    shipped_line_items = "SELECT COUNT(Id) total FROM WorkOrderLineItem WHERE ($where) AND WorkOrder.Ship_Date__c != null"
    with_part_used_asset = "SELECT COUNT(Id) total FROM WorkOrderLineItem WHERE ($where) AND Part_Used__c != null"
    with_part_number = "SELECT COUNT(Id) total FROM WorkOrderLineItem WHERE ($where) AND Part_Number__c != null"
    with_product_description = "SELECT COUNT(Id) total FROM WorkOrderLineItem WHERE ($where) AND Part_Used__r.Product_Name__r.Name != null"
    with_line_description = "SELECT COUNT(Id) total FROM WorkOrderLineItem WHERE ($where) AND Description != null"
    with_part_cost = "SELECT COUNT(Id) total FROM WorkOrderLineItem WHERE ($where) AND Part_Used__r.Cost__c != null"
    with_system_service_asset = "SELECT COUNT(Id) total FROM WorkOrderLineItem WHERE ($where) AND WorkOrder.AssetId != null"
    with_system_serial = "SELECT COUNT(Id) total FROM WorkOrderLineItem WHERE ($where) AND WorkOrder.Asset.SerialNumber != null"
    with_customer_id_fallback = "SELECT COUNT(Id) total FROM WorkOrderLineItem WHERE ($where) AND WorkOrder.Customer_ID__c != null"
}
$results = @()
foreach ($item in $queries.GetEnumerator()) {
    $raw = & sf data query --target-org ProboMedical --query $item.Value --json 2>$null
    $json = $raw | ConvertFrom-Json
    if ($json.status -eq 0) {
        $results += [pscustomobject]@{ metric=$item.Key; count=$json.result.records[0].total }
    } else {
        $results += [pscustomobject]@{ metric=$item.Key; error=$json.message }
    }
}
$results | ConvertTo-Json -Compress
