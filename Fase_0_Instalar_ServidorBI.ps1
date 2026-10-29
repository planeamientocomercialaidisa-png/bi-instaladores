# Bootstrap publico. No incluye credenciales ni datos de AIDISA.
[CmdletBinding()]
param(
 [string]$Destino='C:\ProyectoBI\ServidorBI',
 [string]$GitCorreo
)
$ErrorActionPreference='Stop'
function Requerir($nombre,$paquete) {
 if(Get-Command $nombre -ErrorAction SilentlyContinue){Write-Host "DEPENDENCIA_OK | $nombre | se omite instalacion";return}
 if(-not(Get-Command winget -ErrorAction SilentlyContinue)){throw "Instale $paquete mediante IT"}
 Write-Host "INSTALANDO | $paquete | source=winget"
 & winget install --id $paquete --exact --source winget --accept-package-agreements --accept-source-agreements
 if($LASTEXITCODE -ne 0){
  $env:Path=[Environment]::GetEnvironmentVariable('Path','Machine')+';'+[Environment]::GetEnvironmentVariable('Path','User')
  if(Get-Command $nombre -ErrorAction SilentlyContinue){Write-Host "DEPENDENCIA_OK | $nombre | instalado pese al aviso winget";return}
  throw "No se instalo $paquete desde winget (codigo $LASTEXITCODE). Compruebe winget source list y conectividad del servidor."
 }
 $env:Path=[Environment]::GetEnvironmentVariable('Path','Machine')+';'+[Environment]::GetEnvironmentVariable('Path','User')
 if(-not(Get-Command $nombre -ErrorAction SilentlyContinue)){throw "Abra otra consola PowerShell y ejecute nuevamente Fase 0 ($nombre)"}
}
Requerir git Git.Git
Requerir python Python.Python.3.12
Requerir node OpenJS.NodeJS.LTS
Requerir gh GitHub.cli
$ghStatus = Start-Process -FilePath (Get-Command gh).Source -ArgumentList @('auth','status') -Wait -PassThru -NoNewWindow -RedirectStandardError (Join-Path $env:TEMP 'bi_gh_auth_status.err') -RedirectStandardOutput (Join-Path $env:TEMP 'bi_gh_auth_status.out')
if($ghStatus.ExitCode -ne 0){
 Write-Host 'GITHUB_LOGIN | Abriendo autenticacion en navegador'
 & gh auth login --hostname github.com --git-protocol https --web
}
if($LASTEXITCODE -ne 0){throw 'No se pudo autenticar GitHub'}
& gh auth setup-git
if($LASTEXITCODE -ne 0){throw 'No se pudieron configurar las credenciales Git'}
$repo='planeamientocomercialaidisa-png/portal-bi-gerencial'
$endpoint="repos/$repo/contents/Fase_0_Instalar_Equipo.ps1?ref=main"
$raw= & gh api $endpoint
if($LASTEXITCODE -ne 0){throw 'No se pudo obtener Fase 0 privada'}
$item=$raw | Out-String | ConvertFrom-Json
if(-not $item.content){throw 'El archivo descargado no tiene contenido'}
$archivo=Join-Path $env:TEMP 'Fase_0_Instalar_Equipo_ServidorBI.ps1'
[IO.File]::WriteAllBytes($archivo,[Convert]::FromBase64String(($item.content -replace '\s','')))
if(-not $GitCorreo){$GitCorreo=Read-Host 'Correo corporativo autorizado para autoria Git'}
if($GitCorreo -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$'){throw 'Correo no valido'}
& git config --global user.name 'BI Automatizacion'
& git config --global user.email $GitCorreo
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $archivo -Destino $Destino -Ejecutor servidorbi
if($LASTEXITCODE -ne 0){throw 'Fase 0 oficial no termino correctamente'}
Write-Host 'SERVIDOR_BI_FASE0_OK'
