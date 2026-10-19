$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$workspace06 = az monitor log-analytics workspace show -g rg-leadutp-06-dev -n log-lead06 --query customerId -o tsv
if ($LASTEXITCODE -ne 0) { throw 'Consultar workspace.' }
$telemetryToken06 = az account get-access-token --resource https://api.loganalytics.io --query accessToken -o tsv
if ($LASTEXITCODE -ne 0) { throw 'Autenticar consulta.' }
try {
    $query = @'
union withsource=SourceTable AppRequests, AppTraces, ContainerAppConsoleLogs_CL
| summarize Events=count() by SourceTable
'@
    $body = @{query=$query;timespan='PT1H'} | ConvertTo-Json
    $result = Invoke-RestMethod -Method Post -Uri "https://api.loganalytics.azure.com/v1/workspaces/$workspace06/query" -Headers @{Authorization="Bearer $telemetryToken06"} -ContentType application/json -Body $body
    $result | ConvertTo-Json -Depth 8
    $requests = @($result.tables[0].rows | Where-Object { $_[0] -eq 'AppRequests' -and $_[1] -gt 0 })
    $traces = @($result.tables[0].rows | Where-Object { $_[0] -eq 'AppTraces' -and $_[1] -gt 0 })
    if ($requests.Count -lt 1 -or $traces.Count -lt 1) { throw 'Aún faltan solicitudes o trazas de aplicación; revisar propagación/exportador.' }
    Write-Output 'APP_INSIGHTS_06_TEST_PASS'
} finally { $telemetryToken06=$null }
