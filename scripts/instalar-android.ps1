param([string]$Flutter='flutter')
$ErrorActionPreference='Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
New-Item -ItemType Directory -Force work\sockets | Out-Null
$taskSocket=(Resolve-Path work\sockets).Path
$env:JAVA_TOOL_OPTIONS="-Djdk.net.unixdomain.tmpdir=$taskSocket"
& $Flutter pub get
if($LASTEXITCODE -ne 0){throw 'Falló pub get'}
& $Flutter build apk --debug
if($LASTEXITCODE -ne 0){throw 'Falló la compilación'}
& "$PSScriptRoot\conectar-celular.ps1"
adb install -r build\app\outputs\flutter-apk\app-debug.apk
if($LASTEXITCODE -ne 0){throw 'Falló la instalación'}
adb shell am start -n pe.melacampos.gm_campo/.MainActivity
