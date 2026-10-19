param([string]$VaultName,[string]$StorageAccount)
$ErrorActionPreference='Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$account=az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
$outputs=az deployment group show -g rg-leadutp-05-dev -n security --query properties.outputs -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Desplegar primero la infraestructura.' }
$vault=if($VaultName) { $VaultName } else { $outputs.vaultName.value }
$storage=if($StorageAccount) { $StorageAccount } else { $outputs.storageAccount.value }
if (-not $vault -or -not $storage) { throw 'No se obtuvieron Vault y Storage.' }
$now=[datetime]::UtcNow
foreach($secret in @(@{name='demo-expira-10d';days=10},@{name='demo-expira-25d';days=25},@{name='demo-expira-90d';days=90})) {
    $expiry=$now.AddDays($secret.days).ToString('yyyy-MM-ddTHH:mm:ssZ')
    az keyvault secret set --vault-name $vault --name $secret.name --value 'DEMO-SINTETICA-SIN-CREDENCIALES-REALES' --expires $expiry --query name -o tsv
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear el secreto de demostración. Revisar propagación RBAC.' }
}
az keyvault key create --vault-name $vault --name demo-rsa-20d --kty RSA --size 2048 --expires $now.AddDays(20).ToString('yyyy-MM-ddTHH:mm:ssZ') --query key.kid -o tsv
if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear la llave RSA.' }
az keyvault key create --vault-name $vault --name demo-ec-90d --kty EC --curve P-256 --expires $now.AddDays(90).ToString('yyyy-MM-ddTHH:mm:ssZ') --query key.kid -o tsv
if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear la llave EC.' }
$certificate=Join-Path $PSScriptRoot '../.local/demo-certificate.pfx'
if (-not (Test-Path -LiteralPath $certificate)) { throw 'Generar primero el certificado de demostración.' }
az keyvault certificate import --vault-name $vault -n demo-cert-12d --file $certificate --query name -o tsv
if ($LASTEXITCODE -ne 0) { throw 'No se pudo importar el certificado.' }
$pdf=Join-Path $PSScriptRoot '../output/pdf/documento-demo.pdf'
az storage blob upload --account-name $storage --container-name documents --name documento-demo.pdf --file $pdf --auth-mode login --overwrite true -o none
if ($LASTEXITCODE -ne 0) { throw 'No se pudo subir el PDF privado.' }
Write-Output 'Secretos sintéticos, llaves, certificado y PDF creados. No se imprimieron valores secretos ni claves privadas.'
