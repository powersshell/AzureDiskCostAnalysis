param (
    [Parameter()] [string] $functionAppName
)

$loc = (Get-Location).Path
if (!($loc).EndsWith("functionapp")) {
    Set-Location -Path "functionapp"
    func azure functionapp publish $functionAppName
    Set-Location -Path $loc
}