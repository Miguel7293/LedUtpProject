param([switch]$Azure)
$ErrorActionPreference = 'Stop'
$project08 = Split-Path $PSScriptRoot -Parent
Set-Location $project08
. ../scripts/Enter-DevEnvironment.ps1
$env:AZURE_OPENAI_ENDPOINT = 'https://banco-abc-resource.openai.azure.com'
$env:AZURE_OPENAI_DEPLOYMENT = 'banco-abc-texto'
$env:ENABLE_AZURE_GENERATION = if ($Azure) { 'true' } else { 'false' }
& ./.venv/Scripts/python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 18090
