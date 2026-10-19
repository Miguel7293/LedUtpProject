$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$gh = 'C:/Program Files/GitHub CLI/gh.exe'
$repository = 'Miguel7293/LedUtpProject'
$group = 'rg-leadutp-02-dev'
$web = 'web-leadutp02-jmas5j6rizpu4'
function Check([string]$message) { if ($LASTEXITCODE -ne 0) { throw $message } }
$info = & $gh api "repos/$repository" | ConvertFrom-Json; Check 'Repositorio no accesible.'
az identity create -g $group -n id-web02-github -l brazilsouth -o none; Check 'Identidad.'
$identity = az identity show -g $group -n id-web02-github -o json | ConvertFrom-Json; Check 'Consultar identidad.'
$subject = "repo:$($info.owner.login)@$($info.owner.id)/$($info.name)@$($info.id):environment:azure-web02"
az identity federated-credential create -g $group --identity-name id-web02-github -n github-web02 --issuer https://token.actions.githubusercontent.com --subject $subject --audiences api://AzureADTokenExchange -o none; Check 'Federación.'
$scope = az webapp show -g $group -n $web --query id -o tsv; Check 'App Service.'
az role assignment create --assignee-object-id $identity.principalId --assignee-principal-type ServicePrincipal --role 'Website Contributor' --scope $scope -o none; Check 'Permiso limitado a web.'
New-Item -ItemType Directory -Force "$PSScriptRoot/../.local" | Out-Null
$body = "$PSScriptRoot/../.local/github-environment.json"
@{deployment_branch_policy=@{protected_branches=$false;custom_branch_policies=$true}} | ConvertTo-Json -Depth 5 | Set-Content $body
& $gh api --method PUT "repos/$repository/environments/azure-web02" --input $body --silent; Check 'Environment.'
$policies = & $gh api "repos/$repository/environments/azure-web02/deployment-branch-policies" | ConvertFrom-Json
foreach ($branch in @('main','codex/infraestructura-06')) {
    if ($branch -notin $policies.branch_policies.name) {
        & $gh api --method POST "repos/$repository/environments/azure-web02/deployment-branch-policies" -f "name=$branch" -f type=branch --silent; Check 'Política de rama.'
    }
}
foreach ($entry in @{AZURE_CLIENT_ID=$identity.clientId;AZURE_TENANT_ID=$identity.tenantId;AZURE_SUBSCRIPTION_ID='e1e4a5db-a7e6-49f2-8968-9a0ffd605a91';AZURE_WEBAPP_NAME=$web}.GetEnumerator()) {
    & $gh variable set $entry.Key --repo $repository --env azure-web02 --body $entry.Value; Check 'Variable.'
}
Write-Output 'WEB02_GITHUB_OIDC_READY'
