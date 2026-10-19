# Demuestra una credencial real referenciada desde KV sin habilitar claves de Storage.
# SAS de delegación de usuario: solo lectura/listado del contenedor demo y una hora.
$ErrorActionPreference='Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
function Check04($message) {if ($LASTEXITCODE -ne 0) {throw $message}}
$account04='stretail57cyqpixoehss'
$factory04='https://management.azure.com/subscriptions/e1e4a5db-a7e6-49f2-8968-9a0ffd605a91/resourceGroups/rg-leadutp-04-dev/providers/Microsoft.DataFactory/factories/adf-retail-57cyqpixoehss'
$vaultScope04='/subscriptions/e1e4a5db-a7e6-49f2-8968-9a0ffd605a91/resourceGroups/rg-leadutp-04-dev/providers/Microsoft.KeyVault/vaults/kv-retail-andes-7293'
$operator04=az ad signed-in-user show --query id -o tsv; Check04 'Consultar usuario.'
az role assignment create --assignee-object-id $operator04 --assignee-principal-type User --role 'Key Vault Secrets Officer' --scope $vaultScope04 -o none; Check04 'Permiso para renovar credencial de demo.'
az storage container create --account-name $account04 --name credentials-demo --auth-mode login --public-access off -o none; Check04 'Crear contenedor de demo.'
$file04="$PSScriptRoot/../.local/credential-check.txt"
'Archivo ficticio para validar credenciales de ADF desde Key Vault.' | Set-Content -Encoding utf8 $file04
az storage blob upload --account-name $account04 --container-name credentials-demo --name credential-check.txt --file $file04 --auth-mode login --overwrite --only-show-errors -o none; Check04 'Publicar archivo sintético.'
$expires04=[datetime]::UtcNow.AddHours(1)
$sas04=az storage container generate-sas --account-name $account04 --name credentials-demo --auth-mode login --as-user --https-only --permissions rl --expiry $expires04.ToString('yyyy-MM-ddTHH:mmZ') -o tsv; Check04 'Generar SAS limitada.'
$vaultToken04=az account get-access-token --resource https://vault.azure.net --query accessToken -o tsv; Check04 'Acceso a Key Vault.'
try {
    $body04=@{value="?$sas04";attributes=@{enabled=$true;exp=([DateTimeOffset]$expires04).ToUnixTimeSeconds()}} | ConvertTo-Json -Depth 5
    for ($attempt04=1;$attempt04 -le 6;$attempt04++) {
        try {
            Invoke-RestMethod -Method Put -Uri 'https://kv-retail-andes-7293.vault.azure.net/secrets/demo-read-sas?api-version=7.4' -Headers @{Authorization="Bearer $vaultToken04"} -ContentType application/json -Body $body04 | Out-Null
            break
        } catch {if ($attempt04 -eq 6) {throw};Start-Sleep -Seconds 10}
    }
} finally {$sas04=$null;$vaultToken04=$null;$body04=$null}
function Publish04($path04,$definition04) {
    $definition04 | ConvertTo-Json -Depth 20 | Set-Content -Encoding utf8 "$PSScriptRoot/../.local/credential-adf.json"
    az rest --method put --url "$factory04/$path04`?api-version=2018-06-01" --body "@$PSScriptRoot/../.local/credential-adf.json" -o none
    Check04 "Publicar $path04"
}
Publish04 'linkedservices/ls_retail_blob_keyvault' @{properties=@{type='AzureBlobStorage';typeProperties=@{sasUri=@{type='SecureString';value="https://$account04.blob.core.windows.net/credentials-demo"};sasToken=@{type='AzureKeyVaultSecret';store=@{referenceName='ls_retail_keyvault';type='LinkedServiceReference'};secretName='demo-read-sas'}}}}
Publish04 'datasets/ds_keyvault_credential' @{properties=@{type='Binary';linkedServiceName=@{referenceName='ls_retail_blob_keyvault';type='LinkedServiceReference'};typeProperties=@{location=@{type='AzureBlobStorageLocation';container='credentials-demo';fileName='credential-check.txt'}}}}
Publish04 'pipelines/Retail_ValidateKeyVaultCredential' @{properties=@{activities=@(@{name='ReadPrivateBlob';type='GetMetadata';policy=@{timeout='0.00:05:00';retry=1;retryIntervalInSeconds=15;secureInput=$true;secureOutput=$false};typeProperties=@{dataset=@{referenceName='ds_keyvault_credential';type='DatasetReference'};fieldList=@('exists','size');storeSettings=@{type='AzureBlobStorageReadSettings'}}});concurrency=1}}
az rest --method post --url "$factory04/pipelines/Retail_ValidateKeyVaultCredential/createRun?api-version=2018-06-01" --body '{}' --query runId -o tsv
Check04 'Ejecutar validación de credencial.'
