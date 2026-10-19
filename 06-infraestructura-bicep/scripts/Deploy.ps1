param([switch]$Deploy, [switch]$PublishModules, [string]$ContactEmail = $env:AZURE_ALERT_EMAIL)
$ErrorActionPreference = 'Stop'
if (-not $ContactEmail -and (Test-Path "$PSScriptRoot/../.local/settings.json")) { $ContactEmail = (Get-Content "$PSScriptRoot/../.local/settings.json" -Raw | ConvertFrom-Json).alertEmail }
if (-not $ContactEmail) { throw 'Indicar -ContactEmail o AZURE_ALERT_EMAIL para las alertas del presupuesto.' }
if (Test-Path "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1") { . "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1" }
$account = az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Seleccionar la suscripción Students del laboratorio.' }
if ($PublishModules) {
    foreach ($module in @('observability','security')) {
        $version = if ($module -eq 'observability') { '1.0.2' } else { '1.0.0' }
        az bicep publish --file "$PSScriptRoot/../infra/modules/$module.bicep" --target "br:acrleadutpjmas5j6rizpu4.azurecr.io/bicep/leadutp/${module}:$version" --with-source
        if ($LASTEXITCODE -ne 0) { throw "No se pudo publicar $module. No sobrescribir versiones existentes; incrementar versión si cambia el código." }
    }
}
$operation = if ($Deploy) { 'create' } else { 'what-if' }
az deployment sub $operation --name leadutp-06 --location brazilsouth --template-file "$PSScriptRoot/../infra/main.bicep" --parameters "alertEmail=$ContactEmail" --output json
if ($LASTEXITCODE -ne 0) { throw 'Falló el despliegue de infraestructura.' }
