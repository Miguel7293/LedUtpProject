param([Parameter(Mandatory)][ValidateSet('Start', 'Deallocate')][string]$Action)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$account = az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
foreach ($vmName in @('VM01', 'VM02')) {
    if ($Action -eq 'Start') { az vm start -g rg-leadutp-03-dev -n $vmName --no-wait }
    else { az vm deallocate -g rg-leadutp-03-dev -n $vmName --no-wait }
    if ($LASTEXITCODE -ne 0) { throw "No se pudo aplicar $Action a $vmName." }
}
Write-Output 'Operaciones solicitadas. Consultar az vm list -g rg-leadutp-03-dev -d -o table para verificar el estado final.'
