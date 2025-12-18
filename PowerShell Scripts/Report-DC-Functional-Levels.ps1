Import-Module ActiveDirectory

$domain = Get-ADDomain
$forest = Get-ADForest

$DCs = Get-ADDomainController -Filter * | Sort-Object Name | ForEach-Object {
    [PSCustomObject]@{
        DomainController = $_.HostName
        Site             = $_.Site
        IPv4Address      = $_.IPv4Address
        OperatingSystem  = $_.OperatingSystem
        OSVersion        = $_.OperatingSystemVersion
        GlobalCatalog    = $_.IsGlobalCatalog
        DomainFFL        = $domain.DomainMode
        ForestFFL        = $forest.ForestMode
    }
}

$DCs | Format-Table -AutoSize
