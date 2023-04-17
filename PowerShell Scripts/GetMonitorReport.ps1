# Get plugged in monitor report of the machine. 

$Monitors = Get-WmiObject WmiMonitorID -Namespace root\wmi

ForEach ($Monitor in $Monitors) {

    $Manufacturer = ($Monitor.ManufacturerName -notmatch 0 | ForEach-Object { [char]$_ }) -join ""
    $Name = ($Monitor.UserFriendlyName -notmatch 0 | ForEach-Object { [char]$_ }) -join ""
    $Serial = ($Monitor.SerialNumberID -notmatch 0 | ForEach-Object { [char]$_ }) -join ""
    $ManufacturerYear = $Monitor.YearOfManufacture   

    Write-Host "Manufactured Year: $ManufacturerYear"
    Write-Host "Manufacturer: $Manufacturer"
    Write-Host "Name/Model: $Name"
    Write-Host "Serial: $Serial"
    Write-Host ""
}