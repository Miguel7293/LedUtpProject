param([Parameter(Mandatory)][guid]$RunId)
$ErrorActionPreference='Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$account=az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
$storage=az deployment group show -g rg-leadutp-04-dev -n retail --query properties.outputs.storageAccount.value -o tsv
if ($LASTEXITCODE -ne 0) { throw 'No se encontró Storage.' }
$source=Join-Path $PSScriptRoot "../.local/silver/Sales/run_id=$RunId"
if (-not (Test-Path -LiteralPath $source)) { throw 'Ejecutar antes la transformación PySpark.' }
az storage blob upload-batch --account-name $storage --auth-mode login --destination silver --destination-path "Sales/run_id=$RunId" --source $source --pattern '*.parquet' --overwrite true --output none
if ($LASTEXITCODE -ne 0) { throw 'No se pudo publicar Silver.' }
Write-Output "Silver publicado: abfss://silver@$storage.dfs.core.windows.net/Sales/run_id=$RunId"
