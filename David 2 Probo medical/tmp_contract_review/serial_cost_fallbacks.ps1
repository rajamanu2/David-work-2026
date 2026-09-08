$ErrorActionPreference = 'Stop'
$where = "ServiceContractId IN ('810Ro00000XRhAjIAL','810Ro00000XRS0QIAX','810Ro00000XRdlSIAT','810Ro00000XR5LcIAL','810Ro00000XRuHdIAL','810Ro00000XRRxCIAX') OR Opportunity__c IN ('006Ro00000iKOb7IAG','006Ro00000iL6QrIAK','006Ro00000iL5eTIAS','006Ro00000iL2NGIA0','006Ro00000iKrbVIAS','006Ro00000iLF5xIAG')"
$queries = [ordered]@{
    total_work_orders = "SELECT COUNT(Id) total FROM WorkOrder WHERE $where"
    work_orders_with_asset_serial_formula = "SELECT COUNT(Id) total FROM WorkOrder WHERE ($where) AND Asset_Serial_Number__c != null"
    work_orders_with_system_serial = "SELECT COUNT(Id) total FROM WorkOrder WHERE ($where) AND System_Serial_Number__c != null"
    work_orders_with_serial_number = "SELECT COUNT(Id) total FROM WorkOrder WHERE ($where) AND Serial_Number__c != null"
    work_orders_with_asset_lookup = "SELECT COUNT(Id) total FROM WorkOrder WHERE ($where) AND AssetId != null"
    work_orders_with_customer_id = "SELECT COUNT(Id) total FROM WorkOrder WHERE ($where) AND Customer_ID__c != null"
    work_orders_with_hospital_asset = "SELECT COUNT(Id) total FROM WorkOrder WHERE ($where) AND Hospital_Asset_Number__c != null"
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
