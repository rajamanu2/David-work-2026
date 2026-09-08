$ErrorActionPreference = 'Stop'

$desired = @(
    @{ Name = 'Work Order Number'; Pattern = 'work order.*number' },
    @{ Name = 'Opportunity Name'; Pattern = 'opportunity.*name' },
    @{ Name = 'Service Contract Name'; Pattern = 'service contract.*name' },
    @{ Name = 'Customer PO'; Pattern = 'customer.*po|purchase order' },
    @{ Name = 'Ship Date'; Pattern = 'ship date' },
    @{ Name = 'GE System Serial'; Pattern = 'asset serial number' },
    @{ Name = 'Asset Number'; Pattern = '^asset number$|part used.*asset' },
    @{ Name = 'Part Number'; Pattern = '^part number$' },
    @{ Name = 'Description'; Pattern = 'part used.*product name|product name' },
    @{ Name = 'Quantity'; Pattern = '^quantity$' },
    @{ Name = 'Part Cost'; Pattern = 'part used.*cost|^cost$' },
    @{ Name = 'Total Cost'; Pattern = 'total cost of assets used in repair' }
)

foreach ($alias in @('ProboDevDO', 'ProboMedical')) {
    $raw = & sf api request rest '/services/data/v67.0/analytics/report-types/Work_Orders_with_Work_Order_Line_items2__c' --target-org $alias 2>$null
    $json = $raw | ConvertFrom-Json
    $columns = foreach ($category in @($json.reportTypeMetadata.categories)) {
        foreach ($property in $category.columns.psobject.Properties) {
            [pscustomobject]@{
                key = $property.Name
                label = $property.Value.label
                filterable = $property.Value.filterable
            }
        }
    }

    $results = foreach ($item in $desired) {
        $matches = @($columns | Where-Object { $_.label -match $item.Pattern -or $_.key -match $item.Pattern })
        [pscustomobject]@{
            requested = $item.Name
            found = $matches.Count -gt 0
            matches = @($matches | Sort-Object key -Unique | Select-Object -First 5)
        }
    }

    [pscustomobject]@{
        alias = $alias
        results = @($results)
    } | ConvertTo-Json -Depth 7 -Compress
}
