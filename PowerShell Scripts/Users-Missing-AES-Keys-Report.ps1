Import-Module ActiveDirectory

# ===== CONFIG =====
$OutputCsv = "C:\Temp\Users_NoAESKeys.csv"
# ==================

# Ensure output folder exists
$folder = Split-Path $OutputCsv
if (-not (Test-Path $folder)) { New-Item -ItemType Directory -Path $folder | Out-Null }

# Get all users and check their msDS-SupportedEncryptionTypes
$UsersWithoutAES = Get-ADUser -Filter * -Properties msDS-SupportedEncryptionTypes | ForEach-Object {

    $aesMissing = $false
    $encTypes = $_["msDS-SupportedEncryptionTypes"]  # <-- Use dictionary-style access

    if (-not $encTypes) {
        # Property not set = AES keys probably never generated
        $aesMissing = $true
    } else {
        # msDS-SupportedEncryptionTypes is set, check if AES128 or AES256 bits are included
        # AES128 = 0x08 (8), AES256 = 0x10 (16)
        if ( -not ($encTypes -band 0x08) -and -not ($encTypes -band 0x10) ) {
            $aesMissing = $true
        }
    }

    if ($aesMissing) {
        [PSCustomObject]@{
            Name                  = $_.Name
            SamAccountName        = $_.SamAccountName
            DistinguishedName     = $_.DistinguishedName
            SupportedEncryptionTypes = if ($encTypes) { $encTypes } else { "Not Set" }
        }
    }
}

# Export to CSV
$UsersWithoutAES | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8

Write-Host "Report complete. Users without AES keys exported to $OutputCsv" -ForegroundColor Green
