#Requires -Version 5.1

<#
.SYNOPSIS
    Clears Print Queue for all printers
.DESCRIPTION
    Clears Print Queue for all printers.
    This script will stop the printer spooler service, clear all print jobs, and start the printer spooler service.
    If some print jobs are not cleared, then a reboot might be needed before running this script again.
.EXAMPLE
    No parameters needed
.OUTPUTS
    String
.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release Notes:
    Initial Release
.COMPONENT
    Printer
#>

[CmdletBinding()]
param ()

begin {
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
}

process {
    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }
    Write-Host "Stopping print spooler service"
    $StopProcess = Start-Process -FilePath "C:\WINDOWS\system32\net.exe" -ArgumentList "stop", "spooler" -Wait -NoNewWindow -PassThru
    # Exit Code 2 usually means the service is already stopped
    if ($StopProcess.ExitCode -eq 0 -or $StopProcess.ExitCode -eq 2) {
        Write-Host "Stopped print spooler service"
        # Sleep just in case the spooler service is taking some time to stop
        Start-Sleep -Seconds 10
        Write-Host "Clearing all print queues"
        Remove-Item -Path "$env:SystemRoot\System32\spool\PRINTERS\*" -Force -ErrorAction SilentlyContinue
        Write-Host "Cleared all print queues"

        Write-Host "Starting print spooler service"
        $StartProcess = Start-Process -FilePath "C:\WINDOWS\system32\net.exe" -ArgumentList "start", "spooler" -Wait -NoNewWindow -PassThru
        if ($StartProcess.ExitCode -eq 0) {
            Write-Host "Started print spooler service"
        }
        else {
            Write-Host "Could not start Print Spooler service. net start spooler returned exit code of $($StartProcess.ExitCode)"
            exit 1
        }
    }
    else {
        Write-Host "Could not stop Print Spooler service. net stop spooler returned exit code of $($StopProcess.ExitCode)"
        exit 1
    }
    exit 0
}

end {}