$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$account = az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
$api = az deployment group show -g rg-leadutp-02-dev -n api --query properties.outputs.apiUrl.value -o tsv
if ($LASTEXITCODE -ne 0) { throw 'No se encontró el despliegue API.' }
$web = az deployment group show -g rg-leadutp-02-dev -n web --query properties.outputs.webUrl.value -o tsv
if ($LASTEXITCODE -ne 0) { throw 'No se encontró el despliegue web.' }
foreach ($base in @($api, $web)) {
    $health = Invoke-RestMethod "$base/health" -TimeoutSec 60
    if ($health.status -ne 'ok') { throw "Salud incorrecta: $base" }
    $catalog = Invoke-RestMethod "$base/api/products" -TimeoutSec 60
    if ($catalog.items.Count -ne 3 -or $catalog.environment -ne 'azure') { throw "Catálogo incorrecto: $base" }
}
$page = Invoke-WebRequest "$web/" -TimeoutSec 60
if ($page.Content -notmatch 'Para tu día a día') { throw 'La web no sirve el catálogo.' }
Write-Output "Correcto: salud y catálogo de API y web; HTML disponible en $web"
