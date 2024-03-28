function Get-AzureDiskRetailPricing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Location
    )
    
    $query = "`$filter=serviceName eq 'Storage' and (productName eq 'Premium SSD Managed Disks' or productName eq 'Standard SSD Managed Disks' or  productName eq 'Standard HDD Managed Disks') and armRegionName eq '$Location'"
    $uri = "https://prices.azure.com/api/retail/prices?$query"
    $encoded = [System.Web.HttpUtility]::UrlPathEncode($uri)

    $response = Invoke-RestMethod -Method Get -Uri $encoded
    $pricing = [System.Collections.ArrayList]$response.Items 

    # $response.Items | Select-Object ProductName, SKUName, CurrencyCode, retailPrice, unitPrice, unitOfMeasure
    while ($response.NextPageLink) {
        $encoded = $response.NextPageLink
        $response = Invoke-RestMethod -Method Get -Uri $response.NextPageLink
        $pricing.AddRange($response.Items)
    }
    
    $result = @()
    foreach ($p in $pricing | Where-Object { $_.ProductName -like "*Managed Disks*" -and $_.meterName -notlike "*Mount*" `
                -and $_.meterName -notlike "*Free*" -and $_.meterName -notlike "*Disk Operations*"`
                -and $_.skuName -notlike "*Burst*" -and $_.skuName -notlike "*Snapshots*" `
                -and $_.Type -eq "Consumption"
            }
    ) {
        $sku = $p.skuName.Split()
        $diskSku = $sku[0].Trim()
        $replType = $sku[1].Trim()

        $diskTier = $p.ProductName
        if ($p.ProductName -eq "Premium SSD Managed Disks") {
            $diskTier = "Premium_$replType"
        }
        if ($p.ProductName -eq "Standard HDD Managed Disks") {
            $diskTier = "Standard_$replType"
        }
        if ($p.ProductName -eq "Standard SSD Managed Disks") {
            $diskTier = "StandardSSD_$replType"
        }

        $result += [PSCustomObject]@{
            Type         = $p.Type
            CurrencyCode = $p.CurrencyCode
            Location     = $p.armRegionName
            DiskTier     = $diskTier
            DiskSku      = $diskSku
            ReplType     = $replType
            MonthlyPrice  = $p.retailPrice
        }
    }

    return $result
}