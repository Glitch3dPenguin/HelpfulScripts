# A script to take and save a multi-monitor screenshot of the logged in user. 
# The screenshot is saved to %appdata%\Local\SCREENSHOT.png

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$screens = [Windows.Forms.Screen]::AllScreens

$top = ($screens.Bounds.Top    | Measure-Object -Minimum).Minimum
$left = ($screens.Bounds.Left   | Measure-Object -Minimum).Minimum
$width = ($screens.Bounds.Right  | Measure-Object -Maximum).Maximum
$height = ($screens.Bounds.Bottom | Measure-Object -Maximum).Maximum

$bounds = [Drawing.Rectangle]::FromLTRB($left, $top, $width, $height)
$bmp = New-Object System.Drawing.Bitmap ([int]$bounds.width), ([int]$bounds.height)
$graphics = [Drawing.Graphics]::FromImage($bmp)

$graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size)

$bmp.Save("$env:USERPROFILE\AppData\Local\$env:computername-$(Get-Date -UFormat "%Y-%m-%d_%H-%m-%S").png")

$graphics.Dispose()
$bmp.Dispose()