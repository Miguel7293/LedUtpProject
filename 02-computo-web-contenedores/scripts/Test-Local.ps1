$ErrorActionPreference = 'Stop'
$web = Invoke-RestMethod 'http://127.0.0.1:18080/health'
$api = Invoke-RestMethod 'http://127.0.0.1:18000/health'
$catalog = Invoke-RestMethod 'http://127.0.0.1:18080/api/products'
if ($web.status -ne 'ok' -or $api.status -ne 'ok') { throw 'Un servicio no está disponible.' }
if ($catalog.items.Count -ne 3 -or $catalog.currency -ne 'PEN') { throw 'Contrato del catálogo incorrecto.' }
$missing = Invoke-WebRequest 'http://127.0.0.1:18000/api/products/999' -SkipHttpErrorCheck
if ([int]$missing.StatusCode -ne 404) { throw 'El producto inexistente debe devolver 404.' }
$page = Invoke-WebRequest 'http://127.0.0.1:18080/'
if ($page.Content -notmatch 'Para tu día a día') { throw 'No se recibió la página de catálogo.' }
Write-Output 'Correcto: salud de ambos servicios, catálogo a través de .NET, producto inexistente y página HTML.'
