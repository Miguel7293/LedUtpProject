$ErrorActionPreference='Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$account=az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
$operatorId=az ad signed-in-user show --query id -o tsv
if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar el usuario.' }
$groups=@{}
foreach($name in @('GRP_bootcamp_LEAD_UTP','GRP_bootcamp_LEAD_UTP_Contributor','GRP_bootcamp_LEAD_UTP_Owner')) {
    $existing=@(az ad group list --filter "displayName eq '$name'" -o json | ConvertFrom-Json)
    if ($LASTEXITCODE -ne 0) { throw 'Se requieren permisos de directorio para administrar grupos.' }
    if ($existing.Count -gt 1) { throw "Nombre de grupo ambiguo: $name." }
    $group=if($existing.Count -eq 1) { $existing[0] } else { az ad group create --display-name $name --mail-nickname $name.ToLowerInvariant() -o json | ConvertFrom-Json }
    if ($LASTEXITCODE -ne 0) { throw "No se pudo crear $name." }
    $groups[$name]=$group.id
    $owners=@(az ad group owner list --group $group.id --query '[].id' -o json | ConvertFrom-Json)
    if ($operatorId -notin $owners) {
        az ad group owner add --group $group.id --owner-object-id $operatorId
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo asignar el propietario del grupo.' }
    }
}
$domain=az rest --method get --url 'https://graph.microsoft.com/v1.0/domains' --query 'value[?isDefault].id | [0]' -o tsv
if ($LASTEXITCODE -ne 0 -or -not $domain) { throw 'No se pudo consultar el dominio del tenant.' }
$upn="lab.reader.leadutp@$domain"
$users=@(az ad user list --filter "userPrincipalName eq '$upn'" -o json | ConvertFrom-Json)
if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar el usuario de laboratorio.' }
if ($users.Count -eq 0) {
    # Usuario de demostración deshabilitado; la contraseña aleatoria no se guarda ni se muestra.
    $password=[guid]::NewGuid().ToString('N')+[guid]::NewGuid().ToString('N')+'Aa1!'
    $body=@{accountEnabled=$false;displayName='LEAD UTP - lector de laboratorio';mailNickname='lab.reader.leadutp';userPrincipalName=$upn;passwordProfile=@{forceChangePasswordNextSignIn=$true;password=$password}} | ConvertTo-Json -Depth 5
    $token=az account get-access-token --resource-type ms-graph --query accessToken -o tsv
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo autenticar Microsoft Graph.' }
    $user=Invoke-RestMethod -Method Post -Uri 'https://graph.microsoft.com/v1.0/users' -Headers @{Authorization="Bearer $token"} -ContentType 'application/json' -Body $body
    $password=$null; $body=$null; $token=$null
} else {
    $user=$users[0]
    if ($user.accountEnabled) { throw 'El usuario de demostración existe y está habilitado; revisar manualmente antes de continuar.' }
}
$member=az ad group member check --group $groups['GRP_bootcamp_LEAD_UTP'] --member-id $user.id --query value -o tsv
if ($member -ne 'true') {
    az ad group member add --group $groups['GRP_bootcamp_LEAD_UTP'] --member-id $user.id
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo añadir el lector al grupo.' }
}
$localDir=Join-Path $PSScriptRoot '../.local'
New-Item -ItemType Directory -Path $localDir -Force | Out-Null
@{groups=$groups;readerUserId=$user.id;readerUpn=$upn} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $localDir 'entra.json') -Encoding utf8
Write-Output 'Grupos creados; lector de laboratorio deshabilitado y miembro del grupo base. Owner y Contributor permanecen sin miembros.'
