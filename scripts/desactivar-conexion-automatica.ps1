$taskShortcut=Join-Path ([Environment]::GetFolderPath('Startup')) 'GM Campo USB.lnk'
if(Test-Path -LiteralPath $taskShortcut){Remove-Item -LiteralPath $taskShortcut}
try{$taskEvent=[Threading.EventWaitHandle]::OpenExisting('Local\GMCampoUsbBridgeStop');$taskEvent.Set() | Out-Null;$taskEvent.Dispose()}catch{}
Write-Host 'Enlace automático desactivado. La app y los datos se conservan.'
