param(
    [ValidateRange(1,60)][int]$MaxPolls=40,
    [ValidateSet('','retail.Sales','SalesLT.Customer','SalesLT.Product')][string]$OnlyTable=''
)
$ErrorActionPreference='Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$account=az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
$outputs=az deployment group show -g rg-leadutp-04-dev -n retail --query properties.outputs -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'No se encontró Retail Andes.' }
$factory=$outputs.factoryName.value
$localDirectory=Join-Path $PSScriptRoot '../.local'
New-Item -ItemType Directory -Path $localDirectory -Force | Out-Null
$parametersFile=Join-Path $localDirectory 'run-parameters.json'
@{onlyTable=$OnlyTable} | ConvertTo-Json | Set-Content -LiteralPath $parametersFile -Encoding utf8
$base="https://management.azure.com/subscriptions/$($account.id)/resourceGroups/rg-leadutp-04-dev/providers/Microsoft.DataFactory/factories/$factory"
$rule='retail-adf-'+[guid]::NewGuid().ToString('N').Substring(0,8)
$run=$null
try {
    # 0.0.0.0 es la excepción temporal de Azure services, no una regla abierta a Internet.
    # Abarca servicios de otras suscripciones Azure; SQL sigue exigiendo identidad y permisos.
    az sql server firewall-rule create -g rg-leadutp-01-dev -s sql-leadutp-epf457eti6toe -n $rule --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0 -o none
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo habilitar temporalmente el acceso de Azure IR.' }
    $run=az rest --method post --url "$base/pipelines/RetailAndes/createRun?api-version=2018-06-01" --body "@$parametersFile" -o json | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo iniciar el pipeline.' }
    Write-Output "RunId: $($run.runId)"
    $lastStatus=''
    for ($i=0;$i -lt $MaxPolls;$i++) {
        $status=az rest --method get --url "$base/pipelineruns/$($run.runId)?api-version=2018-06-01" -o json | ConvertFrom-Json
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar la ejecución.' }
        if ($status.status -ne $lastStatus) { Write-Output "Estado: $($status.status)"; $lastStatus=$status.status }
        if ($status.status -in @('Succeeded','Failed','Cancelled')) { break }
        Start-Sleep -Seconds 15
    }
    $resultDirectory=Join-Path $PSScriptRoot '../.local/runs'
    New-Item -ItemType Directory -Path $resultDirectory -Force | Out-Null
    $status | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $resultDirectory "$($run.runId).json") -Encoding utf8
    if ($status.status -ne 'Succeeded') {
        Write-Output ($status | ConvertTo-Json -Depth 20)
        throw 'El pipeline no terminó correctamente. Consultar Monitor y las actividades fallidas; el checkpoint no debe adelantarse si falla Copy.'
    }
    Write-Output "Pipeline RetailAndes completado: $($run.runId)"
} finally {
    az sql server firewall-rule delete -g rg-leadutp-01-dev -s sql-leadutp-epf457eti6toe -n $rule -o none
    if ($LASTEXITCODE -ne 0) { Write-Warning "Retirar regla temporal $rule." }
}
