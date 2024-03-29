# This file enables modules to be automatically managed by the Functions service.
# See https://aka.ms/functionsmanageddependency for additional information.
#
@{
    # For latest supported version, go to 'https://www.powershellgallery.com/packages/Az'.
    # To use the Az module in your function app, please uncomment the line below.
    # 'Az'     
    'AzureFunctions.PowerShell.Durable.SDK' = '1.*'
    'Az.ResourceGraph' = '0.13.0'
    'Az.Compute' = '5.*'
    'Join-Object' = '2.0.2'
    'Az.Storage' = '3.7.0'
    'Az.Monitor' = '5.*'
}