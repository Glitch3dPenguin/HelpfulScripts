# 1. Ensure the ExchangeOnlineManagement module is installed and imported
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "Installing ExchangeOnlineManagement module..." -ForegroundColor Cyan
    Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber -Scope CurrentUser
}
Import-Module ExchangeOnlineManagement

# 2. Prompt for Login
# Removing the -UserPrincipalName parameter triggers the interactive MFA login window
Write-Host "Please log in to your Microsoft 365 account..." -ForegroundColor Cyan
Connect-ExchangeOnline

# 3. Prompt for the target account to look up
$TargetMailbox = Read-Host "Enter the email address of the mailbox you wish to analyze"

if ([string]::IsNullOrWhiteSpace($TargetMailbox)) {
    Write-Error "No email address provided. Exiting script."
    return
}

Write-Host "Analyzing folder statistics for $TargetMailbox..." -ForegroundColor Cyan

# 4. Execute the lookup and process sizes
Get-MailboxFolderStatistics -Identity $TargetMailbox | 
ForEach-Object {
    # Extract just the raw numerical bytes from inside the text parentheses
    if ($_.FolderSize -match '\(([\d,]+)\s+bytes\)') {
        $RawBytes = $Matches[1] -replace ',', ''
        $SizeMB   = [Math]::Round(($RawBytes / 1MB), 2)
    } else {
        $SizeMB   = 0.00
    }

    [PSCustomObject]@{
        Name          = $_.Name
        FolderPath    = $_.FolderPath
        ItemsInFolder = $_.ItemsInFolder
        Size_MB       = $SizeMB
    }
} | Sort-Object Size_MB -Descending | Format-Table -AutoSize