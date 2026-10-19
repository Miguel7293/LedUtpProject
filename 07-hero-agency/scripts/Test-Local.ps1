$ErrorActionPreference = 'Stop'
docker build --target test -t hero-agency:test "$PSScriptRoot/.."
if ($LASTEXITCODE -ne 0) { throw 'Falló build de pruebas.' }
docker run --rm hero-agency:test
if ($LASTEXITCODE -ne 0) { throw 'Fallaron pruebas.' }
docker compose -f "$PSScriptRoot/../compose.yml" up -d --build
if ($LASTEXITCODE -ne 0) { throw 'Falló Compose.' }
$script = (Resolve-Path "$PSScriptRoot/smoke.mjs").Path
docker run --rm --add-host host.docker.internal:host-gateway --mount "type=bind,source=$script,target=/smoke.mjs,readonly" node:24-bookworm-slim node /smoke.mjs http://host.docker.internal:18070 --vote
if ($LASTEXITCODE -ne 0) { throw 'Falló prueba HTTP local.' }
