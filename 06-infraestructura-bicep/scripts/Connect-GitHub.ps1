param([string]$Repository = 'Miguel7293/LedUtpProject', [string]$ContactEmail = $env:AZURE_ALERT_EMAIL)
$ErrorActionPreference = 'Stop'
if (-not $ContactEmail -and (Test-Path "$PSScriptRoot/../.local/settings.json")) { $ContactEmail = (Get-Content "$PSScriptRoot/../.local/settings.json" -Raw | ConvertFrom-Json).alertEmail }
if (-not $ContactEmail) { throw 'Indicar -ContactEmail o AZURE_ALERT_EMAIL.' }
if ($Repository -ne 'Miguel7293/LedUtpProject') { throw 'Este script está limitado al repositorio autorizado.' }
if (Test-Path "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1") { . "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1" }
$gh = if (Get-Command gh -ErrorAction SilentlyContinue) { 'gh' } else { 'C:/Program Files/GitHub CLI/gh.exe' }
function Check([string]$Action) { if ($LASTEXITCODE -ne 0) { throw "Falló: $Action" } }
& $gh auth status; Check 'autenticación GitHub'
$sub = 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91'
$account = az account show -o json | ConvertFrom-Json; Check 'cuenta Azure'
if ($account.id -ne $sub) { throw 'Suscripción incorrecta.' }
$group = 'rg-leadutp-06-dev'
$scope = "/subscriptions/$sub"
$groupScope = "$scope/resourceGroups/$group"
$registryScope = "$scope/resourceGroups/rg-leadutp-02-dev/providers/Microsoft.ContainerRegistry/registries/acrleadutpjmas5j6rizpu4"
$local = "$PSScriptRoot/../.local"
New-Item -ItemType Directory -Force $local | Out-Null
az identity create -g $group -n id-lead06-github --location brazilsouth -o none; Check 'identidad GitHub'
$identity = az identity show -g $group -n id-lead06-github -o json | ConvertFrom-Json; Check 'consultar identidad'
$repoInfo = & $gh api "repos/$Repository" | ConvertFrom-Json; Check 'identificadores del repositorio'
$subject = "repo:$($repoInfo.owner.login)@$($repoInfo.owner.id)/$($repoInfo.name)@$($repoInfo.id):environment:azure-lab"
az identity federated-credential create -g $group --identity-name id-lead06-github -n github-azure-lab --issuer https://token.actions.githubusercontent.com --subject $subject --audiences api://AzureADTokenExchange -o none; Check 'federación OIDC'
$roleName = 'LeadUTP06 Subscription Deployment'
@{ Name=$roleName; IsCustom=$true; Description='Operaciones de despliegue ARM; no concede permisos sobre recursos de otros grupos.'; Actions=@('Microsoft.Resources/deployments/*'); NotActions=@(); AssignableScopes=@($scope) } | ConvertTo-Json -Depth 5 | Set-Content "$local/deployment-role.json"
$roles = az role definition list --name $roleName -o json | ConvertFrom-Json; Check 'buscar rol'
if (-not $roles) { az role definition create --role-definition "$local/deployment-role.json" -o none; Check 'crear rol' }
$grants = @(
    @{Role=$roleName; Scope=$scope},
    @{Role='Contributor'; Scope=$groupScope},
    @{Role='Role Based Access Control Administrator'; Scope=$groupScope},
    @{Role='AcrPull'; Scope=$registryScope},
    @{Role='Role Based Access Control Administrator'; Scope=$registryScope}
)
foreach ($grant in $grants) {
    az role assignment create --assignee-object-id $identity.principalId --assignee-principal-type ServicePrincipal --role $grant.Role --scope $grant.Scope -o none
    Check "rol $($grant.Role)"
}
@{ deployment_branch_policy=@{protected_branches=$false;custom_branch_policies=$true} } | ConvertTo-Json -Depth 4 | Set-Content "$local/environment.json"
& $gh api --method PUT "repos/$Repository/environments/azure-lab" --input "$local/environment.json" --silent; Check 'environment'
$policies = & $gh api "repos/$Repository/environments/azure-lab/deployment-branch-policies" | ConvertFrom-Json; Check 'políticas de ramas'
foreach ($branch in @('main','codex/infraestructura-06')) {
    if ($branch -notin $policies.branch_policies.name) {
        & $gh api --method POST "repos/$Repository/environments/azure-lab/deployment-branch-policies" -f "name=$branch" -f type=branch --silent; Check 'rama autorizada'
    }
}
foreach ($entry in @{AZURE_CLIENT_ID=$identity.clientId; AZURE_TENANT_ID=$account.tenantId; AZURE_SUBSCRIPTION_ID=$sub}.GetEnumerator()) {
    & $gh variable set $entry.Key --repo $Repository --env azure-lab --body $entry.Value; Check "variable $($entry.Key)"
}
& $gh secret set AZURE_ALERT_EMAIL --repo $Repository --env azure-lab --body $ContactEmail; Check 'destinatario protegido'
Write-Host 'GITHUB_OIDC_READY: federación sin secretos y permisos limitados al laboratorio/ACR, más operaciones ARM de suscripción.'
