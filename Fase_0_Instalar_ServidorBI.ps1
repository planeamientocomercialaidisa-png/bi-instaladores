# Bootstrap publico. No incluye credenciales ni datos de AIDISA.
[CmdletBinding()]
param(
 [string]$Destino='C:\ProyectoBI\ServidorBI',
 [string]$GitCorreo
)
$ErrorActionPreference='Stop'
function Requerir($nombre,$paquete) {
 if(Get-Command $nombre -ErrorAction SilentlyContinue){return}
 if(-not(Get-Command winget -ErrorAction SilentlyContinue)){throw "Instale $paquete mediante IT"}
 & winget install --id $paquete --exact --accept-package-agreements --accept-source-agreements
 if($LASTEXITCODE -ne 0){throw "No se instalo $paquete"}
 $env:Path=[Environment]::GetEnvironmentVariable('Path','Machine')+';'+[Environment]::GetEnvironmentVariable('Path','User')
 if(-not(Get-Command $nombre -ErrorAction SilentlyContinue)){throw "Abra otra consola PowerShell y ejecute nuevamente Fase 0 ($nombre)"}
}
Requerir git Git.Git
Requerir python Python.Python.3.12
Requerir node OpenJS.NodeJS.LTS
Requerir gh GitHub.cli
& gh auth status *> $null
if($LASTEXITCODE -ne 0){& gh auth login --hostname github.com --git-protocol https --web}
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
