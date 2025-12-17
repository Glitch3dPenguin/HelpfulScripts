# ======================================================================
#                   NTLM Traffic Audit Script
# Run this on a single DC to view the NTLM authenticaiton and traffic
# Useful for identifying devices that are using insecure authentication 
# methods. 
# ======================================================================

$StartTime = (Get-Date).AddDays(-7)   # Change window as needed
$Results = @()

Write-Host "Collecting NTLM authentication events since $StartTime..." -ForegroundColor Cyan

# Event IDs relevant to NTLM auditing
$EventIDs = @(4624, 4776, 8004)

$Events = Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    ID      = $EventIDs
    StartTime = $StartTime
} -ErrorAction SilentlyContinue

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
            TimeCreated   = $Event.TimeCreated
            EventID       = $Event.Id
            User          = $EventData.TargetUserName
            Domain        = $EventData.TargetDomainName
            Workstation   = $EventData.WorkstationName
            SourceIP      = $EventData.IpAddress
            LogonType     = $EventData.LogonType
            AuthPackage   = $EventData.AuthenticationPackageName
            NTLMVersion   = $EventData.LmPackageName
            Process       = $EventData.ProcessName
        }
    }
}

# Output paths
$CsvPath = "C:\Temp\NTLM_Audit_$(Get-Date -Format yyyyMMdd).csv"

$Results |
    Sort-Object TimeCreated |
    Export-Csv -Path $CsvPath -NoTypeInformation

Write-Host "NTLM audit complete." -ForegroundColor Green
Write-Host "Results saved to $CsvPath" -ForegroundColor Yellow
