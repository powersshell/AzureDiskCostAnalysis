param($params)

$instanceId = $params[0]
$disk = $params[1]
$pricing = $params[2]

$IOPSMaxThreshold = 90
$IOPS95thThreshold = 50

$resourceId = $disk.DiskResourceId

Write-Host "Processing $($resourceId) ..."

$metrics = Get-AzMetric -ResourceId $resourceId `
    -TimeGrain 00:30:00 `
    -MetricNamespace "Microsoft.Compute/disks" `
    -MetricName "Composite Disk Read Operations/sec", "Composite Disk Write Operations/sec" `
    -StartTime (Get-Date).AddHours(-168)`
    -EndTime (Get-Date) `
    -AggregationType 'Maximum' `
    -DetailedOutput `
    -WarningAction SilentlyContinue 
    
$read = ($metrics | Where-Object { $_.Name.Value -like "Composite Disk Read Operations/sec" }).Data
$write = ($metrics | Where-Object { $_.Name.Value -like "Composite Disk Write Operations/sec" }).Data

$iops = @()
foreach ($readItem in $read) {
    $writeItem = $write | Where-Object TimeStamp -eq $readItem.TimeStamp | Select-Object -Property Maximum
    $iops += [PSCustomObject]@{
        TimeStamp = $readItem.TimeStamp
        ReadWrite = $readItem.Maximum + $writeItem.Maximum
    }
}

$DiskIOPSMax = ($iops.ReadWrite | Measure-Object -Maximum).Maximum
$DiskIOPS95th = Get-Percentile -Sequence $iops.ReadWrite -Percentile 0.95

$result = [PSCustomObject]@{
    PartitionKey              = $instanceId
    RowKey                    = ([guid]::NewGuid()).ToString()

    SubscriptionId            = $disk.SubscriptionId
    Location                  = $disk.Location
    RG                        = $disk.RG
    VMResourceId              = $disk.VMResourceId
    VMName                    = $disk.VMName
    ComputerName              = $disk.ComputerName
    OSType                    = $disk.OSType
    VMSize                    = $disk.VMSize
    CreatedTime               = $disk.CreatedTime.ToString("yyyy-MM-dd")
    DiskName                  = $disk.DiskName
    DiskTier                  = $disk.DiskTier
    DiskSize                  = [int]$disk.DiskSize
    DiskMaxMBpsRW             = [int]$disk.DiskMaxMBpsRW
    DiskMaxIOPS               = [int]$disk.DiskMaxIOPS
    DiskIOPS95th              = [math]::Round($DiskIOPS95th, 2)
    DiskIOPSMaxUsed           = [math]::Round($DiskIOPSMax, 2)
    DiskIOPS95thPercentage    = [math]::Round($DiskIOPS95th / $disk.DiskMaxIOPS * 100, 2)  
    DiskIOPSMaxUsedPercentage = [math]::Round($DiskIOPSMax / $disk.DiskMaxIOPS * 100, 2)
    DiskSku                   = $disk.DiskSku ?? "n/a" 
    MonthlyPrice              = 0
    Good                      = $disk.DiskSku ?? "n/a" 
    GoodSavings               = 0
}

# Assign monthly price of current SKU
$monthlyPrice = $pricing | 
Where-Object { $_.Location -eq $result.Location -and $_.Size -eq $result.DiskSku -and $_.Name -eq $result.DiskTier } | 
Select-Object -First 1 -ExpandProperty MonthlyPrice

$result.MonthlyPrice = [math]::Round($monthlyPrice, 2)

# Skip savings if:
if ($result.DiskSku.StartsWith("S") -or # Disk is already Standard SSD
    $result.DiskIOPSMaxUsedPercentage -ge $IOPSMaxThreshold -or # IOPS is above threshold
    $result.DiskIOPS95thPercentage -ge $IOPS95thThreshold  # IOPS is above threshold
) { 
    
    Write-host "Skipping savings for $($result.DiskName) because it is already Standard SSD or metrics is above threshold"

}
else {

    $lowerTier = $result.DiskSku.StartsWith("P") ? "E" : "S"

    $good = $pricing | 
        Where-Object { $_.Location -eq $disk.Location -and # Match location
            $_.Geo -eq $disk.DiskTier.Split("_")[1] -and # Match geo
            $_.Size.StartsWith($lowerTier) -and # Match lower tier    
            $_.MaxSizeGiB -ge $disk.DiskSize } | # Greater than or same size
            Sort-Object -Property MonthlyPrice, MaxSizeGiB | # Sort by price
            Select-Object -First 1
    
    $result.Good = $good.Size
    $result.GoodSavings = [math]::Round($MonthlyPrice - $good.MonthlyPrice, 2)
}

Push-OutputBinding -Name TableBinding -Value $result

$result