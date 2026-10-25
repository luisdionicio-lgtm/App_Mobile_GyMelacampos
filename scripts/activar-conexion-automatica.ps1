$ErrorActionPreference='Stop'
$taskRoot=Split-Path $PSScriptRoot -Parent
$taskAdb=(Get-Command adb).Source
$taskPowerShell="$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
$taskScript=Join-Path $PSScriptRoot 'mantener-conexion-usb.ps1'
$taskArguments="-NoProfile -WindowStyle Hidden -File `"$taskScript`" -Adb `"$taskAdb`""
$taskShortcut=Join-Path ([Environment]::GetFolderPath('Startup')) 'GM Campo USB.lnk'
$taskShell=New-Object -ComObject WScript.Shell
$taskLink=$taskShell.CreateShortcut($taskShortcut)
$taskLink.TargetPath=$taskPowerShell
$taskLink.Arguments=$taskArguments
$taskLink.WorkingDirectory=$taskRoot
$taskLink.Description='Restablece el enlace USB entre G&M Campo y Docker local.'
$taskLink.WindowStyle=7
$taskLink.Save()
Start-Process -FilePath $taskPowerShell -ArgumentList $taskArguments -WindowStyle Hidden
Write-Host 'Enlace USB automático activado para este usuario de Windows. No expone puertos a la red.'
