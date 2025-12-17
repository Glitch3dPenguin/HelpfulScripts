# ======================================================================
#                   NTLM Traffic Audit Script
# Run this on a domain contrller to view all the NTLM authenticaiton
# and traffic across all domain controllers in an enviroment. Useful 
# for identifying devices that are using insecure authentication 
# methods across an entire windows domain enviroment. 
# ======================================================================

Import-Module ActiveDirectory

# ===============================
# CONFIG
# ===============================
$DaysBack = 7
$StartTime = (Get-Date).AddDays(-$DaysBack)
$OutputPath = "C:\Temp\NTLM_Audit_AllDCs_$(Get-Date -Format yyyyMMdd).csv"

# NTLM-relevant Event IDs
$EventIDs = @(4624, 4776, 8004)

# ===============================
# DISCOVER DOMAIN CONTROLLERS
# ===============================
Write-Host "Discovering Domain Controllers..." -ForegroundColor Cyan
$DCs = Get-ADDomainController -Filter * | Select-Object -ExpandProperty HostName

Write-Host "Found $($DCs.Count) DCs" -ForegroundColor Green

$Results = @()

# ===============================
# COLLECT EVENTS
# ===============================
foreach ($DC in $DCs) {
    Write-Host "Querying $DC..." -ForegroundColor Yellow

    try {
        $Events = Get-WinEvent -ComputerName $DC -FilterHashtable @{
            LogName   = 'Security'
            ID        = $EventIDs
            StartTime = $StartTime
        } -ErrorAction Stop

        foreach ($Event in $Events) {
            $Xml = [xml]$Event.ToXml()
            $EventData = @{}

            foreach ($Data in $Xml.Event.EventData.Data) {
                $EventData[$Data.Name] = $Data.'#text'
            }

            # NTLM-focused filtering
            if ($EventData.AuthenticationPackageName -eq "NTLM" -or
                $EventData.PackageName -eq "NTLM" -or
                $Event.Id -eq 8004) {

                $Results += [PSCustomObject]@{
                    TimeCreated = $Event.TimeCreated
                    DC          = $DC
                    EventID     = $Event.Id
                    User        = $EventData.TargetUserName
                    Domain      = $EventData.TargetDomainName
                    Workstation = $EventData.WorkstationName
                    SourceIP    = $EventData.IpAddress
                    LogonType   = $EventData.LogonType
                    AuthPackage = $EventData.AuthenticationPackageName
                    NTLMVersion = $EventData.LmPackageName
                    Process     = $EventData.ProcessName
                }
            }
        }
    }
    catch {
        Write-Warning "Failed to query $DC : $_"
    }
}

# ===============================
# EXPORT
# ===============================
if ($Results.Count -gt 0) {
    $Results |
        Sort-Object TimeCreated |
        Export-Csv -Path $OutputPath -NoTypeInformation

    Write-Host "NTLM audit complete." -ForegroundColor Green
    Write-Host "Results saved to $OutputPath" -ForegroundColor Cyan
}
else {
    Write-Host "No NTLM activity found in the selected timeframe." -ForegroundColor Green
}
