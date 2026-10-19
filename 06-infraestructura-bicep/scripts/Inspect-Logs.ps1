$ErrorActionPreference = 'Stop'
if (Test-Path "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1") { . "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1" }
$workspaceId = az monitor log-analytics workspace show -g rg-leadutp-06-dev -n log-lead06 --query customerId -o tsv
if ($LASTEXITCODE -ne 0) { throw 'No se pudo obtener el workspace.' }
$token = az account get-access-token --resource https://api.loganalytics.io --query accessToken -o tsv
if ($LASTEXITCODE -ne 0) { throw 'No se pudo autenticar en Log Analytics.' }
try {
    $body = @{ query = "ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'ca-lead06-api' | summarize Events=count()"; timespan = 'PT1H' } | ConvertTo-Json
    $result = Invoke-RestMethod -Method Post -Uri "https://api.loganalytics.azure.com/v1/workspaces/$workspaceId/query" -Headers @{ Authorization = "Bearer $token" } -ContentType 'application/json' -Body $body
    if ($result.error) { throw ($result.error | ConvertTo-Json -Depth 10) }
    $result | ConvertTo-Json -Depth 15
    if ($result.tables[0].rows[0][0] -lt 1) { throw 'Aún no se recibieron logs de la API; esperar propagación y repetir.' }
    Write-Host 'LOG_ANALYTICS_06_TEST_PASS'
} finally { $token = $null }
