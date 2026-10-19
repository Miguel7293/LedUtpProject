param(
    [ValidateSet('Registry', 'Api', 'Web')][string]$Stage = 'Registry',
    [switch]$Deploy,
    [string]$ImageTag = 'v1'
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
function Assert-Exit([string]$Message) { if ($LASTEXITCODE -ne 0) { throw $Message } }
$account = az account show -o json | ConvertFrom-Json
Assert-Exit 'Iniciar sesión en Azure.'
if ($account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
$rg = 'rg-leadutp-02-dev'
$operation = if ($Deploy) { 'create' } else { 'what-if' }
switch ($Stage) {
    'Registry' {
        az deployment group $operation -g $rg -n registry --template-file "$PSScriptRoot/../infra/registry.bicep" --query properties.outputs -o json
        Assert-Exit 'Falló el registro de contenedores.'
    }
    'Api' {
        $registry = az deployment group show -g $rg -n registry --query properties.outputs -o json | ConvertFrom-Json
        Assert-Exit 'Desplegar primero Registry.'
        if ($Deploy) {
            docker build -t "$($registry.loginServer.value)/leadutp02-api:$ImageTag" "$PSScriptRoot/../api"
            Assert-Exit 'Falló la construcción Docker.'
            az acr login -n $registry.registryName.value
            Assert-Exit 'Falló el inicio de sesión ACR.'
            docker push "$($registry.loginServer.value)/leadutp02-api:$ImageTag"
            Assert-Exit 'Falló la publicación de la imagen.'
        }
        az deployment group $operation -g $rg -n api --template-file "$PSScriptRoot/../infra/container-app.bicep" --parameters "registryServer=$($registry.loginServer.value)" "identityId=$($registry.identityId.value)" "imageTag=$ImageTag" --query properties.outputs -o json
        Assert-Exit 'Falló Container Apps.'
    }
    'Web' {
        $api = az deployment group show -g $rg -n api --query properties.outputs -o json | ConvertFrom-Json
        Assert-Exit 'Desplegar primero Api.'
        az deployment group $operation -g $rg -n web --template-file "$PSScriptRoot/../infra/webapp.bicep" --parameters "catalogApiUrl=$($api.apiUrl.value)" --query properties.outputs -o json
        Assert-Exit 'Falló App Service F1. No cambiar automáticamente a un plan de pago.'
        if ($Deploy) {
            $web = az deployment group show -g $rg -n web --query properties.outputs -o json | ConvertFrom-Json
            Assert-Exit 'No se pudo obtener el destino web.'
            $publishDir = Join-Path $PSScriptRoot '../artifacts/publish'
            $zipPath = Join-Path $PSScriptRoot '../artifacts/web.zip'
            dotnet publish "$PSScriptRoot/../web" -c Release -o $publishDir
            Assert-Exit 'Falló dotnet publish.'
            Compress-Archive -Path "$publishDir/*" -DestinationPath $zipPath -Force
            az webapp deploy -g $rg -n $web.webName.value --src-path $zipPath --type zip --output none
            Assert-Exit 'Falló la publicación ZIP.'
            Write-Output $web.webUrl.value
        }
    }
}
