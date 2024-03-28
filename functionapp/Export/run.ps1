using namespace System.Net

param($Request, $VMDiskInfo, $TriggerMetadata)

$result = $VMDiskInfo | Sort-Object VMResourceId, DiskName | 
Select-Object -Property SubscriptionId, Location, RG, VMResourceId, VMName, ComputerName, OSType, VMSize, CreatedTime, `
    DiskName, DiskTier, DiskSize, DiskMaxMBpsRW, DiskMaxIOPS, DiskIOPSMaxUsed, DiskIOPSMaxUsedPercentage, DiskIOPS95th, `
    DiskIOPS95thPercentage, DiskSku, MonthlyPrice, Good, GoodSavings

# Save results to CSV
$fileName = "result-$(Get-Date -Format 'yyyyMMddHHmmss').csv"
Write-Host "Saving to $env:TEMP"
$result | ConvertTo-Csv | Out-File -FilePath "$env:TEMP\$fileName"

# Upload to blob storage
$context = New-AzStorageContext -ConnectionString $env:OutputBlobStorageAccessKey
Set-AzStorageBlobContent -File "$env:TEMP\$fileName" -Container "reports" -Context $context
    
$sasUrl = New-AzStorageBlobSASToken -Context $context `
    -Container "reports" `
    -Blob $fileName `
    -Permission r `
    -ExpiryTime (Get-Date).AddDays(7) `
    -FullUri

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $sasUrl
})
