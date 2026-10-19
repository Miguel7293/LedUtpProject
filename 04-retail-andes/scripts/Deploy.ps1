param([ValidateSet('Validate','WhatIf','Deploy')][string]$Mode='WhatIf')
$ErrorActionPreference='Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$account=az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
$user=az ad signed-in-user show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'No se pudo leer la identidad del usuario.' }
python "$PSScriptRoot/build_pipelines.py"
if ($LASTEXITCODE -ne 0) { throw 'Falló la generación de pipelines.' }
az group create -n rg-leadutp-04-dev -l brazilsouth --tags project=retail-andes environment=lab --output none
if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear el grupo.' }
$operation=switch($Mode) { 'Validate' {'validate'}; 'WhatIf' {'what-if'}; 'Deploy' {'create'} }
az deployment group $operation -g rg-leadutp-04-dev -n retail --template-file "$PSScriptRoot/../infra/main.bicep" --parameters "operatorObjectId=$($user.id)" --query properties.outputs -o json
if ($LASTEXITCODE -ne 0) { throw 'Falló el despliegue de Retail Andes.' }
