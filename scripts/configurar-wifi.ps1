param([string]$WebRoot='D:\GyMelacampos',[string]$InterfaceAlias='Wi-Fi',[string]$Flutter='flutter',[switch]$Build)
$ErrorActionPreference='Stop'
$taskMobileRoot=Split-Path $PSScriptRoot -Parent
$taskAddress=Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike '169.254.*'} | Select-Object -First 1
if(-not $taskAddress){throw 'Conecta el equipo a tu red Wi-Fi antes de configurar.'}
$taskIP=$taskAddress.IPAddress
$taskEnvPath=Join-Path $WebRoot '.env'
$taskEnv=[IO.File]::ReadAllText($taskEnvPath)
$taskKey=if($taskIP -like '192.168.18.*'){'LAN_HOME_HOST'}else{'LAN_MOTOROLA_HOST'}
foreach($taskPair in @(@($taskKey,$taskIP),@('LAN_LISTEN_IP','0.0.0.0'))){
 $taskName=$taskPair[0];$taskValue=$taskPair[1]
 if($taskEnv -match "(?m)^${taskName}="){$taskEnv=[regex]::Replace($taskEnv,"(?m)^${taskName}=.*$",("${taskName}=$taskValue"))}else{$taskEnv+="`r`n${taskName}=$taskValue`r`n"}
}
[IO.File]::WriteAllText($taskEnvPath,$taskEnv,[Text.UTF8Encoding]::new($false))
Remove-Variable taskEnv
Push-Location $WebRoot
try{
 docker compose config --quiet
 if($LASTEXITCODE -ne 0){throw 'Compose inválido'}
 docker compose up -d lan lan_motorola
 if($LASTEXITCODE -ne 0){throw 'No se pudo iniciar HTTPS local'}
 $taskContainer=docker compose ps -q lan
 docker cp "${taskContainer}:/data/caddy/pki/authorities/local/root.crt" "$taskMobileRoot\assets\lan-root-ca.pem"
 if($LASTEXITCODE -ne 0){throw 'Espera unos segundos y repite: el certificado local aún no está listo.'}
}finally{Pop-Location}
$taskPort=if($taskKey -eq 'LAN_HOME_HOST'){8443}else{8444}
$taskServer="https://${taskIP}:$taskPort"
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
  & $Flutter build apk --release "--dart-define=API_BASE_URL=https://192.168.18.103:8443"
  if($LASTEXITCODE -ne 0){throw 'Falló la compilación Android'}
 }finally{Pop-Location}
}
