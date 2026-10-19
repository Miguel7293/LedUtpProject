param([switch]$RunNow)
$ErrorActionPreference='Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$account=az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
python "$PSScriptRoot/build_workflow.py"
if ($LASTEXITCODE -ne 0) { throw 'No se pudo generar el flujo.' }
$id="/subscriptions/$($account.id)/resourceGroups/rg-leadutp-05-dev/providers/Microsoft.Logic/workflows/logic-keyvault-expiry"
$current=az rest --method get --url "https://management.azure.com${id}?api-version=2019-05-01" -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'No se encontró Logic Apps.' }
$definition=Get-Content -LiteralPath "$PSScriptRoot/../logic/workflow.json" -Raw | ConvertFrom-Json
$body=@{location=$current.location;identity=@{type='SystemAssigned'};properties=@{state='Enabled';definition=$definition;parameters=$current.properties.parameters}}
$file=Join-Path $PSScriptRoot '../.local/enable-workflow.json'
$body | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $file -Encoding utf8
az rest --method put --url "https://management.azure.com${id}?api-version=2019-05-01" --body "@$file" --output none
if ($LASTEXITCODE -ne 0) { throw 'No se pudo habilitar el flujo.' }
if ($RunNow) {
    az rest --method post --url "https://management.azure.com$id/triggers/Daily/run?api-version=2016-06-01" --output none
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo iniciar la auditoría manual.' }
}
Write-Output 'Monitor habilitado: auditoría diaria a las 08:00 America/Lima. Si RunNow se indicó, se solicitó además una ejecución inmediata.'
