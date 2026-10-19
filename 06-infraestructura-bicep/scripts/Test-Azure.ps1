$ErrorActionPreference = 'Stop'
if (Test-Path "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1") { . "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1" }
$deployment = az deployment sub show --name leadutp-06 -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $deployment.properties.provisioningState -ne 'Succeeded') { throw 'Despliegue incompleto.' }
$url = $deployment.properties.outputs.apiUrl.value
$healthy = $false
for ($attempt = 1; $attempt -le 12; $attempt++) {
    try {
        $response = Invoke-WebRequest "$url/health" -TimeoutSec 30
        if ($response.StatusCode -eq 200) { $healthy = $true; break }
    } catch { Write-Host "Esperando arranque de la API ($attempt/12)." }
    Start-Sleep -Seconds 10
}
if (-not $healthy) { throw 'La API no respondió HTTP 200.' }
$app = az containerapp show -g rg-leadutp-06-dev -n ca-lead06-api -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $app.properties.template.scale.minReplicas -ne 0 -or $app.identity.type -ne 'UserAssigned') { throw 'Identidad o escala incorrectas.' }
$workspace = az resource show --ids $deployment.properties.outputs.workspaceId.value --api-version 2023-09-01 -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $workspace.properties.retentionInDays -ne 30 -or $workspace.properties.workspaceCapping.dailyQuotaGb -ne 1) { throw 'Límites de logs incorrectos.' }
if ($workspace.properties.features.disableLocalAuth -ne $false) { throw 'La integración Express de logs requiere autenticación local del workspace.' }
$environment = az containerapp env show -g rg-leadutp-06-dev -n cae-lead06 -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $environment.properties.appLogsConfiguration.destination -ne 'log-analytics' -or $environment.properties.appLogsConfiguration.logAnalyticsConfiguration.customerId -ne $workspace.properties.customerId) { throw 'Destino de logs incorrecto.' }
Write-Host "BICEP_06_TEST_PASS: HTTP 200, managed identity, escala mínima 0, retención 30 días y cuota 1 GB/día. $url"
