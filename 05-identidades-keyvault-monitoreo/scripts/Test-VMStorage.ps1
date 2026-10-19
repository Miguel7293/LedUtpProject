$ErrorActionPreference='Stop'
. "$PSScriptRoot/../../scripts/Enter-DevEnvironment.ps1"
$account=az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $account.id -ne 'e1e4a5db-a7e6-49f2-8968-9a0ffd605a91') { throw 'Suscripción incorrecta.' }
$outputs=az deployment group show -g rg-leadutp-05-dev -n security --query properties.outputs -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'No se encontró la infraestructura.' }
$url="https://$($outputs.storageAccount.value).blob.core.windows.net/documents/documento-demo.pdf"
$hash=(Get-FileHash -LiteralPath "$PSScriptRoot/../output/pdf/documento-demo.pdf" -Algorithm SHA256).Hash.ToLowerInvariant()
$script=(Get-Content -LiteralPath "$PSScriptRoot/test_vm_storage.sh" -Raw).Replace('__DOCUMENT_URL__',$url).Replace('__EXPECTED_SHA256__',$hash)
$file=Join-Path $PSScriptRoot '../.local/test_vm_storage.sh'
Set-Content -LiteralPath $file -Value $script -Encoding utf8NoBOM
try {
    az vm start -g rg-leadutp-03-dev -n VM01 -o none
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo iniciar VM01.' }
    $result=az vm run-command invoke -g rg-leadutp-03-dev -n VM01 --command-id RunShellScript --scripts "@$file" -o json | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo ejecutar la prueba.' }
    $message=$result.value.message -join "`n"
    Write-Output $message
    if ($message -notmatch 'MI_STORAGE_TEST_PASS') { throw 'Falló la lectura con identidad administrada o la prueba de permisos.' }
} finally {
    az vm deallocate -g rg-leadutp-03-dev -n VM01 --no-wait
    if ($LASTEXITCODE -ne 0) { Write-Warning 'Desasignar VM01 para detener el costo de cómputo.' }
}
