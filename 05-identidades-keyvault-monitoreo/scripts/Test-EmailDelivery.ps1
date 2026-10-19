# Envía una alerta real solo al destinatario ya configurado; no altera las reglas diarias.
# La entrega al buzón debe confirmarla la persona. La regla temporal se retira al finalizar.
$ErrorActionPreference='Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$sub05=az account show --query id -o tsv
if ($LASTEXITCODE -ne 0 -or $sub05 -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') {throw 'Suscripción incorrecta.'}
try {
    az deployment group create -g rg-leadutp-05-dev -n email-delivery-check --template-file "$PSScriptRoot/../infra/email-delivery-check.bicep" --query properties.provisioningState -o tsv
    if ($LASTEXITCODE -ne 0) {throw 'No se pudo crear la regla temporal.'}
    az rest --method post --url "https://management.azure.com/subscriptions/$sub05/resourceGroups/rg-leadutp-05-dev/providers/Microsoft.Logic/workflows/logic-keyvault-expiry/triggers/Daily/run?api-version=2016-06-01" -o none
    if ($LASTEXITCODE -ne 0) {throw 'No se pudo ejecutar la auditoría real.'}
    $found05=$false
    for ($attempt05=1;$attempt05 -le 12;$attempt05++) {
        $token05=az account get-access-token --query accessToken -o tsv
        try {
            $alerts05=Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$sub05/providers/Microsoft.AlertsManagement/alerts?api-version=2019-03-01" -Headers @{Authorization="Bearer $token05"}
            $match05=@($alerts05.value | Where-Object { ($_.properties.essentials.alertRule -like '*keyvault-delivery-check*' -or $_.properties.essentials.description -like '*Prueba de entrega LEAD*') -and $_.properties.essentials.monitorCondition -eq 'Fired' })
            if ($match05.Count) {
                $found05=$true
                @{status='FIRED';alertId=$match05[0].id;delivery='PENDIENTE_CONFIRMACION_BUZON'} | ConvertTo-Json | Set-Content "$PSScriptRoot/../.local/email-delivery-check.json"
                Write-Output 'EMAIL_DELIVERY_ALERT_FIRED: comprobar correo; Fired no prueba recepción.'
                break
            }
        } finally {$token05=$null}
        Start-Sleep -Seconds 20
    }
    if (-not $found05) {throw 'No se encontró Fired dentro de la ventana; revisar auditoría y métricas.'}
} finally {
    az monitor metrics alert delete -g rg-leadutp-05-dev -n keyvault-delivery-check -o none
    if ($LASTEXITCODE -ne 0) {Write-Warning 'Revisar y retirar la regla temporal keyvault-delivery-check.'}
}
