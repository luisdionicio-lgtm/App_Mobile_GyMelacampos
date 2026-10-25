param([string]$Serial='ZY22LJ23MF',[string]$Adb='')
$ErrorActionPreference='SilentlyContinue'
if(-not $Adb){$Adb=(Get-Command adb -ErrorAction Stop).Source}
$mutex=New-Object Threading.Mutex($false,'Local\GMCampoUsbBridge')
if(-not $mutex.WaitOne(0)){exit}
$stop=New-Object Threading.EventWaitHandle($false,[Threading.EventResetMode]::ManualReset,'Local\GMCampoUsbBridgeStop')
$stop.Reset() | Out-Null
try {
 do {
  $state=& $Adb -s $Serial get-state 2>$null
  if($state -eq 'device'){
   $mappings=& $Adb -s $Serial reverse --list 2>$null
   if(-not ($mappings -match 'tcp:8080 tcp:8080')){& $Adb -s $Serial reverse tcp:8080 tcp:8080 *> $null}
  }
 }while(-not $stop.WaitOne(12000))
}finally{$stop.Dispose();$mutex.ReleaseMutex();$mutex.Dispose()}
