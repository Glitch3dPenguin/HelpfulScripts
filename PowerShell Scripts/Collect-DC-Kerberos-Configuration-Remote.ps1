Import-Module ActiveDirectory

$DCs = Get-ADDomainController -Filter *

$results = foreach ($dc in $DCs) {
    Invoke-Command -ComputerName $dc.HostName -ScriptBlock {

        $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters'

        $supportedETypes = Get-ItemProperty -Path $regPath -Name SupportedEncryptionTypes -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            DCName                   = $env:COMPUTERNAME
            OSVersion               = (Get-CimInstance Win32_OperatingSystem).Caption
            SupportedEncryptionTypes = if ($supportedETypes) {
                $supportedETypes.SupportedEncryptionTypes
            } else {
                'Not Set (Default)'
            }
            UseStrongCrypto          = (Get-ItemProperty `
                                        'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' `
                                        -Name SchUseStrongCrypto `
                                        -ErrorAction SilentlyContinue).SchUseStrongCrypto
        }
    }
}

$results | Format-Table -AutoSize
