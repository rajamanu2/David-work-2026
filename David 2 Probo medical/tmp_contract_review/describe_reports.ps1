$ErrorActionPreference = 'Stop'

$targets = @(
    [pscustomobject]@{ id = '00ORo000009YRyHMAW'; label = 'GE Capitated Agreement' },
    [pscustomobject]@{ id = '00ORo000009MuO9MAK'; label = 'Generic Parts Shipped on Sales Opps' },
    [pscustomobject]@{ id = '00ORo000006YNDFMA4'; label = 'Cost of Parts Shipped on SWO' }
)

foreach ($alias in @('ProboDevDO','ProboMedical')) {
    foreach ($target in $targets) {
        try {
            $raw = & sf api request rest "/services/data/v67.0/analytics/reports/$($target.id)/describe" --target-org $alias 2>$null
            $json = $raw | ConvertFrom-Json
            $metadata = $json.reportMetadata
            $detailInfo = $json.reportExtendedMetadata.detailColumnInfo
            $columns = @()
            foreach ($key in @($metadata.detailColumns)) {
                $info = $detailInfo.$key
                $columns += [pscustomobject]@{
                    key = $key
                    label = $info.label
                    dataType = $info.dataType
                    entityColumnName = $info.entityColumnName
                }
            }
            [pscustomobject]@{
                alias = $alias
                requestedLabel = $target.label
                id = $metadata.id
                name = $metadata.name
                developerName = $metadata.developerName
                reportType = $metadata.reportType
                reportFormat = $metadata.reportFormat
                detailColumns = $columns
                groupingsDown = @($metadata.groupingsDown)
                reportFilters = @($metadata.reportFilters)
                standardDateFilter = $metadata.standardDateFilter
            } | ConvertTo-Json -Depth 10 -Compress
        }
        catch {
            [pscustomobject]@{ alias=$alias; requestedLabel=$target.label; error=$_.Exception.Message } | ConvertTo-Json -Compress
        }
    }
}
