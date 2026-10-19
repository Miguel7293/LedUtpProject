param([Parameter(Mandatory)][guid]$RunId)
$ErrorActionPreference='Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$account=az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
$storage=az deployment group show -g rg-leadutp-04-dev -n retail --query properties.outputs.storageAccount.value -o tsv
if ($LASTEXITCODE -ne 0) { throw 'No se encontró Storage.' }
$root=Join-Path $PSScriptRoot '../.local/bronze'
New-Item -ItemType Directory -Path $root -Force | Out-Null
$files=az storage blob list --account-name $storage --container-name bronze --auth-mode login -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron listar archivos.' }
$count=0
foreach ($blob in $files) {
    if ($blob.name -notlike "*/run_id=$RunId/*" -or $blob.name -notlike '*.parquet') { continue }
    $destination=Join-Path $root $blob.name
    New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
    az storage blob download --account-name $storage --container-name bronze --auth-mode login --name $blob.name --file $destination --overwrite true --output none
    if ($LASTEXITCODE -ne 0) { throw "No se pudo descargar $($blob.name)." }
    $count++
}
Write-Output "Archivos Parquet descargados: $count. Raíz local: $root"
