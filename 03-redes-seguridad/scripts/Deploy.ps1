param(
    [ValidateSet('Validate', 'WhatIf', 'Deploy')][string]$Mode = 'WhatIf',
    [string]$Location = 'centralus',
    [string]$VmSize = 'Standard_B2pts_v2',
    [string]$ImageSku = 'server-arm64'
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$account = az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
$keyDirectory = Join-Path $PSScriptRoot '../.local'
New-Item -ItemType Directory -Path $keyDirectory -Force | Out-Null
$keyPath = Join-Path $keyDirectory 'id_ed25519'
if (-not (Test-Path -LiteralPath $keyPath)) {
    ssh-keygen -t ed25519 -f $keyPath -N '' -C 'leadutp03-lab'
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo generar la clave local.' }
}
$adminIp = (Invoke-RestMethod 'https://api.ipify.org' -TimeoutSec 20).Trim()
$parsedAddress = $null
if (-not [System.Net.IPAddress]::TryParse($adminIp, [ref]$parsedAddress) -or $parsedAddress.AddressFamily -ne 'InterNetwork') { throw 'No se obtuvo una IPv4 válida.' }
$groupExists = az group exists -n rg-leadutp-03-dev -o tsv
if ($LASTEXITCODE -ne 0) { throw 'No se pudo comprobar el grupo del laboratorio.' }
if ($groupExists -eq 'false') {
    az group create -n rg-leadutp-03-dev -l $Location --tags project=leadutp-03 environment=lab --output none
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear el grupo del laboratorio.' }
}
$operation = switch ($Mode) { 'Validate' { 'validate' }; 'WhatIf' { 'what-if' }; 'Deploy' { 'create' } }
$publicKey = Get-Content -LiteralPath "$keyPath.pub" -Raw
$watchers = az network watcher list -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'No se pudo comprobar Network Watcher.' }
$createWatcher = (@($watchers | Where-Object location -EQ $Location).Count -eq 0).ToString().ToLowerInvariant()
az deployment group $operation -g rg-leadutp-03-dev -n network-lab --template-file "$PSScriptRoot/../infra/main.bicep" --parameters "location=$Location" "sshPublicKey=$($publicKey.Trim())" "adminIPv4=$adminIp" "vmSize=$VmSize" "imageSku=$ImageSku" "createNetworkWatcher=$createWatcher" --query properties.outputs -o json
if ($LASTEXITCODE -ne 0) { throw 'Falló el laboratorio de redes.' }
