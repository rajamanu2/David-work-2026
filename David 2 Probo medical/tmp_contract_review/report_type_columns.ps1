$ErrorActionPreference = 'Stop'
$pattern = 'serial|asset number|customer id|part number|part used.*cost|product name|opportunity.*name|service contract.*name|work order.*number|ship date|description'
foreach ($alias in @('ProboDevDO','ProboMedical')) {
    $raw = & sf api request rest '/services/data/v67.0/analytics/report-types/Work_Orders_with_Work_Order_Line_items2__c' --target-org $alias 2>$null
    $json = $raw | ConvertFrom-Json
    $foundColumns = @()
    foreach ($category in @($json.reportTypeMetadata.categories)) {
        foreach ($property in $category.columns.psobject.Properties) {
            $column = $property.Value
            if ($property.Name -match $pattern -or $column.label -match $pattern -or $column.entityColumnName -match $pattern) {
                $foundColumns += [pscustomobject]@{
                    key = $property.Name
                    label = $column.label
                    dataType = $column.dataType
                    filterable = $column.filterable
                }
            }
        }
    }
    [pscustomobject]@{
        alias = $alias
        reportType = $json.reportMetadata.reportType
        rootObjects = @($json.reportTypeMetadata.apiCustomReportTypeDetail.objects | Select-Object entityApiName,joinType,fieldsCountInLayout)
        matchingColumns = @($foundColumns | Sort-Object key -Unique)
    } | ConvertTo-Json -Depth 8 -Compress
}
