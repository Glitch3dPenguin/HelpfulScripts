Import-Module ActiveDirectory

# ===== CONFIG =====
$DCs = Get-ADDomainController -Filter * | Sort-Object HostName
$RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
$RegValue = "SupportedEncryptionTypes"
# ==================

$Report = foreach ($dc in $DCs) {

    Write-Host "Checking $($dc.HostName)..." -ForegroundColor Cyan

    Invoke-Command -ComputerName $dc.HostName -ScriptBlock {
        param($RegPath, $RegValue)
        
        $regExists = Test-Path $RegPath
        $value = $null

        if ($regExists) {
            try {
                $value = (Get-ItemProperty -Path $RegPath -Name $RegValue -ErrorAction Stop).$RegValue
            } catch {
                $value = $null
            }
        }

        # Decode the value to see which encryption types are allowed
        $aesEnabled = $false
        if ($value) {
            # AES128 = 17, AES256 = 18, check if either is present
            if (($value -band 0x10) -or ($value -band 0x18)) {
                $aesEnabled = $true
            }
        } else {
            # No value = default Windows behavior = AES enabled
            $aesEnabled = $true
        }

        [PSCustomObject]@{
            DCName      = $env:COMPUTERNAME
            RegExists   = $regExists
            RegValue    = if ($value) { $value } else { "Not set (default AES enabled)" }
            AES_Enabled = $aesEnabled
            Status      = if ($aesEnabled) { "AES Enabled" } else { "AES Disabled / Restricted" }
        }

    } -ArgumentList $RegPath, $RegValue
}

# ===== OUTPUT =====
$Report | Format-Table -AutoSize
