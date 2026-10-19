$ErrorActionPreference = 'Continue'
$knownToolDirectories = @(
    "$env:LOCALAPPDATA\Programs\Python\Python312",
    "$env:LOCALAPPDATA\Programs\Python\Python312\Scripts",
    "$env:ProgramFiles\dotnet",
    "$env:ProgramFiles\Microsoft SDKs\Azure\CLI2\wbin"
)
$env:PATH = ($knownToolDirectories -join ';') + ';' + $env:PATH
$toolsToCheck = @{
    Git = @('git', '--version')
    Node = @('node', '--version')
    Npm = @('npm.cmd', '--version')
    Python = @('python', '--version')
    Docker = @('docker', '--version')
    DotNet = @('dotnet', '--version')
    AzureCLI = @('az', 'version')
}
foreach ($entry in $toolsToCheck.GetEnumerator()) {
    $command = Get-Command $entry.Value[0] -ErrorAction SilentlyContinue
    if ($command) {
        Write-Host "`n[$($entry.Key)]"
        & $command.Source $entry.Value[1]
    } else {
        Write-Warning "$($entry.Key): no encontrado en PATH. Abrir una terminal nueva después de instalar."
    }
}
Write-Host "`n[Pip]"
python -m pip --version
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "`n[Motor Docker]"
    docker info --format '{{.ServerVersion}}'
}
