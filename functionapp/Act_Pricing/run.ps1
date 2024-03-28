param($params)

$body = Get-AzureResourceGraphResults -kqlFile "Disk"

if ($null -eq $body) {
    return
}

$locations = @($body.Location | Sort-Object -Unique)
$allSkus = @()

foreach ($location in $locations) {
    $pricingData = Get-AzureDiskRetailPricing -Location $location
    $skus = Get-AzComputeResourceSku -Location $location | Where-Object resourceType -eq "disks"

    foreach ($sku in $skus) {
        $replType = $sku.Name.Split("_")[1]
        $pricing = $pricingData | Where-Object { $_.DiskSku -eq $sku.Size -and $_.Name -eq $sku.DiskTier -and $_.ReplType -eq $replType } | 
        Select-Object -First 1
        $allSkus += [PSCustomObject]@{
            PartitionKey     = $params
            RowKey           = [guid]::NewGuid().ToString()

            Name             = $sku.Name
            Type             = $pricing.Type
            Size             = $sku.Size
            Location         = $sku.Locations[0]
            MinSizeGiB       = [convert]::ToInt32(($sku.Capabilities | Where-Object Name -eq "MinSizeGiB").Value)
            MaxSizeGiB       = [convert]::ToInt32(($sku.Capabilities | Where-Object Name -eq "MaxSizeGiB").Value)
            MaxIOps          = ($sku.Capabilities | Where-Object Name -eq "MaxIOps").Value
            MaxBandwidthMBps = ($sku.Capabilities | Where-Object Name -eq "MaxBandwidthMBps").Value
            CurrencyCode     = $pricing.CurrencyCode 
            MonthlyPrice     = $pricing.MonthlyPrice 
            Geo              = $sku.Name -Replace '^.*(?=.{3}$)' # LRS / ZRS
        }
    }      
}

Write-Host "Found $($allSkus.Count) SKUs"

Push-OutputBinding -Name TableBinding -Value $allSkus

return $allSkus
