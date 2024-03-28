function Get-AzureResourceGraphResults {
    [CmdletBinding()]

    param ( [String] $kqlFile )

    $resourceGraphQuery = Get-Content -Path .\_Queries\$kqlFile.kql -Raw

    try {
        $resourceGraphResults = [System.Collections.ArrayList]::new()
        while ($true) {
            $results = Search-AzGraph -Query $resourceGraphQuery -SkipToken $results.SkipToken -UseTenantScope
            $resourceGraphResults += $results
            if ($null -eq $results.SkipToken) {
                break;
            }
        }
        return $resourceGraphResults
    }
    catch {
        Write-Error 'Unable to Query Azure Resource Graph. Exiting'
        Write-Error $_
        break
    }
}