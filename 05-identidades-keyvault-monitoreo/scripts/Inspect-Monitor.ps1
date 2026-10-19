$ErrorActionPreference='Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$account=az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
$base="https://management.azure.com/subscriptions/$($account.id)/resourceGroups/rg-leadutp-05-dev/providers/Microsoft.Logic/workflows/logic-keyvault-expiry"
$runs=az rest --method get --url ($base+'/runs?api-version=2016-06-01') -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $runs.value.Count -eq 0) { throw 'No se encontraron ejecuciones.' }
$run=$runs.value | Sort-Object { $_.properties.startTime } -Descending | Select-Object -First 1
[PSCustomObject]@{runId=$run.name;status=$run.properties.status;error=$run.properties.error} | ConvertTo-Json -Depth 6
az rest --method get --url "$base/runs/$($run.name)/actions?api-version=2016-06-01" --query 'value[].{action:name,status:properties.status,error:properties.error}' -o json
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron consultar las acciones.' }
