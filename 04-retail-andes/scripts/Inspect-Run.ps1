param([Parameter(Mandatory)][guid]$RunId)
$ErrorActionPreference='Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$account=az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
$factory=az deployment group show -g rg-leadutp-04-dev -n retail --query properties.outputs.factoryName.value -o tsv
if ($LASTEXITCODE -ne 0) { throw 'No se encontró el factory.' }
$localDir=Join-Path $PSScriptRoot '../.local'
New-Item -ItemType Directory -Path $localDir -Force | Out-Null
$queryFile=Join-Path $localDir 'activity-query.json'
@{lastUpdatedAfter=[datetime]::UtcNow.AddDays(-2).ToString('o');lastUpdatedBefore=[datetime]::UtcNow.AddHours(1).ToString('o')} | ConvertTo-Json | Set-Content -LiteralPath $queryFile -Encoding utf8
$base="https://management.azure.com/subscriptions/$($account.id)/resourceGroups/rg-leadutp-04-dev/providers/Microsoft.DataFactory/factories/$factory"
function Read-Activities([string]$Id) {
    $result=az rest --method post --url "$base/pipelineruns/$Id/queryActivityruns?api-version=2018-06-01" --body "@$queryFile" -o json | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { throw "No se pudieron leer actividades de $Id." }
    foreach($activity in $result.value) {
        [PSCustomObject]@{RunId=$Id;Activity=$activity.activityName;Status=$activity.status;RowsCopied=$activity.output.rowsCopied;Error=$activity.error.message} | ConvertTo-Json -Compress
        if ($activity.activityType -eq 'ExecutePipeline' -and $activity.output.pipelineRunId) { Read-Activities $activity.output.pipelineRunId }
    }
}
Read-Activities $RunId.ToString()
