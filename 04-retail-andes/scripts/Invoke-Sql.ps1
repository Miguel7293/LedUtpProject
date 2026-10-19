param([Parameter(Mandatory)][ValidateSet('Initialize','DemoChanges','Inspect','Verify')][string]$Action)
$ErrorActionPreference='Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$account=az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
$outputs=az deployment group show -g rg-leadutp-04-dev -n retail --query properties.outputs -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Desplegar primero la infraestructura.' }
$clientIp=(Invoke-RestMethod 'https://api.ipify.org' -TimeoutSec 20).Trim()
$parsed=$null
if (-not [System.Net.IPAddress]::TryParse($clientIp,[ref]$parsed) -or $parsed.AddressFamily -ne 'InterNetwork') { throw 'IPv4 no válida.' }
$rule='retail-pc-'+[guid]::NewGuid().ToString('N').Substring(0,8)
try {
    az sql server firewall-rule create -g rg-leadutp-01-dev -s sql-leadutp-epf457eti6toe -n $rule --start-ip-address $clientIp --end-ip-address $clientIp -o none
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo autorizar temporalmente el PC.' }
    & "$env:ProgramFiles/sqlcmd/sqlcmd.exe" -S tcp:sql-leadutp-epf457eti6toe.database.windows.net,1433 -d sqldb-leadutp --authentication-method ActiveDirectoryAzCli -N true -l 120 -b -v "AdfName=$($outputs.factoryName.value)" -i "$PSScriptRoot/../sql/$Action.sql"
    if ($LASTEXITCODE -ne 0) { throw "Falló SQL: $Action. Si SQL estaba pausado, esperar a que termine de reanudarse y repetir." }
} finally {
    az sql server firewall-rule delete -g rg-leadutp-01-dev -s sql-leadutp-epf457eti6toe -n $rule -o none
    if ($LASTEXITCODE -ne 0) { Write-Warning "Retirar regla temporal $rule." }
}
