param($pricing)

$body = Get-AzureResourceGraphResults -kqlFile "Disk"

foreach ($disk in $body | Where-Object DiskSku -eq "") {
    Write-Host @"
    Finding the missing sku for Disk with the following capabilities:
    Tier :       $($disk.DiskTier)
    Location :   $($disk.Location)
    Size :       $($disk.DiskSize)
    MaxIOPS :    $($disk.DiskMaxIOPS)
    MaxMBpsRW :  $($disk.DiskMaxMBpsRW)
"@
                
    $sku = $pricing | Where-Object { $_.Name -eq $disk.DiskTier `
            -and $_.Location -eq $disk.Location `
            -and $_.MaxIOps -eq $disk.DiskMaxIOPS `
            -and $_.MaxBandwidthMBps -eq $disk.DiskMaxMBpsRW `
            -and $_.MaxSizeGiB -ge [convert]::ToInt32($disk.DiskSize) `
            -and $_.MinSizeGiB -lt [convert]::ToInt32($disk.DiskSize)
    } | Select-Object -First 1

    $disk.DiskSku = $sku.Size
}

return $body