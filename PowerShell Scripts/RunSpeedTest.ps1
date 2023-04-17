#Run a Speed Test using SpeedTest's CLI

$URL = "https://install.speedtest.net/app/cli/ookla-speedtest-1.0.0-win64.zip"
$DestinationPath = "$env:SYSTEMDRIVE\ookla-speedtest-1.0.0-win64"
$OUTFILE = "$DestinationPath\ookla-speedtest-1.0.0-win64.zip"
$EXEPath = "$DestinationPath\speedtest.exe"
mkdir $DestinationPath
(New-Object System.Net.WebClient).DownloadFile($URL, $OUTFILE)
Expand-Archive -LiteralPath $OUTFILE -DestinationPath $DestinationPath
Start-Process -Wait -NoNewWindow -FilePath $EXEPath --accept-license
Start-Sleep -s 30
Remove-Item $OUTFILE
Remove-Item $DestinationPath -Recurse