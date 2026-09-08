param(
    [string]$ManifestPath = "manifest/package.xml",
    [string]$OutputDirectory = "manifest/chunks",
    [int]$MaximumMembers = 2500
)

$source = [xml](Get-Content -LiteralPath $ManifestPath)
$namespace = "http://soap.sforce.com/2006/04/metadata"

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
Get-ChildItem -LiteralPath $OutputDirectory -Filter "package-*.xml" -ErrorAction SilentlyContinue |
    Remove-Item -Force

$groups = @()
$current = @()
$currentMemberCount = 0

foreach ($typeNode in $source.Package.types) {
    $typeName = [string]$typeNode.name
    $members = @($typeNode.members | ForEach-Object { [string]$_ })

    for ($offset = 0; $offset -lt $members.Count; $offset += $MaximumMembers) {
        $count = [Math]::Min($MaximumMembers, $members.Count - $offset)
        $slice = @($members[$offset..($offset + $count - 1)])

        if (($currentMemberCount + $slice.Count) -gt $MaximumMembers -and $current.Count -gt 0) {
            $groups += ,@($current)
            $current = @()
            $currentMemberCount = 0
        }

        $current += ,@{ Name = $typeName; Members = $slice }
        $currentMemberCount += $slice.Count
    }
}

if ($current.Count -gt 0) {
    $groups += ,@($current)
}

for ($index = 0; $index -lt $groups.Count; $index++) {
    $document = New-Object System.Xml.XmlDocument
    $declaration = $document.CreateXmlDeclaration("1.0", "UTF-8", $null)
    $document.AppendChild($declaration) | Out-Null
    $package = $document.CreateElement("Package", $namespace)
    $document.AppendChild($package) | Out-Null

    foreach ($entry in $groups[$index]) {
        $types = $document.CreateElement("types", $namespace)
        foreach ($member in $entry.Members) {
            $memberNode = $document.CreateElement("members", $namespace)
            $memberNode.InnerText = $member
            $types.AppendChild($memberNode) | Out-Null
        }
        $nameNode = $document.CreateElement("name", $namespace)
        $nameNode.InnerText = $entry.Name
        $types.AppendChild($nameNode) | Out-Null
        $package.AppendChild($types) | Out-Null
    }

    $version = $document.CreateElement("version", $namespace)
    $version.InnerText = [string]$source.Package.version
    $package.AppendChild($version) | Out-Null

    $path = Join-Path $OutputDirectory ("package-{0:D2}.xml" -f ($index + 1))
    $settings = New-Object System.Xml.XmlWriterSettings
    $settings.Indent = $true
    $settings.Encoding = New-Object System.Text.UTF8Encoding($false)
    $writer = [System.Xml.XmlWriter]::Create($path, $settings)
    $document.Save($writer)
    $writer.Close()
}

Write-Output ("Created {0} manifest chunks in {1}" -f $groups.Count, $OutputDirectory)
