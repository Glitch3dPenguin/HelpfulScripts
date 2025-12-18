Import-Module ActiveDirectory

# ===== CONFIG =====
$OutputCsv = "C:\Temp\Users_WithAESSet.csv"
# ==================

# Ensure output folder exists
$folder = Split-Path $OutputCsv
if (-not (Test-Path $folder)) { New-Item -ItemType Directory -Path $folder | Out-Null }

# Get users who have msDS-SupportedEncryptionTypes explicitly set
$UsersWithAESSet = Get-ADUser -Filter * -Properties msDS-SupportedEncryptionTypes | Where-Object {
    $_["msDS-SupportedEncryptionTypes"]
} | ForEach-Object {
    [PSCustomObject]@{
        Name                  = $_.Name
        SamAccountName        = $_.SamAccountName
        DistinguishedName     = $_.DistinguishedName
        SupportedEncryptionTypes = $_["msDS-SupportedEncryptionTypes"]
    }
}

# Export to CSV
$UsersWithAESSet | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8

Write-Host "Report complete. Users with explicit encryption types exported to $OutputCsv" -ForegroundColor Green
