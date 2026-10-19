param([switch]$Stop)
$ErrorActionPreference='Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$config04=Get-Content "$PSScriptRoot/../.local/databricks.json" -Raw | ConvertFrom-Json
if ($config04.host -ne 'https://adb-7405618636834329.9.azuredatabricks.net') {throw 'Workspace inesperado.'}
$token04=az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --query accessToken -o tsv
if ($LASTEXITCODE -ne 0) {throw 'Autenticación Databricks.'}
try {
    $headers04=@{Authorization="Bearer $token04"}
    if ($Stop) {
        Invoke-RestMethod -Method Post -Uri "$($config04.host)/api/2.0/clusters/delete" -Headers $headers04 -ContentType application/json -Body (@{cluster_id=$config04.clusterId}|ConvertTo-Json) | Out-Null
    }
    $status04=Invoke-RestMethod -Uri "$($config04.host)/api/2.0/clusters/get?cluster_id=$($config04.clusterId)" -Headers $headers04
    $status04 | Select-Object cluster_id,state,state_message,termination_reason | ConvertTo-Json -Depth 8
} finally {$token04=$null;$headers04=$null}
