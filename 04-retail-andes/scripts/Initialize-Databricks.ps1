$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$dbHost04 = 'https://adb-7405618636834329.9.azuredatabricks.net'
$dbToken04 = $env:DATABRICKS_BOOTSTRAP_TOKEN
if (-not $dbToken04) {
    $dbToken04 = az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --query accessToken -o tsv
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo autenticar en Databricks.' }
}
$headers04 = @{Authorization="Bearer $dbToken04"}
function Db04([string]$Path, [string]$Method='GET', $Body=$null) {
    $args04 = @{Uri="$dbHost04$Path";Headers=$headers04;Method=$Method;ContentType='application/json'}
    if ($null -ne $Body) { $args04.Body=$Body | ConvertTo-Json -Depth 25 -Compress }
    Invoke-RestMethod @args04
}
try {
    $adfObject04 = az resource show -g rg-leadutp-04-dev -n adf-retail-57cyqpixoehss --resource-type Microsoft.DataFactory/factories --query identity.principalId -o tsv
    $adfApp04 = az ad sp show --id $adfObject04 --query appId -o tsv
    if ($LASTEXITCODE -ne 0) {throw 'Consultar identidad ADF.'}
    $dbPrincipals04=Db04 '/api/2.0/preview/scim/v2/ServicePrincipals'
    if ($adfApp04 -notin $dbPrincipals04.Resources.applicationId) {
        Db04 '/api/2.0/preview/scim/v2/ServicePrincipals' 'POST' @{schemas=@('urn:ietf:params:scim:schemas:core:2.0:ServicePrincipal');applicationId=$adfApp04;externalId=$adfObject04;displayName='RetailAndes ADF';active=$true} | Out-Null
    }
    $connector = '/subscriptions/e1e4a5db-a7e6-49f2-8968-9a0ffd605a91/resourceGroups/rg-leadutp-04-dev/providers/Microsoft.Databricks/accessConnectors/ac-retail-andes'
    $credentials = Db04 '/api/2.1/unity-catalog/storage-credentials'
    if ('retail_lake_mi' -notin $credentials.storage_credentials.name) {
        $lakeIdentity04='/subscriptions/e1e4a5db-a7e6-49f2-8968-9a0ffd605a91/resourceGroups/rg-leadutp-04-dev/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-retail-databricks-lake'
        Db04 '/api/2.1/unity-catalog/storage-credentials' 'POST' @{name='retail_lake_mi';azure_managed_identity=@{access_connector_id=$connector;managed_identity_id=$lakeIdentity04};comment='MI del laboratorio 04, sin claves.'} | Out-Null
    }
    $locations = Db04 '/api/2.1/unity-catalog/external-locations'
    foreach ($container in @('bronze','silver')) {
        $name04="retail_$container"
        if ($name04 -notin $locations.external_locations.name) {
            Db04 '/api/2.1/unity-catalog/external-locations' 'POST' @{name=$name04;url="abfss://$container@stretail57cyqpixoehss.dfs.core.windows.net/";credential_name='retail_lake_mi';comment='Laboratorio 04'} | Out-Null
        }
    }
    Db04 '/api/2.0/workspace/mkdirs' 'POST' @{path='/Shared/RetailAndes'} | Out-Null
    $content = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot/../notebooks/RetailAndes.py"))
    Db04 '/api/2.0/workspace/import' 'POST' @{path='/Shared/RetailAndes/BronzeToSilver';format='SOURCE';language='PYTHON';overwrite=$true;content=$content} | Out-Null
    $clusters = Db04 '/api/2.0/clusters/list'
    $cluster = @($clusters.clusters | Where-Object cluster_name -eq 'retail-lab-single-node') | Select-Object -First 1
    if (-not $cluster) {
        $me04 = Db04 '/api/2.0/preview/scim/v2/Me'
        $cluster = Db04 '/api/2.0/clusters/create' 'POST' @{
            cluster_name='retail-lab-single-node';spark_version='16.4.x-scala2.12';node_type_id='Standard_D4ds_v4';num_workers=0
            autotermination_minutes=10;data_security_mode='SINGLE_USER';single_user_name=$adfApp04
            spark_conf=@{'spark.databricks.cluster.profile'='singleNode';'spark.master'='local[*, 4]'}
            custom_tags=@{ResourceClass='SingleNode';Project='LeadUTP04'}
        }
    }
    @{host=$dbHost04;clusterId=$cluster.cluster_id;notebookPath='/Shared/RetailAndes/BronzeToSilver'} | ConvertTo-Json | Set-Content "$PSScriptRoot/../.local/databricks.json"
    Db04 "/api/2.0/permissions/clusters/$($cluster.cluster_id)" 'PATCH' @{access_control_list=@(@{service_principal_name=$adfApp04;permission_level='CAN_RESTART'})} | Out-Null
    foreach ($entry04 in @(@{name='retail_bronze';privileges=@('READ_FILES')},@{name='retail_silver';privileges=@('READ_FILES','WRITE_FILES')})) {
        Db04 "/api/2.1/unity-catalog/permissions/external_location/$($entry04.name)" 'PATCH' @{changes=@(@{principal=$adfApp04;add=$entry04.privileges})} | Out-Null
    }
    Write-Output "DATABRICKS_CONFIGURED: cluster $($cluster.cluster_id)"
} finally { $dbToken04=$null;$headers04=$null }
