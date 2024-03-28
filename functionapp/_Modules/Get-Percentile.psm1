function Get-Percentile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] 
        [Double[]]$Sequence
        ,
        [Parameter(Mandatory)]
        [Double]$Percentile
    )
   
    $Sequence = $Sequence | Sort-Object
    [int]$N = $Sequence.Length
    Write-Verbose "N is $N"
    [Double]$Num = ($N - 1) * $Percentile + 1
    Write-Verbose "Num is $Num"
    if ($num -eq 1) {
        return $Sequence[0]
    } elseif ($num -eq $N) {
        return $Sequence[$N-1]
    } else {
        $k = [Math]::Floor($Num)
        Write-Verbose "k is $k"
        [Double]$d = $num - $k
        Write-Verbose "d is $d"
        return $Sequence[$k - 1] + $d * ($Sequence[$k] - $Sequence[$k - 1])
    }
}