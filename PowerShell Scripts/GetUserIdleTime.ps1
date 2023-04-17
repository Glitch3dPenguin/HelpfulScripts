#Requires -Version 5.1

<#
.SYNOPSIS
    Returns the longest idle time of any user logged in or for a specific user.
.DESCRIPTION
    Returns the longest idle time of any user logged in or for a specific user.
    If RDS(Remote Desktop Services) is installed and the RSAT tools for it as well,
     then this will get the idle time of each logged in user.
    For workstations and servers(with out RDS installed),
     this will get the current idle of the currently logged in user.
    If a user is logged in via the console and another is via the admin RDP session,
     then both will be considered as one user for calculating idle time.
.EXAMPLE
    No parameters needed.
    Returns the longest idle time of all users logged in.
.EXAMPLE
     -UserName "Fred"
    Returns the longest idle time of the user Fred.
.EXAMPLE
    PS C:\> Get-User-Idle-Time.ps1 -UserName "Fred"
    Returns the longest idle time of the user Fred.
.OUTPUTS
    PSCustomObject[]
.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release Notes:
    Adds functions to get idle time from RDS and non-RDS computers.
.COMPONENT
    ManageUsers
#>

[CmdletBinding()]
param (
    # Specify one user on a Terminal Services Server, else leave blank for normal servers and workstations
    [Parameter(Mandatory = $false)]
    $UserName
)

begin {
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
        { Write-Output $true }
        else
        { Write-Output $false }
    }
    Function Get-QueryUser() {
        Param()
        $Result = @()
        # Replaces all occurrences of 2 or more spaces in a row with a single comma
        $Lines = @(query.exe user).foreach({ $(($_) -replace ('\s{2,}', ',')) })
        if ($Lines.Count -gt 1) {
            $Header = $($Lines[0].split(',').trim())
            for ($i = 1; $i -lt $($Lines.Count); $i++) {
                $Res = "" | Select-Object $Header
                $Line = $($Lines[$i].split(',')).foreach({ $_.trim().trim('>') })
                # Accounts for disconnected users
                if ($Line.count -eq 5) {
                    $Line = @($Line[0], "$($null)", $Line[1], $Line[2], $Line[3], $Line[4] )
                }
                for ($j = 0; $j -lt $($Line.count); $j++) {
                    $Res.$($Header[$j]) = $Line[$j]
                }
                $Result += $Res
                Remove-Variable Res
            }
            return $Result
        }
        else {
            return $null
        }
    }

    Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.ComponentModel;

namespace GetLastUserInput
{
    public class GetLastUserInput
    {
        private struct LASTINPUTINFO
        {
            public uint cbSize;
            public uint dwTime;
        }
        private static LASTINPUTINFO lastInPutNfo;
        static GetLastUserInput()
        {
            lastInPutNfo = new LASTINPUTINFO();
            lastInPutNfo.cbSize = (uint)Marshal.SizeOf(lastInPutNfo);
        }
        [DllImport("User32.dll")]
        private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        /// <summary>
        /// Idle time in ticks
        /// </summary>
        /// <returns></returns>
        public static uint GetIdleTickCount()
        {
            return ((uint)Environment.TickCount - GetLastInputTime());
        }
        /// <summary>
        /// Last input time in ticks
        /// </summary>
        /// <returns></returns>
        public static uint GetLastInputTime()
        {
            if (!GetLastInputInfo(ref lastInPutNfo))
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }
            return lastInPutNfo.dwTime;
        }
    }
}
"@
}

process {
    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }
    if ($(Get-Module -Name "RemoteDesktop") -and $(Get-RDServer -ErrorAction SilentlyContinue)) {
        try {
            $Sessions = Get-RDUserSession
            $Sessions | Select-Object UserName, IdleTime
        }
        catch {
            Write-Warning -Message "A Remote Desktop Services deployment does not exist on $env:COMPUTERNAME."
        }
    }
    else {
        Write-Warning -Message "Remote Desktop Services is not installed on this computer, Falling back to query user."
        $Results = Get-QueryUser
        if ($null -eq $Results) {
            Write-Host "No user(s) logged in."
            exit 0
        }
        # Parse query results and loop through each user
        $Results | ForEach-Object {
            $CurrentUser = $_.USERNAME
            # If UserName param is used, only filter that user; If UserName param isn't used, return all users
            if ($CurrentUser -like $UserName -or ([string]::IsNullOrEmpty($UserName) -or [string]::IsNullOrWhiteSpace($UserName))) {
                # Output a PowerShell Custom Object array
                [PSCustomObject]@{
                    UserName    = $CurrentUser
                    SessionName = $_.SESSIONNAME
                    Id          = $_.ID
                    State       = $_.STATE
                    LogonTime   = $_.'LOGON TIME'
                    IdleTime    = if ($_.'IDLE TIME' -like 'none') { 0 }else { $_.'IDLE TIME' }
                }
            }
        } | Sort-Object -Property IdleTime | Select-Object -Property UserName, @{
            # Modify IdleTime when it shows none
            Label      = "IdleTime"
            Expression = {
                New-TimeSpan -Start $(Get-Date) -End $(Get-Date).AddMilliseconds([GetLastUserInput.GetLastUserInput]::GetIdleTickCount())
            }
        }
    }
}

end {}