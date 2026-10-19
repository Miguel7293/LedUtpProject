param([Parameter(Mandatory)][guid[]]$RunIds)
$ErrorActionPreference='Stop'
$projectRoot=(Resolve-Path "$PSScriptRoot/..").Path
$arguments=@('run','--rm','--mount',"type=bind,source=$projectRoot,target=/work",'--workdir','/work','spark:4.0.1-python3','/opt/spark/bin/spark-submit','--master','local[2]','--driver-memory','512m','spark/bronze_to_silver.py')
foreach($runId in $RunIds) { $arguments += @('--run-id',$runId.ToString()) }
docker @arguments
if ($LASTEXITCODE -ne 0) { throw 'Falló la transformación local PySpark.' }
Get-Content -LiteralPath "$projectRoot/.local/silver-result.json"
