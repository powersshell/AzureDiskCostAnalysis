using namespace System.Net

param($Request, $TriggerMetadata)

$InstanceId = Start-DurableOrchestration -FunctionName "Orch_Resource"
Write-Host "Started orchestration with ID = '$InstanceId'"

$Response = New-DurableOrchestrationCheckStatusResponse -Request $Request -InstanceId $InstanceId
Push-OutputBinding -Name Response -Value $Response