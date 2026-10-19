param(
    [ValidateSet('Validate', 'WhatIf', 'Deploy')]
    [string]$Mode = 'WhatIf',
    [string]$Location = 'brazilsouth'
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$expectedSubscription = 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91'
$account = az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne $expectedSubscription) {
    throw 'Iniciar sesión y seleccionar la suscripción Azure for Students del laboratorio.'
}
$user = az ad signed-in-user show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar el usuario de Entra.' }
$operation = switch ($Mode) { 'Validate' { 'validate' }; 'WhatIf' { 'what-if' }; 'Deploy' { 'create' } }
az deployment sub $operation --name leadutp-01 --location eastus2 --template-file "$PSScriptRoot/../infra/main.bicep" --parameters "location=$Location" "administratorObjectId=$($user.id)" "administratorLogin=$($user.userPrincipalName)" --output json
if ($LASTEXITCODE -ne 0) { throw "Falló la operación $Mode. No cambiar a una modalidad de pago para reintentar." }
