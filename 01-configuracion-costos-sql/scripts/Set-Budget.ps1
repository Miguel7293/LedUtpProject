param(
    [Parameter(Mandatory)][string]$ContactEmail,
    [ValidateRange(1, 100)][int]$MonthlyAmount = 10,
    [switch]$Deploy
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$account = az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') {
    throw 'Seleccionar la suscripción Students del laboratorio.'
}
try { $null = [System.Net.Mail.MailAddress]::new($ContactEmail) } catch { throw 'Correo no válido.' }
$limaTime = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([datetime]::UtcNow, 'SA Pacific Standard Time')
$startDate = $limaTime.ToString('yyyy-MM-01') + 'T00:00:00Z'
$operation = if ($Deploy) { 'create' } else { 'what-if' }
az deployment group $operation --name leadutp-01-budget --resource-group rg-leadutp-01-dev --template-file "$PSScriptRoot/../infra/budget.bicep" --parameters "contactEmail=$ContactEmail" "monthlyAmount=$MonthlyAmount" "startDate=$startDate" --output json
if ($LASTEXITCODE -ne 0) { throw 'No se pudo configurar el presupuesto.' }
