<#
.SYNOPSIS
    Audits and fixes external meeting processing for resource mailboxes (Rooms & Equipment).

.DESCRIPTION
    - Connects to Exchange Online
    - Audits resource mailboxes for ProcessExternalMeetingMessages
    - Optionally enables it where disabled
    - Includes safety prompts and optional CSV export

.NOTES
    This script ONLY applies to Room and Equipment mailboxes.
#>

$ErrorActionPreference = 'Stop'

function Prompt-Default {
    param (
        [string]$Message,
        [string]$Default
    )
    $input = Read-Host "$Message [$Default]"
    if ([string]::IsNullOrWhiteSpace($input)) {
        return $Default
    }
    return $input
}

# --- Prompt for Admin Account ---
$AdminUPN = Prompt-Default -Message "Enter Exchange Admin UPN" -Default "admin@yourdomain.com"

# --- Prompt for Mode ---
Write-Host ""
Write-Host "Select Mode:" -ForegroundColor Cyan
Write-Host "1) Audit Only (no changes)"
Write-Host "2) Audit + Fix (resource mailboxes only)"
$mode = Prompt-Default -Message "Enter selection (1 or 2)" -Default "1"

$AuditOnly = $true
if ($mode -eq "2") {
    $AuditOnly = $false
}

# --- Prompt for CSV Export ---
$ExportCsvPath = Read-Host "Optional: Enter CSV export path (or leave blank to skip)"

# --- Install Module if Needed ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "Installing ExchangeOnlineManagement module..." -ForegroundColor Yellow
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}

Import-Module ExchangeOnlineManagement

# --- Connect to Exchange Online ---
Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
Connect-ExchangeOnline -UserPrincipalName $AdminUPN -ShowBanner:$false

# --- Get Resource Mailboxes ONLY ---
Write-Host "Gathering resource mailboxes (Rooms & Equipment)..." -ForegroundColor Cyan
$mailboxes = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails RoomMailbox,EquipmentMailbox

$results = @()
$needsFixList = @()

foreach ($mb in $mailboxes) {
    $identity = $mb.UserPrincipalName

    try {
        $proc = Get-CalendarProcessing -Identity $identity

        $needsFix = ($proc.ProcessExternalMeetingMessages -eq $false)

        if ($needsFix) {
            $needsFixList += $identity
        }

        $results += [PSCustomObject]@{
            DisplayName = $mb.DisplayName
            UserPrincipalName = $identity
            ProcessExternalMeetingMessages = $proc.ProcessExternalMeetingMessages
            Status = if ($needsFix) { "NeedsFix" } else { "OK" }
        }
    }
    catch {
        $results += [PSCustomObject]@{
            DisplayName = $mb.DisplayName
            UserPrincipalName = $identity
            ProcessExternalMeetingMessages = "Error"
            Status = $_.Exception.Message
        }
    }
}

# --- Show Summary ---
Write-Host ""
Write-Host "Audit Summary:" -ForegroundColor Cyan
Write-Host "Total Resource Mailboxes: $($mailboxes.Count)"
Write-Host "Needs Fix: $($needsFixList.Count)"
Write-Host ""

# --- Confirm before fixing ---
if (-not $AuditOnly -and $needsFixList.Count -gt 0) {
    $confirm = Prompt-Default -Message "Proceed with fixing $($needsFixList.Count) mailboxes? (Y/N)" -Default "N"

    if ($confirm.ToUpper() -eq "Y") {
        foreach ($identity in $needsFixList) {
            try {
                Write-Host "Fixing $identity" -ForegroundColor Yellow
                Set-CalendarProcessing -Identity $identity -ProcessExternalMeetingMessages $true

                # Update result status
                ($results | Where-Object { $_.UserPrincipalName -eq $identity }).Status = "Fixed"
            }
            catch {
                Write-Host "Failed to fix $identity" -ForegroundColor Red
            }
        }
    }
    else {
        Write-Host "Fix operation cancelled." -ForegroundColor Yellow
    }
}

# --- Output Results ---
Write-Host ""
Write-Host "Results:" -ForegroundColor Cyan
$results | Sort-Object DisplayName | Format-Table -AutoSize

# --- Export if Requested ---
if (-not [string]::IsNullOrWhiteSpace($ExportCsvPath)) {
    $results | Export-Csv -NoTypeInformation -Path $ExportCsvPath
    Write-Host "Results exported to $ExportCsvPath" -ForegroundColor Green
}

# --- Disconnect ---
Disconnect-ExchangeOnline -Confirm:$false

Write-Host ""
Write-Host "Done." -ForegroundColor Green