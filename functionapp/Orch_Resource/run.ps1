param($Context)

$pricing = Invoke-DurableActivity -FunctionName 'Act_Pricing' -Input $Context.InstanceId
$disks = Invoke-DurableActivity -FunctionName 'Act_Disks' -Input $pricing

$tasks = @()
foreach ($disk in $disks) {
  $tasks += Invoke-DurableActivity -FunctionName 'Act_IOPS' -Input @($Context.InstanceId, $disk, $pricing) -NoWait
}

$null = Wait-DurableTask -Task $tasks

return $Context.InstanceId