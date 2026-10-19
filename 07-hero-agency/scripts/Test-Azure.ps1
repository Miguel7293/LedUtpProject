param([switch]$Vote)
$ErrorActionPreference = 'Stop'
if (Test-Path "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1") { . "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1" }
$outputs = az deployment group show -g rg-leadutp-07-dev -n hero07 --query properties.outputs -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'No se encontraron outputs.' }
foreach ($environment in $outputs.environments.value) {
    $arguments = @('run','--rm','--mount',"type=bind,source=$((Resolve-Path "$PSScriptRoot/smoke.mjs").Path),target=/smoke.mjs,readonly",'node:24-bookworm-slim','node','/smoke.mjs',$environment.url)
    if ($Vote) { $arguments += '--vote' }
    & docker @arguments
    if ($LASTEXITCODE -ne 0) { throw "Falló prueba $($environment.name)." }
}
