param(
    [Parameter(Mandatory)][string]$ClientIPv4
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$parsedAddress = $null
if (-not [System.Net.IPAddress]::TryParse($ClientIPv4, [ref]$parsedAddress) -or
    $parsedAddress.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork -or
    $ClientIPv4 -eq '0.0.0.0') { throw 'Indicar una dirección IPv4 pública individual válida.' }
$account = az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
$outputs = az deployment sub show -n leadutp-01 --query properties.outputs -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or -not $outputs.serverName.value) { throw 'Completar primero el despliegue SQL.' }
$serverName = $outputs.serverName.value
$sqlcmd = Join-Path $env:ProgramFiles 'sqlcmd/sqlcmd.exe'
if (-not (Test-Path -LiteralPath $sqlcmd)) { throw 'Instalar Microsoft.Sqlcmd antes de verificar.' }
$ruleName = 'verify-' + [guid]::NewGuid().ToString('N').Substring(0, 12)
try {
    az sql server firewall-rule create -g rg-leadutp-01-dev -s $serverName -n $ruleName --start-ip-address $ClientIPv4 --end-ip-address $ClientIPv4 --output none
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo autorizar la IP temporalmente.' }
    & $sqlcmd -S "tcp:$($outputs.endpoint.value),1433" -d $outputs.databaseName.value --authentication-method ActiveDirectoryAzCli -N true -l 120 -b -i "$PSScriptRoot/../sql/Verify.sql"
    if ($LASTEXITCODE -ne 0) { throw 'Falló la consulta SQL; revisar el error de conexión o autenticación.' }
} finally {
    az sql server firewall-rule delete -g rg-leadutp-01-dev -s $serverName -n $ruleName --output none
    if ($LASTEXITCODE -ne 0) { Write-Warning "Revisar y eliminar la regla temporal $ruleName." }
}
