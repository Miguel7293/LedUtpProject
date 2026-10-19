param([ValidateSet('Validate','WhatIf','Deploy')][string]$Mode='WhatIf', [string]$ContactEmail=$env:AZURE_ALERT_EMAIL)
$ErrorActionPreference='Stop'
if (-not $ContactEmail -and (Test-Path "$PSScriptRoot/../.local/settings.json")) { $ContactEmail=(Get-Content "$PSScriptRoot/../.local/settings.json" -Raw | ConvertFrom-Json).alertEmail }
if (-not $ContactEmail) {throw 'Indicar -ContactEmail o AZURE_ALERT_EMAIL para las alertas.'}
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$account=az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
$user=az ad signed-in-user show --query id -o tsv
if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar el usuario.' }
$vmId=az vm identity assign -g rg-leadutp-03-dev -n VM01 --query systemAssignedIdentity -o tsv
if ($LASTEXITCODE -ne 0) { throw 'No se pudo habilitar la identidad de VM01.' }
if (-not $vmId) { $vmId=az vm show -g rg-leadutp-03-dev -n VM01 --query identity.principalId -o tsv }
if ($LASTEXITCODE -ne 0 -or -not $vmId) { throw 'No se obtuvo la identidad de VM01.' }
python "$PSScriptRoot/build_workflow.py"
if ($LASTEXITCODE -ne 0) { throw 'No se pudo generar el flujo.' }
az group create -n rg-leadutp-05-dev -l brazilsouth --tags project=leadutp-05 environment=lab -o none
if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear el grupo.' }
$lima=[TimeZoneInfo]::FindSystemTimeZoneById('SA Pacific Standard Time')
$nowLima=[TimeZoneInfo]::ConvertTimeFromUtc([datetime]::UtcNow,$lima)
$nextMorning=[datetime]::SpecifyKind($nowLima.Date.AddDays(1).AddHours(8),[DateTimeKind]::Unspecified)
$start=[TimeZoneInfo]::ConvertTimeToUtc($nextMorning,$lima).ToString('yyyy-MM-ddTHH:mm:ssZ')
$operation=switch($Mode) { 'Validate' {'validate'}; 'WhatIf' {'what-if'}; 'Deploy' {'create'} }
az deployment group $operation -g rg-leadutp-05-dev -n security --template-file "$PSScriptRoot/../infra/main.bicep" --parameters "operatorObjectId=$user" "vmPrincipalId=$vmId" "alertEmail=$ContactEmail" "firstScheduledRun=$start" --query properties.outputs -o json
if ($LASTEXITCODE -ne 0) { throw 'Falló el despliegue de seguridad.' }
if ($Mode -eq 'Deploy') {
    $entraPath=Join-Path $PSScriptRoot '../.local/entra.json'
    if (-not (Test-Path -LiteralPath $entraPath)) { throw 'Ejecutar Setup-Entra antes de asignar roles a grupos.' }
    $entra=Get-Content -LiteralPath $entraPath -Raw | ConvertFrom-Json
    $scope="/subscriptions/$($account.id)/resourceGroups/rg-leadutp-05-dev"
    foreach($assignment in @(@{group='GRP_bootcamp_LEAD_UTP';role='Reader'},@{group='GRP_bootcamp_LEAD_UTP_Contributor';role='Contributor'},@{group='GRP_bootcamp_LEAD_UTP_Owner';role='Owner'})) {
        $principal=$entra.groups.($assignment.group)
        az role assignment create --assignee-object-id $principal --assignee-principal-type Group --role $assignment.role --scope $scope -o none
        if ($LASTEXITCODE -ne 0) { throw "No se pudo asignar $($assignment.role)." }
    }
    $budgetStart=$nowLima.ToString('yyyy-MM-01')+'T00:00:00Z'
    az deployment group create -g rg-leadutp-05-dev -n budget --template-file "$PSScriptRoot/../infra/budget.bicep" --parameters "contactEmail=$ContactEmail" "startDate=$budgetStart" --query properties.provisioningState -o tsv
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo configurar el presupuesto del laboratorio.' }
}
