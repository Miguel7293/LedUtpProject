param([switch]$Deploy, [switch]$Build, [string]$Image, [string]$ContactEmail = $env:AZURE_ALERT_EMAIL)
$ErrorActionPreference = 'Stop'
if (-not $ContactEmail -and (Test-Path "$PSScriptRoot/../.local/settings.json")) { $ContactEmail = (Get-Content "$PSScriptRoot/../.local/settings.json" -Raw | ConvertFrom-Json).alertEmail }
if (-not $ContactEmail) { throw 'Indicar -ContactEmail o AZURE_ALERT_EMAIL.' }
if (Test-Path "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1") { . "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1" }
function Check([string]$Action) { if ($LASTEXITCODE -ne 0) { throw "Falló: $Action" } }
$account = az account show -o json | ConvertFrom-Json; Check 'cuenta'
if ($account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
New-Item -ItemType Directory -Force "$PSScriptRoot/../.local" | Out-Null
if ($Build) {
    if (-not $Deploy) { throw '-Build publica la imagen; usar junto con -Deploy.' }
    $tag = [DateTime]::UtcNow.ToString('yyyyMMddHHmmss')
    $imageTag = "acrleadutpjmas5j6rizpu4.azurecr.io/hero-agency:$tag"
    docker build --target runtime -t $imageTag "$PSScriptRoot/.."; Check 'Docker build'
    az acr login -n acrleadutpjmas5j6rizpu4 -o none; Check 'ACR login'
    docker push $imageTag; Check 'Docker push'
    $digest = az acr repository show -n acrleadutpjmas5j6rizpu4 --image "hero-agency:$tag" --query digest -o tsv; Check 'digest'
    $Image = "acrleadutpjmas5j6rizpu4.azurecr.io/hero-agency@$digest"
    $Image | Set-Content "$PSScriptRoot/../.local/image.txt"
}
if (-not $Image -and (Test-Path "$PSScriptRoot/../.local/image.txt")) { $Image = (Get-Content "$PSScriptRoot/../.local/image.txt" -Raw).Trim() }
if (-not $Image) { throw 'Indicar -Image con digest o usar -Deploy -Build.' }
if ($Deploy) { az group create -n rg-leadutp-07-dev -l brazilsouth --tags project=leadutp-07 environment=lab -o none; Check 'grupo' }
$operation = if ($Deploy) { 'create' } else { 'what-if' }
az deployment group $operation -g rg-leadutp-07-dev -n hero07 --template-file "$PSScriptRoot/../infra/main.bicep" --parameters "image=$Image" "alertEmail=$ContactEmail" -o json
Check 'despliegue'
