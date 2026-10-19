# Identidad temporal Entra para inicializar UC cuando la identidad MSA no sincroniza.
# No escribe credenciales; la aplicación y permisos Azure se retiran al finalizar.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$host04='https://adb-7405618636834329.9.azuredatabricks.net'
$userToken04=az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --query accessToken -o tsv
$userHeaders04=@{Authorization="Bearer $userToken04"}
function UserDb04($path,$method='GET',$body=$null) {
    $options=@{Uri="$host04$path";Method=$method;Headers=$userHeaders04;ContentType='application/json'}
    if ($body) {$options.Body=$body | ConvertTo-Json -Depth 20 -Compress}
    Invoke-RestMethod @options
}
$application04=$null
$principal04=$null
$dbPrincipal04=$null
$adminGroup04=$null
$scopes04=@(
 '/subscriptions/e1e4a5db-a7e6-49f2-8968-9a0ffd605a91/resourceGroups/rg-leadutp-04-dev/providers/Microsoft.Databricks/accessConnectors/ac-retail-andes',
 '/subscriptions/e1e4a5db-a7e6-49f2-8968-9a0ffd605a91/resourceGroups/rg-leadutp-04-dev/providers/Microsoft.Databricks/workspaces/dbw-retail-andes',
 '/subscriptions/e1e4a5db-a7e6-49f2-8968-9a0ffd605a91/resourceGroups/rg-leadutp-04-dev/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-retail-databricks-lake'
)
$owner04=(UserDb04 '/api/2.0/preview/scim/v2/Me').userName
try {
    $application04=az ad app create --display-name LeadUTP04-TemporaryBootstrap -o json | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {throw 'Crear identidad temporal.'}
    $principal04=az ad sp create --id $application04.appId -o json | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {throw 'Crear service principal.'}
    foreach ($scope04 in $scopes04) {
        $role04=if ($scope04 -match 'ManagedIdentity') {'Reader'} else {'Contributor'}
        az role assignment create --assignee-object-id $principal04.id --assignee-principal-type ServicePrincipal --role $role04 --scope $scope04 -o none
        if ($LASTEXITCODE -ne 0) {throw 'Permiso temporal limitado.'}
    }
    $dbPrincipal04=UserDb04 '/api/2.0/preview/scim/v2/ServicePrincipals' 'POST' @{schemas=@('urn:ietf:params:scim:schemas:core:2.0:ServicePrincipal');applicationId=$application04.appId;externalId=$principal04.id;displayName='LeadUTP04-TemporaryBootstrap';active=$true}
    $groups04=UserDb04 '/api/2.0/preview/scim/v2/Groups'
    $adminGroup04=@($groups04.Resources | Where-Object displayName -eq 'admins')[0]
    UserDb04 "/api/2.0/preview/scim/v2/Groups/$($adminGroup04.id)" 'PATCH' @{schemas=@('urn:ietf:params:scim:api:messages:2.0:PatchOp');Operations=@(@{op='add';path='members';value=@(@{value=$dbPrincipal04.id})})} | Out-Null
    $expires04=(Get-Date).ToUniversalTime().AddHours(1).ToString('yyyy-MM-ddTHH:mm:ssZ')
    $credential04=az ad app credential reset --id $application04.appId --append --end-date $expires04 -o json | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {throw 'Credencial temporal.'}
    for ($attempt04=1;$attempt04 -le 6;$attempt04++) {
        try {
            $tokenResponse04=Invoke-RestMethod -Method Post -Uri 'https://login.microsoftonline.com/c6da2222-339d-47c3-9f10-6b3d3dee099b/oauth2/v2.0/token' -ContentType 'application/x-www-form-urlencoded' -Body @{client_id=$application04.appId;client_secret=$credential04.password;grant_type='client_credentials';scope='2ff814a6-3304-4ab8-85cb-cd0e6f879c1d/.default'}
            break
        } catch { if ($attempt04 -eq 6) {throw}; Start-Sleep -Seconds 10 }
    }
    $env:DATABRICKS_BOOTSTRAP_TOKEN=$tokenResponse04.access_token
    & "$PSScriptRoot/Initialize-Databricks.ps1"
    # Dejar todos los objetos UC a cargo del usuario del laboratorio antes de retirar SP.
    $temporaryHeaders04=@{Authorization="Bearer $env:DATABRICKS_BOOTSTRAP_TOKEN"}
    foreach ($target04 in @('storage-credentials/retail_lake_mi','external-locations/retail_bronze','external-locations/retail_silver')) {
        Invoke-RestMethod -Method Patch -Uri "$host04/api/2.1/unity-catalog/$target04" -Headers $temporaryHeaders04 -ContentType application/json -Body (@{owner=$owner04} | ConvertTo-Json) | Out-Null
    }
} finally {
    # Transferir también tras fallos de cómputo para no dejar objetos UC huérfanos.
    if ($env:DATABRICKS_BOOTSTRAP_TOKEN) {
        foreach ($target04 in @('storage-credentials/retail_lake_mi','external-locations/retail_bronze','external-locations/retail_silver')) {
            try {
                Invoke-RestMethod -TimeoutSec 60 -Method Patch -Uri "$host04/api/2.1/unity-catalog/$target04" -Headers @{Authorization="Bearer $env:DATABRICKS_BOOTSTRAP_TOKEN"} -ContentType application/json -Body (@{owner=$owner04}|ConvertTo-Json) | Out-Null
            } catch {
                $transferStatus04=[int]$_.Exception.Response.StatusCode
                if ($transferStatus04 -notin @(403,404)) {Write-Warning "Revisar propiedad UC de $target04 antes de otro bootstrap."}
            }
        }
    }
    $env:DATABRICKS_BOOTSTRAP_TOKEN=$null
    $credential04=$null;$tokenResponse04=$null;$temporaryHeaders04=$null
    if ($dbPrincipal04 -and $adminGroup04) {
        UserDb04 "/api/2.0/preview/scim/v2/Groups/$($adminGroup04.id)" 'PATCH' @{schemas=@('urn:ietf:params:scim:api:messages:2.0:PatchOp');Operations=@(@{op='remove';path="members[value eq `"$($dbPrincipal04.id)`"]"})} | Out-Null
    }
    if ($principal04) {
        foreach ($scope04 in $scopes04) {
            $role04=if ($scope04 -match 'ManagedIdentity') {'Reader'} else {'Contributor'}
            az role assignment delete --assignee $principal04.id --role $role04 --scope $scope04 -o none
        }
    }
    if ($application04) {az ad app delete --id $application04.appId -o none}
    $userToken04=$null;$userHeaders04=$null
}
