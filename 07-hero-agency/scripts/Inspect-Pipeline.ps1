param([int]$RunId = 1)
$ErrorActionPreference = 'Stop'
if (Test-Path "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1") { . "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1" }
$organization = 'https://dev.azure.com/miguel7293-leadutp'
az pipelines runs show --org $organization --project LeadUTP --id $RunId --query '{id:id,status:status,result:result}' -o table
if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar la ejecución.' }
az devops invoke --org $organization --area build --resource timeline --route-parameters project=LeadUTP "buildId=$RunId" --api-version 7.1 --query "records[?type=='Stage'].{Etapa:name,Estado:state,Resultado:result}" -o table
if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar el detalle.' }
Write-Host "$organization/LeadUTP/_build/results?buildId=$RunId"
