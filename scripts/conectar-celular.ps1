$ErrorActionPreference = 'Stop'
adb devices -l
adb reverse tcp:8080 tcp:8080
if ($LASTEXITCODE -ne 0) { throw 'Conecta el celular por USB y autoriza la depuración.' }
Invoke-RestMethod http://localhost:8080/api/health | Select-Object status,database
Write-Host 'Conexión USB lista. Abre G&M Campo. Mantén Docker activo.'
