param([string]$WebRoot='D:\GyMelacampos',[string]$InterfaceAlias='Wi-Fi',[string]$Flutter='flutter',[switch]$Build)
$ErrorActionPreference='Stop'
$taskMobileRoot=Split-Path $PSScriptRoot -Parent
$taskAddress=Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike '169.254.*'} | Select-Object -First 1
if(-not $taskAddress){throw 'Conecta el equipo a tu red Wi-Fi antes de configurar.'}
$taskIP=$taskAddress.IPAddress
$taskEnvPath=Join-Path $WebRoot '.env'
$taskEnv=[IO.File]::ReadAllText($taskEnvPath)
if($taskEnv -match '(?m)^LAN_BIND_IP='){$taskEnv=[regex]::Replace($taskEnv,'(?m)^LAN_BIND_IP=.*$',('LAN_BIND_IP='+$taskIP))}else{$taskEnv+="`r`nLAN_BIND_IP=$taskIP`r`n"}
[IO.File]::WriteAllText($taskEnvPath,$taskEnv,[Text.UTF8Encoding]::new($false))
Remove-Variable taskEnv
Push-Location $WebRoot
try{
 docker compose config --quiet
 if($LASTEXITCODE -ne 0){throw 'Compose inválido'}
 docker compose up -d lan
 if($LASTEXITCODE -ne 0){throw 'No se pudo iniciar HTTPS local'}
 $taskContainer=docker compose ps -q lan
 docker cp "${taskContainer}:/data/caddy/pki/authorities/local/root.crt" "$taskMobileRoot\assets\lan-root-ca.pem"
 if($LASTEXITCODE -ne 0){throw 'Espera unos segundos y repite: el certificado local aún no está listo.'}
}finally{Pop-Location}
$taskServer="https://${taskIP}:8443"
Write-Host "Servidor Wi-Fi: $taskServer"
Write-Host 'En una terminal como administrador, ejecuta el script scripts\permitir-wifi.ps1 de la web con esta IP si el firewall bloquea el acceso.'
if($Build){
 Push-Location $taskMobileRoot
 try{
  New-Item -ItemType Directory -Force work\sockets | Out-Null
  $taskSocket=(Resolve-Path work\sockets).Path
  $env:JAVA_TOOL_OPTIONS="-Djdk.net.unixdomain.tmpdir=$taskSocket"
  & $Flutter pub get
  if($LASTEXITCODE -ne 0){throw 'Falló pub get'}
  & $Flutter build apk --release "--dart-define=API_BASE_URL=$taskServer"
  if($LASTEXITCODE -ne 0){throw 'Falló la compilación Android'}
 }finally{Pop-Location}
}
