$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
try {
    az vm start -g rg-leadutp-02-dev -n vm-leadutp02-win -o none
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo iniciar la VM.' }
    $check = az vm run-command invoke -g rg-leadutp-02-dev -n vm-leadutp02-win --command-id RunPowerShellScript --scripts "@$PSScriptRoot/Check-WindowsGuest.ps1" -o json | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or ($check.value.message -join '') -notmatch 'WINDOWS_VM_TEST_PASS') { throw 'Falló la comprobación de Windows.' }
    Write-Output $check.value.message
} finally {
    az vm deallocate -g rg-leadutp-02-dev -n vm-leadutp02-win -o none
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo desasignar la VM. Revisar inmediatamente.' }
}
