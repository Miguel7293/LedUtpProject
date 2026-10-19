$ErrorActionPreference='Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$account=az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
$outputs=az deployment group show -g rg-leadutp-05-dev -n security --query properties.outputs -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'No se encontró el despliegue.' }
$file=Join-Path $PSScriptRoot '../.local/expiry-report.json'
az storage blob download --account-name $outputs.storageAccount.value --container-name reports --name keyvault-expiry/latest.json --file $file --auth-mode login --overwrite true --output none
if ($LASTEXITCODE -ne 0) { throw 'No se pudo descargar el reporte.' }
$report=Get-Content -LiteralPath $file -Raw | ConvertFrom-Json
if ($report.due15 -ne 2 -or $report.due30 -ne 2 -or $report.items.Count -ne 4) { throw 'El reporte no contiene los cuatro vencimientos de demostración esperados.' }
$token=az account get-access-token --resource https://management.azure.com/ --query accessToken -o tsv
if ($LASTEXITCODE -ne 0) { throw 'No se pudo autenticar Azure Monitor.' }
$headers=@{Authorization="Bearer $token"}
$span=[uri]::EscapeDataString([datetime]::UtcNow.AddMinutes(-30).ToString('o')+'/'+[datetime]::UtcNow.ToString('o'))
$url="https://management.azure.com$($outputs.vaultId.value)/providers/microsoft.insights/metrics?api-version=2018-01-01&metricnamespace=LeadUTP.KeyVault&metricnames=Due15Days,Due30Days&aggregation=Maximum&timespan=$span"
$metrics=Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec 30
foreach($metric in $metrics.value) {
    $points=@($metric.timeseries | ForEach-Object { $_.data } | Where-Object { $null -ne $_.maximum })
    if (-not ($points.maximum -contains 2)) { throw "No se encontró el valor 2 en $($metric.name.value); esperar la propagación inicial de métricas." }
    Write-Output "$($metric.name.value): valor 2 verificado en Azure Monitor."
}
if ($metrics.value.Count -ne 2) { throw 'No se encontraron ambas métricas.' }
$alertUrl="https://management.azure.com/subscriptions/$($account.id)/providers/Microsoft.AlertsManagement/alerts?api-version=2019-03-01"
$alerts=Invoke-RestMethod -Uri $alertUrl -Headers $headers -TimeoutSec 30
$fired=@($alerts.value | Where-Object { $_.properties.essentials.targetResource -eq $outputs.vaultId.value -and $_.properties.essentials.monitorCondition -eq 'Fired' })
if ($fired.Count -lt 2) { throw 'Esperar la evaluación de ambas reglas antes de dar la prueba por terminada.' }
Write-Output 'MONITOR_TEST_PASS: reporte 2/2, métricas publicadas y ambas alertas Fired. La entrega al buzón no se confirma desde Azure Monitor.'
