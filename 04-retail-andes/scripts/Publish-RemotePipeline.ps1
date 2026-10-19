param([switch]$PolicyOnly)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$factory04 = 'https://management.azure.com/subscriptions/e1e4a5db-a7e6-49f2-8968-9a0ffd605a91/resourceGroups/rg-leadutp-04-dev/providers/Microsoft.DataFactory/factories/adf-retail-57cyqpixoehss'
function Put04($resource04,$body04) {
    $file04="$PSScriptRoot/../.local/adf-remote-body.json"
    $body04 | ConvertTo-Json -Depth 30 | Set-Content -Encoding utf8 $file04
    az rest --method put --url "$factory04/$resource04`?api-version=2018-06-01" --body "@$file04" -o none
    if ($LASTEXITCODE -ne 0) {throw "No se pudo publicar $resource04"}
}
Put04 'linkedservices/ls_retail_keyvault' @{properties=@{type='AzureKeyVault';typeProperties=@{baseUrl='https://kv-retail-andes-7293.vault.azure.net/'}}}
$activities04=@(@{
    name='ReadSilverPolicy';type='WebActivity';policy=@{timeout='0.00:05:00';retry=1;retryIntervalInSeconds=15;secureOutput=$true;secureInput=$true}
    typeProperties=@{method='GET';url='https://kv-retail-andes-7293.vault.azure.net/secrets/silver-expected-sales?api-version=7.4';authentication=@{type='MSI';resource='https://vault.azure.net'}}
})
if ($PolicyOnly) {
    $activities04+=@{name='ValidatePolicy';type='IfCondition';dependsOn=@(@{activity='ReadSilverPolicy';dependencyConditions=@('Succeeded')});typeProperties=@{expression=@{value="@equals(activity('ReadSilverPolicy').output.value, '4')";type='Expression'};ifFalseActivities=@(@{name='RejectPolicy';type='Fail';typeProperties=@{message='La política sintética no coincide.';errorCode='POLICY_INVALID'}})}}
    $name04='Retail_ValidateKeyVault'
} else {
    $config04=Get-Content "$PSScriptRoot/../.local/databricks.json" -Raw | ConvertFrom-Json
    Put04 'linkedservices/ls_retail_databricks' @{properties=@{type='AzureDatabricks';typeProperties=@{domain=$config04.host;authentication='MSI';workspaceResourceId='/subscriptions/e1e4a5db-a7e6-49f2-8968-9a0ffd605a91/resourceGroups/rg-leadutp-04-dev/providers/Microsoft.Databricks/workspaces/dbw-retail-andes';existingClusterId=$config04.clusterId}}}
    $activities04+=@{name='BronzeToSilver';type='DatabricksNotebook';dependsOn=@(@{activity='ReadSilverPolicy';dependencyConditions=@('Succeeded')});policy=@{timeout='0.00:30:00';retry=0;secureInput=$true;secureOutput=$false};linkedServiceName=@{referenceName='ls_retail_databricks';type='LinkedServiceReference'};typeProperties=@{notebookPath=$config04.notebookPath;baseParameters=@{storage_account='stretail57cyqpixoehss';committed_run_ids='c2b5f5d1-7fd1-419e-b3d1-f3b358888a15,0488aba4-3f28-41b1-a33d-414aa4c1cef1';expected_sales=@{value="@activity('ReadSilverPolicy').output.value";type='Expression'}}}}
    $name04='Retail_DatabricksSilver'
}
Put04 "pipelines/$name04" @{properties=@{activities=$activities04;concurrency=1}}
az rest --method post --url "$factory04/pipelines/$name04/createRun?api-version=2018-06-01" --body '{}' --query runId -o tsv
if ($LASTEXITCODE -ne 0) {throw 'No se pudo ejecutar el pipeline.'}
