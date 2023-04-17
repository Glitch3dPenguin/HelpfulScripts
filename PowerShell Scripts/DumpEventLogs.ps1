# This script will dump the Windows Event Logs 
# This script only supports Windows 10 and up
# Dumped Event Logs are stored in C:\EventLogs\xxxxxxx

$version = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentVersion
if ($Version -lt "6.2") {
    write-host "Unsupported OS. Only Windows 10 and up are supported."
    exit 1
}
$RightNow = Get-Date -Format FileDateTime
$Logs = get-ciminstance -ClassName Win32_NTEventlogFile | Where-Object { $_.LogfileName -eq "Application" -or $_.LogfileName -eq "System" -or $_.LogfileName -eq "Security" }
foreach ($log in $logs) {
    $BackupPath = Join-Path "c:\EventLogs\$RightNow" "$($log.FileName).evtx"
    New-Item -ItemType File -Path $BackupPath -Force
    Copy-Item -path $($Log.Name) -Destination $BackupPath -Force
}