Import-Module ActiveDirectory

# ===== CONFIG =====
$TargetUser = 'BShea'
$HoursBack  = 12
$MaxEvents  = 300
# ==================

$StartTime = (Get-Date).AddHours(-$HoursBack)
$DCs = Get-ADDomainController -Filter * | Sort-Object HostName

$Report = foreach ($dc in $DCs) {

    Write-Host "Querying $($dc.HostName)..." -ForegroundColor Cyan

    Invoke-Command -ComputerName $dc.HostName -ScriptBlock {
        param ($TargetUser, $StartTime, $MaxEvents)

        $events = Get-WinEvent -FilterHashtable @{
            LogName   = 'Security'
            StartTime = $StartTime
            Id        = 4768,4771
        } -MaxEvents $MaxEvents -ErrorAction SilentlyContinue

        $userEvents = $events | Where-Object {
            $_.Properties[0].Value -ieq $TargetUser
        }

        $counts = @{
            AES_Success = 0
            AES_Failure = 0
            RC4_Success = 0
            RC4_Failure = 0
        }

        $details = foreach ($evt in $userEvents) {

            $etype = $evt.Properties[8].Value

            if ($evt.Id -eq 4768) {
                switch ($etype) {
                    18 { $counts.AES_Success++ }
                    17 { $counts.AES_Success++ }
                    2  { $counts.RC4_Success++ }
                }

                [PSCustomObject]@{
                    DC             = $env:COMPUTERNAME
                    Time           = $evt.TimeCreated
                    Result         = 'SUCCESS'
                    EncryptionType = $etype
                    EncName        = if ($etype -in 17,18) { 'AES' } elseif ($etype -eq 2) { 'RC4' } else { 'Other' }
                    FailureCode    = ''
                }
            }

            if ($evt.Id -eq 4771) {
                switch ($etype) {
                    18 { $counts.AES_Failure++ }
                    17 { $counts.AES_Failure++ }
                    2  { $counts.RC4_Failure++ }
                }

                [PSCustomObject]@{
                    DC             = $env:COMPUTERNAME
                    Time           = $evt.TimeCreated
                    Result         = 'FAILURE'
                    EncryptionType = $etype
                    EncName        = if ($etype -in 17,18) { 'AES' } elseif ($etype -eq 2) { 'RC4' } else { 'Other' }
                    FailureCode    = $evt.Properties[6].Value
                }
            }
        }

        $health = if ($counts.AES_Success -gt 0 -and $counts.AES_Failure -eq 0) {
            'HEALTHY (AES)'
        } elseif ($counts.RC4_Success -gt 0 -and $counts.AES_Success -eq 0) {
            'RC4-ONLY'
        } elseif ($counts.AES_Failure -gt 0 -or $counts.RC4_Failure -gt 0) {
            'SUSPECT'
        } else {
            'NO DATA'
        }

        [PSCustomObject]@{
            DCName        = $env:COMPUTERNAME
            AES_Success   = $counts.AES_Success
            AES_Failure   = $counts.AES_Failure
            RC4_Success   = $counts.RC4_Success
            RC4_Failure   = $counts.RC4_Failure
            HealthScore   = $health
            EventDetails  = $details
        }

    } -ArgumentList $TargetUser, $StartTime, $MaxEvents
}

# ===== SUMMARY =====
$Report |
    Select DCName, AES_Success, AES_Failure, RC4_Success, RC4_Failure, HealthScore |
    Format-Table -AutoSize

# ===== DETAIL =====
Write-Host "`n--- Detailed Event Correlation ---" -ForegroundColor Yellow

$Report.EventDetails |
    Sort Time |
    Format-Table DC, Time, Result, EncName, EncryptionType, FailureCode -AutoSize
