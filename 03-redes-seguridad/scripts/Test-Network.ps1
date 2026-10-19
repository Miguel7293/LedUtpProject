$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$account = az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
$rg = 'rg-leadutp-03-dev'
$ready = az vm run-command invoke -g $rg -n VM02 --command-id RunShellScript --scripts 'cloud-init status --wait; systemctl is-active leadutp-web' -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or ($ready.value.message -join "`n") -notmatch '(?m)^active') { throw 'El servidor de VM02 no está listo.' }
$result = az vm run-command invoke -g $rg -n VM01 --command-id RunShellScript --scripts "@$PSScriptRoot/check-connectivity.sh" -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Falló Run Command en VM01.' }
$message = $result.value.message -join "`n"
Write-Output $message
if ($message -notmatch 'LEADUTP_NETWORK_TEST_PASS') { throw 'No pasaron las pruebas de conectividad.' }
foreach ($port in @(80, 443, 22, 3389)) {
    $flow = az network watcher test-ip-flow -g $rg --vm VM02 --direction Inbound --protocol TCP --local "10.30.2.4:$port" --remote '10.30.1.4:50000' -o json | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { throw "No se pudo evaluar el puerto $port." }
    $expected = if ($port -in @(80, 443)) { 'Allow' } else { 'Deny' }
    if ($flow.access -ne $expected) { throw "Puerto ${port}: esperado $expected, recibido $($flow.access)." }
    Write-Output "NSG TCP ${port}: $($flow.access) ($($flow.ruleName))"
}
$outbound = az network watcher test-ip-flow -g $rg --vm VM01 --direction Outbound --protocol TCP --local '10.30.1.4:50000' --remote '1.1.1.1:3389' -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $outbound.access -ne 'Deny') { throw 'No se verificó la regla de salida RDP.' }
Write-Output "NSG salida TCP 3389 a Internet: $($outbound.access) ($($outbound.ruleName))"
Write-Output 'Correcto: comunicación HTTP y reglas de segmentación verificadas.'
