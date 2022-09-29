Add-Type -AssemblyName System.Windows.Forms
$myshell = New-Object -com "Wscript.Shell"
while ($true)
{
  $Pos = [System.Windows.Forms.Cursor]::Position
  $x = ($pos.X) + 2
  $y = ($pos.Y) + 2
  [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    $myshell.sendkeys(".")
  Start-Sleep -Seconds 60
}
